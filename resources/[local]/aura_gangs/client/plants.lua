-- ============================================================================
-- AURA GANGS: CLIENT PLANTS CONTROLLER (PROJECT GREENHOUSE)
-- Prop Rendering, ox_target Entity Hooks, Planting Sequence & Glassmorphism NUI
-- ============================================================================

local SpawnedPlants = {} -- [plantId] = { entity, data }
local CurrentOpenPlantId = nil

--- Despawnear todas las plantas creadas localmente
local function CleanupSpawnedPlants()
    for plantId, plantData in pairs(SpawnedPlants) do
        if DoesEntityExist(plantData.entity) then
            exports.ox_target:removeLocalEntity(plantData.entity)
            DeleteEntity(plantData.entity)
        end
    end
    SpawnedPlants = {}
end

--- Registrar interacciones ox_target en la entidad física de la maceta
--- @param entity number
--- @param plantData table
local function AttachPlantTarget(entity, plantData)
    local plantId = plantData.id

    exports.ox_target:addLocalEntity(entity, {
        {
            name = 'plant_inspect_' .. plantId,
            icon = 'fas fa-microscope',
            label = 'Inspeccionar Estado (Diagnóstico)',
            distance = 1.8,
            onSelect = function()
                OpenPlantNUI(plantId)
            end
        },
        {
            name = 'plant_water_' .. plantId,
            icon = 'fas fa-droplet',
            label = 'Regar Sustrato (Botella de Agua)',
            distance = 1.8,
            canInteract = function()
                local pState = LocalPlayer.state
                return pState.greenhouse_bucket and pState.greenhouse_bucket > 0
            end,
            onSelect = function()
                WaterPlant(plantId)
            end
        },
        {
            name = 'plant_fertilize_' .. plantId,
            icon = 'fas fa-flask-vial',
            label = 'Nutrir con Fertilizante (NPK)',
            distance = 1.8,
            canInteract = function()
                local pState = LocalPlayer.state
                return pState.greenhouse_bucket and pState.greenhouse_bucket > 0
            end,
            onSelect = function()
                FertilizePlant(plantId)
            end
        },
        {
            name = 'plant_harvest_' .. plantId,
            icon = 'fas fa-scissors',
            label = 'Cosechar Cogollos (Tijeras de Podar)',
            distance = 1.8,
            canInteract = function()
                local p = SpawnedPlants[plantId] and SpawnedPlants[plantId].data
                return p and (p.stage >= 4 or p.growth >= 90.0)
            end,
            onSelect = function()
                HarvestPlant(plantId)
            end
        }
    })
end

--- Sincronizar y generar props visuales según la fase biológica
RegisterNetEvent('aura_gangs:client:syncPlants', function(plantsList)
    local pState = LocalPlayer.state
    if not pState.greenhouse_bucket or pState.greenhouse_bucket == 0 then
        CleanupSpawnedPlants()
        return
    end

    local incomingIds = {}

    for _, plant in ipairs(plantsList or {}) do
        local pId = plant.id
        incomingIds[pId] = true

        local stageConfig = Config.Greenhouse.Stages[plant.stage] or Config.Greenhouse.Stages[1]
        local targetModel = stageConfig.model

        -- Si la planta ya existe y ha cambiado de fase, reemplazar prop
        if SpawnedPlants[pId] then
            local currentEntity = SpawnedPlants[pId].entity
            local currentModel = GetEntityModel(currentEntity)

            if currentModel ~= targetModel then
                if DoesEntityExist(currentEntity) then
                    exports.ox_target:removeLocalEntity(currentEntity)
                    DeleteEntity(currentEntity)
                end
                SpawnedPlants[pId] = nil
            else
                -- Actualizar datos en memoria
                SpawnedPlants[pId].data = plant
            end
        end

        -- Crear entidad física si no existe
        if not SpawnedPlants[pId] then
            if not IsModelInCdimage(targetModel) then
                targetModel = `bkr_prop_weed_bucket_open_01a`
            end
            lib.requestModel(targetModel)
            local coords = plant.coords
            local obj = CreateObject(targetModel, coords.x, coords.y, coords.z, false, false, false)
            SetEntityHeading(obj, plant.heading or 0.0)
            PlaceObjectOnGroundProperly(obj)
            FreezeEntityPosition(obj, true)
            SetEntityCollision(obj, true, true)
            SetEntityAsMissionEntity(obj, true, true)

            SpawnedPlants[pId] = {
                entity = obj,
                data = plant
            }
            AttachPlantTarget(obj, plant)
        end

        -- Si el jugador tiene la interfaz abierta de esta planta, actualizar en tiempo real
        if CurrentOpenPlantId and CurrentOpenPlantId == pId then
            SendNUIMessage({
                action = 'openPlantDiagnosis',
                data = {
                    id = plant.id,
                    stage = plant.stage,
                    stageLabel = (Config.Greenhouse.Stages[plant.stage] and Config.Greenhouse.Stages[plant.stage].label) or ('Fase ' .. plant.stage),
                    growth = plant.growth,
                    thirst = plant.thirst,
                    nutrition = plant.nutrition,
                    isReady = (plant.stage >= 4 or plant.growth >= 90.0)
                }
            })
        end
    end

    -- Eliminar plantas cosechadas o destruidas
    for pId, pObj in pairs(SpawnedPlants) do
        if not incomingIds[pId] then
            if DoesEntityExist(pObj.entity) then
                exports.ox_target:removeLocalEntity(pObj.entity)
                DeleteEntity(pObj.entity)
            end
            SpawnedPlants[pId] = nil
        end
    end
end)

-- ============================================================================
-- 1. SECUENCIA DE PLANTADO
-- ============================================================================

--- Export para usar el item maceta_vacia desde el inventario
local function StartPlantingSequence()
    local pState = LocalPlayer.state
    if not pState.greenhouse_bucket or pState.greenhouse_bucket == 0 then
        lib.notify({
            title = 'ACCESO DENEGADO',
            description = 'Solo puedes instalar macetas dentro de tu invernadero clandestino.',
            type = 'error'
        })
        return
    end

    local ped = PlayerPedId()
    local forwardCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.85, 0.0)
    local foundGround, groundZ = GetGroundZFor_3dCoord(forwardCoords.x, forwardCoords.y, forwardCoords.z + 1.0, false)
    local coords = vec3(forwardCoords.x, forwardCoords.y, foundGround and (groundZ + 0.02) or (forwardCoords.z - 0.95))
    local heading = GetEntityHeading(ped)

    -- Animación de arrodillarse / colocar sustrato y plantar semilla
    if lib.progressBar({
        duration = 5000,
        label = 'Asentando maceta con sustrato y semilla...',
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = {
            dict = 'amb@world_human_gardener_plant@male@base',
            clip = 'base',
            flag = 1
        }
    }) then
        local success, msg = lib.callback.await('aura_gangs:server:plantSeed', false, coords, heading)
        lib.notify({
            title = success and 'CULTIVO INICIADO' or 'ERROR DE PLANTADO',
            description = msg,
            type = success and 'success' or 'error'
        })
    else
        lib.notify({ title = 'CANCELADO', description = 'Has detenido el proceso de plantado.', type = 'inform' })
    end
end
exports('usePlantPot', StartPlantingSequence)

RegisterCommand('plantar', function()
    StartPlantingSequence()
end, false)

-- ============================================================================
-- 2. ACCIONES DE CUIDADO Y COSECHA
-- ============================================================================

function WaterPlant(plantId)
    local ped = PlayerPedId()
    if SpawnedPlants[plantId] and DoesEntityExist(SpawnedPlants[plantId].entity) then
        TaskTurnPedToFaceEntity(ped, SpawnedPlants[plantId].entity, 1000)
        Wait(500)
    end

    if lib.progressBar({
        duration = 3500,
        label = 'Regando sustrato con agua mineral...',
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = {
            dict = 'amb@world_human_gardener_plant@male@base',
            clip = 'base',
            flag = 49
        }
    }) then
        local success, msg = lib.callback.await('aura_gangs:server:waterPlant', false, plantId)
        if success and SpawnedPlants[plantId] then
            SpawnedPlants[plantId].data.thirst = 100.0
            if CurrentOpenPlantId == plantId then
                OpenPlantNUI(plantId)
            end
        end

        lib.notify({
            title = success and 'RIEGO COMPLETADO' or 'ERROR',
            description = msg,
            type = success and 'success' or 'error'
        })
    end
end

function FertilizePlant(plantId)
    local ped = PlayerPedId()
    if SpawnedPlants[plantId] and DoesEntityExist(SpawnedPlants[plantId].entity) then
        TaskTurnPedToFaceEntity(ped, SpawnedPlants[plantId].entity, 1000)
        Wait(500)
    end

    if lib.progressBar({
        duration = 4000,
        label = 'Aplicando abono líquido NPK...',
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = {
            dict = 'amb@world_human_gardener_plant@male@base',
            clip = 'base',
            flag = 49
        }
    }) then
        local success, msg = lib.callback.await('aura_gangs:server:fertilizePlant', false, plantId)
        if success and SpawnedPlants[plantId] then
            SpawnedPlants[plantId].data.nutrition = 100.0
            if CurrentOpenPlantId == plantId then
                OpenPlantNUI(plantId)
            end
        end

        lib.notify({
            title = success and 'FERTILIZADO ÓPTIMO' or 'ERROR',
            description = msg,
            type = success and 'success' or 'error'
        })
    end
end

function HarvestPlant(plantId)
    local ped = PlayerPedId()
    if SpawnedPlants[plantId] and DoesEntityExist(SpawnedPlants[plantId].entity) then
        TaskTurnPedToFaceEntity(ped, SpawnedPlants[plantId].entity, 1000)
        Wait(500)
    end

    if lib.progressBar({
        duration = Config.Greenhouse.Harvest.harvestDuration or 6000,
        label = 'Cortando y embolsando cogollos de marihuana...',
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = {
            dict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@',
            clip = 'weed_crouch_checkingleaves_idle_01_inspector',
            flag = 49
        }
    }) then
        local success, msg = lib.callback.await('aura_gangs:server:harvestPlant', false, plantId)
        lib.notify({
            title = success and 'COSECHA COMPLETADA' or 'COSECHA DENEGADA',
            description = msg,
            type = success and 'success' or 'error'
        })
    end
end

-- ============================================================================
-- 3. NUI GLASSMORPHISM (DIAGNÓSTICO BIOLÓGICO DE LA PLANTA)
-- ============================================================================

function OpenPlantNUI(plantIdentifier)
    local plantId = (type(plantIdentifier) == 'table') and plantIdentifier.id or plantIdentifier
    if not plantId then return end

    -- Consultar al servidor el estado vivo más reciente
    local livePlant = lib.callback.await('aura_gangs:server:getPlantDetails', false, plantId)
    if not livePlant and SpawnedPlants[plantId] then
        livePlant = SpawnedPlants[plantId].data
    end

    if not livePlant then
        lib.notify({ title = 'ERROR', description = 'No se ha podido sincronizar la información del cultivo.', type = 'error' })
        return
    end

    -- Actualizar copia local en memoria
    if SpawnedPlants[plantId] then
        SpawnedPlants[plantId].data = livePlant
    end

    CurrentOpenPlantId = livePlant.id
    local stageConfig = Config.Greenhouse.Stages[livePlant.stage] or { label = 'Fase ' .. livePlant.stage }

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openPlantDiagnosis',
        data = {
            id = livePlant.id,
            stage = livePlant.stage,
            stageLabel = stageConfig.label,
            growth = livePlant.growth,
            thirst = livePlant.thirst,
            nutrition = livePlant.nutrition,
            isReady = (livePlant.stage >= 4 or livePlant.growth >= 90.0)
        }
    })
end

RegisterNUICallback('closeUI', function(_, cb)
    CurrentOpenPlantId = nil
    SetNuiFocus(false, false)
    cb('ok')
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    CurrentOpenPlantId = nil
    CleanupSpawnedPlants()
end)
