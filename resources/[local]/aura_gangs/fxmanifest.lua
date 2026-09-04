fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'aura_gangs'
author 'AuraRP Development Team'
description 'Underground Mafia & Gang Ecosystem - Vehicle Theft, Chop Shop, Money Laundering, Meth Lab & Turf Wars'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/theft.lua',
    'client/chopshop.lua',
    'client/illegal.lua',
    'client/graffiti.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/theft.lua',
    'server/chopshop.lua',
    'server/illegal.lua',
    'server/graffiti.lua',
    'server/darkweb.lua'
}

dependencies {
    'oxmysql',
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'aura_jobs',
    'aura_police',
    'aura_economy',
    'aura_minigames'
}
