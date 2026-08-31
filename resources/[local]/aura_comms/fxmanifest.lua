fx_version 'cerulean'
game 'gta5'

description 'Aura Advanced Communications (Radio Bridge & Voice)'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
}

server_scripts {
    'server/radio.lua'
}

client_scripts {
    'client/radio.lua'
}

-- Si es necesario reemplazar la UI de pma-voice por completo, esto se haría
-- inyectando CSS desde el propio pma-voice, o usando esta ui_page si creamos
-- un wrapper NUI. Para este enfoque, mantendremos la lógica en lua y asumimos 
-- que el CSS de pma-voice será modificado para la estética de Aura.
