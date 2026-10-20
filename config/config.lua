Config = {}

Config.framework = 'auto'
Config.debug = false
Config.notifyTitle = 'Ambulance'

Config.emsJobs = { 'ambulance' }
Config.adminGroup = 'group.admin'

Config.commands = {
    revive = 'revive',
    reviveArea = 'revivearea',
    heal = 'heal',
    healArea = 'healarea',
    reviveAll = 'reviveall',
    emergency = '911',
    calls = 'emscalls',
}

Config.items = {
    medicalBag = 'medicalbag',
    medkit = 'medkit',
    defibrillator = 'defibrillator',
}

Config.treatmentItems = {
    beaten = 'icepack',
    stabbed = 'suturekit',
    shot = 'tweezers',
    burn = 'burncream',
    default = 'bandage',
}

Config.durabilityPerUse = 10
Config.maxTreatDistance = 4.0

Config.death = {
    respawnMinutes = 7,
    extraEffects = true,
    removeItemsOnRespawn = true,
    keepItemsOnRespawn = { 'phone', 'radio' },
}

Config.revive = {
    introMs = 14900,
    compressions = 15,
    compressionMs = 900,
    finishMs = 800,
}

Config.rewards = {
    account = 'money',
    revive = 0,
    injuryTreated = 0,
}

Config.paramedic = {
    price = 0,
    account = 'money',
    revive = true,
    alwaysAvailable = false,
    maxMedicsOnDuty = 0,
    pollSeconds = 60,
    treatmentSeconds = 15,
    maxDistance = 15.0,
}

Config.distress = {
    cooldownMinutes = 5,
    maxMessageLength = 200,
    maxActiveCalls = 50,
    lifetimeMinutes = 30,
}

Config.stretcher = {
    model = 'prop_ld_binbag_01',
    perVehicle = 1,
    maxDistance = 10.0,
}

Config.medicBag = {
    prop = 'xm_prop_x17_bag_med_01a',
    stashSlots = 10,
    stashWeight = 50000,
    maxDistance = 5.0,
}

Config.emsVehicles = {
    ambulance = true,
    emscara = true,
    emsrhinehart = true,
    emsspeedo = true,
}

Config.usePedToDepositVehicle = false

Config.animations = {
    death_car = {
        dict = 'veh@low@front_ps@idle_duck',
        clip = 'sit',
    },
    death_normal = {
        dict = 'dead',
        clip = 'dead_a',
    },
    get_up = {
        dict = 'get_up@directional@movement@from_knees@action',
        clip = 'getup_r_0',
    },
}

Config.logging = {
    console = false,
}

Config.hooks = {
    notify = function(message, notifyType)
        lib.notify({
            title = Config.notifyTitle,
            description = message,
            type = notifyType or 'info',
        })
    end,
    onDeath = function() end,
    onRevive = function() end,
    onRespawn = function() end,
    onVehicleSpawned = function(vehicle, plate) end,
}

Config.serverHooks = {
    onPlayerDied = function(source, weapon) end,
    onPlayerRevived = function(source) end,
    onPlayerRespawned = function(source) end,
    onDistressCall = function(source, call) end,
    onInjuryTreated = function(source, target, bone) end,
    onEmergencyCallCompleted = function(source, call, reward) end,
}
