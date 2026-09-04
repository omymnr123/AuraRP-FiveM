-- ============================================================================
-- AURA GANGS: SERVER ILLEGAL ACTIVITIES ENGINE
-- Laundry Database Persistence & Meth Cooking Safety Engine with Police Alerts
-- ============================================================================

-- Comprobación automática de persistencia en la base de datos
CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `aura_gang_laundry` (
          `id` INT(11) NOT NULL AUTO_INCREMENT,
          `citizenid` VARCHAR(50) NOT NULL,
          `gang` VARCHAR(50) NOT NULL,
          `machine_id` VARCHAR(50) NOT NULL,
          `black_money_input` BIGINT(20) NOT NULL,
          `clean_money_output` BIGINT(20) NOT NULL,
          `tax_fee` BIGINT(20) NOT NULL DEFAULT 0,
          `ready_at` TIMESTAMP NOT NULL,
          `is_collected` TINYINT(1) NOT NULL DEFAULT 0,
          `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
          PRIMARY KEY (`id`),
          KEY `idx_laundry_machine` (`machine_id`),
          KEY `idx_laundry_citizen` (`citizenid`),
          KEY `idx_laundry_ready` (`ready_at`, `is_collected`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
end)

-- ============================================================================
-- 1. BLANQUEO DE CAPITALES (LAVADORAS CLANDESTINAS)
-- ============================================================================

--- Insertar dinero negro en una lavadora
lib.callback.register('aura_gangs:server:insertLaundryMoney', function(source, machineId, amount)
    local src = source
    if not src or not machineId or not amount or amount < Config.Laundry.minAmount then
        return false, "Importe de blanqueo no válido."
    end

    local char = exports.aura_multichar:GetActiveCharacter(src)
    if not char then return false, "Personaje no identificado." end

    -- Comprobar si la máquina ya tiene un ciclo activo sin recoger
    local active = MySQL.single.await([[
        SELECT id FROM aura_gang_laundry 
        WHERE machine_id = ? AND is_collected = 0
    ]], { machineId })

    if active then
        return false, "Esta lavadora ya tiene un ciclo de blanqueo en curso."
    end

    -- Comprobar y retirar dinero negro atómicamente
    local removed = exports.ox_inventory:RemoveItem(src, 'black_money', amount)
    if not removed then
        return false, "No dispones de suficiente dinero negro en tus bolsillos."
    end

    local tax = math.floor(amount * (Config.Laundry.taxRate or 0.20))
    local cleanOutput = amount - tax
    local gangName = char.job or "underground"

    MySQL.query.await([[
        INSERT INTO aura_gang_laundry 
        (citizenid, gang, machine_id, black_money_input, clean_money_output, tax_fee, ready_at) 
        VALUES (?, ?, ?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL ? SECOND))
    ]], { char.citizenid, gangName, machineId, amount, cleanOutput, tax, Config.Laundry.washDuration })

    return true, string.format("Has introducido $%s de dinero negro en el tambor.\nComisión de lavado (20%%): -$%s.\nObtendrás $%s limpios en 30 minutos.", lib.math.groupdigits(amount), lib.math.groupdigits(tax), lib.math.groupdigits(cleanOutput))
end)

--- Consultar el estado actual de una lavadora
lib.callback.register('aura_gangs:server:checkLaundryMachine', function(source, machineId)
    if not machineId then return { hasActiveCycle = false } end

    local row = MySQL.single.await([[
        SELECT id, clean_money_output, 
               UNIX_TIMESTAMP(ready_at) AS ready_timestamp, 
               UNIX_TIMESTAMP(NOW()) AS now_timestamp 
        FROM aura_gang_laundry 
        WHERE machine_id = ? AND is_collected = 0
        ORDER BY id DESC LIMIT 1
    ]], { machineId })

    if not row then
        return { hasActiveCycle = false }
    end

    local isReady = row.now_timestamp >= row.ready_timestamp
    local remaining = math.max(0, row.ready_timestamp - row.now_timestamp)

    return {
        hasActiveCycle = true,
        isReady = isReady,
        cleanAmount = row.clean_money_output,
        remainingSeconds = remaining
    }
end)

--- Recoger dinero limpio de una lavadora completada
lib.callback.register('aura_gangs:server:collectLaundryMoney', function(source, machineId)
    local src = source
    if not src or not machineId then return false, "Petición no válida." end

    local row = MySQL.single.await([[
        SELECT id, clean_money_output, ready_at 
        FROM aura_gang_laundry 
        WHERE machine_id = ? AND is_collected = 0 AND ready_at <= NOW()
        ORDER BY id DESC LIMIT 1
    ]], { machineId })

    if not row then
        return false, "El dinero todavía no está listo para ser retirado o ya fue recogido."
    end

    -- Marcar como recogido en la base de datos
    MySQL.update.await('UPDATE aura_gang_laundry SET is_collected = 1 WHERE id = ?', { row.id })

    -- Entrega atómica del dinero limpio (ítem 'money' de ox_inventory)
    local added = exports.ox_inventory:AddItem(src, 'money', row.clean_money_output)
    if not added then
        local ped = GetPlayerPed(src)
        exports.ox_inventory:CustomDrop('Dinero Blanqueado', {
            { 'money', row.clean_money_output }
        }, GetEntityCoords(ped))
    end

    return true, string.format("Has retirado con éxito $%s limpios de la lavadora.", lib.math.groupdigits(row.clean_money_output))
end)

-- ============================================================================
-- 2. COCINA DE METANFETAMINA (METH LAB)
-- ============================================================================

--- Iniciar cocinado y retirar ingredientes requeridos (atómico)
lib.callback.register('aura_gangs:server:startMethCook', function(source)
    local src = source
    if not src then return false, "Petición inválida." end

    local recipe = Config.Meth.Recipe
    if not recipe or #recipe == 0 then
        -- Fallback de compatibilidad
        local oldItem = Config.Meth.ingredientsItem or 'meth_ingredients'
        local removed = exports.ox_inventory:RemoveItem(src, oldItem, 1)
        return (removed == true), (removed and "OK" or "Faltan ingredientes.")
    end

    -- 1. Comprobar que el jugador tenga TODOS los reactivos antes de retirar nada
    for _, ing in ipairs(recipe) do
        local count = exports.ox_inventory:Search(src, 'count', ing.item) or 0
        if count < ing.count then
            return false, string.format("Te falta %dx %s en tus bolsillos.", (ing.count - count), ing.label or ing.item)
        end
    end

    -- 2. Retirar los ingredientes de forma atómica
    for _, ing in ipairs(recipe) do
        local removed = exports.ox_inventory:RemoveItem(src, ing.item, ing.count)
        if not removed then
            return false, string.format("Error al procesar %s.", ing.label or ing.item)
        end
    end

    return true, "Reactivos mezclados en el reactor."
end)

--- Finalizar con éxito la síntesis de metanfetamina
lib.callback.register('aura_gangs:server:finishMethCook', function(source)
    local src = source
    if not src then return false, "Error de sesión." end

    local minAmount = Config.Meth.outputMin or 4
    local maxAmount = Config.Meth.outputMax or 10
    local outputCount = math.random(minAmount, maxAmount)

    local added = exports.ox_inventory:AddItem(src, Config.Meth.outputItem or 'meth', outputCount)
    if not added then
        local ped = GetPlayerPed(src)
        exports.ox_inventory:CustomDrop('Metanfetamina Cristalina', {
            { Config.Meth.outputItem or 'meth', outputCount }
        }, GetEntityCoords(ped))
    end

    return true, string.format("¡Síntesis completada con éxito!\nHas producido +%d Bolsas de Metanfetamina Cristalina de máxima pureza (99.1%%).", outputCount)
end)

-- ============================================================================
-- 3. REFINADO Y EMPAQUETADO DE COCAÍNA (COCAINE LAB)
-- ============================================================================

--- Iniciar maceración y retirar materias primas requeridas (atómico)
lib.callback.register('aura_gangs:server:startCokeProcess', function(source)
    local src = source
    if not src then return false, "Petición inválida." end

    local recipe = Config.Cocaine and Config.Cocaine.Recipe
    if not recipe or #recipe == 0 then
        return false, "Receta de cocaína no configurada."
    end

    -- 1. Comprobar que el jugador tenga TODOS los reactivos antes de retirar nada
    for _, ing in ipairs(recipe) do
        local count = exports.ox_inventory:Search(src, 'count', ing.item) or 0
        if count < ing.count then
            return false, string.format("Te falta %dx %s en tus bolsillos.", (ing.count - count), ing.label or ing.item)
        end
    end

    -- 2. Retirar los ingredientes de forma atómica
    for _, ing in ipairs(recipe) do
        local removed = exports.ox_inventory:RemoveItem(src, ing.item, ing.count)
        if not removed then
            return false, string.format("Error al procesar %s.", ing.label or ing.item)
        end
    end

    return true, "Materias primas mezcladas en la mesa de refinado."
end)

--- Finalizar con éxito el refinado de cocaína
lib.callback.register('aura_gangs:server:finishCokeProcess', function(source)
    local src = source
    if not src then return false, "Error de sesión." end

    local minAmount = (Config.Cocaine and Config.Cocaine.outputMin) or 4
    local maxAmount = (Config.Cocaine and Config.Cocaine.outputMax) or 10
    local outputCount = math.random(minAmount, maxAmount)

    local added = exports.ox_inventory:AddItem(src, (Config.Cocaine and Config.Cocaine.outputItem) or 'cocaine', outputCount)
    if not added then
        local ped = GetPlayerPed(src)
        exports.ox_inventory:CustomDrop('Bolsas de Cocaína', {
            { (Config.Cocaine and Config.Cocaine.outputItem) or 'cocaine', outputCount }
        }, GetEntityCoords(ped))
    end

    return true, string.format("¡Refinado completado con éxito!\nHas producido +%d Bolsas de Cocaína de máxima pureza (95%%).", outputCount)
end)

-- ============================================================================
-- 4. PENALIZACIONES CRÍTICAS: EXPLOSIONES, DERRAMES Y ALERTAS POLICIALES
-- ============================================================================

RegisterNetEvent('aura_gangs:server:methExplosion', function(coords)
    local src = source
    if not src or not coords then return end

    local ped = GetPlayerPed(src)
    local actualCoords = GetEntityCoords(ped)

    -- Sincronizar explosión letal a todos los jugadores cercanos
    TriggerClientEvent('aura_gangs:client:syncExplosion', -1, actualCoords)

    -- Disparar Alerta Prioritaria de Despacho a Policía (10-90)
    pcall(function()
        if exports.aura_police and exports.aura_police.TriggerCustomDispatchAlert then
            exports.aura_police:TriggerCustomDispatchAlert({
                type = 'gunshot',
                code = '10-90',
                title = 'Explosión en Laboratorio Químico',
                description = 'Deflagración química violenta detectada. Posibles heridos y peligro de materiales tóxicos.',
                coords = actualCoords,
                street = 'Instalación Clandestina',
                zone = 'Zona de Emergencia'
            })
        end
    end)
end)

RegisterNetEvent('aura_gangs:server:cokeChemicalSpill', function(coords)
    local src = source
    if not src or not coords then return end

    local ped = GetPlayerPed(src)
    local actualCoords = GetEntityCoords(ped)

    -- Sincronizar deflagración / derrame químico
    TriggerClientEvent('aura_gangs:client:syncExplosion', -1, actualCoords)

    -- Disparar Alerta Prioritaria de Despacho a Policía (10-90)
    pcall(function()
        if exports.aura_police and exports.aura_police.TriggerCustomDispatchAlert then
            exports.aura_police:TriggerCustomDispatchAlert({
                type = 'gunshot',
                code = '10-90',
                title = 'Derrame de Ácidos en Laboratorio',
                description = 'Fuga tóxica e incendio por ácidos corrosivos en laboratorio de refinado clandestino.',
                coords = actualCoords,
                street = 'Instalación Clandestina',
                zone = 'Zona de Emergencia'
            })
        end
    end)
end)
