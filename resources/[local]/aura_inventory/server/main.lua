-- ============================================================================
-- AURA INVENTORY: CURRENCY BRIDGE & DYNAMIC MARKET SHOPS (PHASE 5)
-- ============================================================================

local function GetAccountType(itemName)
    return Config.CurrencyMap[itemName]
end

-- ============================================================================
-- 1. CONTROL DE DIVISAS
-- ============================================================================
-- NOTA: La paridad y sincronización entre el efectivo físico (ítem 'money' y 'black_money')
-- y el motor financiero de aura_economy es gestionada de forma nativa y atómica por 
-- server.syncInventory en el bridge de ox_inventory (ox_inventory/modules/bridge/aura/server.lua).
-- Esto previene desincronizaciones, bucles de clonación y colisiones de estado.


-- ============================================================================
-- 3. INTEGRACIÓN DEL MERCADO DINÁMICO CON TIENDAS DE OX_INVENTORY
-- ============================================================================

--- Intercepta la apertura de tiendas para inyectar precios dinámicos de oferta/demanda
exports.ox_inventory:registerHook('openShop', function(payload)
    if not payload.items then return true end

    for i = 1, #payload.items do
        local shopItem = payload.items[i]
        if shopItem and shopItem.name then
            -- Consultar el motor de mercado dinámico de aura_economy
            local _, _, unitBuyPrice, _ = exports.aura_economy:GetMarketPrice(shopItem.name, 1)
            if unitBuyPrice and unitBuyPrice > 0 then
                shopItem.price = unitBuyPrice
            end
        end
    end

    return true
end)

--- Intercepta compras en tiendas para retroalimentar la demanda y el stock del mercado
exports.ox_inventory:registerHook('buyItem', function(payload)
    local src = payload.source
    local item = payload.item
    local count = payload.count or 1
    local itemName = type(item) == 'table' and item.name or item

    if itemName and exports.aura_economy and exports.aura_economy.BuyMarketItem then
        -- Si el ítem está registrado en el catálogo del mercado dinámico
        pcall(function()
            local catalog = exports.aura_economy:GetMarketCatalog()
            if catalog and catalog[itemName] then
                -- Actualizar el inventario macroeconómico
                -- Reducir stock del mercado dinámico ante la demanda del jugador
                local marketItem = catalog[itemName]
                if marketItem then
                    MySQL.update('UPDATE aura_market_items SET current_stock = GREATEST(0, current_stock - ?) WHERE name = ?', {
                        count,
                        itemName
                    })
                end
            end
        end)
    end

    return true
end)

-- ============================================================================
-- 4. HELPERS Y EXPORTS DE VALIDACIÓN DE INVENTARIO
-- ============================================================================

--- Comprueba si un jugador en el servidor dispone de al menos una tablet
--- @param src number
--- @return boolean
exports('HasTablet', function(src)
    if not src or src <= 0 then return false end
    if not exports.ox_inventory then return false end
    return (exports.ox_inventory:GetItemCount(src, 'tablet') or 0) > 0
end)

--- Comprueba si un jugador en el servidor dispone de un ítem y cantidad específica
--- @param src number
--- @param itemName string
--- @param count? number
--- @return boolean
exports('HasItem', function(src, itemName, count)
    if not src or src <= 0 or not itemName then return false end
    if not exports.ox_inventory then return false end
    local required = count or 1
    return (exports.ox_inventory:GetItemCount(src, itemName) or 0) >= required
end)

