local bagModel = joaat(Config.medicBag.prop)
local PickupAnimMs = 900

local function playPickupAnim(ped)
    local dict = lib.requestAnimDict('pickup_object')

    TaskPlayAnim(ped, dict, 'pickup_low', 8.0, 8.0, 1000, 50, 0, false, false, false)
    Wait(PickupAnimMs)
end

local function awaitNetworked(entity)
    local attempts = 0

    while not NetworkGetEntityIsNetworked(entity) and attempts < 50 do
        Wait(50)
        attempts = attempts + 1
    end

    return NetworkGetEntityIsNetworked(entity)
end

local function placeMedicalBag()
    local ped = cache.ped
    local model = lib.requestModel(Config.medicBag.prop)
    local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.5, 0.0)

    playPickupAnim(ped)

    local bag = CreateObjectNoOffset(model, coords.x, coords.y, coords.z, true, false)
    SetModelAsNoLongerNeeded(model)
    PlaceObjectOnGroundProperly(bag)

    if awaitNetworked(bag) then
        TriggerServerEvent('ars_ambulancejob:registerMedicalBag', NetworkGetNetworkIdFromEntity(bag))
    else
        DeleteEntity(bag)
    end
end

local function openMedicalBag(entity)
    TaskStartScenarioInPlace(cache.ped, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)

    local stash = lib.callback.await('ars_ambulancejob:openMedicalBag', false, NetworkGetNetworkIdFromEntity(entity))

    if stash then
        exports.ox_inventory:openInventory('stash', stash)
    else
        ClearPedTasks(cache.ped)
    end
end

local function pickupMedicalBag(entity)
    playPickupAnim(cache.ped)
    TriggerServerEvent('ars_ambulancejob:pickupMedicalBag', NetworkGetNetworkIdFromEntity(entity))
    ClearPedTasks(cache.ped)
end

RegisterNetEvent('ars_ambulancejob:placeMedicalBag', placeMedicalBag)

exports.ox_target:addModel({ bagModel }, {
    {
        name = 'ars_ambulancejob_open_bag',
        label = locale('open_medical_bag'),
        icon = 'fa-solid fa-suitcase',
        groups = Config.emsJobs,
        distance = 3.0,
        onSelect = function(data)
            openMedicalBag(data.entity)
        end,
    },
    {
        name = 'ars_ambulancejob_pickup_bag',
        label = locale('pickup_medical_bag'),
        icon = 'fa-solid fa-xmark',
        groups = Config.emsJobs,
        distance = 3.0,
        onSelect = function(data)
            pickupMedicalBag(data.entity)
        end,
    },
})
