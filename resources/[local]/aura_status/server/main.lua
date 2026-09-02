-- Recibir actualización de estado desde el cliente y guardarlo en la caché
RegisterNetEvent('aura_status:server:UpdateStatus')
AddEventHandler('aura_status:server:UpdateStatus', function(statusData)
    local src = source
    if not statusData then return end
    
    local cleanStatus = {
        hunger = tonumber(statusData.hunger) or 100.0,
        thirst = tonumber(statusData.thirst) or 100.0,
        health = tonumber(statusData.health) or 200,
        armor = tonumber(statusData.armor) or 0
    }
    
    -- Actualizar en memoria del personaje activo en aura_multichar
    if exports.aura_multichar and exports.aura_multichar.GetActiveCharacter then
        local char = exports.aura_multichar:GetActiveCharacter(src)
        if char then
            char.metadata = char.metadata or {}
            char.metadata.status = cleanStatus
        end
    end
    
    -- Actualizar en aura_core como persistencia general
    local player = exports.aura_core:GetPlayer(src)
    if player then
        exports.aura_core:UpdatePlayerMetadata(src, 'status', cleanStatus)
    end
end)

-- Cuando el jugador hace spawn y está listo para recibir sus datos
RegisterNetEvent('aura_status:server:PlayerReady')
AddEventHandler('aura_status:server:PlayerReady', function()
    local src = source
    local statusData = nil
    
    -- 1. Intentar obtener el estado del personaje en aura_multichar
    if exports.aura_multichar and exports.aura_multichar.GetActiveCharacter then
        local char = exports.aura_multichar:GetActiveCharacter(src)
        if char and char.metadata and char.metadata.status then
            statusData = char.metadata.status
        end
    end
    
    -- 2. Fallback: obtener desde aura_core
    if not statusData then
        local player = exports.aura_core:GetPlayer(src)
        if player and player.metadata and player.metadata.status then
            statusData = player.metadata.status
        end
    end
    
    -- 3. Enviar datos al cliente (o valores por defecto si es nuevo)
    if statusData then
        TriggerClientEvent('aura_status:client:LoadStatus', src, statusData)
    else
        TriggerClientEvent('aura_status:client:LoadStatus', src, {
            hunger = 100.0,
            thirst = 100.0,
            health = 200,
            armor = 0
        })
    end
end)
