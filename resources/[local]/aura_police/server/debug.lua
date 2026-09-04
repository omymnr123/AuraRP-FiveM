-- ============================================================================
-- AURA POLICE: SERVER DEVELOPER & SOLO TESTING SUITE
-- ============================================================================

-- 1. Asignar rango LSPD y Duty al instante
RegisterNetEvent('aura_police:server:debugSetPoliceDuty', function()
    local src = source
    local pState = Player(src).state
    pState:set('job', 'police', true)
    pState:set('job_grade', 5, true)
    pState:set('job_grade_label', 'Comisario', true)
    pState:set('job_duty', true, true)

    -- Actualizar también en la base de datos si existe personaje activo
    local char = exports.aura_multichar:GetActiveCharacter(src)
    if char then
        MySQL.update('UPDATE characters SET job = ?, job_grade = ?, job_duty = ? WHERE id = ?', {
            'police', 5, 1, char.id
        })
    end

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Modo Pruebas Policial',
        description = 'Ahora eres Comisario (Grado 5) de LSPD y estás EN SERVICIO.',
        type = 'success',
        duration = 6000
    })
end)

-- 2. Inicializar Stash de prueba con objetos ilegales para cachear
RegisterNetEvent('aura_police:server:initDummyStash', function(dummyId)
    local stashId = 'dummy_suspect_inv_' .. tostring(dummyId)
    exports.ox_inventory:RegisterStash(stashId, 'Inventario Sospechoso #' .. dummyId, 30, 80000, nil)

    -- Rellenar con items de prueba
    exports.ox_inventory:AddItem(stashId, 'WEAPON_PISTOL', 1)
    exports.ox_inventory:AddItem(stashId, 'ammo-9', 50)
    exports.ox_inventory:AddItem(stashId, 'lockpick', 3)
    exports.ox_inventory:AddItem(stashId, 'money', 1500)
end)

-- 3. Auto-Jail y Auto-Unjail para pruebas
RegisterNetEvent('aura_police:server:debugSelfJail', function(minutes)
    local src = source
    minutes = tonumber(minutes) or 2
    exports.aura_police:JailPlayer(src, minutes, "Prueba de Condena Penitenciaria (Test Solo)", src)
end)

RegisterNetEvent('aura_police:server:debugSelfUnjail', function()
    local src = source
    exports.aura_police:UnjailPlayer(src)
end)
