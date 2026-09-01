-- ===================================================
-- AURA PHONE - SERVER DEBUG & TESTING SUITE
-- ===================================================

-- Comando desde consola o admin: Enviar notificación a un ID específico
RegisterCommand('testnotif_sv', function(source, args)
    local targetSrc = tonumber(args[1])
    if not targetSrc then
        print("^1[AuraPhone-Debug] Uso: testnotif_sv [playerServerId] [app] [titulo] [mensaje]^7")
        return
    end

    local app = args[2] or "messages"
    local title = args[3] or "Aura OS"
    local message = args[4] or "Notificación de prueba enviada desde el servidor."

    TriggerClientEvent('aura_phone:client:newNotification', targetSrc, {
        app = app,
        title = title,
        message = message
    })
    print(("^2[AuraPhone-Debug] Notificación enviada al jugador %s^7"):format(targetSrc))
end, true) -- Solo admins / consola
