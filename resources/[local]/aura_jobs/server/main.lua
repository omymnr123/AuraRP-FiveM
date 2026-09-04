local AuraJobs = {
    PlayerCache = {} -- [src] = { charId = 1, job = 'police', grade = 0, duty = false }
}

-- ============================================================================
-- RESOLUCIÓN DE PERSONAJE Y CARGA DE ESTADO
-- ============================================================================

local function GetCharacterId(src)
    local active = exports.aura_multichar:GetActiveCharacter(src)
    if active and active.id then
        return active.id
    end
    return nil
end

--- Genera un nuevo número de placa policial único correlativo (101, 102, 103...)
local function GeneratePoliceBadge()
    local existingBadges = MySQL.query.await([[
        SELECT badge FROM characters 
        WHERE badge IS NOT NULL AND badge != '' AND job = 'police'
    ]])
    local maxNum = 100
    if existingBadges then
        for _, row in ipairs(existingBadges) do
            local num = tonumber(string.match(tostring(row.badge), "%d+"))
            if num and num > maxNum then
                maxNum = num
            end
        end
    end
    return string.format("%03d", maxNum + 1)
end
exports('GeneratePoliceBadge', GeneratePoliceBadge)

--- Asegura que un policía tenga asignado su número de placa en DB y StateBags
local function EnsurePoliceBadge(charId, src)
    if not charId then return nil end
    local row = MySQL.single.await('SELECT badge FROM characters WHERE id = ?', { charId })
    local badge = row and row.badge
    if not badge or badge == '' then
        badge = GeneratePoliceBadge()
        MySQL.update('UPDATE characters SET badge = ? WHERE id = ?', { badge, charId })
    end
    
    if src then
        Player(src).state:set('badge', badge, true)
        Player(src).state:set('callsign', badge, true)
        
        local activeChar = exports.aura_multichar:GetActiveCharacter(src)
        if activeChar then
            activeChar.badge = badge
        end
    end
    
    return badge
end
exports('EnsurePoliceBadge', EnsurePoliceBadge)

--- Inicializa y carga en memoria y StateBags el empleo de un jugador
--- @param src number Source del jugador
--- @param charId number | nil ID de personaje opcional
local function LoadPlayerJob(src, charId)
    src = tonumber(src)
    if not src or not GetPlayerName(tostring(src)) then return end

    local cid = charId or GetCharacterId(src)
    if not cid then return end

    local row = MySQL.single.await('SELECT job, job_grade, badge FROM characters WHERE id = ?', { cid })
    local jobName = (row and row.job) or 'unemployed'
    local jobGrade = (row and tonumber(row.job_grade)) or 0
    local badge = (row and row.badge) or nil
    
    -- Todos los personajes se conectan SIEMPRE fuera de servicio por diseño
    local jobDuty = false
    MySQL.update('UPDATE characters SET job_duty = 0 WHERE id = ?', { cid })

    -- Validación contra la tabla de configuración
    local jobConfig = Config.Jobs[jobName]
    if not jobConfig then
        jobName = 'unemployed'
        jobGrade = 0
        jobDuty = false
        jobConfig = Config.Jobs['unemployed']
    end

    local gradeConfig = jobConfig.grades[jobGrade] or jobConfig.grades[0]
    local gradeName = gradeConfig and gradeConfig.name or "Rango 0"

    -- Si el trabajo no admite servicio, forzar duty = false
    if not jobConfig.canDuty then
        jobDuty = false
    end

    -- Si es policía, asegurar asignación de placa policial
    if jobName == 'police' then
        if not badge or badge == '' then
            badge = EnsurePoliceBadge(cid, src)
        else
            Player(src).state:set('badge', badge, true)
            Player(src).state:set('callsign', badge, true)
            local activeChar = exports.aura_multichar:GetActiveCharacter(src)
            if activeChar then activeChar.badge = badge end
        end
    else
        Player(src).state:set('badge', nil, true)
        Player(src).state:set('callsign', nil, true)
    end

    -- Guardar en caché del servidor
    AuraJobs.PlayerCache[src] = {
        charId = cid,
        job = jobName,
        grade = jobGrade,
        duty = jobDuty,
        badge = badge
    }

    -- Replicar a StateBags globales (Sincronización instantánea de red para clientes)
    local pState = Player(src).state
    pState:set('job', jobName, true)
    pState:set('job_grade', jobGrade, true)
    pState:set('job_duty', jobDuty, true)
    pState:set('job_label', jobConfig.label, true)
    pState:set('grade_label', gradeName, true)
    pState:set('isGang', (jobConfig.isGang == true), true)
    pState:set('isBusiness', (jobConfig.isBusiness == true), true)

    -- Sincronizar activeCharacter en multichar si existe
    local activeChar = exports.aura_multichar:GetActiveCharacter(src)
    if activeChar then
        activeChar.job = jobName
        activeChar.job_grade = jobGrade
    end

    -- Sincronizar grupos con ox_inventory
    TriggerEvent('aura_jobs:server:jobUpdated', src, jobName, jobGrade)

    UpdateAllBusinessStates()

    if Config.Debug then
        print(string.format("[Aura Jobs] Empleo cargado para Src #%d (CharID #%d): %s [%d] | Servicio: %s | Placa: %s", src, cid, jobName, jobGrade, tostring(jobDuty), tostring(badge)))
    end
end
exports('LoadPlayerJob', LoadPlayerJob)

--- Recalcula y sincroniza el estado abierto/cerrado de todos los negocios según los empleados en servicio
function UpdateAllBusinessStates()
    local activeDutyByJob = {}

    for _, pData in pairs(AuraJobs.PlayerCache) do
        if pData.duty and pData.job then
            activeDutyByJob[pData.job] = (activeDutyByJob[pData.job] or 0) + 1
        end
    end

    for jobName, jobConfig in pairs(Config.Jobs) do
        if jobConfig.isBusiness then
            local count = activeDutyByJob[jobName] or 0
            local stateKey = 'business_' .. jobName .. '_open'
            local isOpen = count > 0

            if GlobalState[stateKey] ~= isOpen then
                GlobalState[stateKey] = isOpen
                if Config.Debug then
                    print(string.format("[Aura Jobs] Negocio '%s' sincronizado en GlobalState: %s (Empleados en servicio: %d)", jobName, isOpen and "ABIERTO" or "CERRADO", count))
                end
            end
        end
    end
end
exports('UpdateAllBusinessStates', UpdateAllBusinessStates)

--- Comprueba si un negocio está actualmente abierto
--- @param jobName string
--- @return boolean
local function IsBusinessOpen(jobName)
    if not jobName then return false end
    return GlobalState['business_' .. jobName .. '_open'] == true
end
exports('IsBusinessOpen', IsBusinessOpen)

-- ============================================================================
-- EVENTOS DEL CICLO DE VIDA
-- ============================================================================

-- Cuando el jugador conecta y selecciona personaje
RegisterNetEvent('aura_multichar:server:characterLoaded', function(charId, explicitSrc)
    local src = explicitSrc or source
    if not src or src == 0 or not GetPlayerName(tostring(src)) then
        src = explicitSrc
    end
    LoadPlayerJob(src, charId)
end)

RegisterNetEvent('aura_jobs:server:loadCharacter', function(targetSrc, charId)
    local src = targetSrc or source
    LoadPlayerJob(src, charId)
end)

-- Guardar servicio al desconectar
AddEventHandler('playerDropped', function()
    local src = source
    local pData = AuraJobs.PlayerCache[src]
    if pData and pData.charId then
        MySQL.update('UPDATE characters SET job_duty = ? WHERE id = ?', {
            pData.duty and 1 or 0,
            pData.charId
        })
    end
    AuraJobs.PlayerCache[src] = nil
    UpdateAllBusinessStates()
end)

-- Limpieza si el recurso se reinicia
AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    CreateThread(function()
        Wait(1000)
        local players = GetPlayers()
        for _, pSrc in ipairs(players) do
            local cid = GetCharacterId(tonumber(pSrc))
            if cid then
                LoadPlayerJob(tonumber(pSrc), cid)
            end
        end
    end)
end)

-- ============================================================================
-- EXPORTS DE ACCESO Y MANIPULACIÓN DE EMPLEO
-- ============================================================================

--- Alterna o fuerza el estado de servicio de un jugador
--- @param src number Source del jugador
--- @param forceDuty boolean | nil Forzar estado explícito
--- @return boolean success, boolean isDuty
local function SetDuty(src, forceDuty)
    src = tonumber(src)
    if not src then return false, false end

    local pData = AuraJobs.PlayerCache[src]
    if not pData then return false, false end

    local cid = pData.charId
    local currentJob = pData.job
    local jobConfig = Config.Jobs[currentJob]

    if not jobConfig or not jobConfig.canDuty then
        return false, false
    end

    local newDuty = (forceDuty ~= nil) and forceDuty or not pData.duty

    -- 1. Actualización en memoria
    pData.duty = newDuty

    -- 2. Actualización en StateBags para sincronización cliente inmediata
    Player(src).state:set('job_duty', newDuty, true)

    -- 3. Persistencia instantánea en base de datos
    MySQL.update('UPDATE characters SET job_duty = ? WHERE id = ?', {
        newDuty and 1 or 0,
        cid
    })

    -- 4. Notificación visual en el Banner Superior Aura RP
    local currentBadge = (currentJob == 'police') and (Player(src).state.badge or (pData and pData.badge)) or nil
    TriggerClientEvent('aura_hub:client:showDutyAnnouncement', src, {
        job = currentJob,
        label = jobConfig.label,
        isDuty = newDuty,
        isPolice = (currentJob == 'police'),
        badge = currentBadge
    })

    UpdateAllBusinessStates()

    TriggerEvent('aura_jobs:server:onDutyChange', src, currentJob, newDuty)
    TriggerClientEvent('aura_jobs:client:onDutyChange', src, currentJob, newDuty)

    return true, newDuty
end
exports('SetDuty', SetDuty)

--- Asigna un nuevo empleo y rango a un personaje
--- @param srcOrCharId number Source del jugador o CharId
--- @param newJob string Identificador del trabajo
--- @param newGrade number Rango numérico
--- @return boolean success, string message
local function SetJob(srcOrCharId, newJob, newGrade)
    local jobConfig = Config.Jobs[newJob]
    if not jobConfig then return false, "INVALID_JOB" end

    newGrade = tonumber(newGrade) or 0
    if not jobConfig.grades[newGrade] then
        newGrade = 0
    end

    local src = nil
    local charId = nil

    if GetPlayerName(tostring(srcOrCharId)) then
        src = tonumber(srcOrCharId)
        charId = GetCharacterId(src)
    else
        charId = tonumber(srcOrCharId)
        for pSrc, pData in pairs(AuraJobs.PlayerCache) do
            if pData.charId == charId then
                src = pSrc
                break
            end
        end
    end

    if not charId then return false, "CHARACTER_NOT_FOUND" end

    -- Actualizar Base de Datos
    MySQL.update.await('UPDATE characters SET job = ?, job_grade = ?, job_duty = 0 WHERE id = ?', {
        newJob,
        newGrade,
        charId
    })

    -- Si se asigna policía, asegurar que tenga número de placa generado
    if newJob == 'police' then
        EnsurePoliceBadge(charId, src)
    end

    -- Si el jugador está conectado, sincronizar en vivo
    if src then
        local activeChar = exports.aura_multichar:GetActiveCharacter(src)
        if activeChar then
            activeChar.job = newJob
            activeChar.job_grade = newGrade
        end

        LoadPlayerJob(src, charId)
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Contrato Laboral',
            description = string.format("Tu puesto ha sido actualizado a %s - %s.", jobConfig.label, jobConfig.grades[newGrade].name),
            type = 'inform'
        })
    end

    return true, "JOB_SET_SUCCESS"
end
exports('SetJob', SetJob)

--- Obtiene el empleo y datos de un jugador
--- @param src number Source del jugador
--- @return table { name = string, label = string, grade = number, gradeLabel = string, duty = boolean, isBusiness = boolean, isGang = boolean, isBoss = boolean, badge = string | nil }
local function GetJob(src)
    src = tonumber(src)
    if not src then return nil end
    local pState = Player(src).state
    local jobName = pState.job or 'unemployed'
    local grade = pState.job_grade or 0
    local duty = pState.job_duty or false
    local jobConfig = Config.Jobs[jobName] or Config.Jobs['unemployed']
    local gradeConfig = jobConfig.grades[grade] or jobConfig.grades[0]

    local isBoss = (gradeConfig and gradeConfig.isBoss == true) or false
    local isGang = (jobConfig and jobConfig.isGang == true) or false
    local isBusiness = (jobConfig and jobConfig.isBusiness == true) or false
    local badge = (jobName == 'police') and (pState.badge or pState.callsign) or nil

    return {
        name = jobName,
        label = jobConfig.label,
        grade = grade,
        gradeLabel = gradeConfig and gradeConfig.name or "Rango 0",
        salary = gradeConfig and gradeConfig.salary or 0,
        duty = duty,
        isBusiness = isBusiness,
        canDuty = jobConfig.canDuty or false,
        isGang = isGang,
        isBoss = isBoss,
        badge = badge,
        callsign = badge
    }
end
exports('GetJob', GetJob)

--- Comprueba si un jugador es jefe/director de su empleo
--- @param src number Source
--- @return boolean isBoss, string jobName, string jobLabel
local function IsBoss(src)
    local jobData = GetJob(src)
    if not jobData then return false, nil, nil end
    return jobData.isBoss == true, jobData.name, jobData.label
end
exports('IsBoss', IsBoss)

--- Obtiene la configuración de un empleo
--- @param jobName string
--- @return table | nil
local function GetJobConfig(jobName)
    return Config.Jobs[jobName]
end
exports('GetJobConfig', GetJobConfig)

--- Obtiene la lista completa de empleos configurados
--- @return table
local function GetAllJobs()
    return Config.Jobs
end
exports('GetAllJobs', GetAllJobs)

--- Comprueba si un jugador está de servicio
--- @param src number Source
--- @return boolean
local function IsOnDuty(src)
    src = tonumber(src)
    if not src then return false end
    return Player(src).state.job_duty == true
end
exports('IsOnDuty', IsOnDuty)

-- ============================================================================
-- COMANDOS DE CHAT Y ADMINISTRACIÓN
-- ============================================================================

-- Comando para alternar servicio
RegisterCommand('duty', function(source)
    if source == 0 then return end
    SetDuty(source)
end, false)

RegisterCommand('servicio', function(source)
    if source == 0 then return end
    SetDuty(source)
end, false)

-- Comando Administrativo para asignar trabajos: /setjob [id] [trabajo] [grado]
RegisterCommand('setjob', function(source, args)
    if source ~= 0 and not IsPlayerAceAllowed(tostring(source), 'command.setjob') and not IsPlayerAceAllowed(tostring(source), 'group.admin') then
        if source ~= 0 then
            TriggerClientEvent('ox_lib:notify', source, { title = 'Acceso Denegado', description = 'No tienes permisos de administrador.', type = 'error' })
        end
        return
    end

    local targetSrc = tonumber(args[1])
    local targetJob = args[2]
    local targetGrade = tonumber(args[3]) or 0

    if not targetSrc or not targetJob then
        local msg = "Uso: /setjob [ID_Jugador] [Nombre_Trabajo] [Grado_Opcional]"
        if source == 0 then print(msg) else TriggerClientEvent('ox_lib:notify', source, { title = 'Sintaxis', description = msg, type = 'inform' }) end
        return
    end

    local success, err = SetJob(targetSrc, targetJob, targetGrade)
    if success then
        local msg = string.format("Trabajo %s (Grado %d) asignado con éxito a ID %d.", targetJob, targetGrade, targetSrc)
        if source == 0 then print(msg) else TriggerClientEvent('ox_lib:notify', source, { title = 'Éxito', description = msg, type = 'success' }) end
    else
        local msg = string.format("Error al asignar trabajo: %s", tostring(err))
        if source == 0 then print(msg) else TriggerClientEvent('ox_lib:notify', source, { title = 'Error', description = msg, type = 'error' }) end
    end
end, true)

-- Comando Administrativo dedicado para asignar Comisario / Jefe de Policía: /setcomisario [id], /setpolicechief [id] o /setjefepolicia [id]
local function HandleSetPoliceChief(source, args)
    if source ~= 0 and not IsPlayerAceAllowed(tostring(source), 'command.setpolicechief') and not IsPlayerAceAllowed(tostring(source), 'command.setcomisario') and not IsPlayerAceAllowed(tostring(source), 'command.setjob') and not IsPlayerAceAllowed(tostring(source), 'group.admin') then
        if source ~= 0 then
            TriggerClientEvent('ox_lib:notify', source, { title = 'Acceso Denegado', description = 'No tienes permisos de administrador.', type = 'error' })
        end
        return
    end

    local targetSrc = tonumber(args[1])
    if not targetSrc or not GetPlayerName(tostring(targetSrc)) then
        local msg = "Uso: /setcomisario [ID_Servidor] o /setpolicechief [ID_Servidor]"
        if source == 0 then print(msg) else TriggerClientEvent('ox_lib:notify', source, { title = 'Sintaxis', description = msg, type = 'inform' }) end
        return
    end

    local success, err = SetJob(targetSrc, 'police', 5)
    if success then
        local targetName = GetPlayerName(tostring(targetSrc))
        local msg = string.format("¡%s (ID %d) ha sido nombrado COMISARIO (LSPD - Grado 5) exitosamente!", targetName, targetSrc)
        if source == 0 then print(msg) else TriggerClientEvent('ox_lib:notify', source, { title = 'Comisario Asignado', description = msg, type = 'success', duration = 8000 }) end
        TriggerClientEvent('ox_lib:notify', targetSrc, {
            title = 'Nombramiento Oficial LSPD',
            description = 'Has sido nombrado COMISARIO de Los Santos por la administración del servidor.',
            type = 'success',
            duration = 10000
        })
    else
        local msg = string.format("Error al asignar Comisario: %s", tostring(err))
        if source == 0 then print(msg) else TriggerClientEvent('ox_lib:notify', source, { title = 'Error', description = msg, type = 'error' }) end
    end
end

RegisterCommand('setcomisario', HandleSetPoliceChief, true)
RegisterCommand('darcomisario', HandleSetPoliceChief, true)
RegisterCommand('setpolicechief', HandleSetPoliceChief, true)
RegisterCommand('setjefepolicia', HandleSetPoliceChief, true)
RegisterCommand('darjefepolicia', HandleSetPoliceChief, true)

-- Comando para Jefes: /contratar [ID]
RegisterCommand('contratar', function(source, args)
    if source == 0 then return end
    
    local isBoss, jobName, jobLabel = IsBoss(source)
    if not isBoss then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Acceso Denegado', description = 'No eres jefe de ninguna empresa.', type = 'error' })
        return
    end

    local targetSrc = tonumber(args[1])
    if not targetSrc then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Sintaxis', description = 'Uso: /contratar [ID]', type = 'inform' })
        return
    end
    
    local targetData = GetJob(targetSrc)
    if not targetData then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Error', description = 'Jugador no encontrado.', type = 'error' })
        return
    end

    local success, err = SetJob(targetSrc, jobName, 1) -- Grado 1 por defecto
    if success then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Gestión', description = 'Has contratado a un nuevo empleado.', type = 'success' })
    end
end, false)

-- Comando para Jefes: /despedir [ID]
RegisterCommand('despedir', function(source, args)
    if source == 0 then return end
    
    local isBoss, jobName, jobLabel = IsBoss(source)
    if not isBoss then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Acceso Denegado', description = 'No eres jefe de ninguna empresa.', type = 'error' })
        return
    end

    local targetSrc = tonumber(args[1])
    if not targetSrc then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Sintaxis', description = 'Uso: /despedir [ID]', type = 'inform' })
        return
    end

    local targetData = GetJob(targetSrc)
    if not targetData or targetData.name ~= jobName then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Error', description = 'Ese jugador no trabaja en tu empresa.', type = 'error' })
        return
    end

    if targetData.isBoss and targetSrc ~= source then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Error', description = 'No puedes despedir a otro jefe.', type = 'error' })
        return
    end

    local success, err = SetJob(targetSrc, 'unemployed', 0)
    if success then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Gestión', description = 'Has despedido al empleado correctamente.', type = 'success' })
    end
end, false)

-- Callback para cliente ox_lib
lib.callback.register('aura_jobs:getJobData', function(source)
    return GetJob(source)
end)
