Ambulance = {
    players = {},
}

local ox_inventory = exports.ox_inventory
local ReviveWindowMs = 60000

function Ambulance.record(source)
    local record = Ambulance.players[source]

    if not record then
        record = { known = false, isDead = false, deathTime = 0, reviveUntil = 0, killedBy = false, busy = false, lastInjurySync = 0 }
        Ambulance.players[source] = record
    end

    return record
end

function Ambulance.isMedic(source)
    return Framework.hasJob(source, Config.emsJobs)
end

function Ambulance.isOnDutyMedic(source)
    return Ambulance.isMedic(source) and Framework.isOnDuty(source)
end

function Ambulance.isOnline(target)
    target = tonumber(target)

    return target ~= nil and target > 0 and GetPlayerName(target) ~= nil
end

function Ambulance.isDead(target)
    target = tonumber(target)
    if not Ambulance.isOnline(target) then return false end

    local record = Ambulance.players[target]

    return record ~= nil and record.isDead
end

function Ambulance.isNearby(source, target, maxDistance)
    target = tonumber(target)
    if not Ambulance.isOnline(target) or not Ambulance.isOnline(source) then return false end

    local sourcePed, targetPed = GetPlayerPed(source), GetPlayerPed(target)
    if sourcePed == 0 or targetPed == 0 then return false end

    return #(GetEntityCoords(sourcePed) - GetEntityCoords(targetPed)) <= maxDistance
end

function Ambulance.isNearCoords(source, coords, maxDistance)
    local ped = GetPlayerPed(source)
    if ped == 0 then return false end

    return #(GetEntityCoords(ped) - vector3(coords.x, coords.y, coords.z)) <= maxDistance
end

function Ambulance.countMedics()
    local count = 0
    local players = GetPlayers()

    for i = 1, #players do
        if Ambulance.isOnDutyMedic(tonumber(players[i])) then count = count + 1 end
    end

    return count
end

function Ambulance.hook(name, ...)
    local handler = Config.serverHooks[name]
    if not handler then return end

    local ok, err = pcall(handler, ...)

    if not ok then
        print(('^1[ars_ambulancejob] server hook %s failed: %s^7'):format(name, tostring(err)))
    end
end

function Ambulance.notify(target, message, notifyType)
    TriggerClientEvent('ars_ambulancejob:showNotification', target, message, notifyType)
end

function Ambulance.allowRevive(target)
    Ambulance.record(target).reviveUntil = GetGameTimer() + ReviveWindowMs
end

function Ambulance.consumeRevivePermission(target)
    local record = Ambulance.record(target)
    local allowed = GetGameTimer() <= record.reviveUntil

    record.reviveUntil = 0

    return allowed
end

function Ambulance.heal(target, revive)
    if revive or Ambulance.isDead(target) then
        Ambulance.allowRevive(target)
    end

    TriggerClientEvent('ars_ambulancejob:healPlayer', target, { revive = revive == true, heal = revive ~= true })
end

function Ambulance.reward(source, amount, reason)
    amount = tonumber(amount) or 0
    if amount <= 0 then return end

    if Framework.addMoney(source, Config.rewards.account, amount) then
        AmbulanceLogs.Item(source, ('Received $%s for %s'):format(amount, reason))
    end
end

function Ambulance.consumeItem(source, name, percent)
    local slots = ox_inventory:GetSlotsWithItem(source, name)
    if not slots then return false end

    for i = 1, #slots do
        local slot = slots[i]
        local durability = slot.metadata and slot.metadata.durability or 100

        if durability >= percent then
            local remaining = durability - percent

            if remaining <= 0 then
                ox_inventory:RemoveItem(source, name, 1, nil, slot.slot)
            else
                ox_inventory:SetDurability(source, slot.slot, remaining)
            end

            return true
        end
    end

    return false
end

function Ambulance.treatmentItemFor(cause)
    return Config.treatmentItems[cause] or Config.treatmentItems.default
end

exports('isPlayerDead', Ambulance.isDead)
exports('isMedic', Ambulance.isMedic)
exports('getMedicsOnline', Ambulance.countMedics)

exports('revivePlayer', function(target)
    target = tonumber(target)
    if not Ambulance.isOnline(target) then return false end

    Ambulance.heal(target, true)

    return true
end)

exports('healPlayer', function(target)
    target = tonumber(target)
    if not Ambulance.isOnline(target) then return false end

    Ambulance.heal(target, false)

    return true
end)

AddEventHandler('playerDropped', function()
    local source = source

    Ambulance.players[source] = nil
end)
