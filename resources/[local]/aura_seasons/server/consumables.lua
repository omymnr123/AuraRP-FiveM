-- ============================================================================
-- AURARP SEASONS CONSUMABLES & THERMAL RESISTANCE BRIDGE
-- ============================================================================

local function HandleThermalConsumable(src, itemName)
    if not src or src <= 0 then return false end
    local itemCfg = Config.Consumables[itemName]
    if not itemCfg then return false end

    TriggerClientEvent('aura_seasons:client:applyBuff', src, {
        type = itemCfg.type,
        coreTempBoost = itemCfg.coreTempBoost or 0.0,
        buffDuration = itemCfg.buffDuration or 600,
        resistance = (itemCfg.type == 'warmth') and itemCfg.coldResistance or itemCfg.heatResistance,
        label = itemCfg.label
    })

    return true
end

-- Export para ser consumido desde ox_inventory directamente
exports('useThermalItem', function(event, item, inventory, slot, data)
    if event == 'usedItem' then
        local src = inventory.id
        HandleThermalConsumable(src, item.name)
        return true
    end
    return true
end)

-- Evento puente recibido desde cliente
RegisterNetEvent('aura_seasons:server:clientConsumedItem', function(itemName)
    local src = source
    HandleThermalConsumable(src, itemName)
end)

-- Evento puente recibido desde aura_status / otros scripts servidor
AddEventHandler('aura_seasons:server:itemConsumed', function(src, itemName)
    HandleThermalConsumable(src, itemName)
end)

-- Export para aplicar resistencia térmica directamente a un jugador
exports('ApplyThermalBuff', function(targetSrc, buffType, duration, resistance, coreBoost)
    if not targetSrc or targetSrc <= 0 then return end
    TriggerClientEvent('aura_seasons:client:applyBuff', targetSrc, {
        type = buffType, -- 'warmth' o 'cooling'
        coreTempBoost = coreBoost or 0.0,
        buffDuration = duration or 600,
        resistance = resistance or 0.50,
        label = (buffType == 'warmth') and 'Protección Térmica (Calor)' or 'Hidratación Refrescante'
    })
end)
