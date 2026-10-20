if GetResourceState('monitor') ~= 'started' then return end

local function healTarget(target)
    Ambulance.heal(target, Ambulance.isDead(target))
end

local function onPlayerHealed(eventData)
    if GetInvokingResource() ~= 'monitor' or type(eventData) ~= 'table' then return end

    local target = eventData.target
    if type(target) ~= 'number' then return end

    if target ~= -1 then
        healTarget(target)
        return
    end

    local players = GetPlayers()

    for i = 1, #players do
        healTarget(tonumber(players[i]))
    end
end

AddEventHandler('txAdmin:events:healedPlayer', onPlayerHealed)
AddEventHandler('txAdmin:events:playerHealed', onPlayerHealed)
