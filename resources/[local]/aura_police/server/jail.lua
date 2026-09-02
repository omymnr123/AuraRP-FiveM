-- ============================================================================
-- AURA POLICE: SERVER JAIL & SENTENCING ENGINE
-- Autonomous 60s Ticker, Database Persistence, Anti-Combat-Log & Cell Teleport
-- ============================================================================

local JailedPlayers = {} -- [src] = { charId = 11, citizenid = 'HLWWIZKU', minutes = 15, reason = 'Robo a mano armada' }

--- Sentencia y encarcela a un jugador en Bolingbroke Penitentiary
--- @param targetSrc number ID de servidor del sospechoso
--- @param minutes number Tiempo de condena en minutos
--- @param reason string Motivo de los cargos
--- @param officerSrc number | nil ID del oficial actuante
--- @return boolean success, string message
local function JailPlayer(targetSrc, minutes, reason, officerSrc)
    targetSrc = tonumber(targetSrc)
    minutes = math.floor(tonumber(minutes) or 0)
    reason = tostring(reason or "Sentencia Policial LSPD")

    if not targetSrc or not GetPlayerName(tostring(targetSrc)) then
        return false, "El sospechoso no se encuentra conectado al servidor."
    end

    if minutes < (Config.Jail.minTime or 1) or minutes > (Config.Jail.maxTime or 120) then
        return false, string.format("El tiempo de condena debe situarse entre %d y %d minutos.", Config.Jail.minTime or 1, Config.Jail.maxTime or 120)
    end

    local charData = exports.aura_multichar:GetActiveCharacter(targetSrc)
    if not charData or not charData.id then
        return false, "No se pudo recuperar la ficha del personaje."
    end

    local officerName = "LSPD"
    if officerSrc and tonumber(officerSrc) then
        local offChar = exports.aura_multichar:GetActiveCharacter(officerSrc)
        officerName = offChar and string.format("%s %s", offChar.firstname or "", offChar.lastname or "") or GetPlayerName(officerSrc)
    end

    -- 1. Actualizar memoria RAM
    JailedPlayers[targetSrc] = {
        charId = charData.id,
        citizenid = charData.citizenid or tostring(charData.id),
        minutes = minutes,
        reason = reason
    }

    -- 2. Actualizar StateBag replicado
    Player(targetSrc).state:set('isJailed', true, true)
    Player(targetSrc).state:set('jailMinutes', minutes, true)

    -- 3. Persistencia en Base de Datos MySQL
    MySQL.update('UPDATE characters SET jail_time = ? WHERE id = ?', { minutes, charData.id })

    -- Marcar sentencias anteriores como completadas
    MySQL.update('UPDATE aura_police_jail SET status = ? WHERE citizenid = ? AND status = ?', {
        'completed',
        charData.citizenid or tostring(charData.id),
        'active'
    })

    -- Registrar nueva condena activa
    MySQL.insert([[
        INSERT INTO aura_police_jail (citizenid, character_id, jail_time, reason, officer_name, status)
        VALUES (?, ?, ?, ?, ?, 'active')
    ]], {
        charData.citizenid or tostring(charData.id),
        charData.id,
        minutes,
        reason,
        officerName
    })

    -- 4. Teletransporte forzado a la celda de Bolingbroke
    local cell = Config.Jail.cellCoords
    local targetPed = GetPlayerPed(targetSrc)
    SetEntityCoords(targetPed, cell.x, cell.y, cell.z, false, false, false, false)
    SetEntityHeading(targetPed, cell.w or 0.0)

    -- 5. Disparar cliente
    TriggerClientEvent('aura_police:client:onJailed', targetSrc, minutes, reason)

    TriggerClientEvent('ox_lib:notify', targetSrc, {
        title = 'Ingreso en Prisión',
        description = string.format("Has sido condenado a %d minutos en Bolingbroke Penitentiary.\nMotivo: %s", minutes, reason),
        type = 'error',
        duration = 10000
    })

    if officerSrc and officerSrc ~= targetSrc and GetPlayerName(tostring(officerSrc)) then
        TriggerClientEvent('ox_lib:notify', officerSrc, {
            title = 'Sentencia Ejecutada',
            description = string.format("El recluso ha sido trasladado a prisión por %d minutos.", minutes),
            type = 'success'
        })
    end

    return true, "SENTENCE_APPLIED"
end
exports('JailPlayer', JailPlayer)

--- Libera a un recluso de prisión
--- @param targetSrc number ID de servidor del jugador
local function UnjailPlayer(targetSrc)
    targetSrc = tonumber(targetSrc)
    if not targetSrc then return end

    local charData = exports.aura_multichar:GetActiveCharacter(targetSrc)
    local cid = charData and charData.id

    -- 1. Limpiar memoria RAM
    JailedPlayers[targetSrc] = nil

    -- 2. Limpiar StateBag
    Player(targetSrc).state:set('isJailed', false, true)
    Player(targetSrc).state:set('jailMinutes', 0, true)

    -- 3. Base de Datos
    if cid then
        MySQL.update('UPDATE characters SET jail_time = 0 WHERE id = ?', { cid })
        MySQL.update('UPDATE aura_police_jail SET status = ? WHERE character_id = ? AND status = ?', { 'completed', cid, 'active' })
    end

    -- 4. Teletransporte a las puertas exteriores de la prisión
    local release = Config.Jail.releaseCoords
    local targetPed = GetPlayerPed(targetSrc)
    if DoesEntityExist(targetPed) then
        SetEntityCoords(targetPed, release.x, release.y, release.z, false, false, false, false)
        SetEntityHeading(targetPed, release.w or 270.0)
    end

    -- 5. Notificación
    TriggerClientEvent('aura_police:client:onUnjailed', targetSrc)
    TriggerClientEvent('ox_lib:notify', targetSrc, {
        title = 'Condena Cumplida',
        description = 'Has cumplido la totalidad de tu condena penitenciaria. Eres libre.',
        type = 'success',
        duration = 8000
    })
end
exports('UnjailPlayer', UnjailPlayer)

--- Consulta el tiempo de cárcel de un jugador
--- @param src number
--- @return number Minutos restantes o 0
local function GetPlayerJailTime(src)
    src = tonumber(src)
    if not src then return 0 end
    if JailedPlayers[src] then
        return JailedPlayers[src].minutes or 0
    end
    return 0
end
exports('GetPlayerJailTime', GetPlayerJailTime)

-- ============================================================================
-- TICKER RECURRENTE DEL SERVIDOR (CADA 60 SEGUNDOS)
-- ============================================================================

CreateThread(function()
    while true do
        Wait(60 * 1000) -- 1 minuto exacto

        for src, jailData in pairs(JailedPlayers) do
            if GetPlayerName(tostring(src)) then
                jailData.minutes = jailData.minutes - 1
                Player(src).state:set('jailMinutes', jailData.minutes, true)

                if jailData.minutes <= 0 then
                    UnjailPlayer(src)
                else
                    -- Sincronizar en DB cada minuto
                    MySQL.update('UPDATE characters SET jail_time = ? WHERE id = ?', { jailData.minutes, jailData.charId })
                    MySQL.update('UPDATE aura_police_jail SET jail_time = ? WHERE character_id = ? AND status = ?', { jailData.minutes, jailData.charId, 'active' })
                end
            else
                JailedPlayers[src] = nil
            end
        end
    end
end)

-- ============================================================================
-- PERSISTENCIA Y PROTECCIÓN CONTRA EVASIÓN / COMBAT-LOG
-- ============================================================================

AddEventHandler('aura_economy:server:characterLoaded', function(arg1, arg2)
    local src = (type(arg1) == 'number' and type(arg2) == 'number') and arg1 or source
    local charId = (type(arg1) == 'number' and type(arg2) == 'number') and arg2 or arg1

    if not src or not charId then return end

    local row = MySQL.single.await('SELECT jail_time FROM characters WHERE id = ?', { charId })
    local remaining = row and tonumber(row.jail_time) or 0

    if remaining > 0 then
        Wait(1500) -- Esperar a que el cliente termine de spawnear
        JailPlayer(src, remaining, "Reanudación de Condena Pendiente tras Conexión", nil)
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    if JailedPlayers[src] then
        local data = JailedPlayers[src]
        MySQL.update('UPDATE characters SET jail_time = ? WHERE id = ?', { data.minutes, data.charId })
        JailedPlayers[src] = nil
    end
end)
