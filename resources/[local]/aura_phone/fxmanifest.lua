fx_version 'cerulean'
game 'gta5'

description 'Aura OS (Bespoke Smartphone System)'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    '@ox_lib/init.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/calls.lua',
    'server/messages.lua',
    'server/contacts.lua',
    'server/settings.lua'
}

client_scripts {
    'client/main.lua',
    'client/calls.lua',
    'client/messages.lua',
    'client/contacts.lua',
    'client/settings.lua'
}

files {
    'html/index.html',
    'html/css/os.css',
    'html/css/apps.css',
    'html/js/apps.js',
    'html/js/core.js',
    'html/js/bank.js',
    'html/js/phone.js',
    'html/js/messages.js',
    'html/js/contacts.js',
    'html/js/settings.js',
    'audio/*.mp3'
}
