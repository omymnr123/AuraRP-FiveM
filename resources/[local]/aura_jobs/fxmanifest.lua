fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'AuraRP Elite Development Team'
description 'Aura Jobs & Universal Business Billing Framework'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/society.lua',
    'server/main.lua',
    'server/paycheck.lua',
    'server/billing.lua',
    'server/vendors.lua',
    'server/doors.lua'
}

client_scripts {
    'client/main.lua',
    'client/billing.lua',
    'client/vendors.lua',
    'client/blips.lua',
    'client/doors.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/css/style.css',
    'web/js/app.js',
    'web/images/*.png'
}

dependencies {
    'oxmysql',
    'ox_lib',
    'ox_inventory',
    'ox_target',
    'aura_economy'
}
