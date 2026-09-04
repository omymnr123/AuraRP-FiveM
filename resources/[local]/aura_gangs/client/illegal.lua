-- ============================================================================
-- AURA GANGS: CLIENT ILLEGAL ACTIVITIES CONTROLLER
-- Money Laundering Machines & Meth Lab Cooking with Critical Lethal Explosion
-- ============================================================================

local isCookingMeth = false

local function IsPlayerInGang()
    if LocalPlayer.state.isGang == true then return true end
    local pJob = LocalPlayer.state.job
    if pJob and Config.Gangs and Config.Gangs[pJob] then return true end

    local jobData = exports.aura_jobs and exports.aura_jobs:GetJob()
    if jobData and (jobData.isGang == true or (jobData.name and Config.Gangs and Config.Gangs[jobData.name])) then
        return true
    end
    return false
end

-- ============================================================================
-- 1. BLANQUEO DE CAPITALES (LAVADORAS CLANDESTINAS)
-- ============================================================================

local function GenerateMachineId(entity, fallbackCoords)
    if entity and DoesEntityExist(entity) then
        local coords = GetEntityCoords(entity)
        return string.format("wash_%.1f_%.1f_%.1f", coords.x, coords.y, coords.z)
    elseif fallbackCoords then
        return string.format("wash_%.1f_%.1f_%.1f", fallbackCoords.x, fallbackCoords.y, fallbackCoords.z)
    end
    local pedCoords = GetEntityCoords(cache.ped)
    return string.format("wash_%.1f_%.1f_%.1f", pedCoords.x, pedCoords.y, pedCoords.z)
end

local function InsertLaundryMoney(entity, fallbackCoords)
    local machineId = GenerateMachineId(entity, fallbackCoords)

    local blackMoneyCount = exports.ox_inventory:Search('count', 'black_money') or 0
    if blackMoneyCount < Config.Laundry.minAmount then
        lib.notify({
            title = 'Lavandería Clandestina',
            description = string.format("Necesitas al menos $%d de dinero negro para iniciar el ciclo de lavado.", Config.Laundry.minAmount),
            type = 'error'
        })
        return
    end

    local input = lib.inputDialog('Lavadora Clandestina - Carga de Billetes', {
        {
            type = 'number',
            label = 'Cantidad de Dinero Negro a Introducir',
            description = string.format("Disponible en bolsillos: $%s (Comisión fija del %d%%)", lib.math.groupdigits(blackMoneyCount), math.floor(Config.Laundry.taxRate * 100)),
            min = Config.Laundry.minAmount,
            max = blackMoneyCount,
            default = blackMoneyCount,
            required = true
        }
    })

    if not input or not input[1] then return end
    local amount = math.floor(tonumber(input[1]))

    if amount < Config.Laundry.minAmount or amount > blackMoneyCount then
        lib.notify({ title = 'Lavandería', description = 'Cantidad inválida.', type = 'error' })
        return
    end

    -- Animación de meter dinero en la máquina
    if lib.progressBar({
        duration = 4000,
        label = 'Introduciendo fajos de billetes en el tambor...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, combat = true },
        anim = { dict = 'anim@heists@prison_heiststation@cop_reactions', clip = 'cop_b_idle' }
    }) then
        lib.callback('aura_gangs:server:insertLaundryMoney', false, function(success, message)
            if success then
                PlaySoundFrontend(-1, "LOCAL_PLYR_CASH_COUNTER_COMPLETE", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", true)
                lib.notify({
                    title = 'Lavandería Clandestina',
                    description = message,
                    type = 'success',
                    duration = 8000
                })
            else
                lib.notify({ title = 'Lavandería', description = message, type = 'error' })
            end
        end, machineId, amount)
    end
end

local function CheckLaundryMachine(entity, fallbackCoords)
    local machineId = GenerateMachineId(entity, fallbackCoords)

    lib.callback('aura_gangs:server:checkLaundryMachine', false, function(data)
        if not data.hasActiveCycle then
            lib.notify({
                title = 'Lavadora Clandestina',
                description = 'El tambor está vacío. No hay ningún ciclo de lavado en curso en esta máquina.',
                type = 'inform'
            })
            return
        end

        if data.isReady then
            local confirm = lib.alertDialog({
                header = '🧺 BLANQUEO DE CAPITALES',
                content = string.format("### 💵 CICLO DE LAVADO COMPLETADO\nEl proceso de 30 minutos ha finalizado con éxito.\n\n- ✅ **Total Disponible:** **$%s limpios** listos para retirar.", lib.math.groupdigits(data.cleanAmount)),
                centered = true,
                cancel = true,
                labels = { confirm = 'RECOGER DINERO', cancel = 'DEJAR EN TAMBOR' }
            })

            if confirm == 'confirm' then
                lib.callback('aura_gangs:server:collectLaundryMoney', false, function(success, message)
                    if success then
                        PlaySoundFrontend(-1, "LOCAL_PLYR_CASH_COUNTER_COMPLETE", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", true)
                        lib.notify({ title = 'Lavandería Clandestina', description = message, type = 'success' })
                    else
                        lib.notify({ title = 'Lavandería', description = message, type = 'error' })
                    end
                end, machineId)
            end
        else
            lib.notify({
                title = 'Lavado en Proceso',
                description = string.format("⏳ Ciclo en curso. Faltan %d minutos para completar el blanqueo.\nRecibirás $%s limpios.", math.ceil(data.remainingSeconds / 60), lib.math.groupdigits(data.cleanAmount)),
                type = 'inform',
                duration = 6000
            })
        end
    end, machineId)
end

-- ============================================================================
-- 2. COCINA DE METANFETAMINA (METH LAB CON EXPLOSIÓN CRÍTICA)
-- ============================================================================

local function CookMeth(entity)
    if isCookingMeth then return end
    local ped = cache.ped

    -- Validar ingredientes requeridos según la receta
    local missingItems = {}
    local recipe = Config.Meth.Recipe or {
        { item = 'pseudoephedrine',   count = 2, label = 'Pseudoefedrina' },
        { item = 'hydrochloric_acid', count = 1, label = 'Ácido Clorhídrico' },
        { item = 'liquid_acetone',     count = 1, label = 'Acetona Industrial' },
        { item = 'empty_baggies',      count = 5, label = 'Bolsitas Herméticas' }
    }

    local recipeSummary = ""
    for _, ing in ipairs(recipe) do
        local count = exports.ox_inventory:Search('count', ing.item) or 0
        local statusIcon = (count >= ing.count) and "✅" or "❌"
        recipeSummary = recipeSummary .. string.format("\n- %s **%dx %s** — _En posesión: %d_", statusIcon, ing.count, ing.label or ing.item, count)
        if count < ing.count then
            table.insert(missingItems, string.format("%dx %s", ing.count - count, ing.label or ing.item))
        end
    end

    if #missingItems > 0 then
        lib.alertDialog({
            header = '🧪 SÍNTESIS DE METANFETAMINA',
            content = string.format("### 📦 REACTIVOS REQUERIDOS:\n%s\n\n> ⚠️ **FALTAN INGREDIENTES:**\n> Consigue los precursores y bolsitas faltantes antes de iniciar la reacción térmica.", recipeSummary),
            centered = true,
            cancel = false,
            labels = { confirm = 'ENTENDIDO' }
        })
        return
    end

    local confirm = lib.alertDialog({
        header = '🧪 SÍNTESIS DE METANFETAMINA',
        content = string.format("### 📦 FÓRMULA QUÍMICA PREPARADA:\n%s\n\n> ⚠️ **ADVERTENCIA DE SEGURIDAD EXTREMA**\n> La reacción química es sumamente inestable. Un fallo en el control térmico provocará una **explosión letal inmediata** y notificará al despacho policial (**10-90**).", recipeSummary),
        centered = true,
        cancel = true,
        labels = { confirm = 'COMENZAR SÍNTESIS', cancel = 'ABORTAR' }
    })

    if confirm ~= 'confirm' then return end

    isCookingMeth = true

    -- Retirar ingredientes antes de comenzar el proceso
    lib.callback('aura_gangs:server:startMethCook', false, function(canStart, errorMsg)
        if not canStart then
            isCookingMeth = false
            lib.notify({ title = 'Laboratorio', description = errorMsg or 'No tienes los ingredientes requeridos.', type = 'error' })
            return
        end

        local coords = GetEntityCoords(ped)

        -- Animación de control de síntesis química
        lib.requestAnimDict('anim@amb@business@meth@meth_monitoring_cooking@cooking@')
        TaskPlayAnim(ped, 'anim@amb@business@meth@meth_monitoring_cooking@cooking@', 'chemical_pour_long_cooker', 3.0, 3.0, -1, 49, 0, false, false, false)

        local success = false
        if GetResourceState('aura_minigames') == 'started' then
            success = exports.aura_minigames:ChemicalReactor({ duration = 18, criticalTimeLimit = 3.0 })
        else
            local step1 = lib.skillCheck({'medium', 'medium'}, {'w', 'a', 's', 'd'})
            local step2 = step1 and lib.skillCheck({'hard'}, {'w', 'a', 's', 'd'})
            local step3 = step2 and lib.skillCheck({'hard', 'hard'}, {'w', 'a', 's', 'd'})
            success = (step3 == true)
        end

        ClearPedTasks(ped)
        isCookingMeth = false

        if not success then
            -- DISPARAR EXPLOSIÓN LETAL INMEDIATA
            TriggerServerEvent('aura_gangs:server:methExplosion', coords)
            return
        end

        -- Síntesis completada con éxito
        lib.callback('aura_gangs:server:finishMethCook', false, function(ok, message)
            if ok then
                PlaySoundFrontend(-1, "COLLECTED", "HUD_AWARDS", true)
                lib.notify({
                    title = 'Laboratorio Químico',
                    description = message,
                    type = 'success',
                    duration = 8000
                })
            else
                lib.notify({ title = 'Laboratorio', description = message, type = 'error' })
            end
        end)
    end)
end

-- ============================================================================
-- 3. REFINADO Y EMPAQUETADO DE COCAÍNA (COCAINE LAB)
-- ============================================================================

local isProcessingCoke = false

local function ProcessCocaine(entity)
    if isProcessingCoke then return end
    local ped = cache.ped

    -- Validar ingredientes requeridos según la receta
    local missingItems = {}
    local recipe = (Config.Cocaine and Config.Cocaine.Recipe) or {
        { item = 'coca_leaf',     count = 10, label = 'Hojas de Coca' },
        { item = 'sulfuric_acid',  count = 1,  label = 'Ácido Sulfúrico' },
        { item = 'baking_soda',    count = 2,  label = 'Bicarbonato de Sodio' },
        { item = 'empty_baggies',  count = 5,  label = 'Bolsitas Herméticas' }
    }

    local recipeSummary = ""
    for _, ing in ipairs(recipe) do
        local count = exports.ox_inventory:Search('count', ing.item) or 0
        local statusIcon = (count >= ing.count) and "✅" or "❌"
        recipeSummary = recipeSummary .. string.format("\n- %s **%dx %s** — _En posesión: %d_", statusIcon, ing.count, ing.label or ing.item, count)
        if count < ing.count then
            table.insert(missingItems, string.format("%dx %s", ing.count - count, ing.label or ing.item))
        end
    end

    if #missingItems > 0 then
        lib.alertDialog({
            header = '🌿 REFINADO DE COCAÍNA',
            content = string.format("### 📦 MATERIAS PRIMAS REQUERIDAS:\n%s\n\n> ⚠️ **FALTAN INSUMOS:**\n> Consigue las hojas de coca, ácidos y neutralizantes requeridos antes de iniciar la maceración.", recipeSummary),
            centered = true,
            cancel = false,
            labels = { confirm = 'ENTENDIDO' }
        })
        return
    end

    local confirm = lib.alertDialog({
        header = '🌿 REFINADO DE COCAÍNA',
        content = string.format("### 📦 FÓRMULA QUÍMICA DE REFINADO:\n%s\n\n> ⚠️ **ADVERTENCIA DE SEGURIDAD EXTREMA**\n> La manipulación de ácidos minerales altamente corrosivos y solventes inflamables requiere máxima precisión. Un fallo en el filtrado provocará un **derrame tóxico e incendio químico**, alertando al despacho policial (**10-90**).", recipeSummary),
        centered = true,
        cancel = true,
        labels = { confirm = 'COMENZAR REFINADO', cancel = 'ABORTAR' }
    })

    if confirm ~= 'confirm' then return end

    isProcessingCoke = true

    -- Retirar ingredientes antes de comenzar el proceso
    lib.callback('aura_gangs:server:startCokeProcess', false, function(canStart, errorMsg)
        if not canStart then
            isProcessingCoke = false
            lib.notify({ title = 'Laboratorio Químico', description = errorMsg or 'No tienes los ingredientes requeridos en tus bolsillos.', type = 'error' })
            return
        end

        local coords = GetEntityCoords(ped)

        -- Animación de corte / maceración / empaquetado de cocaína
        lib.requestAnimDict('anim@amb@business@coc@coc_unpack_cut_left@')
        TaskPlayAnim(ped, 'anim@amb@business@coc@coc_unpack_cut_left@', 'coke_cut_v1_coccutter', 3.0, 3.0, -1, 49, 0, false, false, false)

        local success = false
        if GetResourceState('aura_minigames') == 'started' then
            success = exports.aura_minigames:ChemicalReactor({ duration = 18, criticalTimeLimit = 3.0 })
        else
            local step1 = lib.skillCheck({'medium', 'medium'}, {'w', 'a', 's', 'd'})
            local step2 = step1 and lib.skillCheck({'hard'}, {'w', 'a', 's', 'd'})
            local step3 = step2 and lib.skillCheck({'hard', 'hard'}, {'w', 'a', 's', 'd'})
            success = (step3 == true)
        end

        ClearPedTasks(ped)
        isProcessingCoke = false

        if not success then
            -- DISPARAR DERRAME / EXPLOSIÓN Y ALERTA POLICIAL
            TriggerServerEvent('aura_gangs:server:cokeChemicalSpill', coords)
            return
        end

        -- Refinado completado con éxito
        lib.callback('aura_gangs:server:finishCokeProcess', false, function(ok, message)
            if ok then
                PlaySoundFrontend(-1, "COLLECTED", "HUD_AWARDS", true)
                lib.notify({
                    title = 'Laboratorio de Narcóticos',
                    description = message,
                    type = 'success',
                    duration = 8000
                })
            else
                lib.notify({ title = 'Laboratorio', description = message, type = 'error' })
            end
        end)
    end)
end

-- ============================================================================
-- 4. REGISTRO DE TARGETS PARA PROPS ILÍCITOS Y ZONAS DE LABORATORIO
-- ============================================================================

CreateThread(function()
    -- 1. Targets en Props de Lavadoras
    if Config.Laundry and Config.Laundry.Props then
        exports.ox_target:addModel(Config.Laundry.Props, {
            {
                name = 'aura_gangs_laundry_insert',
                icon = 'fa-solid fa-money-bill-transfer',
                label = 'Insertar Dinero Negro a Lavar',
                distance = 2.0,
                canInteract = function()
                    return IsPlayerInGang()
                end,
                onSelect = function(data)
                    InsertLaundryMoney(data.entity)
                end
            },
            {
                name = 'aura_gangs_laundry_check',
                icon = 'fa-solid fa-clock-rotate-left',
                label = 'Comprobar / Retirar Dinero Limpio',
                distance = 2.0,
                canInteract = function()
                    return IsPlayerInGang()
                end,
                onSelect = function(data)
                    CheckLaundryMachine(data.entity)
                end
            }
        })
    end

    -- 2. Zonas Fijas para Lavadoras (DefaultLocations)
    if Config.Laundry and Config.Laundry.DefaultLocations then
        for i, loc in ipairs(Config.Laundry.DefaultLocations) do
            exports.ox_target:addSphereZone({
                coords = vec3(loc.x, loc.y, loc.z),
                radius = 2.0,
                debug = Config.Debug,
                options = {
                    {
                        name = 'aura_gangs_laundry_zone_insert_' .. i,
                        icon = 'fa-solid fa-money-bill-transfer',
                        label = 'Insertar Dinero Negro a Lavar',
                        distance = 2.5,
                        canInteract = function()
                            return IsPlayerInGang()
                        end,
                        onSelect = function()
                            InsertLaundryMoney(nil, loc)
                        end
                    },
                    {
                        name = 'aura_gangs_laundry_zone_check_' .. i,
                        icon = 'fa-solid fa-clock-rotate-left',
                        label = 'Comprobar / Retirar Dinero Limpio',
                        distance = 2.5,
                        canInteract = function()
                            return IsPlayerInGang()
                        end,
                        onSelect = function()
                            CheckLaundryMachine(nil, loc)
                        end
                    }
                }
            })
        end
    end

    -- ============================================================================
    -- 3. ESTACIONES Y PROPS DE LABORATORIO DE DROGAS (METANFETAMINA & COCAÍNA)
    -- ============================================================================

    -- Menú unificado de opciones de producción clandestina
    local drugManufacturingOptions = {
        {
            name = 'aura_gangs_meth_cook',
            icon = 'fa-solid fa-flask-vial',
            label = 'Sintetizar Metanfetamina Cristalina',
            distance = 2.5,
            canInteract = function()
                return IsPlayerInGang()
            end,
            onSelect = function(data)
                CookMeth(data and data.entity)
            end
        },
        {
            name = 'aura_gangs_coke_process',
            icon = 'fa-solid fa-mortar-pestle',
            label = 'Refinar y Empaquetar Cocaína',
            distance = 2.5,
            canInteract = function()
                return IsPlayerInGang()
            end,
            onSelect = function(data)
                ProcessCocaine(data and data.entity)
            end
        }
    }

    -- Props de Mesas de Laboratorio Químico y Narcóticos
    local labProps = {}
    if Config.Meth and Config.Meth.Props then
        for _, p in ipairs(Config.Meth.Props) do table.insert(labProps, p) end
    end
    if Config.Cocaine and Config.Cocaine.Props then
        for _, p in ipairs(Config.Cocaine.Props) do table.insert(labProps, p) end
    end

    if #labProps > 0 then
        exports.ox_target:addModel(labProps, drugManufacturingOptions)
    end

    -- Zonas Fijas Unificadas de Laboratorio (Deduplicación de coordenadas)
    local uniqueLabCoords = {}
    local registeredCoords = {}

    local function addLabCoordinate(loc)
        if not loc then return end
        local key = string.format("%.2f_%.2f_%.2f", loc.x, loc.y, loc.z)
        if not registeredCoords[key] then
            registeredCoords[key] = true
            table.insert(uniqueLabCoords, loc)
        end
    end

    if Config.Meth and Config.Meth.LabLocations then
        for _, loc in ipairs(Config.Meth.LabLocations) do
            addLabCoordinate(loc)
        end
    end

    if Config.Cocaine and Config.Cocaine.LabLocations then
        for _, loc in ipairs(Config.Cocaine.LabLocations) do
            addLabCoordinate(loc)
        end
    end

    for i, loc in ipairs(uniqueLabCoords) do
        exports.ox_target:addSphereZone({
            coords = vec3(loc.x, loc.y, loc.z),
            radius = 2.2,
            debug = Config.Debug,
            options = {
                {
                    name = 'aura_gangs_unified_meth_zone_' .. i,
                    icon = 'fa-solid fa-flask-vial',
                    label = 'Sintetizar Metanfetamina Cristalina',
                    distance = 2.5,
                    canInteract = function()
                        return IsPlayerInGang()
                    end,
                    onSelect = function()
                        CookMeth(nil)
                    end
                },
                {
                    name = 'aura_gangs_unified_coke_zone_' .. i,
                    icon = 'fa-solid fa-mortar-pestle',
                    label = 'Refinar y Empaquetar Cocaína',
                    distance = 2.5,
                    canInteract = function()
                        return IsPlayerInGang()
                    end,
                    onSelect = function()
                        ProcessCocaine(nil)
                    end
                }
            }
        })
    end
end)

-- ============================================================================
-- 4. SINCRONIZACIÓN DE EXPLOSIÓN LETAL
-- ============================================================================

RegisterNetEvent('aura_gangs:client:syncExplosion', function(coords)
    if not coords then return end
    -- Explosión química violenta de alta intensidad
    AddExplosion(coords.x, coords.y, coords.z, 2, 10.0, true, false, 1.2)
    AddExplosion(coords.x, coords.y, coords.z + 0.5, 3, 5.0, true, false, 1.0)
end)

