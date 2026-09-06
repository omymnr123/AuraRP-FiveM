fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'aura_death'
author 'AuraRP Development Team'
description 'Fase 8: Sistema Avanzado de Estado Critico, Coma, Bleed-out y NUI Glassmorphism'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/callbacks.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
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
