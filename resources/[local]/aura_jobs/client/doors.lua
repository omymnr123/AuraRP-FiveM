-- ============================================================================
-- AURA JOBS: CLIENT DOORLOCK CONTROLLER (DATABASE & REAL-TIME DYNAMIC SYNC)
-- ============================================================================

local ActiveDoors = {} -- [doorId] = { job = 'vazou', coords = vector3(...), distance = 2.5, locked = true, foundEntities = {} }
local currentClosestDoor = nil
local registeredInSystem = {} -- [doorSystemId] = true

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

-- Sincronizar tabla de puertas recibida desde el servidor
local function UpdateActiveDoors(doorsTable)
    if not doorsTable then return end
    for doorId, doorData in pairs(doorsTable) do
        local c = parseVector3(doorData.coords)
        if not ActiveDoors[doorId] then
            ActiveDoors[doorId] = {
                job = doorData.job,
                coords = c,
                distance = tonumber(doorData.distance) or 2.5,
                locked = doorData.locked ~= false,
                foundEntities = {}
            }
        else
            ActiveDoors[doorId].job = doorData.job
            ActiveDoors[doorId].coords = c
            ActiveDoors[doorId].distance = tonumber(doorData.distance) or 2.5
            ActiveDoors[doorId].locked = doorData.locked ~= false
        end
    end

    -- Limpiar puertas eliminadas
    for doorId in pairs(ActiveDoors) do
        if not doorsTable[doorId] and (not Config.Doors or not Config.Doors[doorId]) then
            ActiveDoors[doorId] = nil
        end
    end
end

RegisterNetEvent('aura_jobs:client:syncDoors', function(serverDoors)
    UpdateActiveDoors(serverDoors)
end)

local function InitDoors()
    -- Cargar Config.Doors estáticas inicialmente
    if Config.Doors then
        UpdateActiveDoors(Config.Doors)
    end

    -- Solicitar puertas dinámicas de la base de datos al servidor
    TriggerServerEvent('aura_jobs:server:requestDoors')

    CreateThread(function()
        while true do
            local wait = 500
            local plyCoords = GetEntityCoords(cache.ped)
            local closestDist = 12.0
            local closestDoor = nil

            for doorId, doorData in pairs(ActiveDoors) do
                local dist = #(plyCoords - doorData.coords)
                if dist < closestDist then
                    closestDist = dist
                    closestDoor = doorId
                end
            end

            if closestDoor and closestDist < 8.0 then
                wait = 0
                local doorData = ActiveDoors[closestDoor]
                local isLocked = GlobalState['doorlock_' .. closestDoor] == true

                -- Escanear y vincular objetos de puerta cercanos (Soporte automático para puertas simples y dobles)
                if not doorData.foundEntities or #doorData.foundEntities == 0 then
                    doorData.foundEntities = {}
                    local objects = GetGamePool('CObject')
                    for i = 1, #objects do
                        local obj = objects[i]
                        local objCoords = GetEntityCoords(obj)
                        local distToCenter = #(objCoords - doorData.coords)
                        
                        -- Capturar todas las hojas de puerta en un radio de 3.5m del centro
                        if distToCenter <= 3.5 and math.abs(objCoords.z - doorData.coords.z) < 2.5 then
                            table.insert(doorData.foundEntities, obj)
                            
                            local hash = GetEntityModel(obj)
                            local subDoorId = joaat(closestDoor .. '_' .. #doorData.foundEntities)
                            if not registeredInSystem[subDoorId] then
                                AddDoorToSystem(subDoorId, hash, objCoords.x, objCoords.y, objCoords.z, false, false, false)
                                DoorSystemSetAutomaticDistance(subDoorId, 0.0, false, false)
                                registeredInSystem[subDoorId] = true
                            end
                        end
                    end
                end

                -- Aplicar bloqueo físico a todas las hojas detectadas
                if doorData.foundEntities and #doorData.foundEntities > 0 then
                    for idx, obj in ipairs(doorData.foundEntities) do
                        if DoesEntityExist(obj) then
                            local subDoorId = joaat(closestDoor .. '_' .. idx)
                            if isLocked then
                                DoorSystemSetDoorState(subDoorId, 4, false, false)
                                DoorSystemSetOpenRatio(subDoorId, 0.0, false, false)
                                FreezeEntityPosition(obj, true)
                                SetEntityCanBeDamaged(obj, false)
                            else
                                DoorSystemSetDoorState(subDoorId, 0, false, false)
                                FreezeEntityPosition(obj, false)
                            end
                        end
                    end
                end

                -- Renderizado de interfaz 3D-flotante del Candado NUI (Centrado en el marco de la puerta)
                local drawCoords = vector3(doorData.coords.x, doorData.coords.y, doorData.coords.z + 0.1)
                local onScreen, x, y = GetScreenCoordFromWorldCoord(drawCoords.x, drawCoords.y, drawCoords.z)
                if onScreen then
                    SendNUIMessage({
                        action = 'updateDoorlock',
                        x = x * 100,
                        y = y * 100,
                        locked = isLocked
                    })
                else
                    SendNUIMessage({ action = 'hideDoorlock' })
                end
            else
                SendNUIMessage({ action = 'hideDoorlock' })
            end
            
            currentClosestDoor = closestDoor
            Wait(wait)
        end
    end)
end

CreateThread(function()
    Wait(500)
    InitDoors()
end)

local function HasDoorPermission(playerJob, doorJob)
    if not playerJob or not doorJob then return false end
    if playerJob == doorJob then return true end
    if Config.GangBusinessMap and Config.GangBusinessMap[playerJob] == doorJob then return true end
    if Config.BusinessVendors and Config.BusinessVendors[doorJob] and Config.BusinessVendors[doorJob].gang == playerJob then return true end
    return false
end

-- Keymapping para abrir/cerrar puertas con la tecla 'I'
RegisterCommand('toggle_doorlock', function()
    if not currentClosestDoor then return end
    
    local doorData = ActiveDoors[currentClosestDoor]
    if not doorData then return end

    local plyCoords = GetEntityCoords(cache.ped)
    local dist = #(plyCoords - doorData.coords)
    
    -- Margen de interacción
    if dist <= math.max(doorData.distance or 2.5, 3.0) then
        local myJobInfo = exports.aura_jobs:GetJob()
        if HasDoorPermission(myJobInfo.job, doorData.job) then
            TriggerServerEvent('aura_jobs:server:toggleDoorlock', currentClosestDoor)
            
            -- Animación inmersiva de llaves / tarjeta
            lib.requestAnimDict("anim@heists@keycard@")
            TaskPlayAnim(cache.ped, "anim@heists@keycard@", "exit", 8.0, 1.0, -1, 16, 0, 0, 0, 0)
            Wait(700)
            ClearPedTasks(cache.ped)
        else
            lib.notify({ type = 'error', description = 'No tienes la llave de esta puerta' })
        end
    end
end)

RegisterKeyMapping('toggle_doorlock', 'Aura: Bloquear/Desbloquear Puerta', 'keyboard', 'I')

-- Reacción en caliente vía StateBag
AddStateBagChangeHandler(nil, 'global', function(bagName, key, value)
    if string.sub(key, 1, 9) == 'doorlock_' then
        local doorId = string.sub(key, 10)
        local doorData = ActiveDoors[doorId]
        if doorData and doorData.foundEntities then
            for idx, obj in ipairs(doorData.foundEntities) do
                if DoesEntityExist(obj) then
                    local subDoorId = joaat(doorId .. '_' .. idx)
                    if value == true then
                        DoorSystemSetDoorState(subDoorId, 4, false, false)
                        DoorSystemSetOpenRatio(subDoorId, 0.0, false, false)
                        FreezeEntityPosition(obj, true)
                    else
                        DoorSystemSetDoorState(subDoorId, 0, false, false)
                        FreezeEntityPosition(obj, false)
                    end
                end
            end
        end
    end
end)
