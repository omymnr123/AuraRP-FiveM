-- ============================================================================
-- AURA GANGS: SERVER GREENHOUSE CORE CONTROLLER (PROJECT GREENHOUSE)
-- Instanced MLO Dimension Isolation, Routing Buckets & Admin Engine
-- ============================================================================

local Greenhouses = {} -- [gangId] = { id, gang_id, coords = vec4(x,y,z,h) }

--- Obtener o calcular el Routing Bucket asignado a una banda
--- @param gangId string
--- @return number bucketId
function GetGangBucket(gangId)
    if not gangId then return 0 end
    if Config.Greenhouse.GangBuckets and Config.Greenhouse.GangBuckets[gangId] then
        return Config.Greenhouse.GangBuckets[gangId]
    end
    -- Algoritmo hash de fallback determinista (> 100)
    local hash = 0
    for i = 1, #gangId do
        hash = (hash * 31 + string.byte(gangId, i)) % 500
    end
    return 200 + hash
end
exports('GetGangBucket', GetGangBucket)

--- Cargar todos los invernaderos registrados desde la base de datos
local function LoadGreenhouses()
    local results = MySQL.query.await([[
        SELECT id, gang_id, exterior_x, exterior_y, exterior_z, exterior_h 
        FROM aura_greenhouses
    ]])

    Greenhouses = {}
    if results and #results > 0 then
        for _, row in ipairs(results) do
            Greenhouses[row.gang_id] = {
                id = row.id,
                gang_id = row.gang_id,
                coords = vec4(row.exterior_x, row.exterior_y, row.exterior_z, row.exterior_h or 0.0)
            }
        end
    end

    TriggerClientEvent('aura_gangs:client:syncGreenhouses', -1, Greenhouses)
    print(string.format('^2[AURA GANGS]^7 Sistema de Invernaderos cargado con éxito: ^3%d^7 recintos activos.', #results or 0))
end

-- Inicialización de tablas y carga al encender el recurso
CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `aura_greenhouses` (
          `id` INT(11) NOT NULL AUTO_INCREMENT,
          `gang_id` VARCHAR(50) NOT NULL,
          `exterior_x` DOUBLE NOT NULL,
          `exterior_y` DOUBLE NOT NULL,
          `exterior_z` DOUBLE NOT NULL,
          `exterior_h` FLOAT NOT NULL DEFAULT 0.0,
          `created_by` VARCHAR(100) DEFAULT 'Admin',
          `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
          `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP() ON UPDATE CURRENT_TIMESTAMP(),
          PRIMARY KEY (`id`),
          UNIQUE KEY `idx_greenhouse_gang` (`gang_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
    
    Wait(500)
    LoadGreenhouses()
end)

--- Sincronización cuando un jugador entra al servidor
RegisterNetEvent('aura_gangs:server:requestGreenhouses', function()
    local src = source
    TriggerClientEvent('aura_gangs:client:syncGreenhouses', src, Greenhouses)
end)

lib.callback.register('aura_gangs:server:fetchGreenhouses', function(source)
    return Greenhouses
end)

-- ============================================================================
-- 1. COMANDOS DE ADMINISTRACIÓN (/crearinvernadero & /borrarinvernadero)
-- ============================================================================

--- Crear o reubicar invernadero para una banda
RegisterCommand('crearinvernadero', function(source, args, rawCommand)
    local src = source
    if src ~= 0 and not IsPlayerAceAllowed(tostring(src), 'command.crearinvernadero') 
       and not IsPlayerAceAllowed(tostring(src), 'command.admin') 
       and not IsPlayerAceAllowed(tostring(src), 'group.admin') then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'ACCESO DENEGADO',
            description = 'No tienes privilegios administrativos para ejecutar este comando.',
            type = 'error'
        })
        return
    end

    local gangId = args[1]
    if not gangId or not Config.Gangs[gangId] then
        local validGangs = {}
        for k, _ in pairs(Config.Gangs) do table.insert(validGangs, k) end
        local msg = string.format('Sintaxis inválida: /crearinvernadero [gangId]\nBandas disponibles: %s', table.concat(validGangs, ', '))
        if src == 0 then print(msg) else
            TriggerClientEvent('ox_lib:notify', src, { title = 'SINTAXIS', description = msg, type = 'inform' })
        end
        return
    end

    if src == 0 then
        print('^1[ERROR]^7 Este comando debe ejecutarse desde el cliente de un administrador dentro del juego.')
        return
    end

    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    MySQL.query.await([[
        INSERT INTO aura_greenhouses (gang_id, exterior_x, exterior_y, exterior_z, exterior_h, created_by)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE 
            exterior_x = VALUES(exterior_x),
            exterior_y = VALUES(exterior_y),
            exterior_z = VALUES(exterior_z),
            exterior_h = VALUES(exterior_h),
            created_by = VALUES(created_by)
    ]], { gangId, coords.x, coords.y, coords.z, heading, GetPlayerName(src) })

    LoadGreenhouses()

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'INVERNADERO REGISTRADO',
        description = string.format('Entrada exterior establecida para %s en: (%.2f, %.2f, %.2f).', Config.Gangs[gangId].label, coords.x, coords.y, coords.z),
        type = 'success'
    })
end, false)

--- Eliminar un invernadero existente y sus cultivos asociados
RegisterCommand('borrarinvernadero', function(source, args, rawCommand)
    local src = source
    if src ~= 0 and not IsPlayerAceAllowed(tostring(src), 'command.borrarinvernadero') 
       and not IsPlayerAceAllowed(tostring(src), 'command.admin') 
       and not IsPlayerAceAllowed(tostring(src), 'group.admin') then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'ACCESO DENEGADO',
            description = 'No tienes permisos administrativos.',
            type = 'error'
        })
        return
    end

    local gangId = args[1]
    if not gangId then
        local msg = 'Sintaxis: /borrarinvernadero [gangId]'
        if src == 0 then print(msg) else
            TriggerClientEvent('ox_lib:notify', src, { title = 'SINTAXIS', description = msg, type = 'inform' })
        end
        return
    end

    -- Eliminar registro de invernadero y sus plantas
    MySQL.query.await('DELETE FROM aura_greenhouses WHERE gang_id = ?', { gangId })
    MySQL.query.await('DELETE FROM aura_plants WHERE gang_id = ?', { gangId })

    -- Forzar a cualquier jugador dentro de ese bucket a volver a la dimensión 0
    local bucketId = GetGangBucket(gangId)
    for _, pid in ipairs(GetPlayers()) do
        local pSrc = tonumber(pid)
        if pSrc and GetPlayerRoutingBucket(pSrc) == bucketId then
            SetPlayerRoutingBucket(pSrc, 0)
            Player(pSrc).state:set('greenhouse_bucket', 0, true)
            Player(pSrc).state:set('in_greenhouse_gang', nil, true)
            local defaultExit = vec3(1066.37, -3183.47, -39.16)
            SetEntityCoords(GetPlayerPed(pSrc), defaultExit.x, defaultExit.y, defaultExit.z, false, false, false, false)
        end
    end

    -- Recargar y sincronizar
    LoadGreenhouses()
    TriggerEvent('aura_gangs:server:onGreenhouseDeleted', gangId)

    local successMsg = string.format('Invernadero de la organización "%s" y todos sus cultivos han sido eliminados de la base de datos.', gangId)
    if src == 0 then print(successMsg) else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'INVERNADERO ELIMINADO',
            description = successMsg,
            type = 'inform'
        })
    end
end, false)

-- ============================================================================
-- 2. TELETRANSPORTE E INSTANCIACIÓN (ROUTING BUCKETS)
-- ============================================================================

--- Comprobar si un jugador está dentro del MLO interior y restaurar su dimensión instanciada
--- @param src number
function CheckAndRestorePlayerInterior(src)
    if not src then return end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end

    local coords = GetEntityCoords(ped)
    local interiorCenter = Config.Greenhouse.Interior.plantingCenter or vec3(1051.49, -3196.53, -39.14)
    local dist = #(coords - interiorCenter)

    -- Si el jugador está dentro de la zona del interior del invernadero
    if dist <= (Config.Greenhouse.Interior.plantingRadius or 45.0) or (coords.z < -30.0 and coords.x > 1020.0 and coords.x < 1080.0 and coords.y < -3160.0 and coords.y > -3220.0) then
        local pState = Player(src).state
        local gangId = pState.job

        -- Si la banda del jugador es válida en Config.Gangs
        if gangId and Config.Gangs[gangId] then
            local bucketId = GetGangBucket(gangId)
            SetPlayerRoutingBucket(src, bucketId)
            pState:set('greenhouse_bucket', bucketId, true)
            pState:set('in_greenhouse_gang', gangId, true)

            -- Sincronizar plantas de su banda
            TriggerEvent('aura_gangs:server:syncPlantsToPlayer', src, gangId)
            TriggerClientEvent('aura_gangs:client:interiorRestored', src, gangId, bucketId)

            print(string.format('^2[AURA GANGS]^7 Jugador %s (%d) reconectado dentro del Invernadero de "%s". Restaurado a Bucket %d y sincronizado.^7', GetPlayerName(src) or tostring(src), src, gangId, bucketId))
        else
            -- Si es administrador
            local isAdmin = IsPlayerAceAllowed(tostring(src), 'group.admin') or IsPlayerAceAllowed(tostring(src), 'command')
            if isAdmin then
                pState:set('greenhouse_bucket', 0, true)
                pState:set('in_greenhouse_gang', 'admin', true)
                TriggerClientEvent('aura_gangs:client:interiorRestored', src, 'admin', 0)
            else
                -- Si no pertenece a ninguna banda, salir de forma segura al exterior
                local defaultExit = vec4(1066.37, -3183.47, -39.16, 0.0)
                SetPlayerRoutingBucket(src, 0)
                pState:set('greenhouse_bucket', 0, true)
                pState:set('in_greenhouse_gang', nil, true)
                SetEntityCoords(ped, defaultExit.x, defaultExit.y, defaultExit.z, false, false, false, false)
            end
        end
    end
end
exports('CheckAndRestorePlayerInterior', CheckAndRestorePlayerInterior)

--- Callback para solicitar entrada al Invernadero Clandestino
lib.callback.register('aura_gangs:server:enterGreenhouse', function(source, gangId)
    local src = source
    if not src or not gangId then return false, "Parámetros inválidos." end

    local gh = Greenhouses[gangId]
    if not gh then
        return false, "No existe un invernadero configurado para esta organización."
    end

    local pState = Player(src).state
    local charJob = pState.job or "unemployed"

    -- Verificar si pertenece a la banda o es admin
    local isAdmin = IsPlayerAceAllowed(tostring(src), 'group.admin') or IsPlayerAceAllowed(tostring(src), 'command')
    if charJob ~= gangId and not isAdmin then
        return false, "La puerta está blindada con cerradura electrónica de la organización."
    end

    local bucketId = GetGangBucket(gangId)
    local interior = Config.Greenhouse.Interior

    -- Aislar en la dimensión privada FiveM
    SetPlayerRoutingBucket(src, bucketId)
    pState:set('greenhouse_bucket', bucketId, true)
    pState:set('in_greenhouse_gang', gangId, true)

    -- Sincronizar plantas del bucket al jugador que ingresa
    TriggerEvent('aura_gangs:server:syncPlantsToPlayer', src, gangId)

    return true, interior.spawnCoords
end)

--- Callback para salir del Invernadero al exterior
lib.callback.register('aura_gangs:server:exitGreenhouse', function(source)
    local src = source
    if not src then return false end

    local pState = Player(src).state
    local gangId = pState.in_greenhouse_gang or pState.job
    local exitCoords = nil

    if gangId and Greenhouses[gangId] then
        exitCoords = Greenhouses[gangId].coords
    else
        -- Buscar el primer invernadero disponible o coordenadas exteriores por defecto
        for _, gh in pairs(Greenhouses) do
            if gh and gh.coords then
                exitCoords = gh.coords
                break
            end
        end
        if not exitCoords then
            exitCoords = vec4(1066.37, -3183.47, -39.16, 0.0)
        end
    end

    -- Restaurar a la dimensión pública 0
    SetPlayerRoutingBucket(src, 0)
    pState:set('greenhouse_bucket', 0, true)
    pState:set('in_greenhouse_gang', nil, true)

    return true, exitCoords
end)

--- Eventos de carga y conexión de personajes
RegisterNetEvent('aura_gangs:server:checkPlayerInteriorState', function()
    local src = source
    CheckAndRestorePlayerInterior(src)
end)

RegisterNetEvent('aura_multichar:server:characterLoaded', function(charId, explicitSrc)
    local src = (source and source ~= 0 and source ~= '') and source or explicitSrc
    if not src then return end
    SetTimeout(1000, function()
        CheckAndRestorePlayerInterior(src)
    end)
end)

AddEventHandler('aura_economy:server:characterLoaded', function(arg1, arg2, arg3)
    local src = (type(arg1) == 'number') and arg1 or source
    SetTimeout(1000, function()
        CheckAndRestorePlayerInterior(src)
    end)
end)

-- Comprobación periódica / al arrancar el script para restaurar jugadores ya conectados
CreateThread(function()
    Wait(1500)
    for _, pid in ipairs(GetPlayers()) do
        local pSrc = tonumber(pid)
        if pSrc then
            CheckAndRestorePlayerInterior(pSrc)
        end
    end
end)

-- Función exportada para obtener invernaderos activos
exports('GetGreenhouses', function()
    return Greenhouses
end)
