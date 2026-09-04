Config = {}

Config.Debug = false

-- ============================================================================
-- 0. CONFIGURACIÓN DE DESPACHO INTELIGENTE (SMART DISPATCH)
-- ============================================================================
Config.Dispatch = {
    -- Cooldown anti-spam (en segundos) por tirador para no saturar la centralita
    gunshotCooldown = 15,
    -- Duración de los blips en el mapa antes de auto-eliminarse (en segundos)
    blipDuration = 120
}

-- ============================================================================
-- 1. CONFIGURACIÓN DE PRISIÓN Y CÁRCEL (BOLINGBROKE PENITENTIARY)
-- ============================================================================
Config.Jail = {
    -- Coordenadas de la celda de ingreso en Bolingbroke Penitentiary
    cellCoords = vec4(1775.28, 2552.12, 45.56, 35.0),

    -- Radio de contención perimetral (en metros). Si el recluso lo supera, se le teletransporta de vuelta
    escapeRadius = 85.0,

    -- Coordenadas de liberación al cumplir condena (frente a las puertas de la prisión)
    releaseCoords = vec4(1847.45, 2585.94, 45.67, 270.0),

    -- Tiempo mínimo y máximo de condena en minutos
    minTime = 1,
    maxTime = 120
}

-- ============================================================================
-- 2. ESTACIONES DE POLICÍA (MISSION ROW, SANDY SHORES, PALETO BAY)
-- ============================================================================
Config.Stations = {
    ['mission_row'] = {
        label = 'Comisaría Central - Mission Row (LSPD)',
        blip = {
            sprite = 60,
            color = 38,
            scale = 0.85,
            name = 'LSPD - Mission Row'
        },
        armory = {
            coords = vec3(441.96, -983.81, 34.30),  -- 👈 Tus coordenadas exactas guardadas
            stashId = 'police_armory_mrpd',
            returnStashId = 'police_disposal_mrpd', -- 👈 Buzón de devolución (1 min)
            slots = 50,
            maxWeight = 1000000                     -- 1000kg
        },
        evidence = {
            coords = vec3(445.77, -984.78, 30.69),
            stashId = 'police_evidence_mrpd',
            slots = 100,
            maxWeight = 1000000 -- 1000kg
        },
        wardrobe = {
            coords = vec3(457.68, -979.34, 34.30)
        },
        garage = {
            spawn = vec4(438.42, -1018.30, 28.75, 90.0),
            interact = vec3(488.06, -1002.62, 26.82),
            heading = 269.11, -- Girado 180° para que la pantalla del terminal mire al oficial y no hacia la pared
            returns = {
                vec3(464.18, -1019.79, 28.10),
                vec3(464.00, -1015.00, 28.08)
            }
        },
        helipad = {
            spawn = vec4(449.25, -981.34, 43.69, 90.0),
            interact = vec3(453.12, -987.25, 43.69)
        }
    },

    ['sandy_shores'] = {
        label = 'Sheriff Office - Sandy Shores (BCSO)',
        blip = {
            sprite = 60,
            color = 38,
            scale = 0.85,
            name = 'BCSO - Sandy Shores'
        },
        armory = {
            coords = vec3(1851.48, 3683.47, 34.27),
            stashId = 'police_armory_sandy',
            slots = 50,
            maxWeight = 500000
        },
        evidence = {
            coords = vec3(1853.22, 3689.85, 34.27),
            stashId = 'police_evidence_sandy',
            slots = 80,
            maxWeight = 800000
        },
        wardrobe = {
            coords = vec3(1857.15, 3689.52, 34.27)
        },
        garage = {
            spawn = vec4(1863.85, 3678.95, 33.88, 210.0),
            interact = vec3(1860.25, 3682.15, 33.95)
        }
    },

    ['paleto_bay'] = {
        label = 'Sheriff Station - Paleto Bay (BCSO)',
        blip = {
            sprite = 60,
            color = 38,
            scale = 0.85,
            name = 'BCSO - Paleto Bay'
        },
        armory = {
            coords = vec3(-448.22, 6012.35, 31.72),
            stashId = 'police_armory_paleto',
            slots = 50,
            maxWeight = 500000
        },
        evidence = {
            coords = vec3(-444.85, 6010.55, 31.72),
            stashId = 'police_evidence_paleto',
            slots = 80,
            maxWeight = 800000
        },
        wardrobe = {
            coords = vec3(-442.15, 6014.22, 31.72)
        },
        garage = {
            spawn = vec4(-458.25, 6002.15, 31.35, 190.0),
            interact = vec3(-454.12, 6005.85, 31.45)
        }
    }
}

-- ============================================================================
-- 3. DOTACIÓN DE ARMERÍA POR RANGO POLICIAL (0: Cadete ... 5: Comisario)
-- ============================================================================
Config.ArmoryWeapons = {
    [0] = { -- Cadete
        { name = 'weapon_combatpistol', label = 'Pistola Glock 19 (9mm)', count = 1 },
        { name = 'ammo-9',              label = 'Munición 9mm (x50)',     count = 100 },
        { name = 'weapon_stungun',      label = 'Pistola Taser X26',      count = 1 },
        { name = 'weapon_nightstick',   label = 'Porra Reglamentaria',    count = 1 },
        { name = 'weapon_flashlight',   label = 'Linterna Táctica',       count = 1 },
        { name = 'handcuffs',           label = 'Esposas Reglamentarias', count = 1 },
        { name = 'radio',               label = 'Radio Walkie-Talkie',    count = 1 },
        { name = 'armour',              label = 'Chaleco Balístico',      count = 2 },
        { name = 'bandage',             label = 'Vendaje Médico',         count = 5 },
        { name = 'police_badge',        label = 'Placa Policial LSPD',    count = 1 },
        { name = 'bodycam',             label = 'Cámara Corporal Axon',   count = 1 }
    },
    [1] = { -- Oficial
        { name = 'weapon_combatpistol', label = 'Pistola Glock 19 (9mm)', count = 1 },
        { name = 'ammo-9',              label = 'Munición 9mm (x50)',     count = 100 },
        { name = 'weapon_stungun',      label = 'Pistola Taser X26',      count = 1 },
        { name = 'weapon_nightstick',   label = 'Porra Reglamentaria',    count = 1 },
        { name = 'weapon_flashlight',   label = 'Linterna Táctica',       count = 1 },
        { name = 'handcuffs',           label = 'Esposas Reglamentarias', count = 1 },
        { name = 'radio',               label = 'Radio Walkie-Talkie',    count = 1 },
        { name = 'armour',              label = 'Chaleco Balístico',      count = 2 },
        { name = 'bandage',             label = 'Vendaje Médico',         count = 5 },
        { name = 'police_badge',        label = 'Placa Policial LSPD',    count = 1 },
        { name = 'bodycam',             label = 'Cámara Corporal Axon',   count = 1 }
    },
    [2] = { -- Sargento
        { name = 'weapon_combatpistol', label = 'Pistola Glock 19 (9mm)',   count = 1 },
        { name = 'ammo-9',              label = 'Munición 9mm (x50)',       count = 100 },
        { name = 'weapon_pumpshotgun',  label = 'Escopeta Mossberg 590',    count = 1 },
        { name = 'ammo-shotgun',        label = 'Cartuchos Escopeta (x20)', count = 50 },
        { name = 'weapon_stungun',      label = 'Pistola Taser X26',        count = 1 },
        { name = 'weapon_nightstick',   label = 'Porra Reglamentaria',      count = 1 },
        { name = 'weapon_flashlight',   label = 'Linterna Táctica',         count = 1 },
        { name = 'handcuffs',           label = 'Esposas Reglamentarias',   count = 1 },
        { name = 'radio',               label = 'Radio Walkie-Talkie',      count = 1 },
        { name = 'armour',              label = 'Chaleco Balístico',        count = 2 },
        { name = 'bandage',             label = 'Vendaje Médico',           count = 5 },
        { name = 'spikestrip',          label = 'Banda de Clavos Portátil', count = 1 },
        { name = 'police_badge',        label = 'Placa Policial LSPD',      count = 1 },
        { name = 'bodycam',             label = 'Cámara Corporal Axon',     count = 1 }
    },
    [3] = { -- Teniente
        { name = 'weapon_combatpistol', label = 'Pistola Glock 19 (9mm)',    count = 1 },
        { name = 'ammo-9',              label = 'Munición 9mm (x50)',        count = 100 },
        { name = 'weapon_carbinerifle', label = 'Carabina Táctica M4',       count = 1 },
        { name = 'ammo-rifle',          label = 'Munición Rifle 5.56 (x60)', count = 100 },
        { name = 'weapon_pumpshotgun',  label = 'Escopeta Mossberg 590',     count = 1 },
        { name = 'ammo-shotgun',        label = 'Cartuchos Escopeta (x20)',  count = 50 },
        { name = 'weapon_stungun',      label = 'Pistola Taser X26',         count = 1 },
        { name = 'weapon_nightstick',   label = 'Porra Reglamentaria',       count = 1 },
        { name = 'weapon_flashlight',   label = 'Linterna Táctica',          count = 1 },
        { name = 'handcuffs',           label = 'Esposas Reglamentarias',    count = 1 },
        { name = 'radio',               label = 'Radio Walkie-Talkie',       count = 1 },
        { name = 'armour',              label = 'Chaleco Balístico',         count = 2 },
        { name = 'bandage',             label = 'Vendaje Médico',            count = 5 },
        { name = 'medikit',             label = 'Botiquín Táctico IFAK',     count = 1 },
        { name = 'spikestrip',          label = 'Banda de Clavos Portátil',  count = 1 },
        { name = 'police_badge',        label = 'Placa Policial LSPD',       count = 1 },
        { name = 'bodycam',             label = 'Cámara Corporal Axon',      count = 1 }
    },
    [4] = { -- Detective
        { name = 'weapon_combatpistol', label = 'Pistola Glock 19 (9mm)', count = 1 },
        { name = 'ammo-9',              label = 'Munición 9mm (x50)',     count = 100 },
        { name = 'weapon_stungun',      label = 'Pistola Taser X26',      count = 1 },
        { name = 'weapon_flashlight',   label = 'Linterna Táctica',       count = 1 },
        { name = 'handcuffs',           label = 'Esposas Reglamentarias', count = 1 },
        { name = 'radio',               label = 'Radio Walkie-Talkie',    count = 1 },
        { name = 'armour',              label = 'Chaleco Balístico',      count = 2 },
        { name = 'bandage',             label = 'Vendaje Médico',         count = 5 },
        { name = 'police_badge',        label = 'Placa Policial LSPD',    count = 1 },
        { name = 'bodycam',             label = 'Cámara Corporal Axon',   count = 1 }
    },
    [5] = { -- Comisario (Máxima Autoridad / Chief)
        { name = 'weapon_combatpistol', label = 'Pistola Glock 19 (9mm)',    count = 1 },
        { name = 'ammo-9',              label = 'Munición 9mm (x50)',        count = 100 },
        { name = 'weapon_carbinerifle', label = 'Carabina Táctica M4',       count = 1 },
        { name = 'ammo-rifle',          label = 'Munición Rifle 5.56 (x60)', count = 100 },
        { name = 'weapon_pumpshotgun',  label = 'Escopeta Mossberg 590',     count = 1 },
        { name = 'ammo-shotgun',        label = 'Cartuchos Escopeta (x20)',  count = 100 },
        { name = 'weapon_stungun',      label = 'Pistola Taser X26',         count = 1 },
        { name = 'weapon_nightstick',   label = 'Porra Reglamentaria',       count = 1 },
        { name = 'weapon_flashlight',   label = 'Linterna Táctica',          count = 1 },
        { name = 'handcuffs',           label = 'Esposas Reglamentarias',    count = 1 },
        { name = 'radio',               label = 'Radio Walkie-Talkie',       count = 1 },
        { name = 'armour',              label = 'Chaleco Balístico',         count = 2 },
        { name = 'bandage',             label = 'Vendaje Médico',            count = 5 },
        { name = 'medikit',             label = 'Botiquín Táctico IFAK',     count = 2 },
        { name = 'spikestrip',          label = 'Banda de Clavos Portátil',  count = 1 },
        { name = 'police_badge',        label = 'Placa Policial LSPD',       count = 1 },
        { name = 'bodycam',             label = 'Cámara Corporal Axon',      count = 1 }
    }
}

-- ============================================================================
-- 4. FLOTA VEHICULAR POLICIAL
-- ============================================================================
Config.Vehicles = {
    { model = 'police',  label = 'Patrulla Cruiser Vapid (LSPD)', minGrade = 0, category = 'Cruiser',      desc = 'Vehículo estándar de patrulla urbana con equipamiento táctico LSPD.' },
    { model = 'police2', label = 'Patrulla Buffalo Interceptor',  minGrade = 1, category = 'Interceptor',  desc = 'Unidad de interceptación y persecución de alta velocidad.' },
    { model = 'police3', label = 'Interceptor Vapid Cruiser',     minGrade = 1, category = 'Interceptor',  desc = 'Cruiser repotenciado con kit aerodinámico y suspensión reforzada.' },
    { model = 'policet', label = 'Furgón de Transporte / Celdas', minGrade = 1, category = 'Transporte',   desc = 'Furgón blindado con celdas de contención múltiple para detenidos.' },
    { model = 'fbi2',    label = 'SUV Blindado Granger LSPD',     minGrade = 2, category = 'SUV Blindado', desc = 'SUV táctico 4x4 con blindaje balístico ligero y espacio de carga.' },
    { model = 'riot',    label = 'Furgón Blindado SWAT / Riot',   minGrade = 3, category = 'SWAT',         desc = 'Vehículo de asalto táctico SWAT y contención de disturbios graves.' },
    { model = 'police4', label = 'Vehículo Camuflado (Unmarked)', minGrade = 4, category = 'Encubierto',   desc = 'Vehículo camuflado sin distintivos exteriores para operaciones de Detective.' }
}

Config.Helicopters = {
    { model = 'polmav', label = 'Helicóptero Policial Air-1 (Con Helicam)', minGrade = 2, category = 'Aéreo', desc = 'Unidad aérea con cámara térmica, foco de alta potencia y rastreador.' }
}

-- ============================================================================
-- 5. CATÁLOGO ESTÁNDAR DE SANCIONES Y MULTAS (PRE-SET FINES)
-- ============================================================================
Config.FinePresets = {
    { category = 'Tráfico',        code = 'TR-01', label = 'Exceso de velocidad leve (< 30 km/h)',           amount = 250 },
    { category = 'Tráfico',        code = 'TR-02', label = 'Exceso de velocidad grave (> 50 km/h)',          amount = 600 },
    { category = 'Tráfico',        code = 'TR-03', label = 'Conducción temeraria / Sentido contrario',       amount = 1200 },
    { category = 'Tráfico',        code = 'TR-04', label = 'Estacionamiento indebido en acera / carril bus', amount = 150 },
    { category = 'Tráfico',        code = 'TR-05', label = 'Conducción bajo efectos de sustancias',          amount = 2000 },
    { category = 'Orden Público',  code = 'OP-01', label = 'Desacato / Negativa a identificarse',            amount = 800 },
    { category = 'Orden Público',  code = 'OP-02', label = 'Insulto / Falta de respeto a la autoridad',      amount = 500 },
    { category = 'Orden Público',  code = 'OP-03', label = 'Alteración grave del orden público / Riña',      amount = 1000 },
    { category = 'Delitos Graves', code = 'DG-01', label = 'Posesión de arma de fuego ilegal',               amount = 3500 },
    { category = 'Delitos Graves', code = 'DG-02', label = 'Tentativa de robo o allanamiento',               amount = 2500 },
    { category = 'Delitos Graves', code = 'DG-03', label = 'Agresión física a funcionario público',          amount = 5000 },
    { category = 'Delitos Graves', code = 'DG-04', label = 'Fuga de control policial en vehículo',           amount = 3000 }
}

-- ============================================================================
-- 6. VESTUARIO Y UNIFORMES REGLAMENTARIOS POR RANGO (MASCULINO Y FEMENINO)
-- ============================================================================
Config.Uniforms = {
    [0] = { -- Cadete
        label = 'Uniforme de Cadete en Prácticas (LSPD)',
        ['Male'] = {
            components = {
                { component_id = 1,  drawable = 0,   texture = 0 }, -- Máscara
                { component_id = 3,  drawable = 19,  texture = 0 }, -- Brazos / Manga corta
                { component_id = 4,  drawable = 24,  texture = 0 }, -- Pantalón azul marino LSPD
                { component_id = 6,  drawable = 51,  texture = 0 }, -- Botas de servicio
                { component_id = 7,  drawable = 125, texture = 0 }, -- Cinturón táctico con funda
                { component_id = 8,  drawable = 58,  texture = 0 }, -- Camiseta interior
                { component_id = 9,  drawable = 0,   texture = 0 }, -- Sin chaleco exterior
                { component_id = 10, drawable = 0,   texture = 0 }, -- Sin galones
                { component_id = 11, drawable = 55,  texture = 0 }  -- Camisa manga corta LSPD
            },
            props = {
                { prop_id = 0, drawable = 46, texture = 0 }, -- Gorra de patrulla LSPD
                { prop_id = 1, drawable = -1, texture = 0 }
            }
        },
        ['Female'] = {
            components = {
                { component_id = 1,  drawable = 0,   texture = 0 },
                { component_id = 3,  drawable = 31,  texture = 0 },
                { component_id = 4,  drawable = 133, texture = 0 },
                { component_id = 6,  drawable = 52,  texture = 0 },
                { component_id = 7,  drawable = 95,  texture = 0 },
                { component_id = 8,  drawable = 35,  texture = 0 },
                { component_id = 9,  drawable = 0,   texture = 0 },
                { component_id = 10, drawable = 0,   texture = 0 },
                { component_id = 11, drawable = 48,  texture = 0 }
            },
            props = {
                { prop_id = 0, drawable = 45, texture = 0 },
                { prop_id = 1, drawable = -1, texture = 0 }
            }
        }
    },

    [1] = { -- Oficial
        label = 'Uniforme de Oficial de Patrulla (LSPD)',
        ['Male'] = {
            components = {
                { component_id = 1,  drawable = 0,   texture = 0 },
                { component_id = 3,  drawable = 19,  texture = 0 },
                { component_id = 4,  drawable = 24,  texture = 0 },
                { component_id = 6,  drawable = 51,  texture = 0 },
                { component_id = 7,  drawable = 125, texture = 0 },
                { component_id = 8,  drawable = 58,  texture = 0 },
                { component_id = 9,  drawable = 12,  texture = 0 }, -- Chaleco balístico LSPD
                { component_id = 10, drawable = 1,   texture = 0 }, -- Placa Oficial
                { component_id = 11, drawable = 55,  texture = 0 }
            },
            props = {
                { prop_id = 0, drawable = -1, texture = 0 },
                { prop_id = 1, drawable = -1, texture = 0 }
            }
        },
        ['Female'] = {
            components = {
                { component_id = 1,  drawable = 0,   texture = 0 },
                { component_id = 3,  drawable = 31,  texture = 0 },
                { component_id = 4,  drawable = 133, texture = 0 },
                { component_id = 6,  drawable = 52,  texture = 0 },
                { component_id = 7,  drawable = 95,  texture = 0 },
                { component_id = 8,  drawable = 35,  texture = 0 },
                { component_id = 9,  drawable = 34,  texture = 0 }, -- Chaleco balístico femenino LSPD
                { component_id = 10, drawable = 1,   texture = 0 },
                { component_id = 11, drawable = 48,  texture = 0 }
            },
            props = {
                { prop_id = 0, drawable = -1, texture = 0 },
                { prop_id = 1, drawable = -1, texture = 0 }
            }
        }
    },

    [2] = { -- Sargento
        label = 'Uniforme de Mando - Sargento (LSPD)',
        ['Male'] = {
            components = {
                { component_id = 1,  drawable = 0,   texture = 0 },
                { component_id = 3,  drawable = 20,  texture = 0 },
                { component_id = 4,  drawable = 24,  texture = 0 },
                { component_id = 6,  drawable = 51,  texture = 0 },
                { component_id = 7,  drawable = 126, texture = 0 }, -- Cinturón de mando con placa dorada
                { component_id = 8,  drawable = 58,  texture = 0 },
                { component_id = 9,  drawable = 12,  texture = 1 }, -- Chaleco táctico Sargento
                { component_id = 10, drawable = 3,   texture = 0 }, -- Triple galón de Sargento
                { component_id = 11, drawable = 317, texture = 0 }
            },
            props = {
                { prop_id = 0, drawable = 58, texture = 0 }, -- Gorra de plato oficial de mando
                { prop_id = 1, drawable = -1, texture = 0 }
            }
        },
        ['Female'] = {
            components = {
                { component_id = 1,  drawable = 0,   texture = 0 },
                { component_id = 3,  drawable = 31,  texture = 0 },
                { component_id = 4,  drawable = 133, texture = 0 },
                { component_id = 6,  drawable = 52,  texture = 0 },
                { component_id = 7,  drawable = 96,  texture = 0 },
                { component_id = 8,  drawable = 35,  texture = 0 },
                { component_id = 9,  drawable = 34,  texture = 1 },
                { component_id = 10, drawable = 3,   texture = 0 },
                { component_id = 11, drawable = 327, texture = 0 }
            },
            props = {
                { prop_id = 0, drawable = 57, texture = 0 },
                { prop_id = 1, drawable = -1, texture = 0 }
            }
        }
    },

    [3] = { -- Teniente
        label = 'Uniforme de Mando - Teniente (LSPD)',
        ['Male'] = {
            components = {
                { component_id = 1,  drawable = 0,   texture = 0 },
                { component_id = 3,  drawable = 20,  texture = 0 },
                { component_id = 4,  drawable = 24,  texture = 0 },
                { component_id = 6,  drawable = 51,  texture = 0 },
                { component_id = 7,  drawable = 126, texture = 0 },
                { component_id = 8,  drawable = 58,  texture = 0 },
                { component_id = 9,  drawable = 12,  texture = 1 },
                { component_id = 10, drawable = 4,   texture = 0 }, -- Insignia de Teniente
                { component_id = 11, drawable = 317, texture = 1 }  -- Uniforme Class A Teniente
            },
            props = {
                { prop_id = 0, drawable = 58, texture = 0 },
                { prop_id = 1, drawable = -1, texture = 0 }
            }
        },
        ['Female'] = {
            components = {
                { component_id = 1,  drawable = 0,   texture = 0 },
                { component_id = 3,  drawable = 31,  texture = 0 },
                { component_id = 4,  drawable = 133, texture = 0 },
                { component_id = 6,  drawable = 52,  texture = 0 },
                { component_id = 7,  drawable = 96,  texture = 0 },
                { component_id = 8,  drawable = 35,  texture = 0 },
                { component_id = 9,  drawable = 34,  texture = 1 },
                { component_id = 10, drawable = 4,   texture = 0 },
                { component_id = 11, drawable = 327, texture = 1 }
            },
            props = {
                { prop_id = 0, drawable = 57, texture = 0 },
                { prop_id = 1, drawable = -1, texture = 0 }
            }
        }
    },

    [4] = { -- Detective
        label = 'Indumentaria de Investigación - Detective (LSPD)',
        ['Male'] = {
            components = {
                { component_id = 1,  drawable = 0,   texture = 0 }, -- Máscara
                { component_id = 3,  drawable = 11,  texture = 0 }, -- Brazos con camisa
                { component_id = 4,  drawable = 28,  texture = 0 }, -- Pantalón formal
                { component_id = 6,  drawable = 10,  texture = 0 }, -- Zapatos elegantes
                { component_id = 7,  drawable = 125, texture = 0 }, -- Funda táctica con placa en cinturón
                { component_id = 8,  drawable = 31,  texture = 0 }, -- Camisa con corbata
                { component_id = 9,  drawable = 0,   texture = 0 }, -- Sin chaleco exterior
                { component_id = 10, drawable = 0,   texture = 0 },
                { component_id = 11, drawable = 10,  texture = 0 }  -- Chaqueta blazer Detective
            },
            props = {
                { prop_id = 0, drawable = -1, texture = 0 },
                { prop_id = 1, drawable = 5,  texture = 0 } -- Gafas de sol tácticas
            }
        },
        ['Female'] = {
            components = {
                { component_id = 1,  drawable = 0,  texture = 0 },
                { component_id = 3,  drawable = 14, texture = 0 },
                { component_id = 4,  drawable = 37, texture = 0 },
                { component_id = 6,  drawable = 13, texture = 0 },
                { component_id = 7,  drawable = 95, texture = 0 },
                { component_id = 8,  drawable = 35, texture = 0 },
                { component_id = 9,  drawable = 0,  texture = 0 },
                { component_id = 10, drawable = 0,  texture = 0 },
                { component_id = 11, drawable = 6,  texture = 0 }
            },
            props = {
                { prop_id = 0, drawable = -1, texture = 0 },
                { prop_id = 1, drawable = 5,  texture = 0 }
            }
        }
    },

    [5] = { -- Comisario (Máxima Autoridad / Chief of Police)
        label = 'Uniforme de Gala y Máxima Autoridad - Comisario (LSPD)',
        ['Male'] = {
            components = {
                { component_id = 1,  drawable = 0,   texture = 0 },
                { component_id = 3,  drawable = 20,  texture = 0 },
                { component_id = 4,  drawable = 24,  texture = 0 }, -- Pantalón de gala negro/azul
                { component_id = 6,  drawable = 51,  texture = 0 }, -- Zapatos de gala charol
                { component_id = 7,  drawable = 126, texture = 0 }, -- Placa de oro de Comisario
                { component_id = 8,  drawable = 58,  texture = 0 },
                { component_id = 9,  drawable = 12,  texture = 2 }, -- Chaleco táctico ejecutivo
                { component_id = 10, drawable = 6,   texture = 0 }, -- 4 estrellas doradas de Comisario
                { component_id = 11, drawable = 317, texture = 2 }  -- Uniforme Class A de máxima graduación
            },
            props = {
                { prop_id = 0, drawable = 58, texture = 2 }, -- Gorra ejecutiva con escudo dorado
                { prop_id = 1, drawable = -1, texture = 0 }
            }
        },
        ['Female'] = {
            components = {
                { component_id = 1,  drawable = 0,   texture = 0 },
                { component_id = 3,  drawable = 31,  texture = 0 },
                { component_id = 4,  drawable = 133, texture = 0 },
                { component_id = 6,  drawable = 52,  texture = 0 },
                { component_id = 7,  drawable = 96,  texture = 0 },
                { component_id = 8,  drawable = 35,  texture = 0 },
                { component_id = 9,  drawable = 34,  texture = 2 },
                { component_id = 10, drawable = 6,   texture = 0 },
                { component_id = 11, drawable = 327, texture = 2 }
            },
            props = {
                { prop_id = 0, drawable = 57, texture = 2 },
                { prop_id = 1, drawable = -1, texture = 0 }
            }
        }
    }
}
