Ambulance = {
    isDead = false,
    respawning = false,
    gettingRevived = false,
    injuries = {},
    distressCallTime = nil,
}

local function createHospitalZone(key, hospital)
    if hospital.blip.enable then
        Utils.createBlip(hospital.blip)
    end

    lib.zones.box({
        name = 'ars_hospital:' .. key,
        coords = hospital.zone.pos,
        size = hospital.zone.size,
        rotation = 0.0,
        debug = Config.debug,
        onEnter = function()
            Garage.load(key, hospital.garage)
            Paramedic.load(key, hospital)
        end,
        onExit = function()
            Garage.unload(key)
            Paramedic.unload(key)
        end,
    })
end

CreateThread(function()
    for key, hospital in pairs(Hospitals) do
        createHospitalZone(key, hospital)
    end
end)

exports('isDead', function()
    return Ambulance.isDead
end)
