Config = {}

Config.Debug = false

-- ============================================================================
-- 1. CONFIGURACIÓN DEL TRABAJO EMS Y PERMISOS
-- ============================================================================
Config.JobName = 'ambulance'

-- Grados del cuerpo médico y accesos jerárquicos
-- 0: Enfermero en Prácticas
-- 1: Paramédico
-- 2: Médico Titular
-- 3: Cirujano Especialista
-- 4: Director Médico (Boss)
Config.BossGrade = 4

-- ============================================================================
-- 2. SMART DISPATCH & BLIPS TEMPORALES
-- ============================================================================
Config.Dispatch = {
    blipDuration = 120, -- Segundos de persistencia del blip en mapa (2 min)
    blipSprite = 153,   -- Cruz médica
    blipColor = 1,      -- Rojo / Turquesa
    radiusColor = 1,
    radiusAlpha = 160,
    radiusSize = 70.0,
    maxUnitsPerCall = 2 -- Máximo 2 unidades médicas asignadas por llamada
}

-- ============================================================================
-- 3. RADIO ENCRIPTADA EXCLUSIVA EMS (10.0 MHz - 19.9 MHz)
-- ============================================================================
Config.Radio = {
    minFrequency = 10.0,
    maxFrequency = 19.9,
    requiredItems = {
        'radio',
        'radio_satelite'
    },
    defaultChannels = {
        { index = 1, label = "Canal #1", frequency = 10.1, color = "#40E0D0", blipColor = 1 },
        { index = 2, label = "Canal #2", frequency = 10.2, color = "#40E0D0", blipColor = 1 },
        { index = 3, label = "Canal #3", frequency = 10.3, color = "#40E0D0", blipColor = 1 },
        { index = 4, label = "Canal #4", frequency = 10.4, color = "#40E0D0", blipColor = 1 },
        { index = 5, label = "Canal #5", frequency = 10.5, color = "#FF007F", blipColor = 48 },
        { index = 6, label = "Canal #6", frequency = 10.6, color = "#FF007F", blipColor = 48 },
        { index = 7, label = "Canal #7", frequency = 10.7, color = "#FF007F", blipColor = 48 },
        { index = 8, label = "Canal #8", frequency = 10.8, color = "#40E0D0", blipColor = 38 },
        { index = 9, label = "Canal #9", frequency = 10.9, color = "#40E0D0", blipColor = 38 },
        { index = 10, label = "Canal #10", frequency = 11.0, color = "#38bdf8", blipColor = 3 },
        { index = 11, label = "Canal #11", frequency = 11.1, color = "#f59e0b", blipColor = 46 },
        { index = 12, label = "Canal #12", frequency = 11.2, color = "#3b82f6", blipColor = 38 },
        { index = 13, label = "Canal #13", frequency = 11.3, color = "#ef4444", blipColor = 1 },
        { index = 14, label = "Canal #14", frequency = 11.4, color = "#40E0D0", blipColor = 1 },
        { index = 15, label = "Canal #15", frequency = 11.5, color = "#a855f7", blipColor = 27 },
        { index = 16, label = "Canal #16", frequency = 11.6, color = "#10b981", blipColor = 2 },
        { index = 17, label = "Canal #17", frequency = 11.7, color = "#64748b", blipColor = 39 },
        { index = 18, label = "Canal #18", frequency = 11.8, color = "#40E0D0", blipColor = 1 },
        { index = 19, label = "Canal #19", frequency = 11.9, color = "#FF007F", blipColor = 48 },
        { index = 20, label = "Canal #20", frequency = 12.0, color = "#d946ef", blipColor = 83 }
    }
}

-- ============================================================================
-- 4. OPERACIONES DE CAMPO Y REANIMACIÓN (FIELD OPS)
-- ============================================================================
Config.FieldOps = {
    tourniquet = {
        item = 'torniquete',
        duration = 3500,
        animDict = 'mini@repair',
        animClip = 'fixing_a_ped'
    },
    defib = {
        item = 'desfibrilador',
        minigame = 'StartDefib',
        minigameOptions = {
            timeLimit = 25,
            chargeDuration = 2.5,
            requiredShocks = 2,
            shockTolerance = 0.22
        }
    },
    revival = {
        health = 140,       -- Salud otorgada tras descarga DEA exitosa
        hunger = 15.0,      -- Inanición post-coma (15%)
        thirst = 15.0,      -- Deshidratación post-coma (15%)
        stamina = 0.0       -- Agotamiento extremo
    }
}

-- ============================================================================
-- 5. FLOTA DE VEHÍCULOS MÉDICOS POR RANGO
-- ============================================================================
Config.Vehicles = {
    {
        model = 'ambulance',
        label = 'Ambulancia de Soporte Vital (SVB)',
        category = 'Ambulancia',
        minGrade = 0,
        desc = 'Unidad de traslado asistencial y soporte vital básico con camilla medicalizada.',
        icon = 'fa-solid fa-truck-medical',
        image = 'ambulance.png',
        livery = 0
    },
    {
        model = 'granger2',
        label = 'SUV Rápido de Intervención Médica (VIR)',
        category = 'Intervención',
        minGrade = 1,
        desc = 'SUV 4x4 de respuesta médica urgente con equipamiento de reanimación avanzada.',
        icon = 'fa-solid fa-car-side',
        image = 'granger2.png',
        livery = 0
    },
    {
        model = 'polalamo',
        label = 'Unidad Táctica de Rescate y Catástrofes',
        category = 'Rescate',
        minGrade = 2,
        desc = 'Vehículo de rescate en montaña, zonas hostiles y triaje de múltiples víctimas.',
        icon = 'fa-solid fa-truck-pickup',
        image = 'polalamo.png',
        livery = 0
    },
    {
        model = 'fbi2',
        label = 'Unidad de Mando Médico / Jefatura EMS',
        category = 'Jefatura',
        minGrade = 3,
        desc = 'Vehículo de coordinación médica de incidentes, supervisión y mando directivo.',
        icon = 'fa-solid fa-shield-halved',
        image = 'fbi2.png',
        livery = 0
    }
}

Config.Helicopters = {
    {
        model = 'supervolito2',
        label = 'Helicóptero Medevac Air-Ambulance',
        category = 'Aéreo',
        minGrade = 2,
        desc = 'Unidad aérea sanitaria de evacuación crítica con monitor multiparamétrico y soporte vital.',
        icon = 'fa-solid fa-helicopter',
        image = 'supervolito.png',
        livery = 0
    }
}

-- ============================================================================
-- 6. MLO INFRASTRUCTURE (3 HOSPITALES ACTIVOS)
-- ============================================================================
Config.Stations = {
    -- 1. Hospital Central Pillbox Hill (hospital_map)
    ['pillbox'] = {
        label = 'Hospital Central de Pillbox Hill',
        shortName = 'Pillbox Hill',
        blip = { coords = vector3(309.5, -596.5, 43.28), sprite = 61, color = 1, scale = 0.85 },
        duty = {
            coords = vector3(310.2, -597.4, 43.28),
            radius = 1.6
        },
        pharmacy = {
            coords = vector3(306.8, -601.5, 43.28),
            radius = 1.6,
            stashId = 'ems_pharmacy_pillbox',
            slots = 50,
            maxWeight = 250000 -- 250kg
        },
        garage = {
            interact = vector3(340.5, -560.5, 28.74),
            spawn = vector4(338.2, -570.2, 28.8, 340.0),
            heading = 340.0
        },
        helipad = {
            interact = vector3(351.9, -588.5, 74.16),
            spawn = vector4(351.9, -588.5, 74.16, 160.0),
            heading = 160.0
        }
    },

    -- 2. Thunder Medical Center (thunder_medicalcenter / El Burro)
    ['thunder'] = {
        label = 'Thunder Medical Center',
        shortName = 'Thunder Medical',
        blip = { coords = vector3(1152.37, -1504.83, 41.29), sprite = 61, color = 1, scale = 0.85 },
        duty = {
            coords = vector3(1152.37, -1504.83, 41.29),
            radius = 1.6
        },
        pharmacy = {
            coords = vector3(1157.12, -1510.45, 41.29),
            radius = 1.6,
            stashId = 'ems_pharmacy_thunder',
            slots = 50,
            maxWeight = 250000
        },
        garage = {
            interact = vector3(1119.39, -1620.09, 34.69),
            spawn = vector4(1121.46, -1612.72, 34.69, 265.80),
            heading = 117.77
        },
        helipad = {
            interact = vector3(1178.50, -1490.20, 48.50),
            spawn = vector4(1178.50, -1490.20, 48.50, 90.0),
            heading = 90.0
        }
    },

    -- 3. Clínica de Paleto Bay (prompt_paleto_clinic)
    ['paleto'] = {
        label = 'Clínica Rural de Paleto Bay',
        shortName = 'Paleto Clinic',
        blip = { coords = vector3(-247.05, 6331.45, 32.43), sprite = 61, color = 1, scale = 0.85 },
        duty = {
            coords = vector3(-247.05, 6331.45, 32.43),
            radius = 1.6
        },
        pharmacy = {
            coords = vector3(-244.15, 6328.20, 32.43),
            radius = 1.6,
            stashId = 'ems_pharmacy_paleto',
            slots = 40,
            maxWeight = 200000
        },
        garage = {
            interact = vector3(-232.0, 6317.0, 31.5),
            spawn = vector4(-232.0, 6317.0, 31.5, 225.0),
            heading = 225.0
        },
        helipad = {
            interact = vector3(-260.5, 6345.0, 32.5),
            spawn = vector4(-260.5, 6345.0, 32.5, 45.0),
            heading = 45.0
        }
    }
}
