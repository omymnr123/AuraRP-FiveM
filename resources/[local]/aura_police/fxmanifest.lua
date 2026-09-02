fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'AuraRP Elite Development Team'
description 'Aura Police - Triple-A Law Enforcement Suite, Custody, Jail & Stations'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@aura_jobs/config.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/jail.lua'
}

client_scripts {
    'client/main.lua',
    'client/interactions.lua',
    'client/stations.lua',
    'client/jail.lua'
}

dependencies {
    'oxmysql',
    'ox_lib',
    'ox_inventory',
    'ox_target',
    'aura_jobs',
    'aura_economy'
}
