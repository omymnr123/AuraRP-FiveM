-- ============================================================================
-- AURA DEATH: SERVER MAIN CONTROLLER (PERSISTENCE, PK & DISPATCH HOOK)
-- ============================================================================

local deadPlayers = {} -- [source] = { charId = 11, citizenid = 'HLWWIZKU', remaining = 600, deathTime = os.time(), lastDispatch = 0 }

--- Inicialización y migración automática de la tabla en base de datos al arrancar el recurso
CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `aura_death` (
          `character_id` int(11) NOT NULL,
          `citizenid` varchar(50) NOT NULL,
          `is_dead` tinyint(1) NOT NULL DEFAULT 0,
          `death_time` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
          `bleedout_remaining` int(11) NOT NULL DEFAULT 600 COMMENT 'Segundos restantes de estado crítico',
          `death_reason` varchar(255) DEFAULT 'Heridas Críticas',
          `killer_source` varchar(100) DEFAULT NULL,
          PRIMARY KEY (`character_id`),
          KEY `idx_death_citizenid` (`citizenid`),
          KEY `idx_death_status` (`is_dead`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {}, function(success)
        -- Verificar si la tabla existe con el esquema antiguo (sin character_id) y migrarla
        MySQL.query([[
            SELECT COLUMN_NAME 
            FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME = 'aura_death' 
              AND COLUMN_NAME = 'character_id';
        ]], {}, function(result)
            if not result or #result == 0 then
                print("[AURA_DEATH] Migrando tabla `aura_death` a esquema con `character_id`...")
                pcall(function()
                    MySQL.query.await([[
                        ALTER TABLE `aura_death` 
                        DROP PRIMARY KEY,
                        ADD COLUMN `character_id` INT(11) NOT NULL FIRST,
                        ADD PRIMARY KEY (`character_id`),
                        ADD INDEX `idx_death_citizenid` (`citizenid`);
                    ]])
                end)
                print("[AURA_DEATH] Migración de `aura_death` completada.")
            else
                if Config.Debug then
                    print("[AURA_DEATH] Tabla `aura_death` verificada y lista con Primary Key `character_id`.")
                end
            end
        end)
    end)
end)

--- Obtiene la información del personaje activo (ID único de personaje y CitizenID)
--- @param source number Source ID del jugador
--- @return table|nil { charId = number, citizenid = string }
local function GetPlayerCharacterInfo(source)
    if not source or source <= 0 then return nil end

    -- 1. Intentar desde aura_multichar
    if exports.aura_multichar and exports.aura_multichar.GetActiveCharacter then
        local char = exports.aura_multichar:GetActiveCharacter(source)
        if char and char.id then
            return {
                charId = tonumber(char.id),
                citizenid = char.citizenid
            }
        end
    end

    -- 2. Intentar desde aura_core
    if exports.aura_core and exports.aura_core.GetPlayer then
        local player = exports.aura_core:GetPlayer(source)
        if player and player.citizenid then
            local charId = MySQL.scalar.await('SELECT id FROM characters WHERE citizenid = ? ORDER BY last_played DESC LIMIT 1', { player.citizenid })
            return {
                charId = tonumber(charId) or source,
                citizenid = player.citizenid
            }
        end
    end

    -- 3. Fallback: buscar por licencia en players
    local identifiers = GetPlayerIdentifiers(source)
    for _, id in ipairs(identifiers) do
        if string.sub(id, 1, 8) == "license:" then
            local citizenid = MySQL.scalar.await('SELECT citizenid FROM players WHERE license = ? LIMIT 1', { id })
            if citizenid then
                local charId = MySQL.scalar.await('SELECT id FROM characters WHERE citizenid = ? ORDER BY last_played DESC LIMIT 1', { citizenid })
                return {
                    charId = tonumber(charId) or source,
                    citizenid = citizenid
                }
            end
        end
    end

    return nil
end

--- Confisca el inventario completo tras PK o reaparición en hospital (conservando únicamente teléfono y documentos)
--- @param src number Source del jugador
local function ConfiscatePlayerInventoryForHospital(src)
    if not exports.ox_inventory then return end

    local inventoryItems = exports.ox_inventory:GetInventoryItems(src)
    if not inventoryItems then return end

    local preserved = Config.PreservedItems or {
        ['phone'] = true,
        ['id_card'] = true,
        ['police_badge'] = true,
        ['driver_license'] = true,
        ['identification'] = true
    }

    for slot, item in pairs(inventoryItems) do
        if item and item.name then
            local isPreserved = preserved[item.name] or false

            -- Si no es un item protegido (teléfono o documento de identidad), se confisca
            if not isPreserved then
                exports.ox_inventory:RemoveItem(src, item.name, item.count or 1, item.metadata, slot)
                if Config.Debug then
                    print(string.format("[AURA_DEATH] Item retirado en PK a Source %s: %s x%s (Slot: %s)", src, item.name, item.count or 1, slot))
                end
            end
        end
    end
end

-- ============================================================================
-- EVENTOS DE RED (SERVER EVENTS)
-- ============================================================================

-- Jugador entra en coma / estado crítico
RegisterNetEvent('aura_death:server:playerEnteredComa', function(remainingTime, deathReason, killerSource)
    local src = source
    local charInfo = GetPlayerCharacterInfo(src)
    if not charInfo then return end

    local bleedoutTime = tonumber(remainingTime) or Config.BleedoutTime
    local reason = deathReason or "Trauma Crítico"
    local killerStr = killerSource and tostring(killerSource) or nil

    deadPlayers[src] = {
        charId = charInfo.charId,
        citizenid = charInfo.citizenid,
        remaining = bleedoutTime,
        deathTime = os.time(),
        lastDispatch = 0
    }

    Player(src).state:set('isDead', true, true)

    -- Guardado atómico en tabla dedicada `aura_death`
    MySQL.insert([[
        INSERT INTO `aura_death` (`character_id`, `citizenid`, `is_dead`, `bleedout_remaining`, `death_reason`, `killer_source`, `death_time`)
        VALUES (?, ?, 1, ?, ?, ?, NOW())
        ON DUPLICATE KEY UPDATE
            `citizenid` = VALUES(`citizenid`),
            `is_dead` = 1,
            `bleedout_remaining` = VALUES(`bleedout_remaining`),
            `death_reason` = VALUES(`death_reason`),
            `killer_source` = VALUES(`killer_source`),
            `death_time` = NOW()
    ]], { charInfo.charId, charInfo.citizenid, bleedoutTime, reason, killerStr })

    -- Doble persistencia en la tabla `characters`
    MySQL.update([[
        UPDATE `characters` 
        SET `metadata` = JSON_SET(
            IFNULL(`metadata`, '{}'),
            '$.is_dead', 1,
            '$.death', JSON_OBJECT('inComa', true, 'remaining', ?, 'reason', ?)
        )
        WHERE `id` = ?
    ]], { bleedoutTime, reason, charInfo.charId })

    -- Actualizar memoria de aura_multichar
    if exports.aura_multichar and exports.aura_multichar.GetActiveCharacter then
        local char = exports.aura_multichar:GetActiveCharacter(src)
        if char then
            char.metadata = char.metadata or {}
            char.metadata.is_dead = 1
            char.metadata.death = {
                inComa = true,
                remaining = bleedoutTime,
                reason = reason
            }
        end
    end

    if Config.Debug then
        print(string.format("[AURA_DEATH] Personaje ID %s (CitizenID: %s) guardado en COMA en BD. Tiempo: %ss.", charInfo.charId, charInfo.citizenid, bleedoutTime))
    end
end)

-- Sincronización periódica del tiempo restante de desangrado
RegisterNetEvent('aura_death:server:syncBleedoutTime', function(remaining)
    local src = source
    local charInfo = GetPlayerCharacterInfo(src)
    if not charInfo then return end

    local seconds = tonumber(remaining)
    if not seconds then return end

    if deadPlayers[src] then
        deadPlayers[src].remaining = seconds
    end

    MySQL.update('UPDATE `aura_death` SET `bleedout_remaining` = ?, `death_time` = NOW() WHERE `character_id` = ? AND `is_dead` = 1', {
        seconds,
        charInfo.charId
    })
end)

-- Hook de alerta a emergencias (Botón "EMERGENCIAS")
RegisterNetEvent('aura_death:server:callDispatch', function()
    local src = source
    local charInfo = GetPlayerCharacterInfo(src)
    if not charInfo then return end

    local now = os.time()
    local playerData = deadPlayers[src]

    if playerData and (now - playerData.lastDispatch < Config.DispatchCooldown) then
        local cooldownRemaining = Config.DispatchCooldown - (now - playerData.lastDispatch)
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Emergencias',
            description = string.format('Ya has enviado una alerta. Espera %s segundos antes de volver a llamar.', cooldownRemaining),
            type = 'error'
        })
        return
    end

    if playerData then
        playerData.lastDispatch = now
    end

    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)

    TriggerEvent('aura_death:onDispatchCalled', src, coords, charInfo.citizenid)
    TriggerEvent('aura_ems:server:reportComaEmergency', {
        src = src,
        coords = coords,
        citizenid = charInfo.citizenid,
        deathReason = playerData and playerData.reason or "Parada Cardiorrespiratoria / Coma"
    })

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Emergencias 911 / EMS',
        description = 'Señal de auxilio y localización GPS enviada a los servicios de emergencia.',
        type = 'info',
        icon = 'satellite-dish',
        duration = 6000
    })
end)

-- Pausado de temporizador de desangrado (por aplicación de torniquete táctico)
RegisterNetEvent('aura_death:server:pauseBleedout', function(targetSrc)
    local target = tonumber(targetSrc) or source
    if deadPlayers[target] then
        deadPlayers[target].isPaused = true
    end
    Player(target).state:set('bleedoutPaused', true, true)
    TriggerClientEvent('aura_death:client:pauseBleedout', target)
end)

-- Reaparición voluntaria en Hospital (Botón "HOSPITAL")
RegisterNetEvent('aura_death:server:requestHospitalRespawn', function()
    local src = source
    local charInfo = GetPlayerCharacterInfo(src)
    if not charInfo then return end

    if Config.Debug then
        print(string.format("[AURA_DEATH] Reaparición voluntaria en Hospital solicitada por Source %s (Char ID: %s).", src, charInfo.charId))
    end

    -- 1. Confiscar inventario completo excepto teléfono y documentación
    ConfiscatePlayerInventoryForHospital(src)

    -- 2. Limpieza de estado de muerte en Base de Datos
    MySQL.update('UPDATE `aura_death` SET `is_dead` = 0, `bleedout_remaining` = 0 WHERE `character_id` = ?', {
        charInfo.charId
    })

    MySQL.update([[
        UPDATE `characters` 
        SET `metadata` = JSON_SET(
            IFNULL(`metadata`, '{}'),
            '$.is_dead', 0,
            '$.death', JSON_OBJECT('inComa', false, 'remaining', 0)
        )
        WHERE `id` = ?
    ]], { charInfo.charId })

    -- 3. Limpieza en memoria y StateBag
    deadPlayers[src] = nil
    Player(src).state:set('isDead', false, true)

    if exports.aura_multichar and exports.aura_multichar.GetActiveCharacter then
        local char = exports.aura_multichar:GetActiveCharacter(src)
        if char and char.metadata then
            char.metadata.is_dead = 0
            char.metadata.death = nil
            char.metadata.health = Config.HospitalReviveHealth
            char.metadata.armor = Config.HospitalReviveArmor
        end
    end

    -- 4. Ordenar reaparición en cama de hospital al cliente
    TriggerClientEvent('aura_death:client:respawnAtHospital', src)
end)

-- Expiración del temporizador de desangrado (10 minutos alcanzados -> PK forzoso)
RegisterNetEvent('aura_death:server:timerExpired', function()
    local src = source
    local charInfo = GetPlayerCharacterInfo(src)
    if not charInfo then return end

    ConfiscatePlayerInventoryForHospital(src)

    MySQL.update('UPDATE `aura_death` SET `is_dead` = 0, `bleedout_remaining` = 0 WHERE `character_id` = ?', {
        charInfo.charId
    })

    MySQL.update([[
        UPDATE `characters` 
        SET `metadata` = JSON_SET(
            IFNULL(`metadata`, '{}'),
            '$.is_dead', 0,
            '$.death', JSON_OBJECT('inComa', false, 'remaining', 0)
        )
        WHERE `id` = ?
    ]], { charInfo.charId })

    deadPlayers[src] = nil
    Player(src).state:set('isDead', false, true)

    if exports.aura_multichar and exports.aura_multichar.GetActiveCharacter then
        local char = exports.aura_multichar:GetActiveCharacter(src)
        if char and char.metadata then
            char.metadata.is_dead = 0
            char.metadata.death = nil
        end
    end

    TriggerClientEvent('aura_death:client:respawnAtHospital', src)
end)

-- Verificación de estado de muerte al reconectar, cambiar de personaje o reiniciar servidor
RegisterNetEvent('aura_death:server:checkDeathState', function()
    local src = source
    local charInfo = GetPlayerCharacterInfo(src)
    if not charInfo then return end

    local deathRecord = MySQL.single.await([[
        SELECT `character_id`, `is_dead`, `bleedout_remaining`, UNIX_TIMESTAMP(`death_time`) as `death_ts` 
        FROM `aura_death` 
        WHERE `character_id` = ? 
        LIMIT 1
    ]], { charInfo.charId })

    if not deathRecord then
        -- Fallback 1: comprobar por citizenid
        deathRecord = MySQL.single.await([[
            SELECT `character_id`, `is_dead`, `bleedout_remaining`, UNIX_TIMESTAMP(`death_time`) as `death_ts` 
            FROM `aura_death` 
            WHERE `citizenid` = ? AND `is_dead` = 1
            LIMIT 1
        ]], { charInfo.citizenid })
    end

    if not deathRecord then
        -- Fallback 2: comprobar por metadata en la tabla characters
        local charMeta = MySQL.scalar.await("SELECT `metadata` FROM `characters` WHERE `id` = ? LIMIT 1", { charInfo.charId })
        if charMeta then
            local decoded = type(charMeta) == "string" and json.decode(charMeta) or charMeta
            if decoded and (decoded.is_dead == 1 or (decoded.death and decoded.death.inComa)) then
                local rem = decoded.death and tonumber(decoded.death.remaining) or Config.BleedoutTime
                deathRecord = {
                    character_id = charInfo.charId,
                    is_dead = 1,
                    bleedout_remaining = rem,
                    death_ts = os.time()
                }
            end
        end
    end

    if deathRecord and deathRecord.is_dead == 1 then
        local elapsed = os.time() - (deathRecord.death_ts or os.time())
        local remaining = (deathRecord.bleedout_remaining or Config.BleedoutTime) - elapsed

        if remaining <= 0 then
            -- El tiempo expiró mientras estaba desconectado: ejecutar reaparición en hospital
            ConfiscatePlayerInventoryForHospital(src)
            MySQL.update('UPDATE `aura_death` SET `is_dead` = 0, `bleedout_remaining` = 0 WHERE `character_id` = ?', { charInfo.charId })
            MySQL.update("UPDATE `characters` SET `metadata` = JSON_SET(IFNULL(`metadata`, '{}'), '$.is_dead', 0, '$.death', JSON_OBJECT('inComa', false)) WHERE `id` = ?", { charInfo.charId })
            deadPlayers[src] = nil
            Player(src).state:set('isDead', false, true)
            TriggerClientEvent('aura_death:client:respawnAtHospital', src)
        else
            -- Sigue en estado crítico: restaurar coma con el tiempo exacto restante
            deadPlayers[src] = {
                charId = charInfo.charId,
                citizenid = charInfo.citizenid,
                remaining = remaining,
                deathTime = os.time(),
                lastDispatch = 0
            }
            Player(src).state:set('isDead', true, true)
            TriggerClientEvent('aura_death:client:setInComa', src, remaining, "Estado Crítico Persistente")
        end
    else
        Player(src).state:set('isDead', false, true)
    end
end)

-- Guardado de emergencia al desconectarse el jugador o caerse el servidor
AddEventHandler('playerDropped', function()
    local src = source
    local data = deadPlayers[src]
    if data and data.charId then
        MySQL.update.await('UPDATE `aura_death` SET `bleedout_remaining` = ?, `death_time` = NOW() WHERE `character_id` = ? AND `is_dead` = 1', {
            data.remaining,
            data.charId
        })
        MySQL.update.await("UPDATE `characters` SET `metadata` = JSON_SET(IFNULL(`metadata`, '{}'), '$.is_dead', 1, '$.death', JSON_OBJECT('inComa', true, 'remaining', ?)) WHERE `id` = ?", {
            data.remaining,
            data.charId
        })
        deadPlayers[src] = nil
    end
end)

-- Guardado síncrono maestro de todos los jugadores muertos al detener el recurso o reiniciar el servidor
local function SaveAllDeathStates()
    local count = 0
    for src, data in pairs(deadPlayers) do
        if data and data.charId and data.remaining then
            MySQL.update.await('UPDATE `aura_death` SET `bleedout_remaining` = ?, `death_time` = NOW() WHERE `character_id` = ? AND `is_dead` = 1', {
                data.remaining,
                data.charId
            })
            MySQL.update.await("UPDATE `characters` SET `metadata` = JSON_SET(IFNULL(`metadata`, '{}'), '$.is_dead', 1, '$.death', JSON_OBJECT('inComa', true, 'remaining', ?)) WHERE `id` = ?", {
                data.remaining,
                data.charId
            })
            count = count + 1
        end
    end
    return count
end
exports('SaveAllDeathStates', SaveAllDeathStates)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    SaveAllDeathStates()
end)

-- ============================================================================
-- COMANDOS ADMINISTRATIVOS (/revive y /kill)
-- ============================================================================

local function IsAdmin(source)
    if source == 0 then return true end
    local srcStr = tostring(source)
    if IsPlayerAceAllowed(srcStr, 'group.admin') or IsPlayerAceAllowed(srcStr, 'command') or IsPlayerAceAllowed(srcStr, 'command.revive') then
        return true
    end
    if exports.aura_core and exports.aura_core.GetPlayer then
        local player = exports.aura_core:GetPlayer(source)
        if player and player.metadata and (player.metadata.permissions == 'admin' or player.metadata.permissions == 'god') then
            return true
        end
    end
    return false
end

-- Comando /revive [id]
RegisterCommand('revive', function(source, args)
    if not IsAdmin(source) then
        if source > 0 then
            TriggerClientEvent('ox_lib:notify', source, { title = 'Permisos Insuficientes', description = 'No tienes autorización para usar /revive.', type = 'error' })
        end
        return
    end

    local targetSrc = tonumber(args[1]) or source
    if not targetSrc or targetSrc <= 0 or not GetPlayerPed(targetSrc) or GetPlayerPed(targetSrc) == 0 then
        if source > 0 then
            TriggerClientEvent('ox_lib:notify', source, { title = 'Error', description = 'ID de jugador no válido.', type = 'error' })
        end
        return
    end

    local charInfo = GetPlayerCharacterInfo(targetSrc)
    if charInfo then
        MySQL.update('UPDATE `aura_death` SET `is_dead` = 0, `bleedout_remaining` = 0 WHERE `character_id` = ?', { charInfo.charId })
        MySQL.update("UPDATE `characters` SET `metadata` = JSON_SET(IFNULL(`metadata`, '{}'), '$.is_dead', 0, '$.death', JSON_OBJECT('inComa', false)) WHERE `id` = ?", { charInfo.charId })
    end

    deadPlayers[targetSrc] = nil
    Player(targetSrc).state:set('isDead', false, true)

    TriggerClientEvent('aura_death:client:revivePlayer', targetSrc)

    if source > 0 and source ~= targetSrc then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Reanimación Exitosa',
            description = string.format('Has reanimado al jugador ID %s.', targetSrc),
            type = 'success'
        })
    end
end, false)

-- Comando /kill [id] para pruebas técnicas
RegisterCommand('kill', function(source, args)
    if not IsAdmin(source) then
        if source > 0 then
            TriggerClientEvent('ox_lib:notify', source, { title = 'Permisos Insuficientes', description = 'No tienes autorización para usar /kill.', type = 'error' })
        end
        return
    end

    local targetSrc = tonumber(args[1]) or source
    if not targetSrc or targetSrc <= 0 or not GetPlayerPed(targetSrc) or GetPlayerPed(targetSrc) == 0 then
        return
    end

    TriggerClientEvent('aura_death:client:killPlayer', targetSrc)
end, false)

-- ============================================================================
-- EXPORTS DEL SERVIDOR
-- ============================================================================

exports('isPlayerDead', function(source)
    return deadPlayers[tonumber(source)] ~= nil or (Player(source).state and Player(source).state.isDead == true)
end)

exports('revivePlayer', function(targetSrc)
    local src = tonumber(targetSrc)
    if not src then return false end

    local charInfo = GetPlayerCharacterInfo(src)
    if charInfo then
        MySQL.update('UPDATE `aura_death` SET `is_dead` = 0, `bleedout_remaining` = 0 WHERE `character_id` = ?', { charInfo.charId })
        MySQL.update("UPDATE `characters` SET `metadata` = JSON_SET(IFNULL(`metadata`, '{}'), '$.is_dead', 0, '$.death', JSON_OBJECT('inComa', false)) WHERE `id` = ?", { charInfo.charId })
    end

    deadPlayers[src] = nil
    Player(src).state:set('isDead', false, true)
    TriggerClientEvent('aura_death:client:revivePlayer', src)
    return true
end)
