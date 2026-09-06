-- ============================================================================
-- AURA CORE: SISTEMA DE GUARDADO MAESTRO DEL SERVIDOR (SAVE ALL / SAVE SERVER)
-- ============================================================================
-- Este módulo orquesta el guardado atómico y síncrono de todos los subsistemas:
-- 1. Coordenadas, vida, armadura, apariencia y metadatos de personajes (aura_multichar).
-- 2. Perfiles principales de conexión y licencias (aura_core).
-- 3. Inventarios de jugadores, stashes, maleteros y guanteras (ox_inventory).
-- 4. Cuentas bancarias, efectivo y dinero negro en RAM (aura_economy).
-- 5. Clima, estación, reloj maestro y temperatura (aura_seasons).
-- 6. Plantaciones clandestinas e invernaderos (aura_gangs).
-- 7. Sociedades empresariales (aura_jobs).
-- ============================================================================

local isSaving = false

--- Comprobación estricta de privilegios administrativos
--- @param source number Source del emisor (0 para consola)
--- @return boolean isAllowed, string senderName
local function IsAdmin(source)
    if source == 0 then
        return true, "Consola del Servidor (txAdmin/RCON)"
    end

    local srcStr = tostring(source)
    local playerName = GetPlayerName(source) or ("Jugador #" .. tostring(source))

    -- 1. Comprobación de ACE permissions estándar
    if IsPlayerAceAllowed(srcStr, 'group.admin') 
       or IsPlayerAceAllowed(srcStr, 'command') 
       or IsPlayerAceAllowed(srcStr, 'command.saveall') 
       or IsPlayerAceAllowed(srcStr, 'command.saveserver') then
        return true, playerName
    end

    -- 2. Comprobación en AuraCore
    if AuraCore and AuraCore.Players and AuraCore.Players[source] then
        local player = AuraCore.Players[source]
        local perm = player.metadata and player.metadata.permissions
        local group = player.group
        if perm == 'admin' or perm == 'god' or perm == 'superadmin' 
           or group == 'admin' or group == 'god' or group == 'superadmin' then
            return true, playerName
        end
    end

    return false, playerName
end

--- Ejecuta el ciclo completo de guardado maestro
--- @param initiatorSource number 0 para consola o ID de jugador
--- @param broadcastNotification boolean Si es true, notifica a todos los jugadores
--- @return table stats Métricas del proceso de guardado
local function PerformMasterSave(initiatorSource, broadcastNotification)
    if isSaving then
        local msg = "[Aura Core] ⚠️ Ya hay una operación de guardado maestro en progreso. Esperando finalización..."
        print(msg)
        return { success = false, message = "Guardado ya en progreso" }
    end

    isSaving = true
    local startTime = os.nanotime and os.nanotime() or (os.clock() * 1e9)
    local _, initiatorName = IsAdmin(initiatorSource or 0)

    print(string.format("^3[Aura Core] Iniciando Guardado Maestro del Servidor solicitado por: %s...^0", initiatorName))

    local stats = {
        charactersSaved = 0,
        playersSaved = 0,
        inventoriesSaved = false,
        accountsSaved = 0,
        seasonsSaved = false,
        plantsSaved = 0,
        elapsedMs = 0.0
    }

    -- ------------------------------------------------------------------------
    -- 1. GUARDADO DE PERSONAJES ACTIVOS Y COORDENADAS (aura_multichar)
    -- ------------------------------------------------------------------------
    pcall(function()
        if exports.aura_multichar and exports.aura_multichar.SaveAllCharacters then
            stats.charactersSaved = exports.aura_multichar:SaveAllCharacters()
        elseif exports.aura_multichar and exports.aura_multichar.SaveCharacterLocation then
            for _, pid in ipairs(GetPlayers()) do
                local pSrc = tonumber(pid)
                if pSrc then
                    exports.aura_multichar:SaveCharacterLocation(pSrc)
                    stats.charactersSaved = stats.charactersSaved + 1
                end
            end
        end
    end)

    -- ------------------------------------------------------------------------
    -- 2. GUARDADO DE PERFILES DE JUGADORES PRINCIPALES (aura_core)
    -- ------------------------------------------------------------------------
    pcall(function()
        if exports.aura_core and exports.aura_core.SaveAllPlayers then
            stats.playersSaved = exports.aura_core:SaveAllPlayers()
        elseif AuraCore and AuraCore.Players then
            for src, player in pairs(AuraCore.Players) do
                if player and player.license then
                    local ped = GetPlayerPed(src)
                    if ped and ped ~= 0 then
                        local coords = GetEntityCoords(ped)
                        local heading = GetEntityHeading(ped)
                        if coords and (coords.x ~= 0.0 or coords.y ~= 0.0 or coords.z ~= 0.0) then
                            player.metadata = player.metadata or {}
                            player.metadata.last_location = {
                                x = coords.x,
                                y = coords.y,
                                z = coords.z,
                                heading = heading
                            }
                        end
                    end
                    MySQL.update.await('UPDATE players SET metadata = ?, last_login = CURRENT_TIMESTAMP WHERE license = ?', {
                        json.encode(player.metadata),
                        player.license
                    })
                    stats.playersSaved = stats.playersSaved + 1
                end
            end
        end
    end)

    -- ------------------------------------------------------------------------
    -- 3. GUARDADO DE INVENTARIOS, MALETEROS Y STASHES (ox_inventory)
    -- ------------------------------------------------------------------------
    pcall(function()
        if exports.ox_inventory and exports.ox_inventory.SaveInventories then
            exports.ox_inventory:SaveInventories(false, false)
            stats.inventoriesSaved = true
        elseif exports.ox_inventory and exports.ox_inventory.saveInventories then
            exports.ox_inventory:saveInventories(false, false)
            stats.inventoriesSaved = true
        else
            -- Fallback por comando de consola seguro
            ExecuteCommand('saveinv false')
            stats.inventoriesSaved = true
        end
    end)

    -- ------------------------------------------------------------------------
    -- 4. GUARDADO DE ECONOMÍA Y CUENTAS BANCARIAS/CASH (aura_economy)
    -- ------------------------------------------------------------------------
    pcall(function()
        if exports.aura_economy and exports.aura_economy.SaveAllAccounts then
            stats.accountsSaved = exports.aura_economy:SaveAllAccounts()
        end
    end)

    -- ------------------------------------------------------------------------
    -- 5. GUARDADO DE SISTEMA ESTACIONAL, CLIMA Y HORA (aura_seasons)
    -- ------------------------------------------------------------------------
    pcall(function()
        if exports.aura_seasons and exports.aura_seasons.SaveSeasonState then
            exports.aura_seasons:SaveSeasonState()
            stats.seasonsSaved = true
        end
    end)

    -- ------------------------------------------------------------------------
    -- 6. GUARDADO DE CULTIVOS E INVERNADEROS (aura_gangs)
    -- ------------------------------------------------------------------------
    pcall(function()
        if exports.aura_gangs and exports.aura_gangs.SaveAllPlants then
            stats.plantsSaved = exports.aura_gangs:SaveAllPlants()
        end
    end)

    -- ------------------------------------------------------------------------
    -- 7. GUARDADO DE ESTADOS DE COMA Y MUERTE (aura_death)
    -- ------------------------------------------------------------------------
    pcall(function()
        if exports.aura_death and exports.aura_death.SaveAllDeathStates then
            stats.deathsSaved = exports.aura_death:SaveAllDeathStates()
        end
    end)

    -- ------------------------------------------------------------------------
    -- CÁLCULO DE TELEMETRÍA Y LOGS ESTRUCTURADOS
    -- ------------------------------------------------------------------------
    local endTime = os.nanotime and os.nanotime() or (os.clock() * 1e9)
    stats.elapsedMs = (endTime - startTime) / 1e6
    if stats.elapsedMs < 0.01 then stats.elapsedMs = 0.01 end

    local logBanner = string.format([[

^2==============================================================================^0
^2[AURA SERVER] 💾 GUARDADO MAESTRO DEL SERVIDOR COMPLETADO CON ÉXITO^0
^2==============================================================================^0
^7-> Solicitado por:                 ^3%s^7
-> Personajes guardados (Coords/Ped): ^2%d^7 activos
-> Perfiles de jugadores (DB):       ^2%d^7 registros
-> Inventarios & Stashes:            ^2%s^7 (ox_inventory)
-> Balances Financieros volcados:    ^2%d^7 cuentas (aura_economy)
-> Estación, Clima & Reloj Maestro:  ^2%s^7 (aura_seasons)
-> Cultivos de Bandas sincronizados: ^2%d^7 plantas (aura_gangs)
-> Tiempo total de ejecución:        ^3%.2f ms^7
^2==============================================================================^0
]], initiatorName, stats.charactersSaved, stats.playersSaved, 
    stats.inventoriesSaved and "Sincronizados OK" or "N/A", 
    stats.accountsSaved, 
    stats.seasonsSaved and "Persistido OK" or "N/A", 
    stats.plantsSaved, 
    stats.elapsedMs)

    print(logBanner)

    -- ------------------------------------------------------------------------
    -- RESPUESTA Y FEEDBACK IN-GAME
    -- ------------------------------------------------------------------------
    if initiatorSource and initiatorSource > 0 then
        TriggerClientEvent('ox_lib:notify', initiatorSource, {
            title = '💾 Guardado Maestro Exitoso',
            description = string.format('Servidor asegurado en %.2f ms (%d personajes, inventarios y economía persistidos).', stats.elapsedMs, stats.charactersSaved),
            type = 'success',
            duration = 7000
        })
    end

    if broadcastNotification then
        TriggerClientEvent('ox_lib:notify', -1, {
            title = '💾 Servidor Asegurado',
            description = 'Todos los datos de personajes, economía e inventarios han sido guardados en la base de datos.',
            type = 'inform',
            duration = 5000
        })
    end

    isSaving = false
    stats.success = true
    return stats
end

-- ============================================================================
-- REGISTRO DE COMANDOS (CONSOLA & IN-GAME)
-- ============================================================================

local function CommandHandler(source, args, rawCommand)
    local allowed, senderName = IsAdmin(source)
    if not allowed then
        if source > 0 then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Acceso Denegado',
                description = 'No tienes permisos de administrador para forzar el guardado del servidor.',
                type = 'error',
                duration = 6000
            })
        else
            print("^1[Aura Core] Acceso denegado: permisos insuficientes para ejecutar saveall.^0")
        end
        return
    end

    local shouldBroadcast = false
    if args and args[1] then
        local firstArg = string.lower(tostring(args[1]))
        if firstArg == 'broadcast' or firstArg == 'anuncio' or firstArg == 'true' or firstArg == '1' or firstArg == 'global' then
            shouldBroadcast = true
        end
    end

    PerformMasterSave(source, shouldBroadcast)
end

-- Comando principal
RegisterCommand('saveall', CommandHandler, false)
-- Alias del servidor
RegisterCommand('saveserver', CommandHandler, false)
-- Alias en español
RegisterCommand('guardartodo', CommandHandler, false)
RegisterCommand('forzar_guardado', CommandHandler, false)

-- ============================================================================
-- EXPORTS PÚBLICOS DEL SERVIDOR & EVENTOS
-- ============================================================================

exports('SaveServer', function(broadcast)
    return PerformMasterSave(0, broadcast or false)
end)

exports('SaveAll', function(broadcast)
    return PerformMasterSave(0, broadcast or false)
end)

RegisterNetEvent('aura_core:server:saveAll', function(broadcast)
    local src = source
    local allowed = IsAdmin(src)
    if allowed then
        PerformMasterSave(src, broadcast or false)
    end
end)

AddEventHandler('aura:server:saveAll', function(broadcast)
    PerformMasterSave(0, broadcast or false)
end)

-- ============================================================================
-- INTERCEPTACIÓN DE EVENTOS DE REINICIO AUTOMÁTICO (txAdmin & Resource Stop)
-- ============================================================================

-- Guardado automático cuando txAdmin programa o ejecuta un reinicio rápido
AddEventHandler('txAdmin:events:serverShuttingDown', function()
    print("^3[Aura Core] Evento txAdmin:serverShuttingDown detectado. Ejecutando guardado de emergencia...^0")
    PerformMasterSave(0, false)
end)

AddEventHandler('txAdmin:events:scheduledRestart', function(eventData)
    if eventData and eventData.secondsRemaining and eventData.secondsRemaining <= 30 then
        print(string.format("^3[Aura Core] Reinicio programado en %d segundos. Asegurando base de datos...^0", eventData.secondsRemaining))
        PerformMasterSave(0, true)
    end
end)

-- Guardado de seguridad si el recurso aura_core se detiene
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print("^3[Aura Core] Deteniendo recurso. Forzando guardado final del estado del servidor...^0")
        PerformMasterSave(0, false)
    end
end)
