-- ============================================================================
-- AURA EMS: CLIENT SMART DISPATCH CONTROLLER
-- Medical Alert Reception, Blips, Tactical Response [G] & Active Calls Board [U]
-- ============================================================================

local ActiveDispatchBlips = {}
local LatestDispatchCoords = nil
local LatestCallId = nil
local IsBoardOpen = false

-- ============================================================================
-- 1. RECEPTOR DE ALERTAS Y BLIPS (MÉDICOS EN SERVICIO)
-- ============================================================================

local function CreateMedicalDispatchBlip(alert)
    local coords = alert.coords

    -- 1. Blip de Icono Cruz Médica Centrado
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, Config.Dispatch.blipSprite or 153)
    SetBlipScale(blip, 1.2)
    SetBlipColour(blip, Config.Dispatch.blipColor or 1)
    SetBlipAsShortRange(blip, false)
    SetBlipFlashes(blip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(string.format("[%s] %s", alert.code or "10-33", alert.title or "Emergencia Médica"))
    EndTextCommandSetBlipName(blip)

    -- 2. Blip de Radio Perimetral
    local radiusBlip = AddBlipForRadius(coords.x, coords.y, coords.z, Config.Dispatch.radiusSize or 70.0)
    SetBlipColour(radiusBlip, Config.Dispatch.radiusColor or 1)
    SetBlipAlpha(radiusBlip, Config.Dispatch.radiusAlpha or 160)

    local blipDuration = (Config.Dispatch.blipDuration or 120) * 1000

    table.insert(ActiveDispatchBlips, {
        blip = blip,
        radiusBlip = radiusBlip,
        createdAt = GetGameTimer(),
        duration = blipDuration
    })
end

RegisterNetEvent('aura_ems:client:receiveDispatchAlert', function(alert)
    local pState = LocalPlayer.state
    if not (pState.job == Config.JobName and pState.job_duty == true) then return end

    LatestDispatchCoords = alert.coords
    LatestCallId = alert.id

    -- Sonido de llamada médica de emergencia
    PlaySoundFrontend(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", false)

    -- Crear blip temporal
    CreateMedicalDispatchBlip(alert)

    -- Calcular distancia en metros desde el paramédico hasta la víctima
    local pedCoords = GetEntityCoords(PlayerPedId())
    local dist = math.floor(#(pedCoords - vector3(alert.coords.x, alert.coords.y, alert.coords.z)))
    alert.distance = dist

    -- Enviar alerta al HUD NUI
    SendNUIMessage({
        action = 'dispatchAlert',
        alert = alert
    })
end)

RegisterNetEvent('aura_ems:client:syncCallUpdate', function(updatedCall)
    local pState = LocalPlayer.state
    if not (pState.job == Config.JobName and pState.job_duty == true) then return end

    SendNUIMessage({
        action = 'syncCallUpdate',
        call = updatedCall
    })
end)

-- Hilo de gestión de opacidad (fade-out) y borrado a los 2 minutos
CreateThread(function()
    while true do
        Wait(2000)
        local now = GetGameTimer()
        for i = #ActiveDispatchBlips, 1, -1 do
            local item = ActiveDispatchBlips[i]
            local elapsed = now - item.createdAt
            if elapsed >= item.duration then
                if DoesBlipExist(item.blip) then RemoveBlip(item.blip) end
                if DoesBlipExist(item.radiusBlip) then RemoveBlip(item.radiusBlip) end
                table.remove(ActiveDispatchBlips, i)
            else
                local remaining = item.duration - elapsed
                if remaining <= 30000 then
                    local alphaFactor = remaining / 30000
                    if DoesBlipExist(item.blip) then
                        SetBlipAlpha(item.blip, math.max(10, math.floor(255 * alphaFactor)))
                    end
                    if DoesBlipExist(item.radiusBlip) then
                        SetBlipAlpha(item.radiusBlip, math.max(10, math.floor(160 * alphaFactor)))
                    end
                end
            end
        end
    end
end)

-- ============================================================================
-- 2. RESPUESTA TÁCTICA [G]: ASIGNARSE A LA LLAMADA Y FIJAR GPS
-- ============================================================================

local function RespondToLatestCall()
    local pState = LocalPlayer.state
    if not (pState.job == Config.JobName and pState.job_duty == true) then return end

    lib.callback('aura_ems:server:respondToCall', false, function(success, message, coords)
        if success then
            if coords then
                SetNewWaypoint(coords.x, coords.y)
            elseif LatestDispatchCoords then
                SetNewWaypoint(LatestDispatchCoords.x, LatestDispatchCoords.y)
            end
            PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
            lib.notify({
                title = 'Centralita EMS',
                description = message,
                type = 'success',
                icon = 'location-dot',
                duration = 6000
            })
        else
            lib.notify({
                title = 'Centralita EMS',
                description = message,
                type = 'error',
                duration = 6000
            })
        end
    end, LatestCallId)
end

RegisterCommand('dispatch_ems_gps', RespondToLatestCall, false)
RegisterKeyMapping('dispatch_ems_gps', 'Acudir / Responder a última emergencia médica [GPS]', 'keyboard', 'G')

-- ============================================================================
-- 3. CENTRALITA DE AVISOS MÉDICOS [U] (DISPATCH BOARD NUI)
-- ============================================================================

local function ToggleDispatchBoard()
    local pState = LocalPlayer.state
    if not (pState.job == Config.JobName and pState.job_duty == true) then
        lib.notify({
            title = 'Centralita EMS',
            description = 'Debes estar de servicio como personal médico para abrir la central.',
            type = 'error'
        })
        return
    end

    if IsBoardOpen then
        IsBoardOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'closeDispatchBoard' })
        return
    end

    lib.callback('aura_ems:server:getDispatchBoardCalls', false, function(calls)
        IsBoardOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openDispatchBoard',
            calls = calls or {},
            mySrc = GetPlayerServerId(PlayerId())
        })
    end)
end

RegisterCommand('dispatch_ems_board', ToggleDispatchBoard, false)
RegisterKeyMapping('dispatch_ems_board', 'Abrir Central de Avisos Médicos (10-33)', 'keyboard', 'U')

-- ============================================================================
-- 4. NUI CALLBACKS DE LA CENTRAL DE AVISOS
-- ============================================================================

RegisterNUICallback('closeDispatchBoard', function(_, cb)
    IsBoardOpen = false
    SetNuiFocus(false, false)
    cb(true)
end)

RegisterNUICallback('respondDispatchCall', function(data, cb)
    local callId = tonumber(data.callId)
    lib.callback('aura_ems:server:respondToCall', false, function(success, message, coords)
        if success and coords then
            SetNewWaypoint(coords.x, coords.y)
        end
        cb({ success = success, message = message })
    end, callId)
end)

RegisterNUICallback('cancelDispatchCall', function(data, cb)
    local callId = tonumber(data.callId)
    lib.callback('aura_ems:server:cancelCallResponse', false, function(success, message)
        cb({ success = success, message = message })
    end, callId)
end)

RegisterNUICallback('resolveDispatchCall', function(data, cb)
    local callId = tonumber(data.callId)
    lib.callback('aura_ems:server:resolveCall', false, function(success, message)
        cb({ success = success, message = message })
    end, callId)
end)

RegisterNUICallback('setDispatchGps', function(data, cb)
    if data and data.x and data.y then
        SetNewWaypoint(tonumber(data.x), tonumber(data.y))
        lib.notify({ title = 'Centralita EMS', description = 'Ruta GPS fijada en la llamada médica.', type = 'success' })
    end
    cb(true)
end)
