local InjuriesMenu = 'ars_ambulancejob:patient_injuries'
local InjuryMenu = 'ars_ambulancejob:patient_injury'
local PatientMenu = 'ars_ambulancejob:check_patient'

local function treatmentItemFor(cause)
    return Config.treatmentItems[cause] or Config.treatmentItems.default
end

local function treatInjury(targetId, injury)
    local item = treatmentItemFor(injury.cause)

    if not Utils.hasItem(item) then
        Utils.notify(locale('not_enough_' .. item), 'error')
        return
    end

    local completed = lib.progressBar({
        duration = 2000 * (injury.value / 10),
        label = locale('treating_injury'),
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true },
        anim = { scenario = 'CODE_HUMAN_MEDIC_TEND_TO_DEAD' },
    })

    if not completed then
        Utils.notify(locale('operation_canceled'))
        return
    end

    TriggerServerEvent('ars_ambulancejob:treatInjury', targetId, injury.bone)
    Utils.notify(locale('injury_treated'))
end

local function showInjury(targetId, injury)
    lib.registerContext({
        id = InjuryMenu,
        title = injury.label,
        menu = InjuriesMenu,
        options = {
            {
                title = locale('injury_value'),
                progress = injury.value,
                metadata = { injury.value .. '%' },
            },
            {
                title = locale('injury_cause'),
                description = locale(injury.cause),
            },
            {
                title = locale('injury_treat'),
                onSelect = function()
                    treatInjury(targetId, injury)
                end,
            },
        },
    })

    lib.showContext(InjuryMenu)
end

local function showInjuries(targetId, injuries)
    local options = {}

    if injuries then
        for _, injury in pairs(injuries) do
            options[#options + 1] = {
                title = injury.label,
                description = injury.desc,
                arrow = true,
                onSelect = function()
                    showInjury(targetId, injury)
                end,
            }
        end
    end

    if #options == 0 then
        options[1] = { title = locale('no_injuries') }
    end

    lib.registerContext({
        id = InjuriesMenu,
        title = locale('injury_menu_title'),
        menu = PatientMenu,
        options = options,
    })

    lib.showContext(InjuriesMenu)
end

local function revivePatient(targetId)
    if not Utils.hasItem(Config.items.defibrillator) then
        Utils.notify(locale('not_enough_defibrillator'), 'error')
        return
    end

    TriggerServerEvent('ars_ambulancejob:reviveTarget', targetId)
end

local function showPatient(targetId, data)
    local isDead = data.status.isDead

    local options = {
        {
            title = locale('status_patient') .. (isDead and locale('patient_not_conscious') or locale('patient_conscious')),
            icon = 'heartbeat',
            iconColor = isDead and '#b5300b' or '#5b87b0',
            readOnly = true,
        },
        {
            title = locale('check_injuries'),
            description = locale('check_injuries_desc'),
            icon = 'user-injured',
            onSelect = function()
                showInjuries(targetId, data.injuries)
            end,
        },
    }

    if isDead then
        options[#options + 1] = {
            title = locale('revive_patient'),
            description = locale('revive_patient_desc'),
            icon = 'medkit',
            iconColor = '#5BC0DE',
            onSelect = function()
                revivePatient(targetId)
            end,
        }

        options[#options + 1] = {
            title = Weapons[data.killedBy] and Weapons[data.killedBy][1] or locale('patient_not_found'),
            icon = 'skull',
            readOnly = true,
        }
    end

    lib.registerContext({
        id = PatientMenu,
        title = locale('check_patient_menu_title'),
        options = options,
    })

    lib.showContext(PatientMenu)
end

local function checkPatient(ped)
    local targetId = Utils.serverIdFromPed(ped)

    local completed = lib.progressBar({
        duration = 3000,
        label = locale('checking_patient'),
        useWhileDead = false,
        canCancel = false,
        disable = { car = true },
    })

    if not completed then return end

    local data = lib.callback.await('ars_ambulancejob:getPatientData', false, targetId)

    if not data then
        Utils.notify(locale('patient_not_found'), 'error')
        return
    end

    showPatient(targetId, data)
end

local function playMedicRevive(data)
    local ped = cache.ped
    local revive = Config.revive
    local duration = revive.introMs + revive.compressions * revive.compressionMs + 1000

    Utils.notify(locale('action_revive_notification'))

    CreateThread(function()
        lib.progressBar({
            duration = duration,
            label = locale('reviving_patient'),
            useWhileDead = false,
            canCancel = false,
            disable = { car = true, move = true },
        })
    end)

    lib.requestAnimDict('mini@cpr@char_a@cpr_def')
    lib.requestAnimDict('mini@cpr@char_a@cpr_str')

    TaskPlayAnim(ped, 'mini@cpr@char_a@cpr_def', 'cpr_intro', 8.0, 8.0, -1, 0, 0, false, false, false)
    Wait(revive.introMs)

    for _ = 1, revive.compressions do
        Wait(revive.compressionMs)
        TaskPlayAnim(ped, 'mini@cpr@char_a@cpr_str', 'cpr_pumpchest', 8.0, 8.0, -1, 0, 0, false, false, false)
    end

    Wait(1000)

    local getUp = Config.animations.get_up
    lib.requestAnimDict(getUp.dict)
    TaskPlayAnim(ped, getUp.dict, getUp.clip, 10.0, -10.0, -1, 0, 0, false, false, false)
end

local function playPatientRevive(data)
    local ped = cache.ped
    local revive = Config.revive

    Utils.notify(locale('action_revived_notification'))
    Ambulance.gettingRevived = true

    lib.requestAnimDict('mini@cpr@char_b@cpr_str')
    lib.requestAnimDict('mini@cpr@char_b@cpr_def')

    SetCurrentPedWeapon(ped, joaat('WEAPON_UNARMED'), true)

    local position = data.coords + data.location

    SetEntityCoords(ped, position.x, position.y, position.z - 0.5)
    SetEntityHeading(ped, data.heading - 270.0)

    TaskPlayAnim(ped, 'mini@cpr@char_b@cpr_def', 'cpr_intro', 8.0, 8.0, -1, 0, 0, false, false, false)
    Wait(revive.introMs)

    for _ = 1, revive.compressions do
        Wait(revive.compressionMs)
        TaskPlayAnim(ped, 'mini@cpr@char_b@cpr_str', 'cpr_pumpchest', 8.0, 8.0, -1, 0, 0, false, false, false)
    end
end

RegisterNetEvent('ars_ambulancejob:playReviveAnim', function(data)
    if type(data) ~= 'table' then return end

    if data.anim == 'medic' then
        playMedicRevive(data)
    elseif data.anim == 'patient' then
        playPatientRevive(data)
    end
end)

RegisterNetEvent('ars_ambulancejob:cancelRevive', function()
    Ambulance.gettingRevived = false
    ClearPedTasks(cache.ped)
end)

exports.ox_target:addGlobalPlayer({
    {
        name = 'ars_ambulancejob_check_patient',
        icon = 'fas fa-magnifying-glass',
        label = locale('check_patient'),
        groups = Config.emsJobs,
        distance = 3.0,
        onSelect = function(data)
            checkPatient(data.entity)
        end,
    },
})
