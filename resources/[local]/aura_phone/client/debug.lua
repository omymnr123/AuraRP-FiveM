-- ===================================================
-- AURA PHONE - CLIENT DEBUG & TESTING SUITE
-- ===================================================

RegisterNetEvent('aura_phone:client:newNotification', function(data)
    SendNUIMessage({
        action = "newNotification",
        app = data.app or "messages",
        title = data.title or "Aura OS",
        message = data.message or ""
    })
end)

-- 1. Comando: Probar Notificación Genérica o Específica
RegisterCommand('testnotif', function(source, args)
    local app = args[1] or "messages"
    local title = args[2] or "Otto Suarez"
    local message = args[3]
    
    -- Concatenar mensaje si tiene espacios
    if #args >= 3 then
        local msgTable = {}
        for i = 3, #args do
            table.insert(msgTable, args[i])
        end
        message = table.concat(msgTable, " ")
    else
        if app == "bank" then
            title = title == "Otto Suarez" and "AuraBank" or title
            message = "Has recibido una transferencia de $5,000"
        elseif app == "calls" then
            title = title == "Otto Suarez" and "Llamada Perdida" or title
            message = "555-0199 (hace 2 min)"
        else
            message = "¡Hola! Este es un mensaje de prueba para verificar las notificaciones en la pantalla de bloqueo."
        end
    end

    SendNUIMessage({
        action = "newNotification",
        app = app,
        title = title,
        message = message
    })

    lib.notify({
        title = 'Aura OS Debug',
        description = ('Notificación de [%s] enviada al teléfono'):format(app),
        type = 'info',
        position = 'top-right'
    })
end, false)

-- 2. Comando: Probar Llamada Entrante
RegisterCommand('testcall', function(source, args)
    local callerName = args[1] or "Michael De Santa"
    local callerNumber = args[2] or "555-0199"

    TriggerServerEvent('aura_phone:server:startTestCall', callerName, callerNumber)

    lib.notify({
        title = 'Aura OS Debug',
        description = ('Llamada de %s (%s). Pulsa [ENTER] para contestar o [BORRAR] para declinar'):format(callerName, callerNumber),
        type = 'info',
        position = 'top-right',
        duration = 7000
    })
end, false)

-- 3. Comando: Probar Mensaje Entrante
RegisterCommand('testmsg', function(source, args)
    local senderName = args[1] or "Franklin Clinton"
    local senderNumber = args[2] or "555-8822"
    local content = "Hermano, nos vemos en el garaje de Grove Street."

    if #args >= 3 then
        local msgTable = {}
        for i = 3, #args do
            table.insert(msgTable, args[i])
        end
        content = table.concat(msgTable, " ")
    end

    SendNUIMessage({
        app = "messages",
        action = "newMessage",
        sender_name = senderName,
        sender_number = senderNumber,
        message_type = "text",
        content = content
    })

    lib.notify({
        title = 'Aura OS Debug',
        description = ('Mensaje de %s recibido en el teléfono'):format(senderName),
        type = 'info',
        position = 'top-right'
    })
end, false)

-- 4. Comando: Probar Alerta Bancaria
RegisterCommand('testbank', function(source, args)
    local amount = args[1] or "10000"
    local sender = args[2] or "Maze Bank"
    local formattedAmount = tostring(amount)

    SendNUIMessage({
        action = "newNotification",
        app = "bank",
        title = "AuraBank - Transferencia",
        message = ("Has recibido $%s de %s"):format(formattedAmount, sender),
        icon = "fas fa-university",
        color = "#00F0FF"
    })

    lib.notify({
        title = 'Aura OS Debug',
        description = ('Alerta bancaria de $%s enviada al teléfono'):format(formattedAmount),
        type = 'info',
        position = 'top-right'
    })
end, false)

-- 5. Comando: Limpiar todas las notificaciones del teléfono
RegisterCommand('clearnotifs', function()
    SendNUIMessage({
        action = "clearAllNotifications"
    })

    lib.notify({
        title = 'Aura OS Debug',
        description = 'Todas las notificaciones han sido limpiadas',
        type = 'success',
        position = 'top-right'
    })
end, false)

-- 6. Comando: Reparar/Resetear estado y animación del teléfono
RegisterCommand('fixphone', function()
    if AuraPhoneClient then
        AuraPhoneClient.isInCall = false
        AuraPhoneClient.isPhoneOpen = false
        AuraPhoneClient.RemovePhoneProp()
    end
    
    local ped = PlayerPedId()
    StopAnimTask(ped, "cellphone@", "cellphone_call_listen_base", 1.0)
    StopAnimTask(ped, "cellphone@", "cellphone_call_in", 1.0)
    StopAnimTask(ped, "cellphone@", "cellphone_call_out", 1.0)
    StopAnimTask(ped, "cellphone@", "cellphone_text_in", 1.0)
    ClearPedSecondaryTask(ped)
    
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closePhone" })
    SendNUIMessage({ action = "callEnded", reason = "Llamada finalizada" })

    lib.notify({
        title = 'Aura OS Debug',
        description = 'Estado y animación del teléfono reseteados correctamente',
        type = 'success',
        position = 'top-right'
    })
end, false)

-- 7. Comando: Añadir foto de prueba a la Galería
RegisterCommand('testphoto', function(source, args)
    local sampleUrls = {
        "https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=800&q=80",
        "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=800&q=80",
        "https://images.unsplash.com/photo-1509198397868-475647b2a1e5?auto=format&fit=crop&w=800&q=80"
    }
    local url = args[1] or sampleUrls[math.random(1, #sampleUrls)]
    TriggerServerEvent('aura_phone:server:saveGalleryPhoto', url)

    lib.notify({
        title = 'Aura Galería',
        description = 'Foto de prueba añadida a tu Galería multimedia',
        type = 'success',
        position = 'top-right'
    })
end, false)
