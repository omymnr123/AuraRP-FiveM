--[[
    ===================================================================
    AuraRP Chat - Server API & Exports
    Permite a scripts externos (como aura_police, aura_ems, scripts de entorno)
    enviar mensajes al chat o mostrar textos 3D desde el lado servidor.
    ===================================================================
]]

-- Envío de mensaje a un jugador específico o tabla de jugadores
local function SendMessageToPlayer(target, data)
    if type(target) == 'table' then
        for _, playerId in ipairs(target) do
            TriggerClientEvent('aura_chat:client:addMessage', playerId, data)
        end
    else
        TriggerClientEvent('aura_chat:client:addMessage', target, data)
    end
end

-- Envío global a todos los jugadores
local function BroadcastMessage(data)
    TriggerClientEvent('aura_chat:client:addMessage', -1, data)
end

-- ===================================================================
-- EXPORTS DEL SERVIDOR
-- ===================================================================

exports('addMessage', SendMessageToPlayer)
exports('addBroadcastMessage', BroadcastMessage)

exports('show3DText', function(targets, emitterServerId, text)
    if type(targets) == 'table' then
        for _, playerId in ipairs(targets) do
            TriggerClientEvent('aura_chat:client:show3DMe', playerId, emitterServerId, text)
        end
    else
        TriggerClientEvent('aura_chat:client:show3DMe', targets, emitterServerId, text)
    end
end)

-- ===================================================================
-- EVENTOS DEL SERVIDOR PARA INTEROPERABILIDAD
-- ===================================================================

RegisterNetEvent('aura_chat:server:addMessage', function(target, data)
    SendMessageToPlayer(target, data)
end)

RegisterNetEvent('chat:server:addMessage', function(target, data)
    SendMessageToPlayer(target, data)
end)
