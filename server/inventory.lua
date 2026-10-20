local ox_inventory = exports.ox_inventory
local BagRegisterTimeoutMs = 15000
local BagReplicationAttempts = 20

local medicBags = {}
local pendingBags = {}

local function bagModel()
    return joaat(Config.medicBag.prop)
end

local function resolveBag(netId)
    if type(netId) ~= 'number' then return nil end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return nil end
    if GetEntityModel(entity) ~= bagModel() then return nil end

    return entity
end

local function awaitBag(netId)
    for _ = 1, BagReplicationAttempts do
        local entity = resolveBag(netId)
        if entity then return entity end

        Wait(100)
    end
end

local function registerStashes()
    for _, hospital in pairs(Hospitals) do
        for id, stash in pairs(hospital.stash) do
            local groups = {}

            for i = 1, #Config.emsJobs do
                groups[Config.emsJobs[i]] = stash.minGrade or 0
            end

            ox_inventory:RegisterStash(id, stash.label, stash.slots, stash.weight, false, groups, stash.pos)
        end
    end
end

local function registerBagHook()
    ox_inventory:registerHook('swapItems', function(payload)
        if type(payload.fromSlot) == 'table' and payload.fromSlot.name == Config.items.medicalBag then return false end
    end, { inventoryFilter = { '^medicalBag_' } })
end

local function setupInventory()
    registerStashes()
    registerBagHook()
end

CreateThread(function()
    while GetResourceState('ox_inventory') ~= 'started' do Wait(100) end

    setupInventory()
end)

AddEventHandler('onServerResourceStart', function(resource)
    if resource == 'ox_inventory' then setupInventory() end
end)

Framework.registerUsableItem(Config.items.medicalBag, function(source)
    if not Ambulance.isMedic(source) or Ambulance.isDead(source) or pendingBags[source] then return end

    if not ox_inventory:RemoveItem(source, Config.items.medicalBag, 1) then return end

    pendingBags[source] = true
    TriggerClientEvent('ars_ambulancejob:placeMedicalBag', source)

    SetTimeout(BagRegisterTimeoutMs, function()
        if not pendingBags[source] then return end

        pendingBags[source] = nil
        ox_inventory:AddItem(source, Config.items.medicalBag, 1)
    end)
end)

Framework.registerUsableItem(Config.items.medkit, function(source)
    if Ambulance.isDead(source) then return end

    if not ox_inventory:RemoveItem(source, Config.items.medkit, 1) then return end

    TriggerClientEvent('ars_ambulancejob:useMedkit', source)
    AmbulanceLogs.Item(source, 'Used a medkit')
end)

RegisterNetEvent('ars_ambulancejob:registerMedicalBag', function(netId)
    local source = source
    if not pendingBags[source] then return end

    local entity = awaitBag(netId)

    if not entity or not Ambulance.isNearCoords(source, GetEntityCoords(entity), Config.medicBag.maxDistance * 2) then
        AmbulanceLogs.Suspicious(source, 'Registered an invalid medical bag')
        return
    end

    pendingBags[source] = nil
    medicBags[netId] = source
    AmbulanceLogs.Item(source, 'Placed a medical bag')
end)

RegisterNetEvent('ars_ambulancejob:pickupMedicalBag', function(netId)
    local source = source
    if not Ambulance.isMedic(source) or not medicBags[netId] then return end

    local entity = resolveBag(netId)

    if not entity then
        medicBags[netId] = nil
        return
    end

    if not Ambulance.isNearCoords(source, GetEntityCoords(entity), Config.medicBag.maxDistance) then
        AmbulanceLogs.Suspicious(source, 'Tried to pick up a medical bag from a distance')
        return
    end

    if not ox_inventory:CanCarryItem(source, Config.items.medicalBag, 1) then
        Ambulance.notify(source, locale('cannot_carry_bag'), 'error')
        return
    end

    medicBags[netId] = nil
    DeleteEntity(entity)
    ox_inventory:AddItem(source, Config.items.medicalBag, 1)
    AmbulanceLogs.Item(source, 'Picked up a medical bag')
end)

lib.callback.register('ars_ambulancejob:openMedicalBag', function(source, netId)
    if not Ambulance.isMedic(source) or not medicBags[netId] then return false end

    local entity = resolveBag(netId)
    if not entity or not Ambulance.isNearCoords(source, GetEntityCoords(entity), Config.medicBag.maxDistance) then return false end

    local license = GetPlayerIdentifierByType(source, 'license')
    if not license then return false end

    local stashId = 'medicalBag_' .. license:gsub('license:', '')

    ox_inventory:RegisterStash(stashId, 'Medical Bag', Config.medicBag.stashSlots, Config.medicBag.stashWeight)

    return stashId
end)

AddEventHandler('playerDropped', function()
    pendingBags[source] = nil
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for netId in pairs(medicBags) do
        local entity = NetworkGetEntityFromNetworkId(netId)
        if entity and entity ~= 0 and DoesEntityExist(entity) then DeleteEntity(entity) end
    end
end)
