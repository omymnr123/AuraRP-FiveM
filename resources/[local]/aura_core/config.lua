Config = {}

-- ==========================================================
-- CONFIGURACIÓN DE DENSIDAD DE NPC Y TRÁFICO (Reducción 80%)
-- ==========================================================
Config.Density = {
    Peds = 0.20,             -- Multiplicador de peatones/NPCs (0.20 = 20% del valor base, -80%)
    ScenarioPeds = 0.20,     -- Multiplicador de peatones en escenarios/aceras/bancos
    Vehicles = 0.20,         -- Multiplicador de vehículos en circulación
    ParkedVehicles = 0.20,   -- Multiplicador de vehículos estacionados
    RandomVehicles = 0.20,   -- Multiplicador de vehículos aleatorios
    AmbientRange = 0.20      -- Rango de generación de tráfico ambiental
}

-- ==========================================================
-- PROTECCIÓN DE INTERIORES / NEGOCIOS / MLOS
-- ==========================================================
Config.Interiors = {
    ClearInteriorPeds = true,        -- Elimina automáticamente NPCs ambientales dentro de interiores
    ScanInterval = 1000,             -- Intervalo de escaneo en ms
    ClearRadiusWhenInside = 40.0     -- Radio de limpieza de peds ambientales cuando el jugador está dentro de un interior
}

-- ==========================================================
-- PACIFICACIÓN DE NPCS / RELACIONES
-- ==========================================================
Config.PacifyNPCs = {
    DisableAggression = true,        -- Desactiva la agresividad de todos los NPCs hacia los jugadores
    GangsIgnorePlayers = true,       -- Las bandas y mafias de GTA no atacan ni increpan a los jugadores
    FleeOnPanic = true               -- Los peatones huyen en lugar de atacar si se asustan
}
