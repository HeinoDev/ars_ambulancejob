Config.emergencyCalls = {
    enabled = true,
    minMedicsOnDuty = 1,
    maxActive = 2,
    intervalMinutes = { min = 3, max = 8 },
    expireMinutes = 12,
    spawnDistance = 120.0,
    interactDistance = 2.5,
    minHandleSeconds = 8,
    reward = {
        account = Config.rewards.account,
        min = 150,
        max = 350,
        fastBonus = 100,
        fastMinutes = 4,
    },
    streak = {
        windowMinutes = 15,
        maxCount = 5,
        bonusPerCall = 0.1,
    },
    blip = {
        sprite = 153,
        colour = 1,
        scale = 0.9,
    },
    scenarios = {
        {
            label = 'call_scenario_injured',
            models = { 'a_m_y_hipster_01', 'a_f_y_tourist_01', 'a_m_m_business_01', 'a_f_y_hipster_02' },
            anim = { dict = 'combat@damage@writhe', clip = 'writhe_loop' },
            steps = {
                { label = 'call_step_examine', line = 'call_line_injured', duration = 4000, scenario = 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', icon = 'fa-solid fa-stethoscope' },
                { label = 'call_step_bandage', duration = 6000, scenario = 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', icon = 'fa-solid fa-bandage', item = Config.treatmentItems.default, durability = true },
            },
        },
        {
            label = 'call_scenario_burn',
            models = { 'a_m_m_farmer_01', 'a_f_m_beach_01', 'a_m_y_beach_01' },
            anim = { dict = 'combat@damage@writhe', clip = 'writhe_loop' },
            steps = {
                { label = 'call_step_examine', line = 'call_line_burn', duration = 4000, scenario = 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', icon = 'fa-solid fa-stethoscope' },
                { label = 'call_step_burn', duration = 7000, scenario = 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', icon = 'fa-solid fa-fire-flame-curved', item = Config.treatmentItems.burn, durability = true },
            },
        },
        {
            label = 'call_scenario_cardiac',
            models = { 'a_m_m_fatlatin_01', 'a_f_m_bevhills_01', 'a_m_o_soucent_01' },
            anim = { dict = 'dead', clip = 'dead_a' },
            steps = {
                { label = 'call_step_examine', line = 'call_line_cardiac', duration = 3000, scenario = 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', icon = 'fa-solid fa-stethoscope' },
                { label = 'call_step_cpr', duration = 9000, anim = { dict = 'mini@cpr@char_a@cpr_str', clip = 'cpr_pumpchest' }, icon = 'fa-solid fa-heart-pulse' },
                { label = 'call_step_shock', duration = 4000, scenario = 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', icon = 'fa-solid fa-bolt', item = Config.items.defibrillator, durability = true },
            },
        },
        {
            label = 'call_scenario_overdose',
            models = { 'a_m_y_methhead_01', 'a_f_y_hipster_01', 'a_m_m_tramp_01' },
            anim = { dict = 'missfinale_c1@', clip = 'lying_dead_player0' },
            steps = {
                { label = 'call_step_examine', line = 'call_line_overdose', duration = 4000, scenario = 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', icon = 'fa-solid fa-stethoscope' },
                { label = 'call_step_stabilize', duration = 8000, scenario = 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', icon = 'fa-solid fa-kit-medical', item = Config.items.medkit },
            },
        },
    },
    locations = {
        vector4(195.17, -934.4, 30.69, 144.0),
        vector4(118.0, -1945.0, 20.7, 90.0),
        vector4(300.0, 200.0, 104.0, 160.0),
        vector4(-150.0, -250.0, 43.6, 250.0),
        vector4(1117.0, -645.0, 56.4, 30.0),
        vector4(-1117.0, -1040.0, 2.2, 120.0),
        vector4(1961.0, 3740.0, 32.3, 210.0),
        vector4(-60.0, -1600.0, 29.3, 50.0),
        vector4(-1393.0, -587.0, 30.3, 300.0),
        vector4(373.0, 325.0, 103.6, 255.0),
    },
}
