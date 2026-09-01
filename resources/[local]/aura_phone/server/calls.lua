-- Registro en memoria de estado telefónico
AuraPhone = AuraPhone or {}
AuraPhone.ActivePhones = {} -- [phoneNumber] = source
AuraPhone.PhoneToSource = {} -- [source] = phoneNumber
AuraPhone.CallData = {} -- [source] = {target = targetSrc, channel = channelId, status = 'ringing' | 'active'}

-- Evento al cargar personaje (Invocado desde tu script de core/multichar)
exports('setPhoneOnline', function(source, phoneNumber)
    AuraPhone.ActivePhones[phoneNumber] = source
    AuraPhone.PhoneToSource[source] = phoneNumber
end)

-- Iniciar una llamada
lib.callback.register('aura_phone:server:dialNumber', function(source, targetNumber)
    local callerSrc = source
    local callerNumber = AuraPhone.PhoneToSource[callerSrc]
    
    if not callerNumber then return false, "No tienes un número asignado" end
    if callerNumber == targetNumber then return false, "No puedes llamarte a ti mismo" end

    local targetSrc = AuraPhone.ActivePhones[targetNumber]
    
    -- Si el jugador no está online o está en otra llamada
    if not targetSrc or AuraPhone.CallData[targetSrc] then 
        -- Registrar la llamada fallida para que aparezca en Recientes
        MySQL.insert('INSERT INTO aura_phone_calls (caller_number, receiver_number, status, duration) VALUES (?, ?, ?, ?)', {
            callerNumber, targetNumber, 'declined', 0
        })
        
        if targetSrc then
            return false, "Línea ocupada", "linea_ocupada.mp3"
        else
            -- Comprobar si el numero existe en la BD
            local exists = MySQL.scalar.await('SELECT 1 FROM characters WHERE phone_number = ?', {targetNumber})
            if exists then
                return false, "El teléfono está apagado o fuera de cobertura", "telefono_apagado.mp3"
            else
                return false, "El número marcado no existe", "numero_no_existe.mp3"
            end
        end
    end

    -- Generar canal único
    local callChannel = math.random(10000, 99999)

    -- Guardar estado temporal (Timbrando)
    AuraPhone.CallData[callerSrc] = { target = targetSrc, channel = callChannel, status = 'ringing', isCaller = true, number = callerNumber, targetNumber = targetNumber, startTime = 0 }
    AuraPhone.CallData[targetSrc] = { target = callerSrc, channel = callChannel, status = 'ringing', isCaller = false, number = targetNumber, targetNumber = callerNumber, startTime = 0 }

    -- Avisar al destino que está recibiendo llamada
    TriggerClientEvent('aura_phone:client:incomingCall', targetSrc, callerNumber)

    return true, "Llamando..."
end)

-- Iniciar Llamada de Prueba / Simulada
RegisterNetEvent('aura_phone:server:startTestCall', function(callerName, callerNumber)
    local src = source
    local myNumber = AuraPhone.GetPlayerPhoneNumber(src) or "555-0000"
    local cNumber = callerNumber or "555-0199"
    local cName = callerName or "Michael De Santa"
    
    AuraPhone.CallData[src] = {
        target = -1,
        channel = math.random(10000, 99999),
        status = 'ringing',
        isCaller = false,
        number = myNumber,
        targetNumber = cNumber,
        startTime = 0,
        isSimulated = true
    }

    TriggerClientEvent('aura_phone:client:incomingCall', src, cNumber, cName)
end)

-- Aceptar Llamada
RegisterNetEvent('aura_phone:server:acceptCall', function()
    local src = source
    local data = AuraPhone.CallData[src]
    
    if data and data.status == 'ringing' then
        local now = os.time()
        data.status = 'active'
        data.startTime = now
        
        if data.target and data.target ~= -1 and AuraPhone.CallData[data.target] then
            AuraPhone.CallData[data.target].status = 'active'
            AuraPhone.CallData[data.target].startTime = now
            TriggerClientEvent('aura_phone:client:callAccepted', data.target, data.channel)
        end

        -- Ordenar a este cliente que cambie al canal
        TriggerClientEvent('aura_phone:client:callAccepted', src, data.channel)
    else
        -- Fallback seguro para llamadas simuladas o sin estado
        TriggerClientEvent('aura_phone:client:callAccepted', src, math.random(10000, 99999))
    end
end)

-- Rechazar o Finalizar Llamada
RegisterNetEvent('aura_phone:server:endCall', function()
    local src = source
    local data = AuraPhone.CallData[src]

    if data then
        local targetSrc = data.target
        local duration = 0
        local finalStatus = 'missed'
        
        if data.status == 'active' then
            duration = data.startTime > 0 and (os.time() - data.startTime) or 0
            finalStatus = 'answered'
        elseif data.status == 'ringing' and not data.isCaller then
            finalStatus = 'declined'
        end

        -- Solo registrar si no es llamada simulada y es el llamante
        if not data.isSimulated and data.isCaller then
            MySQL.insert('INSERT INTO aura_phone_calls (caller_number, receiver_number, status, duration) VALUES (?, ?, ?, ?)', {
                data.number, data.targetNumber, finalStatus, duration
            })
        end
        
        AuraPhone.CallData[src] = nil
        if targetSrc and targetSrc ~= -1 and AuraPhone.CallData[targetSrc] then
            if not AuraPhone.CallData[targetSrc].isSimulated and AuraPhone.CallData[targetSrc].isCaller then
                MySQL.insert('INSERT INTO aura_phone_calls (caller_number, receiver_number, status, duration) VALUES (?, ?, ?, ?)', {
                    AuraPhone.CallData[targetSrc].number, AuraPhone.CallData[targetSrc].targetNumber, finalStatus, duration
                })
            end
            AuraPhone.CallData[targetSrc] = nil
            TriggerClientEvent('aura_phone:client:callEnded', targetSrc, "Llamada finalizada")
        end
        
        TriggerClientEvent('aura_phone:client:callEnded', src, "Llamada finalizada")
    else
        -- Fallback seguro: siempre enviar callEnded al cliente para que no quede atascado
        TriggerClientEvent('aura_phone:client:callEnded', src, "Llamada finalizada")
    end
end)

-- NUI Callbacks: DB Fetching
lib.callback.register('aura_phone:server:getRecents', function(source)
    local src = source
    local number = AuraPhone.GetPlayerPhoneNumber(src)
    if not number then return {} end

    -- Obtenemos llamadas y tratamos de hacer un JOIN con contactos si existe
    local query = [[
        SELECT c.*, 
            IF(c.caller_number = ?, 1, 0) as isOutgoing,
            IF(c.caller_number = ?, c.receiver_number, c.caller_number) as number,
            cont.contact_name
        FROM aura_phone_calls c
        LEFT JOIN aura_phone_contacts cont ON cont.owner_number = ? AND cont.contact_number = IF(c.caller_number = ?, c.receiver_number, c.caller_number)
        WHERE c.caller_number = ? OR c.receiver_number = ?
        ORDER BY c.created_at DESC LIMIT 30
    ]]
    local results = MySQL.query.await(query, {number, number, number, number, number, number})
    return results or {}
end)

lib.callback.register('aura_phone:server:getContacts', function(source)
    local src = source
    local number = AuraPhone.GetPlayerPhoneNumber(src)
    if not number then return {} end

    local results = MySQL.query.await('SELECT * FROM aura_phone_contacts WHERE owner_number = ? ORDER BY is_favorite DESC, contact_name ASC', {number})
    return results or {}
end)

lib.callback.register('aura_phone:server:getFavorites', function(source)
    local src = source
    local number = AuraPhone.GetPlayerPhoneNumber(src)
    if not number then return {} end

    local results = MySQL.query.await('SELECT * FROM aura_phone_contacts WHERE owner_number = ? AND is_favorite = 1 ORDER BY contact_name ASC', {number})
    return results or {}
end)

lib.callback.register('aura_phone:server:addContact', function(source, name, targetNumber)
    local src = source
    local number = AuraPhone.GetPlayerPhoneNumber(src)
    
    if not number then 
        print("^1[AuraPhone] Error: No se pudo obtener el numero del Source " .. tostring(src) .. "^7")
        return false 
    end

    local id = MySQL.insert.await('INSERT INTO aura_phone_contacts (owner_number, contact_number, contact_name) VALUES (?, ?, ?)', {
        number, targetNumber, name
    })
    
    if id then
        return true
    else
        return false
    end
end)

-- ANTI-CRASH: Si un jugador crashea o se desconecta, cortar la llamada del otro
AddEventHandler('playerDropped', function(reason)
    local src = source
    local number = AuraPhone.GetPlayerPhoneNumber(src)
    
    if number then
        AuraPhone.ActivePhones[number] = nil
        AuraPhone.PhoneToSource[src] = nil
    end

    local call = AuraPhone.CallData[src]
    if call then
        local targetSrc = call.target
        if targetSrc and AuraPhone.CallData[targetSrc] then
            AuraPhone.CallData[targetSrc] = nil
            TriggerClientEvent('aura_phone:client:callEnded', targetSrc, "Se perdió la conexión")
        end
        AuraPhone.CallData[src] = nil
    end
end)
