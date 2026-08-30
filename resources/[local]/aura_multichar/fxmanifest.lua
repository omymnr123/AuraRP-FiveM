fx_version 'cerulean'
game 'gta5'

description 'Aura MultiChar - NextGen Character Selection System'
version '1.0.0'
author 'Elite UI/UX Engineer'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

server_exports {
    'GetActiveCharacter'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/app.js',
    'html/assets/*' -- Reservado para imágenes si el usuario decide agregarlas luego
}
