-- =========================================
-- AURA MESSAGES (WhatsApp Clone) - SERVER
-- =========================================

-- Obtener Lista de Chats
lib.callback.register('aura_phone:server:getChats', function(source)
    local src = source
    local number = AuraPhone.PhoneToSource[src]
    if not number then return {} end

    -- Obtenemos los chats y tratamos de hacer JOIN con la tabla de contactos
    local query = [[
        SELECT c.*, 
            IF(c.number_1 = ?, c.number_2, c.number_1) as other_number,
            cont.contact_name,
            c.last_message as last_message,
            (SELECT message_type FROM aura_phone_messages WHERE chat_id = c.id ORDER BY created_at DESC LIMIT 1) as last_message_type,
            (SELECT COUNT(*) FROM aura_phone_messages WHERE chat_id = c.id AND sender_number != ? AND is_read = 0) as unread
        FROM aura_phone_chats c
        LEFT JOIN aura_phone_contacts cont ON cont.owner_number = ? AND cont.contact_number = IF(c.number_1 = ?, c.number_2, c.number_1)
        WHERE c.number_1 = ? OR c.number_2 = ?
        ORDER BY c.last_update DESC
    ]]
    
    local results = MySQL.query.await(query, {number, number, number, number, number, number})
    return results or {}
end)

-- Obtener Mensajes de un Chat
lib.callback.register('aura_phone:server:getMessages', function(source, data)
    local src = source
    local number = AuraPhone.PhoneToSource[src]
    if not number then return { messages = {} } end

    local chatId = data.chat_id
    local targetNumber = data.target_number

    -- Si no hay chatId, busquemos si existe un chat entre estos dos
    if not chatId and targetNumber then
        local chat = MySQL.single.await('SELECT id FROM aura_phone_chats WHERE (number_1 = ? AND number_2 = ?) OR (number_1 = ? AND number_2 = ?)', {
            number, targetNumber, targetNumber, number
        })
        if chat then
            chatId = chat.id
        end
    end

    if not chatId then
        -- Es un chat totalmente nuevo, no hay mensajes
        return { chat_id = nil, messages = {} }
    end

    -- Obtenemos los mensajes
    local query = [[
        SELECT id, chat_id, sender_number, message_type, content, is_read, created_at,
               IF(sender_number = ?, 1, 0) as is_me
        FROM aura_phone_messages
        WHERE chat_id = ?
        ORDER BY created_at ASC
    ]]
    local messages = MySQL.query.await(query, {number, chatId})
    
    return { chat_id = chatId, messages = messages or {} }
end)

-- Enviar Mensaje
lib.callback.register('aura_phone:server:sendMessage', function(source, data)
    local src = source
    local senderNumber = AuraPhone.PhoneToSource[src]
    if not senderNumber then return { success = false } end

    local chatId = data.chat_id
    local targetNumber = data.target_number
    local msgType = data.message_type or 'text'
    local content = data.content

    -- Si no hay chatId, buscamos si ya existe conversación previa
    if not chatId and targetNumber then
        local existingChat = MySQL.single.await('SELECT id FROM aura_phone_chats WHERE (number_1 = ? AND number_2 = ?) OR (number_1 = ? AND number_2 = ?)', {
            senderNumber, targetNumber, targetNumber, senderNumber
        })
        
        if existingChat then
            chatId = existingChat.id
        else
            local summary = msgType == 'text' and content or ('[' .. msgType .. ']')
            chatId = MySQL.insert.await('INSERT INTO aura_phone_chats (number_1, number_2, last_message) VALUES (?, ?, ?)', {
                senderNumber, targetNumber, summary
            })
        end
    end

    if not chatId then return { success = false } end

    -- Insertar el mensaje
    MySQL.insert.await('INSERT INTO aura_phone_messages (chat_id, sender_number, message_type, content) VALUES (?, ?, ?, ?)', {
        chatId, senderNumber, msgType, content
    })

    -- Actualizar last_message del chat y marca de tiempo
    local summary = msgType == 'text' and content or ('[' .. msgType .. ']')
    MySQL.update.await('UPDATE aura_phone_chats SET last_message = ?, last_update = NOW() WHERE id = ?', {
        summary, chatId
    })

    -- Notificar en tiempo real al receptor si está online
    if targetNumber then
        local targetSrc = AuraPhone.ActivePhones[targetNumber]
        if targetSrc then
            TriggerClientEvent('aura_phone:client:receiveMessage', targetSrc, {
                chat_id = chatId,
                sender_number = senderNumber,
                message_type = msgType,
                content = content
            })
        end
    end

    return { success = true, chat_id = chatId }
end)

-- Marcar mensajes como leidos
lib.callback.register('aura_phone:server:markRead', function(source, data)
    local src = source
    local number = AuraPhone.PhoneToSource[src]
    if not number or not data.chat_id then return false end

    MySQL.update.await('UPDATE aura_phone_messages SET is_read = 1 WHERE chat_id = ? AND sender_number != ?', {
        data.chat_id, number
    })
    return true
end)
