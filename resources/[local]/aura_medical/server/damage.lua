-- ============================================================================
-- AURA MEDICAL: SERVER DAMAGE CONTROLLER & PERSISTENCE
-- ============================================================================

RegisterNetEvent('aura_medical:server:syncDamage', function(damageData)
    local src = source
    if not damageData or type(damageData) ~= "table" then return end

    -- 1. Sincronizar en StateBag replicado del jugador para visibilidad global (EMS / Médicos)
    Player(src).state:set('bone_damage', damageData, true)

    -- 2. Persistir en la caché de personajes activos de aura_multichar
    if exports.aura_multichar and exports.aura_multichar.GetActiveCharacter then
        local char = exports.aura_multichar:GetActiveCharacter(src)
        if char then
            char.metadata = char.metadata or {}
            char.metadata.medical = char.metadata.medical or {}
            char.metadata.medical.bone_damage = damageData
        end
    end

    -- 3. Persistir en aura_core si está disponible
    if exports.aura_core and exports.aura_core.UpdatePlayerMetadata then
        exports.aura_core:UpdatePlayerMetadata(src, 'medical', { bone_damage = damageData })
    end
end)

-- Export servidor para consultar daños óseos de cualquier jugador
exports('GetPlayerBoneDamage', function(targetSrc)
    local state = Player(targetSrc).state.bone_damage
    if state then return state end
    return {
        head = { health = 100, injuries = {} },
        torso = { health = 100, injuries = {} },
        right_arm = { health = 100, injuries = {} },
        left_arm = { health = 100, injuries = {} },
        right_hand = { health = 100, injuries = {} },
        left_hand = { health = 100, injuries = {} },
        right_leg = { health = 100, injuries = {} },
        left_leg = { health = 100, injuries = {} },
        right_foot = { health = 100, injuries = {} },
        left_foot = { health = 100, injuries = {} }
    }
end)

exports('SetPlayerBoneDamage', function(targetSrc, damageData)
    if not targetSrc or not damageData then return false end
    Player(targetSrc).state:set('bone_damage', damageData, true)
    TriggerClientEvent('aura_medical:client:loadDamage', targetSrc, damageData)
    return true
end)

-- Interceptación en Servidor de Curaciones por txAdmin
AddEventHandler('txAdmin:events:healed', function(eventData)
    local target = eventData and eventData.target
    if target and target > 0 then
        local defaultDamage = {
            head = { health = 100, injuries = {} },
            torso = { health = 100, injuries = {} },
            right_arm = { health = 100, injuries = {} },
            left_arm = { health = 100, injuries = {} },
            right_hand = { health = 100, injuries = {} },
            left_hand = { health = 100, injuries = {} },
            right_leg = { health = 100, injuries = {} },
            left_leg = { health = 100, injuries = {} },
            right_foot = { health = 100, injuries = {} },
            left_foot = { health = 100, injuries = {} }
        }
        Player(target).state:set('bone_damage', defaultDamage, true)
        TriggerClientEvent('aura_medical:client:resetDamage', target)
    end
end)
