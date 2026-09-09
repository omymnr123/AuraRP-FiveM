fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'AuraRP Elite Development Team'
description 'AuraRP Phase 10: Custom Chat System & Synced 3D Text Engine'
version '1.0.0'

ui_page 'web/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/3dtext.lua',
    'client/api.lua',
    'client/main.lua'
}

server_scripts {
    'server/commands.lua',
    'server/api.lua',
    'server/main.lua'
}

files {
    'web/index.html',
    'web/css/style.css',
    'web/js/app.js'
}

dependencies {
    'ox_lib'
}
