Config = {}

-- Distancias de proximidad para comandos de rol (en metros)
Config.Proximity = {
    me = 15.0,
    doCmd = 15.0
}

-- ==============================================================================
-- >> CONFIGURACIÓN DEL MOTOR DE TEXTO 3D (/me) <<
-- ==============================================================================
Config.Text3D = {
    duration = 8000,           -- Duración en pantalla en ms (8 segundos)
    maxDistance = 15.0,        -- Distancia máxima de renderizado

    -- ==========================================================================
    -- >>> [AQUÍ SE CAMBIA EL TAMAÑO DE LA FUENTE 3D A MANO] <<<
    -- Valores recomendados:
    --   0.18 = Muy pequeña / Ultra fina
    --   0.22 = Pequeña y estilizada (Valor Actual)
    --   0.28 = Mediana estándar
    --   0.35 = Grande
    -- ==========================================================================
    scale = 0.22,              -- <--- MODIFICA ESTE VALOR PARA CAMBIAR EL TAMAÑO
    
    driftSpeed = 0.0,          -- 0.0 = Sin desplazamiento (fijo sobre la cabeza)
    baseOffsetZ = 0.35,        -- Altura fija sobre la cabeza (bone SKEL_Head)
    font = 0,                  -- 0 = Fuente fina limpia nativa de GTA V
    primaryColor = { r = 64, g = 224, b = 208 }, -- Turquesa AuraRP (#40E0D0)
    shadowColor = { r = 255, g = 0, b = 127 },  -- Resplandor Rosa Neón AuraRP (#FF007F)
    outline = true
}

-- Configuración de la interfaz NUI 2D
Config.UI = {
    hideTimeout = 7000,        -- Tiempo en ms antes de ocultar el chat inactivo
    maxMessages = 80,          -- Límite máximo de mensajes conservados en el DOM
    defaultColor = '#E2E8F0'
}

-- Paleta de colores temáticos AuraRP
Config.Colors = {
    turquoise = '#40E0D0',
    neonPink = '#FF007F',
    ooc = '#E2E8F0',
    oocAuthor = '#94A3B8',
    system = '#38BDF8',
    error = '#F87171',
    success = '#4ADE80',
    warning = '#FBBF24'
}

-- Sugerencias de comandos predeterminadas para el autocompletado
Config.DefaultSuggestions = {
    {
        name = '/me',
        help = 'Acción física de tu personaje (Visible en 2D a 15m y en 3D sobre tu cabeza)',
        params = {
            { name = 'acción', help = 'Descripción de la acción que realiza tu personaje' }
        }
    },
    {
        name = '/do',
        help = 'Descripción del entorno o consecuencias (Visible únicamente en chat 2D a 15m)',
        params = {
            { name = 'entorno', help = 'Descripción del entorno o respuesta' }
        }
    },
    {
        name = '/ooc',
        help = 'Mensaje fuera de personaje (OOC) enviado globalmente a todo el servidor',
        params = {
            { name = 'mensaje', help = 'Texto fuera de rol' }
        }
    },
    {
        name = '/clear',
        help = 'Limpia los mensajes de tu ventana de chat local'
    }
}
