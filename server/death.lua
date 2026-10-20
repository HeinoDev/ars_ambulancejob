local ox_inventory = exports.ox_inventory
local MaxInjuryCauseLength = 24
local InjurySyncIntervalMs = 200
local RespawnToleranceMs = 5000

local deathClips = {}

for _, anim in pairs(Config.animations) do
    deathClips[anim.clip] = true
end

local function sanitizeInjuries(injuries)
    local clean = {}
    if type(injuries) ~= 'table' then return clean end

    for boneId, injury in pairs(injuries) do
        local part = BodyPartsById[boneId]

        if part and type(injury) == 'table' then
            local value = math.floor(math.max(0, math.min(100, tonumber(injury.value) or 0)))
            local cause = type(injury.cause) == 'string' and #injury.cause <= MaxInjuryCauseLength and injury.cause or 'not found'

            clean[boneId] = {
                bone = boneId,
                label = part.label,
                desc = part.levels[tostring(value)] or part.levels.default,
                value = value,
                cause = cause,
            }
        end
    end

    return clean
end

local function setDeathState(source, isDead)
    local state = Player(source).state

    state:set('dead', isDead, true)
    state:set('isDead', isDead, true)

    if not isDead then
        state:set('deathEmote', false, true)
    end
end

local function markDead(source, record, weapon)
    record.known = true
    record.isDead = true
    record.deathTime = GetGameTimer()
    record.killedBy = weapon

    Framework.setDead(source, true)
    setDeathState(source, true)

    AmbulanceLogs.Death(source, 'Died')
    TriggerEvent('ars_ambulancejob:playerDied', source, weapon)
    Ambulance.hook('onPlayerDied', source, weapon)
end

local function markAlive(source, record)
    record.known = true
    record.isDead = false
    record.killedBy = false

    Framework.setDead(source, false)
    setDeathState(source, false)

    TriggerEvent('ars_ambulancejob:playerRevived', source)
    Ambulance.hook('onPlayerRevived', source)
end

RegisterNetEvent('ars_ambulancejob:updateDeathStatus', function(death)
    local source = source
    if type(death) ~= 'table' then return end

    local record = Ambulance.record(source)
    local isDead = death.isDead == true

    if isDead then
        if not record.isDead then
            markDead(source, record, type(death.weapon) == 'number' and death.weapon or false)
        end

        return
    end

    if not record.isDead then
        record.known = true
        return
    end

    if not Ambulance.consumeRevivePermission(source) then
        AmbulanceLogs.Suspicious(source, 'Tried to leave the dead state without being revived')
        TriggerClientEvent('ars_ambulancejob:forceDeath', source)
        return
    end

    markAlive(source, record)
end)

RegisterNetEvent('ars_ambulancejob:setDeathEmote', function(clip)
    local source = source
    if not deathClips[clip] or not Ambulance.isDead(source) then return end

    Player(source).state:set('deathEmote', clip, true)
end)

RegisterNetEvent('ars_ambulancejob:syncInjuries', function(injuries)
    local source = source
    local record = Ambulance.record(source)
    local now = GetGameTimer()

    if now - record.lastInjurySync < InjurySyncIntervalMs then return end
    record.lastInjurySync = now

    Player(source).state:set('injuries', sanitizeInjuries(injuries), true)
end)

local function clearInventoryOnRespawn(source)
    if not Config.death.removeItemsOnRespawn then return end

    ox_inventory:ClearInventory(source, Config.death.keepItemsOnRespawn)
end

lib.callback.register('ars_ambulancejob:requestRespawn', function(source)
    local record = Ambulance.record(source)
    if not record.isDead then return false end

    local required = Config.death.respawnMinutes * 60000 - RespawnToleranceMs

    if GetGameTimer() - record.deathTime < required then
        AmbulanceLogs.Suspicious(source, 'Tried to respawn before the respawn timer ran out')
        return false
    end

    clearInventoryOnRespawn(source)
    Ambulance.allowRevive(source)
    AmbulanceLogs.Respawn(source, 'Respawned at the hospital')
    Ambulance.hook('onPlayerRespawned', source)

    return true
end)

lib.callback.register('ars_ambulancejob:getDeathStatus', function(source)
    local record = Ambulance.players[source]

    if record and record.known then
        return { isDead = record.isDead }
    end

    return { isDead = Framework.wasDead(source) }
end)

lib.callback.register('ars_ambulancejob:getPatientData', function(source, target)
    if not Ambulance.isMedic(source) then return false end

    target = tonumber(target)
    if not Ambulance.isNearby(source, target, Config.maxTreatDistance * 2) then return false end

    local record = Ambulance.record(target)

    return {
        injuries = Player(target).state.injuries or false,
        status = { isDead = record.isDead },
        killedBy = record.killedBy,
    }
end)

lib.callback.register('ars_ambulancejob:getMedicsOnline', function()
    return Ambulance.countMedics()
end)
