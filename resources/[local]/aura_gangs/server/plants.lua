-- ============================================================================
-- AURA GANGS: SERVER PLANTS ENGINE (PROJECT GREENHOUSE)
-- Lifecycle, Growth Tick Loop, Thirst/Nutrition Decay & Simplified Harvest
-- ============================================================================

local GangPlants = {} -- [gangId] = { [plantId] = plantData }
local DirtyPlants = {} -- [plantId] = true

--- Sincronizar todas las plantas de una banda a los jugadores en su routing bucket
--- @param gangId string
local function BroadcastPlantsToGang(gangId)
    if not gangId then return end
    local bucketId = exports.aura_gangs:GetGangBucket(gangId)
    local plantsList = {}

    if GangPlants[gangId] then
        for _, p in pairs(GangPlants[gangId]) do
            table.insert(plantsList, p)
        end
    end

    for _, pid in ipairs(GetPlayers()) do
        local pSrc = tonumber(pid)
        if pSrc and GetPlayerRoutingBucket(pSrc) == bucketId then
            TriggerClientEvent('aura_gangs:client:syncPlants', pSrc, plantsList)
        end
    end
end

--- Sincronizar plantas a un jugador específico que entra a la dimensión
RegisterNetEvent('aura_gangs:server:syncPlantsToPlayer', function(targetSrc, gangId)
    local src = targetSrc or source
    if not src or not gangId then return end
    local plantsList = {}

    if GangPlants[gangId] then
        for _, p in pairs(GangPlants[gangId]) do
            table.insert(plantsList, p)
        end
    end

    TriggerClientEvent('aura_gangs:client:syncPlants', src, plantsList)
end)

--- Cargar todas las plantas desde la base de datos
local function LoadAllPlants()
    local results = MySQL.query.await([[
        SELECT id, gang_id, stage, growth, thirst, nutrition, coords_x, coords_y, coords_z, heading 
        FROM aura_plants
    ]])

    GangPlants = {}
    if results and #results > 0 then
        for _, row in ipairs(results) do
            local gId = row.gang_id
            if not GangPlants[gId] then GangPlants[gId] = {} end
            GangPlants[gId][row.id] = {
                id = row.id,
                gang_id = gId,
                stage = tonumber(row.stage) or 1,
                growth = tonumber(row.growth) or 0.0,
                thirst = tonumber(row.thirst) or 100.0,
                nutrition = tonumber(row.nutrition) or 100.0,
                coords = vec3(row.coords_x, row.coords_y, row.coords_z),
                heading = tonumber(row.heading) or 0.0
            }
        end
    end

    -- Difundir a cada bucket activo
    for gId, _ in pairs(Config.Gangs) do
        BroadcastPlantsToGang(gId)
    end
    print(string.format('^2[AURA GANGS]^7 Cultivos de Marihuana cargados: ^3%d^7 plantas activas en el ecosistema.', results and #results or 0))
end

CreateThread(function()
    Wait(1000)
    LoadAllPlants()
end)

-- ============================================================================
-- 1. PLANTADO DE NUEVAS SEMILLAS (SETUP CON MACETA + TIERRA + SEMILLA)
-- ============================================================================

lib.callback.register('aura_gangs:server:plantSeed', function(source, plantCoords, heading)
    local src = source
    if not src or not plantCoords then return false, "Coordenadas no válidas." end

    local pState = Player(src).state
    local gangId = pState.in_greenhouse_gang
    local bucketId = pState.greenhouse_bucket

    if not gangId or not bucketId or bucketId == 0 then
        return false, "Solo puedes colocar macetas de cultivo dentro de tu invernadero clandestino."
    end

    -- Validar límite de plantas por invernadero
    if not GangPlants[gangId] then GangPlants[gangId] = {} end
    local currentCount = 0
    for _ in pairs(GangPlants[gangId]) do currentCount = currentCount + 1 end

    if currentCount >= Config.Greenhouse.MaxPlantsPerGreenhouse then
        return false, string.format("Has alcanzado el límite máximo de cultivo (%d plantas).", Config.Greenhouse.MaxPlantsPerGreenhouse)
    end

    -- Validar distancia mínima contra otras macetas existentes
    for _, existing in pairs(GangPlants[gangId]) do
        local dist = #(existing.coords - vec3(plantCoords.x, plantCoords.y, plantCoords.z))
        if dist < Config.Greenhouse.MinPlantDistance then
            return false, "Espacio insuficiente. Debes dejar al menos 1 metro de separación entre macetas."
        end
    end

    -- Comprobación de inventario: maceta_vacia, saco_tierra, weed_seed
    local hasPot = exports.ox_inventory:GetItemCount(src, 'maceta_vacia') >= 1
    local hasSoil = exports.ox_inventory:GetItemCount(src, 'saco_tierra') >= 1
    local hasSeed = exports.ox_inventory:GetItemCount(src, 'weed_seed') >= 1

    if not hasPot or not hasSoil or not hasSeed then
        return false, "Necesitas: 1x Maceta Vacía, 1x Saco de Sustrato y 1x Semilla Feminizada."
    end

    -- Retirar materiales atómicamente
    local remPot = exports.ox_inventory:RemoveItem(src, 'maceta_vacia', 1)
    local remSoil = exports.ox_inventory:RemoveItem(src, 'saco_tierra', 1)
    local remSeed = exports.ox_inventory:RemoveItem(src, 'weed_seed', 1)

    if not remPot or not remSoil or not remSeed then
        return false, "Fallo al procesar los materiales en tu inventario."
    end

    local initThirst = (Config.Greenhouse.InitialStats and Config.Greenhouse.InitialStats.thirst) or 0.0
    local initNutrition = (Config.Greenhouse.InitialStats and Config.Greenhouse.InitialStats.nutrition) or 0.0

    -- Insertar registro persistente en base de datos con valores iniciales
    local insertId = MySQL.insert.await([[
        INSERT INTO aura_plants (gang_id, stage, growth, thirst, nutrition, coords_x, coords_y, coords_z, heading)
        VALUES (?, 1, 0.0, ?, ?, ?, ?, ?, ?)
    ]], { gangId, initThirst, initNutrition, plantCoords.x, plantCoords.y, plantCoords.z, heading or 0.0 })

    if not insertId then
        return false, "Error de base de datos al asentar la maceta."
    end

    local newPlant = {
        id = insertId,
        gang_id = gangId,
        stage = 1,
        growth = 0.0,
        thirst = initThirst,
        nutrition = initNutrition,
        coords = vec3(plantCoords.x, plantCoords.y, plantCoords.z),
        heading = heading or 0.0
    }

    GangPlants[gangId][insertId] = newPlant
    BroadcastPlantsToGang(gangId)

    return true, "Has plantado la semilla correctamente. El sustrato está seco: riégalo y abónalo para que comience a germinar."
end)

-- ============================================================================
-- 2. CUIDADO: RIEGO (botella_agua) Y FERTILIZACIÓN (fertilizante)
-- ============================================================================

lib.callback.register('aura_gangs:server:waterPlant', function(source, plantId)
    local src = source
    if not src or not plantId then return false, "Planta no identificada." end

    local pState = Player(src).state
    local gangId = pState.in_greenhouse_gang
    if not gangId or not GangPlants[gangId] or not GangPlants[gangId][plantId] then
        return false, "La planta no existe o no tienes acceso a ella."
    end

    local plant = GangPlants[gangId][plantId]
    if plant.thirst >= 98.0 then
        return false, "El sustrato ya está completamente humedecido."
    end

    local removed = exports.ox_inventory:RemoveItem(src, 'botella_agua', 1) or exports.ox_inventory:RemoveItem(src, 'water', 1)
    if not removed then
        return false, "No tienes ninguna Botella de Agua (botella_agua / water) en tu inventario."
    end

    plant.thirst = 100.0
    DirtyPlants[plantId] = true

    MySQL.query.await('UPDATE aura_plants SET thirst = 100.0 WHERE id = ?', { plantId })
    BroadcastPlantsToGang(gangId)

    return true, "Has regado la planta con agua mineral balanceada (Hidratación: 100%)."
end)

lib.callback.register('aura_gangs:server:fertilizePlant', function(source, plantId)
    local src = source
    if not src or not plantId then return false, "Planta no identificada." end

    local pState = Player(src).state
    local gangId = pState.in_greenhouse_gang
    if not gangId or not GangPlants[gangId] or not GangPlants[gangId][plantId] then
        return false, "La planta no existe o no tienes acceso a ella."
    end

    local plant = GangPlants[gangId][plantId]
    if plant.nutrition >= 98.0 then
        return false, "El sustrato ya cuenta con nutrientes NPK óptimos."
    end

    local removed = exports.ox_inventory:RemoveItem(src, 'fertilizante', 1)
    if not removed then
        return false, "No tienes Fertilizante NPK en tu inventario."
    end

    plant.nutrition = 100.0
    DirtyPlants[plantId] = true

    MySQL.query.await('UPDATE aura_plants SET nutrition = 100.0 WHERE id = ?', { plantId })
    BroadcastPlantsToGang(gangId)

    return true, "Has enriquecido el sustrato con fertilizante NPK (Nutrición: 100%)."
end)

-- ============================================================================
-- 3. COSECHA SIMPLIFICADA (tijeras_podar + empty_baggies -> weed)
-- ============================================================================

lib.callback.register('aura_gangs:server:harvestPlant', function(source, plantId)
    local src = source
    if not src or not plantId then return false, "Parámetros de cosecha inválidos." end

    local pState = Player(src).state
    local gangId = pState.in_greenhouse_gang
    if not gangId or not GangPlants[gangId] or not GangPlants[gangId][plantId] then
        return false, "La planta no existe en este invernadero."
    end

    local plant = GangPlants[gangId][plantId]
    if plant.stage < 4 or plant.growth < 90.0 then
        return false, string.format("La planta aún no ha madurado por completo (Progreso actual: %.1f%%).", plant.growth)
    end

    -- Comprobar tijeras de podar
    local hasShears = exports.ox_inventory:GetItemCount(src, Config.Greenhouse.Harvest.requiredTool) >= 1
    if not hasShears then
        return false, "Necesitas Tijeras de Podar para cortar los cogollos."
    end

    -- Comprobar si tiene bolsitas herméticas (empty_baggies)
    local hasBaggies = exports.ox_inventory:GetItemCount(src, Config.Greenhouse.Harvest.requiredBaggie) >= 1
    if not hasBaggies then
        return false, "¡Cosecha denegada! Necesitas al menos 1 bolsita hermética (empty_baggies) para envasar la marihuana."
    end

    -- Retirar 1 bolsita hermética
    local remBag = exports.ox_inventory:RemoveItem(src, Config.Greenhouse.Harvest.requiredBaggie, 1)
    if not remBag then
        return false, "Error al retirar la bolsita hermética de tu inventario."
    end

    -- Calcular cantidad de weed producida
    local rewardAmount = math.random(Config.Greenhouse.Harvest.rewardAmount.min, Config.Greenhouse.Harvest.rewardAmount.max)
    local canCarry = exports.ox_inventory:CanCarryItem(src, Config.Greenhouse.Harvest.rewardItem, rewardAmount)
    if not canCarry then
        -- Devolver la bolsita si no puede cargar el peso
        exports.ox_inventory:AddItem(src, Config.Greenhouse.Harvest.requiredBaggie, 1)
        return false, "Inventario lleno. No puedes cargar el peso de la cosecha."
    end

    -- Entregar weed y eliminar planta
    exports.ox_inventory:AddItem(src, Config.Greenhouse.Harvest.rewardItem, rewardAmount)
    
    MySQL.query.await('DELETE FROM aura_plants WHERE id = ?', { plantId })
    GangPlants[gangId][plantId] = nil
    DirtyPlants[plantId] = nil

    BroadcastPlantsToGang(gangId)

    return true, string.format("¡Cosecha exitosa! Has envasado %d bolsas de Marihuana de primera calidad.", rewardAmount)
end)

-- Callback para obtener el estado vivo y en tiempo real de una planta
lib.callback.register('aura_gangs:server:getPlantDetails', function(source, plantId)
    local src = source
    if not src or not plantId then return nil end

    local pState = Player(src).state
    local gangId = pState.in_greenhouse_gang
    if gangId and GangPlants[gangId] and GangPlants[gangId][plantId] then
        return GangPlants[gangId][plantId]
    end

    -- Búsqueda global de fallback
    for _, plants in pairs(GangPlants) do
        if plants[plantId] then
            return plants[plantId]
        end
    end
    return nil
end)

-- ============================================================================
-- 4. MOTOR DE CRECIMIENTO BIOLÓGICO (SERVER TICK LOOP)
-- ============================================================================

CreateThread(function()
    local engine = Config.Greenhouse.GrowthEngine
    while true do
        Wait(engine.tickInterval * 1000)

        for gangId, plants in pairs(GangPlants) do
            local hasPlants = false
            for plantId, plant in pairs(plants) do
                hasPlants = true

                -- 1. Degradación natural de agua y nutrientes
                plant.thirst = math.max(0.0, plant.thirst - engine.thirstDecay)
                plant.nutrition = math.max(0.0, plant.nutrition - engine.nutritionDecay)

                -- 2. Progreso de crecimiento solo si está viva (agua > 0 y abono > 0)
                if plant.growth < 100.0 and plant.thirst > 0.0 and plant.nutrition > 0.0 then
                    local growthRate = engine.baseGrowthRate
                    if plant.thirst > 50.0 and plant.nutrition > 50.0 then
                        growthRate = growthRate * engine.optimalBonusMultiplier
                    end

                    plant.growth = math.min(100.0, plant.growth + growthRate)

                    -- 3. Actualizar fase visual (1 a 4)
                    if plant.growth >= 90.0 then
                        plant.stage = 4
                    elseif plant.growth >= 55.0 then
                        plant.stage = 3
                    elseif plant.growth >= 25.0 then
                        plant.stage = 2
                    else
                        plant.stage = 1
                    end
                end

                DirtyPlants[plantId] = true
            end

            -- Difundir las métricas actualizadas en tiempo real a todos los clientes dentro del bucket
            if hasPlants then
                BroadcastPlantsToGang(gangId)
            end
        end

        -- Guardado periódico asíncrono en MySQL
        for plantId in pairs(DirtyPlants) do
            for _, plants in pairs(GangPlants) do
                local p = plants[plantId]
                if p then
                    MySQL.query([[
                        UPDATE aura_plants 
                        SET stage = ?, growth = ?, thirst = ?, nutrition = ? 
                        WHERE id = ?
                    ]], { p.stage, p.growth, p.thirst, p.nutrition, plantId })
                end
            end
        end
        DirtyPlants = {}
    end
end)

-- Exportar función para eliminar plantas externamente (e.g. Redadas policiales)
exports('DeletePlant', function(gangId, plantId)
    if gangId and GangPlants[gangId] and GangPlants[gangId][plantId] then
        MySQL.query.await('DELETE FROM aura_plants WHERE id = ?', { plantId })
        GangPlants[gangId][plantId] = nil
        DirtyPlants[plantId] = nil
        BroadcastPlantsToGang(gangId)
        return true
    end
    return false
end)
