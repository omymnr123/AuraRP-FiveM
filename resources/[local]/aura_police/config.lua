Config = {}

Config.Debug = false

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
            coords = vec3(461.35, -999.07, 30.69)
        },
        garage = {
            spawn = vec4(438.42, -1018.30, 28.75, 90.0),
            interact = vec3(441.25, -1024.15, 28.65)
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
-- 3. DOTACIÓN DE ARMERÍA POR RANGO POLICIAL (0: Cadete ... 6: Jefe de Policía)
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
    [1] = { -- Oficial I
        { name = 'weapon_combatpistol', label = 'Pistola Glock 19 (9mm)', count = 1 },
        { name = 'ammo-9',              label = 'Munición 9mm (x50)',     count = 100 },
        { name = 'weapon_stungun',      label = 'Pistola Taser X26',      count = 1 },
        { name = 'weapon_nightstick',   label = 'Porra Reglamentaria',    count = 1 },
        { name = 'weapon_flashlight',   label = 'Linterna Táctica',       count = 1 },
        { name = 'handcuffs',           label = 'Esposas Reglamentarias', count = 1 },
        { name = 'radio',               label = 'Radio Walkie-Talkie',    count = 1 },
        { name = 'armour',              label = 'Chaleco Balístico',      count = 2 },
        { name = 'bandage',             label = 'Vendaje Médico',         count = 5 },
        { name = 'medikit',             label = 'Botiquín Táctico IFAK',  count = 1 },
        { name = 'police_badge',        label = 'Placa Policial LSPD',    count = 1 },
        { name = 'bodycam',             label = 'Cámara Corporal Axon',   count = 1 }
    },
    [2] = { -- Oficial II
        { name = 'weapon_combatpistol', label = 'Pistola Glock 19 (9mm)',   count = 1 },
        { name = 'ammo-9',              label = 'Munición 9mm (x50)',       count = 100 },
        { name = 'weapon_pumpshotgun',  label = 'Escopeta Mossberg 590',    count = 1 },
        { name = 'ammo-shotgun',        label = 'Cartuchos Escopeta (x20)', count = 100 },
        { name = 'weapon_stungun',      label = 'Pistola Taser X26',        count = 1 },
        { name = 'weapon_nightstick',   label = 'Porra Reglamentaria',      count = 1 },
        { name = 'weapon_flashlight',   label = 'Linterna Táctica',         count = 1 },
        { name = 'handcuffs',           label = 'Esposas Reglamentarias',   count = 1 },
        { name = 'radio',               label = 'Radio Walkie-Talkie',      count = 1 },
        { name = 'armour',              label = 'Chaleco Balístico',        count = 2 },
        { name = 'bandage',             label = 'Vendaje Médico',           count = 5 },
        { name = 'medikit',             label = 'Botiquín Táctico IFAK',    count = 2 },
        { name = 'spikestrip',          label = 'Banda de Clavos Portátil', count = 1 },
        { name = 'police_badge',        label = 'Placa Policial LSPD',      count = 1 },
        { name = 'bodycam',             label = 'Cámara Corporal Axon',     count = 1 }
    },
    [3] = { -- Sargento
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
    },
    [4] = { -- Teniente
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
    },
    [5] = { -- Capitán
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
    },
    [6] = { -- Jefe de Policía (Comisario Principal / Chief)
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
    { model = 'police',  label = 'Patrulla Cruiser Vapid (LSPD)', minGrade = 0 },
    { model = 'police2', label = 'Patrulla Buffalo Interceptor',  minGrade = 1 },
    { model = 'police3', label = 'Interceptor Vapid Cruiser',     minGrade = 1 },
    { model = 'police4', label = 'Vehículo Camuflado (Unmarked)', minGrade = 2 },
    { model = 'policet', label = 'Furgón de Transporte / Celdas', minGrade = 1 },
    { model = 'fbi2',    label = 'SUV Blindado Granger LSPD',     minGrade = 2 },
    { model = 'riot',    label = 'Furgón Blindado SWAT / Riot',   minGrade = 3 }
}

Config.Helicopters = {
    { model = 'polmav', label = 'Helicóptero Policial Air-1 (Con Helicam)', minGrade = 2 }
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
