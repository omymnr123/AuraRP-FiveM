-- ============================================================================
-- AURA JOBS: SERVER DOORLOCK CONTROLLER (DATABASE & IN-GAME ADMIN SYSTEM)
-- ============================================================================

local DynamicDoors = {} -- [doorId] = { job = 'vazou', coords = vector3(...), distance = 2.5, locked = true }

local function parseVector3(coords, y, z)
    if type(coords) == 'vector3' then
        return coords
    elseif type(coords) == 'table' then
        local cx = tonumber(coords.x or coords[1]) or 0.0
        local cy = tonumber(coords.y or coords[2]) or 0.0
        local cz = tonumber(coords.z or coords[3]) or 0.0
        return vector3(cx, cy, cz)
    else
        local cx = tonumber(coords) or 0.0
        local cy = tonumber(y) or 0.0
        local cz = tonumber(z) or 0.0
        return vector3(cx, cy, cz)
    end
end

local function InitDoors()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `aura_doors` (
            `door_id` VARCHAR(50) PRIMARY KEY,
            `job` VARCHAR(50) NOT NULL DEFAULT '',
            `coords_x` DOUBLE NOT NULL DEFAULT 0,
            `coords_y` DOUBLE NOT NULL DEFAULT 0,
            `coords_z` DOUBLE NOT NULL DEFAULT 0,
            `is_locked` TINYINT(1) NOT NULL DEFAULT 1,
            `distance` FLOAT NOT NULL DEFAULT 2.5
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function()
        -- Auto-migración en caliente: asegurar que todas las columnas existan si la tabla ya existía
        MySQL.query([[
            ALTER TABLE `aura_doors`
                ADD COLUMN IF NOT EXISTS `job` VARCHAR(50) NOT NULL DEFAULT '',
                ADD COLUMN IF NOT EXISTS `coords_x` DOUBLE NOT NULL DEFAULT 0,
                ADD COLUMN IF NOT EXISTS `coords_y` DOUBLE NOT NULL DEFAULT 0,
                ADD COLUMN IF NOT EXISTS `coords_z` DOUBLE NOT NULL DEFAULT 0,
                ADD COLUMN IF NOT EXISTS `distance` FLOAT NOT NULL DEFAULT 2.5;
        ]], {}, function()
            -- 1. Cargar puertas existentes en Base de Datos
            MySQL.query('SELECT * FROM aura_doors', {}, function(results)
                DynamicDoors = {}
                if results then
                    for i = 1, #results do
                        local row = results[i]
                        local c = parseVector3(row.coords_x, row.coords_y, row.coords_z)
                        
                        -- Si la fila en DB proviene de un esquema antiguo sin coordenadas o job, recuperar de Config.Doors
                        if (not row.job or row.job == '') and Config.Doors and Config.Doors[row.door_id] then
                            local cfgDoor = Config.Doors[row.door_id]
                            local cfgCoords = parseVector3(cfgDoor.coords)
                            row.job = cfgDoor.job
                            c = cfgCoords
                            row.distance = cfgDoor.distance or 2.5

                            MySQL.update('UPDATE aura_doors SET job = ?, coords_x = ?, coords_y = ?, coords_z = ?, distance = ? WHERE door_id = ?', {
                                cfgDoor.job,
                                cfgCoords.x,
                                cfgCoords.y,
                                cfgCoords.z,
                                cfgDoor.distance or 2.5,
                                row.door_id
                            })
                        end

                        if row.job and row.job ~= '' then
                            DynamicDoors[row.door_id] = {
                                job = row.job,
                                coords = c,
                                distance = tonumber(row.distance) or 2.5,
                                locked = row.is_locked == 1
                            }
                            GlobalState['doorlock_' .. row.door_id] = (row.is_locked == 1)
                        end
                    end
                end

                -- 2. Migrar/Añadir las puertas estáticas de Config.Doors si no existen en DB
                if Config.Doors then
                    for doorId, doorData in pairs(Config.Doors) do
                        if not DynamicDoors[doorId] then
                            local c = parseVector3(doorData.coords)
                            DynamicDoors[doorId] = {
                                job = doorData.job,
                                coords = c,
                                distance = tonumber(doorData.distance) or 2.5,
                                locked = doorData.locked ~= false
                            }
                            GlobalState['doorlock_' .. doorId] = (doorData.locked ~= false)
                            
                            MySQL.insert('INSERT INTO aura_doors (door_id, job, coords_x, coords_y, coords_z, is_locked, distance) VALUES (?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE job = VALUES(job), coords_x = VALUES(coords_x), coords_y = VALUES(coords_y), coords_z = VALUES(coords_z), distance = VALUES(distance)', {
                                doorId,
                                doorData.job,
                                c.x,
                                c.y,
                                c.z,
                                doorData.locked and 1 or 0,
                                doorData.distance or 2.5
                            })
                        end
                    end
                end

                GlobalState['dynamic_doors'] = DynamicDoors
                TriggerClientEvent('aura_jobs:client:syncDoors', -1, DynamicDoors)

                if Config.Debug then
                    print(string.format("[Aura Jobs] Sistema de Puertas inicializado con %d cerraduras activas.", GetTableSize(DynamicDoors)))
                end
            end)
        end)
    end)
end

function GetTableSize(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

CreateThread(function()
    Wait(500)
    InitDoors()
end)

-- Sincronizar puertas al conectar un nuevo cliente
RegisterNetEvent('aura_jobs:server:requestDoors', function()
    local src = source
    TriggerClientEvent('aura_jobs:client:syncDoors', src, DynamicDoors)
end)

-- Bloquear / Desbloquear puerta (Jugadores y Jefes)
RegisterNetEvent('aura_jobs:server:toggleDoorlock', function(doorId)
    local src = source
    local pState = Player(src).state
    local pJob = pState.job
    
    if not pJob then return end
    
    local doorConfig = DynamicDoors[doorId] or (Config.Doors and Config.Doors[doorId])
    if not doorConfig then return end
    
    -- Verificar si el trabajo del jugador coincide con la cerradura
    if pJob ~= doorConfig.job then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'No tienes las llaves de esta puerta' })
        return
    end
    
    -- Invertir el estado
    local currentState = GlobalState['doorlock_' .. doorId]
    local newState = not currentState
    
    GlobalState['doorlock_' .. doorId] = newState
    if DynamicDoors[doorId] then
        DynamicDoors[doorId].locked = newState
    end
    
    MySQL.update('UPDATE aura_doors SET is_locked = ? WHERE door_id = ?', { newState and 1 or 0, doorId })
    
    TriggerClientEvent('ox_lib:notify', src, { 
        title = 'Cerradura',
        type = 'success', 
        description = newState and 'Puerta bloqueada' or 'Puerta desbloqueada' 
    })
end)

-- ============================================================================
-- COMANDOS ADMINISTRATIVOS EN JUEGO
-- ============================================================================

-- /lockdoor [negocio] [numero/id] -> Crea/Registra una puerta en las coordenadas actuales
RegisterCommand('lockdoor', function(source, args)
    if source ~= 0 and not IsPlayerAceAllowed(tostring(source), 'command.lockdoor') and not IsPlayerAceAllowed(tostring(source), 'group.admin') then
        if source ~= 0 then
            TriggerClientEvent('ox_lib:notify', source, { title = 'Acceso Denegado', description = 'No tienes permisos de administrador.', type = 'error' })
        end
        return
    end

    local jobName = args[1]
    local doorNum = args[2]

    if not jobName or not doorNum then
        local msg = "Uso: /lockdoor [nombre_negocio] [numero_puerta] (Ejemplo: /lockdoor vazou 1)"
        if source == 0 then print(msg) else TriggerClientEvent('ox_lib:notify', source, { title = 'Sintaxis', description = msg, type = 'inform' }) end
        return
    end

    if source == 0 then
        print("[Aura Jobs] Este comando debe ejecutarse dentro del juego frente a la puerta.")
        return
    end

    -- Validar que el negocio exista en Config.Jobs
    if not Config.Jobs[jobName] then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Error', description = string.format("El negocio '%s' no existe en Config.Jobs.", jobName), type = 'error' })
        return
    end

    local ped = GetPlayerPed(source)
    local pCoords = GetEntityCoords(ped)
    local doorId = string.format("%s_%s", jobName, tostring(doorNum))

    -- Guardar o actualizar en Base de Datos
    MySQL.query([[
        INSERT INTO aura_doors (door_id, job, coords_x, coords_y, coords_z, is_locked, distance)
        VALUES (?, ?, ?, ?, ?, 1, 2.5)
        ON DUPLICATE KEY UPDATE 
            job = VALUES(job),
            coords_x = VALUES(coords_x),
            coords_y = VALUES(coords_y),
            coords_z = VALUES(coords_z),
            is_locked = 1;
    ]], { doorId, jobName, pCoords.x, pCoords.y, pCoords.z }, function(res)
        
        -- Actualizar memoria del servidor y GlobalState
        DynamicDoors[doorId] = {
            job = jobName,
            coords = pCoords,
            distance = 2.5,
            locked = true
        }
        GlobalState['doorlock_' .. doorId] = true
        GlobalState['dynamic_doors'] = DynamicDoors

        -- Sincronizar en tiempo real con todos los jugadores
        TriggerClientEvent('aura_jobs:client:syncDoors', -1, DynamicDoors)

        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Puerta Registrada',
            description = string.format("Bloqueo '%s' creado con éxito para el negocio %s.", doorId, Config.Jobs[jobName].label or jobName),
            type = 'success'
        })

        print(string.format("[Aura Jobs] Admin #%d ha registrado la cerradura '%s' en [%.2f, %.2f, %.2f] para '%s'.", source, doorId, pCoords.x, pCoords.y, pCoords.z, jobName))
    end)
end, false)

-- /deletedoor [negocio] [numero/id] -> Elimina una cerradura de la base de datos y del juego
RegisterCommand('deletedoor', function(source, args)
    if source ~= 0 and not IsPlayerAceAllowed(tostring(source), 'command.deletedoor') and not IsPlayerAceAllowed(tostring(source), 'group.admin') then
        if source ~= 0 then
            TriggerClientEvent('ox_lib:notify', source, { title = 'Acceso Denegado', description = 'No tienes permisos de administrador.', type = 'error' })
        end
        return
    end

    local jobName = args[1]
    local doorNum = args[2]

    if not jobName or not doorNum then
        local msg = "Uso: /deletedoor [nombre_negocio] [numero_puerta] (Ejemplo: /deletedoor vazou 1)"
        if source == 0 then print(msg) else TriggerClientEvent('ox_lib:notify', source, { title = 'Sintaxis', description = msg, type = 'inform' }) end
        return
    end

    local doorId = string.format("%s_%s", jobName, tostring(doorNum))

    MySQL.query('DELETE FROM aura_doors WHERE door_id = ?', { doorId }, function(res)
        DynamicDoors[doorId] = nil
        GlobalState['doorlock_' .. doorId] = nil
        GlobalState['dynamic_doors'] = DynamicDoors

        TriggerClientEvent('aura_jobs:client:syncDoors', -1, DynamicDoors)

        local msg = string.format("Cerradura '%s' eliminada de la base de datos y del servidor.", doorId)
        if source == 0 then print(msg) else TriggerClientEvent('ox_lib:notify', source, { title = 'Eliminada', description = msg, type = 'inform' }) end
    end)
end, false)

-- /puertas o /verpuertas -> Lista todas las puertas registradas
RegisterCommand('verpuertas', function(source)
    if source ~= 0 and not IsPlayerAceAllowed(tostring(source), 'group.admin') then return end

    local count = 0
    print("--- [AURA JOBS] LISTA DE PUERTAS REGISTRADAS ---")
    for dId, dData in pairs(DynamicDoors) do
        count = count + 1
        local info = string.format("#%d: ID '%s' | Negocio: %s | Coords: vec3(%.2f, %.2f, %.2f) | Estado: %s", 
            count, dId, dData.job, dData.coords.x, dData.coords.y, dData.coords.z, dData.locked and "CERRADA" or "ABIERTA")
        if source == 0 then print(info) else TriggerClientEvent('chat:addMessage', source, { args = { '^5[Aura Puertas]^0', info } }) end
    end
    if count == 0 then
        local emptyMsg = "No hay puertas registradas en la base de datos."
        if source == 0 then print(emptyMsg) else TriggerClientEvent('ox_lib:notify', source, { description = emptyMsg, type = 'inform' }) end
    end
end, false)
