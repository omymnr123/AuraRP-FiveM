fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'AuraRP Elite Development Team'
description 'Aura Animations - Modern Glassmorphism Visual Frontend for RPEmotes'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/css/style.css',
    'web/js/animations_data.js',
    'web/js/app.js'
}

dependencies {
    'rpemotes'
}
