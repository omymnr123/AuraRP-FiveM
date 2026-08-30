Config = {}

Config.Debug = false

-- ============================================================================
-- BALANCES INICIALES DE PERSONAJE (REGLA ESTRICTA DE LA FASE 4)
-- ============================================================================
Config.StartingBalances = {
    cash = 0,             -- $0 en efectivo
    bank = 5000,          -- $5,000 en cuenta bancaria
    savings = 0,          -- $0 en cuenta de ahorros
    black_money = 0       -- $0 en dinero negro
}

-- ============================================================================
-- CUENTAS MONETARIAS VÁLIDAS
-- ============================================================================
Config.ValidAccounts = {
    cash = true,
    bank = true,
    savings = true,
    black_money = true
}

-- ============================================================================
-- ARQUITECTURA DE SUMIDEROS Y POLÍTICA FISCAL (ANTI-HIPERINFLACIÓN)
-- ============================================================================
Config.Taxes = {
    -- Impuesto sobre transferencias interbancarias (2% por defecto)
    TransferFeeRate = 0.02,
    MinTransferFee = 10,
    MaxTransferFee = 5000,

    -- Tasa de retención por lavado de dinero negro (20% por defecto)
    LaunderingFeeRate = 0.20,

    -- Recargo por compras con tarjeta de débito en comercios (1%)
    PointOfSaleTax = 0.01
}

-- Intervalo de sincronización periódica de RAM a MySQL (en ms)
Config.SyncInterval = 30000 -- 30 segundos

-- ============================================================================
-- MOTOR DE MERCADO DINÁMICO (OFERTA Y DEMANDA)
-- ============================================================================
Config.Market = {
    -- Intervalo de equilibrio (Mean Reversion Decay) en ms (10 min)
    DecayInterval = 600000,
    
    -- Tasa de retorno hacia el stock objetivo por ciclo de decay (5%)
    DecayRate = 0.05,

    -- Margen del comprador (Spread de compra vs venta: 15% de markup)
    BuyMarkup = 1.15,

    -- Catálogo base de materias primas y bienes comercializables
    Items = {
        ['gold_ore'] = {
            label = 'Mineral de Oro',
            basePrice = 150,
            minPrice = 50,
            maxPrice = 350,
            targetStock = 500,
            elasticity = 0.08
        },
        ['iron_ore'] = {
            label = 'Mineral de Hierro',
            basePrice = 50,
            minPrice = 15,
            maxPrice = 120,
            targetStock = 2000,
            elasticity = 0.05
        },
        ['copper_ore'] = {
            label = 'Mineral de Cobre',
            basePrice = 35,
            minPrice = 10,
            maxPrice = 90,
            targetStock = 3000,
            elasticity = 0.05
        },
        ['wood_log'] = {
            label = 'Tronco de Roble',
            basePrice = 25,
            minPrice = 8,
            maxPrice = 70,
            targetStock = 4000,
            elasticity = 0.04
        },
        ['raw_meat'] = {
            label = 'Carne de Caza Cruda',
            basePrice = 70,
            minPrice = 20,
            maxPrice = 160,
            targetStock = 800,
            elasticity = 0.07
        },
        ['packaged_fish'] = {
            label = 'Pescado Fresco',
            basePrice = 45,
            minPrice = 12,
            maxPrice = 110,
            targetStock = 1500,
            elasticity = 0.06
        }
    }
}
