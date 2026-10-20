local calls = {}
local lastCallTime = {}
local nextCallId = 0
local MaxLocationLength = 64

local function pruneCalls()
    local cutoff = os.time() - Config.distress.lifetimeMinutes * 60

    for i = #calls, 1, -1 do
        if calls[i].time < cutoff then table.remove(calls, i) end
    end

    while #calls >= Config.distress.maxActiveCalls do
        table.remove(calls, 1)
    end
end

local function notifyMedics(callerName)
    local players = GetPlayers()

    for i = 1, #players do
        local id = tonumber(players[i])

        if Ambulance.isMedic(id) then
            TriggerClientEvent('ars_ambulancejob:newDistressCall', id, callerName)
        end
    end
end

local function cleanText(value, maxLength)
    if type(value) ~= 'string' then return nil end

    value = value:gsub('^%s+', ''):gsub('%s+$', '')
    if value == '' or #value > maxLength then return nil end

    return value
end

lib.callback.register('ars_ambulancejob:createDistressCall', function(source, message, location)
    local text = cleanText(message, Config.distress.maxMessageLength)
    if not text then return false, 'invalid_request' end

    local cooldown = Config.distress.cooldownMinutes * 60
    local now = os.time()

    if lastCallTime[source] and now - lastCallTime[source] < cooldown then
        return false, 'distress_call_in_cooldown'
    end

    lastCallTime[source] = now
    pruneCalls()
    nextCallId = nextCallId + 1

    local name = Framework.getName(source)

    local call = {
        id = nextCallId,
        msg = text,
        gps = GetEntityCoords(GetPlayerPed(source)),
        location = cleanText(location, MaxLocationLength) or '',
        name = name,
        time = now,
    }

    calls[#calls + 1] = call

    notifyMedics(name)
    Ambulance.hook('onDistressCall', source, call)
    AmbulanceLogs.Dispatch(source, ('Sent a distress call: %s'):format(text))

    return true
end)

lib.callback.register('ars_ambulancejob:getDistressCalls', function(source)
    if not Ambulance.isMedic(source) then return {} end

    pruneCalls()

    return calls
end)

RegisterNetEvent('ars_ambulancejob:callCompleted', function(callId)
    local source = source
    if not Ambulance.isMedic(source) then return end

    for i = #calls, 1, -1 do
        if calls[i].id == callId then
            table.remove(calls, i)
            AmbulanceLogs.Dispatch(source, 'Completed a distress call')
            return
        end
    end
end)

AddEventHandler('playerDropped', function()
    lastCallTime[source] = nil
end)
