local CurrentSeason = 'spring'
local CurrentWeather = 'CLEAR'
local BaseTemperature = 18.0
local HasSnow = false
local DayInSeason = 1
local TotalDay = 1
local CurrentAmbientTemp = 18.0
local IsInShelter = false

-- ============================================================================
-- SINCRONIZACIÓN Y OVERRIDE METEOROLÓGICO NATIVO CON COBERTURA DE NIEVE
-- ============================================================================

local isSnowActive = false

local function UpdateSnowCoverage(enable)
    isSnowActive = enable

    -- Nativa FiveM/GTA V para pintar el mapa completo con el shader de nieve
    Citizen.InvokeNative(0xc79d0322c3bf12e0, enable and true or false)

    -- Activar / desactivar efectos de marcas en nieve y huellas
    SetForceVehicleTrails(enable)
    SetForcePedFootstepsTracks(enable)

    if enable then
        -- Cargar bancos de audio para sonido crujiente de pisadas en hielo/nieve
        RequestScriptAudioBank("ICE_FOOTSTEPS", false)
        RequestScriptAudioBank("SNOW_FOOTSTEPS", false)

        -- Cargar efectos de partículas de nieve
        RequestNamedPtfxAsset("core_snow")
        while not HasNamedPtfxAssetLoaded("core_snow") do
            Wait(10)
        end
        UseParticleFxAssetNextCall("core_snow")
    else
        RemoveNamedPtfxAsset("core_snow")
    end
end

local function ApplyClientWeather(weatherType, hasSnowParam, instant)
    CurrentWeather = string.upper(weatherType or 'CLEAR')
    
    local isSnow = (hasSnowParam == true) or (CurrentSeason == 'winter') or (CurrentWeather == 'XMAS') or (CurrentWeather == 'BLIZZARD') or (CurrentWeather == 'SNOW') or (CurrentWeather == 'SNOWLIGHT') or (CurrentWeather == 'XMAS_SNOW')
    HasSnow = isSnow

    if instant then
        SetWeatherTypeNowPersist(CurrentWeather)
        SetWeatherTypeNow(CurrentWeather)
        SetWeatherTypePersist(CurrentWeather)
    else
        SetWeatherTypeOvertimePersist(CurrentWeather, Config.WeatherTransitionTime or 15.0)
    end

    UpdateSnowCoverage(HasSnow)
end

-- Bucle de persistencia para el Shader de Nieve en el Mapa
-- Evita que el motor de renderizado de GTA V desactive la nieve al cambiar de streaming chunks o salir de interiores
CreateThread(function()
    while true do
        local needsSnow = HasSnow or (CurrentSeason == 'winter') or (CurrentWeather == 'XMAS') or (CurrentWeather == 'BLIZZARD') or (CurrentWeather == 'SNOW') or (CurrentWeather == 'SNOWLIGHT')
        
        if needsSnow then
            if not isSnowActive then
                UpdateSnowCoverage(true)
            end
            -- Reafirmar nativa en el motor gráfico
            Citizen.InvokeNative(0xc79d0322c3bf12e0, true)
            SetForceVehicleTrails(true)
            SetForcePedFootstepsTracks(true)
            Wait(1000)
        else
            if isSnowActive then
                UpdateSnowCoverage(false)
            end
            Wait(3000)
        end
    end
end)

-- Variables de Tiempo en Cliente
local ClientHour = 12
local ClientMinute = 0
local IsTimeFrozen = false

RegisterNetEvent('aura_seasons:client:syncWeather', function(data)
    if not data then return end
    CurrentSeason = data.season or CurrentSeason
    BaseTemperature = data.baseTemp or BaseTemperature
    DayInSeason = data.dayInSeason or DayInSeason
    TotalDay = data.totalDay or TotalDay

    ApplyClientWeather(data.weather or 'CLEAR', data.hasSnow, data.instant)
end)

RegisterNetEvent('aura_seasons:client:syncTime', function(data)
    if not data then return end
    ClientHour = data.hour or ClientHour
    ClientMinute = data.minute or ClientMinute
    IsTimeFrozen = data.isFrozen or false
    NetworkOverrideClockTime(ClientHour, ClientMinute, 0)
end)

-- Bucle de Sincronización del Reloj Maestro de GTA V
CreateThread(function()
    PauseClock(true)

    while true do
        Wait(500)
        local sTime = GlobalState.ServerTime
        if sTime then
            ClientHour = sTime.hour or ClientHour
            ClientMinute = sTime.minute or ClientMinute
            IsTimeFrozen = sTime.isFrozen or false
            NetworkOverrideClockTime(ClientHour, ClientMinute, 0)
        else
            NetworkOverrideClockTime(ClientHour, ClientMinute, 0)
        end
    end
end)

-- Solicitar sincronización al iniciar el cliente o hacer spawn
CreateThread(function()
    Wait(1000)
    TriggerServerEvent('aura_seasons:server:requestSync')
end)

AddEventHandler('playerSpawned', function()
    TriggerServerEvent('aura_seasons:server:requestSync')
end)

RegisterNetEvent('aura_core:client:playerSpawned', function()
    TriggerServerEvent('aura_seasons:server:requestSync')
end)

-- ============================================================================
-- CÁLCULO DE TEMPERATURA AMBIENTAL Y DETECCIÓN PRECISA DE REFUGIOS
-- ============================================================================

local function IsEntitySheltered(ped)
    if not ped or not DoesEntityExist(ped) then return false end

    -- 1. Vehículo (Habitáculo cerrado)
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        return true
    end

    -- 2. Interior MLO / Casa / Local por Entidad (0 cuando está en la calle)
    local interiorEntity = GetInteriorFromEntity(ped)
    if interiorEntity ~= 0 then
        return true
    end

    return false
end

local function CalculateLocalAmbientTemperature()
    local ped = PlayerPedId()
    
    -- Detección de Refugio (Interiores / Vehículos)
    IsInShelter = IsEntitySheltered(ped)
    if IsInShelter then
        return Config.Survival.Shelter.NormalizedTemp -- Climatización perfecta 21.0ºC
    end

    -- 3. Temperatura Base de la Estación
    local temp = BaseTemperature

    -- 4. Modificador por Hora del Día (Ciclo Solar GTA)
    local hour = GetClockHours()
    local minute = GetClockMinutes()
    local timeFloat = hour + (minute / 60.0)

    -- Curva sinusoidal térmica diaria (Pico cálido a las 14:00, Mínimo frío a las 05:00)
    local timeOffset = math.sin(((timeFloat - 8.0) / 24.0) * (2 * math.pi))
    local dailyAmplitude = (CurrentSeason == 'summer') and 7.0 or (CurrentSeason == 'winter' and 3.5 or 5.0)
    temp = temp + (timeOffset * dailyAmplitude)

    -- 5. Modificador por Altitud / Elevación Geográfica (Lapse Rate)
    local coords = GetEntityCoords(ped)
    local altitude = math.max(0.0, coords.z)
    local altitudeDrop = altitude * (Config.Survival.AltitudeLapseRate or 0.01)
    temp = temp - altitudeDrop

    -- 6. Modificador por Clima Específico
    if CurrentWeather == 'RAIN' or CurrentWeather == 'THUNDER' then
        temp = temp - 3.0
    elseif CurrentWeather == 'FOGGY' or CurrentWeather == 'OVERCAST' then
        temp = temp - 1.5
    elseif CurrentWeather == 'BLIZZARD' then
        temp = temp - 6.0
    elseif CurrentWeather == 'EXTRASUNNY' then
        temp = temp + 3.0
    end

    -- 7. Modificador por Agua / Inmersión
    if IsEntityInWater(ped) then
        if temp < 25.0 then
            temp = temp - 5.0 -- El agua fría acelera drásticamente la pérdida de calor
        end
    end

    return tonumber(string.format('%.1f', temp))
end

-- Bucle ligero de actualización de temperatura ambiental (cada 1 segundo)
CreateThread(function()
    while true do
        Wait(1000)
        CurrentAmbientTemp = CalculateLocalAmbientTemperature()
    end
end)

-- ============================================================================
-- EXPORTS DEL CLIENTE
-- ============================================================================

exports('GetAmbientTemperature', function()
    return CurrentAmbientTemp
end)

exports('GetCurrentSeason', function()
    return CurrentSeason
end)

exports('GetCurrentWeather', function()
    return CurrentWeather
end)

exports('IsInsideShelter', function()
    return IsInShelter
end)

exports('GetSeasonInfo', function()
    return {
        season = CurrentSeason,
        seasonLabel = Config.Seasons[CurrentSeason] and Config.Seasons[CurrentSeason].label or CurrentSeason,
        weather = CurrentWeather,
        ambientTemp = CurrentAmbientTemp,
        dayInSeason = DayInSeason,
        totalDay = TotalDay,
        hasSnow = HasSnow,
        isSheltered = IsInShelter
    }
end)

exports('GetTime', function()
    local sTime = GlobalState.ServerTime
    if sTime then
        return sTime
    end
    return {
        hour = ClientHour,
        minute = ClientMinute,
        isFrozen = IsTimeFrozen,
        isDay = (ClientHour >= 6 and ClientHour < 20)
    }
end)

