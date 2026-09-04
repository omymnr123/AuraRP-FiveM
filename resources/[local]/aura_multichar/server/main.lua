local activeCharacters = {}

local function GetPlayerLicense(source)
    local identifiers = GetPlayerIdentifiers(source)
    for i = 1, #identifiers do
        if string.sub(identifiers[i], 1, 8) == "license:" then
            return identifiers[i]
        end
    end
    return nil
end

-- Export para obtener el personaje activo desde otros scripts
exports('GetActiveCharacter', function(source)
    return activeCharacters[tonumber(source)]
end)

-- Helper para asegurar que la apariencia no esté vacía o machacada (Fallback a playerskins)
local function EnsureCharacterAppearance(charId, metadata)
    metadata = metadata or {}
    local app = metadata.appearance
    local needsFallback = false

    if not app or type(app) ~= "table" or next(app) == nil then
        needsFallback = true
    elseif app.components then
        local hasAnyClothing = false
        for _, comp in ipairs(app.components) do
            if comp.drawable and comp.drawable > 0 then
                hasAnyClothing = true
                break
            end
        end
        if not hasAnyClothing and app.props then
            for _, prop in ipairs(app.props) do
                if prop.drawable and prop.drawable >= 0 then
                    hasAnyClothing = true
                    break
                end
            end
        end
        if not hasAnyClothing then
            needsFallback = true
        end
    else
        needsFallback = true
    end

    if needsFallback and charId then
        local skinRow = MySQL.scalar.await('SELECT skin FROM playerskins WHERE citizenid = ? AND active = 1 ORDER BY id DESC LIMIT 1', { tostring(charId) })
        if skinRow then
            local decodedSkin = json.decode(skinRow)
            if decodedSkin and type(decodedSkin) == "table" and next(decodedSkin) ~= nil then
                metadata.appearance = decodedSkin
                MySQL.update('UPDATE characters SET metadata = ? WHERE id = ?', {
                    json.encode(metadata),
                    charId
                })
            end
        end
    end

    return metadata
end

-- Función interna para actualizar la ubicación en memoria
local function UpdateCharacterLocation(src, coords, heading)
    local char = activeCharacters[tonumber(src)]
    if not char or not char.id then return end

    if not coords then
        local ped = GetPlayerPed(src)
        if ped and ped ~= 0 then
            local pCoords = GetEntityCoords(ped)
            if pCoords and (pCoords.x ~= 0.0 or pCoords.y ~= 0.0 or pCoords.z ~= 0.0) then
                coords = {
                    x = pCoords.x,
                    y = pCoords.y,
                    z = pCoords.z,
                    heading = GetEntityHeading(ped)
                }
            end
        end
    end

    if coords and (coords.x ~= 0.0 or coords.y ~= 0.0 or coords.z ~= 0.0) then
        char.metadata = char.metadata or {}
        char.metadata.last_location = {
            x = coords.x,
            y = coords.y,
            z = coords.z,
            heading = heading or coords.heading or 0.0
        }
    end
end

-- Función para guardar físicamente en la base de datos
local function SaveCharacterToDatabase(src)
    local char = activeCharacters[tonumber(src)]
    if not char or not char.id then return end
    
    char.metadata = EnsureCharacterAppearance(char.id, char.metadata)

    MySQL.update('UPDATE characters SET metadata = ? WHERE id = ?', {
        json.encode(char.metadata),
        char.id
    })
end

-- Export para forzar guardado desde otros scripts
exports('SaveCharacterLocation', SaveCharacterToDatabase)

-- Función para actualizar la apariencia en memoria activa y en la base de datos sincronizadamente
local function SetCharacterAppearance(target, appearanceData)
    if not appearanceData or type(appearanceData) ~= "table" then return false end

    local char = nil
    local charId = nil
    local targetNum = tonumber(target)

    if targetNum and activeCharacters[targetNum] then
        char = activeCharacters[targetNum]
        charId = char.id
    else
        for _, activeChar in pairs(activeCharacters) do
            if activeChar and activeChar.id == targetNum then
                char = activeChar
                charId = targetNum
                break
            end
        end
        charId = charId or targetNum
    end

    if char then
        char.metadata = char.metadata or {}
        char.metadata.appearance = appearanceData
    end

    if charId then
        local charRow = MySQL.single.await('SELECT metadata FROM characters WHERE id = ?', { charId })
        local meta = (charRow and json.decode(charRow.metadata)) or (char and char.metadata) or {}
        meta.appearance = appearanceData

        MySQL.update.await('UPDATE characters SET metadata = ? WHERE id = ?', {
            json.encode(meta),
            charId
        })

        pcall(function()
            MySQL.update.await('UPDATE playerskins SET active = 0 WHERE citizenid = ?', { tostring(charId) })
            if appearanceData.model then
                MySQL.query.await('DELETE FROM playerskins WHERE citizenid = ? AND model = ?', { tostring(charId), appearanceData.model })
            end
            MySQL.insert.await('INSERT INTO playerskins (citizenid, model, skin, active) VALUES (?, ?, ?, 1)', {
                tostring(charId),
                appearanceData.model or 'mp_m_freemode_01',
                json.encode(appearanceData)
            })
        end)

        return true
    end

    return false
end

exports('SetCharacterAppearance', SetCharacterAppearance)

exports('UpdateCharacterMetadata', function(src, key, value)
    local char = activeCharacters[tonumber(src)]
    if not char or not char.id then return false end
    char.metadata = char.metadata or {}
    char.metadata[key] = value
    return true
end)

RegisterNetEvent('aura_multichar:server:setAppearance', function(appearanceData)
    local src = source
    SetCharacterAppearance(src, appearanceData)
end)

-- Evento de cliente para sincronización periódica de coordenadas (SOLO EN MEMORIA)
RegisterNetEvent('aura_multichar:server:updateLocation', function(locationData)
    local src = source
    if locationData and locationData.x and locationData.y and locationData.z then
        UpdateCharacterLocation(src, locationData, locationData.heading)
    end
end)

-- Limpiar el personaje activo y guardar su posición cuando el jugador se desconecta
AddEventHandler('playerDropped', function(reason)
    local src = source
    UpdateCharacterLocation(src) -- Actualiza la ultima posición
    SaveCharacterToDatabase(src) -- Guarda en DB
    activeCharacters[tonumber(src)] = nil
end)

-- Hilo de auto-guardado en segundo plano (cada 3 minutos) para no saturar oxmysql
CreateThread(function()
    while true do
        Wait(180000) -- 3 minutos
        for src, char in pairs(activeCharacters) do
            if char and char.id then
                -- Actualiza la posición con el GetPlayerPed y guarda en base de datos
                UpdateCharacterLocation(src)
                SaveCharacterToDatabase(src)
            end
        end
    end
end)

lib.callback.register('aura_multichar:getCharacters', function(source)
    local license = GetPlayerLicense(source)
    if not license then return {} end

    local citizenRecord = MySQL.single.await('SELECT citizenid FROM players WHERE license = ?', {license})
    if not citizenRecord then return {} end

    local chars = MySQL.query.await('SELECT * FROM characters WHERE citizenid = ?', {citizenRecord.citizenid})
    
    for i = 1, #chars do
        chars[i].metadata = json.decode(chars[i].metadata) or {}
        chars[i].metadata = EnsureCharacterAppearance(chars[i].id, chars[i].metadata)
        if chars[i].accounts then
            chars[i].accounts = json.decode(chars[i].accounts)
        else
            chars[i].accounts = { cash = 0, bank = 5000, black_money = 0 }
        end
    end

    return chars
end)

lib.callback.register('aura_multichar:createCharacter', function(source, data)
    local src = source
    local license = GetPlayerLicense(src)
    if not license then return nil end

    local citizenRecord = MySQL.single.await('SELECT citizenid FROM players WHERE license = ?', {license})
    if not citizenRecord then return nil end

    -- Regla estricta de la Fase 4: $5,000 en banco, $0 en cash y $0 en black_money
    local accounts = {
        cash = 0,
        bank = 5000,
        black_money = 0
    }

    local metadata = {
        health = 200,
        armor = 0,
        bank = 5000,
        cash = 0,
        black_money = 0,
        appearance = {},
        last_location = {x = -1037.8, y = -2737.9, z = 20.17, heading = 330.0} -- LSIA
    }

    local insertId = MySQL.insert.await('INSERT INTO characters (citizenid, slot, firstname, lastname, nationality, dob, gender, accounts, metadata) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        citizenRecord.citizenid,
        data.slot,
        data.firstname,
        data.lastname,
        data.nationality,
        data.dob,
        data.gender,
        json.encode(accounts),
        json.encode(metadata)
    })

    if insertId then
        -- Generar número de teléfono a través de aura_phone
        local phoneNum = nil
        pcall(function()
            if exports.aura_phone and exports.aura_phone.assignPhoneNumber then
                phoneNum = exports.aura_phone:assignPhoneNumber(insertId)
            end
        end)

        local newChar = {
            id = insertId,
            citizenid = citizenRecord.citizenid,
            slot = data.slot,
            firstname = data.firstname,
            lastname = data.lastname,
            nationality = data.nationality,
            dob = data.dob,
            gender = data.gender,
            phone_number = phoneNum,
            accounts = accounts,
            metadata = metadata
        }
        -- Registrar inmediatamente como personaje activo en esta sesión
        activeCharacters[tonumber(src)] = newChar
        
        -- Sincronizar teléfono
        pcall(function()
            if phoneNum and exports.aura_phone and exports.aura_phone.setPhoneOnline then
                exports.aura_phone:setPhoneOnline(src, phoneNum)
            end
        end)

        -- Registrar transacción inicial en auditoría económica
        pcall(function()
            if exports.aura_economy and exports.aura_economy.RegisterInitialBalance then
                exports.aura_economy:RegisterInitialBalance(insertId)
            end
        end)

        -- Notificar carga a aura_economy y aura_jobs
        TriggerEvent('aura_economy:server:characterLoaded', src, insertId, accounts)
        pcall(function()
            if exports.aura_jobs and exports.aura_jobs.LoadPlayerJob then
                exports.aura_jobs:LoadPlayerJob(src, insertId)
            else
                TriggerEvent('aura_multichar:server:characterLoaded', insertId, src)
            end
        end)

        return newChar
    end

    return nil
end)

lib.callback.register('aura_multichar:deleteCharacter', function(source, slot)
    local license = GetPlayerLicense(source)
    if not license then return false end

    local citizenRecord = MySQL.single.await('SELECT citizenid FROM players WHERE license = ?', {license})
    if not citizenRecord then return false end

    local affectedRows = MySQL.update.await('DELETE FROM characters WHERE citizenid = ? AND slot = ?', {citizenRecord.citizenid, slot})
    return affectedRows > 0
end)

lib.callback.register('aura_multichar:selectCharacter', function(source, id)
    local src = source
    local license = GetPlayerLicense(src)
    if not license then return nil end

    local citizenRecord = MySQL.single.await('SELECT citizenid FROM players WHERE license = ?', {license})
    if not citizenRecord then return nil end

    local char = MySQL.single.await('SELECT * FROM characters WHERE citizenid = ? AND id = ?', {citizenRecord.citizenid, id})
    if not char then return nil end

    -- Retrocompatibilidad: Asignar número si es un personaje viejo sin teléfono
    if not char.phone_number or char.phone_number == "" then
        pcall(function()
            if exports.aura_phone and exports.aura_phone.assignPhoneNumber then
                char.phone_number = exports.aura_phone:assignPhoneNumber(char.id)
            end
        end)
    end

    char.metadata = json.decode(char.metadata) or {}
    char.metadata = EnsureCharacterAppearance(char.id, char.metadata)
    if char.accounts then
        char.accounts = json.decode(char.accounts)
    else
        char.accounts = {
            cash = (char.metadata and char.metadata.cash) or 0,
            bank = (char.metadata and char.metadata.bank) or 5000,
            black_money = (char.metadata and char.metadata.black_money) or 0
        }
    end
    
    -- Registrar personaje activo para esta sesión
    activeCharacters[tonumber(src)] = char

    -- Sincronizar teléfono
    pcall(function()
        if char.phone_number and exports.aura_phone and exports.aura_phone.setPhoneOnline then
            exports.aura_phone:setPhoneOnline(src, char.phone_number)
        end
    end)

    -- Sincronizar estado en memoria en aura_economy y aura_jobs
    TriggerEvent('aura_economy:server:characterLoaded', src, char.id, char.accounts)
    pcall(function()
        if exports.aura_jobs and exports.aura_jobs.LoadPlayerJob then
            exports.aura_jobs:LoadPlayerJob(src, char.id)
        else
            TriggerEvent('aura_multichar:server:characterLoaded', char.id, src)
        end
    end)

    return char
end)

RegisterNetEvent('aura_multichar:cancelPendingCharacter', function(charId)
    local src = source
    local targetId = charId
    if not targetId then
        local active = activeCharacters[tonumber(src)]
        if active then targetId = active.id end
    end

    if targetId then
        MySQL.query('DELETE FROM characters WHERE id = ?', { targetId })
        activeCharacters[tonumber(src)] = nil
    end
end)
