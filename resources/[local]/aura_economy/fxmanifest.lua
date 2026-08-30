fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Aura Framework - Lead Economist & System Architect'
description 'Aura Economy - Phase 4: Core Economy, Dynamic Market & Anti-Inflation Sinks'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/market.lua',
    'server/sinks.lua'
}

client_scripts {
    'client/main.lua'
}

server_exports {
    'GetMoney',
    'GetAccounts',
    'AddMoney',
    'RemoveMoney',
    'TransferMoney',
    'SetMoney',
    'GetMarketPrice',
    'GetMarketCatalog',
    'BuyMarketItem',
    'SellMarketItem',
    'LaunderBlackMoney',
    'ProcessMaintenanceSink',
    'GetGlobalEconomicStats'
}
