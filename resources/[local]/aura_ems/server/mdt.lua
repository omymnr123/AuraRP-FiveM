-- ============================================================================
-- AURA EMS: SERVER MEDICAL TABLET & MDT CONTROLLER
-- Medical Records Lookup, Clinical Diagnoses & Chief Roster Management
-- ============================================================================

local function IsEmsBoss(source)
    local pState = Player(source).state
    return pState.job == Config.JobName and (pState.job_grade or 0) >= (Config.BossGrade or 4)
end

--- Resumen general del MDT Médico
lib.callback.register('aura_ems:server:getMdtOverview', function(source)
    local src = source
    local pState = Player(src).state
    if pState.job ~= Config.JobName then return false, "Acceso denegado al MDT Médico." end

    local activeDoctors = 0
    for _, pid in ipairs(GetPlayers()) do
        local p = Player(tonumber(pid)).state
        if p and p.job == Config.JobName and p.job_duty == true then
            activeDoctors = activeDoctors + 1
        end
    end

    local totalRecords = MySQL.scalar.await('SELECT COUNT(*) FROM `aura_medical_records`') or 0
    local recentRecords = MySQL.query.await('SELECT * FROM `aura_medical_records` ORDER BY `created_at` DESC LIMIT 6') or {}

    return true, {
        activeDoctors = activeDoctors,
        totalRecords = totalRecords,
        recentRecords = recentRecords,
        jobGrade = pState.job_grade or 0,
        isBoss = (pState.job_grade or 0) >= (Config.BossGrade or 4)
    }
end)

--- Búsqueda de historiales clínicos de pacientes
lib.callback.register('aura_ems:server:searchMedicalRecords', function(source, query)
    local src = source
    local pState = Player(src).state
    if pState.job ~= Config.JobName then return false, {} end

    if not query or query:gsub("%s+", "") == "" then
        return true, MySQL.query.await('SELECT * FROM `aura_medical_records` ORDER BY `created_at` DESC LIMIT 15') or {}
    end

    local searchTerm = '%' .. query .. '%'
    local records = MySQL.query.await([[
        SELECT * FROM `aura_medical_records`
        WHERE `citizenid` LIKE ? OR `patient_name` LIKE ? OR `doctor_name` LIKE ?
        ORDER BY `created_at` DESC LIMIT 25
    ]], { searchTerm, searchTerm, searchTerm })

    return true, records or {}
end)

--- Creación de nueva ficha médica de diagnóstico
lib.callback.register('aura_ems:server:createMedicalRecord', function(source, data)
    local src = source
    local pState = Player(src).state
    if pState.job ~= Config.JobName then return false, "No perteneces al cuerpo médico." end

    if not data or not data.citizenid or not data.patientName or not data.diagnosis then
        return false, "Faltan datos obligatorios para crear el informe clínico."
    end

    local doctorName = "Médico #" .. src
    local doctorCitizen = "EMS-" .. src
    if exports.aura_core and exports.aura_core.GetPlayer then
        local p = exports.aura_core:GetPlayer(src)
        if p then
            doctorName = p.firstname .. " " .. p.lastname
            doctorCitizen = p.citizenid or doctorCitizen
        end
    end

    local injuriesJson = data.injuries and json.encode(data.injuries) or '{}'
    local vitalsJson = data.vitalSigns and json.encode(data.vitalSigns) or '{}'

    local insertId = MySQL.insert.await([[
        INSERT INTO `aura_medical_records` (`citizenid`, `patient_name`, `doctor_citizenid`, `doctor_name`, `diagnosis`, `injuries_json`, `vital_signs`, `created_at`)
        VALUES (?, ?, ?, ?, ?, ?, ?, NOW())
    ]], {
        data.citizenid,
        data.patientName,
        doctorCitizen,
        doctorName,
        data.diagnosis,
        injuriesJson,
        vitalsJson
    })

    if insertId and insertId > 0 then
        return true, "Informe médico guardado en el historial clínico del paciente."
    else
        return false, "Error al guardar el informe en la base de datos."
    end
end)

-- ============================================================================
-- GESTIÓN DE PLANTILLA Y JEFATURA MÉDICA (ROSTER & HR)
-- ============================================================================

--- Obtener plantilla de sanitarios
lib.callback.register('aura_ems:server:getStaff', function(source)
    local src = source
    local pState = Player(src).state
    if pState.job ~= Config.JobName then return false, {} end

    local employees = MySQL.query.await([[
        SELECT `id`, `citizenid`, `firstname`, `lastname`, `job_grade`, `phone_number`, `last_played`
        FROM `characters`
        WHERE `job` = ?
        ORDER BY `job_grade` DESC, `lastname` ASC
    ]], { Config.JobName }) or {}

    local onlinePlayers = {}
    for _, pid in ipairs(GetPlayers()) do
        local pSrc = tonumber(pid)
        local state = Player(pSrc).state
        if state and state.citizenid then
            onlinePlayers[state.citizenid] = {
                src = pSrc,
                duty = state.job_duty == true
            }
        end
    end

    local staffList = {}
    for _, emp in ipairs(employees) do
        local isOnline = onlinePlayers[emp.citizenid] ~= nil
        local duty = isOnline and onlinePlayers[emp.citizenid].duty or false
        local onlineSrc = isOnline and onlinePlayers[emp.citizenid].src or nil

        local gradeConfig = Config.Jobs and Config.Jobs['ambulance'] and Config.Jobs['ambulance'].grades[emp.job_grade]
        local gradeLabel = gradeConfig and gradeConfig.name or ("Grado " .. emp.job_grade)
        local salary = gradeConfig and gradeConfig.salary or 800

        table.insert(staffList, {
            charId = emp.id,
            citizenid = emp.citizenid,
            name = emp.firstname .. " " .. emp.lastname,
            grade = emp.job_grade,
            gradeLabel = gradeLabel,
            salary = salary,
            phone = emp.phone_number or "N/A",
            isOnline = isOnline,
            isDuty = duty,
            src = onlineSrc
        })
    end

    return true, staffList
end)

--- Contratar a un nuevo sanitario (Grado 0)
lib.callback.register('aura_ems:server:hireStaff', function(source, targetSrc)
    local bossSrc = source
    if not IsEmsBoss(bossSrc) then
        return false, "No tienes permisos de Dirección Médica para contratar personal."
    end

    local target = tonumber(targetSrc)
    if not target or target <= 0 or not GetPlayerPed(target) or GetPlayerPed(target) == 0 then
        return false, "ID de jugador inválido o desconectado."
    end

    local targetState = Player(target).state
    targetState:set('job', Config.JobName, true)
    targetState:set('job_grade', 0, true)
    targetState:set('job_duty', false, true)

    if exports.aura_multichar and exports.aura_multichar.GetActiveCharacter then
        local char = exports.aura_multichar:GetActiveCharacter(target)
        if char then
            char.job = Config.JobName
            char.job_grade = 0
            char.job_duty = false
            MySQL.update('UPDATE `characters` SET `job` = ?, `job_grade` = 0 WHERE `id` = ?', { Config.JobName, char.id })
        end
    end

    TriggerClientEvent('ox_lib:notify', target, {
        title = 'Contratación Sanitaria',
        description = 'Has sido contratado en el Cuerpo Médico de Emergencias como Enfermero en Prácticas.',
        type = 'success',
        duration = 8000
    })

    return true, string.format("Has contratado al jugador ID %s en el cuerpo médico.", target)
end)

--- Despedir a un sanitario
lib.callback.register('aura_ems:server:fireStaff', function(source, targetCharId)
    local bossSrc = source
    if not IsEmsBoss(bossSrc) then
        return false, "No tienes permisos de Dirección Médica para despedir personal."
    end

    local charId = tonumber(targetCharId)
    if not charId then return false, "ID de personaje no válido." end

    MySQL.update('UPDATE `characters` SET `job` = "unemployed", `job_grade` = 0 WHERE `id` = ?', { charId })

    -- Si el jugador está conectado, actualizar su estado inmediatamente
    for _, pid in ipairs(GetPlayers()) do
        local pSrc = tonumber(pid)
        local state = Player(pSrc).state
        if state and state.character_id == charId then
            state:set('job', 'unemployed', true)
            state:set('job_grade', 0, true)
            state:set('job_duty', false, true)
            TriggerClientEvent('ox_lib:notify', pSrc, {
                title = 'Baja Laboral',
                description = 'Has sido dado de baja del Cuerpo Médico de Emergencias.',
                type = 'error',
                duration = 8000
            })
            break
        end
    end

    return true, "Empleado despedido y trasladado a desempleado."
end)

--- Modificar rango de un sanitario
lib.callback.register('aura_ems:server:setStaffGrade', function(source, data)
    local bossSrc = source
    if not IsEmsBoss(bossSrc) then
        return false, "No tienes permisos de Dirección Médica."
    end

    if not data or not data.targetCharId or data.newGrade == nil then
        return false, "Datos incompletos."
    end

    local charId = tonumber(data.targetCharId)
    local newGrade = tonumber(data.newGrade)

    if newGrade < 0 or newGrade > (Config.BossGrade or 4) then
        return false, "Rango no válido."
    end

    MySQL.update('UPDATE `characters` SET `job_grade` = ? WHERE `id` = ?', { newGrade, charId })

    for _, pid in ipairs(GetPlayers()) do
        local pSrc = tonumber(pid)
        local state = Player(pSrc).state
        if state and state.character_id == charId then
            state:set('job_grade', newGrade, true)
            TriggerClientEvent('ox_lib:notify', pSrc, {
                title = 'Rango Actualizado',
                description = string.format("Tu rango médico ha sido actualizado a Grado %s.", newGrade),
                type = 'inform',
                duration = 6000
            })
            break
        end
    end

    return true, string.format("Rango actualizado con éxito a Grado %s.", newGrade)
end)
