Ambulance.dutyCount = 0

local function refreshDutyCount()
    Ambulance.dutyCount = Ambulance.countMedics()
    GlobalState.emsOnDuty = Ambulance.dutyCount
end

CreateThread(function()
    while true do
        refreshDutyCount()
        Wait(Config.paramedic.pollSeconds * 1000)
    end
end)
