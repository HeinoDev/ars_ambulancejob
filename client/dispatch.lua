local CallsMenu = 'ars_ambulancejob:openDistressCalls'
local CallMenu = 'ars_ambulancejob:openCall'

local function openCallMenu(call)
    lib.registerContext({
        id = CallMenu,
        title = call.name,
        menu = CallsMenu,
        options = {
            {
                title = call.msg,
                description = locale('tablet_call_desc'),
                icon = 'fa-info-circle',
                iconColor = '#0077FF',
                readOnly = true,
            },
            {
                title = call.location ~= '' and call.location or call.name,
                description = locale('tablet_call_location'),
                icon = 'fa-map-marker',
                iconColor = '#00CC00',
                readOnly = true,
            },
            {
                title = locale('tablet_call_waypoint_title'),
                description = locale('tablet_call_waypoint_desc'),
                icon = 'fa-map-pin',
                iconColor = '#FFA500',
                arrow = true,
                onSelect = function()
                    SetNewWaypoint(call.gps.x, call.gps.y)
                    Utils.notify(locale('tablet_call_waypoint_notification'))
                    lib.hideContext(false)
                end,
            },
            {
                title = locale('tablet_call_resolved_title'),
                description = locale('tablet_call_resolved_desc'),
                icon = 'fa-check',
                iconColor = '#32CD32',
                arrow = true,
                onSelect = function()
                    TriggerServerEvent('ars_ambulancejob:callCompleted', call.id)
                    Utils.notify(locale('tablet_call_resolved_notification'))
                    lib.hideContext(false)
                end,
            },
        },
    })

    lib.showContext(CallMenu)
end

local function openDistressCalls()
    if not Framework.hasJob(Config.emsJobs) then return end

    local calls = lib.callback.await('ars_ambulancejob:getDistressCalls', false)

    local options = {}

    for i = 1, #calls do
        local call = calls[i]

        options[i] = {
            title = call.name,
            description = call.msg,
            icon = 'fa-truck-medical',
            iconColor = '#FEBD69',
            arrow = true,
            onSelect = function()
                openCallMenu(call)
            end,
        }
    end

    lib.registerContext({
        id = CallsMenu,
        title = locale('tablet_calls_title'),
        options = options,
    })

    lib.showContext(CallsMenu)
end

local function createDistressCall()
    local cooldownMs = Config.distress.cooldownMinutes * 60000

    if Ambulance.distressCallTime and GetGameTimer() - Ambulance.distressCallTime < cooldownMs then
        Utils.notify(locale('distress_call_in_cooldown'), 'error')
        return
    end

    local input = lib.inputDialog(locale('distress_call_form_title'), {
        {
            type = 'input',
            label = locale('distress_call_form_label'),
            description = locale('distress_call_form_desc'),
            required = true,
            max = Config.distress.maxMessageLength,
        },
    })

    if not input then return end

    local coords = GetEntityCoords(cache.ped)
    local street = GetStreetNameFromHashKey((GetStreetNameAtCoord(coords.x, coords.y, coords.z)))

    local sent, reason = lib.callback.await('ars_ambulancejob:createDistressCall', false, input[1], street)

    if not sent then
        Utils.notify(locale(reason or 'invalid_request'), 'error')
        return
    end

    Ambulance.distressCallTime = GetGameTimer()
    Utils.notify(locale('medic_coming'), 'success')
end

RegisterNetEvent('ars_ambulancejob:newDistressCall', function(callerName)
    if not Framework.hasJob(Config.emsJobs) then return end

    lib.notify({
        title = Config.notifyTitle,
        description = locale('notification_new_call_desc', callerName),
        position = 'bottom-right',
        duration = 8000,
        icon = 'fas fa-truck-medical',
        iconColor = '#FEBD69',
    })

    PlaySound(-1, 'Event_Start_Text', 'GTAO_FM_Events_Soundset')
end)

RegisterNetEvent('ars_ambulancejob:openDistressCalls', openDistressCalls)

RegisterCommand(Config.commands.calls, openDistressCalls, false)

RegisterCommand(Config.commands.emergency, createDistressCall, false)

exports('createDistressCall', createDistressCall)
exports('openDistressCalls', openDistressCalls)
