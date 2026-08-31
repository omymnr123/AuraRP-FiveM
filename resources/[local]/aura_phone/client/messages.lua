-- =========================================
-- AURA MESSAGES (WhatsApp Clone) - CLIENT
-- =========================================

-- NUI Callbacks para Mensajería
RegisterNUICallback('getChats', function(data, cb)
    lib.callback('aura_phone:server:getChats', false, function(results)
        cb(results)
    end)
end)

RegisterNUICallback('getMessages', function(data, cb)
    lib.callback('aura_phone:server:getMessages', false, function(results)
        cb(results)
    end, data)
end)

RegisterNUICallback('sendMessage', function(data, cb)
    lib.callback('aura_phone:server:sendMessage', false, function(results)
        cb(results)
    end, data)
end)

RegisterNUICallback('markRead', function(data, cb)
    lib.callback('aura_phone:server:markRead', false, function(results)
        cb(results)
    end, data)
end)

-- Feature: Compartir Ubicación GPS
RegisterNUICallback('sendLocation', function(data, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local coordsStr = string.format("%.2f, %.2f", coords.x, coords.y)

    -- Le decimos a NUI que la ubicación está lista para enviar
    SendNUIMessage({
        app = "messages",
        action = "locationReady",
        coords = coordsStr
    })
    
    cb('ok')
end)

-- Feature: Recibir Click en Ubicación GPS y Setear Waypoint Nativo
RegisterNUICallback('setWaypoint', function(data, cb)
    if data.coords then
        -- data.coords vendrá en formato "X.XX, Y.YY"
        local xStr, yStr = string.match(data.coords, "([^,]+),([^,]+)")
        if xStr and yStr then
            local x = tonumber(xStr)
            local y = tonumber(yStr)
            if x and y then
                SetNewWaypoint(x, y)
                lib.notify({
                    title = 'GPS Actualizado',
                    description = 'Se ha marcado la ruta en tu mapa.',
                    type = 'success',
                    position = 'top-right'
                })
            end
        end
    end
    cb('ok')
end)

-- Recibir mensaje en tiempo real desde el servidor
RegisterNetEvent('aura_phone:client:receiveMessage', function(data)
    -- Enviar al frontend (NUI)
    SendNUIMessage({
        app = "messages",
        action = "newMessage",
        chat_id = data.chat_id,
        sender_number = data.sender_number,
        message_type = data.message_type,
        content = data.content
    })
    
    -- Si el teléfono está cerrado, emitimos un sonido de notificación sutil
    -- TriggerServerEvent('InteractSound_SV:PlayOnSource', 'notification', 0.2)
    -- (Descomenta si usas InteractSound o pon tu propio sistema de sonido nativo aquí)
end)
