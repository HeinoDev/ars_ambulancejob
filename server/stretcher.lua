local function canMovePatient(source, target)
    target = tonumber(target)

    if not Ambulance.isMedic(source) or Ambulance.isDead(source) then return false end

    return Ambulance.isDead(target) and Ambulance.isNearby(source, target, Config.stretcher.maxDistance)
end

RegisterNetEvent('ars_ambulancejob:putOnStretcher', function(target, toggle)
    if not canMovePatient(source, target) then return end

    TriggerClientEvent('ars_ambulancejob:putOnStretcher', tonumber(target), toggle == true)
end)

RegisterNetEvent('ars_ambulancejob:togglePatientVehicle', function(target, vehicleNetId)
    if not canMovePatient(source, target) then return end
    if type(vehicleNetId) ~= 'number' then return end

    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    TriggerClientEvent('ars_ambulancejob:togglePatientVehicle', tonumber(target), vehicleNetId)
end)
