local stretcherModel = joaat(Config.stretcher.model)
local emsVehicleModels = {}

local usingStretcher = false
local currentStretcher = nil
local patientServerId = nil

for name in pairs(Config.emsVehicles) do
    emsVehicleModels[joaat(name)] = true
end

local function isEmsVehicle(vehicle)
    return emsVehicleModels[GetEntityModel(vehicle)] == true
end

local function entityFromTarget(data)
    return type(data) == 'number' and data or data.entity
end

local function holdStretcher(stretcher)
    usingStretcher = true
    currentStretcher = stretcher

    local ped = cache.ped
    local dict = lib.requestAnimDict('anim@heists@box_carry@')

    AttachEntityToEntity(stretcher, ped, GetPedBoneIndex(ped, 28422), -0.1681134, -1.0495786, -0.516176, 12.740244, 4.5091583, -8.204815, true, true, false, true, 1, true)
    SetEntityAsMissionEntity(stretcher, true, true)

    lib.showTextUI(locale('control_drop_stretcher'), {
        position = 'top-center',
        icon = 'bed',
        style = {
            borderRadius = '8px',
            backgroundColor = '#48BB78',
            color = 'white',
            padding = '10px',
            boxShadow = '0 2px 4px rgba(0, 0, 0, 0.2)',
        },
    })

    CreateThread(function()
        while IsEntityAttachedToEntity(stretcher, ped) do
            if IsControlJustPressed(0, 47) then
                DetachEntity(stretcher, true, true)
                ClearPedTasks(ped)
                PlaceObjectOnGroundProperly(stretcher)
                FreezeEntityPosition(stretcher, true)
                usingStretcher = false
                lib.hideTextUI()
            end

            Wait(1)
        end
    end)

    while IsEntityAttachedToEntity(stretcher, ped) do
        if not IsEntityPlayingAnim(ped, dict, 'idle', 3) then
            TaskPlayAnim(ped, dict, 'idle', 8.0, 8.0, -1, 50, 0, false, false, false)
        end

        Wait(1000)
    end
end

local function takeStretcher()
    local coords = GetEntityCoords(cache.ped)
    local model = lib.requestModel(Config.stretcher.model)
    local stretcher = CreateObject(model, coords.x, coords.y, coords.z, true, false, false)

    SetModelAsNoLongerNeeded(model)
    holdStretcher(stretcher)
end

local function returnStretcher()
    ClearPedTasks(cache.ped)
    DeleteEntity(currentStretcher)

    currentStretcher = nil
    usingStretcher = false
    lib.hideTextUI()
end

local function setPatientOnStretcher(toggle, patientPed)
    TriggerServerEvent('ars_ambulancejob:putOnStretcher', Utils.serverIdFromPed(patientPed), toggle)
    patientServerId = toggle and Utils.serverIdFromPed(patientPed) or nil
end

local function stretcherCount(vehicle)
    return Entity(vehicle).state.stretcher or Config.stretcher.perVehicle
end

RegisterNetEvent('ars_ambulancejob:putOnStretcher', function(toggle)
    local ped = cache.ped

    if not toggle then
        DetachEntity(ped)
        ClearPedTasks(ped)
        return
    end

    local coords = GetEntityCoords(ped)
    local stretcher = GetClosestObjectOfType(coords.x, coords.y, coords.z, 5.5, stretcherModel, false)
    if stretcher == 0 then return end

    AttachEntityToEntity(ped, stretcher, 0, 0.0, 0.0, 1.0, 195.0, 0.0, 180.0, 0.0, false, false, false, false, 2)
end)

RegisterNetEvent('ars_ambulancejob:togglePatientVehicle', function(vehicleNetId)
    local ped = cache.ped
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not DoesEntityExist(vehicle) then return end

    DetachEntity(ped)

    if cache.vehicle then
        TaskLeaveVehicle(ped, cache.vehicle, 16)
        return
    end

    local seats = GetVehicleMaxNumberOfPassengers(vehicle)
    local seat = nil

    if seats >= 4 and IsVehicleSeatFree(vehicle, 3) then
        seat = 3
    else
        for i = 0, seats - 1 do
            if IsVehicleSeatFree(vehicle, i) then
                seat = i
                break
            end
        end
    end

    if seat then TaskWarpPedIntoVehicle(ped, vehicle, seat) end
end)

local function vehicleOptions()
    return {
        {
            name = 'ars_ambulancejob_take_stretcher',
            icon = 'fa-solid fa-car-side',
            label = locale('take_stretcher'),
            groups = Config.emsJobs,
            canInteract = function(entity)
                return isEmsVehicle(entity) and not usingStretcher and not Ambulance.isDead
            end,
            onSelect = function(data)
                local vehicle = entityFromTarget(data)
                local count = stretcherCount(vehicle)

                if count < 1 then
                    Utils.notify(locale('no_stretcher_found'), 'error')
                    return
                end

                Entity(vehicle).state.stretcher = count - 1
                takeStretcher()
            end,
        },
        {
            name = 'ars_ambulancejob_put_stretcher',
            icon = 'fa-solid fa-car-side',
            label = locale('put_stretcher'),
            groups = Config.emsJobs,
            canInteract = function(entity)
                return isEmsVehicle(entity) and usingStretcher and not patientServerId and not Ambulance.isDead
            end,
            onSelect = function(data)
                local vehicle = entityFromTarget(data)
                local count = stretcherCount(vehicle)

                if count >= Config.stretcher.perVehicle then
                    Utils.notify(locale('stretcher_limit_reached'), 'error')
                    return
                end

                Entity(vehicle).state.stretcher = count + 1
                returnStretcher()
            end,
        },
        {
            name = 'ars_ambulancejob_put_patient_in_vehicle',
            icon = 'fa-solid fa-car-side',
            label = locale('put_patient_in_vehicle'),
            groups = Config.emsJobs,
            canInteract = function(entity)
                return isEmsVehicle(entity) and usingStretcher and patientServerId ~= nil and not Ambulance.isDead
            end,
            onSelect = function(data)
                local vehicle = entityFromTarget(data)

                TriggerServerEvent('ars_ambulancejob:togglePatientVehicle', patientServerId, NetworkGetNetworkIdFromEntity(vehicle))

                Entity(vehicle).state.patient = patientServerId
                patientServerId = nil
            end,
        },
        {
            name = 'ars_ambulancejob_take_patient_from_vehicle',
            icon = 'fa-solid fa-car-side',
            label = locale('take_patient_from_vehicle'),
            groups = Config.emsJobs,
            canInteract = function(entity)
                return isEmsVehicle(entity) and Entity(entity).state.patient ~= nil and not Ambulance.isDead
            end,
            onSelect = function(data)
                local vehicle = entityFromTarget(data)
                local patient = Entity(vehicle).state.patient

                TriggerServerEvent('ars_ambulancejob:togglePatientVehicle', patient, NetworkGetNetworkIdFromEntity(vehicle))
                Entity(vehicle).state.patient = nil

                Wait(150)
                setPatientOnStretcher(true, Utils.pedFromServerId(patient))
            end,
        },
    }
end

local function stretcherOptions()
    return {
        {
            name = 'ars_ambulancejob_stretcher_model',
            label = locale('take_stretcher'),
            icon = 'fa-solid fa-bed',
            groups = Config.emsJobs,
            distance = 3.0,
            canInteract = function()
                return not usingStretcher and not Ambulance.isDead
            end,
            onSelect = function(data)
                holdStretcher(entityFromTarget(data))
            end,
        },
        {
            name = 'ars_ambulancejob_remove_from_stretcher',
            icon = 'fa-solid fa-car-side',
            label = locale('remove_from_stretcher'),
            groups = Config.emsJobs,
            distance = 3.0,
            canInteract = function(entity)
                local _, ped = lib.getClosestPlayer(GetEntityCoords(entity), 2.0, false)

                return ped ~= nil and GetEntityAttachedTo(ped) == entity and not Ambulance.isDead
            end,
            onSelect = function(data)
                local _, ped = lib.getClosestPlayer(GetEntityCoords(data.entity), 2.0, false)

                if ped and GetEntityAttachedTo(ped) == data.entity then
                    setPatientOnStretcher(false, ped)
                end
            end,
        },
    }
end

exports.ox_target:addGlobalVehicle(vehicleOptions())
exports.ox_target:addModel({ stretcherModel }, stretcherOptions())

exports.ox_target:addGlobalPlayer({
    {
        name = 'ars_ambulancejob_put_on_stretcher',
        icon = 'fas fa-bed',
        label = locale('put_on_stretcher'),
        groups = Config.emsJobs,
        distance = 3.0,
        canInteract = function(entity)
            local coords = GetEntityCoords(entity)
            local stretcher = GetClosestObjectOfType(coords.x, coords.y, coords.z, 5.5, stretcherModel, false)

            return stretcher ~= 0 and not Ambulance.isDead
        end,
        onSelect = function(data)
            setPatientOnStretcher(true, entityFromTarget(data))
        end,
    },
})
