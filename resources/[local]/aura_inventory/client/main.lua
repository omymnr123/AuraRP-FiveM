-- ============================================================================
-- AURA INVENTORY: CLIENT SUBSYSTEM
-- ============================================================================

RegisterNetEvent('aura_inventory:client:notifyTransaction', function(title, description, type)
    if lib and lib.notify then
        lib.notify({
            title = title or 'Inventario',
            description = description,
            type = type or 'info',
            position = 'top-right'
        })
    end
end)

--- Comprueba si el jugador local dispone de una tablet en su inventario
--- @return boolean
exports('HasTablet', function()
    if not exports.ox_inventory then return false end
    return (exports.ox_inventory:Search('count', 'tablet') or 0) > 0
end)

--- Comprueba si el jugador local dispone de un ítem y cantidad específica
--- @param itemName string
--- @param count? number
--- @return boolean
exports('HasItem', function(itemName, count)
    if not exports.ox_inventory then return false end
    local required = count or 1
    return (exports.ox_inventory:Search('count', itemName) or 0) >= required
end)

