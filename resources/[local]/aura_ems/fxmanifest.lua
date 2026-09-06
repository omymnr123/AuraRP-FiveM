fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'AuraRP Elite Development Team'
description 'Aura EMS - The Ultimate Triple-A Emergency Medical Services Ecosystem'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@aura_jobs/config.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/dispatch.lua',
    'server/mdt.lua',
    'server/radio.lua'
}

client_scripts {
    'client/main.lua',
    'client/dispatch.lua',
    'client/field.lua',
    'client/stations.lua',
    'client/mdt.lua',
    'client/debug.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/css/style.css',
    'web/js/app.js'
}

dependencies {
    'oxmysql',
    'ox_lib',
    'ox_inventory',
    'ox_target',
    'aura_jobs',
    'aura_death',
    'aura_medical',
    'aura_status',
    'aura_minigames'
}
