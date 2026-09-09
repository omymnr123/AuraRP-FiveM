-- ============================================================================
-- AURA MEDICAL: SERVER P2P ROUTING & SYNC CONTROLLER (PHASE 11)
-- ============================================================================

local Sessions = {}

local function IsEmsOnDuty(source)
    local pState = Player(source).state
    return pState.job == Config.JobName and pState.job_duty == true
end

local ValidZones = {
    head = true, torso = true,
    right_arm = true, left_arm = true,
    right_hand = true, left_hand = true,
    right_leg = true, left_leg = true,
    right_foot = true, left_foot = true
}

local function CountRemainingInjuries(injuriesTable)
    if not injuriesTable or type(injuriesTable) ~= "table" then return 0 end
    local count = 0
    for zoneKey, list in pairs(injuriesTable) do
        if ValidZones[zoneKey] and type(list) == "table" then
            count = count + #list
        end
    end
    return count
end

-- ============================================================================
-- 1. SOLICITUD DE TELEMETRÍA (MÉDICO -> PACIENTE)
-- ============================================================================

RegisterNetEvent('aura_medical:server:requestPatientTelemetry', function(targetServerId)
    local medicSrc = source
    local targetSrc = tonumber(targetServerId)

    if not IsEmsOnDuty(medicSrc) then
        TriggerClientEvent('ox_lib:notify', medicSrc, {
            title = 'Acceso Denegado',
            description = 'Debes estar de servicio como personal médico (EMS).',
            type = 'error'
        })
        return
    end

    if not targetSrc or targetSrc <= 0 or not GetPlayerPed(targetSrc) or GetPlayerPed(targetSrc) == 0 then
        TriggerClientEvent('ox_lib:notify', medicSrc, {
            title = 'Error de Telemetría',
            description = 'El paciente no se encuentra disponible.',
            type = 'error'
        })
        return
    end

    local isDead = Player(targetSrc).state.isDead == true
    local initialBpm = isDead and 40 or 75

    Sessions[targetSrc] = {
        medicSrc = medicSrc,
        patientSrc = targetSrc,
        status = 'waiting_patient',
        bpm = initialBpm,
        injuries = {},
        history = {},
        createdAt = os.time()
    }

    -- Abrir interfaz de selección de daños en el cliente del paciente
    TriggerClientEvent('aura_medical:client:openPatientInput', targetSrc, medicSrc, initialBpm)
end)

-- ============================================================================
-- 2. ENVÍO DE DIAGNÓSTICO (PACIENTE -> MÉDICO)
-- ============================================================================

RegisterNetEvent('aura_medical:server:sendDiagnosisToMedic', function(payload)
    local patientSrc = source
    if not payload or not payload.medicSrc then return end

    local medicSrc = tonumber(payload.medicSrc)
    if not medicSrc or not GetPlayerPed(medicSrc) or GetPlayerPed(medicSrc) == 0 then
        TriggerClientEvent('ox_lib:notify', patientSrc, {
            title = 'Error de Conexión',
            description = 'El médico actuante no está disponible.',
            type = 'error'
        })
        return
    end

    local injuries = payload.injuries or {}
    local bpm = tonumber(payload.bpm) or 75
    local isMale = payload.isMale ~= false

    Sessions[patientSrc] = {
        medicSrc = medicSrc,
        patientSrc = patientSrc,
        status = 'in_treatment',
        isMale = isMale,
        patientName = payload.patientName or GetPlayerName(patientSrc),
        bpm = bpm,
        injuries = injuries,
        history = {},
        createdAt = os.time()
    }

    -- Convertir formato para compatibilidad con StateBag de huesos (10 zonas)
    local boneDamageMap = {
        head = { health = (injuries.head and #injuries.head > 0) and 40 or 100, injuries = injuries.head or {} },
        torso = { health = (injuries.torso and #injuries.torso > 0) and 40 or 100, injuries = injuries.torso or {} },
        right_arm = { health = (injuries.right_arm and #injuries.right_arm > 0) and 50 or 100, injuries = injuries.right_arm or {} },
        left_arm = { health = (injuries.left_arm and #injuries.left_arm > 0) and 50 or 100, injuries = injuries.left_arm or {} },
        right_hand = { health = (injuries.right_hand and #injuries.right_hand > 0) and 50 or 100, injuries = injuries.right_hand or {} },
        left_hand = { health = (injuries.left_hand and #injuries.left_hand > 0) and 50 or 100, injuries = injuries.left_hand or {} },
        right_leg = { health = (injuries.right_leg and #injuries.right_leg > 0) and 40 or 100, injuries = injuries.right_leg or {} },
        left_leg = { health = (injuries.left_leg and #injuries.left_leg > 0) and 40 or 100, injuries = injuries.left_leg or {} },
        right_foot = { health = (injuries.right_foot and #injuries.right_foot > 0) and 50 or 100, injuries = injuries.right_foot or {} },
        left_foot = { health = (injuries.left_foot and #injuries.left_foot > 0) and 50 or 100, injuries = injuries.left_foot or {} }
    }
    Player(patientSrc).state:set('bone_damage', boneDamageMap, true)

    -- Abrir pantalla de tratamiento en el cliente del médico
    TriggerClientEvent('aura_medical:client:openEmsTreatment', medicSrc, {
        patientSrc = patientSrc,
        medicSrc = medicSrc,
        isMale = isMale,
        patientName = payload.patientName or GetPlayerName(patientSrc),
        bpm = bpm,
        injuries = injuries
    })
end)

-- ============================================================================
-- 2.5 SESIONES SIMULADAS DE PRUEBA / DUMMIES (ADMIN TEST SUITE)
-- ============================================================================

RegisterNetEvent('aura_medical:server:startDummySession', function(payload)
    local medicSrc = source
    if not payload or not payload.dummyId then return end

    local dummyKey = "DUMMY_" .. tostring(payload.dummyId)
    local injuries = payload.injuries or {}
    local bpm = tonumber(payload.bpm) or 75
    local isMale = payload.isMale ~= false

    Sessions[dummyKey] = {
        medicSrc = medicSrc,
        patientSrc = dummyKey,
        isDummy = true,
        status = 'in_treatment',
        isMale = isMale,
        patientName = payload.patientName or ("Paciente Dummy #" .. payload.dummyId),
        bpm = bpm,
        injuries = injuries,
        history = {},
        createdAt = os.time()
    }

    TriggerClientEvent('aura_medical:client:openEmsTreatment', medicSrc, {
        patientSrc = dummyKey,
        medicSrc = medicSrc,
        isMale = isMale,
        patientName = payload.patientName or ("Paciente Dummy #" .. payload.dummyId),
        bpm = bpm,
        injuries = injuries
    })
end)

-- ============================================================================
-- 3. APLICACIÓN DE TRATAMIENTO EN TIEMPO REAL (MÉDICO -> AMBOS)
-- ============================================================================

RegisterNetEvent('aura_medical:server:applyTreatment', function(data)
    local medicSrc = source
    if not data or not data.patientSrc or not data.zone or not data.injuryId then return end

    local patientKey = tonumber(data.patientSrc) or tostring(data.patientSrc)
    local session = Sessions[patientKey]
    if not session or session.medicSrc ~= medicSrc then return end

    local zone = tostring(data.zone)
    local injuryId = tostring(data.injuryId)

    if session.injuries[zone] and type(session.injuries[zone]) == "table" then
        local newZoneList = {}
        local found = false
        for _, inj in ipairs(session.injuries[zone]) do
            if inj == injuryId and not found then
                found = true
            else
                table.insert(newZoneList, inj)
            end
        end
        session.injuries[zone] = newZoneList
    end

    local remainingInZone = session.injuries[zone] or {}
    local totalRemaining = CountRemainingInjuries(session.injuries)
    local allCured = (totalRemaining == 0)
    local isStable = allCured and (session.bpm >= Config.StableBpmRange.min and session.bpm <= Config.StableBpmRange.max)

    table.insert(session.history, {
        type = 'treatment',
        zone = zone,
        injuryId = injuryId,
        time = os.time()
    })

    local syncPayload = {
        zone = zone,
        injuryId = injuryId,
        remainingInjuries = remainingInZone,
        allInjuries = session.injuries,
        allCured = allCured,
        isStable = isStable,
        bpm = session.bpm,
        medicName = GetPlayerName(medicSrc)
    }

    -- Sincronizar en ambas pantallas
    TriggerClientEvent('aura_medical:client:syncTreatmentApplied', medicSrc, syncPayload)
    if type(patientKey) == "number" and patientKey > 0 then
        TriggerClientEvent('aura_medical:client:syncTreatmentApplied', patientKey, syncPayload)
    end
end)

-- ============================================================================
-- 4. AJUSTE DE FRECUENCIA CARDÍACA / FARMACOLOGÍA (BPM CONTROL)
-- ============================================================================

RegisterNetEvent('aura_medical:server:adjustBpm', function(data)
    local medicSrc = source
    if not data or not data.patientSrc or not data.medication then return end

    local patientKey = tonumber(data.patientSrc) or tostring(data.patientSrc)
    local session = Sessions[patientKey]
    if not session or session.medicSrc ~= medicSrc then return end

    local medKey = tostring(data.medication)
    local medConfig = Config.Medications[medKey]
    if not medConfig then return end

    local curBpm = session.bpm or 75
    local newBpm = curBpm

    if medKey == 'saline' then
        if curBpm > 75 then
            newBpm = math.max(75, curBpm - 15)
        elseif curBpm < 75 then
            newBpm = math.min(75, curBpm + 15)
        end
    else
        newBpm = math.max(0, math.min(220, curBpm + medConfig.bpmDelta))
    end

    session.bpm = newBpm
    local totalRemaining = CountRemainingInjuries(session.injuries)
    local allCured = (totalRemaining == 0)
    local isStable = allCured and (newBpm >= Config.StableBpmRange.min and newBpm <= Config.StableBpmRange.max)

    table.insert(session.history, {
        type = 'medication',
        medication = medKey,
        label = medConfig.label,
        bpmResult = newBpm,
        time = os.time()
    })

    local syncPayload = {
        bpm = newBpm,
        medicationLabel = medConfig.label,
        allCured = allCured,
        isStable = isStable
    }

    TriggerClientEvent('aura_medical:client:syncBpmUpdated', medicSrc, syncPayload)
    if type(patientKey) == "number" and patientKey > 0 then
        TriggerClientEvent('aura_medical:client:syncBpmUpdated', patientKey, syncPayload)
    end
end)

-- ============================================================================
-- 5. PROCEDIMIENTOS FINALES: TORNIQUETE Y DESFIBRILADOR (DEA)
-- ============================================================================

RegisterNetEvent('aura_medical:server:applyTourniquetFinal', function(data)
    local medicSrc = source
    if not data or not data.patientSrc then return end

    local patientKey = tonumber(data.patientSrc) or tostring(data.patientSrc)
    local session = Sessions[patientKey]
    if not session or session.medicSrc ~= medicSrc then return end

    -- Retirar ítem torniquete del inventario del médico
    if exports.ox_inventory then
        local count = exports.ox_inventory:Search(medicSrc, 'count', Config.FinalProcedures.tourniquet.item) or 0
        if count <= 0 then
            TriggerClientEvent('ox_lib:notify', medicSrc, {
                title = 'Material Insuficiente',
                description = 'No tienes torniquetes en tu inventario.',
                type = 'error'
            })
            return
        end
        exports.ox_inventory:RemoveItem(medicSrc, Config.FinalProcedures.tourniquet.item, 1)
    end

    -- Pausar desangrado en aura_death si es jugador real
    if type(patientKey) == "number" and patientKey > 0 then
        if exports.aura_death and exports.aura_death.pausePlayerBleedout then
            exports.aura_death:pausePlayerBleedout(patientKey)
        else
            TriggerEvent('aura_death:server:pauseBleedout', patientKey)
        end
        TriggerClientEvent('ox_lib:notify', patientKey, {
            title = 'Torniquete Aplicado',
            description = 'El médico ha colocado un torniquete táctico. La pérdida de sangre se ha detenido.',
            type = 'inform',
            icon = 'bandage'
        })
    end

    TriggerClientEvent('ox_lib:notify', medicSrc, {
        title = 'Torniquete Fijado',
        description = 'Has aplicado el torniquete táctico. La hemorragia ha sido ocluida.',
        type = 'success',
        icon = 'bandage'
    })
end)

RegisterNetEvent('aura_medical:server:useDefibFinal', function(data)
    local medicSrc = source
    if not data or not data.patientSrc then return end

    local patientKey = tonumber(data.patientSrc) or tostring(data.patientSrc)
    local session = Sessions[patientKey]
    if not session or session.medicSrc ~= medicSrc then return end

    -- Validar que no queden lesiones activas y que el pulso esté estabilizado
    local totalRemaining = CountRemainingInjuries(session.injuries)
    if totalRemaining > 0 then
        TriggerClientEvent('ox_lib:notify', medicSrc, {
            title = 'Procedimiento Bloqueado',
            description = 'Aún quedan heridas abiertas o traumatismos sin tratar.',
            type = 'error'
        })
        return
    end

    -- Al aplicar el DEA, se normaliza el ritmo cardíaco a ritmo sinusal (75 BPM)
    if not session.bpm or session.bpm < Config.StableBpmRange.min or session.bpm > Config.StableBpmRange.max then
        session.bpm = 75
    end

    -- Si es jugador real
    if type(patientKey) == "number" and patientKey > 0 then
        -- 1. Reanimar en aura_death
        if exports.aura_death and exports.aura_death.revivePlayer then
            exports.aura_death:revivePlayer(patientKey)
        else
            TriggerClientEvent('aura_death:client:revivePlayer', patientKey)
        end

        -- 2. Restablecer daños corporales en aura_medical y statebag
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
        Player(patientKey).state:set('bone_damage', healthyBones, true)
        TriggerClientEvent('aura_medical:client:resetDamage', patientKey)

        -- 3. Aplicar agotamiento en aura_status
        TriggerClientEvent('aura_status:client:ApplyPostComaExhaustion', patientKey)

        TriggerClientEvent('ox_lib:notify', patientKey, {
            title = '⚡ Signos Vitales Restablecidos',
            description = 'Has sido reanimado con éxito por el personal médico. Tus lesiones han cicatrizado.',
            type = 'success',
            icon = 'heart-pulse',
            duration = 8000
        })

        TriggerClientEvent('aura_medical:client:closeMedicalUI', patientKey)
    else
        -- Es un paciente Dummy de pruebas o NPC
        TriggerClientEvent('aura_medical:client:reviveDummy', -1, patientKey)
    end

    -- 4. Persistir registro clínico en Base de Datos
    local citizenId = type(patientKey) == "number" and ("PACIENTE_" .. patientKey) or "DUMMY_TEST"
    local patientName = session.patientName or "Paciente"
    local doctorCitizenId = "MEDIC_" .. medicSrc
    local doctorName = GetPlayerName(medicSrc)
    if exports.aura_multichar and exports.aura_multichar.GetActiveCharacter then
        local dChar = exports.aura_multichar:GetActiveCharacter(medicSrc)
        if dChar then
            doctorCitizenId = dChar.citizenid or dChar.citizenId or doctorCitizenId
            doctorName = (dChar.firstname or "") .. " " .. (dChar.lastname or "")
        end
    end

    pcall(function()
        MySQL.insert([=[
            INSERT INTO `aura_medical_records` 
            (`citizenid`, `patient_name`, `doctor_citizenid`, `doctor_name`, `diagnosis`, `injuries_json`, `treatments_json`, `vital_signs`, `outcome`)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]=], {
            citizenId,
            patientName,
            doctorCitizenId,
            doctorName,
            'Protocolo Completo de Telemetría Quirúrgica y Desfibrilación Sincronizada P2P',
            json.encode(session.injuries or {}),
            json.encode(session.history or {}),
            string.format("BPM Final: %d | Ritmo Sinusal Estable", session.bpm),
            'Reanimado y Estabilizado'
        })
    end)

    -- 5. Cerrar interface NUI del médico con éxito
    TriggerClientEvent('aura_medical:client:closeMedicalUI', medicSrc)

    TriggerClientEvent('ox_lib:notify', medicSrc, {
        title = '⚡ Reanimación Exitosa',
        description = '¡Descarga efectiva! El paciente ha recuperado el pulso y todas sus lesiones han sido curadas.',
        type = 'success',
        icon = 'heart-pulse',
        duration = 8000
    })

    Sessions[patientKey] = nil
end)

-- ============================================================================
-- 6. CANCELACIÓN Y CIERRE DE SESIONES
-- ============================================================================

RegisterNetEvent('aura_medical:server:cancelTelemetry', function(targetSrc)
    local target = tonumber(targetSrc)
    if target and target > 0 then
        TriggerClientEvent('aura_medical:client:closeMedicalUI', target)
    end
end)

RegisterNetEvent('aura_medical:server:closeSession', function(patientSrc)
    local pSrc = tonumber(patientSrc)
    if pSrc and Sessions[pSrc] then
        local mSrc = Sessions[pSrc].medicSrc
        TriggerClientEvent('aura_medical:client:closeMedicalUI', pSrc)
        if mSrc and mSrc > 0 then
            TriggerClientEvent('aura_medical:client:closeMedicalUI', mSrc)
        end
        Sessions[pSrc] = nil
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    if Sessions[src] then
        local mSrc = Sessions[src].medicSrc
        if mSrc and mSrc > 0 then
            TriggerClientEvent('aura_medical:client:closeMedicalUI', mSrc)
        end
        Sessions[src] = nil
    end

    for pSrc, sess in pairs(Sessions) do
        if sess.medicSrc == src then
            TriggerClientEvent('aura_medical:client:closeMedicalUI', pSrc)
            Sessions[pSrc] = nil
        end
    end
end)
