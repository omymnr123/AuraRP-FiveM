fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'aura_progress'
author 'AuraRP Elite Development Team'
description 'AuraRP Standalone Glassmorphic Progress Bar Module'
version '1.0.0'

ui_page 'web/index.html'

client_scripts {
    'client/main.lua'
}

files {
    'web/index.html',
    'web/css/style.css',
    'web/js/app.js'
}

exports {
    'Start',
    'Cancel',
    'IsActive',
    'Show',
    'Hide'
}
