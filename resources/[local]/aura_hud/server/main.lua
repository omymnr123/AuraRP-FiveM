-- Guardar posición
RegisterNetEvent('aura_hud:server:SavePosition')
AddEventHandler('aura_hud:server:SavePosition', function(data, legacyY)
    local src = source
    local player = exports.aura_core and exports.aura_core:GetPlayer(src)
    local char = exports.aura_multichar and exports.aura_multichar:GetActiveCharacter(src)
    
    local hudPos = { x = 17.5, y = 3.5 }
    local hotbarPos = { x = 50.0, y = 3.5 }

    if type(data) == 'table' and (data.hud or data.hotbar) then
        hudPos = data.hud or hudPos
        hotbarPos = data.hotbar or hotbarPos
    elseif type(data) == 'number' then
        hudPos = { x = data, y = legacyY or 3.5 }
    end

    local posPayload = {
        hud = hudPos,
        hotbar = hotbarPos
    }

    -- Guardar en aura_core (metadata de cuenta/jugador)
    if player then
        exports.aura_core:UpdatePlayerMetadata(src, 'hud_positions', posPayload)
        exports.aura_core:UpdatePlayerMetadata(src, 'hud_position', hudPos)
    end

    -- Guardar en aura_multichar / DB characters (metadata de personaje)
    if char and char.id then
        char.metadata = char.metadata or {}
        char.metadata.hud_positions = posPayload
        char.metadata.hud_position = hudPos
        
        -- Guardado directo en la base de datos para persistencia inmediata
        MySQL.update('UPDATE characters SET metadata = ? WHERE id = ?', {
            json.encode(char.metadata),
            char.id
        })
    end
end)

-- Cuando el jugador entra y solicita el HUD, enviamos las posiciones guardadas
RegisterNetEvent('aura_hud:server:RequestPosition')
AddEventHandler('aura_hud:server:RequestPosition', function()
    local src = source
    local player = exports.aura_core and exports.aura_core:GetPlayer(src)
    local char = exports.aura_multichar and exports.aura_multichar:GetActiveCharacter(src)
    
    local hudPos = nil
    local hotbarPos = { x = 50.0, y = 3.5 }

    if char and char.metadata then
        if char.metadata.hud_positions then
            hudPos = char.metadata.hud_positions.hud
            hotbarPos = char.metadata.hud_positions.hotbar or hotbarPos
        elseif char.metadata.hud_position then
            hudPos = char.metadata.hud_position
        end
    end

    if not hudPos and player and player.metadata then
        if player.metadata.hud_positions then
            hudPos = player.metadata.hud_positions.hud
            hotbarPos = player.metadata.hud_positions.hotbar or hotbarPos
        elseif player.metadata.hud_position then
            hudPos = player.metadata.hud_position
        end
    end

    if hudPos then
        TriggerClientEvent('aura_hud:client:SetPosition', src, hudPos, hotbarPos)
    end
end)
