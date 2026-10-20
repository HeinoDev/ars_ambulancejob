if not Framework.isFramework('custom') then return end

function Framework.hasJob(Jobs)
    return Framework.matchesJob(LocalPlayer.state.job, Jobs)
end

function Framework.getJobGrade()
    return LocalPlayer.state.jobGrade or 0
end

function Framework.healStatus()
    TriggerEvent('ars_ambulancejob:statusRestored')
end

function Framework.playerSpawned()
    TriggerEvent('playerSpawned')
end

AddEventHandler('onResourceStart', function(Resource)
    if Resource ~= GetCurrentResourceName() or not LocalPlayer.state.isLoggedIn then return end

    Ambulance.onPlayerLoaded()
end)
