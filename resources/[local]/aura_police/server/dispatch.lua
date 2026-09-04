-- ============================================================================
-- AURA POLICE: SERVER SMART DISPATCH ENGINE
-- Anti-Spam Cooldown, Dispatch Broadcaster, Unit Assignment & Active Calls Hub
-- ============================================================================

local LastShooterCooldown = {}  -- [src] = timestamp
local LastTheftCooldown = {}    -- [plate] = timestamp
local RecentDispatchHistory = {} -- Buffer de las últimas 50 alertas

local function IsCopOnDuty(src)
    local pState = Player(src).state
    return pState.job == 'police' and pState.job_duty == true
end

--- Transmite una nueva alerta o actualización a todos los policías de servicio
--- @param alertData table Datos del aviso
local function BroadcastDispatchAlert(alertData)
    -- Insertar en el historial de llamadas en memoria (máximo 50)
    table.insert(RecentDispatchHistory, 1, alertData)
    if #RecentDispatchHistory > 50 then
        table.remove(RecentDispatchHistory)
    end

    -- Difundir a cada policía conectado y de servicio
    for _, pid in ipairs(GetPlayers()) do
        local pSrc = tonumber(pid)
        if pSrc and IsCopOnDuty(pSrc) then
            TriggerClientEvent('aura_police:client:receiveDispatchAlert', pSrc, alertData)
        end
    end
end

--- Sincroniza la actualización de estado de una llamada existente a todos los policías
--- @param updatedCall table
local function BroadcastCallUpdate(updatedCall)
    for _, pid in ipairs(GetPlayers()) do
        local pSrc = tonumber(pid)
        if pSrc and IsCopOnDuty(pSrc) then
            TriggerClientEvent('aura_police:client:syncCallUpdate', pSrc, updatedCall)
        end
    end
end

-- ============================================================================
-- 1. RECEPCIÓN DE DISPAROS DE ARMA DE FUEGO (10-71)
-- ============================================================================

RegisterNetEvent('aura_police:server:reportGunshot', function(data)
    local src = source
    if not src or not data or not data.coords then return end

    local now = os.time()
    local cooldown = (Config.Dispatch and Config.Dispatch.gunshotCooldown) or 15
    -- Validar cooldown anti-spam configurado en el servidor
    if LastShooterCooldown[src] and (now - LastShooterCooldown[src]) < cooldown then
        return
    end
    LastShooterCooldown[src] = now

    local alertData = {
        id = #RecentDispatchHistory + 1,
        type = 'gunshot',
        code = '10-71',
        title = 'Disparos de Arma de Fuego',
        description = string.format("Detonaciones reportadas en %s (%s).", data.street or "Vía Pública", data.zone or "Área Urbana"),
        coords = data.coords,
        street = data.street or "Vía Pública",
        zone = data.zone or "Área Urbana",
        time = os.date('%H:%M:%S'),
        timestamp = now,
        maxUnits = 2,           -- Máximo 2 patrullas asignadas para disparos
        units = {},             -- Lista de agentes asignados
        status = 'pending'      -- 'pending', 'responding', 'full', 'resolved'
    }

    BroadcastDispatchAlert(alertData)
end)

-- ============================================================================
-- 2. RECEPCIÓN DE ROBO DE VEHÍCULO EN CURSO (10-99)
-- ============================================================================

RegisterNetEvent('aura_police:server:reportVehicleTheft', function(data)
    local src = source
    if not data or not data.coords or not data.plate then return end

    local plate = string.upper(tostring(data.plate))
    local now = os.time()

    -- Cooldown anti-spam de 30 segundos por la misma matrícula
    if LastTheftCooldown[plate] and (now - LastTheftCooldown[plate]) < 30 then
        return
    end
    LastTheftCooldown[plate] = now

    local alertData = {
        id = #RecentDispatchHistory + 1,
        type = 'vehicle_theft',
        code = '10-99',
        title = 'Robo de Vehículo en Curso',
        description = string.format("Sustracción de vehículo [%s] mod. '%s' en %s (%s).", plate, data.model or "Desconocido", data.street or "Vía Pública", data.zone or "Área Urbana"),
        coords = data.coords,
        street = data.street or "Vía Pública",
        zone = data.zone or "Área Urbana",
        plate = plate,
        model = data.model or "Vehículo",
        time = os.date('%H:%M:%S'),
        timestamp = now,
        maxUnits = 1,           -- Máximo 1 patrulla asignada para robos de vehículos
        units = {},
        status = 'pending'
    }

    BroadcastDispatchAlert(alertData)
end)

-- ============================================================================
-- 3. SISTEMA DE RESPUESTA Y ASIGNACIÓN DE PATRULLAS
-- ============================================================================

local function FindCallById(callId)
    for _, call in ipairs(RecentDispatchHistory) do
        if call.id == callId then
            return call
        end
    end
    return nil
end

--- Un policía acepta / acude a una llamada de despacho
lib.callback.register('aura_police:server:respondToCall', function(source, callId)
    local src = source
    if not IsCopOnDuty(src) then return false, "No estás en servicio policial." end

    local call = nil
    if callId then
        call = FindCallById(tonumber(callId))
    else
        -- Si no especifica ID, toma la última llamada no resuelta
        for _, c in ipairs(RecentDispatchHistory) do
            if c.status ~= 'resolved' then
                call = c
                break
            end
        end
    end

    if not call then
        return false, "No hay ningún aviso activo disponible."
    end

    if call.status == 'resolved' then
        return false, "Este aviso ya ha sido resuelto y archivado."
    end

    -- Comprobar si este oficial ya estaba asignado a la llamada
    for _, u in ipairs(call.units) do
        if u.src == src then
            return true, "Ya estás asignado a este aviso. Ruta GPS actualizada.", call.coords, call
        end
    end

    -- Comprobar límite de patrullas para este aviso
    if #call.units >= (call.maxUnits or 2) then
        return false, string.format("El cupo de patrullas para este aviso está cubierto (%d/%d).", #call.units, call.maxUnits or 2), call.coords, call
    end

    local char = exports.aura_multichar:GetActiveCharacter(src)
    local officerName = char and string.format("%s %s", char.firstname or "Oficial", char.lastname or "") or ("Oficial #" .. src)
    local callsign = char and char.badge or ("UNIT-" .. src)

    table.insert(call.units, {
        src = src,
        name = officerName,
        callsign = callsign
    })

    if #call.units >= (call.maxUnits or 2) then
        call.status = 'full'
    else
        call.status = 'responding'
    end

    -- Sincronizar actualización a todas las patrullas en tiempo real
    BroadcastCallUpdate(call)

    -- Mensaje de radio táctico a todos los policías de servicio
    for _, pid in ipairs(GetPlayers()) do
        local pSrc = tonumber(pid)
        if pSrc and IsCopOnDuty(pSrc) and pSrc ~= src then
            TriggerClientEvent('ox_lib:notify', pSrc, {
                title = string.format("Central 911 | [%s]", call.code),
                description = string.format("🚔 %s en camino hacia %s (%d/%d Unidades).", officerName, call.street, #call.units, call.maxUnits),
                type = 'inform',
                duration = 6000
            })
        end
    end

    return true, string.format("Te has asignado al aviso [%s]. Ruta GPS fijada.", call.code), call.coords, call
end)

--- Un policía cancela su respuesta a una llamada
lib.callback.register('aura_police:server:cancelCallResponse', function(source, callId)
    local src = source
    if not IsCopOnDuty(src) then return false, "No autorizado." end

    local call = FindCallById(tonumber(callId))
    if not call then return false, "Aviso no encontrado." end

    local removed = false
    for i, u in ipairs(call.units) do
        if u.src == src then
            table.remove(call.units, i)
            removed = true
            break
        end
    end

    if not removed then
        return false, "No estabas asignado a este aviso."
    end

    if #call.units == 0 then
        call.status = 'pending'
    else
        call.status = 'responding'
    end

    BroadcastCallUpdate(call)
    return true, "Has cancelado tu respuesta a este aviso.", call
end)

--- Marcar un aviso como resuelto
lib.callback.register('aura_police:server:resolveCall', function(source, callId)
    local src = source
    if not IsCopOnDuty(src) then return false, "No autorizado." end

    local call = FindCallById(tonumber(callId))
    if not call then return false, "Aviso no encontrado." end

    call.status = 'resolved'
    BroadcastCallUpdate(call)
    return true, "Aviso marcado como resuelto con éxito.", call
end)

--- Obtener todas las llamadas activas
lib.callback.register('aura_police:server:getDispatchBoardCalls', function(source)
    if not IsCopOnDuty(source) then return {} end
    return RecentDispatchHistory
end)

-- Callback para aura_hub/client/main.lua
lib.callback.register('aura_police:server:getDispatchHistory', function(source)
    if not IsCopOnDuty(source) then return {} end
    return RecentDispatchHistory
end)

-- Exports
exports('GetRecentDispatchCalls', function() return RecentDispatchHistory end)
