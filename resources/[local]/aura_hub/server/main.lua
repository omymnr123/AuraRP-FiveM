-- ============================================================================
-- AURA HUB: SERVER CORE CONTROLLER
-- Master Pause Menu, HR Engine, Corporate Wire Transfers & Business State
-- ============================================================================

local function getActiveCharacterId(src)
    local active = exports.aura_multichar:GetActiveCharacter(src)
    return active and active.id or nil
end

local function getCharacterById(charId)
    return MySQL.single.await('SELECT id, citizenid, firstname, lastname, job, job_grade, iban, phone_number FROM characters WHERE id = ?', { charId })
end

-- ============================================================================
-- 1. CONSULTA DE DATOS GENERALES DEL HUB
-- ============================================================================

lib.callback.register('aura_hub:server:getHubData', function(source)
    local src = source
    local activeChar = exports.aura_multichar:GetActiveCharacter(src)
    if not activeChar then return nil end

    local charId = activeChar.id
    local jobData = exports.aura_jobs:GetJob(src)
    local accounts = exports.aura_economy:GetAccounts(src) or { cash = 0, bank = 0, savings = 0 }

    local isBusiness = jobData and jobData.isBusiness == true
    local isBoss = jobData and jobData.isBoss == true
    local jobName = jobData and jobData.name or 'unemployed'

    local businessOpen = false
    local societyData = nil

    if isBusiness then
        businessOpen = GlobalState['business_' .. jobName .. '_open'] == true
    end

    if isBoss and jobName ~= 'unemployed' then
        local socBalance = exports.aura_jobs:GetSocietyBalance(jobName)
        societyData = {
            name = jobName,
            label = jobData.label,
            balance = socBalance
        }
    end

    -- Obtener IBAN y metadata
    local row = MySQL.single.await('SELECT iban, citizenid, phone_number, metadata FROM characters WHERE id = ?', { charId })

    -- Conteo de servicios activos y jugadores
    local players = GetPlayers()
    local onlineCount = #players
    local maxPlayers = GetConvarInt('sv_maxclients', 48)

    local policeCount = 0
    local emsCount = 0
    local mechanicCount = 0
    local taxiCount = 0

    for _, pid in ipairs(players) do
        local pSrc = tonumber(pid)
        if pSrc then
            local pState = Player(pSrc).state
            if pState.job == 'police' and pState.job_duty then policeCount = policeCount + 1 end
            if pState.job == 'ambulance' and pState.job_duty then emsCount = emsCount + 1 end
            if pState.job == 'mechanic' and pState.job_duty then mechanicCount = mechanicCount + 1 end
            if pState.job == 'taxi' and pState.job_duty then taxiCount = taxiCount + 1 end
        end
    end

    -- Gestión robusta de lista de comercios abiertos
    local allJobs = (Config and Config.Jobs) or (exports.aura_jobs and exports.aura_jobs:GetAllJobs()) or {}
    local openBusinesses = {}
    for jName, jConf in pairs(allJobs) do
        if jConf.isBusiness then
            local isOpen = (OpenBusinessesState and OpenBusinessesState[jName] == true) or (GlobalState['business_' .. jName .. '_open'] == true)
            if isOpen then
                table.insert(openBusinesses, {
                    name = jName,
                    label = jConf.label
                })
            end
        end
    end

    return {
        serverId = src,
        charId = charId,
        citizenid = row and row.citizenid or activeChar.citizenid or "UNKNOWN",
        name = string.format("%s %s", activeChar.firstname or "Ciudadano", activeChar.lastname or ""),
        iban = row and row.iban or "SIN IBAN",
        phoneNumber = row and row.phone_number or "SIN TELEFONO",
        job = jobData,
        accounts = accounts,
        businessOpen = businessOpen,
        isBoss = isBoss,
        society = societyData,
        onlinePlayers = onlineCount,
        maxPlayers = maxPlayers,
        services = {
            police = policeCount,
            ems = emsCount,
            mechanic = mechanicCount,
            taxi = taxiCount
        },
        openBusinesses = openBusinesses
    }
end)

-- ============================================================================
-- 2. ALTERNAR ESTADO DEL NEGOCIO (ACCESIBLE POR CUALQUIER EMPLEADO)
-- ============================================================================

local function getOpenBusinessesList()
    local allJobs = (Config and Config.Jobs) or (exports.aura_jobs and exports.aura_jobs:GetAllJobs()) or {}
    local list = {}
    for jName, jConf in pairs(allJobs) do
        if jConf.isBusiness then
            local isOpen = (OpenBusinessesState and OpenBusinessesState[jName] == true) or (GlobalState['business_' .. jName .. '_open'] == true)
            if isOpen then
                table.insert(list, {
                    name = jName,
                    label = jConf.label
                })
            end
        end
    end
    return list
end

lib.callback.register('aura_hub:server:toggleBusinessState', function(source)
    local src = source
    local jobData = exports.aura_jobs:GetJob(src)

    if not jobData or not jobData.isBusiness or jobData.name == 'unemployed' then
        return false, "No perteneces a ningún negocio o comercio autorizado."
    end

    local jobName = jobData.name
    local stateKey = 'business_' .. jobName .. '_open'
    local currentState = (OpenBusinessesState and OpenBusinessesState[jobName] == true) or (GlobalState[stateKey] == true)
    local newState = not currentState

    -- Actualizar estado en memoria y GlobalState
    if not OpenBusinessesState then OpenBusinessesState = {} end
    OpenBusinessesState[jobName] = newState
    GlobalState[stateKey] = newState

    local updatedList = getOpenBusinessesList()

    -- Emitir anuncio global NUI a todos los jugadores del servidor con la lista actualizada
    TriggerClientEvent('aura_hub:client:showAnnouncement', -1, {
        business = jobData.label,
        job = jobName,
        isOpen = newState,
        openBusinesses = updatedList,
        duration = Config.AnnouncementDuration or 7000
    })

    if Config.Debug then
        print(string.format("[Aura Hub] Estado del negocio '%s' modificado a: %s por Src #%d", jobName, newState and "ABIERTO" or "CERRADO", src))
    end

    return true, newState, updatedList
end)

-- ============================================================================
-- 3. RECURSOS HUMANOS / GESTIÓN DE EMPLEADOS (EXCLUSIVO BOSS)
-- ============================================================================

lib.callback.register('aura_hub:server:getEmployees', function(source)
    local src = source
    local isBoss, jobName, jobLabel = exports.aura_jobs:IsBoss(src)

    if not isBoss or not jobName then
        return false, "Acceso denegado."
    end

    local jobConfig = exports.aura_jobs:GetJobConfig(jobName)
    if not jobConfig then return false, "Configuración no encontrada." end

    local rows = MySQL.query.await([[
        SELECT id, citizenid, firstname, lastname, job_grade, phone_number 
        FROM characters 
        WHERE job = ? 
        ORDER BY job_grade DESC, firstname ASC
    ]], { jobName })

    local employees = {}
    if rows then
        for _, emp in ipairs(rows) do
            local gradeNum = tonumber(emp.job_grade) or 0
            local gradeConfig = jobConfig.grades[gradeNum] or jobConfig.grades[0]
            
            -- Detectar si está online
            local isOnline = false
            local onlineSrc = nil
            for _, pid in ipairs(GetPlayers()) do
                local pSrc = tonumber(pid)
                if pSrc then
                    local pChar = exports.aura_multichar:GetActiveCharacter(pSrc)
                    if pChar and pChar.id == emp.id then
                        isOnline = true
                        onlineSrc = pSrc
                        break
                    end
                end
            end

            table.insert(employees, {
                charId = emp.id,
                citizenid = emp.citizenid,
                name = string.format("%s %s", emp.firstname or "", emp.lastname or ""),
                grade = gradeNum,
                gradeLabel = gradeConfig and gradeConfig.name or "Rango 0",
                salary = gradeConfig and gradeConfig.salary or 0,
                phoneNumber = emp.phone_number or "N/A",
                isOnline = isOnline,
                src = onlineSrc
            })
        end
    end

    return true, {
        employees = employees,
        grades = jobConfig.grades,
        jobLabel = jobLabel
    }
end)

lib.callback.register('aura_hub:server:hireEmployee', function(source, targetSrc)
    local bossSrc = source
    local isBoss, jobName, jobLabel = exports.aura_jobs:IsBoss(bossSrc)

    if not isBoss or not jobName then
        return false, "Acceso denegado: No dispones de rango directivo."
    end

    targetSrc = tonumber(targetSrc)
    if not targetSrc or not GetPlayerName(tostring(targetSrc)) then
        return false, "El jugador especificado no se encuentra conectado."
    end

    if targetSrc == bossSrc then
        return false, "No puedes contratarte a ti mismo."
    end

    -- Validación de proximidad
    local bossPed = GetPlayerPed(bossSrc)
    local targetPed = GetPlayerPed(targetSrc)
    if #(GetEntityCoords(bossPed) - GetEntityCoords(targetPed)) > (Config.MaxHireDistance or 10.0) then
        return false, "El candidato debe estar físicamente cerca de ti para firmar el contrato."
    end

    local success, err = exports.aura_jobs:SetJob(targetSrc, jobName, 0)
    if success then
        TriggerClientEvent('ox_lib:notify', targetSrc, {
            title = 'Contratación Aceptada',
            description = string.format("Has sido contratado en %s como Empleado Inicial.", jobLabel),
            type = 'success',
            duration = 6000
        })

        return true, string.format("Has contratado a %s correctamente en %s.", GetPlayerName(tostring(targetSrc)), jobLabel)
    else
        return false, err or "Error al contratar al jugador."
    end
end)

lib.callback.register('aura_hub:server:fireEmployee', function(source, targetCharId)
    local bossSrc = source
    local isBoss, jobName = exports.aura_jobs:IsBoss(bossSrc)

    if not isBoss or not jobName then
        return false, "Acceso denegado."
    end

    targetCharId = tonumber(targetCharId)
    if not targetCharId then return false, "ID inválido." end

    local bossCharId = getActiveCharacterId(bossSrc)
    if bossCharId == targetCharId then
        return false, "No puedes despedirte a ti mismo como director."
    end

    local emp = getCharacterById(targetCharId)
    if not emp or emp.job ~= jobName then
        return false, "Este personaje no forma parte de tu empresa."
    end

    -- Asignar desempleado
    local success = exports.aura_jobs:SetJob(targetCharId, 'unemployed', 0)
    if success then
        return true, string.format("El contrato de %s %s ha sido rescindido.", emp.firstname, emp.lastname)
    else
        return false, "Error al despedir al empleado."
    end
end)

lib.callback.register('aura_hub:server:setEmployeeGrade', function(source, data)
    local bossSrc = source
    local isBoss, jobName = exports.aura_jobs:IsBoss(bossSrc)

    if not isBoss or not jobName then
        return false, "Acceso denegado."
    end

    local targetCharId = tonumber(data.targetCharId)
    local newGrade = tonumber(data.newGrade)

    if not targetCharId or newGrade == nil then
        return false, "Parámetros incompletos."
    end

    local jobConfig = exports.aura_jobs:GetJobConfig(jobName)
    if not jobConfig or not jobConfig.grades[newGrade] then
        return false, "Rango inexistente en la estructura empresarial."
    end

    local emp = getCharacterById(targetCharId)
    if not emp or emp.job ~= jobName then
        return false, "El empleado no pertenece a tu empresa."
    end

    local success = exports.aura_jobs:SetJob(targetCharId, jobName, newGrade)
    if success then
        return true, string.format("Puesto de %s %s actualizado a: %s.", emp.firstname, emp.lastname, jobConfig.grades[newGrade].name)
    else
        return false, "Error al actualizar el rango."
    end
end)

-- ============================================================================
-- 4. TRANSFERENCIAS BANCARIAS DIGITALES (EXCLUSIVO BOSS - FONDOS SOCIEDAD)
-- ============================================================================

lib.callback.register('aura_hub:server:corporateWireTransfer', function(source, data)
    local bossSrc = source
    local isBoss, jobName, jobLabel = exports.aura_jobs:IsBoss(bossSrc)

    if not isBoss or not jobName then
        return false, "Acceso denegado: No dispones de permisos de tesorería."
    end

    local targetIban = data.targetIban and string.upper(string.gsub(data.targetIban, "%s+", ""))
    local amount = tonumber(data.amount)
    local reason = data.reason or "Transferencia Corporativa Digital"

    if not targetIban or string.len(targetIban) < 4 then
        return false, "IBAN de destino inválido."
    end

    if not amount or amount <= 0 then
        return false, "Importe de transferencia inválido."
    end

    -- 1. Verificar balance disponible en la cuenta societaria
    local currentSocBalance = exports.aura_jobs:GetSocietyBalance(jobName)
    if currentSocBalance < amount then
        return false, "Fondos societarios insuficientes para emitir esta transferencia."
    end

    -- 2. Localizar personaje receptor por su IBAN
    local recipient = MySQL.single.await('SELECT id, firstname, lastname FROM characters WHERE iban = ?', { targetIban })
    if not recipient then
        return false, "El IBAN de destino no corresponde a ninguna cuenta bancaria registrada."
    end

    local bossCharId = getActiveCharacterId(bossSrc)

    -- 3. Débito digital de la cuenta societaria
    local debited, newSocBalance = exports.aura_jobs:RemoveSocietyMoney(
        jobName,
        amount,
        string.format("Transferencia Digital emitida hacia IBAN %s (%s)", targetIban, reason),
        { targetIban = targetIban, targetCharId = recipient.id, executor = bossCharId }
    )

    if not debited then
        return false, "Fallo al debitar fondos de la tesorería corporativa."
    end

    -- 4. Crédito directo a la cuenta bancaria del receptor
    local credited = exports.aura_economy:AddMoney(
        recipient.id,
        'bank',
        amount,
        string.format("Transferencia Corporativa recibida de %s: %s", jobLabel, reason),
        { fromSociety = jobName, executor = bossCharId }
    )

    if not credited then
        -- Rollback de emergencia a la sociedad
        exports.aura_jobs:AddSocietyMoney(jobName, amount, "ROLLBACK: Transferencia fallida a " .. targetIban)
        return false, "Error al acreditar fondos en la cuenta bancaria del destinatario."
    end

    return true, string.format("Transferencia de $%s enviada con éxito a %s %s (%s).", lib.math.groupdigits(amount), recipient.firstname, recipient.lastname, targetIban), newSocBalance
end)

-- ============================================================================
-- 5. DESCONEXIÓN LIMPIA Y GESTIÓN DE SERVICIO DESDE EL HUB
-- ============================================================================

RegisterNetEvent('aura_hub:server:disconnect', function()
    local src = source
    DropPlayer(src, "Desconexión voluntaria desde el Menú Principal Aura Hub.")
end)

lib.callback.register('aura_hub:server:toggleDuty', function(source)
    local src = source
    local success, newDuty = exports.aura_jobs:SetDuty(src)
    return success, newDuty
end)

-- ============================================================================
-- 6. MDT POLICIAL LSPD (ENDPOINTS, BÚSQUEDAS, SANCIONES Y CÁRCEL EN AURA HUB)
-- ============================================================================

local function IsPoliceOfficer(src)
    local pState = Player(src).state
    return pState.job == 'police'
end

local function IsPoliceOnDuty(src)
    local pState = Player(src).state
    return pState.job == 'police'
end

--- Resumen general del MDT: agentes en servicio, balances societarios y estadísticas
lib.callback.register('aura_hub:server:getPoliceMdtOverview', function(source)
    local src = source
    if not IsPoliceOfficer(src) then return false, "UNAUTHORIZED" end

    local socBalance = exports.aura_jobs:GetSocietyBalance('police') or 0
    local officers = {}
    for _, pid in ipairs(GetPlayers()) do
        local pSrc = tonumber(pid)
        if pSrc and IsPoliceOfficer(pSrc) then
            local pState = Player(pSrc).state
            local pChar = exports.aura_multichar:GetActiveCharacter(pSrc)
            table.insert(officers, {
                src = pSrc,
                citizenid = pChar and pChar.citizenid or tostring(pSrc),
                name = pChar and string.format("%s %s", pChar.firstname or "", pChar.lastname or "") or GetPlayerName(pSrc),
                grade = pState.job_grade or 0,
                gradeLabel = pState.grade_label or "Oficial",
                phoneNumber = pChar and pChar.phone_number or "N/A",
                duty = pState.job_duty == true
            })
        end
    end

    local warrantsCount = MySQL.scalar.await('SELECT COUNT(*) FROM aura_police_warrants WHERE status = ?', { 'active' }) or 0
    local inmatesCount = MySQL.scalar.await('SELECT COUNT(*) FROM aura_police_jail WHERE status = ?', { 'active' }) or 0
    local totalFinesSum = MySQL.scalar.await('SELECT COALESCE(SUM(amount), 0) FROM aura_police_fines', {}) or 0

    return true, {
        societyBalance = socBalance,
        officers = officers,
        warrantsCount = warrantsCount,
        inmatesCount = inmatesCount,
        totalFinesSum = totalFinesSum,
        presets = (Config and Config.FinePresets) or (exports.aura_police and Config.FinePresets) or {}
    }
end)

--- Búsqueda exhaustiva de ciudadanos por Nombre, Apellidos o CitizenID
lib.callback.register('aura_hub:server:policeSearchCitizen', function(source, query)
    local src = source
    if not IsPoliceOnDuty(src) then return false, "UNAUTHORIZED" end

    query = string.gsub(tostring(query or ""), "^%s*(.-)%s*$", "%1")
    if string.len(query) < 2 then return false, "Término de búsqueda demasiado corto." end

    local searchPattern = "%" .. query .. "%"
    local rows = MySQL.query.await([[
        SELECT id, citizenid, firstname, lastname, dob, gender, phone_number, iban, job, job_grade, metadata
        FROM characters
        WHERE citizenid LIKE ? OR firstname LIKE ? OR lastname LIKE ? OR CONCAT(firstname, ' ', lastname) LIKE ?
        LIMIT 10
    ]], { searchPattern, searchPattern, searchPattern, searchPattern })

    if not rows or #rows == 0 then
        return false, "No se encontraron ciudadanos con esos datos en el censo."
    end

    local results = {}
    for _, row in ipairs(rows) do
        local meta = {}
        if row.metadata then
            if type(row.metadata) == 'table' then
                meta = row.metadata
            else
                pcall(function() meta = json.decode(row.metadata) or {} end)
            end
        end

        local vehicles = MySQL.query.await('SELECT plate FROM vehicles WHERE owner = ?', { row.citizenid }) or {}
        local plates = {}
        for _, v in ipairs(vehicles) do table.insert(plates, v.plate) end

        local fines = MySQL.query.await('SELECT amount, reason, officer_name, created_at FROM aura_police_fines WHERE citizenid = ? ORDER BY id DESC LIMIT 5', { row.citizenid }) or {}
        local jailRecords = MySQL.query.await('SELECT jail_time, reason, officer_name, status, created_at FROM aura_police_jail WHERE citizenid = ? ORDER BY id DESC LIMIT 5', { row.citizenid }) or {}
        local warrants = MySQL.query.await('SELECT id, reason, severity, status, created_at FROM aura_police_warrants WHERE citizenid = ? AND status = ?', { row.citizenid, 'active' }) or {}

        table.insert(results, {
            id = row.id,
            citizenid = row.citizenid,
            name = string.format("%s %s", row.firstname, row.lastname),
            dob = row.dob or "1995-01-01",
            gender = row.gender == 1 and "Femenino" or "Masculino",
            phone = row.phone_number or "N/A",
            iban = row.iban or "N/A",
            job = row.job or "unemployed",
            licenses = meta.licenses or { weapon = false, driver = true, business = false },
            plates = plates,
            fines = fines,
            jailRecords = jailRecords,
            hasWarrant = #warrants > 0,
            warrantInfo = warrants[1]
        })
    end

    return true, results
end)

--- Búsqueda de vehículos por matrícula (Plate)
lib.callback.register('aura_hub:server:policeSearchVehicle', function(source, plate)
    local src = source
    if not IsPoliceOnDuty(src) then return false, "UNAUTHORIZED" end

    plate = string.upper(string.gsub(tostring(plate or ""), "%s+", ""))
    local row = MySQL.single.await([[
        SELECT v.plate, v.owner, c.firstname, c.lastname, c.phone_number
        FROM vehicles v
        LEFT JOIN characters c ON v.owner = c.citizenid
        WHERE UPPER(v.plate) = ?
    ]], { plate })

    local bolo = MySQL.single.await('SELECT reason, officer_name, status FROM aura_police_vehicle_bolo WHERE plate = ? AND status = ?', { plate, 'active' })

    if not row and not bolo then
        return false, "Vehículo no registrado en la base de datos de tráfico."
    end

    return true, {
        plate = plate,
        owner = row and string.format("%s %s", row.firstname or "Ciudadano", row.lastname or "") or "Desconocido",
        ownerCitizenId = row and row.owner or "N/A",
        phone = row and row.phone_number or "N/A",
        isBolo = bolo ~= nil,
        boloReason = bolo and bolo.reason or nil,
        boloOfficer = bolo and bolo.officer_name or nil
    }
end)

--- Alternar BOLO / Búsqueda y captura de vehículo
lib.callback.register('aura_hub:server:policeToggleVehicleBolo', function(source, data)
    local src = source
    if not IsPoliceOnDuty(src) then return false, "UNAUTHORIZED" end

    local plate = string.upper(string.gsub(tostring(data.plate or ""), "%s+", ""))
    local reason = tostring(data.reason or "Vehículo en Búsqueda Policial (BOLO)")

    local existing = MySQL.single.await('SELECT id FROM aura_police_vehicle_bolo WHERE plate = ? AND status = ?', { plate, 'active' })
    if existing then
        MySQL.update('UPDATE aura_police_vehicle_bolo SET status = ? WHERE id = ?', { 'resolved', existing.id })
        return true, string.format("BOLO del vehículo [%s] cancelado y resuelto.", plate), false
    else
        local offChar = exports.aura_multichar:GetActiveCharacter(src)
        local officerName = offChar and string.format("%s %s", offChar.firstname or "", offChar.lastname or "") or GetPlayerName(src)

        MySQL.insert('INSERT INTO aura_police_vehicle_bolo (plate, reason, officer_name, status) VALUES (?, ?, ?, ?)', {
            plate, reason, officerName, 'active'
        })
        return true, string.format("Vehículo [%s] marcado en Búsqueda y Captura (BOLO).", plate), true
    end
end)

--- Emisión de Sanción / Multa Directa desde el MDT (Cobra en banco y abona en society_police)
lib.callback.register('aura_hub:server:policeIssueFine', function(source, data)
    local copSrc = source
    if not IsPoliceOnDuty(copSrc) then return false, "UNAUTHORIZED" end

    local targetCitizenId = data.citizenid
    local targetServerId = tonumber(data.targetServerId)
    local amount = math.floor(tonumber(data.amount) or 0)
    local reason = tostring(data.reason or "Sanción Policial LSPD")

    if amount <= 0 then return false, "El importe de la multa debe ser mayor a $0." end

    local suspect = nil
    local suspectSrc = nil

    if targetServerId and GetPlayerName(tostring(targetServerId)) then
        suspectSrc = targetServerId
        local char = exports.aura_multichar:GetActiveCharacter(suspectSrc)
        if char then
            suspect = char
            targetCitizenId = char.citizenid
        end
    elseif targetCitizenId then
        suspect = MySQL.single.await('SELECT id, citizenid, firstname, lastname FROM characters WHERE citizenid = ?', { targetCitizenId })
        for _, pid in ipairs(GetPlayers()) do
            local pSrc = tonumber(pid)
            if pSrc then
                local c = exports.aura_multichar:GetActiveCharacter(pSrc)
                if c and c.citizenid == targetCitizenId then
                    suspectSrc = pSrc
                    break
                end
            end
        end
    end

    if not suspect then return false, "Ciudadano infractor no encontrado." end

    local copChar = exports.aura_multichar:GetActiveCharacter(copSrc)
    local officerName = copChar and string.format("%s %s", copChar.firstname or "", copChar.lastname or "") or GetPlayerName(copSrc)
    local officerCid = copChar and copChar.citizenid or tostring(copSrc)

    -- 1. Débito bancario del infractor mediante aura_economy
    local debited, _, txId = exports.aura_economy:RemoveMoney(
        suspect.id,
        'bank',
        amount,
        string.format("Multa Policial: %s", reason),
        { officer = officerName, officerCid = officerCid }
    )

    -- 2. Acreditación del 100% en la cuenta societaria de la policía mediante aura_jobs
    exports.aura_jobs:AddSocietyMoney('police', amount, string.format("Cobro de Multa LSPD a %s %s (%s)", suspect.firstname, suspect.lastname, reason), {
        txId = txId,
        suspectCitizenId = suspect.citizenid,
        officer = officerName
    })

    -- 3. Registrar en base de datos
    MySQL.insert([[
        INSERT INTO aura_police_fines (citizenid, receiver_name, officer_citizenid, officer_name, amount, reason)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        suspect.citizenid,
        string.format("%s %s", suspect.firstname, suspect.lastname),
        officerCid,
        officerName,
        amount,
        reason
    })

    -- 4. Notificar al infractor si está conectado
    if suspectSrc then
        TriggerClientEvent('ox_lib:notify', suspectSrc, {
            title = 'Multa Policial Notificada',
            description = string.format("Has sido sancionado con $%s por la Policía.\nMotivo: %s", lib.math.groupdigits(amount), reason),
            type = 'error',
            duration = 8000
        })
    end

    return true, string.format("Sanción de $%s emitida correctamente a %s %s.", lib.math.groupdigits(amount), suspect.firstname, suspect.lastname)
end)

--- Encarcelamiento directo desde el MDT de Aura Hub (Sin comandos de chat)
lib.callback.register('aura_hub:server:policeJailSuspect', function(source, data)
    local copSrc = source
    if not IsPoliceOnDuty(copSrc) then return false, "UNAUTHORIZED" end

    local targetSrc = tonumber(data.targetServerId)
    local targetCitizenId = data.citizenid
    local minutes = math.floor(tonumber(data.minutes) or 0)
    local reason = tostring(data.reason or "Sentencia Judicial LSPD")

    if not targetSrc and targetCitizenId then
        for _, pid in ipairs(GetPlayers()) do
            local pSrc = tonumber(pid)
            if pSrc then
                local c = exports.aura_multichar:GetActiveCharacter(pSrc)
                if c and c.citizenid == targetCitizenId then
                    targetSrc = pSrc
                    break
                end
            end
        end
    end

    if not targetSrc or not GetPlayerName(tostring(targetSrc)) then
        return false, "El sospechoso debe estar conectado en el servidor para procesar el ingreso a prisión."
    end

    local success, msg = exports.aura_police:JailPlayer(targetSrc, minutes, reason, copSrc)
    return success, msg
end)

--- Órdenes de búsqueda y captura (Warrants)
lib.callback.register('aura_hub:server:policeGetWarrants', function(source)
    if not IsPoliceOnDuty(source) then return false, "UNAUTHORIZED" end
    local rows = MySQL.query.await('SELECT id, citizenid, suspect_name, reason, officer_name, severity, status, created_at FROM aura_police_warrants ORDER BY id DESC LIMIT 20')
    return true, rows or {}
end)

lib.callback.register('aura_hub:server:policeCreateWarrant', function(source, data)
    local src = source
    if not IsPoliceOnDuty(src) then return false, "UNAUTHORIZED" end

    local suspectCitizenId = data.citizenid
    local suspectName = data.suspectName or "Sospechoso"
    local reason = data.reason or "Orden de Búsqueda y Captura"
    local severity = data.severity or 'medium'

    local offChar = exports.aura_multichar:GetActiveCharacter(src)
    local officerName = offChar and string.format("%s %s", offChar.firstname or "", offChar.lastname or "") or GetPlayerName(src)

    MySQL.insert('INSERT INTO aura_police_warrants (citizenid, suspect_name, reason, officer_name, severity, status) VALUES (?, ?, ?, ?, ?, ?)', {
        suspectCitizenId, suspectName, reason, officerName, severity, 'active'
    })

    return true, "Orden de búsqueda y captura emitida con éxito."
end)

lib.callback.register('aura_hub:server:policeDeleteWarrant', function(source, warrantId)
    if not IsPoliceOnDuty(source) then return false, "UNAUTHORIZED" end
    MySQL.update('UPDATE aura_police_warrants SET status = ? WHERE id = ?', { 'resolved', tonumber(warrantId) })
    return true, "Orden de búsqueda resuelta / archivada."
end)

--- Reclusos actualmente en prisión
lib.callback.register('aura_hub:server:policeGetActiveInmates', function(source)
    if not IsPoliceOnDuty(source) then return false, "UNAUTHORIZED" end
    local rows = MySQL.query.await('SELECT id, citizenid, jail_time, reason, officer_name, created_at FROM aura_police_jail WHERE status = ? ORDER BY id DESC', { 'active' })
    return true, rows or {}
end)

-- ============================================================================
-- 7. MDT POLICIAL: GESTIÓN DE PERSONAL / RRHH (CONTRATAR, ASCENDER, DEGRADAR, DESPEDIR)
-- ============================================================================

--- Obtener la plantilla completa de oficiales de policía
lib.callback.register('aura_hub:server:policeGetStaff', function(source)
    local src = source
    if not IsPoliceOnDuty(src) then return false, "UNAUTHORIZED" end

    local pState = Player(src).state
    local callerGrade = pState.job_grade or 0
    local isHighCommand = callerGrade >= 4 -- Teniente (4), Capitán (5), Jefe de Policía (6)

    local rows = MySQL.query.await([[
        SELECT id, citizenid, firstname, lastname, job_grade, job_duty, phone_number
        FROM characters
        WHERE job = 'police'
        ORDER BY job_grade DESC, firstname ASC
    ]])

    local staff = {}
    local onlineOfficersMap = {}

    for _, pid in ipairs(GetPlayers()) do
        local pSrc = tonumber(pid)
        if pSrc then
            local char = exports.aura_multichar:GetActiveCharacter(pSrc)
            if char and char.id then
                onlineOfficersMap[char.id] = pSrc
            end
        end
    end

    local jobConfig = exports.aura_jobs:GetJobConfig('police')
    local gradesConfig = jobConfig and jobConfig.grades or {}

    for _, row in ipairs(rows or {}) do
        local gradeCfg = gradesConfig[row.job_grade] or { name = "Rango " .. row.job_grade, salary = 0 }
        local onlineSrc = onlineOfficersMap[row.id]

        table.insert(staff, {
            charId = row.id,
            citizenid = row.citizenid,
            name = string.format("%s %s", row.firstname, row.lastname),
            grade = row.job_grade,
            gradeLabel = gradeCfg.name,
            salary = gradeCfg.salary or 0,
            phone = row.phone_number or "N/A",
            isOnline = onlineSrc ~= nil,
            src = onlineSrc or 0
        })
    end

    return true, { staff = staff, isHighCommand = isHighCommand, callerGrade = callerGrade }
end)

--- Contratar a un nuevo oficial (Cadete)
lib.callback.register('aura_hub:server:policeHireOfficer', function(source, targetSrc)
    local src = source
    if not IsPoliceOnDuty(src) then return false, "UNAUTHORIZED" end

    local pState = Player(src).state
    local callerGrade = pState.job_grade or 0
    if callerGrade < 4 then
        return false, "Se requiere rango de Alto Mando (Teniente o superior) para contratar oficiales."
    end

    targetSrc = tonumber(targetSrc)
    if not targetSrc or not GetPlayerName(tostring(targetSrc)) then
        return false, "El ciudadano no se encuentra conectado o el ID es inválido."
    end

    local copPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(targetSrc)
    if #(GetEntityCoords(copPed) - GetEntityCoords(targetPed)) > 15.0 then
        return false, "El ciudadano debe estar cerca de ti para formalizar la contratación."
    end

    local success, err = exports.aura_jobs:SetJob(targetSrc, 'police', 0)
    if not success then
        return false, "Error al procesar contratación: " .. tostring(err)
    end

    local targetChar = exports.aura_multichar:GetActiveCharacter(targetSrc)
    local targetName = targetChar and string.format("%s %s", targetChar.firstname or "", targetChar.lastname or "") or GetPlayerName(targetSrc)

    TriggerClientEvent('ox_lib:notify', targetSrc, {
        title = 'Contratación LSPD',
        description = '¡Has sido contratado en el Departamento de Policía (LSPD) como Cadete!',
        type = 'success',
        duration = 10000
    })

    return true, string.format("Has contratado a %s (ID %d) como Cadete en el LSPD.", targetName, targetSrc)
end)

--- Ascender o degradar a un oficial
lib.callback.register('aura_hub:server:policeSetOfficerGrade', function(source, data)
    local src = source
    if not IsPoliceOnDuty(src) then return false, "UNAUTHORIZED" end

    local pState = Player(src).state
    local callerGrade = pState.job_grade or 0
    if callerGrade < 4 then
        return false, "Se requiere rango de Alto Mando para modificar rangos."
    end

    local targetCharId = tonumber(data.targetCharId)
    local newGrade = tonumber(data.newGrade)
    if not targetCharId or newGrade == nil or newGrade < 0 or newGrade > 6 then
        return false, "Rango o ID de oficial inválido (0 a 6)."
    end

    if callerGrade < 6 and newGrade >= callerGrade then
        return false, "No puedes ascender a un oficial a un rango igual o superior al tuyo."
    end

    local targetOnlineSrc = nil
    for _, pid in ipairs(GetPlayers()) do
        local pSrc = tonumber(pid)
        if pSrc then
            local c = exports.aura_multichar:GetActiveCharacter(pSrc)
            if c and c.id == targetCharId then
                targetOnlineSrc = pSrc
                break
            end
        end
    end

    local jobConfig = exports.aura_jobs:GetJobConfig('police')
    local gradeName = (jobConfig and jobConfig.grades[newGrade] and jobConfig.grades[newGrade].name) or ("Grado " .. newGrade)

    if targetOnlineSrc then
        exports.aura_jobs:SetJob(targetOnlineSrc, 'police', newGrade)
        TriggerClientEvent('ox_lib:notify', targetOnlineSrc, {
            title = 'Actualización de Rango LSPD',
            description = string.format("Tu rango policial ha sido actualizado a: %s (Grado %d).", gradeName, newGrade),
            type = 'inform',
            duration = 8000
        })
    else
        MySQL.update('UPDATE characters SET job_grade = ? WHERE id = ? AND job = ?', { newGrade, targetCharId, 'police' })
    end

    return true, string.format("Rango actualizado con éxito a %s (Grado %d).", gradeName, newGrade)
end)

--- Despedir o expulsar a un oficial del cuerpo
lib.callback.register('aura_hub:server:policeFireOfficer', function(source, targetCharId)
    local src = source
    if not IsPoliceOnDuty(src) then return false, "UNAUTHORIZED" end

    local pState = Player(src).state
    local callerGrade = pState.job_grade or 0
    if callerGrade < 4 then
        return false, "Se requiere rango de Alto Mando para expulsar agentes del cuerpo."
    end

    targetCharId = tonumber(targetCharId)
    if not targetCharId then return false, "ID de oficial inválido." end

    local row = MySQL.single.await('SELECT firstname, lastname, job_grade FROM characters WHERE id = ?', { targetCharId })
    if not row then return false, "Oficial no encontrado en la base de datos." end

    if row.job_grade >= callerGrade and callerGrade < 6 then
        return false, "No tienes autoridad para expulsar a un oficial de igual o superior graduación."
    end

    local targetOnlineSrc = nil
    for _, pid in ipairs(GetPlayers()) do
        local pSrc = tonumber(pid)
        if pSrc then
            local c = exports.aura_multichar:GetActiveCharacter(pSrc)
            if c and c.id == targetCharId then
                targetOnlineSrc = pSrc
                break
            end
        end
    end

    if targetOnlineSrc then
        exports.aura_jobs:SetJob(targetOnlineSrc, 'unemployed', 0)
        TriggerClientEvent('ox_lib:notify', targetOnlineSrc, {
            title = 'Cese de Funciones LSPD',
            description = 'Has sido cesado y expulsado del Departamento de Policía.',
            type = 'error',
            duration = 10000
        })
    else
        MySQL.update('UPDATE characters SET job = ?, job_grade = 0, job_duty = 0 WHERE id = ?', { 'unemployed', targetCharId })
    end

    return true, string.format("El oficial %s %s ha sido expulsado del cuerpo policial.", row.firstname, row.lastname)
end)
