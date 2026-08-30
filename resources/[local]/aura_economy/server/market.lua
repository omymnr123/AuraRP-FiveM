local Market = {
    Items = {} -- [itemName] = { name, basePrice, minPrice, maxPrice, currentStock, targetStock, elasticity }
}

-- ============================================================================
-- ALGORITMO DE FIJACIÓN DE PRECIOS DINÁMICOS Y ELASTICIDAD
-- ============================================================================

--- Calcula el precio unitario marginal de un ítem para un nivel de stock determinado
--- @param item table Registro del ítem en memoria
--- @param stock number Nivel de stock actual
--- @return number Precio unitario acotado entre minPrice y maxPrice
local function CalculateMarginalPrice(item, stock)
    local target = item.targetStock
    local base = item.basePrice
    local elasticity = item.elasticity

    -- Ecuación de Oferta y Demanda: P(S) = P_base * (1 + elasticity * (Target - Stock) / Target)
    local supplyDeficitRatio = (target - stock) / target
    local calculatedPrice = base * (1.0 + (elasticity * supplyDeficitRatio))

    -- Acotamiento estricto entre precio mínimo y precio máximo
    local clampedPrice = math.max(item.minPrice, math.min(item.maxPrice, calculatedPrice))
    return math.floor(clampedPrice + 0.5) -- Redondeo al entero más cercano
end

--- Calcula la curva de rendimientos decrecientes para una venta o compra en lote (Batch Processing)
--- @param itemName string Identificador del ítem
--- @param quantity number Cantidad de unidades (> 0)
--- @return number unitSellPrice, number totalSellPayout, number unitBuyPrice, number totalBuyCost
local function CalculateBatchQuote(itemName, quantity)
    local item = Market.Items[itemName]
    if not item then return 0, 0, 0, 0 end

    local qty = math.max(1, math.floor(quantity))
    local currentStock = item.currentStock

    -- Cálculo de venta escalonada (Diminishing Marginal Returns)
    local totalSellPayout = 0
    for i = 0, qty - 1 do
        local stepStock = currentStock + i
        local stepPrice = CalculateMarginalPrice(item, stepStock)
        totalSellPayout = totalSellPayout + stepPrice
    end

    -- Cálculo de compra escalonada (Increasing Marginal Cost)
    local totalBuyCost = 0
    local markup = Config.Market.BuyMarkup or 1.15
    for i = 0, qty - 1 do
        local stepStock = math.max(0, currentStock - i)
        local stepPrice = CalculateMarginalPrice(item, stepStock)
        local stepBuyPrice = math.ceil(stepPrice * markup)
        totalBuyCost = totalBuyCost + stepBuyPrice
    end

    local avgUnitSell = math.floor((totalSellPayout / qty) + 0.5)
    local avgUnitBuy = math.floor((totalBuyCost / qty) + 0.5)

    return avgUnitSell, totalSellPayout, avgUnitBuy, totalBuyCost
end

-- ============================================================================
-- INICIALIZACIÓN Y PERSISTENCIA EN BASE DE DATOS
-- ============================================================================

local function InitializeMarket()
    MySQL.ready(function()
        -- 0. Auto-inicialización resiliente de tablas SQL en Base de Datos
        MySQL.query.await([[CREATE TABLE IF NOT EXISTS `aura_market_items` (
          `name` VARCHAR(50) NOT NULL PRIMARY KEY,
          `base_price` INT NOT NULL,
          `min_price` INT NOT NULL,
          `max_price` INT NOT NULL,
          `current_stock` INT NOT NULL DEFAULT 0,
          `target_stock` INT NOT NULL DEFAULT 1000,
          `elasticity` FLOAT NOT NULL DEFAULT 0.05,
          `last_updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;]])

        MySQL.query.await([[CREATE TABLE IF NOT EXISTS `aura_transactions` (
          `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
          `transaction_id` VARCHAR(64) NOT NULL UNIQUE,
          `character_id` INT(11) NOT NULL,
          `target_character_id` INT(11) NULL DEFAULT NULL,
          `account` ENUM('cash', 'bank', 'black_money') NOT NULL,
          `type` ENUM('INITIAL', 'DEPOSIT', 'WITHDRAW', 'TRANSFER_SEND', 'TRANSFER_RECEIVE', 'PURCHASE', 'SALE', 'TAX', 'FINE', 'SALARY', 'SINK', 'ADMIN') NOT NULL,
          `amount` BIGINT NOT NULL,
          `balance_before` BIGINT NOT NULL,
          `balance_after` BIGINT NOT NULL,
          `fee` BIGINT NOT NULL DEFAULT 0,
          `reason` VARCHAR(255) NOT NULL,
          `metadata` LONGTEXT NULL DEFAULT NULL,
          `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY (`id`),
          KEY `idx_char_date` (`character_id`, `created_at`),
          KEY `idx_target_char` (`target_character_id`),
          KEY `idx_type` (`type`),
          KEY `idx_tx_uuid` (`transaction_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;]])

        pcall(function()
            MySQL.query.await([[ALTER TABLE `characters` ADD COLUMN IF NOT EXISTS `accounts` LONGTEXT NOT NULL DEFAULT '{"cash":0,"bank":5000,"black_money":0}' COMMENT 'JSON: cash, bank, black_money' CHECK (JSON_VALID(`accounts`));]])
        end)

        -- 1. Cargar datos existentes de la base de datos
        local dbItems = MySQL.query.await('SELECT * FROM aura_market_items')
        local loadedMap = {}

        if dbItems then
            for _, row in ipairs(dbItems) do
                loadedMap[row.name] = true
                Market.Items[row.name] = {
                    name = row.name,
                    basePrice = row.base_price,
                    minPrice = row.min_price,
                    maxPrice = row.max_price,
                    currentStock = row.current_stock,
                    targetStock = row.target_stock,
                    elasticity = row.elasticity
                }
            end
        end

        -- 2. Insertar ítems configurados que falten en base de datos
        for name, cfg in pairs(Config.Market.Items) do
            if not loadedMap[name] then
                Market.Items[name] = {
                    name = name,
                    basePrice = cfg.basePrice,
                    minPrice = cfg.minPrice,
                    maxPrice = cfg.maxPrice,
                    currentStock = cfg.targetStock, -- Iniciar en equilibrio
                    targetStock = cfg.targetStock,
                    elasticity = cfg.elasticity
                }

                MySQL.insert.await('INSERT INTO aura_market_items (name, base_price, min_price, max_price, current_stock, target_stock, elasticity) VALUES (?, ?, ?, ?, ?, ?, ?)', {
                    name,
                    cfg.basePrice,
                    cfg.minPrice,
                    cfg.maxPrice,
                    cfg.targetStock,
                    cfg.targetStock,
                    cfg.elasticity
                })
            end
        end

        local count = (type(dbItems) == 'table' and #dbItems) or 0
        print(string.format("[Aura Economy] Mercado Dinámico Inicializado. %d recursos activos en catálogo.", count))
    end)
end

-- ============================================================================
-- HILO DE EQUILIBRIO DE MERCADO (MEAN REVERSION / MACROECONOMIC DECAY)
-- ============================================================================

CreateThread(function()
    while true do
        Wait(Config.Market.DecayInterval or 600000)
        local decayRate = Config.Market.DecayRate or 0.05

        for name, item in pairs(Market.Items) do
            if item.currentStock ~= item.targetStock then
                local delta = item.targetStock - item.currentStock
                local adjustment = math.floor(delta * decayRate)
                if adjustment == 0 then
                    adjustment = delta > 0 and 1 or -1
                end

                item.currentStock = item.currentStock + adjustment

                MySQL.update('UPDATE aura_market_items SET current_stock = ? WHERE name = ?', {
                    item.currentStock,
                    name
                })
            end
        end

        if Config.Debug then
            print("[Aura Economy] Mercado Dinámico: Ciclo de Mean Reversion aplicado.")
        end
    end
end)

-- ============================================================================
-- EXPORTS DEL MERCADO DINÁMICO
-- ============================================================================

--- Obtiene la cotización en tiempo real de un ítem
--- @param itemName string
--- @param quantity number | nil
--- @return number unitSellPrice, number totalSellPayout, number unitBuyPrice, number totalBuyCost
local function GetMarketPrice(itemName, quantity)
    local qty = quantity or 1
    return CalculateBatchQuote(itemName, qty)
end
exports('GetMarketPrice', GetMarketPrice)

--- Obtiene el catálogo completo con precios y existencias actuales
--- @return table
local function GetMarketCatalog()
    local catalog = {}
    for name, item in pairs(Market.Items) do
        local unitSell, _, unitBuy, _ = CalculateBatchQuote(name, 1)
        catalog[name] = {
            name = name,
            label = (Config.Market.Items[name] and Config.Market.Items[name].label) or name,
            currentStock = item.currentStock,
            targetStock = item.targetStock,
            sellPrice = unitSell,
            buyPrice = unitBuy,
            minPrice = item.minPrice,
            maxPrice = item.maxPrice
        }
    end
    return catalog
end
exports('GetMarketCatalog', GetMarketCatalog)

--- Vende un ítem al mercado dinámico aplicando rendimientos decrecientes y actualizando stock
--- @param src number Source del jugador
--- @param itemName string Identificador del ítem
--- @param quantity number Cantidad a vender
--- @param account string 'cash' | 'bank'
--- @return boolean success, string message, number totalPayout
local function SellMarketItem(src, itemName, quantity, account)
    local item = Market.Items[itemName]
    if not item then return false, "ITEM_NOT_IN_MARKET", 0 end

    local qty = math.floor(tonumber(quantity) or 0)
    if qty <= 0 then return false, "INVALID_QUANTITY", 0 end

    local targetAccount = account or 'cash'
    local _, totalPayout, _, _ = CalculateBatchQuote(itemName, qty)

    -- Aumentar stock del mercado (mayor oferta -> menor precio futuro)
    item.currentStock = item.currentStock + qty

    -- Persistir stock actualizado
    MySQL.update('UPDATE aura_market_items SET current_stock = ? WHERE name = ?', {
        item.currentStock,
        itemName
    })

    -- Acreditar balance al jugador
    local success, newBal, txId = exports.aura_economy:AddMoney(
        src,
        targetAccount,
        totalPayout,
        string.format("Venta de mercado dinámico: %dx %s", qty, itemName),
        { item = itemName, quantity = qty, payout = totalPayout, stockAfter = item.currentStock }
    )

    if not success then
        -- Rollback de stock en caso de fallo
        item.currentStock = item.currentStock - qty
        return false, "PAYOUT_FAILED", 0
    end

    return true, "SALE_COMPLETED", totalPayout
end
exports('SellMarketItem', SellMarketItem)

--- Compra un ítem del mercado dinámico debitando la cuenta del jugador
--- @param src number Source del jugador
--- @param itemName string Identificador del ítem
--- @param quantity number Cantidad a comprar
--- @param account string 'cash' | 'bank'
--- @return boolean success, string message, number totalCost
local function BuyMarketItem(src, itemName, quantity, account)
    local item = Market.Items[itemName]
    if not item then return false, "ITEM_NOT_IN_MARKET", 0 end

    local qty = math.floor(tonumber(quantity) or 0)
    if qty <= 0 then return false, "INVALID_QUANTITY", 0 end

    if item.currentStock < qty then
        return false, "INSUFFICIENT_MARKET_STOCK", 0
    end

    local targetAccount = account or 'cash'
    local _, _, _, totalCost = CalculateBatchQuote(itemName, qty)

    -- Retirar dinero de forma atómica
    local success, _, _ = exports.aura_economy:RemoveMoney(
        src,
        targetAccount,
        totalCost,
        string.format("Compra de mercado dinámico: %dx %s", qty, itemName),
        { item = itemName, quantity = qty, cost = totalCost }
    )

    if not success then
        return false, "INSUFFICIENT_FUNDS", 0
    end

    -- Reducir stock del mercado (menor oferta -> mayor precio futuro)
    item.currentStock = item.currentStock - qty
    MySQL.update('UPDATE aura_market_items SET current_stock = ? WHERE name = ?', {
        item.currentStock,
        itemName
    })

    return true, "PURCHASE_COMPLETED", totalCost
end
exports('BuyMarketItem', BuyMarketItem)

-- Iniciar carga del mercado
InitializeMarket()
