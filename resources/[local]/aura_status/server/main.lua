-- Recibir actualización de estado desde el cliente y guardarlo en la caché de aura_core
RegisterNetEvent('aura_status:server:UpdateStatus')
AddEventHandler('aura_status:server:UpdateStatus', function(statusData)
    local src = source
    local player = exports.aura_core:GetPlayer(src)
    
    if player then
        -- statusData contendrá {hunger, thirst, health, armor}
        exports.aura_core:UpdatePlayerMetadata(src, 'status', {
            hunger = statusData.hunger,
            thirst = statusData.thirst,
            health = statusData.health,
            armor = statusData.armor
        })
    end
end)

-- Cuando el jugador hace spawn y está listo para recibir sus datos
RegisterNetEvent('aura_status:server:PlayerReady')
AddEventHandler('aura_status:server:PlayerReady', function()
    local src = source
    local player = exports.aura_core:GetPlayer(src)
    
    if player and player.metadata and player.metadata.status then
        -- Enviar los estados guardados al cliente
        TriggerClientEvent('aura_status:client:LoadStatus', src, player.metadata.status)
    else
        -- Si no hay estados previos (nuevo jugador), inicializar con 100
        TriggerClientEvent('aura_status:client:LoadStatus', src, {
            hunger = 100.0,
            thirst = 100.0,
            health = 200,
            armor = 0
        })
    end
end)
