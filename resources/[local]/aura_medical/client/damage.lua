-- ============================================================================
-- AURA MEDICAL: MOTOR DE DAÑO ÓSEO LOCALIZADO (CLIENT DAMAGE ENGINE)
-- ============================================================================

local CurrentBoneDamage = {
    head = { health = 100, injuries = {} },
    torso = { health = 100, injuries = {} },
    left_arm = { health = 100, injuries = {} },
    right_arm = { health = 100, injuries = {} },
    left_leg = { health = 100, injuries = {} },
    right_leg = { health = 100, injuries = {} }
}

local lastHealth = 200

-- Mapeo inverso rápido para búsqueda O(1) de huesos a grupos
local BoneLookup = {}
for groupKey, groupData in pairs(Config.Bones) do
    for _, boneId in ipairs(groupData.boneIds) do
        BoneLookup[boneId] = groupKey
    end
end

-- ============================================================================
-- FUNCIONES AUXILIARES DE CLASIFICACIÓN CLÍNICA
-- ============================================================================

---Determina el tipo de trauma a partir del hash del arma y contexto de impacto
local function ResolveDamageType(weaponHash, isMelee)
    local weaponType = "Blunt"
    
    if not weaponHash or weaponHash == 0 then
        return "Blunt"
    end

    -- Armas de fuego / Balística
    local weaponGroup = GetWeapontypeGroup(weaponHash)
    -- Grupos FiveM: 416676503 (Pistol), -957766203 (SMG), 970310034 (Rifle), 860032945 (Shotgun), -1212426201 (Sniper), 1159398588 (MG)
    if weaponGroup == 416676503 or weaponGroup == -957766203 or weaponGroup == 970310034 or 
       weaponGroup == 860032945 or weaponGroup == -1212426201 or weaponGroup == 1159398588 or
       weaponGroup == GetHashKey("GROUP_PISTOL") or weaponGroup == GetHashKey("GROUP_SMG") or
       weaponGroup == GetHashKey("GROUP_RIFLE") or weaponGroup == GetHashKey("GROUP_SHOTGUN") or
       weaponGroup == GetHashKey("GROUP_SNIPER") or weaponGroup == GetHashKey("GROUP_MG") then
        return "Bullet"
    end

    -- Fuego / Térmico / Explosiones
    if weaponHash == `WEAPON_MOLOTOV` or weaponHash == `WEAPON_FLARE` or weaponHash == `WEAPON_PETROLCAN` or 
       weaponHash == `WEAPON_EXPLOSION` or weaponHash == `WEAPON_FIRE` or weaponGroup == GetHashKey("GROUP_EXPLOSIVE") or
       weaponGroup == -1569615261 then
        return "Burn"
    end

    -- Filos / Armas Blancas Punzocortantes
    if weaponHash == `WEAPON_KNIFE` or weaponHash == `WEAPON_DAGGER` or weaponHash == `WEAPON_SWITCHBLADE` or 
       weaponHash == `WEAPON_MACHETE` or weaponHash == `WEAPON_HATCHET` or weaponHash == `WEAPON_BATTLEAXE` or
       weaponHash == `WEAPON_BOTTLE` or weaponHash == `WEAPON_STONE_HATCHET` then
        return "Cut"
    end

    -- Caídas y Desaceleración
    if weaponHash == `WEAPON_FALL` or weaponHash == `WEAPON_RAMMED_BY_CAR` or weaponHash == `WEAPON_RUN_OVER_BY_CAR` or
       weaponHash == `WEAPON_HELI_CRASH` or weaponHash == `WEAPON_UNARMED` then
        if weaponHash == `WEAPON_FALL` or weaponHash == `WEAPON_RAMMED_BY_CAR` or weaponHash == `WEAPON_RUN_OVER_BY_CAR` then
            return "Fall"
        else
            return "Blunt"
        end
    end

    return "Blunt"
end

---Calcula el nivel de severidad basado en los puntos de salud perdidos
local function CalculateSeverity(damageAmount)
    if damageAmount >= 60 then
        return "Critical", Config.DamageTypes[ "Bullet" ].severityLevels.Critical
    elseif damageAmount >= 35 then
        return "Severe", Config.DamageTypes[ "Bullet" ].severityLevels.Severe
    elseif damageAmount >= 15 then
        return "Moderate", Config.DamageTypes[ "Bullet" ].severityLevels.Moderate
    else
        return "Minor", Config.DamageTypes[ "Bullet" ].severityLevels.Minor
    end
end

-- ============================================================================
-- INTERCEPTACIÓN DE DAÑO (CEVENTNETWORKENTITYDAMAGE)
-- ============================================================================

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end

    local victim = args[1]
    local attacker = args[2]
    local isFatal = args[6]
    local weaponHash = args[7]
    local isMelee = args[12]

    local playerPed = PlayerPedId()
    if victim ~= playerPed then return end

    local currentHealth = GetEntityHealth(playerPed)
    local damageDealt = math.max(1, lastHealth - currentHealth)
    lastHealth = currentHealth

    -- Obtener el hueso impactado
    local foundBone, boneId = GetPedLastDamageBone(playerPed)
    local targetGroup = "torso" -- Grupo por defecto si no se detecta hueso específico

    if foundBone and boneId and BoneLookup[boneId] then
        targetGroup = BoneLookup[boneId]
    end

    -- Clasificar trauma
    local damageTypeKey = ResolveDamageType(weaponHash, isMelee)
    local severityKey, _ = CalculateSeverity(damageDealt)
    
    local typeConfig = Config.DamageTypes[damageTypeKey] or Config.DamageTypes.Blunt
    local severityLabel = typeConfig.severityLevels[severityKey] or typeConfig.label

    -- Reducir salud ósea del grupo
    local boneGroup = CurrentBoneDamage[targetGroup]
    local healthReduction = math.floor(damageDealt * 0.75)
    boneGroup.health = math.max(0, boneGroup.health - healthReduction)

    -- Registrar la lesión en la lista anatómica
    local injuryRecord = {
        id = #boneGroup.injuries + 1,
        boneGroup = targetGroup,
        boneLabel = Config.Bones[targetGroup].label,
        type = damageTypeKey,
        typeLabel = typeConfig.label,
        severity = severityKey,
        severityLabel = severityLabel,
        damage = damageDealt,
        badgeColor = typeConfig.badgeColor,
        timestamp = GetGameTimer(),
        timeFormatted = os.date("%H:%M:%S")
    }

    table.insert(boneGroup.injuries, injuryRecord)

    if Config.Debug then
        print(string.format("[AURA_MEDICAL] Daño recibido: Grupo=%s, Tipo=%s (%s), Dmg=%d, HuesoID=%s", 
            targetGroup, damageTypeKey, severityKey, damageDealt, tostring(boneId)))
    end

    -- Sincronizar en StateBag Replicado de FiveM
    LocalPlayer.state:set('bone_damage', CurrentBoneDamage, true)
    TriggerServerEvent('aura_medical:server:syncDamage', CurrentBoneDamage)
end)

-- ============================================================================
-- SINCRONIZACIÓN Y RESET AL SPAWN
-- ============================================================================

local function InitDamageTracking()
    local ped = PlayerPedId()
    lastHealth = GetEntityHealth(ped)
    LocalPlayer.state:set('bone_damage', CurrentBoneDamage, true)
end

AddEventHandler('playerSpawned', function()
    InitDamageTracking()
end)

RegisterNetEvent('aura_core:client:playerSpawned', function()
    InitDamageTracking()
end)

RegisterNetEvent('aura_medical:client:resetDamage', function()
    for groupKey, _ in pairs(CurrentBoneDamage) do
        CurrentBoneDamage[groupKey] = { health = 100, injuries = {} }
    end
    LocalPlayer.state:set('bone_damage', CurrentBoneDamage, true)
    TriggerServerEvent('aura_medical:server:syncDamage', CurrentBoneDamage)
end)

RegisterNetEvent('aura_medical:client:loadDamage', function(savedDamage)
    if savedDamage and type(savedDamage) == "table" then
        CurrentBoneDamage = savedDamage
        LocalPlayer.state:set('bone_damage', CurrentBoneDamage, true)
    end
end)

-- ============================================================================
-- EXPORTS
-- ============================================================================

exports('GetBoneDamage', function()
    return CurrentBoneDamage
end)

exports('GetLimbHealth', function(limbKey)
    if CurrentBoneDamage[limbKey] then
        return CurrentBoneDamage[limbKey].health
    end
    return 100
end)

exports('IsLimbDamaged', function(limbKey)
    if CurrentBoneDamage[limbKey] then
        return CurrentBoneDamage[limbKey].health < 100 or #CurrentBoneDamage[limbKey].injuries > 0
    end
    return false
end)
