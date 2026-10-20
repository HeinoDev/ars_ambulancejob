local function reviveDurationMs()
    local revive = Config.revive

    return revive.introMs + revive.compressions * revive.compressionMs + revive.finishMs
end

local function playReviveAnimations(medicId, targetId)
    local medicPed = GetPlayerPed(medicId)
    local heading = GetEntityHeading(medicPed)
    local radians = math.rad(heading)

    local animData = {
        heading = heading,
        coords = GetEntityCoords(medicPed),
        location = vector3(-math.sin(radians), math.cos(radians), 0.0),
    }

    animData.anim = 'medic'
    TriggerClientEvent('ars_ambulancejob:playReviveAnim', medicId, animData)

    animData.anim = 'patient'
    TriggerClientEvent('ars_ambulancejob:playReviveAnim', targetId, animData)
end

local function finishRevive(medicId, targetId)
    if not Ambulance.isOnline(targetId) then return end

    Ambulance.record(targetId).busy = false

    if not Ambulance.isDead(targetId) then return end

    if not Ambulance.isOnline(medicId) or not Ambulance.isNearby(medicId, targetId, Config.maxTreatDistance * 2) then
        TriggerClientEvent('ars_ambulancejob:cancelRevive', targetId)
        return
    end

    Ambulance.heal(targetId, true)
    Ambulance.reward(medicId, Config.rewards.revive, 'reviving a patient')
    AmbulanceLogs.Revive(medicId, ('Revived %s [%s]'):format(GetPlayerName(targetId), targetId))
end

RegisterNetEvent('ars_ambulancejob:reviveTarget', function(targetId)
    local source = source
    targetId = tonumber(targetId)

    if not Ambulance.isMedic(source) or Ambulance.isDead(source) then return end
    if not Ambulance.isOnline(targetId) or targetId == source then return end

    if not Ambulance.isNearby(source, targetId, Config.maxTreatDistance) then
        AmbulanceLogs.Suspicious(source, ('Tried to revive %s from a distance'):format(targetId))
        return
    end

    local target = Ambulance.record(targetId)
    if not target.isDead or target.busy then return end

    if not Ambulance.consumeItem(source, Config.items.defibrillator, Config.durabilityPerUse) then
        Ambulance.notify(source, locale('not_enough_defibrillator'), 'error')
        return
    end

    target.busy = true
    playReviveAnimations(source, targetId)

    SetTimeout(reviveDurationMs(), function()
        finishRevive(source, targetId)
    end)
end)

RegisterNetEvent('ars_ambulancejob:treatInjury', function(targetId, bone)
    local source = source
    targetId = tonumber(targetId)

    if not Ambulance.isMedic(source) or Ambulance.isDead(source) then return end
    if type(bone) ~= 'string' or not BodyPartsById[bone] then return end
    if not Ambulance.isOnline(targetId) then return end

    if not Ambulance.isNearby(source, targetId, Config.maxTreatDistance) then
        AmbulanceLogs.Suspicious(source, ('Tried to treat %s from a distance'):format(targetId))
        return
    end

    local injuries = Player(targetId).state.injuries
    local injury = injuries and injuries[bone]
    if not injury then return end

    local item = Ambulance.treatmentItemFor(injury.cause)

    if not Ambulance.consumeItem(source, item, Config.durabilityPerUse) then
        Ambulance.notify(source, locale('not_enough_' .. item), 'error')
        return
    end

    TriggerClientEvent('ars_ambulancejob:healPlayer', targetId, { injury = true, bone = bone })
    Ambulance.reward(source, Config.rewards.injuryTreated, 'treating an injury')
    AmbulanceLogs.Treatment(source, ('Treated %s on %s [%s]'):format(bone, GetPlayerName(targetId), targetId))
    Ambulance.hook('onInjuryTreated', source, targetId, bone)
end)
