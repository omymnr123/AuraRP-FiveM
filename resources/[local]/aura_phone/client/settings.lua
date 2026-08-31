-- =========================================
-- AURA SETTINGS - CLIENT
-- =========================================

-- Obtener configuración guardada
RegisterNUICallback('getSettings', function(data, cb)
    lib.callback('aura_phone:server:getSettings', false, function(settings)
        cb(settings)
    end)
end)

-- Guardar configuración completa
RegisterNUICallback('saveSettings', function(data, cb)
    lib.callback('aura_phone:server:saveSettings', false, function(res)
        cb(res or { success = true })
    end, data)
end)

-- Actualizar una clave individual
RegisterNUICallback('updateSettingKey', function(data, cb)
    lib.callback('aura_phone:server:updateSettingKey', false, function(res)
        cb(res or { success = true })
    end, data)
end)
