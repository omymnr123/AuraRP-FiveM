fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'AuraRP Elite Development Team'
description 'Aura Hub - Master Pause Menu, HR Management & Global Announcement System'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@aura_jobs/config.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/css/style.css',
    'web/js/app.js',
    'web/img/*'
}

dependencies {
    'oxmysql',
    'ox_lib',
    'aura_economy',
    'aura_jobs'
}
