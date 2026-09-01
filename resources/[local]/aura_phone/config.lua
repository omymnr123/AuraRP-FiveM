AuraConfig = {}

-- Webhook de Discord para almacenamiento de fotos y multimedia
-- Reemplaza con tu Webhook de Discord real. Si se deja vacío o placeholder, el sistema guardará la captura localmente de forma segura.
AuraConfig.DiscordWebhook = "https://discord.com/api/webhooks/1345437894562414644/t8JqD-GqP1uXJgYJc_sample_placeholder"

-- Configuración de la Cámara
AuraConfig.Camera = {
    ShutterSound = true,        -- Sonido de obturador al tomar foto
    FlashEnabled = true,        -- Permitir alternar linterna/flash
    DefaultZoom = 1.0,          -- Zoom por defecto
    MaxZoom = 3.0,
    MinZoom = 0.5,
    InstructionalHUD = true,    -- Mostrar caja de instrucciones en la esquina superior izquierda
}
