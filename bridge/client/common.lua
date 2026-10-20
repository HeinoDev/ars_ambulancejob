RegisterNetEvent('ars_ambulancejob:playerLoaded', function()
    Ambulance.onPlayerLoaded()
end)

RegisterNetEvent('ars_ambulancejob:playerUnloaded', function()
    Ambulance.isDead = false
end)
