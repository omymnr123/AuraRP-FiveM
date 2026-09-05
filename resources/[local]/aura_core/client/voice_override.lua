-- ============================================================================
-- AURA CORE: CLIENT VOICE OVERRIDE & DUAL-TIER RADIO SYSTEM
-- PMA-Voice Bridges, Half-Duplex (Standard) vs Full-Duplex (Satellite)
-- Zero-overhead event-driven architecture (0.00ms CPU in idle)
-- ============================================================================

local savedRadioVolume = nil
local isHalfDuplexMuted = false

--- Evalúa la jerarquía de hardware de radio e implementa la atenuación Half-Duplex / Full-Duplex.
--- @param isTalking boolean Estado de transmisión activa (PTT pulsado / soltado)
local function HandleVoiceTransmissionState(isTalking)
    -- 1. Jerarquía de prioridad: Radio Satelital (Full-Duplex)
    local satelliteCount = exports.ox_inventory:Search('count', 'radio_satelite') or 0
    if satelliteCount > 0 then
        -- Satélite tiene prioridad absoluta: Full-Duplex habilitado (transmisión y recepción bidireccional)
        if isHalfDuplexMuted then
            local restoreVol = savedRadioVolume or 100
            if restoreVol <= 0 then restoreVol = 100 end
            exports['pma-voice']:setRadioVolume(restoreVol)
            isHalfDuplexMuted = false
            savedRadioVolume = nil
        end
        return
    end

    -- 2. Jerarquía secundaria: Radio Estándar (Half-Duplex)
    local standardCount = exports.ox_inventory:Search('count', 'radio') or 0
    if standardCount > 0 then
        if isTalking then
            if not isHalfDuplexMuted then
                -- Obtener y almacenar el volumen configurado por el usuario
                local currentVol = exports['pma-voice']:getRadioVolume()
                if currentVol and currentVol > 0 then
                    savedRadioVolume = currentVol
                elseif not savedRadioVolume or savedRadioVolume <= 0 then
                    savedRadioVolume = 100
                end

                -- Silenciar recepción de radio mientras transmite (Half-Duplex)
                exports['pma-voice']:setRadioVolume(0)
                isHalfDuplexMuted = true
            end
        else
            if isHalfDuplexMuted then
                -- Restaurar el volumen previo del usuario
                local restoreVol = savedRadioVolume or 100
                if restoreVol <= 0 then restoreVol = 100 end
                exports['pma-voice']:setRadioVolume(restoreVol)
                isHalfDuplexMuted = false
                savedRadioVolume = nil
            end
        end
        return
    end

    -- 3. Si no tiene ninguna radio y estaba marcado como muteado, restaurar por seguridad
    if isHalfDuplexMuted then
        local restoreVol = savedRadioVolume or 100
        if restoreVol <= 0 then restoreVol = 100 end
        exports['pma-voice']:setRadioVolume(restoreVol)
        isHalfDuplexMuted = false
        savedRadioVolume = nil
    end
end

-- ============================================================================
-- EVENT LISTENERS & STATE HANDLERS (PMA-VOICE REACTIVITY)
-- ============================================================================

-- Listener primario de PMA-Voice al activar/desactivar transmisión de radio
AddEventHandler('pma-voice:radioActive', function(radioTalking)
    HandleVoiceTransmissionState(radioTalking == true)
end)

-- Listener secundario por State Bag para garantizar sincronización en cualquier cambio de estado
AddStateBagChangeHandler('radioActive', ('player:%s'):format(GetPlayerServerId(PlayerId())), function(_, _, value)
    HandleVoiceTransmissionState(value == true)
end)

-- Limpieza de seguridad al detener el recurso
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and isHalfDuplexMuted then
        local restoreVol = savedRadioVolume or 100
        if restoreVol <= 0 then restoreVol = 100 end
        exports['pma-voice']:setRadioVolume(restoreVol)
        isHalfDuplexMuted = false
    end
end)

-- Exports para diagnóstico y utilidades del sistema
exports('IsHalfDuplexMuted', function()
    return isHalfDuplexMuted
end)

exports('GetRadioDuplexMode', function()
    local satelliteCount = exports.ox_inventory:Search('count', 'radio_satelite') or 0
    if satelliteCount > 0 then
        return 'full-duplex'
    end
    local standardCount = exports.ox_inventory:Search('count', 'radio') or 0
    if standardCount > 0 then
        return 'half-duplex'
    end
    return 'none'
end)
