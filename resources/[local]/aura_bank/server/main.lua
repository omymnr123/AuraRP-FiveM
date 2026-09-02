local ox_inventory = exports.ox_inventory

local function generateIBAN()
    local chars = "0123456789"
    local iban = "AURA"
    for i = 1, 8 do
        local r = math.random(1, #chars)
        iban = iban .. chars:sub(r, r)
    end
    return iban
end

local function generatePIN()
    return tostring(math.random(1000, 9999))
end

local function getActiveCharacter(src)
    local charId = Player(src).state.charId
    if not charId then
        local active = exports.aura_multichar:GetActiveCharacter(src)
        if active then charId = active.id end
    end
    return charId
end

lib.callback.register('aura_bank:requestCard', function(source)
    local src = source
    local charId = getActiveCharacter(src)
    if not charId then return false, "No hay personaje activo" end

    -- Check if character has IBAN and PIN
    local row = MySQL.single.await('SELECT iban, pin FROM characters WHERE id = ?', { charId })
    if not row then return false, "Personaje no encontrado en DB" end

    local iban = row.iban
    local pin = row.pin

    if not iban or not pin then
        iban = generateIBAN()
        pin = generatePIN()
        MySQL.update.await('UPDATE characters SET iban = ?, pin = ? WHERE id = ?', { iban, pin, charId })
    end

    -- Comprobar coste de tarjeta
    local money = exports.aura_economy:GetMoney(src, 'bank')
    if money < Config.CardCost then
        return false, "No tienes suficiente dinero en el banco para la tarjeta ($" .. Config.CardCost .. ")"
    end

    exports.aura_economy:RemoveMoney(src, 'bank', Config.CardCost, "Emisión de Tarjeta de Crédito")

    local metadata = {
        iban = iban,
        owner = charId,
        description = "IBAN: " .. iban .. "\nTitular ID: " .. charId
    }

    ox_inventory:AddItem(src, 'credit_card', 1, metadata)
    
    return true, "Tarjeta emitida. Tu PIN es: " .. pin
end)

lib.callback.register('aura_bank:verifyPin', function(source, inputPin, cardMetadata)
    local src = source
    local charId = getActiveCharacter(src)
    if not charId then return false, "Error de sesión" end
    
    if not cardMetadata or not cardMetadata.iban then
        return false, "Tarjeta inválida"
    end

    -- Comprobar si la tarjeta es del usuario que la usa (Seguridad Anti-Robo de tarjetas con PIN guardado en DB)
    -- Asumiremos que puedes usar tarjeta robada si sabes el PIN, pero debemos validar el IBAN de la tarjeta
    local row = MySQL.single.await('SELECT id, pin, firstname, lastname FROM characters WHERE iban = ?', { cardMetadata.iban })
    if not row then return false, "Esta tarjeta está bloqueada o es falsa." end
    
    if tostring(row.pin) ~= tostring(inputPin) then
        return false, "PIN Incorrecto."
    end
    
    local name = (row.firstname .. " " .. row.lastname) or "Desconocido"
    local accounts = exports.aura_economy:GetAccounts(row.id)
    
    local isBoss, jobName, jobLabel = exports.aura_jobs:IsBoss(src)
    local societyData = nil
    if isBoss and jobName then
        local socBalance = exports.aura_jobs:GetSocietyBalance(jobName)
        societyData = {
            name = jobName,
            label = jobLabel,
            balance = socBalance
        }
    end

    return true, {
        targetCharId = row.id,
        accounts = accounts,
        iban = cardMetadata.iban,
        name = name,
        isBoss = isBoss,
        society = societyData
    }
end)

-- Permite loguear directamente en el Teller (sin tarjeta ni PIN)
lib.callback.register('aura_bank:tellerLogin', function(source)
    local src = source
    local charId = getActiveCharacter(src)
    if not charId then return false, "Error de sesión" end
    
    local row = MySQL.single.await('SELECT iban, firstname, lastname FROM characters WHERE id = ?', { charId })
    local iban = row and row.iban or "SIN IBAN"
    local name = row and (row.firstname .. " " .. row.lastname) or "Desconocido"

    local accounts = exports.aura_economy:GetAccounts(charId)

    local isBoss, jobName, jobLabel = exports.aura_jobs:IsBoss(src)
    local societyData = nil
    if isBoss and jobName then
        local socBalance = exports.aura_jobs:GetSocietyBalance(jobName)
        societyData = {
            name = jobName,
            label = jobLabel,
            balance = socBalance
        }
    end

    return true, {
        targetCharId = charId,
        accounts = accounts,
        iban = iban,
        name = name,
        isBoss = isBoss,
        society = societyData
    }
end)

-- ============================================================================
-- BANCA CORPORATIVA: DEPÓSITO Y RETIRADA DE EFECTIVO FÍSICO (EXCLUSIVO BOSS)
-- ============================================================================

lib.callback.register('aura_bank:corporateDeposit', function(source, amount)
    local src = source
    local isBoss, jobName = exports.aura_jobs:IsBoss(src)
    if not isBoss or not jobName then
        return false, "Acceso denegado: No dispones de rango directivo en esta empresa."
    end

    local amountNum = tonumber(amount)
    if not amountNum or amountNum <= 0 then
        return false, "Importe inválido."
    end

    local charId = getActiveCharacter(src)
    local moneyCount = exports.ox_inventory:Search(src, 'count', 'money') or 0
    if moneyCount < amountNum then
        return false, "No dispones de suficiente dinero en efectivo físico encima."
    end

    local removed = exports.ox_inventory:RemoveItem(src, 'money', amountNum)
    if not removed then
        return false, "Error al retirar el efectivo de tu inventario."
    end

    local success, newBalance = exports.aura_jobs:AddSocietyMoney(
        jobName, 
        amountNum, 
        string.format("Depósito de Efectivo en Sucursal Bancaria (Boss ID #%s)", tostring(charId)),
        { bossCharId = charId }
    )

    if success then
        return true, string.format("Depósito corporativo de $%s completado con éxito.", lib.math.groupdigits(amountNum)), newBalance
    else
        exports.ox_inventory:AddItem(src, 'money', amountNum) -- Rollback
        return false, "Error al acreditar fondos en la cuenta de la sociedad."
    end
end)

lib.callback.register('aura_bank:corporateWithdraw', function(source, amount)
    local src = source
    local isBoss, jobName = exports.aura_jobs:IsBoss(src)
    if not isBoss or not jobName then
        return false, "Acceso denegado: No dispones de rango directivo en esta empresa."
    end

    local amountNum = tonumber(amount)
    if not amountNum or amountNum <= 0 then
        return false, "Importe inválido."
    end

    local charId = getActiveCharacter(src)
    local currentBalance = exports.aura_jobs:GetSocietyBalance(jobName)
    if currentBalance < amountNum then
        return false, "Fondos insuficientes en la cuenta corporativa de la empresa."
    end

    local success, newBalance = exports.aura_jobs:RemoveSocietyMoney(
        jobName,
        amountNum,
        string.format("Retirada de Efectivo en Sucursal Bancaria (Boss ID #%s)", tostring(charId)),
        { bossCharId = charId }
    )

    if success then
        exports.ox_inventory:AddItem(src, 'money', amountNum)
        return true, string.format("Retirada corporativa de $%s completada. Dinero físico en tus bolsillos.", lib.math.groupdigits(amountNum)), newBalance
    else
        return false, "Error al debitar fondos de la sociedad."
    end
end)

lib.callback.register('aura_bank:getCorporateData', function(source)
    local src = source
    local isBoss, jobName, jobLabel = exports.aura_jobs:IsBoss(src)
    if not isBoss or not jobName then
        return { isBoss = false, society = nil }
    end
    local balance = exports.aura_jobs:GetSocietyBalance(jobName)
    return {
        isBoss = true,
        society = {
            name = jobName,
            label = jobLabel,
            balance = balance
        }
    }
end)

lib.callback.register('aura_bank:doTransaction', function(source, targetCharId, type, amount, targetIban)
    local src = source
    local executorCharId = getActiveCharacter(src)
    if not executorCharId then return false, "Error de sesión" end
    
    local amountNum = tonumber(amount)
    if not amountNum or amountNum <= 0 then return false, "Cantidad inválida" end

    -- Para depositar (saca efectivo del inventario y lo mete al banco)
    if type == 'deposit' then
        local moneyCount = exports.ox_inventory:GetItem(src, 'money', nil, true) or 0
        if moneyCount < amountNum then return false, "No tienes suficiente dinero físico" end
        
        -- Quitamos efectivo físico
        local removedItem = exports.ox_inventory:RemoveItem(src, 'money', amountNum)
        if removedItem then
            -- Añadimos banco a la cuenta target (server.syncInventory sincroniza el cash en memoria y BD automáticamente)
            exports.aura_economy:AddMoney(targetCharId, 'bank', amountNum, "Depósito bancario ATM", { executor = executorCharId })
            return true, "Depósito completado"
        end
        return false, "Error en depósito"
    
    -- Para retirar (saca banco de la target, lo da en efectivo físico al executor)
    elseif type == 'withdraw' then
        local bank = exports.aura_economy:GetMoney(targetCharId, 'bank')
        if bank < amountNum then return false, "Fondos insuficientes en banco" end

        local removed = exports.aura_economy:RemoveMoney(targetCharId, 'bank', amountNum, "Retirada ATM", { executor = executorCharId })
        if removed then
            -- Entregar dinero físico (server.syncInventory sincroniza el cash en memoria y BD automáticamente)
            exports.ox_inventory:AddItem(src, 'money', amountNum)
            return true, "Retirada completada"
        end
        return false, "Error en retirada"

    elseif type == 'transfer' then
        if not targetIban then return false, "IBAN destino requerido" end
        
        -- Buscar CharId del IBAN destino
        local row = MySQL.single.await('SELECT id FROM characters WHERE iban = ?', { targetIban })
        if not row then return false, "IBAN destino no existe" end
        
        local recipientCharId = row.id
        
        -- Ejecutamos la transferencia del targetCharId (dueño cuenta abierta) al recipientCharId
        local success, msg = exports.aura_economy:TransferMoney(targetCharId, recipientCharId, amountNum, "Transferencia Bancaria", 0.0)
        if success then
            return true, "Transferencia enviada correctamente"
        else
            return false, msg or "Error en transferencia"
        end

    elseif type == 'transfer_to_savings' then
        local bank = exports.aura_economy:GetMoney(targetCharId, 'bank')
        if bank < amountNum then return false, "Fondos insuficientes en la cuenta corriente" end
        
        local removed = exports.aura_economy:RemoveMoney(targetCharId, 'bank', amountNum, "Transferencia a Ahorros", { executor = executorCharId })
        if removed then
            exports.aura_economy:AddMoney(targetCharId, 'savings', amountNum, "Transferencia desde Corriente")
            return true, "Dinero movido a ahorros"
        end
        return false, "Error moviendo fondos a ahorros"

    elseif type == 'transfer_from_savings' then
        local savings = exports.aura_economy:GetMoney(targetCharId, 'savings')
        if savings < amountNum then return false, "Fondos insuficientes en la cuenta de ahorros" end
        
        local removed = exports.aura_economy:RemoveMoney(targetCharId, 'savings', amountNum, "Transferencia a Corriente", { executor = executorCharId })
        if removed then
            exports.aura_economy:AddMoney(targetCharId, 'bank', amountNum, "Transferencia desde Ahorros")
            return true, "Dinero movido a cuenta corriente"
        end
        return false, "Error moviendo fondos a corriente"
    end

    return false, "Tipo de transacción desconocida"
end)

lib.callback.register('aura_bank:changePin', function(source, targetCharId, newPin)
    local src = source
    local executorCharId = getActiveCharacter(src)
    if not executorCharId or executorCharId ~= targetCharId then return false, "No tienes permiso para hacer esto" end
    
    if type(newPin) ~= 'string' or string.len(newPin) ~= 4 or not tonumber(newPin) then
        return false, "El PIN debe ser exactamente 4 números"
    end

    local rowsChanged = MySQL.update.await('UPDATE characters SET pin = ? WHERE id = ?', { newPin, targetCharId })
    if rowsChanged > 0 then
        return true, "PIN cambiado con éxito a " .. newPin
    end
    return false, "Error cambiando el PIN"
end)

lib.callback.register('aura_bank:getTransactions', function(source, targetCharId)
    local rows = MySQL.query.await('SELECT transaction_id, type, amount, balance_before, balance_after, fee, reason, UNIX_TIMESTAMP(created_at) * 1000 AS timestamp FROM aura_transactions WHERE character_id = ? AND account IN ("bank", "savings") ORDER BY created_at DESC LIMIT 20', { targetCharId })
    return rows or {}
end)

lib.callback.register('aura_bank:getChartData', function(source, targetCharId)
    -- Obtener transacciones de los últimos 7 días
    local rows = MySQL.query.await([[
        SELECT 
            DATE(created_at) as date, 
            SUM(CASE 
                WHEN type IN ('INITIAL', 'DEPOSIT', 'TRANSFER_RECEIVE', 'SALARY', 'SALE') THEN amount 
                WHEN type IN ('WITHDRAW', 'TRANSFER_SEND', 'PURCHASE', 'TAX', 'FINE', 'SINK') THEN -amount 
                ELSE 0 END) as daily_change
        FROM aura_transactions 
        WHERE character_id = ? AND account = 'bank' AND created_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
        GROUP BY DATE(created_at)
        ORDER BY date ASC
    ]], { targetCharId })

    local currentBank = exports.aura_economy:GetMoney(targetCharId, 'bank')
    
    -- Inicializar un mapa de los últimos 7 días con cambios = 0
    local daysMap = {}
    local labels = {}
    local dataPoints = {}
    
    for i = 6, 0, -1 do
        local d = os.date("%Y-%m-%d", os.time() - (i * 24 * 60 * 60))
        local label = os.date("%a", os.time() - (i * 24 * 60 * 60)) -- Mon, Tue, etc.
        -- Para español:
        local esDays = {Mon="Lun", Tue="Mar", Wed="Mié", Thu="Jue", Fri="Vie", Sat="Sáb", Sun="Dom"}
        label = esDays[label] or label

        daysMap[d] = 0
        table.insert(labels, label)
    end
    
    -- Rellenar los cambios diarios
    if rows then
        for _, row in ipairs(rows) do
            if daysMap[row.date] ~= nil then
                daysMap[row.date] = tonumber(row.daily_change) or 0
            end
        end
    end

    -- Reconstruir saldo hacia atrás (El saldo de HOY es currentBank, ayer = HOY - cambio_hoy, etc.)
    local balances = {}
    local runningBalance = currentBank
    
    -- Recorrer de hoy al pasado para saber el saldo al FINAL de cada día, o de pasado a futuro.
    -- La lógica más sencilla: si hoy tengo X, ayer terminaba con X - (lo ganado hoy).
    local backwardsBalances = {}
    
    for i = 7, 1, -1 do
        local dateStr = os.date("%Y-%m-%d", os.time() - ((7-i) * 24 * 60 * 60))
        backwardsBalances[i] = runningBalance
        local change = daysMap[dateStr] or 0
        runningBalance = runningBalance - change
    end

    for i = 1, 7 do
        table.insert(dataPoints, backwardsBalances[i])
    end

    return { labels = labels, data = dataPoints }
end)
