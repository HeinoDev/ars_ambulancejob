local function playersInRadius(source, radius)
    local origin = GetEntityCoords(GetPlayerPed(source))
    local result = {}
    local players = GetPlayers()

    for i = 1, #players do
        local id = tonumber(players[i])

        if #(GetEntityCoords(GetPlayerPed(id)) - origin) <= radius then
            result[#result + 1] = id
        end
    end

    return result
end

local function notifyAdmin(source, message)
    if source > 0 then Ambulance.notify(source, message, 'success') end
end

local function resolveTarget(source, args)
    if args.target then return args.target end
    if source > 0 then return source end

    print('^1[ars_ambulancejob] a target id is required from the console^7')
end

local function registerTargetCommand(name, help, revive, doneKey, logVerb)
    lib.addCommand(name, {
        help = help,
        params = {
            { name = 'target', type = 'playerId', help = 'Target server id', optional = true },
        },
        restricted = Config.adminGroup,
    }, function(source, args)
        local target = resolveTarget(source, args)
        if not target then return end

        Ambulance.heal(target, revive)
        notifyAdmin(source, locale(doneKey):format(target))
        AmbulanceLogs.Command(source, ('%s %s [%s]'):format(logVerb, GetPlayerName(target), target))
    end)
end

local function registerAreaCommand(name, help, revive, doneKey, logVerb)
    lib.addCommand(name, {
        help = help,
        params = {
            { name = 'radius', type = 'number', help = 'Radius in meters' },
        },
        restricted = Config.adminGroup,
    }, function(source, args)
        if source <= 0 then
            print('^1[ars_ambulancejob] this command cannot be run from the console^7')
            return
        end

        local targets = playersInRadius(source, args.radius)

        for i = 1, #targets do
            Ambulance.heal(targets[i], revive)
        end

        notifyAdmin(source, locale(doneKey):format(args.radius))
        AmbulanceLogs.Command(source, ('%s %s players within %s meters'):format(logVerb, #targets, args.radius))
    end)
end

registerTargetCommand(Config.commands.revive, locale('revive_player'), true, 'revived_player', 'Revived')
registerTargetCommand(Config.commands.heal, locale('heal_player'), false, 'healed_player', 'Healed')
registerAreaCommand(Config.commands.reviveArea, locale('revive_area'), true, 'revived_area', 'Revived')
registerAreaCommand(Config.commands.healArea, locale('heal_area'), false, 'healed_area', 'Healed')

lib.addCommand(Config.commands.reviveAll, {
    help = locale('revive_all'),
    restricted = Config.adminGroup,
}, function(source)
    local players = GetPlayers()

    for i = 1, #players do
        Ambulance.heal(tonumber(players[i]), true)
    end

    notifyAdmin(source, locale('revived_all'))
    AmbulanceLogs.Command(source, ('Revived everyone (%s players)'):format(#players))
end)
