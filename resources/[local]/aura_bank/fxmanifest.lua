fx_version 'cerulean'
game 'gta5'

author 'Aura Scripts'
description 'Central Banking System Phase 5.5'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/script.js'
}

dependencies {
    'ox_lib',
    'ox_inventory',
    'ox_target',
    'aura_economy'
}
