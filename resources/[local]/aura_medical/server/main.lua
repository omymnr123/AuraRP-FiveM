-- ============================================================================
-- AURA MEDICAL: SERVER MAIN CONTROLLER
-- ============================================================================

local function InitPlayerMedicalState(src)
    if not src or src <= 0 then return end

    local medicalData = nil

    -- Intentar obtener desde aura_multichar
    if exports.aura_multichar and exports.aura_multichar.GetActiveCharacter then
        local char = exports.aura_multichar:GetActiveCharacter(src)
        if char and char.metadata and char.metadata.medical and char.metadata.medical.bone_damage then
            medicalData = char.metadata.medical.bone_damage
        end
    end

    -- Fallback aura_core
    if not medicalData and exports.aura_core and exports.aura_core.GetPlayer then
        local player = exports.aura_core:GetPlayer(src)
        if player and player.metadata and player.metadata.medical and player.metadata.medical.bone_damage then
            medicalData = player.metadata.medical.bone_damage
        end
    end

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

    local finalData = medicalData or defaultDamage
    Player(src).state:set('bone_damage', finalData, true)
    TriggerClientEvent('aura_medical:client:loadDamage', src, finalData)
end

RegisterNetEvent('aura_core:playerLoaded', function()
    local src = source
    InitPlayerMedicalState(src)
end)

RegisterNetEvent('aura_multichar:server:characterSelected', function()
    local src = source
    InitPlayerMedicalState(src)
end)
