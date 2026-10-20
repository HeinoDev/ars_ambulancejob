local function createStashPoint(id, stash)
    lib.points.new({
        coords = stash.pos,
        distance = 3,
        onEnter = function()
            if Framework.hasJob(Config.emsJobs) then
                lib.showTextUI(locale('control_to_open_stash'))
            end
        end,
        onExit = function()
            lib.hideTextUI()
        end,
        nearby = function(point)
            if not Framework.hasJob(Config.emsJobs) then return end

            DrawMarker(2, point.coords.x, point.coords.y, point.coords.z, 0.0, 0.0, 0.0, 180.0, 0.0, 0.0, 0.2, 0.2, 0.2, 199, 208, 209, 100, true, true, 2, false, nil, nil, false)

            if IsControlJustReleased(0, 38) then
                exports.ox_inventory:openInventory('stash', id)
            end
        end,
    })
end

CreateThread(function()
    for _, hospital in pairs(Hospitals) do
        for id, stash in pairs(hospital.stash) do
            createStashPoint(id, stash)
        end
    end
end)
