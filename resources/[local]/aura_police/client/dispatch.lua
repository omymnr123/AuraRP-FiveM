-- ============================================================================
-- AURA POLICE: CLIENT SMART DISPATCH CONTROLLER
-- Gunshot Detection, Wilderness Filter, Tactical Response Hub & Active Calls Modal
-- ============================================================================

local LastGunshotTime = 0
local ActiveDispatchBlips = {}
local LatestDispatchCoords = nil
local LatestCallId = nil
local IsBoardOpen = false

-- Zonas rústicas, desérticas, de montaña y mar abierto excluidas de disparos automáticos
local WildernessZones = {
    ['MTCHIL']  = true, -- Mount Chiliad
    ['MTGORDO'] = true, -- Mount Gordo
    ['PALFOR']  = true, -- Paleto Forest
    ['CCREAK']  = true, -- Cassidy Creek
    ['MTJOSE']  = true, -- Mount Josiah
    ['LACT']    = true, -- Land Act Reservoir
    ['ALAMO']   = true, -- Alamo Sea
    ['SANCHIA'] = true, -- San Chianski Mountain Range
    ['TATAMO']  = true, -- Tataviam Mountains
    ['OCEANA']  = true  -- Pacific Ocean
}

-- Armas que NO deben generar alerta de disparos (no letales, arrojadizas, herramientas)
local IgnoredWeapons = {
    [`WEAPON_STUNGUN`]            = true,
    [`WEAPON_FLAREGUN`]           = true,
    [`WEAPON_FIREEXTINGUISHER`]   = true,
    [`WEAPON_PETROLCAN`]          = true,
    [`WEAPON_HAZARDCAN`]          = true,
    [`WEAPON_SNOWBALL`]           = true,
    [`WEAPON_BALL`]               = true,
    [`WEAPON_SMOKEGRENADE`]       = true,
    [`WEAPON_BZGAS`]              = true
}

-- ============================================================================
-- 1. DETECCIÓN AUTOMÁTICA DE DISPAROS DE ARMA DE FUEGO
-- ============================================================================

CreateThread(function()
    while true do
        local sleep = 400
        local ped = cache.ped

        -- Cuando el ped está empuñando arma de fuego, evaluar cada tick (0ms) para no perder ningún frame de disparo
        if IsPedArmed(ped, 4) or IsPedArmed(ped, 6) then
            sleep = 0
            if IsPedShooting(ped) then
                local currentTimer = GetGameTimer()
                local cooldownMs = ((Config.Dispatch and Config.Dispatch.gunshotCooldown) or 15) * 1000

                -- Cooldown anti-spam: se respeta el intervalo configurado
                if (currentTimer - LastGunshotTime) >= cooldownMs then
                    -- 1. Exclusión obligatoria: Silenciador montado en el arma
                    if not IsPedCurrentWeaponSilenced(ped) then
                        local weaponHash = GetSelectedPedWeapon(ped)
                        if not IgnoredWeapons[weaponHash] then
                            local coords = GetEntityCoords(ped)
                            local zone = GetNameOfZone(coords.x, coords.y, coords.z)

                            -- 2. Exclusión obligatoria: Zonas rústicas (Blacklist)
                            if not WildernessZones[zone] then
                                LastGunshotTime = currentTimer

                                local s1, s2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
                                local street = GetStreetNameFromHashKey(s1)
                                if s2 ~= 0 then
                                    street = street .. " / " .. GetStreetNameFromHashKey(s2)
                                end

                                local zoneLabel = GetLabelText(zone)
                                if zoneLabel == "NULL" or not zoneLabel then
                                    zoneLabel = zone
                                end

                                TriggerServerEvent('aura_police:server:reportGunshot', {
                                    coords = coords,
                                    street = street,
                                    zone = zoneLabel
                                })
                            end
                        end
                    end
                end
                Wait(250)
            end
        end

        Wait(sleep)
    end
end)

-- ============================================================================
-- 2. HOOK EXPORTABLE: ROBO DE VEHÍCULO EN CURSO (LOCKPICK / GANZÚA)
-- ============================================================================

local function TriggerVehicleTheftAlert(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return false end

    local coords = GetEntityCoords(vehicle)
    local s1, s2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = GetStreetNameFromHashKey(s1)
    if s2 ~= 0 then
        street = street .. " / " .. GetStreetNameFromHashKey(s2)
    end

    local zone = GetNameOfZone(coords.x, coords.y, coords.z)
    local zoneLabel = GetLabelText(zone)
    if zoneLabel == "NULL" or not zoneLabel then
        zoneLabel = zone
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    local modelHash = GetEntityModel(vehicle)
    local modelName = GetLabelText(GetDisplayNameFromVehicleModel(modelHash))
    if modelName == "NULL" or not modelName then
        modelName = GetDisplayNameFromVehicleModel(modelHash)
    end

    TriggerServerEvent('aura_police:server:reportVehicleTheft', {
        coords = coords,
        street = street,
        zone = zoneLabel,
        plate = plate,
        model = modelName
    })

    return true
end
exports('TriggerVehicleTheftAlert', TriggerVehicleTheftAlert)

-- ============================================================================
-- 3. RECEPTOR DE ALERTAS Y BLIPS (POLICÍAS EN SERVICIO)
-- ============================================================================

local function CreateDispatchBlip(alert)
    local coords = alert.coords
    local isGunshot = alert.type == 'gunshot'

    -- 1. Blip de Icono Centrado
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, isGunshot and 110 or 225)
    SetBlipScale(blip, 1.15)
    SetBlipColour(blip, isGunshot and 1 or 17)
    SetBlipAsShortRange(blip, false)
    SetBlipFlashes(blip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(string.format("[%s] %s", alert.code, alert.title))
    EndTextCommandSetBlipName(blip)

    -- 2. Blip de Radio Perimetral
    local radiusBlip = AddBlipForRadius(coords.x, coords.y, coords.z, 70.0)
    SetBlipColour(radiusBlip, isGunshot and 1 or 17)
    SetBlipAlpha(radiusBlip, 170)

    local blipDuration = ((Config.Dispatch and Config.Dispatch.blipDuration) or 120) * 1000

    table.insert(ActiveDispatchBlips, {
        blip = blip,
        radiusBlip = radiusBlip,
        createdAt = GetGameTimer(),
        duration = blipDuration
    })
end

RegisterNetEvent('aura_police:client:receiveDispatchAlert', function(alert)
    local pState = LocalPlayer.state
    if not (pState.job == 'police' and pState.job_duty == true) then return end

    LatestDispatchCoords = alert.coords
    LatestCallId = alert.id

    -- Audio de llamada policial
    PlaySoundFrontend(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", false)

    -- Blip en mapa con fade-out de 2 minutos
    CreateDispatchBlip(alert)

    -- Alerta NUI Táctica Exclusiva (Banner HUD Aura RP)
    SendNUIMessage({
        action = 'dispatchAlert',
        alert = alert
    })
end)

RegisterNetEvent('aura_police:client:syncCallUpdate', function(updatedCall)
    local pState = LocalPlayer.state
    if not (pState.job == 'police' and pState.job_duty == true) then return end

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
                        SetBlipAlpha(item.radiusBlip, math.max(10, math.floor(170 * alphaFactor)))
                    end
                end
            end
        end
    end
end)

-- ============================================================================
-- 4. RESPUESTA TÁCTICA [G]: ASIGNARSE A LA LLAMADA Y FIJAR GPS
-- ============================================================================

local function RespondToLatestCall()
    local pState = LocalPlayer.state
    if not (pState.job == 'police' and pState.job_duty == true) then return end

    lib.callback('aura_police:server:respondToCall', false, function(success, message, coords)
        if success then
            if coords then
                SetNewWaypoint(coords.x, coords.y)
            elseif LatestDispatchCoords then
                SetNewWaypoint(LatestDispatchCoords.x, LatestDispatchCoords.y)
            end
            PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
            lib.notify({
                title = 'Centralita LSPD',
                description = message,
                type = 'success',
                duration = 6000
            })
        else
            lib.notify({
                title = 'Centralita LSPD',
                description = message,
                type = 'error',
                duration = 6000
            })
        end
    end, LatestCallId)
end

RegisterCommand('dispatch_gps', RespondToLatestCall, false)
RegisterKeyMapping('dispatch_gps', 'Acudir / Responder a último aviso y fijar GPS', 'keyboard', 'G')

-- ============================================================================
-- 5. CENTRALITA DE AVISOS POLICIALES [U] (TACTICAL BOARD NUI)
-- ============================================================================

local function ToggleDispatchBoard()
    local pState = LocalPlayer.state
    if not (pState.job == 'police' and pState.job_duty == true) then
        lib.notify({
            title = 'Centralita LSPD',
            description = 'Debes estar de servicio como policía para abrir la central.',
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

    lib.callback('aura_police:server:getDispatchBoardCalls', false, function(calls)
        IsBoardOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openDispatchBoard',
            calls = calls or {},
            mySrc = GetPlayerServerId(PlayerId())
        })
    end)
end

RegisterCommand('dispatch_board', ToggleDispatchBoard, false)
RegisterKeyMapping('dispatch_board', 'Abrir Central de Avisos Policiales (911)', 'keyboard', 'U')

-- ============================================================================
-- 6. NUI CALLBACKS DE LA CENTRAL DE AVISOS
-- ============================================================================

RegisterNUICallback('closeDispatchBoard', function(_, cb)
    IsBoardOpen = false
    SetNuiFocus(false, false)
    cb(true)
end)

RegisterNUICallback('respondDispatchCall', function(data, cb)
    local callId = tonumber(data.callId)
    lib.callback('aura_police:server:respondToCall', false, function(success, message, coords)
        if success and coords then
            SetNewWaypoint(coords.x, coords.y)
        end
        cb({ success = success, message = message })
    end, callId)
end)

RegisterNUICallback('cancelDispatchCall', function(data, cb)
    local callId = tonumber(data.callId)
    lib.callback('aura_police:server:cancelCallResponse', false, function(success, message)
        cb({ success = success, message = message })
    end, callId)
end)

RegisterNUICallback('resolveDispatchCall', function(data, cb)
    local callId = tonumber(data.callId)
    lib.callback('aura_police:server:resolveCall', false, function(success, message)
        cb({ success = success, message = message })
    end, callId)
end)

RegisterNUICallback('setDispatchGps', function(data, cb)
    if data and data.x and data.y then
        SetNewWaypoint(tonumber(data.x), tonumber(data.y))
        lib.notify({ title = 'Centralita LSPD', description = 'Ruta GPS fijada en el aviso.', type = 'success' })
    end
    cb(true)
end)
