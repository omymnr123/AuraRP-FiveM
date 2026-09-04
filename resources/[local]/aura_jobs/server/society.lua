local AuraSociety = {
    Societies = {}, -- [societyName] = { name = 'burgershot', label = 'Burgershot', balance = 15000 }
    Locks = {}      -- Mutex lock por sociedad
}

-- ============================================================================
-- UTILIDADES INTERNAS Y CONCURRENCIA
-- ============================================================================

local function NormalizeSocietyName(jobOrSociety)
    if not jobOrSociety or type(jobOrSociety) ~= 'string' then return nil end
    if string.sub(jobOrSociety, 1, 8) == "society_" then
        return string.sub(jobOrSociety, 9)
    end
    return jobOrSociety
end

local function AcquireLock(societyName)
    local timeout = 500
    local elapsed = 0
    while AuraSociety.Locks[societyName] do
        Wait(10)
        elapsed = elapsed + 10
        if elapsed >= timeout then
            print(string.format("[Aura Jobs] ^3ADVERTENCIA: Lock timeout superado para sociedad %s. Liberando.^0", societyName))
            break
        end
    end
    AuraSociety.Locks[societyName] = true
end

local function ReleaseLock(societyName)
    AuraSociety.Locks[societyName] = nil
end

-- ============================================================================
-- INICIALIZACIÓN Y CARGA DE SOCIEDADES EN MEMORIA
-- ============================================================================

local function LoadSocieties()
    local results = MySQL.query.await('SELECT name, label, balance FROM aura_societies', {})
    if results then
        for _, row in ipairs(results) do
            AuraSociety.Societies[row.name] = {
                name = row.name,
                label = row.label,
                balance = tonumber(row.balance) or 0
            }
        end
    end

    -- Inicializar cualquier trabajo de Config.Jobs que no exista en la DB
    for jobName, jobData in pairs(Config.Jobs) do
        if (jobData.isBusiness or jobData.isGang) and not AuraSociety.Societies[jobName] then
            MySQL.insert.await('INSERT INTO aura_societies (name, label, balance) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE `label` = VALUES(`label`)', {
                jobName,
                jobData.label,
                0
            })
            AuraSociety.Societies[jobName] = {
                name = jobName,
                label = jobData.label,
                balance = 0
            }
        end
    end

    print(string.format("[Aura Jobs] ^2Sistema de Sociedades inicializado: %d empresas cargadas en RAM.^0", #results or 0))
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    LoadSocieties()
end)

-- ============================================================================
-- API PÚBLICA DEL SERVIDOR (SOCIETY EXPORTS)
-- ============================================================================

--- Obtiene el saldo actual de la sociedad empresarial
--- @param jobOrSociety string Nombre del trabajo o identificador 'society_xxx'
--- @return number Balance de la empresa o 0
local function GetSocietyBalance(jobOrSociety)
    local name = NormalizeSocietyName(jobOrSociety)
    if not name then return 0 end
    if AuraSociety.Societies[name] then
        return AuraSociety.Societies[name].balance or 0
    end
    local row = MySQL.single.await('SELECT balance FROM aura_societies WHERE name = ?', { name })
    if row then
        return tonumber(row.balance) or 0
    end
    return 0
end
exports('GetSocietyBalance', GetSocietyBalance)

--- Añade dinero a la cuenta societaria de la empresa
--- @param jobOrSociety string Nombre del trabajo o sociedad
--- @param amount number Cantidad a ingresar (> 0)
--- @param reason string Motivo del ingreso
--- @param metadata table | nil Metadatos adicionales
--- @return boolean success, number newBalance
local function AddSocietyMoney(jobOrSociety, amount, reason, metadata)
    local name = NormalizeSocietyName(jobOrSociety)
    if not name or type(amount) ~= 'number' or amount <= 0 then
        return false, 0
    end

    AcquireLock(name)

    local current = AuraSociety.Societies[name]
    if not current then
        local label = Config.Jobs[name] and Config.Jobs[name].label or name
        AuraSociety.Societies[name] = { name = name, label = label, balance = 0 }
        current = AuraSociety.Societies[name]
    end

    local newBalance = current.balance + math.floor(amount)
    current.balance = newBalance

    MySQL.update('UPDATE aura_societies SET balance = ? WHERE name = ?', { newBalance, name })

    if Config.Debug then
        print(string.format("[Aura Jobs] +$%d acreditados a la sociedad '%s'. Motivo: %s | Nuevo Saldo: $%d", amount, name, reason or "N/A", newBalance))
    end

    ReleaseLock(name)
    return true, newBalance
end
exports('AddSocietyMoney', AddSocietyMoney)

--- Retira fondos de la cuenta societaria de la empresa
--- @param jobOrSociety string Nombre del trabajo o sociedad
--- @param amount number Cantidad a retirar (> 0)
--- @param reason string Motivo de la retirada
--- @param metadata table | nil Metadatos adicionales
--- @return boolean success, number newBalance
local function RemoveSocietyMoney(jobOrSociety, amount, reason, metadata)
    local name = NormalizeSocietyName(jobOrSociety)
    if not name or type(amount) ~= 'number' or amount <= 0 then
        return false, 0
    end

    AcquireLock(name)

    local current = AuraSociety.Societies[name]
    if not current or current.balance < amount then
        ReleaseLock(name)
        return false, (current and current.balance) or 0
    end

    local newBalance = current.balance - math.floor(amount)
    current.balance = newBalance

    MySQL.update('UPDATE aura_societies SET balance = ? WHERE name = ?', { newBalance, name })

    ReleaseLock(name)
    return true, newBalance
end
exports('RemoveSocietyMoney', RemoveSocietyMoney)

lib.callback.register('aura_jobs:server:getSocietyBalance', function(source)
    local pState = Player(source).state
    local job = pState.job or 'unemployed'
    local isDuty = pState.job_duty == true
    local jobConfig = Config.Jobs[job]
    if not isDuty or not jobConfig or not jobConfig.isBusiness then
        return false, 0, "No estás de servicio en una empresa."
    end
    local balance = GetSocietyBalance(job)
    return true, balance, (jobConfig.label or job)
end)
