Config = {}

-- ============================================================================
-- AURARP SEASONS & THERMAL SURVIVAL CONFIGURATION
-- ============================================================================

-- Modo Desarrollo (permite a todos los jugadores ejecutar comandos de prueba sin configurar ACEs)
Config.AllowDevMode = true

-- Grupos de Administrador reconocidos
Config.AdminGroups = { 'admin', 'god', 'superadmin', 'mod' }

-- Duración de cada estación en días de la vida real (1 semana = 7 días reales)
Config.SeasonDurationDays = 7

-- ============================================================================
-- CONTROL DE TIEMPO Y CICLO DÍA / NOCHE
-- ============================================================================
Config.Time = {
    DefaultHour = 12,              -- Hora por defecto al inicializar
    DefaultMinute = 0,             -- Minuto por defecto al inicializar
    DayStartHour = 6,              -- A partir de las 06:00 se considera DÍA (14 horas de juego = 840 min in-game)
    NightStartHour = 20,           -- A partir de las 20:00 se considera NOCHE (10 horas de juego = 600 min in-game)
    
    -- Valores por defecto en milisegundos por minuto de juego:
    -- 2143 ms = 30 minutos reales para el Día entero (06:00 a 20:00)
    -- 1500 ms = 15 minutos reales para la Noche entera (20:00 a 06:00)
    -- Ciclo total de 24h = 45 minutos reales
    DayDurationMs = 2143,
    NightDurationMs = 1500,

    SaveIntervalMinutes = 1,       -- Intervalo de guardado automático de la hora exacta en BD (minutos)
}

-- Intervalo de rotación de clima dinámico dentro de la estación activa (en minutos)
Config.WeatherChangeInterval = 15 -- Cada 15 minutos cambia el clima dentro del catálogo estacional

-- Transición visual suave entre climas (en segundos)
Config.WeatherTransitionTime = 15.0

-- Definición de Estaciones y Parámetros Meteorológicos / Térmicos
Config.Seasons = {
    ['spring'] = {
        label = 'Primavera',
        minTemp = 14.0,
        maxTemp = 22.0,
        weatherPool = {
            { type = 'CLEAR', weight = 35 },
            { type = 'EXTRASUNNY', weight = 25 },
            { type = 'CLOUDS', weight = 15 },
            { type = 'OVERCAST', weight = 15 },
            { type = 'RAIN', weight = 10 }
        },
        hasSnow = false,
        nextSeason = 'summer'
    },
    ['summer'] = {
        label = 'Verano',
        minTemp = 28.0,
        maxTemp = 42.0,
        weatherPool = {
            { type = 'EXTRASUNNY', weight = 50 },
            { type = 'CLEAR', weight = 30 },
            { type = 'SMOG', weight = 15 },
            { type = 'CLOUDS', weight = 5 }
        },
        hasSnow = false,
        nextSeason = 'autumn'
    },
    ['autumn'] = {
        label = 'Otoño',
        minTemp = 8.0,
        maxTemp = 16.0,
        weatherPool = {
            { type = 'OVERCAST', weight = 30 },
            { type = 'RAIN', weight = 25 },
            { type = 'FOGGY', weight = 20 },
            { type = 'THUNDER', weight = 15 },
            { type = 'CLOUDS', weight = 10 }
        },
        hasSnow = false,
        nextSeason = 'winter'
    },
    ['winter'] = {
        label = 'Invierno',
        minTemp = -10.0,
        maxTemp = 5.0,
        weatherPool = {
            { type = 'XMAS', weight = 40 },
            { type = 'BLIZZARD', weight = 25 },
            { type = 'SNOWLIGHT', weight = 20 },
            { type = 'SNOW', weight = 10 },
            { type = 'FOGGY', weight = 5 }
        },
        hasSnow = true,
        nextSeason = 'spring'
    }
}

-- Orden canónico de las estaciones
Config.SeasonOrder = { 'spring', 'summer', 'autumn', 'winter' }

-- ============================================================================
-- PARÁMETROS DE SUPERVIVENCIA Y FISIOLOGÍA TÉRMICA
-- ============================================================================
Config.Survival = {
    -- Temperatura corporal ideal (Base Homeostasis)
    BaseCoreTemp = 37.0,
    
    -- Temperatura neutral del entorno donde el cuerpo no sufre estrés térmico
    NeutralAmbientTemp = 21.0,

    -- Intervalo del tick de simulación fisiológica en milisegundos (Adaptive Loop)
    BaseTickRate = 1500,
    ExtremeTickRate = 750,

    -- Umbrales de Hipotermia (Frío)
    Cold = {
        MildThreshold = 35.8,     -- Se activa indicador leve
        ModerateThreshold = 34.5, -- Comienzan temblores (animación shivering) y drenaje de stamina
        SevereThreshold = 33.0,   -- Comienza daño periódico a la salud
        DamagePerTick = 4,        -- Daño a la salud en hipotermia severa
        StaminaDrainMultiplier = 2.5
    },

    -- Umbrales de Hipertermia (Calor)
    Heat = {
        MildThreshold = 38.2,     -- Se activa indicador leve
        ModerateThreshold = 39.5, -- Sudoración, sensación de bochorno y ligero incremento de sed
        SevereThreshold = 41.0,   -- Tropiezos ocasionales y daño a la salud en calor extremo
        DamagePerTick = 3,        -- Daño suave a la salud en hipertermia severa
        ThirstDrainRate = 0.4     -- Drenaje moderado y realista de sed por tick (pausado)
    },

    -- Refugios y Climatización (Interiores y Vehículos)
    Shelter = {
        NormalizedTemp = 21.0,    -- Temperatura dentro de interiores o vehículos con motor encendido
        CoreRecoveryRate = 0.20   -- Velocidad de recuperación de temperatura por tick hacia 37.0ºC (dinámica y reconfortante)
    },

    -- Efecto de altura sobre la temperatura ambiental (-1ºC cada 100m sobre el nivel del mar)
    AltitudeLapseRate = 0.01, -- Grados Celsius por metro de elevación en Z
    
    -- Penalización por estar sumergido en agua fría
    WaterCoolingMultiplier = 2.2
}

-- ============================================================================
-- ITEMS CONSUMIBLES & RESISTENCIA TÉRMICA
-- ============================================================================
Config.Consumables = {
    ['coffee'] = {
        type = 'warmth',
        coreTempBoost = 1.5,
        buffDuration = 600, -- 10 minutos reales
        coldResistance = 0.50, -- Reduce el impacto del frío en un 50%
        label = 'Café Expreso Caliente'
    },
    ['hot_coffee'] = {
        type = 'warmth',
        coreTempBoost = 2.0,
        buffDuration = 600,
        coldResistance = 0.60,
        label = 'Café Caliente'
    },
    ['water'] = {
        type = 'cooling',
        coreTempBoost = -1.2,
        buffDuration = 600,
        heatResistance = 0.50, -- Reduce el impacto del calor en un 50%
        label = 'Botella de Agua Fresca'
    },
    ['water_bottle'] = {
        type = 'cooling',
        coreTempBoost = -1.5,
        buffDuration = 600,
        heatResistance = 0.55,
        label = 'Botella de Agua Mineral'
    }
}
