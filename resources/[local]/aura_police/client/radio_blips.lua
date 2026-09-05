-- ============================================================================
-- AURA POLICE: CLIENT RADIO-PATRULLAS, DUAL-KEYBINDS & LIVE GPS BLIPS
-- PMA-Voice Bridges, Mando Priority Broadcast & Tactical Officer Map Blips
-- ============================================================================

local CurrentPoliceRadio = {
    freq = 0,
    label = "Desconectado",
    color = "#00f2fe",
    isMando = false
}

local ActiveOfficerBlips = {} -- [src] = blipHandle
local isMandoBroadcasting = false

local function IsCopOnDuty()
    local pState = LocalPlayer.state
    return pState and pState.job == 'police' and pState.job_duty == true
end

-- ============================================================================
-- 1. SINCRONIZACIÓN DE CANAL CON PMA-VOICE
-- ============================================================================

RegisterNetEvent('aura_police:client:syncRadioChannel', function(frequency, label, color, isMando)
    CurrentPoliceRadio.freq = frequency or 0
    CurrentPoliceRadio.label = label or "Desconectado"
    CurrentPoliceRadio.color = color or "#00f2fe"
    CurrentPoliceRadio.isMando = (isMando == true)

    if frequency and frequency > 0 then
        exports['pma-voice']:setRadioChannel(frequency)
        lib.notify({
            title = 'Radio Policial LSPD',
            description = string.format('Conectado a %s (%s MHz)', label, frequency),
            type = 'success',
            icon = 'walkie-talkie'
        })
    else
        exports['pma-voice']:setRadioChannel(0)
        lib.notify({
            title = 'Radio Policial LSPD',
            description = 'Desconectado de la frecuencia policial.',
            type = 'info',
            icon = 'walkie-talkie'
        })
    end
end)

-- ============================================================================
-- 2. TRANSMISIÓN PRIORITARIA DE MANDO (MALLA GENERAL - KEYBIND 'Y')
-- ============================================================================

RegisterCommand('+radiotalk_all', function()
    if not IsCopOnDuty() then return end
    if not CurrentPoliceRadio.isMando or CurrentPoliceRadio.freq == 0 then
        lib.notify({
            title = 'Malla General de Mando',
            description = 'Solo disponible para el Alto Mando conectado en el Canal de Mando.',
            type = 'error',
            icon = 'shield-halved'
        })
        return
    end

    if not isMandoBroadcasting then
        isMandoBroadcasting = true
        LocalPlayer.state:set('mandoRadioActive', true, true)
        TriggerEvent('pma-voice:radioActive', true)
        TriggerEvent('aura_police:client:radioStateChanged', true)

        PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
        TriggerServerEvent('aura_police:server:broadcastMandoTalk', true)
        
        -- Añadir a todos los agentes en servicio como objetivos de voz directos (Mumble VoiceTarget 1)
        local mySrc = GetPlayerServerId(PlayerId())
        for src, _ in pairs(ActiveOfficerBlips) do
            if src ~= mySrc then
                MumbleAddVoiceTargetPlayerByServerId(1, src)
            end
        end

        -- Iniciar animación táctica de radio y activación de PTT continuo
        CreateThread(function()
            local dict = "random@arrests"
            local anim = "generic_radio_enter"
            RequestAnimDict(dict)
            local timeout = 0
            while not HasAnimDictLoaded(dict) and timeout < 20 do
                Wait(10)
                timeout = timeout + 1
            end

            while isMandoBroadcasting do
                local ped = PlayerPedId()
                if HasAnimDictLoaded(dict) and not IsEntityPlayingAnim(ped, dict, anim, 3) then
                    TaskPlayAnim(ped, dict, anim, 8.0, 2.0, -1, 50, 2.0, false, false, false)
                end
                SetControlNormal(0, 249, 1.0)
                SetControlNormal(1, 249, 1.0)
                SetControlNormal(2, 249, 1.0)
                Wait(0)
            end
            if HasAnimDictLoaded(dict) then
                RemoveAnimDict(dict)
            end
        end)
        
        lib.notify({
            title = 'Malla General Activa',
            description = 'Transmitiendo en directo a TODAS las unidades policiales.',
            type = 'warning',
            icon = 'tower-broadcast'
        })
    end
end, false)

RegisterCommand('-radiotalk_all', function()
    if isMandoBroadcasting then
        isMandoBroadcasting = false
        LocalPlayer.state:set('mandoRadioActive', false, true)
        TriggerEvent('pma-voice:radioActive', false)
        TriggerEvent('aura_police:client:radioStateChanged', false)
        MumbleClearVoiceTargetPlayers(1)
        TriggerServerEvent('aura_police:server:broadcastMandoTalk', false)
        StopAnimTask(PlayerPedId(), "random@arrests", "generic_radio_enter", -4.0)
    end
end, false)

RegisterKeyMapping('+radiotalk_all', 'Radio Policial: Malla General (Alto Mando)', 'keyboard', 'Y')

-- Recepción de audio prioritario de Mando
RegisterNetEvent('aura_police:client:onMandoBroadcast', function(mandoSrc, isTalking, officerName, officerGradeLabel)
    if not IsCopOnDuty() then return end

    if isTalking then
        PlaySoundFrontend(-1, "Beep_Red", "DLC_HEIST_HACKING_SNAKE_SOUNDS", 1)
        MumbleSetVolumeOverrideByServerId(mandoSrc, 1.25)
        lib.notify({
            title = string.format('📻 ALTO MANDO // %s', string.upper(officerGradeLabel or "COMISARIO")),
            description = string.format('%s emitiendo orden prioritaria por Malla General.', officerName or "Mando"),
            type = 'warning',
            icon = 'tower-broadcast',
            duration = 4000
        })
    else
        MumbleSetVolumeOverrideByServerId(mandoSrc, -1.0)
    end
end)

-- ============================================================================
-- 3. GPS TÁCTICO EN VIVO: BLIPS DE OFICIALES EN MAPA CON COLOR DE SU CANAL
-- ============================================================================

local function CleanAllOfficerBlips()
    for src, blip in pairs(ActiveOfficerBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    ActiveOfficerBlips = {}
end

RegisterNetEvent('aura_police:client:syncPoliceGps', function(copList)
    if not IsCopOnDuty() then
        CleanAllOfficerBlips()
        return
    end

    local mySrc = GetPlayerServerId(PlayerId())
    local currentServerIds = {}

    for _, cop in ipairs(copList) do
        if cop.src ~= mySrc then
            currentServerIds[cop.src] = true
            local blip = ActiveOfficerBlips[cop.src]

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
                AddTextComponentString(string.format("[%s] %s (%s)", cop.channelLabel or "LSPD", cop.name or "Oficial", cop.gradeLabel or ""))
                EndTextCommandSetBlipName(blip)

                ActiveOfficerBlips[cop.src] = blip
            else
                -- Actualizar Blip existente
                SetBlipCoords(blip, cop.coords.x, cop.coords.y, cop.coords.z)
                SetBlipRotation(blip, math.ceil(cop.heading or 0))
                SetBlipSprite(blip, cop.inVehicle and 225 or 1)
                SetBlipColour(blip, cop.blipColor or 38)

                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(string.format("[%s] %s (%s)", cop.channelLabel or "LSPD", cop.name or "Oficial", cop.gradeLabel or ""))
                EndTextCommandSetBlipName(blip)
            end
        end
    end

    -- Eliminar blips de oficiales que salieron de servicio o desconectaron
    for src, blip in pairs(ActiveOfficerBlips) do
        if not currentServerIds[src] then
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
            ActiveOfficerBlips[src] = nil
        end
    end
end)

-- Limpieza al salir de servicio o parar recurso
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        CleanAllOfficerBlips()
    end
end)

RegisterNetEvent('aura_police:client:onDutyChange', function(isDuty)
    if not isDuty then
        CleanAllOfficerBlips()
        CurrentPoliceRadio.freq = 0
        CurrentPoliceRadio.label = "Desconectado"
        CurrentPoliceRadio.isMando = false
        exports['pma-voice']:setRadioChannel(0)
    end
end)
