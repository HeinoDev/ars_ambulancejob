if not Framework.isFramework('qbcore', 'qbx') then return end

local Core = Framework.Name == 'qbcore' and exports['qb-core']:GetCoreObject() or nil

local function currentJob()
    local Data = Core and Core.Functions.GetPlayerData() or exports.qbx_core:GetPlayerData()

    return Data and Data.job
end

function Framework.hasJob(Jobs)
    local Job = currentJob()
    if not Job then return false end

    return Framework.matchesJob(Job.name, Jobs)
end

function Framework.getJobGrade()
    local Job = currentJob()

    return Job and Job.grade and Job.grade.level or 0
end

function Framework.healStatus()
    TriggerServerEvent('ars_ambulancejob:restoreStatus')
end

function Framework.playerSpawned()
    TriggerEvent('playerSpawned')
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Ambulance.onPlayerLoaded()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    Ambulance.isDead = false
end)

AddEventHandler('onResourceStart', function(Resource)
    if Resource ~= GetCurrentResourceName() or not LocalPlayer.state.isLoggedIn then return end

    Ambulance.onPlayerLoaded()
end)
