if not Framework.isFramework('esx') then return end

local ESX = exports.es_extended:getSharedObject()

function Framework.hasJob(Source, Jobs)
    local Character = ESX.GetPlayerFromId(Source)
    if not Character then return false end

    return Framework.matchesJob(Character.job.name, Jobs)
end

function Framework.isOnDuty(Source)
    local Character = ESX.GetPlayerFromId(Source)

    return Character ~= nil and Character.job.onDuty ~= false
end

function Framework.getName(Source)
    local Character = ESX.GetPlayerFromId(Source)

    return Character and Character.getName() or GetPlayerName(Source) or 'Unknown'
end

function Framework.getMoney(Source, Account)
    local Character = ESX.GetPlayerFromId(Source)
    local Data = Character and Character.getAccount(Account)

    return Data and Data.money or 0
end

function Framework.addMoney(Source, Account, Amount)
    local Character = ESX.GetPlayerFromId(Source)
    if not Character or Amount <= 0 then return false end

    Character.addAccountMoney(Account, Amount)

    return true
end

function Framework.removeMoney(Source, Account, Amount)
    local Character = ESX.GetPlayerFromId(Source)
    if not Character then return false end
    if Amount <= 0 then return true end
    if Framework.getMoney(Source, Account) < Amount then return false end

    Character.removeAccountMoney(Account, Amount)

    return true
end

function Framework.setDead(Source, IsDead)
    local Character = ESX.GetPlayerFromId(Source)
    if not Character then return end

    MySQL.update('UPDATE users SET is_dead = ? WHERE identifier = ?', { IsDead and 1 or 0, Character.identifier })
end

function Framework.wasDead(Source)
    local Character = ESX.GetPlayerFromId(Source)
    if not Character then return false end

    local Value = MySQL.scalar.await('SELECT is_dead FROM users WHERE identifier = ? LIMIT 1', { Character.identifier })

    return Value == 1 or Value == true
end

function Framework.registerUsableItem(Name, Handler)
    ESX.RegisterUsableItem(Name, Handler)
end

local function ensureIsDeadColumn()
    local ColumnQuery = "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'is_dead'"

    if (MySQL.scalar.await(ColumnQuery) or 0) > 0 then return end

    local Ok, Err = pcall(MySQL.query.await, 'ALTER TABLE `users` ADD COLUMN `is_dead` TINYINT(1) NOT NULL DEFAULT 0')

    if not Ok or (MySQL.scalar.await(ColumnQuery) or 0) == 0 then
        print(('^1[ars_ambulancejob] failed to add the is_dead column to users: %s^7'):format(tostring(Err)))
    end
end

local function registerSocieties()
    if GetResourceState('esx_society') ~= 'started' then return end

    for Index = 1, #Config.emsJobs do
        local Job = Config.emsJobs[Index]
        TriggerEvent('esx_society:registerSociety', Job, Job, 'society_' .. Job, 'society_' .. Job, 'society_' .. Job, { type = 'public' })
    end
end

MySQL.ready(ensureIsDeadColumn)
CreateThread(registerSocieties)
