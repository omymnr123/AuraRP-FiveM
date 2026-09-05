Config = {}

-- Tecla por defecto para abrir el panel de animaciones (El usuario puede cambiarla en Esc > Teclado > FiveM)
Config.OpenKey = 'F3'

-- Comando en chat/consola para abrir el panel
Config.Command = 'emotes'
Config.CommandAlias = 'anim'

-- Si está en true, el menú se cerrará automáticamente al hacer clic en una animación
-- Si está en false, el menú se mantiene abierto para previsualizar animaciones libremente
Config.CloseOnSelect = false

-- Habilitar notificaciones en pantalla al ejecutar acciones
Config.ShowToasts = true

-- Idioma y títulos
Config.Locale = {
    title = "AURA",
    subtitle = "ANIMACIONES",
    searchPlaceholder = "Buscar animación, baile, caminata o expresión...",
    cancelAnim = "Detener Animación (X)",
    resetWalk = "Reiniciar Caminata",
    resetMood = "Reiniciar Expresión",
    close = "Cerrar (ESC)",
    emptyFavorites = "Aún no tienes animaciones favoritas. Haz clic en la estrella ⭐ de cualquier animación para fijarla aquí.",
    noResults = "No se encontraron animaciones que coincidan con tu búsqueda.",
    favAdded = "Añadido a favoritos",
    favRemoved = "Eliminado de favoritos"
}
