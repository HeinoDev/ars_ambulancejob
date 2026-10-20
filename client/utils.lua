Utils = {}

function Utils.notify(message, notifyType)
    Config.hooks.notify(message, notifyType)
end

function Utils.debug(...)
    if not Config.debug then return end

    local args = { ... }

    for i = 1, #args do
        local arg = args[i]
        args[i] = type(arg) == 'table' and json.encode(arg, { sort_keys = true, indent = true }) or tostring(arg)
    end

    print('^6[ars_ambulancejob]^7', table.concat(args, '\t'))
end

function Utils.createPed(modelName, coords)
    local model = lib.requestModel(modelName)
    if not model then return end

    local ped = CreatePed(0, model, coords.x, coords.y, coords.z, coords.w, false, true)

    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetModelAsNoLongerNeeded(model)

    return ped
end

function Utils.deletePed(ped)
    if ped and DoesEntityExist(ped) then DeletePed(ped) end
end

function Utils.createBlip(data)
    local blip = AddBlipForCoord(data.pos.x, data.pos.y, data.pos.z)

    SetBlipSprite(blip, data.type)
    SetBlipDisplay(blip, 6)
    SetBlipScale(blip, data.scale or 0.7)
    SetBlipColour(blip, data.color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(data.name)
    EndTextCommandSetBlipName(blip)

    return blip
end

function Utils.getClosestHospital()
    local coords = GetEntityCoords(cache.ped)
    local closest, closestDistance = nil, math.huge

    for _, hospital in pairs(Hospitals) do
        local distance = #(coords - hospital.zone.pos)

        if distance < closestDistance then
            closest, closestDistance = hospital, distance
        end
    end

    return closest
end

function Utils.itemCount(name)
    return exports.ox_inventory:Search('count', name) or 0
end

function Utils.hasItem(name)
    return Utils.itemCount(name) > 0
end

function Utils.isBedOccupied(coords)
    local _, ped = lib.getClosestPlayer(coords.xyz, 1.5, true)
    if not ped then return false end

    return IsEntityPlayingAnim(ped, 'anim@gangops@morgue@table@', 'body_search', 3)
        or IsEntityPlayingAnim(ped, 'switch@franklin@bed', 'sleep_getup_rubeyes', 3)
end

function Utils.findFreeBed(hospital)
    for i = 1, #hospital.respawn do
        if not Utils.isBedOccupied(hospital.respawn[i].bedPoint) then
            return hospital.respawn[i]
        end
    end

    return hospital.respawn[1]
end

function Utils.inHospitalZone(position, boxPosition, boxSize)
    local insideX = position.x >= boxPosition.x - boxSize.x / 2 and position.x <= boxPosition.x + boxSize.x / 2
    local insideY = position.y >= boxPosition.y - boxSize.y / 2 and position.y <= boxPosition.y + boxSize.y / 2
    local insideZ = position.z >= boxPosition.z - boxSize.z / 2 and position.z <= boxPosition.z + boxSize.z / 2

    return insideX and insideY and insideZ
end

function Utils.fadeOut(duration)
    DoScreenFadeOut(duration or 800)

    while not IsScreenFadedOut() do Wait(50) end
end

function Utils.fadeIn(duration)
    DoScreenFadeIn(duration or 800)
end

function Utils.serverIdFromPed(ped)
    return GetPlayerServerId(NetworkGetPlayerIndexFromPed(ped))
end

function Utils.pedFromServerId(serverId)
    local player = GetPlayerFromServerId(serverId)

    return player ~= -1 and GetPlayerPed(player) or 0
end

RegisterNetEvent('ars_ambulancejob:showNotification', Utils.notify)
