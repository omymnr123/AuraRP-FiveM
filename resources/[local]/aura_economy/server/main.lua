local AuraEconomy = {
    ActiveAccounts = {},  -- [src] = { charId = 1, accounts = { cash = 0, bank = 5000, black_money = 0 }, dirty = false }
    CharIdToSrc = {},     -- [charId] = src
    Locks = {}            -- [charId] = boolean (Mutex lock por personaje)
}

-- ============================================================================
-- UTILIDADES INTERNAS Y CONTROL DE CONCURRENCIA (MUTEX)
-- ============================================================================

local function GenerateTxId(charId)
    local timestamp = os.time()
    local randomHex = string.format("%04x%04x", math.random(0, 0xFFFF), math.random(0, 0xFFFF))
    return string.format("TX-%d-%d-%s", timestamp, charId or 0, randomHex)
end

local function AcquireLock(charId)
    local timeout = 500 -- 500ms max timeout para evitar deadlocks
    local elapsed = 0
    while AuraEconomy.Locks[charId] do
        Wait(10)
        elapsed = elapsed + 10
        if elapsed >= timeout then
            print(string.format("[Aura Economy] ^3ADVERTENCIA: Lock timeout superado para charId %s. Forzando liberación.^0", tostring(charId)))
            break
        end
    end
    AuraEconomy.Locks[charId] = true
end

local function ReleaseLock(charId)
    AuraEconomy.Locks[charId] = nil
end

local function ValidateAmount(amount)
    if type(amount) ~= 'number' then return nil, "INVALID_AMOUNT_TYPE" end
    if amount ~= amount then return nil, "AMOUNT_IS_NAN" end -- NaN check
    if amount <= 0 then return nil, "AMOUNT_MUST_BE_POSITIVE" end
    if amount == math.huge or amount == -math.huge then return nil, "AMOUNT_IS_INFINITE" end
    if amount > 9007199254740991 then return nil, "AMOUNT_OVERFLOW" end
    return math.floor(amount)
end

local function ValidateAccount(account)
    if type(account) ~= 'string' then return false end
    return Config.ValidAccounts[account] == true
end

-- ============================================================================
-- RESOLUCIÓN DE IDENTIDADES Y SINCRONIZACIÓN DE ESTADO
-- ============================================================================

local function ResolveCharacter(srcOrCharId)
    local num = tonumber(srcOrCharId)
    if not num then return nil end

    -- Caso 1: Se pasó el source de un jugador activo en el servidor
    if GetPlayerName(tostring(num)) or AuraEconomy.ActiveAccounts[num] then
        local active = AuraEconomy.ActiveAccounts[num]
        if active then
            return active.charId, num, active.accounts
        end

        -- Si aún no está cacheado en aura_economy, consultar aura_multichar
        local multicharActive = exports.aura_multichar:GetActiveCharacter(num)
        if multicharActive and multicharActive.id then
            local charId = multicharActive.id
            -- Cargar cuentas desde DB o inicializar
            local row = MySQL.single.await('SELECT accounts, metadata FROM characters WHERE id = ?', { charId })
            local accounts = Config.StartingBalances
            if row and row.accounts then
                accounts = json.decode(row.accounts) or accounts
            elseif multicharActive.metadata and (multicharActive.metadata.bank or multicharActive.metadata.cash) then
                accounts = {
                    cash = multicharActive.metadata.cash or 0,
                    bank = multicharActive.metadata.bank or 5000,
                    black_money = multicharActive.metadata.black_money or 0
                }
            end

            AuraEconomy.ActiveAccounts[num] = {
                charId = charId,
                accounts = accounts,
                dirty = false
            }
            AuraEconomy.CharIdToSrc[charId] = num

            -- Publicar en StateBag (Read-only para cliente)
            Player(num).state:set('money', accounts, true)
            return charId, num, accounts
        end
    end

    -- Caso 2: Se pasó directamente un Character ID
    local charId = num
    local activeSrc = AuraEconomy.CharIdToSrc[charId]
    if activeSrc and AuraEconomy.ActiveAccounts[activeSrc] then
        return charId, activeSrc, AuraEconomy.ActiveAccounts[activeSrc].accounts
    end

    -- Personaje offline: consultar directamente a la base de datos
    local row = MySQL.single.await('SELECT accounts FROM characters WHERE id = ?', { charId })
    if row and row.accounts then
        local accounts = json.decode(row.accounts) or Config.StartingBalances
        return charId, nil, accounts
    end

    return nil
end

-- ============================================================================
-- MOTOR TRANSACCIONAL ATÓMICO (CORE TRANSACTION ENGINE)
-- ============================================================================

local function ExecuteBalanceUpdate(charId, src, account, delta, txType, reason, metadata, targetCharId, fee)
    if delta == 0 then
        local _, _, currentAccounts = ResolveCharacter(charId)
        local currentBalance = currentAccounts and currentAccounts[account] or 0
        return true, currentBalance, nil
    end

    AcquireLock(charId)

    local _, _, currentAccounts = ResolveCharacter(charId)
    if not currentAccounts then
        ReleaseLock(charId)
        return false, "CHARACTER_NOT_FOUND", 0
    end

    local currentBalance = currentAccounts[account] or 0
    local newBalance = currentBalance + delta

    -- Validación estricta anti-saldo negativo
    if newBalance < 0 then
        ReleaseLock(charId)
        return false, "INSUFFICIENT_FUNDS", currentBalance
    end

    -- Aplicar nuevo balance a la estructura en memoria
    currentAccounts[account] = newBalance

    local txId = GenerateTxId(charId)
    local feeAmount = fee or 0

    -- Si el jugador está online, actualizar StateBag y marcar sucio/sincronizar
    if src then
        if AuraEconomy.ActiveAccounts[src] then
            AuraEconomy.ActiveAccounts[src].accounts = currentAccounts
            AuraEconomy.ActiveAccounts[src].dirty = true
        end
        Player(src).state:set('money', currentAccounts, true)
        TriggerClientEvent('aura_economy:onBalanceUpdate', src, account, newBalance, delta, reason)
    end

    -- Persistencia asíncrona a MySQL para base de datos
    local accountsJson = json.encode(currentAccounts)
    MySQL.update('UPDATE characters SET accounts = ? WHERE id = ?', { accountsJson, charId })

    -- Inserción forense en aura_transactions
    local metaJson = metadata and json.encode(metadata) or nil
    MySQL.insert('INSERT INTO aura_transactions (transaction_id, character_id, target_character_id, account, type, amount, balance_before, balance_after, fee, reason, metadata) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        txId,
        charId,
        targetCharId,
        account,
        txType,
        math.abs(delta),
        currentBalance,
        newBalance,
        feeAmount,
        reason or "UNKNOWN",
        metaJson
    })

    ReleaseLock(charId)
    return true, newBalance, txId
end

-- ============================================================================
-- EXPORTS PÚBLICOS DEL SERVIDOR (SECURE SERVER API)
-- ============================================================================

--- Obtiene el saldo actual de una cuenta específica
--- @param srcOrCharId number Source del jugador o ID de personaje
--- @param account string 'cash' | 'bank' | 'black_money'
--- @return number Balance actual o 0
local function GetMoney(srcOrCharId, account)
    if not ValidateAccount(account) then return 0 end
    local _, _, accounts = ResolveCharacter(srcOrCharId)
    if not accounts then return 0 end
    return accounts[account] or 0
end
exports('GetMoney', GetMoney)

--- Obtiene la tabla completa de balances monetarios
--- @param srcOrCharId number Source del jugador o ID de personaje
--- @return table | nil { cash = x, bank = y, black_money = z }
local function GetAccounts(srcOrCharId)
    local _, _, accounts = ResolveCharacter(srcOrCharId)
    if not accounts then return nil end
    return {
        cash = accounts.cash or 0,
        bank = accounts.bank or 0,
        black_money = accounts.black_money or 0
    }
end
exports('GetAccounts', GetAccounts)

--- Añade dinero de forma segura a una cuenta específica
--- @param srcOrCharId number Source o ID del personaje
--- @param account string 'cash' | 'bank' | 'black_money'
--- @param amount number Cantidad a añadir (> 0)
--- @param reason string Motivo de la transacción
--- @param metadata table | nil Metadatos adicionales en formato tabla
--- @return boolean success, number newBalance, string txId
local function AddMoney(srcOrCharId, account, amount, reason, metadata)
    local validAmount, err = ValidateAmount(amount)
    if not validAmount then return false, err, 0 end
    if not ValidateAccount(account) then return false, "INVALID_ACCOUNT", 0 end

    local charId, src = ResolveCharacter(srcOrCharId)
    if not charId then return false, "CHARACTER_NOT_FOUND", 0 end

    return ExecuteBalanceUpdate(charId, src, account, validAmount, "DEPOSIT", reason or "ADD_MONEY", metadata, nil, 0)
end
exports('AddMoney', AddMoney)

--- Retira dinero de forma segura de una cuenta específica
--- @param srcOrCharId number Source o ID del personaje
--- @param account string 'cash' | 'bank' | 'black_money'
--- @param amount number Cantidad a retirar (> 0)
--- @param reason string Motivo de la transacción
--- @param metadata table | nil Metadatos adicionales
--- @return boolean success, number newBalance, string txId
local function RemoveMoney(srcOrCharId, account, amount, reason, metadata)
    local validAmount, err = ValidateAmount(amount)
    if not validAmount then return false, err, 0 end
    if not ValidateAccount(account) then return false, "INVALID_ACCOUNT", 0 end

    local charId, src = ResolveCharacter(srcOrCharId)
    if not charId then return false, "CHARACTER_NOT_FOUND", 0 end

    return ExecuteBalanceUpdate(charId, src, account, -validAmount, "WITHDRAW", reason or "REMOVE_MONEY", metadata, nil, 0)
end
exports('RemoveMoney', RemoveMoney)

--- Establece forzosamente el dinero de una cuenta (Solo Uso Administrativo / Sistema)
--- @param srcOrCharId number Source o ID de personaje
--- @param account string 'cash' | 'bank' | 'black_money'
--- @param amount number Nuevo balance (>= 0)
--- @param reason string Motivo
--- @param metadata table | nil Metadatos
local function SetMoney(srcOrCharId, account, amount, reason, metadata)
    if type(amount) ~= 'number' or amount < 0 or amount ~= amount then
        return false, "INVALID_AMOUNT"
    end
    if not ValidateAccount(account) then return false, "INVALID_ACCOUNT" end

    local charId, src, accounts = ResolveCharacter(srcOrCharId)
    if not charId or not accounts then return false, "CHARACTER_NOT_FOUND" end

    local current = accounts[account] or 0
    local delta = math.floor(amount) - current

    return ExecuteBalanceUpdate(charId, src, account, delta, "ADMIN", reason or "SET_MONEY", metadata, nil, 0)
end
exports('SetMoney', SetMoney)

--- Transfiere dinero entre dos cuentas bancarias de forma atómica con impuesto de transferencia
--- @param fromSrcOrId number Origen (Source o CharId)
--- @param toSrcOrId number Destino (Source o CharId)
--- @param amount number Cantidad bruta a transferir
--- @param reason string Motivo
--- @param customFeeRate number | nil Tasa de impuesto personalizada opcional
--- @return boolean success, string message, string txId
local function TransferMoney(fromSrcOrId, toSrcOrId, amount, reason, customFeeRate)
    local validAmount, err = ValidateAmount(amount)
    if not validAmount then return false, err end

    local senderCharId, senderSrc, senderAccounts = ResolveCharacter(fromSrcOrId)
    if not senderCharId or not senderAccounts then return false, "SENDER_NOT_FOUND" end

    local targetCharId, targetSrc, targetAccounts = ResolveCharacter(toSrcOrId)
    if not targetCharId or not targetAccounts then return false, "TARGET_NOT_FOUND" end

    if senderCharId == targetCharId then return false, "CANNOT_TRANSFER_TO_SELF" end

    -- Cálculo del impuesto / sumidero bancario
    local feeRate = customFeeRate or Config.Taxes.TransferFeeRate
    local rawFee = math.floor(validAmount * feeRate)
    local fee = math.max(Config.Taxes.MinTransferFee, math.min(Config.Taxes.MaxTransferFee, rawFee))
    local totalDeduction = validAmount + fee

    local senderBank = senderAccounts.bank or 0
    if senderBank < totalDeduction then
        return false, "INSUFFICIENT_FUNDS_FOR_TRANSFER_AND_FEE"
    end

    -- Paso 1: Débito atómico del emisor
    local debited, _, sendTxId = ExecuteBalanceUpdate(
        senderCharId,
        senderSrc,
        'bank',
        -totalDeduction,
        'TRANSFER_SEND',
        string.format("Transferencia enviada a CharID #%d: %s", targetCharId, reason or ""),
        { target = targetCharId, transferAmount = validAmount, taxFee = fee },
        targetCharId,
        fee
    )

    if not debited then
        return false, "TRANSFER_DEBIT_FAILED"
    end

    -- Paso 2: Crédito atómico al receptor
    local credited, _, recvTxId = ExecuteBalanceUpdate(
        targetCharId,
        targetSrc,
        'bank',
        validAmount,
        'TRANSFER_RECEIVE',
        string.format("Transferencia recibida de CharID #%d: %s", senderCharId, reason or ""),
        { sender = senderCharId, transferAmount = validAmount },
        senderCharId,
        0
    )

    if not credited then
        -- Rollback de emergencia en caso de fallo crítico en el receptor
        ExecuteBalanceUpdate(senderCharId, senderSrc, 'bank', totalDeduction, 'ADMIN', "ROLLBACK: Transferencia fallida", { originalTx = sendTxId }, nil, 0)
        return false, "TRANSFER_CREDIT_FAILED_ROLLED_BACK"
    end

    return true, "TRANSFER_SUCCESS", sendTxId
end
exports('TransferMoney', TransferMoney)

-- ============================================================================
-- REGISTRO DE TRANSACCIÓN INICIAL (FASE 4: $5,000 BANCO)
-- ============================================================================

local function RegisterInitialBalance(charId)
    local txId = GenerateTxId(charId)
    MySQL.insert('INSERT INTO aura_transactions (transaction_id, character_id, account, type, amount, balance_before, balance_after, fee, reason) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        txId,
        charId,
        'bank',
        'INITIAL',
        Config.StartingBalances.bank,
        0,
        Config.StartingBalances.bank,
        0,
        "INITIAL_CHARACTER_CREATION"
    })
end
exports('RegisterInitialBalance', RegisterInitialBalance)

-- ============================================================================
-- CICLO DE VIDA Y SINCRONIZACIÓN
-- ============================================================================

-- Inicializar personaje cuando es seleccionado en aura_multichar
AddEventHandler('aura_economy:server:characterLoaded', function(arg1, arg2, arg3)
    local src, charId, accounts
    if type(arg1) == 'number' and type(arg2) == 'number' then
        src = arg1
        charId = arg2
        accounts = arg3
    else
        src = source
        charId = arg1
        accounts = arg2
    end

    if not src or not charId then return end

    AuraEconomy.ActiveAccounts[src] = {
        charId = charId,
        accounts = accounts or Config.StartingBalances,
        dirty = false
    }
    AuraEconomy.CharIdToSrc[charId] = src
    Player(src).state:set('money', AuraEconomy.ActiveAccounts[src].accounts, true)
end)

-- Limpieza al desconectarse el jugador
AddEventHandler('playerDropped', function(reason)
    local src = source
    local active = AuraEconomy.ActiveAccounts[src]
    if active then
        if active.dirty then
            MySQL.update('UPDATE characters SET accounts = ? WHERE id = ?', {
                json.encode(active.accounts),
                active.charId
            })
        end
        AuraEconomy.CharIdToSrc[active.charId] = nil
        AuraEconomy.ActiveAccounts[src] = nil
    end
end)

-- Guardado periódico de seguridad en segundo plano
CreateThread(function()
    while true do
        Wait(Config.SyncInterval)
        for src, data in pairs(AuraEconomy.ActiveAccounts) do
            if data and data.dirty and data.charId then
                MySQL.update('UPDATE characters SET accounts = ? WHERE id = ?', {
                    json.encode(data.accounts),
                    data.charId
                })
                data.dirty = false
            end
        end
    end
end)

-- Callback para ox_lib en caso de peticiones síncronas de cliente
lib.callback.register('aura_economy:getAccounts', function(source)
    local src = source
    local _, _, accounts = ResolveCharacter(src)
    return accounts or Config.StartingBalances
end)
