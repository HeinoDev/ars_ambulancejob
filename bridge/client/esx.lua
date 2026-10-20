if not Framework.isFramework('esx') then return end

local ESX = exports.es_extended:getSharedObject()

local function currentJob()
    local Data = ESX.GetPlayerData()

    return Data and Data.job
end

function Framework.hasJob(Jobs)
    local Job = currentJob()
    if not Job then return false end

    return Framework.matchesJob(Job.name, Jobs)
end

function Framework.getJobGrade()
    local Job = currentJob()

    return Job and Job.grade or 0
end

function Framework.healStatus()
    TriggerEvent('esx_status:add', 'hunger', 1000000)
    TriggerEvent('esx_status:add', 'thirst', 1000000)
end

function Framework.playerSpawned()
    TriggerEvent('esx_basicneeds:resetStatus')
    TriggerServerEvent('esx:onPlayerSpawn')
    TriggerEvent('esx:onPlayerSpawn')
    TriggerEvent('playerSpawned')
end

AddEventHandler('esx:onPlayerSpawn', function()
    LocalPlayer.state.invBusy = true
    Wait(1000)
    Ambulance.onPlayerLoaded()
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    Ambulance.isDead = false
end)

AddEventHandler('onResourceStart', function(Resource)
    if Resource ~= GetCurrentResourceName() or not ESX.IsPlayerLoaded() then return end

    Ambulance.onPlayerLoaded()
end)
