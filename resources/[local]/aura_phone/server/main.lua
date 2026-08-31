AuraPhone = AuraPhone or {}
AuraPhone.ActivePhones = AuraPhone.ActivePhones or {} -- [phoneNumber] = source
AuraPhone.PhoneToSource = AuraPhone.PhoneToSource or {} -- [source] = phoneNumber
AuraPhone.CallData = AuraPhone.CallData or {}

-- Función universal para resolver el número del jugador de forma infalible
function AuraPhone.GetPlayerPhoneNumber(source)
    local src = tonumber(source)
    if not src then return nil end

    -- 1. Caché en memoria
    if AuraPhone.PhoneToSource and AuraPhone.PhoneToSource[src] then
        return AuraPhone.PhoneToSource[src]
    end

    -- 2. Export de multicharacter
    if exports.aura_multichar and exports.aura_multichar.GetActiveCharacter then
        local char = exports.aura_multichar:GetActiveCharacter(src)
        if char and char.phone_number then
            AuraPhone.PhoneToSource[src] = char.phone_number
            AuraPhone.ActivePhones[char.phone_number] = src
            return char.phone_number
        end
    end

    -- 3. Consulta directa a la base de datos por licencia
    local identifiers = GetPlayerIdentifiers(src)
    local license = nil
    for i = 1, #identifiers do
        if string.sub(identifiers[i], 1, 8) == "license:" then
            license = identifiers[i]
            break
        end
    end

    if license then
        local char = MySQL.single.await([[
            SELECT c.phone_number 
            FROM characters c 
            JOIN players p ON c.citizenid = p.citizenid 
            WHERE p.license = ? 
            ORDER BY c.last_played DESC LIMIT 1
        ]], {license})

        if char and char.phone_number then
            AuraPhone.PhoneToSource[src] = char.phone_number
            AuraPhone.ActivePhones[char.phone_number] = src
            return char.phone_number
        end
    end

    return nil
end

-- Al iniciar o reiniciar el recurso, resolver automáticamente a todos los jugadores online
AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    CreateThread(function()
        Wait(500)
        local players = GetPlayers()
        for _, playerId in ipairs(players) do
            local src = tonumber(playerId)
            if src then
                AuraPhone.GetPlayerPhoneNumber(src)
            end
        end
    end)
end)

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
