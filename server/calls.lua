local ox_inventory = exports.ox_inventory
local Settings = Config.emergencyCalls
local TickMs = 15000

local Calls = {}
local Engaged = {}
local Streaks = {}
local NextCallId = 0

local function publicCall(Call)
    return {
        id = Call.id,
        scenario = Call.scenario,
        coords = Settings.locations[Call.location],
        createdAt = Call.createdAt,
    }
end

local function onDutyMedics()
    local Result = {}
    local Players = GetPlayers()

    for Index = 1, #Players do
        local Id = tonumber(Players[Index])

        if Ambulance.isOnDutyMedic(Id) then Result[#Result + 1] = Id end
    end

    return Result
end

local function countActive()
    local Count = 0

    for _ in pairs(Calls) do Count = Count + 1 end

    return Count
end

local function locationInUse(LocationIndex)
    for _, Call in pairs(Calls) do
        if Call.location == LocationIndex then return true end
    end

    return false
end

local function pickLocation()
    local Free = {}

    for Index = 1, #Settings.locations do
        if not locationInUse(Index) then Free[#Free + 1] = Index end
    end

    if #Free == 0 then return nil end

    return Free[math.random(#Free)]
end

local function closeCall(CallId)
    Calls[CallId] = nil
    Engaged[CallId] = nil

    TriggerClientEvent('ars_ambulancejob:emergencyCallClosed', -1, CallId)
end

local function createCall(Medics)
    local LocationIndex = pickLocation()
    if not LocationIndex then return end

    NextCallId = NextCallId + 1

    local Call = {
        id = NextCallId,
        scenario = math.random(#Settings.scenarios),
        location = LocationIndex,
        createdAt = os.time(),
    }

    Calls[Call.id] = Call
    Engaged[Call.id] = {}

    for Index = 1, #Medics do
        TriggerClientEvent('ars_ambulancejob:emergencyCall', Medics[Index], publicCall(Call))
    end
end

local function randomIntervalMs()
    return math.random(Settings.intervalMinutes.min * 60000, Settings.intervalMinutes.max * 60000)
end

local function pruneExpired()
    local Cutoff = os.time() - Settings.expireMinutes * 60

    for CallId, Call in pairs(Calls) do
        if Call.createdAt < Cutoff then
            closeCall(CallId)
            AmbulanceLogs.Dispatch(0, ('Emergency call %s expired'):format(CallId))
        end
    end
end

local function trySpawnCall()
    if countActive() >= Settings.maxActive then return end

    local Medics = onDutyMedics()
    if #Medics < Settings.minMedicsOnDuty then return end

    createCall(Medics)
end

local function nextStreak(Source)
    local Streak = Streaks[Source]
    local Now = os.time()

    if Streak and Now - Streak.last <= Settings.streak.windowMinutes * 60 then
        Streak.count = math.min(Streak.count + 1, Settings.streak.maxCount)
    else
        Streak = { count = 1 }
        Streaks[Source] = Streak
    end

    Streak.last = Now

    return Streak.count
end

local function calculateReward(Call, StreakCount)
    local Reward = Settings.reward
    if Reward.max <= 0 then return 0, false end

    local Amount = math.random(Reward.min, Reward.max)
    local Fast = os.time() - Call.createdAt <= Reward.fastMinutes * 60

    if Fast then Amount = Amount + Reward.fastBonus end

    return math.floor(Amount * (1 + (StreakCount - 1) * Settings.streak.bonusPerCall)), Fast
end

local function consumeStepItem(Source, Step)
    if Step.durability then
        return Ambulance.consumeItem(Source, Step.item, Config.durabilityPerUse)
    end

    return ox_inventory:RemoveItem(Source, Step.item, 1) == true
end

local function consumeScenarioItems(Source, Scenario)
    for Index = 1, #Scenario.steps do
        local Step = Scenario.steps[Index]

        if Step.item and not consumeStepItem(Source, Step) then return false end
    end

    return true
end

local function isNearCall(Source, Call)
    return Ambulance.isNearCoords(Source, Settings.locations[Call.location], Settings.interactDistance + 5.0)
end

lib.callback.register('ars_ambulancejob:getEmergencyCalls', function(Source)
    local Result = {}

    if not Ambulance.isOnDutyMedic(Source) then return Result end

    for _, Call in pairs(Calls) do
        Result[#Result + 1] = publicCall(Call)
    end

    return Result
end)

lib.callback.register('ars_ambulancejob:beginEmergencyCall', function(Source, CallId)
    local Call = Calls[tonumber(CallId)]

    if not Call or not Ambulance.isOnDutyMedic(Source) or Ambulance.isDead(Source) then return false end
    if not isNearCall(Source, Call) then return false end

    Engaged[Call.id][Source] = Engaged[Call.id][Source] or os.time()

    return true
end)

lib.callback.register('ars_ambulancejob:completeEmergencyCall', function(Source, CallId)
    CallId = tonumber(CallId)

    local Call = Calls[CallId]
    if not Call then return false, 'call_unavailable' end
    if not Ambulance.isOnDutyMedic(Source) or Ambulance.isDead(Source) then return false, 'invalid_request' end

    local StartedAt = Engaged[CallId][Source]

    if not StartedAt or os.time() - StartedAt < Settings.minHandleSeconds or not isNearCall(Source, Call) then
        AmbulanceLogs.Suspicious(Source, ('Tried to complete emergency call %s too quickly or from a distance'):format(CallId))
        return false, 'invalid_request'
    end

    if not consumeScenarioItems(Source, Settings.scenarios[Call.scenario]) then
        return false, 'call_missing_items'
    end

    closeCall(CallId)

    local StreakCount = nextStreak(Source)
    local Reward, Fast = calculateReward(Call, StreakCount)

    if Reward > 0 then Framework.addMoney(Source, Settings.reward.account, Reward) end

    AmbulanceLogs.Dispatch(Source, ('Completed emergency call %s for $%s (streak %s)'):format(CallId, Reward, StreakCount))
    Ambulance.hook('onEmergencyCallCompleted', Source, publicCall(Call), Reward)

    return true, { reward = Reward, streak = StreakCount, fast = Fast }
end)

AddEventHandler('playerDropped', function()
    Streaks[source] = nil
end)

CreateThread(function()
    local NextSpawnAt = GetGameTimer() + randomIntervalMs()

    while true do
        Wait(TickMs)
        pruneExpired()

        if Settings.enabled and GetGameTimer() >= NextSpawnAt then
            NextSpawnAt = GetGameTimer() + randomIntervalMs()
            trySpawnCall()
        end
    end
end)
