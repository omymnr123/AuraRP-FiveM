local consumeCooldowns = {}

exports('consumeItem', function(event, item, inventory, slot, data)
    -- ox_inventory envía evento 'usingItem' y 'usedItem'
    if event == 'usingItem' then
        local src = inventory.id
        
        -- Verificar spam-use
        if consumeCooldowns[src] and consumeCooldowns[src] > os.time() then
            -- Spam detectado
            return false
        end
        
        local consumeData = Config.Consumables[item.name]
        if not consumeData then
            return false
        end
        
        -- Iniciar cooldown
        consumeCooldowns[src] = os.time() + 2 -- 2 segundos de cooldown
        
        -- Reproducir animación y dar estado. Para animaciones, usaremos un TriggerClientEvent si queremos algo más personalizado
        -- Pero ox_inventory maneja 'anim' y 'prop' desde client en items.lua
        -- Así que aquí solo damos el estado después de que el item se usa exitosamente.
        return true -- Permite usar el item
    elseif event == 'usedItem' then
        local src = inventory.id
        local consumeData = Config.Consumables[item.name]
        
        if consumeData then
            -- Añadir estado seguro
            TriggerClientEvent('aura_status:client:AddStatus', src, consumeData.type, consumeData.amount)
        end
        return true
    end
end)
