local bedModels = { `v_med_emptybed`, `v_med_bed1`, -1519439119, -289946279 }
local bedOffsets = {
    [`v_med_emptybed`] = 1.15,
    [`v_med_bed1`] = 1.35,
}
local DefaultBedOffset = 1.95
local GetUpControl = 38

local function waitForGetUp(ped)
    while not IsControlJustPressed(0, GetUpControl) do Wait(0) end

    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)
    lib.hideTextUI()
end

local function lieOnBed(entity)
    local ped = cache.ped
    local coords = GetEntityCoords(entity)
    local offset = bedOffsets[GetEntityModel(entity)] or DefaultBedOffset

    TaskStartScenarioAtPosition(ped, 'WORLD_HUMAN_SUNBATHE_BACK', coords.x, coords.y, coords.z + offset, GetEntityHeading(entity), 0, true, true)
    FreezeEntityPosition(ped, true)
    lib.showTextUI(locale('get_up_prompt'), { alignIcon = 'center', icon = 'fa-solid fa-bed' })

    CreateThread(function()
        waitForGetUp(ped)
    end)
end

exports.ox_target:addModel(bedModels, {
    {
        name = 'ars_ambulancejob_lie_on_bed',
        icon = 'fas fa-bed',
        label = locale('lie_on_bed'),
        onSelect = function(data)
            lieOnBed(data.entity)
        end,
    },
})
