fx_version 'cerulean'
game 'gta5'

author 'Aura Framework'
description 'Aura Appearance Integration (Standalone with Illenium-Appearance)'

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}
