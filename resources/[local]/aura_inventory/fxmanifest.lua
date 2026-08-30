fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Aura Framework - Lead System Architect & UI/UX Designer'
description 'Aura Inventory - Phase 5: ox_inventory Currency Bridge & Dynamic Market Shops'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

dependencies {
    'ox_inventory',
    'aura_economy'
}
