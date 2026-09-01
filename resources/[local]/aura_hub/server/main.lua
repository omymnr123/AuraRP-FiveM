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
-- 5. DESCONEXIÓN LIMPIA DESDE EL HUB
-- ============================================================================

RegisterNetEvent('aura_hub:server:disconnect', function()
    local src = source
    DropPlayer(src, "Desconexión voluntaria desde el Menú Principal Aura Hub.")
end)
