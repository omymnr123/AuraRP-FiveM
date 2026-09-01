local activeCallChannel = 0
local isIncomingCallPending = false

-- Thread para capturar teclado nativo en FiveM durante llamadas (entrantes o activas)
CreateThread(function()
    while true do
        if isIncomingCallPending or activeCallChannel ~= 0 or (AuraPhoneClient and AuraPhoneClient.isInCall) then
            Wait(0)
            -- Tecla ENTER (18 / 191 / 201) -> Aceptar llamada (si está sonando)
            if isIncomingCallPending and (IsControlJustPressed(0, 18) or IsControlJustPressed(0, 191) or IsControlJustPressed(0, 201)) then
                isIncomingCallPending = false
                AuraPhoneClient.StartCallAnimation()
                TriggerServerEvent('aura_phone:server:acceptCall')
                SendNUIMessage({
                    action = "acceptCallByKeyboard"
                })
            -- Tecla BORRAR / BACKSPACE (194 / 177 / 202) -> Declinar o Colgar llamada
            elseif IsControlJustPressed(0, 194) or IsControlJustPressed(0, 177) or IsControlJustPressed(0, 202) then
                isIncomingCallPending = false
                AuraPhoneClient.StopCallAnimation()
                TriggerServerEvent('aura_phone:server:endCall')
                SendNUIMessage({
                    action = "declineCallByKeyboard"
                })
                SendNUIMessage({
                    action = "callEnded",
                    reason = "Llamada finalizada"
                })
            end
        else
            Wait(300)
        end
    end
end)

RegisterNetEvent('aura_phone:client:incomingCall', function(callerNumber, callerName)
    isIncomingCallPending = true
    
    -- Notificar al NUI (Pantalla/Peek de llamada entrante)
    SendNUIMessage({
        action = "incomingCall",
        number = callerNumber,
        callerName = callerName
    })
end)

RegisterNetEvent('aura_phone:client:callAccepted', function(channelId)
    isIncomingCallPending = false
    activeCallChannel = channelId
    -- Enrutar audio a pma-voice
    exports["pma-voice"]:setCallChannel(channelId)
    
    -- Iniciar animación de llamada a la oreja con prop
    AuraPhoneClient.StartCallAnimation()

    -- Avisar al UI que inicie el cronómetro
    SendNUIMessage({
        action = "callConnected"
    })
end)

RegisterNetEvent('aura_phone:client:callEnded', function(reason)
    isIncomingCallPending = false
    -- Si estaba en llamada, salir del canal y resetear mute/altavoz
    if activeCallChannel ~= 0 then
        exports["pma-voice"]:setCallChannel(0)
        activeCallChannel = 0
    end
    
    pcall(function()
        exports["pma-voice"]:setCallMuted(false)
        exports["pma-voice"]:setCallSpeaker(false)
    end)
    
    -- Detener animación de llamada y guardar prop
    AuraPhoneClient.StopCallAnimation()

    -- Notificar al NUI para cerrar la pantalla de llamada
    SendNUIMessage({
        action = "callEnded",
        reason = reason or "Llamada finalizada"
    })
end)

-- NUI Callbacks desde el frontend
RegisterNUICallback('dialNumber', function(data, cb)
    lib.callback('aura_phone:server:dialNumber', false, function(success, msg, audioFile)
        if success then
            AuraPhoneClient.StartCallAnimation()
        end
        cb({ success = success, message = msg, audio = audioFile })
    end, data.number)
end)

RegisterNUICallback('acceptCall', function(data, cb)
    AuraPhoneClient.StartCallAnimation()
    TriggerServerEvent('aura_phone:server:acceptCall')
    cb('ok')
end)

RegisterNUICallback('endCall', function(data, cb)
    AuraPhoneClient.StopCallAnimation()
    TriggerServerEvent('aura_phone:server:endCall')
    cb('ok')
end)

RegisterNUICallback('toggleMute', function(data, cb)
    local muted = data.muted or false
    pcall(function()
        exports["pma-voice"]:setCallMuted(muted)
    end)
    cb('ok')
end)

RegisterNUICallback('toggleSpeaker', function(data, cb)
    local enabled = data.speaker or false
    pcall(function()
        exports["pma-voice"]:setCallSpeaker(enabled)
    end)
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
