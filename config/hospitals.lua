Hospitals = {
    pillbox = {
        paramedic = {
            model = 's_m_m_scientist_01',
            pos = vector4(308.2672, -595.5335, 42.28403, 70.93318),
        },
        zone = {
            pos = vec3(299.0, -585.28, 43.28),
            size = vec3(200.0, 200.0, 200.0),
        },
        blip = {
            enable = true,
            name = 'Pillbox Hospital',
            type = 61,
            scale = 0.7,
            color = 2,
            pos = vector3(308.96, -591.52, 43.28),
        },
        respawn = {
            {
                bedPoint = vector4(319.2205, -581.2819, 44.204, 164.1656),
                spawnPoint = vector4(319.2205, -581.2819, 44.204, 164.1656),
            },
            {
                bedPoint = vector4(317.8326, -585.1843, 44.204, 336.9854),
                spawnPoint = vector4(317.8326, -585.1843, 44.204, 336.9854),
            },
        },
        stash = {
            ems_stash_1 = {
                label = 'EMS Stash',
                slots = 50,
                weight = 500000,
                minGrade = 0,
                pos = vector3(310.4091, -603.0366, 43.28411),
            },
        },
        garage = {
            ems_garage_1 = {
                model = 'mp_m_weapexp_01',
                pedPos = vec4(328.02, -570.34, 89.62, 194.91),
                spawn = vec4(328.02, -570.34, 89.62, 194.91),
                deposit = vec4(328.02, -570.34, 89.62, 194.91),
                driverSpawnCoords = vec4(328.02, -570.34, 89.62, 194.91),
                vehicles = {
                    { label = 'Vapid Speedo', model = 'emsspeedo', minGrade = 0 },
                    { label = 'Vapid Caracara', model = 'emscara', minGrade = 0 },
                    { label = 'Übermacht Rhinehart', model = 'emsrhinehart', minGrade = 0 },
                },
            },
        },
    },
}
