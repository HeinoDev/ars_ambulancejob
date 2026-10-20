if not Framework.isFramework('custom') then return end

local DeadPlayers = {}

local function identifierOf(Source)
    return GetPlayerIdentifierByType(Source, 'license')
end

function Framework.hasJob(Source, Jobs)
    return Framework.matchesJob(Player(Source).state.job, Jobs)
end

function Framework.isOnDuty(Source)
    return Player(Source).state.onDuty ~= false
end

function Framework.getName(Source)
    return GetPlayerName(Source) or 'Unknown'
end

function Framework.getMoney(Source, Account)
    return exports.ox_inventory:GetItemCount(Source, Account) or 0
end

function Framework.addMoney(Source, Account, Amount)
    if Amount <= 0 then return false end

    return exports.ox_inventory:AddItem(Source, Account, Amount) ~= false
end

function Framework.removeMoney(Source, Account, Amount)
    if Amount <= 0 then return true end
    if Framework.getMoney(Source, Account) < Amount then return false end

    return exports.ox_inventory:RemoveItem(Source, Account, Amount) ~= false
end

function Framework.setDead(Source, IsDead)
    DeadPlayers[identifierOf(Source)] = IsDead or nil
end

function Framework.wasDead(Source)
    return DeadPlayers[identifierOf(Source)] == true
end

function Framework.registerUsableItem(Name, Handler)
    AddEventHandler('ox_inventory:usedItem', function(Source, ItemName)
        if ItemName == Name then Handler(Source) end
    end)
end

RegisterNetEvent('ars_ambulancejob:restoreStatus', function()
    TriggerEvent('ars_ambulancejob:statusRestored', source)
end)
