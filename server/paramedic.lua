local function findHospital(key)
    return type(key) == 'string' and Hospitals[key] or nil
end

local function canUseParamedic()
    return Config.paramedic.alwaysAvailable or Ambulance.dutyCount <= Config.paramedic.maxMedicsOnDuty
end

lib.callback.register('ars_ambulancejob:requestParamedicTreatment', function(source, hospitalKey)
    local hospital = findHospital(hospitalKey)
    if not hospital then return false, 'invalid_request' end

    if not Ambulance.isNearCoords(source, hospital.paramedic.pos, Config.paramedic.maxDistance) then
        AmbulanceLogs.Suspicious(source, 'Requested paramedic treatment from too far away')
        return false, 'invalid_request'
    end

    if not canUseParamedic() then return false, 'medics_online' end

    local price = Config.paramedic.price

    if price > 0 and not Framework.removeMoney(source, Config.paramedic.account, price) then
        return false, 'not_enough_money'
    end

    if Config.paramedic.revive and Ambulance.isDead(source) then
        Ambulance.allowRevive(source)
    end

    AmbulanceLogs.Treatment(source, ('Was treated by the paramedic at %s for $%s'):format(hospitalKey, price))

    return true
end)
