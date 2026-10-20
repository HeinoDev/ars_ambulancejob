local animations = Config.animations
local respawnTimeMs = Config.death.respawnMinutes * 60000
local MedicCountRefreshMs = 30000
local RespawnControl = 47

local function setLocalDeathState(isDead)
    LocalPlayer.state:set('dead', isDead, false)
    LocalPlayer.state:set('isDead', isDead, false)

    if not isDead then
        LocalPlayer.state:set('deathEmote', false, false)
    end
end

local function hideDeathScreen()
    SendNUIMessage({ action = 'hideDeath' })
end

local function deathScreenLabels()
    return {
        unconscious = locale('death_unconscious'),
        press = locale('death_press'),
        toRespawn = locale('death_to_respawn'),
        respawnIn = locale('death_respawn_in'),
        medicsOnline = locale('death_medics_online'),
    }
end

function Ambulance.healSelf()
    local ped = cache.ped

    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)

    Ambulance.injuries = {}
    Ambulance.syncInjuries()

    Framework.healStatus()
end

function Ambulance.stopDeath()
    local vehicle, seat = cache.vehicle, cache.seat
    local coords = GetEntityCoords(cache.ped)

    Ambulance.isDead = false
    Ambulance.gettingRevived = false
    hideDeathScreen()

    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(cache.ped), false, false)
    TriggerServerEvent('ars_ambulancejob:updateDeathStatus', { isDead = false })

    local ped = PlayerPedId()

    if vehicle then
        SetPedIntoVehicle(ped, vehicle, seat)
    end

    ClearPedBloodDamage(ped)
    SetEntityInvincible(ped, false)
    SetEveryoneIgnorePlayer(cache.playerId, false)
    ClearPedTasks(ped)
    AnimpostfxStopAll()

    setLocalDeathState(false)
    Ambulance.distressCallTime = nil

    Framework.playerSpawned()
    Ambulance.healSelf()
    Config.hooks.onRevive()
end

local function playDeathEffects()
    if not Config.death.extraEffects then return end

    ShakeGameplayCam('DEATH_FAIL_IN_EFFECT_SHAKE', 1.0)
    AnimpostfxPlay('DeathFailOut', 0, true)
    Wait(4000)
    Utils.fadeOut(200)
    Wait(800)
    Utils.fadeIn(400)
end

local function respawn()
    local allowed = lib.callback.await('ars_ambulancejob:requestRespawn', false)

    if not allowed then
        Utils.notify(locale('respawn_denied'), 'error')
        return
    end

    local ped = cache.ped
    local hospital = Utils.getClosestHospital()

    lib.requestAnimDict('anim@gangops@morgue@table@')
    lib.requestAnimDict('switch@franklin@bed')
    Utils.fadeOut(800)
    Config.hooks.onRespawn()

    local bed = Utils.findFreeBed(hospital)

    Ambulance.respawning = true

    SetEntityCoords(ped, bed.bedPoint.x, bed.bedPoint.y, bed.bedPoint.z)
    SetEntityHeading(ped, bed.bedPoint.w)
    TaskPlayAnim(ped, 'anim@gangops@morgue@table@', 'body_search', 2.0, 2.0, -1, 1, 0, false, false, false)
    FreezeEntityPosition(ped, true)

    Utils.fadeIn(300)
    SetEntityCoords(ped, bed.bedPoint.x, bed.bedPoint.y, bed.bedPoint.z - 1.0)
    FreezeEntityPosition(ped, false)
    SetEntityHeading(ped, bed.bedPoint.w + 90.0)
    TaskPlayAnim(ped, 'switch@franklin@bed', 'sleep_getup_rubeyes', 1.0, 1.0, -1, 8, -1, 0, 0, 0)

    Ambulance.stopDeath()
    ClearPedTasks(PlayerPedId())
    SetEntityCoords(PlayerPedId(), bed.spawnPoint.x, bed.spawnPoint.y, bed.spawnPoint.z)

    Ambulance.respawning = false
end

local function confirmRespawn()
    local confirmation = lib.alertDialog({
        header = locale('death_screen_confirm_respawn_header'),
        content = locale('death_screen_confirm_respawn_content'),
        centered = true,
        cancel = true,
    })

    if confirmation == 'confirm' then respawn() end
end

local function runDeathLoop(ped)
    local deathTime = GetGameTimer()
    local medics = lib.callback.await('ars_ambulancejob:getMedicsOnline', false) or 0
    local lastMedicsCheck = deathTime
    local lastRemaining = -1
    local screenVisible = false

    while Ambulance.isDead do
        local sleep = 500

        if Ambulance.gettingRevived or Ambulance.respawning then
            if screenVisible then
                screenVisible = false
                hideDeathScreen()
            end
        else
            sleep = 100

            local anim = cache.vehicle and animations.death_car or animations.death_normal

            if not IsEntityPlayingAnim(ped, anim.dict, anim.clip, 3) then
                TaskPlayAnim(ped, anim.dict, anim.clip, 50.0, 8.0, -1, 1, 1.0, false, false, false)
            end

            if LocalPlayer.state.deathEmote ~= anim.clip then
                LocalPlayer.state:set('deathEmote', anim.clip, false)
                TriggerServerEvent('ars_ambulancejob:setDeathEmote', anim.clip)
            end

            local now = GetGameTimer()
            local remaining = math.max(0, math.ceil((respawnTimeMs - (now - deathTime)) / 1000))

            if now - lastMedicsCheck >= MedicCountRefreshMs then
                lastMedicsCheck = now
                medics = lib.callback.await('ars_ambulancejob:getMedicsOnline', false) or medics
            end

            if not screenVisible then
                screenVisible = true
                lastRemaining = remaining
                SendNUIMessage({ action = 'showDeath', remaining = remaining, medics = medics, labels = deathScreenLabels() })
            elseif remaining ~= lastRemaining then
                lastRemaining = remaining
                SendNUIMessage({ action = 'updateDeath', remaining = remaining, medics = medics })
            end

            if remaining == 0 then
                sleep = 0
                EnableControlAction(0, RespawnControl, true)

                if IsControlJustPressed(0, RespawnControl) then confirmRespawn() end
            end
        end

        Wait(sleep)
    end
end

local function startDeath(loggedDead)
    if Ambulance.isDead then return end

    Ambulance.isDead = true
    Config.hooks.onDeath()

    for _, anim in pairs(animations) do
        lib.requestAnimDict(anim.dict)
    end

    if not loggedDead then
        playDeathEffects()
        if not Ambulance.isDead then return end
    end

    CreateThread(function()
        while Ambulance.isDead do
            DisableFirstPersonCamThisFrame()
            Wait(0)
        end
    end)

    local coords = GetEntityCoords(cache.ped)
    local vehicle, seat = cache.vehicle, cache.seat

    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(cache.ped), false, false)

    local ped = PlayerPedId()

    if vehicle then
        SetPedIntoVehicle(ped, vehicle, seat)
    end

    SetEntityInvincible(ped, true)
    SetEntityHealth(ped, 100)
    SetEveryoneIgnorePlayer(cache.playerId, true)

    CreateThread(function()
        runDeathLoop(ped)
    end)
end

function Ambulance.onPlayerLoaded()
    exports.spawnmanager:setAutoSpawn(false)

    local status = lib.callback.await('ars_ambulancejob:getDeathStatus', false)

    if not status or not status.isDead then
        LocalPlayer.state.invBusy = false
        return
    end

    startDeath(true)
    setLocalDeathState(true)
    TriggerServerEvent('ars_ambulancejob:updateDeathStatus', { isDead = true })
    Utils.notify(locale('logged_dead'))
end

RegisterNetEvent('ars_ambulancejob:healPlayer', function(data)
    if type(data) ~= 'table' then return end

    if data.revive or (data.heal and Ambulance.isDead) then
        Ambulance.stopDeath()
    elseif data.injury then
        Ambulance.treatInjury(data.bone)
    elseif data.heal then
        Ambulance.healSelf()
    end
end)

RegisterNetEvent('ars_ambulancejob:forceDeath', function()
    startDeath(true)
    setLocalDeathState(true)
end)

RegisterNetEvent('ars_ambulancejob:useMedkit', function()
    if Ambulance.isDead then return end

    SetEntityHealth(cache.ped, GetEntityMaxHealth(cache.ped))
    ClearPedBloodDamage(cache.ped)
    Utils.notify(locale('medkit_used'), 'success')
end)

AddEventHandler('gameEventTriggered', function(event, data)
    if event ~= 'CEventNetworkEntityDamage' then return end

    local victim, victimDied, weapon = data[1], data[4], data[7]

    if not IsPedAPlayer(victim) or NetworkGetPlayerIndexFromPed(victim) ~= cache.playerId then return end

    local diedNow = victimDied and victimDied ~= 0 and not Ambulance.isDead and (IsPedDeadOrDying(victim, true) or IsPedFatallyInjured(victim))

    if diedNow then
        TriggerServerEvent('ars_ambulancejob:updateDeathStatus', { isDead = true, weapon = weapon })
        setLocalDeathState(true)
        CreateThread(startDeath)
    end

    Ambulance.updateInjuries(victim, weapon)
end)
