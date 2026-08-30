Config = {}

Config.Debug = false

-- Monedas soportadas y su mapeo hacia las cuentas de aura_economy
Config.CurrencyMap = {
    ['money'] = 'cash',
    ['cash'] = 'cash',
    ['black_money'] = 'black_money'
}

-- Mapeo de tiendas que sincronizan automáticamente con el Mercado Dinámico
Config.DynamicShops = {
    ['General'] = true,
    ['MiningShop'] = true,
    ['LumberShop'] = true,
    ['HuntingShop'] = true,
    ['FishMarket'] = true
}
