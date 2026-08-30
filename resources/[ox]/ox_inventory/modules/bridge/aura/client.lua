RegisterNetEvent('aura_multichar:client:characterUnloaded', client.onLogout)

RegisterNetEvent('aura_multichar:client:characterLoaded', function(charData)
    PlayerData.loaded = true
    client.setPlayerData('groups', {})
end)

RegisterNetEvent('aura_core:playerSpawnedAndReady', function()
    PlayerData.loaded = true
    client.setPlayerData('groups', {})
end)

-- Comandos directos para abrir el inventario
RegisterCommand('inventory', function()
    if not PlayerData.loaded then
        PlayerData.loaded = true
    end
    client.openInventory()
end, false)

RegisterCommand('inv', function()
    if not PlayerData.loaded then
        PlayerData.loaded = true
    end
    client.openInventory()
end, false)

-- Asignación de tecla por defecto (TAB y F2)
RegisterKeyMapping('inventory', 'Abrir Inventario (Aura)', 'keyboard', 'TAB')
