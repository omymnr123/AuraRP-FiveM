-- ============================================================================
-- AURA ECONOMY: CLIENT SUBSYSTEM (REACTIVE STATE BAGS & UI SYNC)
-- ============================================================================

local currentAccounts = {
    cash = 0,
    bank = 5000,
    black_money = 0
}

-- Sincronización reactiva mediante State Bag del jugador local
AddStateBagChangeHandler('money', string.format('player:%s', GetPlayerServerId(PlayerId())), function(bagName, key, value, _unused, _replicated)
    if value and type(value) == 'table' then
        currentAccounts.cash = value.cash or currentAccounts.cash
        currentAccounts.bank = value.bank or currentAccounts.bank
        currentAccounts.black_money = value.black_money or currentAccounts.black_money

        -- Emitir evento local para cualquier interfaz o HUD
        TriggerEvent('aura_economy:client:onBalanceChanged', currentAccounts)
    end
end)

-- Evento de actualización de saldo disparado por el servidor
RegisterNetEvent('aura_economy:onBalanceUpdate', function(account, newBalance, delta, reason)
    currentAccounts[account] = newBalance

    if Config.Debug then
        local sign = delta >= 0 and "+" or ""
        print(string.format("[Aura Economy Client] Actualización de cuenta %s: %s$%d | Saldo: $%d | Motivo: %s", account, sign, delta, newBalance, reason or ""))
    end
end)

-- ============================================================================
-- EXPORTS DEL CLIENTE (READ-ONLY)
-- ============================================================================

local function GetCash()
    local state = LocalPlayer.state.money
    if state and state.cash ~= nil then return state.cash end
    return currentAccounts.cash
end
exports('GetCash', GetCash)

local function GetBank()
    local state = LocalPlayer.state.money
    if state and state.bank ~= nil then return state.bank end
    return currentAccounts.bank
end
exports('GetBank', GetBank)

local function GetBlackMoney()
    local state = LocalPlayer.state.money
    if state and state.black_money ~= nil then return state.black_money end
    return currentAccounts.black_money
end
exports('GetBlackMoney', GetBlackMoney)

local function GetAccounts()
    local state = LocalPlayer.state.money
    if state then
        return {
            cash = state.cash or currentAccounts.cash,
            bank = state.bank or currentAccounts.bank,
            black_money = state.black_money or currentAccounts.black_money
        }
    end
    return currentAccounts
end
exports('GetAccounts', GetAccounts)
