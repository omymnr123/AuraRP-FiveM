-- ============================================================================
-- AURA EMS: SERVER MAIN CONTROLLER
-- Resuscitation, Tourniquet Application, Stashes & Duty Management
-- ============================================================================

local function IsEmsOnDuty(source)
    local pState = Player(source).state
    return pState.job == Config.JobName and pState.job_duty == true
end
exports('IsEmsOnDuty', IsEmsOnDuty)

--- Inicialización de Base de Datos y Registro de Stashes en ox_inventory
CreateThread(function()
    -- 1. Asegurar tablas requeridas
    MySQL.query([=[
        CREATE TABLE IF NOT EXISTS `aura_medical_records` (
          `id` int(11) NOT NULL AUTO_INCREMENT,
          `citizenid` varchar(50) NOT NULL,
          `patient_name` varchar(100) NOT NULL,
          `doctor_citizenid` varchar(50) DEFAULT NULL,
          `doctor_name` varchar(100) DEFAULT 'Sistema Médico Automatizado',
          `diagnosis` text NOT NULL,
          `injuries_json` longtext NOT NULL COMMENT 'Detalle de huesos dañados y tipo de trauma',
          `vital_signs` longtext NOT NULL COMMENT 'Salud, temperatura, hambre, sed al momento del scan',
          `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
          PRIMARY KEY (`id`),
          KEY `idx_medical_citizenid` (`citizenid`),
          KEY `idx_medical_created` (`created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]=])

    MySQL.query([=[
        CREATE TABLE IF NOT EXISTS `aura_ems_radio_channels` (
          `id` int(11) NOT NULL AUTO_INCREMENT,
          `channel_index` int(11) NOT NULL,
          `label` varchar(64) NOT NULL,
          `frequency` decimal(4,1) NOT NULL,
          `color` varchar(16) NOT NULL DEFAULT '#40E0D0',
          `blip_color` int(11) NOT NULL DEFAULT 1,
          `is_encrypted` tinyint(1) NOT NULL DEFAULT 1,
          PRIMARY KEY (`id`),
          UNIQUE KEY `idx_ems_channel` (`channel_index`),
          KEY `idx_ems_freq` (`frequency`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]=])

    -- Migraciones automáticas seguras por si la tabla ya existía
    pcall(function()
        MySQL.query.await("ALTER TABLE `aura_ems_radio_channels` ADD COLUMN IF NOT EXISTS `blip_color` int(11) NOT NULL DEFAULT 1 AFTER `color`;")
        MySQL.query.await("ALTER TABLE `aura_ems_radio_channels` ADD COLUMN IF NOT EXISTS `is_encrypted` tinyint(1) NOT NULL DEFAULT 1 AFTER `blip_color`;")
    end)

    -- 2. Registrar stashes de farmacia hospitalaria en ox_inventory
    if exports.ox_inventory then
        for stationKey, stationData in pairs(Config.Stations) do
            if stationData.pharmacy and stationData.pharmacy.stashId then
                exports.ox_inventory:RegisterStash(
                    stationData.pharmacy.stashId,
                    'Farmacia Hospitalaria - ' .. (stationData.shortName or stationData.label),
                    stationData.pharmacy.slots or 50,
                    stationData.pharmacy.maxWeight or 250000,
                    false
                )
                if Config.Debug then
                    print(string.format("[AURA_EMS] Stash '%s' registrado para estación '%s'.", stationData.pharmacy.stashId, stationKey))
                end
            end
        end
    end
end)

-- ============================================================================
-- 1. REANIMACIÓN CON DESFIBRILADOR (DEA)
-- ============================================================================

lib.callback.register('aura_ems:server:resuscitatePatient', function(source, targetServerId)
    local medicSrc = source
    local targetSrc = tonumber(targetServerId)

    if not IsEmsOnDuty(medicSrc) then
        return false, "Debes ser personal médico (EMS) y estar de servicio activo."
    end

    if not targetSrc or targetSrc <= 0 or not GetPlayerPed(targetSrc) or GetPlayerPed(targetSrc) == 0 then
        return false, "Paciente no válido o fuera de alcance."
    end

    -- Validar que el paciente esté realmente en estado crítico / muerto
    local isDead = Player(targetSrc).state.isDead
    if not isDead and exports.aura_death and exports.aura_death.isPlayerDead then
        isDead = exports.aura_death:isPlayerDead(targetSrc)
    end

    if not isDead then
        return false, "El paciente no se encuentra en parada cardiorrespiratoria ni en estado crítico."
    end

    -- Validar que el médico posea el desfibrilador
    local hasDefib = false
    if exports.ox_inventory then
        hasDefib = (exports.ox_inventory:Search(medicSrc, 'count', Config.FieldOps.defib.item) or 0) > 0
    else
        hasDefib = true
    end

    if not hasDefib then
        return false, "No dispones de un Desfibrilador en tu inventario."
    end

    -- 1. Revivir en aura_death
    if exports.aura_death and exports.aura_death.revivePlayer then
        exports.aura_death:revivePlayer(targetSrc)
    else
        TriggerClientEvent('aura_death:client:revivePlayer', targetSrc)
    end

    -- 2. Restablecer daños corporales y fracturas en aura_medical
    local healthyBones = {
        head = { health = 100, injuries = {} },
        torso = { health = 100, injuries = {} },
        right_arm = { health = 100, injuries = {} },
        left_arm = { health = 100, injuries = {} },
        right_hand = { health = 100, injuries = {} },
        left_hand = { health = 100, injuries = {} },
        right_leg = { health = 100, injuries = {} },
        left_leg = { health = 100, injuries = {} },
        right_foot = { health = 100, injuries = {} },
        left_foot = { health = 100, injuries = {} }
    }
    Player(targetSrc).state:set('bone_damage', healthyBones, true)
    
    if exports.aura_medical and exports.aura_medical.SetPlayerBoneDamage then
        exports.aura_medical:SetPlayerBoneDamage(targetSrc, healthyBones)
    end
    TriggerClientEvent('aura_medical:client:resetDamage', targetSrc)

    -- 3. Aplicar agotamiento metabólico post-coma en aura_status (15% hambre/sed, 0% estamina)
    TriggerClientEvent('aura_status:client:ApplyPostComaExhaustion', targetSrc)

    -- 4. Notificaciones
    TriggerClientEvent('ox_lib:notify', targetSrc, {
        title = 'Reanimación Exitosa',
        description = 'Has sido desfibrilado con éxito. Tus fracturas y lesiones han sido estabilizadas.',
        type = 'success',
        icon = 'heart-pulse',
        duration = 7000
    })

    return true, "¡Descarga sincronizada efectiva! Signos vitales y lesiones restablecidos."
end)

-- ============================================================================
-- 2. APLICACIÓN DE TORNIQUETE TÁCTICO
-- ============================================================================

lib.callback.register('aura_ems:server:applyTourniquet', function(source, targetServerId)
    local medicSrc = source
    local targetSrc = tonumber(targetServerId)

    if not IsEmsOnDuty(medicSrc) then
        return false, "Debes ser personal médico (EMS) y estar de servicio activo."
    end

    if not targetSrc or targetSrc <= 0 or not GetPlayerPed(targetSrc) or GetPlayerPed(targetSrc) == 0 then
        return false, "Paciente no válido o no encontrado."
    end

    -- Validar que el paciente esté en estado de desangrado / coma
    local isDead = Player(targetSrc).state.isDead
    if not isDead and exports.aura_death and exports.aura_death.isPlayerDead then
        isDead = exports.aura_death:isPlayerDead(targetSrc)
    end

    if not isDead then
        return false, "El paciente no presenta hemorragias críticas activas."
    end

    if Player(targetSrc).state.bleedoutPaused then
        return false, "El paciente ya tiene un torniquete colocado (desangrado pausado)."
    end

    -- Retirar 1 torniquete del inventario del sanitario
    if exports.ox_inventory then
        local count = exports.ox_inventory:Search(medicSrc, 'count', Config.FieldOps.tourniquet.item) or 0
        if count <= 0 then
            return false, "No dispones de torniquetes tácticos en tu inventario."
        end
        exports.ox_inventory:RemoveItem(medicSrc, Config.FieldOps.tourniquet.item, 1)
    end

    -- Pausar desangrado en aura_death
    if exports.aura_death and exports.aura_death.pausePlayerBleedout then
        exports.aura_death:pausePlayerBleedout(targetSrc)
    else
        TriggerEvent('aura_death:server:pauseBleedout', targetSrc)
    end

    return true, "Torniquete táctico fijado correctamente. La hemorragia ha cesado."
end)

-- ============================================================================
-- 3. TELEMETRÍA Y DIAGNÓSTICO CLÍNICO INTEGRAL (PUENTE MULTI-RECURSO)
-- ============================================================================

lib.callback.register('aura_ems:server:getPatientDiagnosticData', function(source, targetServerId)
    local medicSrc = source
    if not IsEmsOnDuty(medicSrc) then
        return nil
    end

    local targetSrc = tonumber(targetServerId)
    if not targetSrc or targetSrc <= 0 or not GetPlayerPed(targetSrc) or GetPlayerPed(targetSrc) == 0 then
        return nil
    end

    local ped = GetPlayerPed(targetSrc)
    local pState = Player(targetSrc).state

    -- 1. Identidad del Paciente
    local patientName = "Paciente Desconocido"
    local citizenId = "HLWWIZKU"

    if exports.aura_multichar and exports.aura_multichar.GetActiveCharacter then
        local char = exports.aura_multichar:GetActiveCharacter(targetSrc)
        if char then
            patientName = (char.firstname or "") .. " " .. (char.lastname or "")
            if patientName:match("^%s*$") then patientName = char.name or GetPlayerName(targetSrc) end
            citizenId = char.citizenid or char.citizenId or citizenId
        else
            patientName = GetPlayerName(targetSrc)
        end
    else
        patientName = GetPlayerName(targetSrc)
    end

    -- 2. Estado de Coma / Muerte / Sangrado
    local isDead = pState.isDead == true
    if not isDead and exports.aura_death and exports.aura_death.isPlayerDead then
        isDead = exports.aura_death:isPlayerDead(targetSrc)
    end

    local bleedoutPaused = pState.bleedoutPaused == true

    -- 3. Daños Óseos y Traumas (aura_medical)
    local boneDamage = pState.bone_damage or {
        head = { health = 100, injuries = {} },
        torso = { health = 100, injuries = {} },
        right_arm = { health = 100, injuries = {} },
        left_arm = { health = 100, injuries = {} },
        right_hand = { health = 100, injuries = {} },
        left_hand = { health = 100, injuries = {} },
        right_leg = { health = 100, injuries = {} },
        left_leg = { health = 100, injuries = {} },
        right_foot = { health = 100, injuries = {} },
        left_foot = { health = 100, injuries = {} }
    }

    -- 4. Constantes Fisiológicas (aura_status)
    local maxHealth = GetEntityMaxHealth(ped)
    local curHealth = GetEntityHealth(ped)
    local healthPct = 0
    if maxHealth > 100 then
        healthPct = math.max(0, math.min(100, math.floor(((curHealth - 100) / (maxHealth - 100)) * 100)))
    else
        healthPct = math.max(0, math.min(100, math.floor((curHealth / maxHealth) * 100)))
    end
    if isDead then healthPct = 0 end

    local armor = math.min(100, GetPedArmour(ped))
    local hunger = pState.hunger or 100.0
    local thirst = pState.thirst or 100.0
    local stamina = isDead and 0 or 100.0

    -- 5. Termorregulación y Clima (aura_seasons)
    local bodyTemp = pState.body_temperature or (isDead and 34.8 or 36.8)
    local ambientTemp = 21.0
    if exports.aura_seasons and exports.aura_seasons.GetAmbientTemperature then
        ambientTemp = exports.aura_seasons:GetAmbientTemperature() or 21.0
    end

    -- 6. Hemodinámica y Ritmo
    local bpm = isDead and 0 or (healthPct < 40 and 125 or (healthPct < 70 and 96 or 72))
    if bodyTemp > 38.5 then bpm = bpm + 12 end
    if bodyTemp < 35.0 and not isDead then bpm = math.max(40, bpm - 15) end

    local bloodPressure = isDead and "0/0 mmHg" or (healthPct < 40 and "85/50 mmHg" or "120/80 mmHg")
    local spo2 = isDead and 40 or (healthPct < 30 and 72 or (healthPct < 70 and 88 or 98))
    local bleedingLevel = isDead and (bleedoutPaused and "Ocluida (Torniquete C-A-T)" or "Grave (Arteria Femoral)") or "Sin Hemorragias Activas"

    local hasLimbTrauma = false
    for _, b in pairs(boneDamage) do
        if b.health and b.health < 100 then
            hasLimbTrauma = true
            break
        end
    end
    if not isDead and hasLimbTrauma and bleedingLevel == "Sin Hemorragias Activas" then
        bleedingLevel = "Leve / Moderada"
    end

    return {
        targetSrc = targetSrc,
        name = patientName,
        citizenid = citizenId,
        isDead = isDead,
        glasgow = isDead and 3 or 15,
        health = healthPct,
        armor = armor,
        hunger = hunger,
        thirst = thirst,
        stamina = stamina,
        temperature = bodyTemp,
        ambientTemp = ambientTemp,
        insulation = 35.0,
        bpm = bpm,
        bloodPressure = bloodPressure,
        spo2 = spo2,
        bleedingLevel = bleedingLevel,
        hasTourniquet = bleedoutPaused,
        isTourniquetApplied = bleedoutPaused,
        boneDamage = boneDamage
    }
end)

-- ============================================================================
-- 4. GESTIÓN DE SERVICIO OFICIAL (DUTY TOGGLE)
-- ============================================================================

lib.callback.register('aura_ems:server:toggleDuty', function(source)
    local src = source
    local pState = Player(src).state

    if pState.job ~= Config.JobName then
        return false, false, "No perteneces al cuerpo médico (EMS)."
    end

    local newDuty = not pState.job_duty
    pState:set('job_duty', newDuty, true)

    -- Sincronizar en aura_multichar / characters metadata
    if exports.aura_multichar and exports.aura_multichar.GetActiveCharacter then
        local char = exports.aura_multichar:GetActiveCharacter(src)
        if char then
            char.job_duty = newDuty
            if char.metadata then char.metadata.job_duty = newDuty end
        end
    end

    -- Anuncio global en Aura Hub de alta o baja de servicio médico
    TriggerEvent('aura_hub:server:broadcastDutyAnnouncement', {
        job = Config.JobName,
        label = 'Cuerpo de Emergencias Sanitarias (EMS)',
        isDuty = newDuty,
        isPolice = false
    })

    return true, newDuty, newDuty and "Has entrado EN SERVICIO como personal médico." or "Has salido de servicio."
end)

-- ============================================================================
-- 4. DEBUG & ADMIN TESTING SUITE EVENTS
-- ============================================================================

RegisterNetEvent('aura_ems:server:debugSetEmsDuty', function()
    local src = source
    local pState = Player(src).state

    pState:set('job', Config.JobName, true)
    pState:set('job_grade', 4, true)
    pState:set('grade_label', 'Jefe de Medicina / Cirujano Jefe', true)
    pState:set('job_duty', true, true)

    if exports.aura_jobs and exports.aura_jobs.SetJob then
        exports.aura_jobs:SetJob(src, Config.JobName, 4)
    end

    if exports.ox_inventory then
        exports.ox_inventory:AddItem(src, 'desfibrilador', 1)
        exports.ox_inventory:AddItem(src, 'torniquete', 5)
    end

    TriggerClientEvent('ox_lib:notify', src, {
        title = '🛡️ Modo Administrador EMS',
        description = 'Se te ha asignado el puesto de Jefe Médico (Grado 4), servicio activo y material sanitario (Desfibrilador + Torniquetes).',
        type = 'success',
        icon = 'user-doctor',
        duration = 7000
    })
end)

RegisterNetEvent('aura_ems:server:debugSimulateEmergency', function(coords, street, zone)
    local src = source
    local callCoords = coords or GetEntityCoords(GetPlayerPed(src))
    
    TriggerEvent('aura_ems:server:reportComaEmergency', {
        src = src,
        coords = callCoords,
        citizenid = 'DUMMY_TEST_' .. math.random(1000, 9999),
        deathReason = 'Parada Cardiorrespiratoria por Trauma (Simulación de Prueba)'
    })

    TriggerClientEvent('ox_lib:notify', src, {
        title = '🚨 Simulación 911 / EMS',
        description = 'Alerta de emergencia médica emitida al sistema de despacho y MDT.',
        type = 'inform',
        icon = 'truck-medical',
        duration = 5000
    })
end)

RegisterNetEvent('aura_ems:server:consumeTestItem', function(itemName)
    local src = source
    if itemName ~= 'torniquete' then return end
    if exports.ox_inventory then
        exports.ox_inventory:RemoveItem(src, itemName, 1)
    end
end)

-- ============================================================================
-- 5. SINCRONIZACIÓN DE TRANSPORTE DE PACIENTES Y CAMILLAS
-- ============================================================================

RegisterNetEvent('aura_ems:server:carryTarget', function(targetSrc)
    local medicSrc = source
    if not IsEmsOnDuty(medicSrc) then return end

    local target = tonumber(targetSrc)
    if not target or target <= 0 or not GetPlayerPed(target) or GetPlayerPed(target) == 0 then return end

    Player(target).state:set('isCarried', true, true)
    Player(medicSrc).state:set('isCarrying', true, true)

    TriggerClientEvent('aura_ems:client:getCarried', target, medicSrc)
end)

RegisterNetEvent('aura_ems:server:stopCarryTarget', function(targetSrc)
    local medicSrc = source
    local target = tonumber(targetSrc)
    if target and target > 0 and GetPlayerPed(target) and GetPlayerPed(target) ~= 0 then
        Player(target).state:set('isCarried', false, true)
        TriggerClientEvent('aura_ems:client:getReleased', target)
    end
    Player(medicSrc).state:set('isCarrying', false, true)
end)

RegisterNetEvent('aura_ems:server:putInAmbulance', function(vehNet, targetSrc, seatIndex)
    local medicSrc = source
    if not IsEmsOnDuty(medicSrc) then return end

    local target = tonumber(targetSrc)
    if not target or target <= 0 or not GetPlayerPed(target) or GetPlayerPed(target) == 0 then return end

    Player(target).state:set('isCarried', false, true)
    TriggerClientEvent('aura_ems:client:putInAmbulanceSeat', target, vehNet, seatIndex or 1)
end)

RegisterNetEvent('aura_ems:server:outOfAmbulance', function(vehNet, targetSrc)
    local medicSrc = source
    if not IsEmsOnDuty(medicSrc) then return end

    local target = tonumber(targetSrc)
    if not target or target <= 0 or not GetPlayerPed(target) or GetPlayerPed(target) == 0 then return end

    TriggerClientEvent('aura_ems:client:leaveAmbulanceSeat', target)
end)



