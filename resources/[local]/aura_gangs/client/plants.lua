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

local CandidatePlantModels = {
    [1] = {
        `prop_plant_pot_01a`,
        `prop_plant_pot_02a`,
        `prop_plant_pot_03a`,
        `prop_plant_pot_04a`,
        `prop_plant_pot_05a`,
        `bkr_prop_weed_01_small_01a`
    },
    [2] = {
        `bkr_prop_weed_01_small_01a`,
        `bkr_prop_weed_01_plant_01a`,
        `bkr_prop_weed_med_01a`
    },
    [3] = {
        `bkr_prop_weed_med_01a`,
        `bkr_prop_weed_01_plant_01c`,
        `bkr_prop_weed_lrg_01a`
    },
    [4] = {
        `bkr_prop_weed_lrg_01a`,
        `bkr_prop_weed_01_plant_02a`,
        `bkr_prop_weed_med_01a`
    }
}

local function ResolvePlantModel(preferredModel, stage)
    local stageNum = tonumber(stage) or 1
    if preferredModel and IsModelValid(preferredModel) and IsModelInCdimage(preferredModel) then
        return preferredModel
    end

    local pool = CandidatePlantModels[stageNum] or CandidatePlantModels[1]
    for _, mod in ipairs(pool) do
        if IsModelValid(mod) and IsModelInCdimage(mod) then
            return mod
        end
    end

    return `bkr_prop_weed_01_small_01a`
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
        local targetModel = ResolvePlantModel(stageConfig.model, plant.stage)

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
        duration = Config.Greenhouse.Harvest.harvestDuration or 5500,
        label = 'Recolectando y cortando cogollos de marihuana...',
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
-- 3. MESA DE TRABAJO: SENTARSE A EMPAQUETAR (MINIJUEGO AURA_MINIGAMES)
-- ============================================================================

local isPackagingActive = false

function SitAndPackageWeed(targetEntity, targetCoords)
    if isPackagingActive then return end

    local pCoords = GetEntityCoords(PlayerPedId())
    local center = Config.Greenhouse.Interior.plantingCenter or vec3(1051.49, -3196.53, -39.14)
    local pState = LocalPlayer.state

    if #(pCoords - center) > 50.0 and (not pState.greenhouse_bucket or pState.greenhouse_bucket == 0) then
        lib.notify({ title = 'Laboratorio Clandestino', description = 'Debes estar dentro del invernadero para empaquetar.', type = 'error' })
        return
    end

    local pkgConfig = Config.Greenhouse.Packaging or {}
    local reqBuds = pkgConfig.requiredBudsItem or 'cogollo_weed'
    local reqBudsCount = pkgConfig.requiredBudsCount or 5
    local reqBaggie = pkgConfig.requiredBaggieItem or 'empty_baggies'
    local reqBaggieCount = pkgConfig.requiredBaggieCount or 1

    local currentBuds = exports.ox_inventory:Search('count', reqBuds) or 0
    local currentBaggies = exports.ox_inventory:Search('count', reqBaggie) or 0

    if currentBuds < reqBudsCount or currentBaggies < reqBaggieCount then
        local statusBuds = (currentBuds >= reqBudsCount) and "✅" or "❌"
        local statusBaggies = (currentBaggies >= reqBaggieCount) and "✅" or "❌"
        lib.alertDialog({
            header = '🌿 MESA DE EMPAQUETADO Y DOSIFICACIÓN',
            content = string.format("### 📦 MATERIAS PRIMAS REQUERIDAS:\n- %s **%dx Cogollos de Marihuana** (`%s`) — _En posesión: %d_\n- %s **%dx Bolsitas Herméticas** (`%s`) — _En posesión: %d_\n\n> ⚠️ **FALTAN INSUMOS:**\n> Cosecha más cogollos frescos con tus tijeras de podar y asegúrate de tener bolsitas herméticas para envasar al vacío.", statusBuds, reqBudsCount, reqBuds, currentBuds, statusBaggies, reqBaggieCount, reqBaggie, currentBaggies),
            centered = true,
            cancel = false,
            labels = { confirm = 'ENTENDIDO' }
        })
        return
    end

    isPackagingActive = true
    local ped = PlayerPedId()

    -- 1. Determinar coordenadas y orientación precisa de asiento
    local sitX, sitY, sitZ = nil, nil, nil
    local sitHeading = nil

    if targetEntity and DoesEntityExist(targetEntity) then
        local eCoords = GetEntityCoords(targetEntity)
        local eHeading = GetEntityHeading(targetEntity)
        sitX, sitY = eCoords.x, eCoords.y
        -- En GTA V, la orientación para sentarse de cara a la mesa es invertida 180° respecto al respaldo de la silla
        sitHeading = (eHeading + 180.0) % 360.0
        -- Ajustar altura de asiento (si la coordenada es a nivel de suelo, elevar al asiento; si es del prop, calibrar)
        sitZ = (eCoords.z < -39.0) and (eCoords.z + 0.45) or (eCoords.z - 0.15)
    elseif targetCoords then
        sitX, sitY = targetCoords.x, targetCoords.y
        sitHeading = (GetEntityHeading(ped) + 180.0) % 360.0
        sitZ = (targetCoords.z < -39.0) and (targetCoords.z + 0.45) or targetCoords.z
    else
        local myPos = GetEntityCoords(ped)
        sitX, sitY = myPos.x, myPos.y
        sitHeading = GetEntityHeading(ped)
        sitZ = myPos.z
    end

    -- 2. Posicionar y sentar físicamente al personaje en la silla de forma persistente
    TaskTurnPedToFaceCoord(ped, sitX, sitY, sitZ, 200)
    Wait(150)
    TaskStartScenarioAtPosition(ped, 'PROP_HUMAN_SEAT_CHAIR_MP_PLAYER', sitX, sitY, sitZ, sitHeading, -1, false, true)
    Wait(500)

    -- Retirar ingredientes antes de abrir el minijuego
    local canStart, startMsg = lib.callback.await('aura_gangs:server:startWeedPackaging', false)
    if not canStart then
        ClearPedTasks(ped)
        isPackagingActive = false
        lib.notify({ title = 'Mesa de Empaquetado', description = startMsg, type = 'error' })
        return
    end

    -- Ejecución del Minijuego AuraRP WeedPackaging
    local success = false
    if GetResourceState('aura_minigames') == 'started' then
        success = exports.aura_minigames:WeedPackaging({
            targetWeight = 28.00,
            weightTolerance = 0.70,
            requiredSeals = 3,
            timeLimit = 35
        })
    else
        local s1 = lib.skillCheck({'medium', 'medium'}, {'w', 'a', 's', 'd'})
        local s2 = s1 and lib.skillCheck({'hard'}, {'w', 'a', 's', 'd'})
        success = (s2 == true)
    end

    -- Levantar al personaje suavemente de la silla
    ClearPedTasks(ped)
    isPackagingActive = false

    if success then
        local ok, finishMsg = lib.callback.await('aura_gangs:server:finishWeedPackaging', false)
        if ok then
            PlaySoundFrontend(-1, "COLLECTED", "HUD_AWARDS", true)
            lib.notify({
                title = 'EMPAQUETADO EXITOSO',
                description = finishMsg,
                type = 'success',
                duration = 7000
            })
        else
            lib.notify({ title = 'Mesa de Empaquetado', description = finishMsg, type = 'error' })
        end
    else
        local _, cancelMsg = lib.callback.await('aura_gangs:server:cancelWeedPackaging', false)
        lib.notify({
            title = 'EMPAQUETADO CANCELADO',
            description = cancelMsg,
            type = 'inform'
        })
    end
end

-- ============================================================================
-- 4. REGISTRO DE TARGETS PARA SILLAS Y MESAS DE EMPAQUETADO
-- ============================================================================

CreateThread(function()
    local pkgConfig = Config.Greenhouse.Packaging or {}
    local center = Config.Greenhouse.Interior.plantingCenter or vec3(1051.49, -3196.53, -39.14)

    local function IsInGreenhouseInterior()
        local pCoords = GetEntityCoords(PlayerPedId())
        local pState = LocalPlayer.state
        return (#(pCoords - center) < 55.0) or (pState.greenhouse_bucket and pState.greenhouse_bucket > 0)
    end

    local function IsPlantEntity(entity)
        if not entity or not DoesEntityExist(entity) then return false end
        for _, plantData in pairs(SpawnedPlants) do
            if plantData.entity == entity then
                return true
            end
        end
        return false
    end

    -- Registro exclusivo y único por modelos de sillas, bancos y mesas de empaquetado
    if pkgConfig.targetModels and #pkgConfig.targetModels > 0 then
        exports.ox_target:addModel(pkgConfig.targetModels, {
            {
                name = 'greenhouse_sit_and_package',
                icon = 'fas fa-box-open',
                label = 'Sentarse a Empaquetar',
                distance = 2.5,
                canInteract = function(entity)
                    return IsInGreenhouseInterior() and not IsPlantEntity(entity)
                end,
                onSelect = function(data)
                    SitAndPackageWeed(data and data.entity, data and data.coords)
                end
            }
        })
    end
end)

-- ============================================================================
-- 5. NUI GLASSMORPHISM (DIAGNÓSTICO BIOLÓGICO DE LA PLANTA)
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
