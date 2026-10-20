fx_version 'cerulean'
use_fxv2_oal 'yes'
lua54 'yes'
game 'gta5'

name 'ars_ambulancejob'
author 'Arius Scripts'
description 'Advanced ambulance job with an integrated death system'
version '2.0.0'

dependencies {
    'ox_lib',
    'ox_inventory',
    'ox_target',
    'oxmysql',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config/config.lua',
    'config/hospitals.lua',
    'config/calls.lua',
    'config/injuries.lua',
    'bridge/shared.lua',
}

ox_libs {
    'locale',
}

client_scripts {
    'config/weapons.lua',
    'bridge/client/common.lua',
    'bridge/client/esx.lua',
    'bridge/client/qb.lua',
    'bridge/client/custom.lua',
    'client/utils.lua',
    'client/main.lua',
    'client/injuries.lua',
    'client/death.lua',
    'client/patient.lua',
    'client/dispatch.lua',
    'client/calls.lua',
    'client/paramedic.lua',
    'client/stretcher.lua',
    'client/garage.lua',
    'client/medical_bag.lua',
    'client/stash.lua',
    'client/beds.lua',
    'client/debug.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/logs.lua',
    'bridge/server/esx.lua',
    'bridge/server/qb.lua',
    'bridge/server/custom.lua',
    'server/main.lua',
    'server/duty.lua',
    'server/death.lua',
    'server/treatment.lua',
    'server/paramedic.lua',
    'server/dispatch.lua',
    'server/calls.lua',
    'server/inventory.lua',
    'server/stretcher.lua',
    'server/commands.lua',
    'server/txadmin.lua',
}

ui_page 'web/build/index.html'

files {
    'web/build/index.html',
    'web/build/**/*',
    'locales/*.json',
}
