fx_version 'cerulean'
game 'gta5'

description 'Aura Status - Sistema de Metabolismo y Estado'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@oxmysql/lib/MySQL.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua',
    'server/consumables.lua'
}

dependencies {
    'ox_inventory',
    'oxmysql',
    'aura_core',
    'ox_lib'
}
