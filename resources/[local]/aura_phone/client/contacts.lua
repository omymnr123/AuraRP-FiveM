-- =========================================
-- AURA CONTACTS - CLIENT
-- =========================================

-- Obtener lista completa de contactos
RegisterNUICallback('getAllContacts', function(data, cb)
    lib.callback('aura_phone:server:getAllContacts', false, function(results)
        cb(results)
    end)
end)

-- Obtener info propia
RegisterNUICallback('getOwnInfo', function(data, cb)
    lib.callback('aura_phone:server:getOwnInfo', false, function(info)
        cb(info)
    end)
end)

-- Guardar / Editar contacto
RegisterNUICallback('saveContact', function(data, cb)
    lib.callback('aura_phone:server:saveContact', false, function(res)
        cb(res)
    end, data)
end)

-- Eliminar contacto
RegisterNUICallback('deleteContact', function(data, cb)
    lib.callback('aura_phone:server:deleteContact', false, function(success)
        cb({ success = success })
    end, data.id)
end)

-- Alternar favorito
RegisterNUICallback('toggleFavoriteContact', function(data, cb)
    lib.callback('aura_phone:server:toggleFavorite', false, function(success)
        cb({ success = success })
    end, data)
end)

-- Compartir Ubicación con Contacto
RegisterNUICallback('shareLocationWithContact', function(data, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local coordsStr = string.format("%.2f, %.2f", coords.x, coords.y)

    lib.callback('aura_phone:server:sendLocationToContact', false, function(success)
        if success then
            lib.notify({
                title = 'Ubicación Enviada',
                description = 'Has enviado tus coordenadas a ' .. (data.name or data.number),
                type = 'success',
                position = 'top-right'
            })
        end
        cb({ success = success })
    end, {
        target_number = data.number,
        coords = coordsStr
    })
end)

-- =========================================
-- PROXIMITY CONTACT SHARING (AirDrop / NameDrop)
-- =========================================

-- Escanear jugadores a menos de 3.5 metros
RegisterNUICallback('getNearbyPlayers', function(data, cb)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local activePlayers = GetActivePlayers()
    local nearbyIds = {}

    for _, player in ipairs(activePlayers) do
        local targetPed = GetPlayerPed(player)
        if targetPed ~= playerPed then
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(playerCoords - targetCoords)
            if distance <= 3.5 then
                local serverId = GetPlayerServerId(player)
                table.insert(nearbyIds, serverId)
            end
        end
    end

    if #nearbyIds == 0 then
        cb({})
        return
    end

    -- Obtener detalles desde el servidor
    lib.callback('aura_phone:server:getNearbyPlayerDetails', false, function(details)
        cb(details or {})
    end, nearbyIds)
end)

-- Enviar solicitud de contacto por AirDrop
RegisterNUICallback('sendContactShare', function(data, cb)
    lib.callback('aura_phone:server:sendContactShareRequest', false, function(res)
        cb(res)
    end, data.targetServerId)
end)

-- Aceptar contacto compartido
RegisterNUICallback('acceptContactShare', function(data, cb)
    lib.callback('aura_phone:server:acceptContactShare', false, function(res)
        cb(res)
    end, data)
end)

-- Recibir solicitud de contacto entrante por Proximidad (AirDrop)
RegisterNetEvent('aura_phone:client:receiveContactSharePrompt', function(data)
    -- Abrir el modal interactivo en el NUI
    SendNUIMessage({
        app = "contacts",
        action = "incomingContactShare",
        data = data
    })
    
    -- Si el teléfono no está abierto, emitir notificación sutil
    lib.notify({
        title = 'AirDrop Contacto',
        description = (data.name or 'Alguien') .. ' quiere compartir su contacto contigo. Abre el teléfono para aceptar.',
        type = 'inform',
        position = 'top-right'
    })
end)

