-- ============================================================================
-- AURA GANGS: CONFIGURACIÓN GENERAL DEL ECOSISTEMA CLANDESTINO
-- ============================================================================

Config = {}

Config.Debug = false

-- Organizaciones / Bandas registradas en el sistema
Config.Gangs = {
    ['salieri'] = {
        label = 'Familia Salieri',
        society = 'salieri',
        color = '#8b0000',
        tag = 'SALIERI'
    },
    ['vazou'] = {
        label = 'Cártel Marc Vazou',
        society = 'vazou',
        color = '#40E0D0',
        tag = 'VAZOU'
    },
    ['cartel'] = {
        label = 'Cártel de Sinaloa',
        society = 'cartel',
        color = '#ffa502',
        tag = 'CARTEL'
    },
    ['ballas'] = {
        label = 'East Los Santos Ballas',
        society = 'ballas',
        color = '#8854d0',
        tag = 'BALLAS'
    },
    ['families'] = {
        label = 'Chamberlain Gangster Families',
        society = 'families',
        color = '#20bf6b',
        tag = 'FAMILIES'
    },
    ['vagos'] = {
        label = 'Los Santos Vagos',
        society = 'vagos',
        color = '#f7b731',
        tag = 'VAGOS'
    }
}

-- ============================================================================
-- 1. CONFIGURACIÓN DE ROBO DE VEHÍCULOS (LOCKPICK & HOTWIRE)
-- ============================================================================
Config.Theft = {
    lockpickItem = 'lockpick',
    advLockpickItem = 'adv_lockpick',

    -- Probabilidad porcentual de rotura al fallar
    breakChance = 40,
    advBreakChance = 25,

    -- Dificultad de los skill checks
    doorSkillCheck = { 'easy', 'easy', 'medium' },
    hotwireSkillCheck = { 'medium', 'hard', 'hard' },

    -- Controles para los minijuegos
    skillCheckInputs = { 'w', 'a', 's', 'd' }
}

-- ============================================================================
-- 2. DESGUACE CLANDESTINO (CHOP SHOP)
-- ============================================================================
Config.ChopShop = {
    -- Bahías de desguace físico (Zona industrial La Puerta & El Burro)
    Locations = {
        {
            name = 'Desguace La Puerta',
            coords = vec3(-425.43, -1686.27, 19.03),
            radius = 8.0,
            heading = 240.0
        },
        {
            name = 'Desguace El Burro Heights',
            coords = vec3(1564.34, -2163.90, 77.54),
            radius = 8.0,
            heading = 90.0
        },
        {
            name = 'Desguace El Burro Heights',
            coords = vec3(2340.93, 3051.97, 48.15),
            radius = 8.0,
            heading = 90.0
        }
    },

    -- Configuración detallada de piezas desmantelables y recompensas
    Parts = {
        ['hood'] = {
            label = 'Capó',
            item = 'car_hood',
            amount = 1,
            cashReward = { min = 400, max = 750 },
            duration = 8000
        },
        ['door_dside_f'] = {
            label = 'Puerta Delantera Izquierda',
            item = 'car_door',
            amount = 1,
            cashReward = { min = 350, max = 600 },
            duration = 8000
        },
        ['door_pside_f'] = {
            label = 'Puerta Delantera Derecha',
            item = 'car_door',
            amount = 1,
            cashReward = { min = 350, max = 600 },
            duration = 8000
        },
        ['door_dside_r'] = {
            label = 'Puerta Trasera Izquierda',
            item = 'car_door',
            amount = 1,
            cashReward = { min = 300, max = 550 },
            duration = 8000
        },
        ['door_pside_r'] = {
            label = 'Puerta Trasera Derecha',
            item = 'car_door',
            amount = 1,
            cashReward = { min = 300, max = 550 },
            duration = 8000
        },
        ['wheel_lf'] = {
            label = 'Rueda Delantera Izquierda',
            item = 'car_wheel',
            amount = 1,
            cashReward = { min = 250, max = 450 },
            duration = 10000
        },
        ['wheel_rf'] = {
            label = 'Rueda Delantera Derecha',
            item = 'car_wheel',
            amount = 1,
            cashReward = { min = 250, max = 450 },
            duration = 10000
        },
        ['wheel_lr'] = {
            label = 'Rueda Trasera Izquierda',
            item = 'car_wheel',
            amount = 1,
            cashReward = { min = 250, max = 450 },
            duration = 10000
        },
        ['wheel_rr'] = {
            label = 'Rueda Trasera Derecha',
            item = 'car_wheel',
            amount = 1,
            cashReward = { min = 250, max = 450 },
            duration = 10000
        },
        ['engine'] = {
            label = 'Bloque Motor',
            item = 'car_engine',
            amount = 1,
            cashReward = { min = 1500, max = 2800 },
            duration = 15000
        },
        ['exhaust'] = {
            label = 'Línea de Escape',
            item = 'car_exhaust',
            amount = 1,
            cashReward = { min = 400, max = 700 },
            duration = 15000
        },
        ['chassis'] = {
            label = 'Chasis y Bastidor',
            item = 'scrap_metal',
            amountMin = 3,
            amountMax = 6,
            duration = 12000
        }
    }
}

-- ============================================================================
-- 3. BLANQUEO DE CAPITALES (LAVADORAS CLANDESTINAS)
-- ============================================================================
Config.Laundry = {
    taxRate = 0.20,         -- 20% de comisión por lavado
    washDuration = 30 * 60, -- 30 minutos (1800 segundos)
    minAmount = 500,        -- Mínimo de dinero negro a introducir

    -- Props físicos identificados como lavadoras operables
    Props = {
        'prop_washer_01',
        'prop_washer_02',
        'prop_washer_03',
        'prop_dryer_01',
        'prop_dryer_02',
        'bkr_prop_prtmeth_washer'
    },

    -- Ubicación fija de lavandería clandestina para prop placement
    DefaultLocations = {
        vec3(1122.25, -3194.98, -40.40),
        vec3(96.38, -1390.28, 29.43)
    }
}

-- ============================================================================
-- 4. COCINA DE METANFETAMINA (METH LAB & PENALIZACIÓN CRÍTICA)
-- ============================================================================
Config.Meth = {
    -- Receta química para una tanda de síntesis de cristales
    Recipe = {
        { item = 'pseudoephedrine',   count = 2, label = 'Pseudoefedrina' },
        { item = 'hydrochloric_acid', count = 1, label = 'Ácido Clorhídrico' },
        { item = 'liquid_acetone',     count = 1, label = 'Acetona Industrial' },
        { item = 'empty_baggies',      count = 5, label = 'Bolsitas Herméticas' }
    },

    outputItem = 'meth',
    outputMin = 4,   -- Mínimo de bolsas producidas por tanda
    outputMax = 10,  -- Máximo de bolsas producidas por tanda

    -- Props de mesas de laboratorio químico
    Props = {
        'bkr_prop_meth_table01a',
        'bkr_prop_meth_setup',
        'v_ret_fh_labtable',
        'prop_chem_vial_02b'
    },

    -- Ubicación fija del laboratorio subterráneo (MLO Soloty Crystal Lab)
    LabLocations = {
        vec3(793.81, 2170.85, 53.09)
    }
}

-- ============================================================================
-- 5. REFINADO Y EMPAQUETADO DE COCAÍNA (COCAINE LAB & PURIFICACIÓN)
-- ============================================================================
Config.Cocaine = {
    -- Receta química para una tanda de refinado de cocaína
    Recipe = {
        { item = 'coca_leaf',     count = 10, label = 'Hojas de Coca' },
        { item = 'sulfuric_acid',  count = 1,  label = 'Ácido Sulfúrico' },
        { item = 'baking_soda',    count = 2,  label = 'Bicarbonato de Sodio' },
        { item = 'empty_baggies',  count = 5,  label = 'Bolsitas Herméticas' }
    },

    outputItem = 'cocaine',
    outputMin = 4,   -- Mínimo de bolsas producidas por tanda
    outputMax = 10,  -- Máximo de bolsas producidas por tanda

    -- Props de mesas de procesamiento de cocaína
    Props = {
        'bkr_prop_coke_table01a',
        'bkr_prop_coke_press_01b',
        'bkr_prop_coke_cuttable',
        'bkr_prop_coke_scale_01',
        'bkr_prop_coke_packaged_01'
    },

    -- Ubicaciones fijas para refinado de cocaína (Lab Central Soloty)
    LabLocations = {
        vec3(793.81, 2170.85, 53.09)
    }
}

-- ============================================================================
-- 6. GUERRA DE TERRITORIOS (GRAFFITI & TURF WARS)
-- ============================================================================
Config.Graffiti = {
    sprayItem = 'spray_can',
    maxRaycastDistance = 3.0,
    sprayDuration = 6000, -- 6 segundos de animación con spray

    -- Colores representativos de cada banda para los sprays en pared
    GangTags = {
        ['salieri']  = { label = 'SALIERI', color = { r = 180, g = 20, b = 20 } },
        ['vazou']    = { label = 'VAZOU', color = { r = 64, g = 224, b = 208 } },
        ['cartel']   = { label = 'CARTEL', color = { r = 255, g = 165, b = 2 } },
        ['ballas']   = { label = 'BALLAS', color = { r = 136, g = 84, b = 208 } },
        ['families'] = { label = 'FAMILIES', color = { r = 32, g = 191, b = 107 } },
        ['vagos']    = { label = 'VAGOS', color = { r = 247, g = 183, b = 49 } }
    }
}
