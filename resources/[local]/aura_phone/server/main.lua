local AuraPhone = {}

-- Generador de números de teléfono aleatorios (ej: 555-XXXX)
local function GeneratePhoneNumber()
    local prefix = "555"
    local suffix = string.format("%04d", math.random(1000, 9999))
    return prefix .. "-" .. suffix
end

-- Asignar número al crear personaje si no tiene (Llamar desde tu core/multichar al crear un pj)
exports('assignPhoneNumber', function(charId)
    local isUnique = false
    local number = ""
    
    while not isUnique do
        number = GeneratePhoneNumber()
        local exists = MySQL.scalar.await('SELECT 1 FROM characters WHERE phone_number = ?', { number })
        if not exists then isUnique = true end
    end
    
    MySQL.update('UPDATE characters SET phone_number = ? WHERE id = ?', { number, charId })
    return number
end)

-- Endpoint Seguro para Transferencias Bancarias
-- Usamos ox_lib callback, el 'source' es sagrado e infalsificable por NUI
lib.callback.register('aura_phone:server:bankTransfer', function(source, targetCharId, amount, reason)
    local src = source
    local amountNum = tonumber(amount)
    
    if not amountNum or amountNum <= 0 then
        return false, "Cantidad inválida"
    end
    
    if not targetCharId then
        return false, "Destinatario inválido"
    end
    
    -- Invocamos directamente al core de la economía.
    -- TransferMoney espera: (fromSrcOrId, toSrcOrId, amount, reason)
    -- Le pasamos 'src' como fromSrcOrId para asegurar que el que transfiere es el source real
    local success, errCode, txId = exports.aura_economy:TransferMoney(src, targetCharId, amountNum, reason or "Transferencia Móvil")
    
    if success then
        return true, "Transferencia exitosa"
    else
        return false, "Error: " .. tostring(errCode)
    end
end)
