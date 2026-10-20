local Settings = Config.emergencyCalls
local SyncIntervalMs = 60000
local ProximityIntervalMs = 1000
local DespawnPadding = 30.0
local LeaveDelayMs = 7000

local Active = {}

local function scenarioOf(Call)
    return Settings.scenarios[Call.scenario]
end

local function modelFor(Call)
    local Models = scenarioOf(Call).models

    return Models[Call.id % #Models + 1]
end

local function streetLabel(Coords)
    return GetStreetNameFromHashKey((GetStreetNameAtCoord(Coords.x, Coords.y, Coords.z)))
end

local function addBlip(Call)
    local Blip = AddBlipForCoord(Call.coords.x, Call.coords.y, Call.coords.z)

    SetBlipSprite(Blip, Settings.blip.sprite)
    SetBlipColour(Blip, Settings.blip.colour)
    SetBlipScale(Blip, Settings.blip.scale)
    SetBlipAsShortRange(Blip, false)
    SetBlipRoute(Blip, true)
    SetBlipRouteColour(Blip, Settings.blip.colour)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(locale(scenarioOf(Call).label))
    EndTextCommandSetBlipName(Blip)

    return Blip
end

local function groundedCoords(Coords)
    RequestCollisionAtCoord(Coords.x, Coords.y, Coords.z)

    for _ = 1, 20 do
        local Found, GroundZ = GetGroundZFor_3dCoord(Coords.x, Coords.y, Coords.z + 3.0, false)

        if Found then return vector3(Coords.x, Coords.y, GroundZ) end

        Wait(50)
    end

    return vector3(Coords.x, Coords.y, Coords.z)
end

local function missingItemLabel(Name)
    local Item = exports.ox_inventory:Items(Name)

    return Item and Item.label or Name
end

local function finishCall(Call)
    local Done, Result = lib.callback.await('ars_ambulancejob:completeEmergencyCall', false, Call.id)

    if not Done then
        Utils.notify(locale(Result or 'invalid_request'), 'error')
        return
    end

    PlaySoundFrontend(-1, 'CHECKPOINT_PERFECT', 'HUD_MINI_GAME_SOUNDSET', true)

    if Result.reward > 0 then
        Utils.notify(locale('call_completed', Result.reward, Result.streak), 'success')
    else
        Utils.notify(locale('call_completed_free', Result.streak), 'success')
    end

    if Result.fast then Utils.notify(locale('call_fast_response'), 'success') end
end

local function runStep(Call, Index)
    local Scenario = scenarioOf(Call)
    local Step = Scenario.steps[Index]

    if Step.item and not Utils.hasItem(Step.item) then
        Utils.notify(locale('call_missing_item', missingItemLabel(Step.item)), 'error')
        return
    end

    if Index == 1 and not lib.callback.await('ars_ambulancejob:beginEmergencyCall', false, Call.id) then
        Utils.notify(locale('call_unavailable'), 'error')
        return
    end

    local Completed = lib.progressBar({
        duration = Step.duration,
        label = locale(Step.label),
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = Step.anim,
    })

    if not Completed then return end

    if Step.line then Utils.notify(locale(Step.line), 'inform') end

    Call.step = Index + 1

    if Index == #Scenario.steps then finishCall(Call) end
end

local function addPatientTarget(Call)
    local Scenario = scenarioOf(Call)
    local Options = {}

    for Index = 1, #Scenario.steps do
        local Step = Scenario.steps[Index]

        Options[Index] = {
            name = ('ars_ambulancejob_call_%s_%s'):format(Call.id, Index),
            label = locale(Step.label),
            icon = Step.icon,
            distance = Settings.interactDistance,
            canInteract = function()
                return Call.step == Index and not Ambulance.isDead
            end,
            onSelect = function()
                runStep(Call, Index)
            end,
        }
    end

    exports.ox_target:addLocalEntity(Call.ped, Options)
end

local function spawnPatient(Call)
    local Model = lib.requestModel(modelFor(Call))
    if not Model then return end

    local Coords = groundedCoords(Call.coords)
    local Anim = scenarioOf(Call).anim
    local Dict = lib.requestAnimDict(Anim.dict)

    local Ped = CreatePed(4, Model, Coords.x, Coords.y, Coords.z + 1.0, Call.coords.w, false, false)

    SetEntityInvincible(Ped, true)
    SetBlockingOfNonTemporaryEvents(Ped, true)
    SetPedCanRagdoll(Ped, false)
    SetModelAsNoLongerNeeded(Model)
    TaskPlayAnim(Ped, Dict, Anim.clip, 8.0, -8.0, -1, 1, 0.0, false, false, false)
    PlaceObjectOnGroundProperly(Ped)
    FreezeEntityPosition(Ped, true)

    Call.ped = Ped
    addPatientTarget(Call)
end

local function releasePatient(Call, Treated)
    local Ped = Call.ped
    Call.ped = nil

    if not Ped or not DoesEntityExist(Ped) then return end

    exports.ox_target:removeLocalEntity(Ped)

    if not Treated then
        DeleteEntity(Ped)
        return
    end

    FreezeEntityPosition(Ped, false)
    ClearPedTasks(Ped)
    SetPedCanRagdoll(Ped, true)
    TaskWanderStandard(Ped, 10.0, 10)

    SetTimeout(LeaveDelayMs, function()
        if DoesEntityExist(Ped) then DeleteEntity(Ped) end
    end)
end

local function removeCall(CallId)
    local Call = Active[CallId]
    if not Call then return end

    Active[CallId] = nil

    if Call.blip and DoesBlipExist(Call.blip) then RemoveBlip(Call.blip) end

    releasePatient(Call, Call.step > #scenarioOf(Call).steps)
end

local function addCall(Data)
    if Active[Data.id] then return end

    Data.step = 1
    Data.blip = addBlip(Data)
    Active[Data.id] = Data

    return Data
end

local function announceCall(Call)
    lib.notify({
        title = Config.notifyTitle,
        description = locale('call_new', locale(scenarioOf(Call).label), streetLabel(Call.coords)),
        position = 'bottom-right',
        duration = 8000,
        icon = 'fas fa-truck-medical',
        iconColor = '#FEBD69',
    })

    PlaySound(-1, 'Event_Start_Text', 'GTAO_FM_Events_Soundset')
end

local function syncCalls()
    if not Framework.hasJob(Config.emsJobs) then
        for CallId in pairs(Active) do removeCall(CallId) end
        return
    end

    local Remote = lib.callback.await('ars_ambulancejob:getEmergencyCalls', false) or {}
    local Known = {}

    for Index = 1, #Remote do
        Known[Remote[Index].id] = true
        addCall(Remote[Index])
    end

    for CallId in pairs(Active) do
        if not Known[CallId] then removeCall(CallId) end
    end
end

local function updatePatients()
    local Origin = GetEntityCoords(cache.ped)

    for _, Call in pairs(Active) do
        local Distance = #(Origin - vector3(Call.coords.x, Call.coords.y, Call.coords.z))

        if not Call.ped and Distance <= Settings.spawnDistance then
            spawnPatient(Call)
        elseif Call.ped and Distance > Settings.spawnDistance + DespawnPadding then
            releasePatient(Call, false)
        end
    end
end

RegisterNetEvent('ars_ambulancejob:emergencyCall', function(Data)
    if not Framework.hasJob(Config.emsJobs) then return end

    local Call = addCall(Data)

    if Call then announceCall(Call) end
end)

RegisterNetEvent('ars_ambulancejob:emergencyCallClosed', removeCall)

CreateThread(function()
    while true do
        Wait(SyncIntervalMs)
        syncCalls()
    end
end)

CreateThread(function()
    while true do
        Wait(ProximityIntervalMs)
        updatePatients()
    end
end)

AddEventHandler('onResourceStop', function(Resource)
    if Resource ~= GetCurrentResourceName() then return end

    for CallId in pairs(Active) do removeCall(CallId) end
end)
