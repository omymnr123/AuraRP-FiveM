-- ============================================================================
-- AURA JOBS: SERVER VENDORS CONTROLLER (24/7 STORE WITH PERSISTENT DB AUDIT)
-- Real-time stock from ox_inventory stashes & automatic revenue deposit in aura_societies
-- ============================================================================

local function InitVendorDatabase()
    -- Crear tabla de auditoría de transacciones 24/7 si no existe
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `aura_vendor_transactions` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `citizenid` VARCHAR(50) NOT NULL,
            `buyer_name` VARCHAR(100) NOT NULL DEFAULT 'Ciudadano',
            `business` VARCHAR(50) NOT NULL,
            `business_label` VARCHAR(100) NOT NULL,
            `items` LONGTEXT NOT NULL,
            `total_price` INT(11) NOT NULL,
            `payment_method` ENUM('cash', 'bank') NOT NULL DEFAULT 'cash',
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_vendor_business` (`business`),
            INDEX `idx_vendor_citizenid` (`citizenid`),
            INDEX `idx_vendor_created` (`created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
end

local function RegisterVendorStashes()
    if not Config.BusinessVendors then return end

    for vendorKey, vendorConfig in pairs(Config.BusinessVendors) do
        local stashId = 'vendor_stock_' .. vendorConfig.job
        local stashLabel = 'Stock 24/7 - ' .. vendorConfig.label

        -- Registrar Stash físico persistente en ox_inventory (300kg de capacidad por defecto)
        local maxWeight = vendorConfig.maxWeight or 300000 -- 300.0 kg (en gramos)
        local slots = vendorConfig.slots or 50

        exports.ox_inventory:RegisterStash(
            stashId,
            stashLabel,
            slots,
            maxWeight,
            nil,     -- compartido
            { [vendorConfig.job] = 0 } -- acceso restringido al trabajo
        )

        if Config.Debug then
            print(string.format("[Aura Jobs] Stash de stock registrado y persistido en DB: %s (%s)", stashId, stashLabel))
        end
    end
end

CreateThread(function()
    Wait(500)
    InitVendorDatabase()
    RegisterVendorStashes()
end)

--- Obtiene los datos del catálogo y stock en tiempo real desde el stash
lib.callback.register('aura_jobs:server:getVendorStoreData', function(source, vendorKey)
    if not vendorKey or not Config.BusinessVendors[vendorKey] then
        return false, "Establecimiento no configurado."
    end

    local vendorConfig = Config.BusinessVendors[vendorKey]
    local isBusinessOpen = GlobalState['business_' .. vendorConfig.job .. '_open'] == true

    if isBusinessOpen then
        return false, "El establecimiento está actualmente ABIERTO al público. Por favor, solicita tu pedido a los empleados en servicio."
    end

    local stashId = 'vendor_stock_' .. vendorConfig.job
    local itemsWithStock = {}

    for _, item in ipairs(vendorConfig.items) do
        local currentStock = exports.ox_inventory:GetItemCount(stashId, item.name) or 0
        table.insert(itemsWithStock, {
            name = item.name,
            label = item.label,
            price = item.price,
            category = item.category or 'other',
            icon = item.icon or 'utensils',
            stock = currentStock
        })
    end

    return true, {
        vendorKey = vendorKey,
        job = vendorConfig.job,
        label = vendorConfig.label,
        items = itemsWithStock
    }
end)

--- Procesa la compra del carrito completo desde la tienda 24/7 con persistencia total
lib.callback.register('aura_jobs:server:buyVendorCart', function(source, data)
    local src = source
    if not data or not data.vendorKey or not data.cart or #data.cart == 0 then
        return false, "El carrito de compras está vacío o es inválido."
    end

    local vendorConfig = Config.BusinessVendors[data.vendorKey]
    if not vendorConfig then
        return false, "Establecimiento no encontrado."
    end

    -- Validar que el negocio siga cerrado
    local isBusinessOpen = GlobalState['business_' .. vendorConfig.job .. '_open'] == true
    if isBusinessOpen then
        return false, "El local ha abierto sus puertas. Realiza tu compra directamente con el personal."
    end

    local stashId = 'vendor_stock_' .. vendorConfig.job
    local totalPrice = 0
    local itemsToProcess = {}

    -- Validar disponibilidad de stock de cada producto en el stash físico
    for _, cartItem in ipairs(data.cart) do
        local count = math.floor(tonumber(cartItem.count) or 0)
        if count <= 0 then
            return false, "Cantidad de producto no válida."
        end

        -- Buscar precio en config
        local cfgItem = nil
        for _, it in ipairs(vendorConfig.items) do
            if it.name == cartItem.name then
                cfgItem = it
                break
            end
        end

        if not cfgItem then
            return false, "Producto desconocido en el carrito."
        end

        local availableStock = exports.ox_inventory:GetItemCount(stashId, cartItem.name) or 0
        if availableStock < count then
            return false, string.format("Stock insuficiente de '%s'. Disponible en tienda: %d.", cfgItem.label, availableStock)
        end

        local subtotal = cfgItem.price * count
        totalPrice = totalPrice + subtotal

        table.insert(itemsToProcess, {
            name = cfgItem.name,
            label = cfgItem.label,
            count = count,
            price = cfgItem.price
        })
    end

    local paymentMethod = data.paymentMethod == 'bank' and 'bank' or 'cash'

    -- Comprobar si el jugador puede cargar todos los productos
    for _, it in ipairs(itemsToProcess) do
        local canCarry = exports.ox_inventory:CanCarryItem(src, it.name, it.count)
        if not canCarry then
            return false, "No tienes suficiente espacio o capacidad de carga en tus bolsillos para todos los productos."
        end
    end

    -- Cobrar al comprador
    local paid = exports.aura_economy:RemoveAccountMoney(
        src,
        paymentMethod,
        totalPrice,
        string.format("Compra 24/7 en %s (%d artículos)", vendorConfig.label, #itemsToProcess)
    )

    if not paid then
        return false, string.format("Fondos insuficientes en tu %s para pagar $%d.", paymentMethod == 'bank' and "cuenta bancaria" or "cartera en efectivo", totalPrice)
    end

    -- Retirar del stash de stock físico (Actualiza ox_inventory en BD inmediatamente)
    for _, it in ipairs(itemsToProcess) do
        exports.ox_inventory:RemoveItem(stashId, it.name, it.count)
        exports.ox_inventory:AddItem(src, it.name, it.count)
    end

    -- Depositar el 100% del pago en la cuenta societaria del negocio en aura_societies
    local societyName = vendorConfig.society or vendorConfig.job
    exports.aura_jobs:AddSocietyMoney(
        societyName,
        totalPrice,
        string.format("Ingresos Tienda 24/7 (%d artículos)", #itemsToProcess)
    )

    -- Registrar la transacción completa en la Base de Datos para auditoría fiscal
    local charData = exports.aura_multichar and exports.aura_multichar:GetActiveCharacter(src)
    local citizenid = (charData and charData.citizenid) or Player(src).state.citizenid or tostring(src)
    local buyerName = (charData and (charData.firstname .. " " .. charData.lastname)) or GetPlayerName(src)

    MySQL.insert([[
        INSERT INTO aura_vendor_transactions 
        (citizenid, buyer_name, business, business_label, items, total_price, payment_method)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        citizenid,
        buyerName,
        vendorConfig.job,
        vendorConfig.label,
        json.encode(itemsToProcess),
        totalPrice,
        paymentMethod
    })

    -- Obtener stock actualizado para la UI
    local updatedItemsWithStock = {}
    for _, item in ipairs(vendorConfig.items) do
        local currentStock = exports.ox_inventory:GetItemCount(stashId, item.name) or 0
        table.insert(updatedItemsWithStock, {
            name = item.name,
            label = item.label,
            price = item.price,
            category = item.category or 'other',
            icon = item.icon or 'utensils',
            stock = currentStock
        })
    end

    if Config.Debug then
        print(string.format("[Aura Jobs 24/7] Compra de $%d completada en %s por %s (%s). Guardado en BD.", totalPrice, vendorConfig.label, buyerName, citizenid))
    end

    return true, {
        message = string.format("Compra completada por $%d con %s.", totalPrice, paymentMethod == 'bank' and "Tarjeta" or "Efectivo"),
        items = updatedItemsWithStock,
        totalPrice = totalPrice
    }
end)
