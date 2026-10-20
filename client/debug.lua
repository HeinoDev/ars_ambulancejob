if not Config.debug then return end

local function checkInside(label, position, hospital)
    if Utils.inHospitalZone(position, hospital.zone.pos, hospital.zone.size) then return end

    Utils.debug(('^1%s^7 is outside the hospital zone'):format(label))
end

for key, hospital in pairs(Hospitals) do
    Utils.debug(('^6Validating hospital %s^7'):format(key))

    checkInside('Paramedic', hospital.paramedic.pos, hospital)
    checkInside('Blip', hospital.blip.pos, hospital)

    for index, bed in ipairs(hospital.respawn) do
        checkInside(('Bed %s'):format(index), bed.bedPoint, hospital)
    end

    for id, stash in pairs(hospital.stash) do
        checkInside(('Stash %s'):format(id), stash.pos, hospital)
    end

    for id, garage in pairs(hospital.garage) do
        checkInside(('Garage %s'):format(id), garage.pedPos.xyz, hospital)
    end
end
