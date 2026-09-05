fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'aura_minigames'
author 'AuraRP Development Team'
description 'AuraRP Ultimate AAA Minigames Suite - Lockpicking, ECU Waveform, Chemical Reactor & Cipher'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/css/style.css',
    'web/js/audio.js',
    'web/js/lockpick.js',
    'web/js/ecubypass.js',
    'web/js/reactor.js',
    'web/js/cipher.js',
    'web/js/weedpackaging.js',
    'web/js/app.js'
}

exports {
    'Lockpick',
    'ECUBypass',
    'ChemicalReactor',
    'CipherMatrix',
    'WeedPackaging'
}
