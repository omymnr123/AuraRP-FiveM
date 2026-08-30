-- ============================================================================
-- AURA ECONOMY: MONEY SINK ENGINE & MACROECONOMIC ANTI-INFLATION
-- ============================================================================

--- Procesa el lavado de dinero negro aplicando una tasa de retención sistémica (Money Sink)
--- @param src number Source del jugador
--- @param amount number Cantidad bruta de dinero negro a lavar
--- @param destinationAccount string 'cash' | 'bank' (por defecto 'cash')
--- @param customFeeRate number | nil Tasa de comisión personalizada opcional
--- @return boolean success, number cleanAmountReceived, number feeSunk
local function LaunderBlackMoney(src, amount, destinationAccount, customFeeRate)
    local targetAccount = (destinationAccount == 'bank') and 'bank' or 'cash'
    local validAmount, err = exports.aura_economy:GetMoney(src, 'black_money')
    
    local parsedAmount = math.floor(tonumber(amount) or 0)
    if parsedAmount <= 0 then return false, 0, 0 end

    if validAmount < parsedAmount then
        return false, 0, 0
    end

    local feeRate = customFeeRate or Config.Taxes.LaunderingFeeRate or 0.20
    local feeSunk = math.floor(parsedAmount * feeRate)
    local cleanAmount = parsedAmount - feeSunk

    -- 1. Retirar la cantidad total de dinero negro
    local removed, _, _ = exports.aura_economy:RemoveMoney(
        src,
        'black_money',
        parsedAmount,
        string.format("Lavado de dinero negro (Bruto: $%d, Tarifa destruida: $%d)", parsedAmount, feeSunk),
        { gross = parsedAmount, fee = feeSunk, clean = cleanAmount }
    )

    if not removed then return false, 0, 0 end

    -- 2. Acreditar el dinero limpio resultante a la cuenta destino
    local credited, _, _ = exports.aura_economy:AddMoney(
        src,
        targetAccount,
        cleanAmount,
        "Recepción de fondos lavados",
        { feeRetained = feeSunk }
    )

    return true, cleanAmount, feeSunk
end
exports('LaunderBlackMoney', LaunderBlackMoney)

--- Ejecuta un cobro de sumidero periódico (Impuesto predial, seguro de vehículos, tarifas de mantenimiento)
--- @param charIdOrSrc number Source o CharID del propietario
--- @param feeAmount number Monto a cobrar
--- @param reason string Descripción del impuesto/tarifa
--- @param metadata table | nil Metadatos de la propiedad o vehículo
--- @return boolean success, string status
local function ProcessMaintenanceSink(charIdOrSrc, feeAmount, reason, metadata)
    local parsedFee = math.floor(tonumber(feeAmount) or 0)
    if parsedFee <= 0 then return false, "INVALID_FEE" end

    -- Se intenta cobrar prioritariamente del banco
    local bankBalance = exports.aura_economy:GetMoney(charIdOrSrc, 'bank')
    if bankBalance >= parsedFee then
        local success = exports.aura_economy:RemoveMoney(
            charIdOrSrc,
            'bank',
            parsedFee,
            string.format("SUMIDERO/TASA: %s", reason or "Mantenimiento"),
            metadata
        )
        return success, success and "PAID_FROM_BANK" or "PAYMENT_FAILED"
    end

    -- Si no hay suficiente en banco, intentar de efectivo
    local cashBalance = exports.aura_economy:GetMoney(charIdOrSrc, 'cash')
    if cashBalance >= parsedFee then
        local success = exports.aura_economy:RemoveMoney(
            charIdOrSrc,
            'cash',
            parsedFee,
            string.format("SUMIDERO/TASA: %s", reason or "Mantenimiento"),
            metadata
        )
        return success, success and "PAID_FROM_CASH" or "PAYMENT_FAILED"
    end

    return false, "INSUFFICIENT_FUNDS_DEFAULTED"
end
exports('ProcessMaintenanceSink', ProcessMaintenanceSink)

--- Genera métricas macroeconómicas de la masa monetaria en circulación (M0, M1, M2 y Sumideros)
--- @return table { totalCash = number, totalBank = number, totalBlack = number, totalMoneySupply = number, totalSinksCollected = number }
local function GetGlobalEconomicStats()
    -- Agregación sobre la base de datos completa de personajes
    local characters = MySQL.query.await('SELECT accounts FROM characters')
    local totalCash = 0
    local totalBank = 0
    local totalBlack = 0

    if characters then
        for _, row in ipairs(characters) do
            if row.accounts then
                local acc = json.decode(row.accounts)
                if acc then
                    totalCash = totalCash + (acc.cash or 0)
                    totalBank = totalBank + (acc.bank or 0)
                    totalBlack = totalBlack + (acc.black_money or 0)
                end
            end
        end
    end

    -- Suma total de impuestos y sumideros destruidos en aura_transactions
    local sinkRow = MySQL.single.await('SELECT SUM(amount) as total_sinks, SUM(fee) as total_fees FROM aura_transactions WHERE type IN ("TAX", "SINK") OR fee > 0')
    local totalSinks = 0
    if sinkRow then
        totalSinks = (sinkRow.total_sinks or 0) + (sinkRow.total_fees or 0)
    end

    return {
        m0_cash = totalCash,
        m1_bank = totalBank,
        m2_black_money = totalBlack,
        total_money_supply = totalCash + totalBank + totalBlack,
        total_sinks_collected = totalSinks
    }
end
exports('GetGlobalEconomicStats', GetGlobalEconomicStats)

-- Comando Administrativo para inspección macroeconómica en consola/juego
RegisterCommand('aurastats', function(source, args)
    if source ~= 0 and not IsPlayerAceAllowed(tostring(source), 'command.admin') then
        return
    end

    CreateThread(function()
        local stats = GetGlobalEconomicStats()
        print("^2================== REPORTE MACROECONÓMICO AURA RP ==================^0")
        print(string.format("^7M0 (Efectivo Circulante):      ^2$%s^0", lib.math.groupDigits and lib.math.groupDigits(stats.m0_cash) or tostring(stats.m0_cash)))
        print(string.format("^7M1 (Depósitos Bancarios):       ^2$%s^0", lib.math.groupDigits and lib.math.groupDigits(stats.m1_bank) or tostring(stats.m1_bank)))
        print(string.format("^7M2 (Dinero Negro):              ^1$%s^0", lib.math.groupDigits and lib.math.groupDigits(stats.m2_black_money) or tostring(stats.m2_black_money)))
        print(string.format("^3Masa Monetaria Total:            ^2$%s^0", lib.math.groupDigits and lib.math.groupDigits(stats.total_money_supply) or tostring(stats.total_money_supply)))
        print(string.format("^6Total Retenido en Sumideros:    ^3$%s^0", lib.math.groupDigits and lib.math.groupDigits(stats.total_sinks_collected) or tostring(stats.total_sinks_collected)))
        print("^2===================================================================^0")
    end)
end, true)
