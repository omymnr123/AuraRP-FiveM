fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'aura_medical'
author 'AuraRP Development Team'
description 'Fase 7: Sistema Avanzado de Diagnostico Medico, Dano Localizado y UI 3D'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/damage.lua',
    'client/scanner.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/damage.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/css/style.css',
    'web/js/app.js'
}

dependencies {
    'ox_lib',
    'oxmysql'
}
