-- ============================================================================
-- AURA GANGS: CLIENT RADIO-CLANDESTINA & LIVE GPS BLIPS
-- PMA-Voice Bridges, Encrypted Frequencies & Gang Map Blips
-- ============================================================================

local CurrentGangRadio = {
    freq = 0,
    label = "Desconectado",
    color = "#00f2fe"
}

local ActiveGangBlips = {} -- [src] = blipHandle

-- ============================================================================
-- 1. SINCRONIZACIÓN DE CANAL CON PMA-VOICE
-- ============================================================================

RegisterNetEvent('aura_gangs:client:syncRadioChannel', function(frequency, label, color)
    CurrentGangRadio.freq = frequency or 0
    CurrentGangRadio.label = label or "Desconectado"
    CurrentGangRadio.color = color or "#00f2fe"

    if frequency and frequency > 0 then
        exports['pma-voice']:setRadioChannel(frequency)
        lib.notify({
            title = 'Red Clandestina de Radio',
            description = string.format('Conectado a %s (%.1f MHz)', label or "Emisora", frequency),
            type = 'success',
            icon = 'walkie-talkie'
        })
    else
        exports['pma-voice']:setRadioChannel(0)
        lib.notify({
            title = 'Red Clandestina de Radio',
            description = 'Desconectado de la emisora clandestina.',
            type = 'info',
            icon = 'walkie-talkie'
        })
    end
end)

-- ============================================================================
-- 2. GPS TÁCTICO EN VIVO: BLIPS DE MIEMBROS DE BANDA EN MAPA CON COLOR DE EMISORA
-- ============================================================================

local function CleanAllGangBlips()
    for src, blip in pairs(ActiveGangBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    ActiveGangBlips = {}
end

RegisterNetEvent('aura_gangs:client:syncGangGps', function(copList)
    if CurrentGangRadio.freq == 0 then
        CleanAllGangBlips()
        return
    end

    local mySrc = GetPlayerServerId(PlayerId())
    local currentServerIds = {}

    for _, cop in ipairs(copList) do
        if cop.src ~= mySrc then
            currentServerIds[cop.src] = true
            local blip = ActiveGangBlips[cop.src]

            if not blip or not DoesBlipExist(blip) then
                -- Crear nuevo Blip táctico
                blip = AddBlipForCoord(cop.coords.x, cop.coords.y, cop.coords.z)
                SetBlipSprite(blip, cop.inVehicle and 225 or 1)
                SetBlipScale(blip, 0.78)
                SetBlipColour(blip, cop.blipColor or 38)
                SetBlipAsShortRange(blip, false)
                SetBlipDisplay(blip, 4)
                SetBlipRotation(blip, math.ceil(cop.heading or 0))
                ShowHeadingIndicatorOnBlip(blip, true)

                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(string.format("[%s] %s (%s)", cop.channelLabel or "Emisora", cop.name or "Miembro", cop.gradeLabel or ""))
                EndTextCommandSetBlipName(blip)

                ActiveGangBlips[cop.src] = blip
            else
                -- Actualizar Blip existente
                SetBlipCoords(blip, cop.coords.x, cop.coords.y, cop.coords.z)
                SetBlipRotation(blip, math.ceil(cop.heading or 0))
                SetBlipSprite(blip, cop.inVehicle and 225 or 1)
                SetBlipColour(blip, cop.blipColor or 38)

                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(string.format("[%s] %s (%s)", cop.channelLabel or "Emisora", cop.name or "Miembro", cop.gradeLabel or ""))
                EndTextCommandSetBlipName(blip)
            end
        end
    end

    -- Eliminar blips de miembros que salieron de la radio o desconectaron
    for src, blip in pairs(ActiveGangBlips) do
        if not currentServerIds[src] then
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
            ActiveGangBlips[src] = nil
        end
    end
end)

-- Limpieza al salir del recurso
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        CleanAllGangBlips()
    end
end)
