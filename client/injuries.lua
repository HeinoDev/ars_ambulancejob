local InjurySyncDelay = 250
local HealPerTreatment = 10
local DamagePerHit = 10

local syncPending = false

function Ambulance.syncInjuries()
    LocalPlayer.state:set('injuries', Ambulance.injuries, false)

    if syncPending then return end
    syncPending = true

    SetTimeout(InjurySyncDelay, function()
        syncPending = false
        TriggerServerEvent('ars_ambulancejob:syncInjuries', Ambulance.injuries)
    end)
end

function Ambulance.treatInjury(bone)
    if not Ambulance.injuries[bone] then return end

    Ambulance.injuries[bone] = nil
    Ambulance.syncInjuries()

    local ped = cache.ped
    SetEntityHealth(ped, math.min(GetEntityHealth(ped) + HealPerTreatment, GetEntityMaxHealth(ped)))
end

function Ambulance.updateInjuries(victim, weapon)
    local _, lastDamagedBone = GetPedLastDamageBone(victim)
    local bodyPart = BodyParts[tostring(lastDamagedBone)]
    if not bodyPart then return end

    local injury = Ambulance.injuries[bodyPart.id]

    if not injury then
        local weaponInfo = Weapons[weapon]

        Ambulance.injuries[bodyPart.id] = {
            bone = bodyPart.id,
            label = bodyPart.label,
            desc = bodyPart.levels.default,
            value = Ambulance.isDead and 100 or DamagePerHit,
            cause = weaponInfo and weaponInfo[2] or 'not found',
        }
    else
        injury.value = math.min(injury.value + DamagePerHit, 100)
        injury.desc = bodyPart.levels[tostring(injury.value)] or bodyPart.levels.default
    end

    Ambulance.syncInjuries()
end
