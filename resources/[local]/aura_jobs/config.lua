_G.Config = {}

Config.Debug = false

-- ============================================================================
-- CONFIGURACIÓN DE NÓMINAS Y POLÍTICA FISCAL DEL ESTADO
-- ============================================================================
-- Intervalo de pago automático en milisegundos (30 minutos)
Config.PaycheckInterval = 30 * 60 * 1000

-- Tasa de impuesto del estado aplicada a cada nómina (5% = 0.05)
-- Este importe se destruye (money sink) para combatir la inflación
Config.PaycheckTaxRate = 0.05

-- ============================================================================
-- CONFIGURACIÓN DE CAJAS REGISTRADORAS UNIVERSALES
-- ============================================================================
-- Nombre del ítem de dinero en ox_inventory
Config.CashItem = 'money'

-- Modelos de props identificados como cajas registradoras en el mapa (MLOs y Vanilla)
Config.RegisterProps = {
    'prop_till_01',
    'prop_till_02',
    'prop_till_03',
    'prop_till_01_dam',
    'prop_till_02_dam',
    'prop_cassa_01',
    'prop_cash_register_01',
    'prop_cash_register_02',
    'hei_prop_hei_cash_reg_01',
    'p_till_01_s',
    'v_res_tre_screen'
}

-- Configuración del inventario físico (stash) de cada caja registradora
Config.RegisterStash = {
    slots = 20,
    maxWeight = 50000, -- 50kg de capacidad
    label = 'Caja Registradora'
}

-- Tiempo de expiración de un cobro pendiente en segundos (10 minutos)
Config.BillExpirationSeconds = 600

-- ============================================================================
-- CATÁLOGO CENTRALIZADO DE TRABAJOS, RANGOS Y SALARIOS
-- ============================================================================
Config.Jobs = {
    ['unemployed'] = {
        label = 'Desempleado',
        isBusiness = false,
        canDuty = false,
        grades = {
            [0] = { name = 'Sin Empleo', salary = 100 }
        }
    },

    ['police'] = {
        label = 'LSPD',
        isBusiness = false,
        canDuty = true,
        grades = {
            [0] = { name = 'Cadete', salary = 850 },
            [1] = { name = 'Oficial I', salary = 1100 },
            [2] = { name = 'Oficial II', salary = 1350 },
            [3] = { name = 'Sargento', salary = 1700 },
            [4] = { name = 'Teniente', salary = 2100 },
            [5] = { name = 'Capitán', salary = 2600 },
            [6] = { name = 'Jefe de Policía', salary = 3200, isBoss = true }
        }
    },

    ['ambulance'] = {
        label = 'EMS & Médicos',
        isBusiness = false,
        canDuty = true,
        grades = {
            [0] = { name = 'Enfermero en Prácticas', salary = 800 },
            [1] = { name = 'Paramédico', salary = 1150 },
            [2] = { name = 'Médico Titular', salary = 1500 },
            [3] = { name = 'Cirujano Especialista', salary = 1950 },
            [4] = { name = 'Director Médico', salary = 2800, isBoss = true }
        }
    },

    ['mechanic'] = {
        label = 'Los Santos Customs',
        isBusiness = true,
        canDuty = true,
        grades = {
            [0] = { name = 'Aprendiz', salary = 600 },
            [1] = { name = 'Mecánico', salary = 950 },
            [2] = { name = 'Técnico Especialista', salary = 1300 },
            [3] = { name = 'Encargado de Taller', salary = 1750 },
            [4] = { name = 'Dueño del Taller', salary = 2400, isBoss = true }
        }
    },

    ['burgershot'] = {
        label = 'Burgershot',
        isBusiness = true,
        canDuty = true,
        grades = {
            [0] = { name = 'Limpiador', salary = 450 },
            [1] = { name = 'Cajero', salary = 700 },
            [2] = { name = 'Cocinero', salary = 900 },
            [3] = { name = 'Supervisor', salary = 1200 },
            [4] = { name = 'Gerente', salary = 1800, isBoss = true }
        }
    },

    ['bahama'] = {
        label = 'Bahama Mamas',
        isBusiness = true,
        canDuty = true,
        grades = {
            [0] = { name = 'Seguridad', salary = 550 },
            [1] = { name = 'Camarero', salary = 750 },
            [2] = { name = 'Bartender VIP', salary = 1000 },
            [3] = { name = 'Relaciones Públicas', salary = 1350 },
            [4] = { name = 'Director de Sala', salary = 2000, isBoss = true }
        }
    },

    ['vanilla'] = {
        label = 'Vanilla Unicorn',
        isBusiness = true,
        canDuty = true,
        grades = {
            [0] = { name = 'Portero', salary = 550 },
            [1] = { name = 'Barman', salary = 750 },
            [2] = { name = 'Bailarín / Bailarina', salary = 1100 },
            [3] = { name = 'Encargado de Club', salary = 1500 },
            [4] = { name = 'Propietario', salary = 2200, isBoss = true }
        }
    },

    ['yellowjack'] = {
        label = 'Yellow Jack Inn',
        isBusiness = true,
        canDuty = true,
        grades = {
            [0] = { name = 'Ayudante', salary = 450 },
            [1] = { name = 'Tabernero', salary = 750 },
            [2] = { name = 'Encargado', salary = 1100 },
            [3] = { name = 'Dueño', salary = 1600, isBoss = true }
        }
    },

    ['salieri'] = {
        label = "Salieri Club",
        isBusiness = true,
        canDuty = true,
        grades = {
            [0] = { name = 'Lavaplatos', salary = 450 },
            [1] = { name = 'Camarero', salary = 700 },
            [2] = { name = 'Barman Coctelero', salary = 1000 },
            [3] = { name = 'Seguridad / Encargado', salary = 1400 },
            [4] = { name = 'Director / Dueño', salary = 2200, isBoss = true }
        }
    },

    ['morningwoodliquor'] = {
        label = "Rob's Liquor (Morningwood)",
        isBusiness = true,
        canDuty = true,
        grades = {
            [0] = { name = 'Reponedor', salary = 300 },
            [1] = { name = 'Dependiente', salary = 500 },
            [2] = { name = 'Encargado', salary = 800 },
            [3] = { name = 'Dueño', salary = 1200, isBoss = true }
        }
    },

    ['elrancholiquor'] = {
        label = "Rob's Liquor (El Rancho Blvd)",
        isBusiness = true,
        canDuty = true,
        grades = {
            [0] = { name = 'Reponedor', salary = 300 },
            [1] = { name = 'Dependiente', salary = 500 },
            [2] = { name = 'Encargado', salary = 800 },
            [3] = { name = 'Dueño', salary = 1200, isBoss = true }
        }
    },

    ['banhamliquor'] = {
        label = "Rob's Liquor (Banham Canyon)",
        isBusiness = true,
        canDuty = true,
        grades = {
            [0] = { name = 'Reponedor', salary = 300 },
            [1] = { name = 'Dependiente', salary = 500 },
            [2] = { name = 'Encargado', salary = 800 },
            [3] = { name = 'Dueño', salary = 1200, isBoss = true }
        }
    },

    ['aceliquor'] = {
        label = "Ace Liquor (Sandy Shores)",
        isBusiness = true,
        canDuty = true,
        grades = {
            [0] = { name = 'Reponedor', salary = 300 },
            [1] = { name = 'Dependiente', salary = 500 },
            [2] = { name = 'Encargado', salary = 800 },
            [3] = { name = 'Dueño', salary = 1200, isBoss = true }
        }
    },

    ['harmonyliquor'] = {
        label = "Rob's Liquor (Harmony Route 68)",
        isBusiness = true,
        canDuty = true,
        grades = {
            [0] = { name = 'Reponedor', salary = 300 },
            [1] = { name = 'Dependiente', salary = 500 },
            [2] = { name = 'Encargado', salary = 800 },
            [3] = { name = 'Dueño', salary = 1200, isBoss = true }
        }
    },

    ['taxi'] = {
        label = 'Downtown Cab Co.',
        isBusiness = true,
        canDuty = true,
        grades = {
            [0] = { name = 'Conductor Novato', salary = 500 },
            [1] = { name = 'Taxista Profesional', salary = 800 },
            [2] = { name = 'Conductor Ejecutivo', salary = 1100 },
            [3] = { name = 'Jefe de Flota', salary = 1600, isBoss = true }
        }
    },

    ['cardealer'] = {
        label = 'Concesionario PDM',
        isBusiness = true,
        canDuty = true,
        grades = {
            [0] = { name = 'Recepcionista', salary = 500 },
            [1] = { name = 'Comercial Junior', salary = 850 },
            [2] = { name = 'Comercial Senior', salary = 1300 },
            [3] = { name = 'Jefe de Ventas', salary = 1800 },
            [4] = { name = 'Director General', salary = 2600, isBoss = true }
        }
    },

    ['tequilala'] = {
        label = 'Tequi-la-la Bar & Club',
        isBusiness = true,
        canDuty = true,
        grades = {
            [0] = { name = 'Seguridad', salary = 500 },
            [1] = { name = 'Camarero / Barman', salary = 800 },
            [2] = { name = 'Jefe de Barra', salary = 1100 },
            [3] = { name = 'Encargado de Local', salary = 1550 },
            [4] = { name = 'Dueño / Propietario', salary = 2200, isBoss = true }
        }
    },

    ['vazou'] = {
        label = 'Discoteca Marc Vazou',
        isBusiness = true,
        canDuty = true,
        grades = {
            [0] = { name = 'Seguridad', salary = 500 },
            [1] = { name = 'Camarero / Barman', salary = 800 },
            [2] = { name = 'Jefe de Barra / DJ', salary = 1100 },
            [3] = { name = 'Encargado de Sala', salary = 1550 },
            [4] = { name = 'Dueño / Propietario', salary = 2200, isBoss = true }
        }
    },

    ['paletoliquor'] = {
        label = 'Paleto Bay Liquor Store',
        isBusiness = true,
        canDuty = true,
        grades = {
            [0] = { name = 'Dependiente Junior', salary = 500 },
            [1] = { name = 'Dependiente', salary = 800 },
            [2] = { name = 'Encargado de Tienda', salary = 1200 },
            [3] = { name = 'Dueño / Propietario', salary = 2000, isBoss = true }
        }
    },

    ['henhouse'] = {
        label = 'The Hen House Bar',
        isBusiness = true,
        canDuty = true,
        grades = {
            [0] = { name = 'Seguridad', salary = 500 },
            [1] = { name = 'Camarero / Barman', salary = 800 },
            [2] = { name = 'Jefe de Barra', salary = 1100 },
            [3] = { name = 'Encargado de Local', salary = 1550 },
            [4] = { name = 'Dueño / Propietario', salary = 2200, isBoss = true }
        }
    }
}

-- ============================================================================
-- VENDEDORES NPC AUTÓNOMOS (FALLBACK CUANDO EL NEGOCIO ESTÁ CERRADO)
-- ============================================================================
Config.BusinessVendors = {
    ['tequilala'] = {
        job = 'tequilala',
        label = 'Tequi-la-la Bar',
        pedModel = 'u_m_y_party_01',
        coords = vec3(-561.74, 280.53, 82.18),
        heading = 353.43,
        scenario = 'WORLD_HUMAN_STAND_IMPARTIAL',
        society = 'tequilala',
        blip = {
            enabled = true,
            coords = vec3(-561.74, 280.53, 82.18),
            sprite = 93,      -- Copa de cóctel / Hostelería
            scale = 0.8,
            openColor = 48,   -- Morado / Neón
            closedColor = 39, -- Gris cuando está cerrado
            name = 'Tequi-la-la Bar'
        },
        items = {
            { name = 'tequila_shot', label = 'Chupito de Tequila', price = 15, category = 'alcohol', icon = 'wine-glass' },
            { name = 'beer',         label = 'Cerveza Pißwasser',  price = 10, category = 'alcohol', icon = 'beer-mug-empty' },
            { name = 'whiskey',      label = 'Whisky Richards',    price = 20, category = 'alcohol', icon = 'whiskey-glass' },
            { name = 'cocktail',     label = 'Cóctel Tropical',    price = 18, category = 'alcohol', icon = 'martini-glass-citrus' },
            { name = 'water',        label = 'Botella de Agua',    price = 5,  category = 'drink',   icon = 'bottle-water' },
            { name = 'chips',        label = 'Patatas Fritas',     price = 8,  category = 'food',    icon = 'bowl-food' }
        }
    },

    ['burgershot'] = {
        job = 'burgershot',
        label = 'Burgershot Vespucci',
        pedModel = 's_m_y_waiter_01',
        coords = vec3(-1220.57, -907.40, 12.33),
        heading = 34.55,
        scenario = 'WORLD_HUMAN_STAND_IMPARTIAL',
        society = 'burgershot',
        blip = {
            enabled = true,
            coords = vec3(-1220.57, -907.40, 12.33),
            sprite = 93,      -- Copa / Hostelería
            scale = 0.8,
            openColor = 5,    -- Amarillo Burgershot
            closedColor = 39, -- Gris cuando está cerrado
            name = 'Burgershot Vespucci'
        },
        items = {
            { name = 'burger', label = 'Hamburguesa Clásica', price = 12, category = 'food',  icon = 'burger' },
            { name = 'chips',  label = 'Patatas Fritas',      price = 6,  category = 'food',  icon = 'bowl-food' },
            { name = 'cola',   label = 'Lata de eCola',       price = 5,  category = 'drink', icon = 'mug-hot' },
            { name = 'sprunk', label = 'Lata de Sprunk',      price = 5,  category = 'drink', icon = 'bottle-droplet' },
            { name = 'water',  label = 'Botella de Agua',     price = 4,  category = 'drink', icon = 'bottle-water' }
        }
    },

    ['bahama'] = {
        job = 'bahama',
        label = 'Bahama Mamas Club',
        pedModel = 's_m_y_barman_01',
        coords = vec4(-1392.54, -606.32, 30.32, 35.0),
        scenario = 'WORLD_HUMAN_STAND_IMPARTIAL',
        society = 'bahama',
        blip = {
            enabled = true,
            coords = vec3(-1392.54, -606.32, 30.32),
            sprite = 93,      -- Copa de cóctel / Hostelería
            scale = 0.8,
            openColor = 27,   -- Violeta / Neón
            closedColor = 39, -- Gris cuando está cerrado
            name = 'Bahama Mamas Club'
        },
        items = {
            { name = 'cocktail', label = 'Cóctel Bahama Especial', price = 22, category = 'alcohol', icon = 'martini-glass-citrus' },
            { name = 'whiskey',  label = 'Whisky Richards',        price = 20, category = 'alcohol', icon = 'whiskey-glass' },
            { name = 'beer',     label = 'Cerveza Pißwasser',      price = 12, category = 'alcohol', icon = 'beer-mug-empty' },
            { name = 'sprunk',   label = 'Lata de Sprunk',         price = 6,  category = 'drink',   icon = 'bottle-droplet' },
            { name = 'water',    label = 'Botella de Agua',        price = 5,  category = 'drink',   icon = 'bottle-water' }
        }
    },

    ['vanilla'] = {
        job = 'vanilla',
        label = 'Vanilla Unicorn',
        pedModel = 's_m_y_barman_01',
        coords = vec3(125.23, -1281.55, 29.28),
        heading = 205.88,
        scenario = 'WORLD_HUMAN_STAND_IMPARTIAL',
        society = 'vanilla',
        blip = {
            enabled = true,
            coords = vec3(125.23, -1281.55, 29.28),
            sprite = 93,      -- Copa de cóctel / Hostelería
            scale = 0.8,
            openColor = 8,    -- Rosa Neón
            closedColor = 39, -- Gris cuando está cerrado
            name = 'Vanilla Unicorn'
        },
        items = {
            { name = 'cocktail',     label = 'Cóctel Unicorn',     price = 20, category = 'alcohol', icon = 'martini-glass-citrus' },
            { name = 'tequila_shot', label = 'Chupito de Tequila', price = 15, category = 'alcohol', icon = 'wine-glass' },
            { name = 'whiskey',      label = 'Whisky Richards',    price = 20, category = 'alcohol', icon = 'whiskey-glass' },
            { name = 'beer',         label = 'Cerveza Pißwasser',  price = 10, category = 'alcohol', icon = 'beer-mug-empty' },
            { name = 'water',        label = 'Botella de Agua',    price = 5,  category = 'drink',   icon = 'bottle-water' }
        }
    },

    ['yellowjack'] = {
        job = 'yellowjack',
        label = 'Yellow Jack Inn',
        pedModel = 'ig_claypain',
        coords = vec3(1986.04, 3048.36, 47.22),
        heading = 357.93,
        scenario = 'WORLD_HUMAN_STAND_IMPARTIAL',
        society = 'yellowjack',
        blip = {
            enabled = true,
            coords = vec3(1986.04, 3048.36, 47.22),
            sprite = 93,      -- Copa de cóctel / Hostelería
            scale = 0.8,
            openColor = 5,    -- Amarillo
            closedColor = 39, -- Gris cuando está cerrado
            name = 'Yellow Jack Inn'
        },
        items = {
            { name = 'beer',     label = 'Cerveza Pißwasser', price = 8,  category = 'alcohol', icon = 'beer-mug-empty' },
            { name = 'whiskey',  label = 'Whisky de Taberna', price = 15, category = 'alcohol', icon = 'whiskey-glass' },
            { name = 'sandwich', label = 'Sándwich Rústico',  price = 10, category = 'food',    icon = 'utensils' },
            { name = 'water',    label = 'Botella de Agua',   price = 4,  category = 'drink',   icon = 'bottle-water' }
        }
    },


    ['vazou'] = {
        job = 'vazou',
        label = 'Discoteca Marc Vazou',
        pedModel = 's_m_y_barman_01',
        coords = vec3(-1566.23, -968.23, 13.02),
        heading = 48.02,
        scenario = 'WORLD_HUMAN_STAND_IMPARTIAL',
        society = 'vazou',
        maxWeight = 300000,
        slots = 50,
        blip = {
            enabled = true,
            coords = vec3(-1566.23, -968.23, 13.02),
            sprite = 93,      -- Copa de cóctel / Hostelería
            scale = 0.8,
            openColor = 27,   -- Morado / Eléctrico
            closedColor = 39, -- Gris cuando está cerrado
            name = 'Discoteca Marc Vazou'
        },
        items = {
            { name = 'cocktail',     label = 'Cóctel Vazou Especial', price = 22, category = 'alcohol', icon = 'martini-glass-citrus' },
            { name = 'whiskey',      label = 'Whisky Richards',       price = 20, category = 'alcohol', icon = 'whiskey-glass' },
            { name = 'tequila_shot', label = 'Chupito de Tequila',    price = 15, category = 'alcohol', icon = 'wine-glass' },
            { name = 'beer',         label = 'Cerveza Pißwasser',     price = 12, category = 'alcohol', icon = 'beer-mug-empty' },
            { name = 'water',        label = 'Botella de Agua',       price = 5,  category = 'drink',   icon = 'bottle-water' },
            { name = 'chips',        label = 'Snacks & Patatas',      price = 8,  category = 'food',    icon = 'bowl-food' }
        }
    },

    ['paletoliquor'] = {
        job = 'paletoliquor',
        label = 'Paleto Bay Liquor Store',
        pedModel = 'mp_m_shopkeep_01',
        coords = vec3(-160.07, 6319.79, 31.60),
        heading = 318.44,
        scenario = 'WORLD_HUMAN_STAND_IMPARTIAL',
        society = 'paletoliquor',
        maxWeight = 300000,
        slots = 50,
        blip = {
            enabled = true,
            coords = vec3(-160.07, 6319.79, 31.60),
            sprite = 52,      -- Icono de Supermercado / Tienda 24/7
            scale = 0.8,
            openColor = 2,    -- Verde cuando está abierto
            closedColor = 39, -- Gris cuando está cerrado
            name = 'Paleto Bay Liquor'
        },
        items = {
            { name = 'whiskey',      label = 'Whisky Richards',    price = 20, category = 'alcohol', icon = 'whiskey-glass' },
            { name = 'beer',         label = 'Cerveza Pißwasser',  price = 10, category = 'alcohol', icon = 'beer-mug-empty' },
            { name = 'tequila_shot', label = 'Chupito de Tequila', price = 15, category = 'alcohol', icon = 'wine-glass' },
            { name = 'cocktail',     label = 'Cóctel Tropical',    price = 18, category = 'alcohol', icon = 'martini-glass-citrus' },
            { name = 'cola',         label = 'Lata de eCola',      price = 5,  category = 'drink',   icon = 'mug-hot' },
            { name = 'water',        label = 'Botella de Agua',    price = 5,  category = 'drink',   icon = 'bottle-water' },
            { name = 'chips',        label = 'Patatas Fritas',     price = 8,  category = 'food',    icon = 'bowl-food' }
        }
    },

    ['henhouse'] = {
        job = 'henhouse',
        label = 'The Hen House Bar',
        pedModel = 's_m_y_barman_01',
        coords = vec3(-297.59, 6271.26, 31.51),
        heading = 134.63,
        scenario = 'WORLD_HUMAN_STAND_IMPARTIAL',
        society = 'henhouse',
        maxWeight = 300000,
        slots = 50,
        blip = {
            enabled = true,
            coords = vec3(-297.59, 6271.26, 31.51),
            sprite = 93,      -- Copa de cóctel / Hostelería
            scale = 0.8,
            openColor = 5,    -- Amarillo Hen House
            closedColor = 39, -- Gris cuando está cerrado
            name = 'The Hen House Bar'
        },
        items = {
            { name = 'beer',         label = 'Cerveza Pißwasser',  price = 10, category = 'alcohol', icon = 'beer-mug-empty' },
            { name = 'whiskey',      label = 'Whisky de Taberna',  price = 18, category = 'alcohol', icon = 'whiskey-glass' },
            { name = 'cocktail',     label = 'Cóctel Hen House',   price = 20, category = 'alcohol', icon = 'martini-glass-citrus' },
            { name = 'tequila_shot', label = 'Chupito de Tequila', price = 15, category = 'alcohol', icon = 'wine-glass' },
            { name = 'sandwich',     label = 'Sándwich Rústico',   price = 12, category = 'food',    icon = 'utensils' },
            { name = 'water',        label = 'Botella de Agua',    price = 4,  category = 'drink',   icon = 'bottle-water' },
            { name = 'chips',        label = 'Patatas Fritas',     price = 8,  category = 'food',    icon = 'bowl-food' }
        }
    },

    ['morningwoodliquor'] = {
        job = 'morningwoodliquor',
        label = "Rob's Liquor (Morningwood)",
        pedModel = 'mp_m_shopkeep_01',
        coords = vec3(-1487.55, -379.10, 40.16),
        heading = 0.0,
        scenario = 'WORLD_HUMAN_STAND_IMPARTIAL',
        society = 'morningwoodliquor',
        maxWeight = 300000,
        slots = 50,
        blip = {
            enabled = true,
            coords = vec3(-1487.55, -379.10, 40.16),
            sprite = 52,
            scale = 0.8,
            openColor = 2,
            closedColor = 39,
            name = "Rob's Liquor"
        },
        items = {
            { name = 'whiskey',      label = 'Whisky Richards',    price = 20, category = 'alcohol', icon = 'whiskey-glass' },
            { name = 'beer',         label = 'Cerveza Pißwasser',  price = 10, category = 'alcohol', icon = 'beer-mug-empty' },
            { name = 'tequila_shot', label = 'Chupito de Tequila', price = 15, category = 'alcohol', icon = 'wine-glass' },
            { name = 'cola',         label = 'Lata de eCola',      price = 5,  category = 'drink',   icon = 'mug-hot' },
            { name = 'water',        label = 'Botella de Agua',    price = 5,  category = 'drink',   icon = 'bottle-water' },
            { name = 'chips',        label = 'Patatas Fritas',     price = 8,  category = 'food',    icon = 'bowl-food' }
        }
    },

    ['elrancholiquor'] = {
        job = 'elrancholiquor',
        label = "Rob's Liquor (El Rancho Blvd)",
        pedModel = 'mp_m_shopkeep_01',
        coords = vec3(1135.81, -982.28, 46.41),
        heading = 0.0,
        scenario = 'WORLD_HUMAN_STAND_IMPARTIAL',
        society = 'elrancholiquor',
        maxWeight = 300000,
        slots = 50,
        blip = {
            enabled = true,
            coords = vec3(1135.81, -982.28, 46.41),
            sprite = 52,
            scale = 0.8,
            openColor = 2,
            closedColor = 39,
            name = "Rob's Liquor"
        },
        items = {
            { name = 'whiskey',      label = 'Whisky Richards',    price = 20, category = 'alcohol', icon = 'whiskey-glass' },
            { name = 'beer',         label = 'Cerveza Pißwasser',  price = 10, category = 'alcohol', icon = 'beer-mug-empty' },
            { name = 'tequila_shot', label = 'Chupito de Tequila', price = 15, category = 'alcohol', icon = 'wine-glass' },
            { name = 'cola',         label = 'Lata de eCola',      price = 5,  category = 'drink',   icon = 'mug-hot' },
            { name = 'water',        label = 'Botella de Agua',    price = 5,  category = 'drink',   icon = 'bottle-water' },
            { name = 'chips',        label = 'Patatas Fritas',     price = 8,  category = 'food',    icon = 'bowl-food' }
        }
    },

    ['banhamliquor'] = {
        job = 'banhamliquor',
        label = "Rob's Liquor (Banham Canyon)",
        pedModel = 'mp_m_shopkeep_01',
        coords = vec3(-3040.67, 585.16, 7.91),
        heading = 0.0,
        scenario = 'WORLD_HUMAN_STAND_IMPARTIAL',
        society = 'banhamliquor',
        maxWeight = 300000,
        slots = 50,
        blip = {
            enabled = true,
            coords = vec3(-3040.67, 585.16, 7.91),
            sprite = 52,
            scale = 0.8,
            openColor = 2,
            closedColor = 39,
            name = "Rob's Liquor"
        },
        items = {
            { name = 'whiskey',      label = 'Whisky Richards',    price = 20, category = 'alcohol', icon = 'whiskey-glass' },
            { name = 'beer',         label = 'Cerveza Pißwasser',  price = 10, category = 'alcohol', icon = 'beer-mug-empty' },
            { name = 'tequila_shot', label = 'Chupito de Tequila', price = 15, category = 'alcohol', icon = 'wine-glass' },
            { name = 'cola',         label = 'Lata de eCola',      price = 5,  category = 'drink',   icon = 'mug-hot' },
            { name = 'water',        label = 'Botella de Agua',    price = 5,  category = 'drink',   icon = 'bottle-water' },
            { name = 'chips',        label = 'Patatas Fritas',     price = 8,  category = 'food',    icon = 'bowl-food' }
        }
    },

    ['aceliquor'] = {
        job = 'aceliquor',
        label = "Ace Liquor (Sandy Shores)",
        pedModel = 'mp_m_shopkeep_01',
        coords = vec3(1392.56, 3604.68, 34.98),
        heading = 0.0,
        scenario = 'WORLD_HUMAN_STAND_IMPARTIAL',
        society = 'aceliquor',
        maxWeight = 300000,
        slots = 50,
        blip = {
            enabled = true,
            coords = vec3(1392.56, 3604.68, 34.98),
            sprite = 52,
            scale = 0.8,
            openColor = 2,
            closedColor = 39,
            name = "Ace Liquor"
        },
        items = {
            { name = 'whiskey',      label = 'Whisky Richards',    price = 20, category = 'alcohol', icon = 'whiskey-glass' },
            { name = 'beer',         label = 'Cerveza Pißwasser',  price = 10, category = 'alcohol', icon = 'beer-mug-empty' },
            { name = 'tequila_shot', label = 'Chupito de Tequila', price = 15, category = 'alcohol', icon = 'wine-glass' },
            { name = 'cola',         label = 'Lata de eCola',      price = 5,  category = 'drink',   icon = 'mug-hot' },
            { name = 'water',        label = 'Botella de Agua',    price = 5,  category = 'drink',   icon = 'bottle-water' },
            { name = 'chips',        label = 'Patatas Fritas',     price = 8,  category = 'food',    icon = 'bowl-food' }
        }
    },

    ['harmonyliquor'] = {
        job = 'harmonyliquor',
        label = "Rob's Liquor (Harmony Route 68)",
        pedModel = 'mp_m_shopkeep_01',
        coords = vec3(1163.37, 2706.84, 38.16),
        heading = 0.0,
        scenario = 'WORLD_HUMAN_STAND_IMPARTIAL',
        society = 'harmonyliquor',
        maxWeight = 300000,
        slots = 50,
        blip = {
            enabled = true,
            coords = vec3(1163.37, 2706.84, 38.16),
            sprite = 52,
            scale = 0.8,
            openColor = 2,
            closedColor = 39,
            name = "Rob's Liquor"
        },
        items = {
            { name = 'whiskey',      label = 'Whisky Richards',    price = 20, category = 'alcohol', icon = 'whiskey-glass' },
            { name = 'beer',         label = 'Cerveza Pißwasser',  price = 10, category = 'alcohol', icon = 'beer-mug-empty' },
            { name = 'tequila_shot', label = 'Chupito de Tequila', price = 15, category = 'alcohol', icon = 'wine-glass' },
            { name = 'cola',         label = 'Lata de eCola',      price = 5,  category = 'drink',   icon = 'mug-hot' },
            { name = 'water',        label = 'Botella de Agua',    price = 5,  category = 'drink',   icon = 'bottle-water' },
            { name = 'chips',        label = 'Patatas Fritas',     price = 8,  category = 'food',    icon = 'bowl-food' }
        }
    },

    ['salieri'] = {
        job = 'salieri',
        label = 'Salieri Club',
        pedModel = 's_m_y_barman_01',
        coords = vec3(322.11, -1095.43, 29.39),
        heading = 88.48,
        scenario = 'WORLD_HUMAN_STAND_IMPARTIAL',
        society = 'salieri',
        maxWeight = 300000,
        slots = 50,
        blip = {
            enabled = true,
            coords = vec3(322.11, -1095.43, 29.39),
            sprite = 93,      -- Copa de cóctel / Hostelería
            scale = 0.8,
            openColor = 5,    -- Amarillo Hen House
            closedColor = 39, -- Gris cuando está cerrado
            name = 'Salieri Club'
        },
        items = {
            { name = 'beer',         label = 'Cerveza Pißwasser',  price = 10, category = 'alcohol', icon = 'beer-mug-empty' },
            { name = 'whiskey',      label = 'Whisky de Taberna',  price = 18, category = 'alcohol', icon = 'whiskey-glass' },
            { name = 'cocktail',     label = 'Cóctel Hen House',   price = 20, category = 'alcohol', icon = 'martini-glass-citrus' },
            { name = 'tequila_shot', label = 'Chupito de Tequila', price = 15, category = 'alcohol', icon = 'wine-glass' },
            { name = 'sandwich',     label = 'Sándwich Rústico',   price = 12, category = 'food',    icon = 'utensils' },
            { name = 'water',        label = 'Botella de Agua',    price = 4,  category = 'drink',   icon = 'bottle-water' },
            { name = 'chips',        label = 'Patatas Fritas',     price = 8,  category = 'food',    icon = 'bowl-food' }
        }
    },
}

-- ============================================================================
-- SISTEMA DE CERRADURAS DE PUERTAS (DOORLOCKS)
-- ============================================================================
Config.Doors = {
    -- Ejemplo: Puerta de Vazou (Ajustar coords y hash según el MLO)
    ['vazou_main'] = {
        job = 'vazou',                           -- Job que puede abrirla/cerrarla
        model = `v_ilev_ss_door04`,              -- Hash del modelo de la puerta
        coords = vec3(-1564.44, -974.61, 13.02), -- Coordenadas exactas de la puerta
        distance = 2.0,                          -- Distancia de interacción
        locked = true                            -- Estado por defecto
    },

    ['vazou_secundaria'] = {
        job = 'vazou',                           -- Job que puede abrirla/cerrarla
        model = `v_ilev_ss_door04`,              -- Hash del modelo de la puerta
        coords = vec3(-1558.66, -972.22, 13.02), -- Coordenadas exactas de la puerta
        distance = 2.0,                          -- Distancia de interacción
        locked = true                            -- Estado por defecto
    },

    ['salieri_main'] = {
        job = 'salieri',                        -- Job que puede abrirla/cerrarla
        model = `v_ilev_ss_door04`,             -- Hash del modelo de la puerta
        coords = vec3(322.11, -1095.43, 29.39), -- Coordenadas exactas de la puerta
        distance = 2.0,                         -- Distancia de interacción
        locked = true                           -- Estado por defecto
    },

    -- Ejemplo: Puerta de The Hen House
    ['henhouse_main'] = {
        job = 'henhouse',
        model = `v_ilev_ss_door04`,
        coords = vec3(-297.59, 6271.26, 31.51),
        distance = 2.0,
        locked = true
    }
}
