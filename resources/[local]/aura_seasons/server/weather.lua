local CurrentSeason = 'spring'
local CurrentDay = 1
local DayInSeason = 1
local CurrentWeather = 'CLEAR'
local BaseTemperature = 18.0
local WeatherOverride = nil
local LastRotationTimestamp = os.time()

-- Variables de Estado del Tiempo y Ciclo Día / Noche
local CurrentHour = Config.Time and Config.Time.DefaultHour or 12
local CurrentMinute = Config.Time and Config.Time.DefaultMinute or 0
local IsTimeFrozen = false
local DayDurationMs = Config.Time and Config.Time.DayDurationMs or 2000
local NightDurationMs = Config.Time and Config.Time.NightDurationMs or 2000

-- ============================================================================
-- UTILIDADES Y SELECCIÓN PONDERADA DE CLIMA
-- ============================================================================

local function IsCurrentDaytime()
    local dayStart = Config.Time and Config.Time.DayStartHour or 6
    local nightStart = Config.Time and Config.Time.NightStartHour or 20
    return CurrentHour >= dayStart and CurrentHour < nightStart
end

local function GetRandomWeatherForSeason(seasonKey)
    local seasonData = Config.Seasons[seasonKey]
    if not seasonData or not seasonData.weatherPool then return 'CLEAR' end

    local totalWeight = 0
    for _, item in ipairs(seasonData.weatherPool) do
        totalWeight = totalWeight + item.weight
    end

    local randomVal = math.random(1, totalWeight)
    local runningWeight = 0

    for _, item in ipairs(seasonData.weatherPool) do
        runningWeight = runningWeight + item.weight
        if randomVal <= runningWeight then
            return item.type
        end
    end

    return seasonData.weatherPool[1].type
end

local function CalculateBaseTemperature(seasonKey)
    local seasonData = Config.Seasons[seasonKey]
    if not seasonData then return 20.0 end

    local min = seasonData.minTemp
    local max = seasonData.maxTemp

    -- Generar variación pseudo-aleatoria suave con 1 decimal
    local rawTemp = min + (math.random() * (max - min))
    return tonumber(string.format('%.1f', rawTemp))
end

-- ============================================================================
-- PERSISTENCIA Y SINCRONIZACIÓN
-- ============================================================================

local function IsSnowWeather(weather, season)
    if season == 'winter' then return true end
    local w = string.upper(weather or '')
    return w == 'XMAS' or w == 'BLIZZARD' or w == 'SNOW' or w == 'SNOWLIGHT' or w == 'XMAS_SNOW'
end

local function SaveSeasonState()
    local targetWeather = WeatherOverride or CurrentWeather
    local hasSnowVal = IsSnowWeather(targetWeather, CurrentSeason) and 1 or 0
    local isFrozenVal = IsTimeFrozen and 1 or 0

    MySQL.update([[
        UPDATE aura_seasons 
        SET current_season = ?, 
            current_day = ?, 
            day_in_season = ?, 
            last_rotation = FROM_UNIXTIME(?), 
            weather_override = ?,
            current_weather = ?,
            base_temperature = ?,
            has_snow = ?,
            current_hour = ?,
            current_minute = ?,
            time_frozen = ?,
            day_duration = ?,
            night_duration = ?
        WHERE id = 1
    ]], { 
        CurrentSeason, 
        CurrentDay, 
        DayInSeason, 
        LastRotationTimestamp, 
        WeatherOverride, 
        targetWeather, 
        BaseTemperature, 
        hasSnowVal,
        CurrentHour,
        CurrentMinute,
        isFrozenVal,
        DayDurationMs,
        NightDurationMs
    }, function(affected)
        -- Guardado persistente confirmado
    end)
end

local function SyncToGlobalState(instant)
    local targetWeather = WeatherOverride or CurrentWeather
    local hasSnow = IsSnowWeather(targetWeather, CurrentSeason)
    local isDay = IsCurrentDaytime()

    GlobalState.CurrentSeason = CurrentSeason
    GlobalState.CurrentWeather = targetWeather
    GlobalState.BaseTemperature = BaseTemperature
    GlobalState.SeasonDay = DayInSeason
    GlobalState.TotalDay = CurrentDay
    GlobalState.HasSnow = hasSnow

    -- Sincronización de Tiempo Maestro
    GlobalState.ServerTime = {
        hour = CurrentHour,
        minute = CurrentMinute,
        isFrozen = IsTimeFrozen,
        isDay = isDay,
        dayDuration = DayDurationMs,
        nightDuration = NightDurationMs
    }
    GlobalState.AuraTime = {
        h = CurrentHour,
        m = CurrentMinute
    }

    TriggerClientEvent('aura_seasons:client:syncWeather', -1, {
        season = CurrentSeason,
        weather = targetWeather,
        baseTemp = BaseTemperature,
        dayInSeason = DayInSeason,
        totalDay = CurrentDay,
        hasSnow = hasSnow,
        instant = instant or false
    })

    TriggerClientEvent('aura_seasons:client:syncTime', -1, {
        hour = CurrentHour,
        minute = CurrentMinute,
        isFrozen = IsTimeFrozen,
        isDay = isDay,
        dayDuration = DayDurationMs,
        nightDuration = NightDurationMs
    })
end

local function RotateSeason(newSeason)
    if not Config.Seasons[newSeason] then return end
    CurrentSeason = newSeason
    DayInSeason = 1
    LastRotationTimestamp = os.time()
    CurrentWeather = GetRandomWeatherForSeason(CurrentSeason)
    BaseTemperature = CalculateBaseTemperature(CurrentSeason)

    print(string.format('^2[AuraRP Seasons]^7 Nueva estación iniciada: ^3%s^7 (%s)', 
        Config.Seasons[CurrentSeason].label, CurrentSeason))

    SaveSeasonState()
    SyncToGlobalState(true)
end

-- ============================================================================
-- CARGA INICIAL Y AUTO-MIGRACIÓN DESDE LA BASE DE DATOS
-- ============================================================================

local function InitializeSeasons()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `aura_seasons` (
            `id` INT(11) NOT NULL PRIMARY KEY DEFAULT 1,
            `current_season` VARCHAR(32) NOT NULL DEFAULT 'spring',
            `current_day` INT(11) NOT NULL DEFAULT 1,
            `day_in_season` INT(11) NOT NULL DEFAULT 1,
            `last_rotation` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `weather_override` VARCHAR(32) DEFAULT NULL,
            `current_weather` VARCHAR(32) NOT NULL DEFAULT 'CLEAR',
            `base_temperature` DECIMAL(4,1) NOT NULL DEFAULT 18.0,
            `has_snow` TINYINT(1) NOT NULL DEFAULT 0,
            `current_hour` INT(11) NOT NULL DEFAULT 12,
            `current_minute` INT(11) NOT NULL DEFAULT 0,
            `time_frozen` TINYINT(1) NOT NULL DEFAULT 0,
            `day_duration` INT(11) NOT NULL DEFAULT 2000,
            `night_duration` INT(11) NOT NULL DEFAULT 2000,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {}, function()
        -- Auto-migración segura de columnas adicionales en bases de datos existentes
        MySQL.query([[
            ALTER TABLE `aura_seasons` 
            ADD COLUMN IF NOT EXISTS `current_weather` VARCHAR(32) NOT NULL DEFAULT 'CLEAR',
            ADD COLUMN IF NOT EXISTS `base_temperature` DECIMAL(4,1) NOT NULL DEFAULT 18.0,
            ADD COLUMN IF NOT EXISTS `has_snow` TINYINT(1) NOT NULL DEFAULT 0,
            ADD COLUMN IF NOT EXISTS `current_hour` INT(11) NOT NULL DEFAULT 12,
            ADD COLUMN IF NOT EXISTS `current_minute` INT(11) NOT NULL DEFAULT 0,
            ADD COLUMN IF NOT EXISTS `time_frozen` TINYINT(1) NOT NULL DEFAULT 0,
            ADD COLUMN IF NOT EXISTS `day_duration` INT(11) NOT NULL DEFAULT 2000,
            ADD COLUMN IF NOT EXISTS `night_duration` INT(11) NOT NULL DEFAULT 2000,
            ADD COLUMN IF NOT EXISTS `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;
        ]], {}, function()
            MySQL.query([[
                INSERT INTO `aura_seasons` (`id`, `current_season`, `current_day`, `day_in_season`, `last_rotation`, `weather_override`, `current_weather`, `base_temperature`, `has_snow`, `current_hour`, `current_minute`, `time_frozen`, `day_duration`, `night_duration`)
                VALUES (1, 'spring', 1, 1, NOW(), NULL, 'CLEAR', 18.0, 0, 12, 0, 0, 2000, 2000)
                ON DUPLICATE KEY UPDATE `id` = 1;
            ]], {}, function()
                MySQL.single('SELECT *, UNIX_TIMESTAMP(last_rotation) as rotation_epoch FROM aura_seasons WHERE id = 1', {}, function(row)
                    if row then
                        CurrentSeason = row.current_season or 'spring'
                        CurrentDay = tonumber(row.current_day) or 1
                        DayInSeason = tonumber(row.day_in_season) or 1
                        WeatherOverride = row.weather_override
                        LastRotationTimestamp = tonumber(row.rotation_epoch) or os.time()
                        CurrentWeather = WeatherOverride or row.current_weather or GetRandomWeatherForSeason(CurrentSeason)
                        BaseTemperature = tonumber(row.base_temperature) or CalculateBaseTemperature(CurrentSeason)
                        
                        -- Cargar hora y configuración de tiempo persistente
                        CurrentHour = tonumber(row.current_hour) or 12
                        CurrentMinute = tonumber(row.current_minute) or 0
                        IsTimeFrozen = (tonumber(row.time_frozen) == 1)
                        DayDurationMs = tonumber(row.day_duration) or (Config.Time and Config.Time.DayDurationMs or 2000)
                        NightDurationMs = tonumber(row.night_duration) or (Config.Time and Config.Time.NightDurationMs or 2000)

                        -- Verificar tiempo transcurrido en días reales (incluso con servidor apagado)
                        local secondsElapsed = os.time() - LastRotationTimestamp
                        local seasonDurationSeconds = (Config.SeasonDurationDays or 7) * 86400

                        if secondsElapsed >= seasonDurationSeconds then
                            local nextSeason = Config.Seasons[CurrentSeason] and Config.Seasons[CurrentSeason].nextSeason or 'summer'
                            RotateSeason(nextSeason)
                        else
                            local calculatedDayInSeason = math.max(1, math.min(Config.SeasonDurationDays or 7, math.floor(secondsElapsed / 86400) + 1))
                            if calculatedDayInSeason ~= DayInSeason then
                                DayInSeason = calculatedDayInSeason
                                SaveSeasonState()
                            end
                            SyncToGlobalState(true)
                        end

                        print(string.format('^2[AuraRP Seasons]^7 Estado cargado desde BD: ^3%s^7 | ^3Día %d/%d (Total: %d)^7 | ^3Clima: %s^7 | ^3Temp: %.1fºC^7 | ^3Hora: %02d:%02d (%s)^7',
                            Config.Seasons[CurrentSeason] and Config.Seasons[CurrentSeason].label or CurrentSeason,
                            DayInSeason,
                            Config.SeasonDurationDays or 7,
                            CurrentDay,
                            WeatherOverride or CurrentWeather,
                            BaseTemperature,
                            CurrentHour,
                            CurrentMinute,
                            IsTimeFrozen and "Pausada" or (IsCurrentDaytime() and "Día" or "Noche")
                        ))
                    else
                        CurrentSeason = 'spring'
                        CurrentDay = 1
                        DayInSeason = 1
                        CurrentWeather = 'CLEAR'
                        BaseTemperature = 18.0
                        CurrentHour = 12
                        CurrentMinute = 0
                        IsTimeFrozen = false
                        SaveSeasonState()
                        SyncToGlobalState(true)
                    end
                end)
            end)
        end)
    end)
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    InitializeSeasons()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    print('^3[AuraRP Seasons]^7 Guardando estado persistente antes de apagar...')
    SaveSeasonState()
end)

-- Auto-guardado periódico de seguridad de tiempo y estaciones (cada 1 minuto)
CreateThread(function()
    local saveInterval = (Config.Time and Config.Time.SaveIntervalMinutes or 1) * 60 * 1000
    while true do
        Wait(saveInterval)
        SaveSeasonState()
    end
end)

-- ============================================================================
-- MOTOR DE TIEMPO CENTRALIZADO Y CICLO DÍA / NOCHE
-- ============================================================================

CreateThread(function()
    while true do
        local isDay = IsCurrentDaytime()
        local interval = isDay and DayDurationMs or NightDurationMs
        Wait(interval)

        if not IsTimeFrozen then
            CurrentMinute = CurrentMinute + 1

            if CurrentMinute >= 60 then
                CurrentMinute = 0
                CurrentHour = CurrentHour + 1

                if CurrentHour >= 24 then
                    CurrentHour = 0
                end
            end

            GlobalState.ServerTime = {
                hour = CurrentHour,
                minute = CurrentMinute,
                isFrozen = IsTimeFrozen,
                isDay = IsCurrentDaytime(),
                dayDuration = DayDurationMs,
                nightDuration = NightDurationMs
            }
            GlobalState.AuraTime = {
                h = CurrentHour,
                m = CurrentMinute
            }
        end
    end
end)

-- ============================================================================
-- BUCLE PRINCIPAL DE ROTACIÓN Y CLIMA DINÁMICO
-- ============================================================================

-- Bucle de rotación de clima dinámico (cada X minutos)
CreateThread(function()
    while true do
        Wait((Config.WeatherChangeInterval or 15) * 60 * 1000)
        
        if not WeatherOverride then
            CurrentWeather = GetRandomWeatherForSeason(CurrentSeason)
            BaseTemperature = CalculateBaseTemperature(CurrentSeason)
            SyncToGlobalState()
        end
    end
end)

-- Bucle de calendario diario y avance de estaciones (comprobación cada hora)
CreateThread(function()
    while true do
        Wait(60 * 60 * 1000) -- Cada hora

        local secondsElapsed = os.time() - LastRotationTimestamp
        local calculatedDaysInSeason = math.floor(secondsElapsed / 86400) + 1
        
        if calculatedDaysInSeason > (Config.SeasonDurationDays or 7) then
            -- Rotar a la siguiente estación
            local nextSeason = Config.Seasons[CurrentSeason].nextSeason or 'spring'
            CurrentDay = CurrentDay + 1
            RotateSeason(nextSeason)
        else
            if calculatedDaysInSeason ~= DayInSeason then
                DayInSeason = calculatedDaysInSeason
                CurrentDay = CurrentDay + 1
                SaveSeasonState()
                SyncToGlobalState()
            end
        end
    end
end)

-- Sincronizar jugador al conectarse / entrar
RegisterNetEvent('aura_seasons:server:requestSync', function()
    local src = source
    local targetWeather = WeatherOverride or CurrentWeather
    local hasSnow = IsSnowWeather(targetWeather, CurrentSeason)
    TriggerClientEvent('aura_seasons:client:syncWeather', src, {
        season = CurrentSeason,
        weather = targetWeather,
        baseTemp = BaseTemperature,
        dayInSeason = DayInSeason,
        totalDay = CurrentDay,
        hasSnow = hasSnow,
        instant = true
    })
end)

-- ============================================================================
-- COMANDOS DE ADMINISTRACIÓN (OX_LIB INTEGRATION)
-- ============================================================================

lib.addCommand('setseason', {
    help = 'Cambiar la estación climática del servidor',
    params = {
        { name = 'season', type = 'string', help = 'spring | summer | autumn | winter' }
    },
    restricted = 'group.admin'
}, function(source, args)
    local targetSeason = string.lower(args.season or '')
    if Config.Seasons[targetSeason] then
        RotateSeason(targetSeason)
        if source > 0 then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Sistema Estacional',
                description = ('Estación cambiada manualmente a %s'):format(Config.Seasons[targetSeason].label),
                type = 'success'
            })
        end
    else
        if source > 0 then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Error',
                description = 'Estación inválida. Usa: spring, summer, autumn, winter.',
                type = 'error'
            })
        end
    end
end)

lib.addCommand('setweather', {
    help = 'Forzar un clima específico en el servidor',
    params = {
        { name = 'weather', type = 'string', help = 'EXTRASUNNY, CLEAR, RAIN, XMAS, BLIZZARD, etc. (o "reset")' }
    },
    restricted = 'group.admin'
}, function(source, args)
    local weatherType = string.upper(args.weather or '')
    if weatherType == 'RESET' then
        WeatherOverride = nil
        CurrentWeather = GetRandomWeatherForSeason(CurrentSeason)
        SaveSeasonState()
        SyncToGlobalState(true)
        if source > 0 then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Clima Dinámico',
                description = 'Se ha restaurado el clima dinámico estacional.',
                type = 'inform'
            })
        end
    else
        WeatherOverride = weatherType
        BaseTemperature = CalculateBaseTemperature(CurrentSeason)
        SaveSeasonState()
        SyncToGlobalState(true)
        if source > 0 then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Clima Forzado',
                description = ('Clima fijado en %s'):format(weatherType),
                type = 'success'
            })
        end
    end
end)

lib.addCommand('seasonsinfo', {
    help = 'Ver estado actual de estación, clima y temperatura del servidor'
}, function(source)
    local msg = ('Estación: %s | Día: %d/%d (Total: %d) | Clima: %s | Temp Base: %.1fºC'):format(
        Config.Seasons[CurrentSeason].label,
        DayInSeason,
        Config.SeasonDurationDays,
        CurrentDay,
        WeatherOverride or CurrentWeather,
        BaseTemperature
    )
    if source > 0 then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'AuraRP Seasons',
            description = msg,
            type = 'inform',
            duration = 6000
        })
    else
        print('^2[AuraRP Seasons]^7 ' .. msg)
    end
end)

lib.addCommand('settime', {
    help = 'Ajustar la hora del servidor (0-23) y minutos opcionales (0-59)',
    params = {
        { name = 'hour', type = 'number', help = 'Hora (0-23)' },
        { name = 'minute', type = 'number', optional = true, help = 'Minuto (0-59)' }
    },
    restricted = 'group.admin'
}, function(source, args)
    local h = tonumber(args.hour) or 12
    local m = tonumber(args.minute) or 0
    SetTimeServer(h, m)
    if source > 0 then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Control de Tiempo',
            description = string.format('Hora ajustada a %02d:%02d', h, m),
            type = 'success'
        })
    else
        print(string.format('^2[AuraRP Seasons]^7 Hora del servidor ajustada a %02d:%02d', h, m))
    end
end)

lib.addCommand('freezetime', {
    help = 'Pausar o reanudar el paso del tiempo en el servidor',
    restricted = 'group.admin'
}, function(source)
    SetTimeFrozenServer(not IsTimeFrozen)
    local msg = IsTimeFrozen and 'Tiempo congelado' or 'Tiempo reanudado'
    if source > 0 then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Control de Tiempo',
            description = msg,
            type = 'inform'
        })
    else
        print('^2[AuraRP Seasons]^7 ' .. msg)
    end
end)

local function SetWeatherServer(weatherType)
    if weatherType == 'RESET' then
        WeatherOverride = nil
        CurrentWeather = GetRandomWeatherForSeason(CurrentSeason)
    else
        WeatherOverride = weatherType
        BaseTemperature = CalculateBaseTemperature(CurrentSeason)
    end
    SaveSeasonState()
    SyncToGlobalState(true)
end

local function SetTimeServer(hour, minute)
    CurrentHour = math.max(0, math.min(23, tonumber(hour) or 12))
    CurrentMinute = math.max(0, math.min(59, tonumber(minute) or 0))
    SaveSeasonState()
    SyncToGlobalState(true)
end

local function SetTimeFrozenServer(frozen)
    IsTimeFrozen = (frozen == true or frozen == 1 or frozen == '1')
    SaveSeasonState()
    SyncToGlobalState(false)
end

local function SetTimeSpeedServer(dayMs, nightMs)
    if dayMs then
        DayDurationMs = math.max(100, tonumber(dayMs) or 2000)
    end
    if nightMs then
        NightDurationMs = math.max(100, tonumber(nightMs) or 2000)
    end
    SaveSeasonState()
    SyncToGlobalState(false)
end

local function SetSeasonDayServer(newDay)
    newDay = math.max(1, math.min(Config.SeasonDurationDays or 7, tonumber(newDay) or 1))
    DayInSeason = newDay
    SaveSeasonState()
    SyncToGlobalState(true)
end

local function AdvanceDayServer(delta)
    delta = tonumber(delta) or 1
    CurrentDay = math.max(1, CurrentDay + delta)
    DayInSeason = DayInSeason + delta

    if DayInSeason > (Config.SeasonDurationDays or 7) then
        local nextSeason = Config.Seasons[CurrentSeason].nextSeason or 'spring'
        RotateSeason(nextSeason)
    elseif DayInSeason < 1 then
        DayInSeason = 1
        SaveSeasonState()
        SyncToGlobalState(true)
    else
        SaveSeasonState()
        SyncToGlobalState(true)
    end
end

-- Exports del Servidor
exports('GetCurrentSeason', function() return CurrentSeason end)
exports('GetCurrentWeather', function() return WeatherOverride or CurrentWeather end)
exports('GetBaseTemperature', function() return BaseTemperature end)
exports('GetSeasonDay', function() return DayInSeason end)
exports('GetTotalDay', function() return CurrentDay end)
exports('GetTime', function()
    return {
        hour = CurrentHour,
        minute = CurrentMinute,
        isFrozen = IsTimeFrozen,
        isDay = IsCurrentDaytime(),
        dayDuration = DayDurationMs,
        nightDuration = NightDurationMs
    }
end)

exports('SetSeason', RotateSeason)
exports('SetWeather', SetWeatherServer)
exports('SetSeasonDay', SetSeasonDayServer)
exports('AdvanceDay', AdvanceDayServer)
exports('SetTime', SetTimeServer)
exports('SetTimeFrozen', SetTimeFrozenServer)
exports('SetTimeSpeed', SetTimeSpeedServer)

