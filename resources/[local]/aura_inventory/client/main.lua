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
