fx_version 'cerulean'
game 'gta5'

description 'Aura Status - Sistema de Metabolismo y Estado'
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
    'server/main.lua',
    'server/consumables.lua'
}

dependencies {
    'ox_inventory',
    'oxmysql',
    'aura_core',
    'ox_lib'
}
