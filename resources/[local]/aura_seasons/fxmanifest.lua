fx_version 'cerulean'
game 'gta5'

name 'aura_seasons'
author 'AuraRP Development Team'
description 'Dynamic Seasons, Weather Engine & Advanced Thermal Survival System'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/weather.lua',
    'client/thermal.lua',
    'client/survival.lua',
    'client/admin.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/weather.lua',
    'server/consumables.lua',
    'server/admin.lua'
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/css/style.css',
    'ui/js/app.js'
}

dependencies {
    'ox_lib',
    'oxmysql'
}

lua54 'yes'
