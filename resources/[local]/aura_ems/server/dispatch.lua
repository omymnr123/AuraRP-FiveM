-- ============================================================================
-- AURA EMS: SERVER SMART DISPATCH ENGINE
-- Medical Emergency Broadcasts, Unit Response & Active Calls Management
-- ============================================================================

local RecentMedicalCalls = {} -- Buffer de últimas 50 alertas
local LastCallCooldown = {}   -- [src] = timestamp

local function IsEmsOnDuty(src)
    local pState = Player(src).state
    return pState.job == Config.JobName and pState.job_duty == true
end

--- Transmite una nueva alerta médica a todos los paramédicos de servicio
--- @param alertData table Datos del aviso
local function BroadcastMedicalAlert(alertData)
    table.insert(RecentMedicalCalls, 1, alertData)
    if #RecentMedicalCalls > 50 then
        table.remove(RecentMedicalCalls)
    end

    for _, pid in ipairs(GetPlayers()) do
        local pSrc = tonumber(pid)
        if pSrc and IsEmsOnDuty(pSrc) then
            TriggerClientEvent('aura_ems:client:receiveDispatchAlert', pSrc, alertData)
        end
    end
end

--- Sincroniza la actualización de estado de una llamada existente a todos los médicos
--- @param updatedCall table
local function BroadcastCallUpdate(updatedCall)
    for _, pid in ipairs(GetPlayers()) do
        local pSrc = tonumber(pid)
        if pSrc and IsEmsOnDuty(pSrc) then
            TriggerClientEvent('aura_ems:client:syncCallUpdate', pSrc, updatedCall)
        end
    end
end

-- ============================================================================
-- 1. RECEPCIÓN DE LLAMADAS DE EMERGENCIA POR COMA / PARADA (10-33)
-- ============================================================================

RegisterNetEvent('aura_ems:server:reportComaEmergency', function(data)
    local src = (data and data.src) or source
    if not data or not data.coords then return end

    local now = os.time()
    if LastCallCooldown[src] and (now - LastCallCooldown[src]) < 60 then
        return
    end
    LastCallCooldown[src] = now

    local patientName = data.name
    if not patientName and exports.aura_core and exports.aura_core.GetPlayer then
        local p = exports.aura_core:GetPlayer(src)
        if p then patientName = p.firstname .. " " .. p.lastname end
    end
    if not patientName then patientName = "Paciente Inconsciente" end

    local alertData = {
        id = #RecentMedicalCalls + 1,
        victimSrc = src,
        type = 'medical',
        code = '10-33',
        title = 'Emergencia Médica / Parada Cardíaca',
        description = string.format("Paciente %s en estado crítico agónico en %s (%s).", patientName, data.street or "Ubicación GPS", data.zone or "Área Sanitaria"),
        coords = data.coords,
        street = data.street or "Vía Pública",
        zone = data.zone or "Distrito Sanitario",
        patientName = patientName,
        deathReason = data.deathReason or "Trauma Crítico",
        time = os.date('%H:%M:%S'),
        timestamp = now,
        maxUnits = Config.Dispatch.maxUnitsPerCall or 2,
        units = {},
        status = 'pending' -- 'pending', 'responding', 'full', 'resolved'
    }

    BroadcastMedicalAlert(alertData)
end)

-- ============================================================================
-- 2. SISTEMA DE ASIGNACIÓN Y RESPUESTA A LA LLAMADA
-- ============================================================================

local function FindCallById(callId)
    for _, call in ipairs(RecentMedicalCalls) do
        if call.id == callId then
            return call
        end
    end
    return nil
end

--- Un médico acepta la llamada médica
lib.callback.register('aura_ems:server:respondToCall', function(source, callId)
    local src = source
    if not IsEmsOnDuty(src) then return false, "Debes estar de servicio como personal médico." end

    local call = nil
    if callId then
        call = FindCallById(tonumber(callId))
    else
        for _, c in ipairs(RecentMedicalCalls) do
            if c.status ~= 'resolved' then
                call = c
                break
            end
        end
    end

    if not call then
        return false, "No hay ningún aviso médico activo disponible."
    end

    if call.status == 'resolved' then
        return false, "Esta llamada ya ha sido atendida y cerrada."
    end

    -- Obtener nombre del médico
    local medicName = "Sanitario #" .. src
    if exports.aura_core and exports.aura_core.GetPlayer then
        local p = exports.aura_core:GetPlayer(src)
        if p and p.firstname then medicName = p.firstname .. " " .. p.lastname end
    end

    -- Verificar si ya estaba asignado
    local alreadyAssigned = false
    for _, u in ipairs(call.units) do
        if u.src == src then
            alreadyAssigned = true
            break
        end
    end

    if not alreadyAssigned then
        if #call.units >= (call.maxUnits or 2) then
            return false, "El cupo máximo de ambulancias ya está asignado a este aviso."
        end

        table.insert(call.units, {
            src = src,
            name = medicName,
            time = os.date('%H:%M:%S')
        })

        if #call.units >= (call.maxUnits or 2) then
            call.status = 'full'
        else
            call.status = 'responding'
        end

        BroadcastCallUpdate(call)
    end

    return true, string.format("Ruta GPS fijada al aviso #%s (%s).", call.id, call.street or "Ubicación"), call.coords
end)

--- Cancelar respuesta a una llamada
lib.callback.register('aura_ems:server:cancelCallResponse', function(source, callId)
    local src = source
    if not IsEmsOnDuty(src) then return false, "No estás de servicio." end

    local call = FindCallById(tonumber(callId))
    if not call then return false, "Aviso no encontrado." end

    for i, u in ipairs(call.units) do
        if u.src == src then
            table.remove(call.units, i)
            break
        end
    end

    if #call.units == 0 then
        call.status = 'pending'
    else
        call.status = 'responding'
    end

    BroadcastCallUpdate(call)
    return true, "Te has desasignado de la llamada médica."
end)

--- Marcar llamada como resuelta
lib.callback.register('aura_ems:server:resolveCall', function(source, callId)
    local src = source
    if not IsEmsOnDuty(src) then return false, "No estás de servicio." end

    local call = FindCallById(tonumber(callId))
    if not call then return false, "Aviso no encontrado." end

    call.status = 'resolved'
    call.resolvedBy = src
    call.resolvedAt = os.date('%H:%M:%S')

    BroadcastCallUpdate(call)
    return true, string.format("Aviso #%s marcado como RESUELTO.", call.id)
end)

--- Crear una llamada de misión médica (NPC / Simulador de Emergencias)
RegisterNetEvent('aura_ems:server:createEmergencyMissionCall', function(data)
    local src = source
    if not data or not data.coords then return end

    local now = os.time()
    local patientName = data.patientName or "Ciudadano Inconsciente"

    local alertData = {
        id = #RecentMedicalCalls + 1,
        missionId = data.missionId,
        isMission = true,
        dummyId = data.dummyId,
        type = 'medical',
        code = '10-33',
        title = data.title or 'Parada Cardiorrespiratoria / Paciente Inconsciente',
        description = string.format("Paciente %s en parada cardiorrespiratoria en %s (%s). Se requiere asistencia inmediata.", patientName, data.street or "Vía Pública", data.zone or "Los Santos"),
        coords = data.coords,
        street = data.street or "Vía Pública",
        zone = data.zone or "Los Santos",
        patientName = patientName,
        deathReason = data.deathReason or "Traumatismo Severo y Parada Cardíaca",
        time = os.date('%H:%M:%S'),
        timestamp = now,
        maxUnits = Config.Dispatch.maxUnitsPerCall or 2,
        units = {},
        status = 'pending'
    }

    BroadcastMedicalAlert(alertData)
end)

--- Resolver llamada por ID de misión o ID de aviso
RegisterNetEvent('aura_ems:server:resolveMissionCall', function(missionId, dummyId)
    local resolvedCall = nil
    for _, call in ipairs(RecentMedicalCalls) do
        if (missionId and call.missionId == missionId) or (dummyId and call.dummyId == dummyId) then
            call.status = 'resolved'
            call.resolvedAt = os.date('%H:%M:%S')
            resolvedCall = call
            break
        end
    end

    if resolvedCall then
        BroadcastCallUpdate(resolvedCall)

        for _, pid in ipairs(GetPlayers()) do
            local pSrc = tonumber(pid)
            if pSrc and IsEmsOnDuty(pSrc) then
                TriggerClientEvent('ox_lib:notify', pSrc, {
                    title = 'Central 10-33 | Emergencia Resuelta',
                    description = string.format("🚑 Paciente reanimado y estabilizado con éxito en %s.", resolvedCall.street or "la zona"),
                    type = 'success',
                    icon = 'heart-circle-check',
                    duration = 8000
                })
            end
        end
    end
end)

--- Obtener listado de llamadas activas para la Central de Avisos NUI
lib.callback.register('aura_ems:server:getDispatchBoardCalls', function(source)
    if not IsEmsOnDuty(source) then return {} end
    return RecentMedicalCalls
end)

lib.callback.register('aura_ems:server:getDispatchHistory', function(source)
    return RecentMedicalCalls
end)

exports('CreateMedicalAlert', BroadcastMedicalAlert)
exports('GetRecentDispatchCalls', function() return RecentMedicalCalls end)
