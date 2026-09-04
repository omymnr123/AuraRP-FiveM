-- ============================================================================
-- AURA GANGS: SERVER THEFT & CHOP SHOP ENGINE
-- Item Integrity, Entity Deletion & Underground Economy Rewards
-- ============================================================================

-- Evento para retirar ítems que se rompen durante el forcejeo
RegisterNetEvent('aura_gangs:server:breakItem', function(itemName)
    local src = source
    if not src or not itemName then return end

    if itemName == Config.Theft.lockpickItem or itemName == Config.Theft.advLockpickItem then
        exports.ox_inventory:RemoveItem(src, itemName, 1)
    end
end)

-- ============================================================================
-- 2. HERRAMIENTAS DE TEST / ADMINISTRACIÓN (ENTREGA DE GANZÚAS)
-- ============================================================================

RegisterNetEvent('aura_gangs:server:giveTestLockpicks', function()
    local src = source
    if not src or src <= 0 then return end

    local currentLockpicks = exports.ox_inventory:GetItem(src, Config.Theft.lockpickItem, nil, true) or 0
    local currentAdvLockpicks = exports.ox_inventory:GetItem(src, Config.Theft.advLockpickItem, nil, true) or 0

    if currentLockpicks < 2 then
        exports.ox_inventory:AddItem(src, Config.Theft.lockpickItem, 2 - currentLockpicks)
    end

    if currentAdvLockpicks < 2 then
        exports.ox_inventory:AddItem(src, Config.Theft.advLockpickItem, 2 - currentAdvLockpicks)
    end
end)

