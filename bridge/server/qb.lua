if not Framework.isFramework('qbcore', 'qbx') then return end

local Core = Framework.Name == 'qbcore' and exports['qb-core']:GetCoreObject() or nil
local AccountNames = { money = 'cash' }
local RestoreCooldownMs = 5000
local LastRestore = {}

local function getCharacter(Source)
    if Core then return Core.Functions.GetPlayer(Source) end

    return exports.qbx_core:GetPlayer(Source)
end

local function accountName(Account)
    return AccountNames[Account] or Account
end

function Framework.hasJob(Source, Jobs)
    local Character = getCharacter(Source)
    if not Character then return false end

    return Framework.matchesJob(Character.PlayerData.job.name, Jobs)
end

function Framework.isOnDuty(Source)
    local Character = getCharacter(Source)

    return Character ~= nil and Character.PlayerData.job.onduty ~= false
end

function Framework.getName(Source)
    local Character = getCharacter(Source)
    if not Character then return GetPlayerName(Source) or 'Unknown' end

    local Info = Character.PlayerData.charinfo

    return ('%s %s'):format(Info.firstname, Info.lastname)
end

function Framework.getMoney(Source, Account)
    local Character = getCharacter(Source)

    return Character and Character.PlayerData.money[accountName(Account)] or 0
end

function Framework.addMoney(Source, Account, Amount)
    local Character = getCharacter(Source)
    if not Character or Amount <= 0 then return false end

    return Character.Functions.AddMoney(accountName(Account), Amount, 'ars_ambulancejob') == true
end

function Framework.removeMoney(Source, Account, Amount)
    local Character = getCharacter(Source)
    if not Character then return false end
    if Amount <= 0 then return true end
    if Framework.getMoney(Source, Account) < Amount then return false end

    return Character.Functions.RemoveMoney(accountName(Account), Amount, 'ars_ambulancejob') == true
end

function Framework.setDead(Source, IsDead)
    local Character = getCharacter(Source)
    if not Character then return end

    Character.Functions.SetMetaData('isdead', IsDead)
end

function Framework.wasDead(Source)
    local Character = getCharacter(Source)

    return Character ~= nil and Character.PlayerData.metadata.isdead == true
end

function Framework.registerUsableItem(Name, Handler)
    local function onUse(Source)
        Handler(Source)
    end

    if Core then
        Core.Functions.CreateUseableItem(Name, onUse)
        return
    end

    exports.qbx_core:CreateUseableItem(Name, onUse)
end

RegisterNetEvent('ars_ambulancejob:restoreStatus', function()
    local Source = source
    local Now = GetGameTimer()

    if LastRestore[Source] and Now - LastRestore[Source] < RestoreCooldownMs then return end
    LastRestore[Source] = Now

    local Character = getCharacter(Source)
    if not Character then return end

    Character.Functions.SetMetaData('hunger', 100)
    Character.Functions.SetMetaData('thirst', 100)
end)

AddEventHandler('playerDropped', function()
    LastRestore[source] = nil
end)
