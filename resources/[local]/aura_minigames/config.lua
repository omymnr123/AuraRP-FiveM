Config = {}

-- Configuración general de Minijuegos AuraRP
Config.Defaults = {
    -- 1. Cerrajería Mecánica (Lockpick)
    Lockpick = {
        pins = 4,             -- Número de pernos del bombín (3 a 6)
        durability = 100,     -- Salud de la ganzúa antes de romperse
        tolerance = 0.09,     -- Margen de error en la línea de corte (calibrado para enganche fluido)
        difficulty = 'medium' -- 'easy', 'medium', 'hard'
    },

    -- 2. Bypass de Centralita / ECU Waveform (adv_lockpick)
    ECUBypass = {
        timeLimit = 35,       -- Segundos límite antes de bloqueo CAN-Bus
        syncHoldTime = 1.6,   -- Segundos requeridos de acoplamiento armónico sostenido
        tolerance = 0.22,     -- Tolerancia calibrada y precisa entre onda objetivo y ganzúa
        difficulty = 'medium' -- 'easy', 'medium', 'hard'
    },

    -- 3. Reactor Termoquímico (Laboratorio de Drogas)
    ChemicalReactor = {
        duration = 18,        -- Duración del ciclo de síntesis en segundos
        criticalTimeLimit = 3.0, -- Segundos permitidos en zona roja antes de la detonación
        safeMinPressure = 45, -- Rango seguro de presión (PSI)
        safeMaxPressure = 90,
        safeMinTemp = 130,    -- Rango seguro de temperatura (°C)
        safeMaxTemp = 190,
        difficulty = 'medium'
    },

    -- 4. Matriz Hexadecimal de Cifrado (Breach Protocol)
    CipherMatrix = {
        gridSize = 5,         -- Tamaño 5x5
        bufferSize = 4,       -- Capacidad máxima de la memoria búfer
        sequenceLength = 3,   -- Longitud del código objetivo a descifrar
        timeLimit = 30,       -- Segundos disponibles
        difficulty = 'medium'
    }
}
