local activeCallChannel = 0

RegisterNetEvent('aura_phone:client:incomingCall', function(callerNumber)
    -- Activar vibración / sonido de llamada (A futuro: interactSound)
    
    -- Notificar al NUI (Pantalla de llamada entrante)
    SendNUIMessage({
        action = "incomingCall",
        number = callerNumber
    })
end)

RegisterNetEvent('aura_phone:client:callAccepted', function(channelId)
    activeCallChannel = channelId
    -- Enrutar audio a pma-voice
    exports["pma-voice"]:setCallChannel(channelId)
    
    -- Avisar al UI que inicie el cronómetro
    SendNUIMessage({
        action = "callConnected"
    })
end)

RegisterNetEvent('aura_phone:client:callEnded', function(reason)
    -- Si estaba en llamada, salir del canal
    if activeCallChannel ~= 0 then
        exports["pma-voice"]:setCallChannel(0)
        activeCallChannel = 0
    end
    
    -- Notificar al NUI para cerrar la pantalla de llamada
    SendNUIMessage({
        action = "callEnded",
        reason = reason or "Llamada finalizada"
    })
end)

-- NUI Callbacks desde el frontend
RegisterNUICallback('dialNumber', function(data, cb)
    lib.callback('aura_phone:server:dialNumber', false, function(success, msg, audioFile)
        cb({ success = success, message = msg, audio = audioFile })
    end, data.number)
end)

RegisterNUICallback('acceptCall', function(data, cb)
    TriggerServerEvent('aura_phone:server:acceptCall')
    cb('ok')
end)

RegisterNUICallback('endCall', function(data, cb)
    TriggerServerEvent('aura_phone:server:endCall')
    cb('ok')
end)

RegisterNUICallback('getRecents', function(data, cb)
    lib.callback('aura_phone:server:getRecents', false, function(results)
        cb(results)
    end)
end)

RegisterNUICallback('getFavorites', function(data, cb)
    lib.callback('aura_phone:server:getFavorites', false, function(results)
        cb(results)
    end)
end)

RegisterNUICallback('getContacts', function(data, cb)
    lib.callback('aura_phone:server:getContacts', false, function(results)
        cb(results)
    end)
end)

RegisterNUICallback('addContact', function(data, cb)
    lib.callback('aura_phone:server:addContact', false, function(success)
        cb({ success = success })
    end, data.name, data.number)
end)
