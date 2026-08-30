-- Guardar posición
RegisterNetEvent('aura_hud:server:SavePosition')
AddEventHandler('aura_hud:server:SavePosition', function(x, y)
    local src = source
    local player = exports.aura_core:GetPlayer(src)
    
    if player then
        exports.aura_core:UpdatePlayerMetadata(src, 'hud_position', {
            x = x,
            y = y
        })
    end
end)

-- Cuando el jugador entra y solicita el HUD, enviamos la posición guardada
RegisterNetEvent('aura_hud:server:RequestPosition')
AddEventHandler('aura_hud:server:RequestPosition', function()
    local src = source
    local player = exports.aura_core:GetPlayer(src)
    
    if player and player.metadata and player.metadata.hud_position then
        TriggerClientEvent('aura_hud:client:SetPosition', src, player.metadata.hud_position.x, player.metadata.hud_position.y)
    end
end)
