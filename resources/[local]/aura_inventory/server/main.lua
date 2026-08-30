-- ============================================================================
-- AURA INVENTORY: CURRENCY BRIDGE & DYNAMIC MARKET SHOPS (PHASE 5)
-- ============================================================================

local function GetAccountType(itemName)
    return Config.CurrencyMap[itemName]
end

-- ============================================================================
-- 1. PUENTE TRANSACCIONAL DE DIVISAS (SWAPITEMS HOOK)
-- ============================================================================

exports.ox_inventory:registerHook('swapItems', function(payload)
    local fromInv = payload.fromInventory
    local toInv = payload.toInventory
    local item = payload.fromSlot
    local itemName = item and item.name
    local count = payload.count or (item and item.count) or 0

    if not itemName or count <= 0 then return true end

    local accountType = GetAccountType(itemName)
    if not accountType then return true end

    -- Si se mueve dentro del mismo inventario (organización interna de slots)
    if fromInv == toInv then
        return true
    end

    local fromIsPlayer = type(fromInv) == 'number' or (type(fromInv) == 'string' and tonumber(fromInv) ~= nil)
    local toIsPlayer = type(toInv) == 'number' or (type(toInv) == 'string' and tonumber(toInv) ~= nil)
    local fromPlayerSrc = fromIsPlayer and tonumber(fromInv) or nil
    local toPlayerSrc = toIsPlayer and tonumber(toInv) or nil

    -- ------------------------------------------------------------------------
    -- CASO 1: Transferencia directa entre dos jugadores (Player A -> Player B)
    -- ------------------------------------------------------------------------
    if fromPlayerSrc and toPlayerSrc then
        -- 1. Débito atómico al emisor
        local debited, _, sendTxId = exports.aura_economy:RemoveMoney(
            fromPlayerSrc,
            accountType,
            count,
            string.format("Físico: Entrega mano a mano a Jugador #%d", toPlayerSrc),
            { action = "PLAYER_GIVE", to = toPlayerSrc, item = itemName, count = count }
        )

        if not debited then
            if Config.Debug then
                print(string.format("[Aura Inventory] Rechazado giveItem: Jugador %d no tiene saldo suficiente en BD.", fromPlayerSrc))
            end
            return false -- Cancela el traspaso físico de inmediato en ox_inventory
        end

        -- 2. Crédito atómico al receptor
        local credited, _, _ = exports.aura_economy:AddMoney(
            toPlayerSrc,
            accountType,
            count,
            string.format("Físico: Recepción mano a mano de Jugador #%d", fromPlayerSrc),
            { action = "PLAYER_RECEIVE", from = fromPlayerSrc, item = itemName, count = count }
        )

        if not credited then
            -- Rollback de seguridad si falla la acreditación
            exports.aura_economy:AddMoney(fromPlayerSrc, accountType, count, "ROLLBACK: Error en recepción física", { originalTx = sendTxId })
            return false
        end

        return true
    end

    -- ------------------------------------------------------------------------
    -- CASO 2: Jugador saca dinero de sus bolsillos (Player -> Drop, Stash, Maletero)
    -- ------------------------------------------------------------------------
    if fromPlayerSrc and not toPlayerSrc then
        local debited, _, _ = exports.aura_economy:RemoveMoney(
            fromPlayerSrc,
            accountType,
            count,
            string.format("Físico: Depósito/Drop hacia %s (%s)", payload.toType or "contenedor", tostring(toInv)),
            { action = "STORAGE_DEPOSIT_OR_DROP", to = toInv, toType = payload.toType, item = itemName, count = count }
        )

        if not debited then
            if Config.Debug then
                print(string.format("[Aura Inventory] Rechazado drop/stash: Jugador %d fondos insuficientes en BD.", fromPlayerSrc))
            end
            return false -- Previene clonación por drop
        end

        return true
    end

    -- ------------------------------------------------------------------------
    -- CASO 3: Jugador ingresa dinero a sus bolsillos (Drop, Stash, Maletero -> Player)
    -- ------------------------------------------------------------------------
    if not fromPlayerSrc and toPlayerSrc then
        local credited, _, _ = exports.aura_economy:AddMoney(
            toPlayerSrc,
            accountType,
            count,
            string.format("Físico: Retiro/Pickup desde %s (%s)", payload.fromType or "contenedor", tostring(fromInv)),
            { action = "STORAGE_WITHDRAW_OR_PICKUP", from = fromInv, fromType = payload.fromType, item = itemName, count = count }
        )

        if not credited then
            return false
        end

        return true
    end

    return true
end, {
    itemFilter = {
        cash = true,
        money = true,
        black_money = true
    }
})

-- ============================================================================
-- 2. CONTROL DE CREACIÓN DIRECTA DE DIVISAS (CREATEITEM HOOK)
-- ============================================================================

exports.ox_inventory:registerHook('createItem', function(payload)
    local inv = payload.inventoryId
    local item = payload.item
    local count = payload.count or 1
    local itemName = type(item) == 'table' and item.name or item

    local accountType = GetAccountType(itemName)
    if not accountType then return end

    local playerSrc = tonumber(inv)
    if playerSrc and GetPlayerName(tostring(playerSrc)) then
        exports.aura_economy:AddMoney(
            playerSrc,
            accountType,
            count,
            "Físico: Creación directa en inventario (createItem)",
            { action = "CREATE_ITEM", item = itemName, count = count }
        )
    end
end, {
    itemFilter = {
        cash = true,
        money = true,
        black_money = true
    }
})

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
