Config = {}

-- Modo depuración en consola del servidor/cliente
Config.Debug = false

-- Tiempo de desangrado en estado herido (5 minutos = 300 segundos)
Config.BleedoutTime = 300

-- Tiempo durante el cual el personaje herido puede arrastrarse por el suelo (1 minuto = 60 segundos)
Config.CrawlDuration = 60

-- Tiempo desde que cae herido hasta que pierde el conocimiento (5 minutos = 300 segundos)
Config.UnconsciousDelay = 300

-- Tiempo de coma/inconsciencia adicional antes de PK forzoso si no se pulsa Hospital (5 minutos = 300 segundos)
Config.ComaDuration = 300

-- Cooldown en segundos del botón de alerta a emergencias (2 minutos = 120 segundos)
Config.DispatchCooldown = 120

-- Umbral de salud para activación del estado crítico (GTA V: 100 = muerte)
Config.DeathHealthThreshold = 100

-- Filtros cinemáticos de pantalla según la fase
Config.TimecycleInjured = 'DeathFailMPDark'
Config.TimecycleInjuredStrength = 0.50
Config.TimecycleUnconscious = 'DeathFailMPDark'
Config.TimecycleUnconsciousStrength = 0.92

-- Intervalo de sincronización periódica del tiempo restante con el servidor (segundos)
Config.SyncInterval = 10

-- Estado vital al reaparecer en el hospital
Config.HospitalReviveHealth = 200
Config.HospitalReviveArmor = 0
Config.HospitalReviveHunger = 80.0
Config.HospitalReviveThirst = 80.0

-- Camas de Hospitales Disponibles (Pillbox Hill, Sandy Shores, Paleto Bay)
-- Vector4(x, y, z, heading)
Config.HospitalBeds = {
    -- Hospital Pillbox Hill (Planta Principal / UCI)
    { coords = vector4(309.5, -596.5, 43.28, 20.0), name = "Pillbox Hill" },
    { coords = vector4(314.0, -594.8, 43.28, 20.0), name = "Pillbox Hill" },
    { coords = vector4(318.5, -593.2, 43.28, 20.0), name = "Pillbox Hill" },
    { coords = vector4(323.0, -591.5, 43.28, 20.0), name = "Pillbox Hill" },
    { coords = vector4(353.1, -584.6, 43.11, 65.0), name = "Pillbox Hill" },
    { coords = vector4(356.76, -585.86, 43.11, 248.0), name = "Pillbox Hill" },
    { coords = vector4(360.5, -587.0, 43.11, 248.0), name = "Pillbox Hill" },
    -- Centro Médico Sandy Shores
    { coords = vector4(1826.54, 3676.08, 34.28, 210.0), name = "Sandy Shores" },
    { coords = vector4(1828.94, 3678.58, 34.28, 210.0), name = "Sandy Shores" },
    -- Clínica Paleto Bay
    { coords = vector4(-247.38, 6331.45, 32.43, 225.0), name = "Paleto Bay" }
}

-- Coordenadas por defecto si no se encuentra cama cercana
Config.RespawnCoords = vector4(309.5, -596.5, 43.28, 20.0)

-- Items protegidos que NO se eliminan al reaparecer en el hospital tras PK
-- El jugador pierde TODO el inventario excepto su teléfono y documentación
Config.PreservedItems = {
    ['phone'] = true,
    ['id_card'] = true,
    ['police_badge'] = true,
    ['driver_license'] = true,
    ['weapon_license'] = true,
    ['identification'] = true
}

-- Animación en la cama del hospital
Config.BedAnimation = {
    dict = "anim@gangops@morgue@table@",
    anim = "body_search",
    flag = 1
}
