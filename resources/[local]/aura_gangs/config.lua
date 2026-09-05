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
    },
    ['lostmc'] = {
        label = 'The Lost MC',
        society = 'lostmc',
        color = '#e67e22',
        tag = 'LOSTMC'
    },
    ['bratva'] = {
        label = 'Bratva (Mafia Rusa)',
        society = 'bratva',
        color = '#e74c3c',
        tag = 'BRATVA'
    },
    ['triada'] = {
        label = 'Tríada',
        society = 'triada',
        color = '#c0392b',
        tag = 'TRIADA'
    },
    ['yakuza'] = {
        label = 'Yakuza',
        society = 'yakuza',
        color = '#9b59b6',
        tag = 'YAKUZA'
    },
    ['marabunta'] = {
        label = 'Marabunta Grande',
        society = 'marabunta',
        color = '#00a8ff',
        tag = 'MARABUNTA'
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
        ['vagos']     = { label = 'VAGOS',     color = { r = 247, g = 183, b = 49 } },
        ['lostmc']    = { label = 'LOST MC',   color = { r = 230, g = 126, b = 34 } },
        ['bratva']    = { label = 'BRATVA',    color = { r = 231, g = 76,  b = 60 } },
        ['triada']    = { label = 'TRIADA',    color = { r = 192, g = 57,  b = 43 } },
        ['yakuza']    = { label = 'YAKUZA',    color = { r = 155, g = 89,  b = 182 } },
        ['marabunta'] = { label = 'MARABUNTA', color = { r = 0,   g = 168, b = 255 } }
    }
}

-- ============================================================================
-- 7. INVERNADERO INSTANCIADO Y CULTIVO DE WEED (PROJECT GREENHOUSE)
-- ============================================================================
Config.Greenhouse = {
    -- Interior instanciado ("sd2" Weed Lab MLO / GTA V Biker DLC Weed Farm)
    Interior = {
        name = "Invernadero Clandestino sd2",
        -- Coordenadas de aparición dentro del MLO al entrar
        spawnCoords = vec4(1066.37, -3183.47, -39.16, 270.0),
        -- Puerta interior para volver al exterior
        exitDoor = vec3(1066.37, -3183.47, -39.16),
        exitRadius = 2.0,
        -- Radio interior permitido para plantar
        plantingCenter = vec3(1051.49, -3196.53, -39.14),
        plantingRadius = 35.0
    },

    -- Asignación de Routing Buckets privados por organización criminal
    GangBuckets = {
        ['salieri']  = 101,
        ['vazou']    = 102,
        ['cartel']   = 103,
        ['ballas']   = 104,
        ['families'] = 105,
        ['vagos']     = 106,
        ['lostmc']    = 107,
        ['bratva']    = 108,
        ['triada']    = 109,
        ['yakuza']    = 110,
        ['marabunta'] = 111
    },

    -- Límites de cultivo por invernadero
    MaxPlantsPerGreenhouse = 25,
    MinPlantDistance = 1.0, -- Distancia mínima en metros entre macetas

    -- 4 Fases visuales de crecimiento (Hashes nativos oficiales GTA V)
    Stages = {
        [1] = {
            model = `prop_plant_pot_01a`,
            label = 'Fase 1: Maceta con Sustrato (Semilla Sembrada)',
            minGrowth = 0.0,
            maxGrowth = 25.0
        },
        [2] = {
            model = `bkr_prop_weed_01_small_01a`,
            label = 'Fase 2: Brote y Plántula Temprana',
            minGrowth = 25.0,
            maxGrowth = 55.0
        },
        [3] = {
            model = `bkr_prop_weed_med_01a`,
            label = 'Fase 3: Crecimiento Vegetativo y Ramificación',
            minGrowth = 55.0,
            maxGrowth = 90.0
        },
        [4] = {
            model = `bkr_prop_weed_lrg_01a`,
            label = 'Fase 4: Floración Madura (Lista para Cosechar)',
            minGrowth = 90.0,
            maxGrowth = 100.0
        }
    },

    -- Valores biológicos iniciales al asentar una maceta nueva (tierra seca y sin abonar)
    InitialStats = {
        thirst = 0.0,      -- 0% de hidratación (sustrato seco que requiere riego inmediato)
        nutrition = 0.0    -- 0% de fertilizante (requiere abonado NPK para activar la nutrición)
    },

    -- Motor de Crecimiento, Muerte por Descuido y Sobremaduración (2h de ciclo biológico)
    GrowthEngine = {
        tickInterval = 30,           -- Comprobación cada 30 segundos en servidor
        thirstDecay = 1.25,          -- -1.25% cada 30s (Exactamente -50% de agua cada 20 minutos)
        nutritionDecay = 1.25,       -- -1.25% cada 30s (Exactamente -50% de abono cada 20 minutos)
        baseGrowthRate = 0.35,       -- % de crecimiento por tick si tiene agua (>0) y abono (>0) (~2.3h)
        optimalBonusMultiplier = 1.2, -- Multiplicador si agua > 50% y abono > 50% -> 0.42% por tick (Exactamente 2.0h)
        maxNeglectedDuration = 600,  -- 10 minutos (600 segundos) al 0% de agua y nutrientes -> Muerte y eliminación de la planta
        maxMatureDuration = 900      -- 15 minutos (900 segundos) al 100% de crecimiento sin cosechar -> La planta se pudre y muere
    },

    -- Recompensas de Cosecha (Escaladas dinámicamente de 10 a 25 según el cuidado de la planta)
    Harvest = {
        requiredTool = 'tijeras_podar',
        rewardItem = 'cogollo_weed',
        minYield = 10,               -- Rendimiento mínimo (planta poco cuidada / seca)
        maxYield = 25,               -- Rendimiento máximo (planta con cuidado óptimo al 100%)
        harvestDuration = 5500
    },

    -- Mesa de Trabajo: Empaquetado, Pesaje de Precisión y Sellado Hermético
    Packaging = {
        requiredBudsItem = 'cogollo_weed',
        requiredBudsCount = 5,       -- Mínimo 5 cogollos de marihuana
        requiredBaggieItem = 'empty_baggies',
        requiredBaggieCount = 1,     -- 1 bolsita hermética
        outputItem = 'weed',         -- Entrega 1 bolsa de marihuana envasada
        outputCount = 1,

        -- Props de sillas, bancos y mesas de empaquetado interactuables
        targetModels = {
            `bkr_prop_weed_chair_01a`,
            `bkr_prop_weed_table_01a`,
            `bkr_prop_weed_scale_01a`,
            `bkr_prop_weed_scales_01a`,
            `bkr_prop_weed_drying_01a`,
            `bkr_prop_weed_drying_02a`,
            `bkr_prop_weed_tub_01a`,
            `bkr_prop_weed_bud_01a`,
            `bkr_prop_weed_bud_02a`,
            `bkr_prop_clubhouse_chair_01`,
            `bkr_prop_clubhouse_chair_02`,
            `bkr_prop_clubhouse_chair_03`,
            `prop_chair_01a`,
            `prop_chair_01b`,
            `prop_chair_02`,
            `prop_chair_03`,
            `prop_chair_04a`,
            `prop_chair_04b`,
            `prop_chair_05`,
            `prop_chair_06`,
            `prop_chair_08`,
            `prop_chair_10`,
            `prop_off_chair_01`,
            `prop_off_chair_03`,
            `prop_off_chair_04`,
            `prop_off_chair_04b`,
            `prop_off_chair_05`,
            `v_corp_offchair`,
            `v_corp_sidechair`,
            `v_club_officechair`,
            `v_ilev_chair02_p`,
            `v_ilev_hd_chair`,
            `v_ret_chair_white`,
            `v_ret_chair`,
            `v_ret_gc_chair01`,
            `v_ret_gc_chair02`,
            `prop_table_01`,
            `prop_table_02`,
            `prop_table_03`,
            `prop_table_03b_chr`,
            `prop_rub_chair_01`,
            `prop_rub_chair_02`,
            `apa_mp_h_din_chair_04`,
            `apa_mp_h_din_chair_08`,
            `apa_mp_h_din_chair_09`,
            `apa_mp_h_din_chair_12`,
            `ba_prop_battle_club_chair_01`,
            `ba_prop_battle_club_chair_02`,
            `gr_prop_gr_chair_office_01b`,
            `hei_prop_heist_off_chair`,
            `xm_prop_lab_chair_01`
        },

        -- Estaciones de empaquetado físicas dedicadas en el interior sd2 (Weed Farm)
        dedicatedStations = {
            { coords = vec3(1044.20, -3194.80, -39.15), heading = 90.0, radius = 2.0 },
            { coords = vec3(1040.50, -3194.80, -39.15), heading = 90.0, radius = 2.0 },
            { coords = vec3(1037.20, -3195.10, -39.15), heading = 180.0, radius = 2.0 },
            { coords = vec3(1048.80, -3194.80, -39.15), heading = 0.0, radius = 2.0 },
            { coords = vec3(1061.20, -3193.80, -39.15), heading = 270.0, radius = 2.0 },
            { coords = vec3(1043.15, -3195.80, -39.15), heading = 180.0, radius = 1.8 },
            { coords = vec3(1045.25, -3193.80, -39.15), heading = 0.0, radius = 1.8 }
        }
    },

    -- Allanamientos e Irrupciones Policiales (Police Raid)
    PoliceRaid = {
        requiredItem = 'ariete_policial',
        policeJob = 'police',
        minigame = { 'medium', 'hard', 'medium' },
        breachDuration = 7500,
        destroyDuration = 8000
    }
}

