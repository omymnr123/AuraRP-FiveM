fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'aura_medical'
author 'AuraRP Development Team'
description 'Fase 11: Sistema Interactivo de Diagnostico Medico P2P y Telemetria Quirurgica'
version '2.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/damage.lua',
    'client/interact.lua',
    'client/scanner.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/damage.lua',
    'server/sync.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/css/style.css',
    'web/js/app.js',
    'web/images/silueta_hombre.png',
    'web/images/silueta_mujer.png'
}

dependencies {
    'ox_lib',
    'oxmysql',
    'ox_target'
}
