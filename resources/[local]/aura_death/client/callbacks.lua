-- ============================================================================
-- AURA DEATH: NUI CALLBACKS & DISPATCH HANDLER
-- ============================================================================

-- NUI Callback: Botón "EMERGENCIAS" presionado
RegisterNUICallback('callDispatch', function(data, cb)
    TriggerServerEvent('aura_death:server:callDispatch')
    cb({ ok = true, status = 'dispatch_sent' })
end)

-- NUI Callback: Botón "HOSPITAL" presionado (Reaparición voluntaria en cama)
RegisterNUICallback('respawnHospital', function(data, cb)
    TriggerServerEvent('aura_death:server:requestHospitalRespawn')
    cb({ ok = true, status = 'hospital_respawn_requested' })
end)

-- NUI Callback: Temporizador de 10 minutos agotado (PK forzoso)
RegisterNUICallback('timerExpired', function(data, cb)
    TriggerServerEvent('aura_death:server:timerExpired')
    cb({ ok = true, status = 'timer_expired' })
end)

-- NUI Callback: Sincronización continua de tiempo
RegisterNUICallback('syncTime', function(data, cb)
    local remaining = tonumber(data.timeRemaining)
    if remaining then
        local state = LocalPlayer.state.deathState or 'injured'
        TriggerServerEvent('aura_death:server:syncBleedoutTime', remaining, state)
    end
    cb({ ok = true })
end)

-- NUI Callback: Alternar modo cursor / cámara libre desde el DOM (contextmenu)
RegisterNUICallback('toggleCursor', function(data, cb)
    if exports.aura_death and exports.aura_death.SetDeathCursorMode then
        exports.aura_death:SetDeathCursorMode()
    end
    cb({ ok = true })
end)

