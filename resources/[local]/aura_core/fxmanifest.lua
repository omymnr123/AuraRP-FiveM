fx_version 'cerulean'
game 'gta5'

description 'Aura Core - Connection & Registry System'
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
    'client/main.lua',
    'client/world.lua',
    'client/radio_checks.lua',
    'client/voice_override.lua'
}

