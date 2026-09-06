local CoreTemperature = 37.0
local ActiveBuffs = {
    warmth = { active = false, expiresAt = 0, resistance = 0.0 },
    cooling = { active = false, expiresAt = 0, resistance = 0.0 }
}

local isShivering = false
local isSweating = false
local isScreenBlurred = false
local lastColdDamageTime = 0
local lastHeatDamageTime = 0

-- ============================================================================
-- GESTIÓN DE BUFFS Y CONSUMIBLES TÉRMICOS
-- ============================================================================

RegisterNetEvent('aura_seasons:client:applyBuff', function(buffData)
    if not buffData then return end
    local now = GetGameTimer()

    if buffData.type == 'warmth' then
        ActiveBuffs.warmth = {
            active = true,
            expiresAt = now + ((buffData.buffDuration or 600) * 1000),
            resistance = buffData.resistance or 0.50
        }
        CoreTemperature = math.min(38.0, CoreTemperature + (buffData.coreTempBoost or 1.5))
        
        lib.notify({
            title = 'Efecto Térmico',
            description = ('%s: Tu cuerpo entra en calor (+%.1fºC). Resistencia al frío activada.'):format(
                buffData.label or 'Bebida Caliente', buffData.coreTempBoost or 1.5),
            type = 'inform',
            duration = 5000
        })
    elseif buffData.type == 'cooling' then
        ActiveBuffs.cooling = {
            active = true,
            expiresAt = now + ((buffData.buffDuration or 600) * 1000),
            resistance = buffData.resistance or 0.50
        }
        CoreTemperature = math.max(36.0, CoreTemperature + (buffData.coreTempBoost or -1.2))

        lib.notify({
            title = 'Hidratación Refrescante',
            description = ('%s: Sientes un alivio refrescante (%.1fºC). Resistencia al calor activada.'):format(
                buffData.label or 'Bebida Fría', buffData.coreTempBoost or -1.2),
            type = 'inform',
            duration = 5000
        })
    end
end)

local function CheckBuffs()
    local now = GetGameTimer()
    if ActiveBuffs.warmth.active and now > ActiveBuffs.warmth.expiresAt then
        ActiveBuffs.warmth.active = false
        ActiveBuffs.warmth.resistance = 0.0
    end
    if ActiveBuffs.cooling.active and now > ActiveBuffs.cooling.expiresAt then
        ActiveBuffs.cooling.active = false
        ActiveBuffs.cooling.resistance = 0.0
    end
end

-- ============================================================================
-- MODELO MATEMÁTICO DE TERMORREGULACIÓN CORPORAL
-- ============================================================================

local function IsEntitySheltered(ped)
    if not ped or not DoesEntityExist(ped) then return false end

    -- 1. Vehículo (Habitáculo cerrado)
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then return true end

    -- 2. Interior MLO / Casa / Local por Entidad (0 cuando está en la calle)
    local interiorEntity = GetInteriorFromEntity(ped)
    if interiorEntity ~= 0 then return true end

    return false
end

-- ============================================================================
-- MODELO MATEMÁTICO DE TERMORREGULACIÓN CORPORAL Y EQUILIBRIO DE AISLAMIENTO
-- ============================================================================

local function UpdateThermalHomeostasis()
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) or IsEntityDead(ped) then return end

    CheckBuffs()

    local ambientTemp = exports['aura_seasons']:GetAmbientTemperature() or 21.0
    local insulation = exports['aura_seasons']:GetInsulation() or 0.0
    local isSheltered = exports['aura_seasons']:IsInsideShelter()
    if isSheltered == nil or not isSheltered then
        isSheltered = IsEntitySheltered(ped)
    end

    -- ------------------------------------------------------------------------
    -- CASO 1: EN REFUGIO (Interiores MLO, Casas, Garajes o Vehículos Climatizados)
    -- ------------------------------------------------------------------------
    if isSheltered then
        local rate = Config.Survival.Shelter.CoreRecoveryRate or 0.20
        if ActiveBuffs.warmth.active then rate = rate * 1.5 end

        if CoreTemperature < 37.0 then
            CoreTemperature = math.min(37.0, CoreTemperature + rate)
        elseif CoreTemperature > 37.0 then
            CoreTemperature = math.max(37.0, CoreTemperature - rate)
        end
        return
    end

    -- ------------------------------------------------------------------------
    -- MODELO DE EQUILIBRIO TÉRMICO Y TERMORREGULACIÓN HUMANA
    -- ------------------------------------------------------------------------
    -- Temperatura ambiente ideal para el nivel de abrigo que lleva puesto:
    -- 0% Aislamiento   -> Confort en 26.0ºC (playa / bañador)
    -- 30% Aislamiento  -> Confort en 16.0ºC a 21.0ºC (ropa ligera de primavera)
    -- 60% Aislamiento  -> Confort en 6.0ºC a 12.0ºC (chaqueta / otoño)
    -- 100% Aislamiento -> Confort en -8.0ºC (equipo ártico / ventisca invernal)
    local idealComfortTemp = 26.0 - ((insulation / 100.0) * 34.0)

    -- Diferencia térmica real entre el ambiente y la ropa
    local thermalDelta = ambientTemp - idealComfortTemp

    -- Margen de tolerancia natural de termorregulación (+-5.0ºC)
    if thermalDelta < -5.0 then
        -- --------------------------------------------------------------------
        -- SENSACIÓN DE FRÍO (Ropa insuficiente para el frío exterior)
        -- --------------------------------------------------------------------
        local coldSeverity = math.abs(thermalDelta + 5.0)
        local baseLoss = math.min(0.025, coldSeverity * 0.0015)

        -- Reducción por Buff de Café / Bebida caliente
        if ActiveBuffs.warmth.active then
            baseLoss = baseLoss * (1.0 - ActiveBuffs.warmth.resistance)
        end

        -- Inmersión en agua helada
        if IsEntityInWater(ped) then
            baseLoss = baseLoss + (coldSeverity * 0.020)
        end

        CoreTemperature = CoreTemperature - baseLoss

    elseif thermalDelta > 5.0 then
        -- --------------------------------------------------------------------
        -- SENSACIÓN DE CALOR (Sobre-abrigo / Exceso de ropa u Ola de calor) - PROGRESO PAUSADO
        -- --------------------------------------------------------------------
        local heatSeverity = (thermalDelta - 5.0)
        local baseGain = math.min(0.020, heatSeverity * 0.0012)

        -- Resistencia por Buff de Agua fresca / Hidratación
        if ActiveBuffs.cooling.active then
            baseGain = baseGain * (1.0 - ActiveBuffs.cooling.resistance)
        end

        -- Actividad física intensa (Sprintar / Correr)
        if IsPedSprinting(ped) or IsPedRunning(ped) then
            baseGain = baseGain * 1.25
        end

        CoreTemperature = CoreTemperature + baseGain

    else
        -- --------------------------------------------------------------------
        -- ZONA DE CONFORT (Ropa equilibrada con el clima actual)
        -- --------------------------------------------------------------------
        if CoreTemperature < 37.0 then
            CoreTemperature = math.min(37.0, CoreTemperature + 0.03)
        elseif CoreTemperature > 37.0 then
            CoreTemperature = math.max(37.0, CoreTemperature - 0.03)
        end
    end

    -- Limitar temperatura a rangos biológicos realistas
    CoreTemperature = math.max(29.0, math.min(43.0, CoreTemperature))
end

-- ============================================================================
-- CONSECUENCIAS FISIOLÓGICAS (HIPOTERMIA E HIPERTERMIA EQUILIBRADAS)
-- ============================================================================

local function HandlePhysiologicalEffects()
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) or IsEntityDead(ped) then return end

    local coldConfig = Config.Survival.Cold
    local heatConfig = Config.Survival.Heat

    -- ------------------------------------------------------------------------
    -- EFECTOS DE HIPOTERMIA (FRÍO)
    -- ------------------------------------------------------------------------
    if CoreTemperature <= coldConfig.ModerateThreshold then
        -- Animación de Temblores (Shivering)
        if not isShivering and not IsPedInAnyVehicle(ped, false) and not IsPedRagdoll(ped) then
            local animDict = 'anim@mp_corona_idles'
            RequestAnimDict(animDict)
            if HasAnimDictLoaded(animDict) then
                TaskPlayAnim(ped, animDict, 'shake_idle', 8.0, -8.0, -1, 49, 0, false, false, false)
                isShivering = true
            end
        end

        -- Drenaje acelerado de fatiga/stamina por el frío al correr
        if IsPedSprinting(ped) or IsPedRunning(ped) then
            RestorePlayerStamina(PlayerId(), -1.0)
        end

        -- Daño a la salud en Hipotermia Severa (solo cada 8 segundos)
        if CoreTemperature <= coldConfig.SevereThreshold then
            local now = GetGameTimer()
            if now - lastColdDamageTime >= 8000 then
                lastColdDamageTime = now
                local health = GetEntityHealth(ped)
                if health > 100 then
                    SetEntityHealth(ped, math.max(100, health - coldConfig.DamagePerTick))
                    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.10)
                end
            end
        end
    else
        if isShivering then
            ClearPedTasks(ped)
            isShivering = false
        end
    end

    -- ------------------------------------------------------------------------
    -- EFECTOS DE HIPERTERMIA (CALOR) - EQUILIBRADO Y PAUSADO
    -- ------------------------------------------------------------------------
    if CoreTemperature >= heatConfig.ModerateThreshold then
        -- Efecto de Sudoración ligera
        if not isSweating then
            SetPedWetnessHeight(ped, 0.5)
            isSweating = true
        end

        -- Drenaje suave de hidratación / sed
        TriggerEvent('aura_status:client:AddStatus', 'thirst', -heatConfig.ThirstDrainRate)

        -- Efecto visual muy suave de calina veraniega (sin cegar la pantalla)
        if not isScreenBlurred then
            SetTimecycleModifier('spectator5')
            SetTimecycleModifierStrength(0.18)
            isScreenBlurred = true
        end

        -- Consecuencias en Hipertermia Severa (solo cada 8 segundos)
        if CoreTemperature >= heatConfig.SevereThreshold then
            local now = GetGameTimer()
            if now - lastHeatDamageTime >= 8000 then
                lastHeatDamageTime = now
                local health = GetEntityHealth(ped)
                if health > 100 then
                    SetEntityHealth(ped, math.max(100, health - heatConfig.DamagePerTick))
                end

                -- Mareo momentáneo ocasional en calor extremo (> 41ºC)
                if math.random(1, 100) <= 8 and not IsPedInAnyVehicle(ped, false) and not IsPedRagdoll(ped) then
                    SetPedToRagdoll(ped, 2000, 2000, 0, false, false, false)
                    lib.notify({
                        title = 'Golpe de Calor',
                        description = 'Sientes mareo por exceso de temperatura corporal.',
                        type = 'warning'
                    })
                end
            end
        end
    else
        if isSweating then
            ClearPedWetness(ped)
            isSweating = false
        end
        if isScreenBlurred then
            ClearTimecycleModifier()
            isScreenBlurred = false
        end
    end
end

-- ============================================================================
-- SINCRONIZACIÓN CON AURA_HUD (INDICADORES DE FRÍO Y CALOR)
-- ============================================================================

local function SyncWithHUD()
    local coldLevel = 0.0
    local heatLevel = 0.0

    -- Cálculo proporcional de severidad en HUD (0% a 100%)
    -- Rango de Frío: inicia sutilmente por debajo de 36.6ºC hasta 32.0ºC
    if CoreTemperature < 36.6 then
        coldLevel = math.max(0.0, math.min(100.0, ((36.6 - CoreTemperature) / 3.6) * 100.0))
    -- Rango de Calor: inicia sutilmente por encima de 37.4ºC hasta 41.5ºC
    elseif CoreTemperature > 37.4 then
        heatLevel = math.max(0.0, math.min(100.0, ((CoreTemperature - 37.4) / 3.6) * 100.0))
    end

    local ambientTemp = exports['aura_seasons']:GetAmbientTemperature() or 21.0

    TriggerEvent('aura_hud:client:updateTemperature', 
        math.floor(coldLevel), 
        math.floor(heatLevel), 
        tonumber(string.format('%.1f', CoreTemperature)),
        ambientTemp
    )
end

-- ============================================================================
-- BUCLE PRINCIPAL ULTRA-OPTIMIZADO (ADAPTIVE TICK LOOP)
-- ============================================================================

CreateThread(function()
    while true do
        local isCritical = (CoreTemperature <= Config.Survival.Cold.ModerateThreshold or CoreTemperature >= Config.Survival.Heat.ModerateThreshold)
        local sleepTime = isCritical and (Config.Survival.ExtremeTickRate or 750) or (Config.Survival.BaseTickRate or 1500)

        Wait(sleepTime)

        UpdateThermalHomeostasis()
        HandlePhysiologicalEffects()
        SyncWithHUD()
    end
end)

-- ============================================================================
-- EXPORTS
-- ============================================================================

exports('GetCoreTemperature', function()
    return tonumber(string.format('%.1f', CoreTemperature))
end)

exports('SetCoreTemperature', function(newTemp)
    CoreTemperature = tonumber(newTemp) or 37.0
end)

exports('GetThermalBuffs', function()
    return ActiveBuffs
end)
