Garage = {}

local garagePeds = {}
local depositPoints = {}

local function spawnVehicle(garage, entry)
    if IsPositionOccupied(garage.spawn.x, garage.spawn.y, garage.spawn.z, 10, false, true, true, false, false, 0, false) then
        Utils.notify(locale('spawn_blocked'), 'error')
        return
    end

    local model = lib.requestModel(entry.model)
    if not model then return end

    local vehicle = CreateVehicle(model, garage.spawn.x, garage.spawn.y, garage.spawn.z, garage.spawn.w, true, false)

    SetModelAsNoLongerNeeded(model)
    NetworkFadeInEntity(vehicle, true)

    if entry.modifications then
        lib.setVehicleProperties(vehicle, entry.modifications)
    end

    Config.hooks.onVehicleSpawned(vehicle, lib.getVehicleProperties(vehicle).plate)
    TaskEnterVehicle(cache.ped, vehicle, -1, -1, 1.0, 1, 0)
end

local function openVehicleList(garage)
    local grade = Framework.getJobGrade()
    local options = {}

    for _, entry in ipairs(garage.vehicles) do
        if grade >= (entry.minGrade or 0) then
            options[#options + 1] = {
                title = entry.label,
                onSelect = function()
                    spawnVehicle(garage, entry)
                end,
            }
        end
    end

    lib.registerContext({
        id = 'ars_ambulancejob:vehicleList',
        title = locale('vehiclemenu_label'),
        options = options,
    })

    lib.showContext('ars_ambulancejob:vehicleList')
end

local function driveAwayAndDelete(garage, vehicle)
    local driver = Utils.createPed(garage.model, garage.driverSpawnCoords)
    FreezeEntityPosition(driver, false)

    TaskEnterVehicle(driver, vehicle, -1, -1, 1.0, 1, 0)
    Wait(1000)

    for seat = 0, 2 do
        while GetPedInVehicleSeat(vehicle, seat) ~= 0 do Wait(50) end
    end

    TaskVehicleDriveWander(driver, vehicle, 60.0, 8)
    Wait(20000)

    NetworkFadeOutEntity(vehicle, false, true)
    NetworkFadeOutEntity(driver, false, true)
    Wait(1000)

    Utils.deletePed(driver)
end

local function depositVehicle(garage, point)
    local vehicle = cache.vehicle
    if not vehicle or GetPedInVehicleSeat(vehicle, -1) ~= cache.ped then return end

    DrawMarker(0, point.coords.x, point.coords.y, point.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.8, 0.8, 0.8, 199, 208, 209, 100, false, true, 2, false, nil, nil, false)

    if point.currentDistance >= 2 or not IsControlJustReleased(0, 38) then return end

    TaskLeaveVehicle(cache.ped, vehicle, 64)
    while cache.vehicle do Wait(100) end

    lib.hideTextUI()

    if Config.usePedToDepositVehicle then
        driveAwayAndDelete(garage, vehicle)
    end

    DeleteVehicle(vehicle)
end

local function createGaragePed(key, garage)
    local ped = Utils.createPed(garage.model, garage.pedPos)
    if not ped then return end

    garagePeds[key] = ped

    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'ars_ambulancejob_garage_' .. key,
            label = locale('garage_interact_label'),
            icon = 'fa-solid fa-car',
            groups = Config.emsJobs,
            distance = 3.0,
            onSelect = function()
                openVehicleList(garage)
            end,
        },
    })
end

local function createDepositPoint(key, garage)
    depositPoints[key] = lib.points.new({
        coords = garage.deposit.xyz,
        distance = 5,
        onEnter = function()
            if cache.vehicle and Framework.hasJob(Config.emsJobs) then
                lib.showTextUI(locale('deposit_vehicle'))
            end
        end,
        onExit = function()
            lib.hideTextUI()
        end,
        nearby = function(point)
            if Framework.hasJob(Config.emsJobs) then
                depositVehicle(garage, point)
            end
        end,
    })
end

function Garage.load(hospitalKey, garages)
    for id, garage in pairs(garages) do
        local key = hospitalKey .. ':' .. id

        if not garagePeds[key] then
            createGaragePed(key, garage)
            createDepositPoint(key, garage)
        end
    end
end

function Garage.unload(hospitalKey)
    local prefix = hospitalKey .. ':'

    for key, ped in pairs(garagePeds) do
        if key:sub(1, #prefix) == prefix then
            Utils.deletePed(ped)
            garagePeds[key] = nil

            if depositPoints[key] then
                depositPoints[key]:remove()
                depositPoints[key] = nil
            end
        end
    end
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for key, ped in pairs(garagePeds) do
        Utils.deletePed(ped)
        garagePeds[key] = nil
    end
end)
