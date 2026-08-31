-- =========================================
-- AURA CONTACTS - SERVER
-- =========================================

-- Obtener todos los contactos del jugador
lib.callback.register('aura_phone:server:getAllContacts', function(source)
    local src = source
    local number = AuraPhone.PhoneToSource[src]
    if not number then return {} end

    local query = [[
        SELECT * FROM aura_phone_contacts 
        WHERE owner_number = ? 
        ORDER BY is_favorite DESC, contact_name ASC
    ]]
    local results = MySQL.query.await(query, {number})
    return results or {}
end)

-- Obtener información propia (Número y Nombre)
lib.callback.register('aura_phone:server:getOwnInfo', function(source)
    local src = source
    local number = AuraPhone.PhoneToSource[src]
    if not number then return { number = "Desconocido", name = "Mi Tarjeta" } end

    local charData = MySQL.single.await('SELECT firstname, lastname FROM characters WHERE phone_number = ?', {number})
    local fullName = "Mi Tarjeta"
    if charData and charData.firstname then
        fullName = charData.firstname .. " " .. (charData.lastname or "")
    end

    return {
        number = number,
        name = fullName
    }
end)

-- Guardar / Crear Contacto
lib.callback.register('aura_phone:server:saveContact', function(source, data)
    local src = source
    local number = AuraPhone.PhoneToSource[src]
    if not number then return { success = false, message = "No tienes teléfono registrado" } end

    local contactName = data.name and data.name:match("^%s*(.-)%s*$")
    local contactNumber = data.number and data.number:match("^%s*(.-)%s*$")
    local note = data.note or ""

    if not contactName or contactName == "" or not contactNumber or contactNumber == "" then
        return { success = false, message = "El nombre y el número son obligatorios" }
    end

    if data.id then
        -- Actualizar existente
        MySQL.update.await('UPDATE aura_phone_contacts SET contact_name = ?, contact_number = ?, note = ? WHERE id = ? AND owner_number = ?', {
            contactName, contactNumber, note, data.id, number
        })
        return { success = true, id = data.id }
    else
        -- Crear nuevo
        local id = MySQL.insert.await('INSERT INTO aura_phone_contacts (owner_number, contact_number, contact_name, note, is_favorite) VALUES (?, ?, ?, ?, ?)', {
            number, contactNumber, contactName, note, 0
        })
        return { success = true, id = id }
    end
end)

-- Eliminar Contacto
lib.callback.register('aura_phone:server:deleteContact', function(source, contactId)
    local src = source
    local number = AuraPhone.PhoneToSource[src]
    if not number or not contactId then return false end

    local affected = MySQL.update.await('DELETE FROM aura_phone_contacts WHERE id = ? AND owner_number = ?', {
        contactId, number
    })
    return affected > 0
end)

-- Alternar Favorito
lib.callback.register('aura_phone:server:toggleFavorite', function(source, data)
    local src = source
    local number = AuraPhone.PhoneToSource[src]
    if not number or not data.id then return false end

    local newStatus = data.is_favorite and 1 or 0
    MySQL.update.await('UPDATE aura_phone_contacts SET is_favorite = ? WHERE id = ? AND owner_number = ?', {
        newStatus, data.id, number
    })
    return true
end)

-- Enviar Ubicación directa a un contacto
lib.callback.register('aura_phone:server:sendLocationToContact', function(source, data)
    local src = source
    local senderNumber = AuraPhone.PhoneToSource[src]
    if not senderNumber or not data.target_number or not data.coords then return false end

    local targetNumber = data.target_number
    local coords = data.coords

    -- Buscar o crear chat
    local existingChat = MySQL.single.await('SELECT id FROM aura_phone_chats WHERE (number_1 = ? AND number_2 = ?) OR (number_1 = ? AND number_2 = ?)', {
        senderNumber, targetNumber, targetNumber, senderNumber
    })
    
    local chatId = nil
    if existingChat then
        chatId = existingChat.id
    else
        chatId = MySQL.insert.await('INSERT INTO aura_phone_chats (number_1, number_2, last_message) VALUES (?, ?, ?)', {
            senderNumber, targetNumber, '[Ubicación]'
        })
    end

    if not chatId then return false end

    -- Insertar mensaje de ubicación
    MySQL.insert.await('INSERT INTO aura_phone_messages (chat_id, sender_number, message_type, content) VALUES (?, ?, ?, ?)', {
        chatId, senderNumber, 'location', coords
    })

    -- Actualizar chat
    MySQL.update.await('UPDATE aura_phone_chats SET last_message = ?, last_update = NOW() WHERE id = ?', {
        '[Ubicación]', chatId
    })

    -- Notificar en tiempo real si el receptor está online
    local targetSrc = AuraPhone.ActivePhones[targetNumber]
    if targetSrc then
        TriggerClientEvent('aura_phone:client:receiveMessage', targetSrc, {
            chat_id = chatId,
            sender_number = senderNumber,
            message_type = 'location',
            content = coords
        })
    end

    return true
end)

-- =========================================
-- PROXIMITY CONTACT SHARING (AirDrop / NameDrop)
-- =========================================

-- Resolver nombres de personajes cercanos
lib.callback.register('aura_phone:server:getNearbyPlayerDetails', function(source, nearbyServerIds)
    local results = {}
    if not nearbyServerIds or #nearbyServerIds == 0 then return results end

    for _, targetSrc in ipairs(nearbyServerIds) do
        local targetSrcNum = tonumber(targetSrc)
        if targetSrcNum and targetSrcNum ~= source then
            local targetNumber = AuraPhone.PhoneToSource[targetSrcNum]
            local targetName = "Ciudadano (" .. targetSrcNum .. ")"

            if targetNumber then
                local charData = MySQL.single.await('SELECT firstname, lastname FROM characters WHERE phone_number = ?', {targetNumber})
                if charData and charData.firstname then
                    targetName = charData.firstname .. " " .. (charData.lastname or "")
                end
            end

            table.insert(results, {
                serverId = targetSrcNum,
                name = targetName,
                number = targetNumber or "Sin Teléfono"
            })
        end
    end

    return results
end)

-- Enviar solicitud de compartir contacto
lib.callback.register('aura_phone:server:sendContactShareRequest', function(source, targetServerId)
    local src = source
    local senderNumber = AuraPhone.PhoneToSource[src]
    if not senderNumber then return { success = false, message = "No tienes teléfono registrado" } end

    local targetSrc = tonumber(targetServerId)
    if not targetSrc or not GetPlayerPed(targetSrc) or targetSrc == src then
        return { success = false, message = "Persona no encontrada" }
    end

    local charData = MySQL.single.await('SELECT firstname, lastname FROM characters WHERE phone_number = ?', {senderNumber})
    local senderName = "Ciudadano"
    if charData and charData.firstname then
        senderName = charData.firstname .. " " .. (charData.lastname or "")
    end

    -- Enviar evento al cliente del receptor
    TriggerClientEvent('aura_phone:client:receiveContactSharePrompt', targetSrc, {
        senderSrc = src,
        name = senderName,
        number = senderNumber
    })

    return { success = true, message = "Solicitud enviada" }
end)

-- Aceptar contacto compartido (Guardar en base de datos)
lib.callback.register('aura_phone:server:acceptContactShare', function(source, data)
    local receiverSrc = source
    local receiverNumber = AuraPhone.PhoneToSource[receiverSrc]
    if not receiverNumber then return { success = false } end

    local contactName = data.name or "Desconocido"
    local contactNumber = data.number

    if not contactNumber then return { success = false } end

    -- Comprobar si ya existe
    local exists = MySQL.scalar.await('SELECT 1 FROM aura_phone_contacts WHERE owner_number = ? AND contact_number = ?', {
        receiverNumber, contactNumber
    })

    if not exists then
        MySQL.insert.await('INSERT INTO aura_phone_contacts (owner_number, contact_number, contact_name, is_favorite, note) VALUES (?, ?, ?, ?, ?)', {
            receiverNumber, contactNumber, contactName, 0, 'Añadido por Proximidad'
        })
    end

    -- Notificar al emisor si sigue online
    if data.senderSrc then
        TriggerClientEvent('ox_lib:notify', data.senderSrc, {
            title = 'Contacto Aceptado',
            description = 'Han guardado tu número de teléfono con éxito.',
            type = 'success',
            position = 'top-right'
        })
    end

    return { success = true }
end)

