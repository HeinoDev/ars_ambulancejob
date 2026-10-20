Paramedic = {}

local peds = {}
local zones = {}

local function treatmentSequence(hospital)
    local ped = cache.ped
    local dict = lib.requestAnimDict('anim@gangops@morgue@table@')

    Utils.fadeOut(500)
    Wait(1000)
    Utils.fadeIn(300)

    local bed = Utils.findFreeBed(hospital)

    SetEntityCoords(ped, bed.bedPoint.x, bed.bedPoint.y, bed.bedPoint.z)
    SetEntityHeading(ped, bed.bedPoint.w)
    TaskPlayAnim(ped, dict, 'body_search', 2.0, 2.0, -1, 1, 0, false, false, false)

    lib.progressBar({
        duration = Config.paramedic.treatmentSeconds * 1000,
        label = locale('getting_treated'),
        useWhileDead = false,
        canCancel = false,
        disable = { car = true, move = true },
    })

    if Config.paramedic.revive then
        Ambulance.stopDeath()
    else
        Utils.fadeOut(500)
        Wait(1000)
        Utils.fadeIn(300)
        Ambulance.healSelf()
    end

    Utils.notify(locale('treated_by_paramedic'))
end

local function requestTreatment(key, hospital)
    local completed = lib.progressBar({
        duration = 1500,
        label = locale('being_examined'),
        useWhileDead = true,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
    })

    if not completed then return end

    local allowed, reason = lib.callback.await('ars_ambulancejob:requestParamedicTreatment', false, key)

    if not allowed then
        Utils.notify(locale(reason or 'invalid_request'), 'error')
        return
    end

    treatmentSequence(hospital)
end

local function isAvailable()
    return Config.paramedic.alwaysAvailable or (GlobalState.emsOnDuty or 0) <= Config.paramedic.maxMedicsOnDuty
end

local function spawnParamedic(key, hospital)
    local ped = Utils.createPed(hospital.paramedic.model, hospital.paramedic.pos)
    if not ped then return end

    peds[key] = ped

    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'ars_ambulancejob_paramedic_' .. key,
            label = locale('paramedic_interact_label'),
            icon = 'fa-solid fa-ambulance',
            distance = 3.0,
            onSelect = function()
                requestTreatment(key, hospital)
            end,
        },
    })
end

local function syncParamedic(key)
    local hospital = zones[key]
    if not hospital then return end

    if isAvailable() and not peds[key] then
        spawnParamedic(key, hospital)
    elseif not isAvailable() and peds[key] then
        Paramedic.unload(key)
    end
end

function Paramedic.load(key, hospital)
    zones[key] = hospital
    syncParamedic(key)
end

function Paramedic.unload(key)
    zones[key] = nil
    Utils.deletePed(peds[key])
    peds[key] = nil
end

AddStateBagChangeHandler('emsOnDuty', 'global', function()
    for key in pairs(zones) do
        syncParamedic(key)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for key in pairs(peds) do
        Paramedic.unload(key)
    end
end)
