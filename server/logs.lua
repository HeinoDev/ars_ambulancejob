AmbulanceLogs = {}

local Webhook = ''
local AntiCheatWebhook = ''
local DefaultColor = 3447003
local AntiCheatColor = 15548997

local function describeSource(source)
    if not source or source <= 0 then return 'console' end

    return ('%s [%s]'):format(GetPlayerName(source) or 'unknown', source)
end

local function postWebhook(url, category, message, color)
    if url == '' then return end

    PerformHttpRequest(url, function() end, 'POST', json.encode({
        username = 'Heino-Ambulance',
        embeds = {
            {
                title = category,
                description = message,
                color = color,
            },
        },
    }), { ['Content-Type'] = 'application/json' })
end

function AmbulanceLogs.Send(source, category, message)
    local line = ('[%s] %s: %s'):format(category, describeSource(source), message)

    if Config.logging.console then
        print(('^5[ars_ambulancejob]^7 %s'):format(line))
    end

    if category == 'suspicious' then
        postWebhook(AntiCheatWebhook, category, line, AntiCheatColor)
        return
    end

    postWebhook(Webhook, category, line, DefaultColor)
end

function AmbulanceLogs.Death(source, message)
    AmbulanceLogs.Send(source, 'death', message)
end

function AmbulanceLogs.Revive(source, message)
    AmbulanceLogs.Send(source, 'revive', message)
end

function AmbulanceLogs.Treatment(source, message)
    AmbulanceLogs.Send(source, 'treatment', message)
end

function AmbulanceLogs.Respawn(source, message)
    AmbulanceLogs.Send(source, 'respawn', message)
end

function AmbulanceLogs.Command(source, message)
    AmbulanceLogs.Send(source, 'command', message)
end

function AmbulanceLogs.Dispatch(source, message)
    AmbulanceLogs.Send(source, 'dispatch', message)
end

function AmbulanceLogs.Item(source, message)
    AmbulanceLogs.Send(source, 'item', message)
end

function AmbulanceLogs.Suspicious(source, message)
    AmbulanceLogs.Send(source, 'suspicious', message)
end
