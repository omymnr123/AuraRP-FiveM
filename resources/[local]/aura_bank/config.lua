Config = {}

Config.BankTellers = {
    -- PACIFIC STANDARD (Mantenido)
    { coords = vec3(242.06, 226.79, 106.29), heading = 160.0, model = `ig_bankman` },

    -- FLEECA BANKS Y BLAINE COUNTY SAVINGS (Actualizados con coordenadas exactas)
    { coords = vec3(149.43, -1042.16, 29.37), heading = 338.85, model = `ig_bankman` }, -- Fleeca Bank (Legion Square)
    { coords = vec3(-1212.00, -332.02, 37.78), heading = 25.14, model = `ig_bankman` }, -- Fleeca Bank (Boulevard Del Perro)
    { coords = vec3(-351.4, -49.6, 49.03), heading = 340.0, model = `ig_bankman` }, -- Fleeca Bank (Hawick Ave - Mantenido)
    { coords = vec3(313.74, -280.47, 54.16), heading = 338.05, model = `ig_bankman` }, -- Fleeca Bank (Alta St)
    { coords = vec3(-2960.81, 482.91, 15.70), heading = 88.76, model = `ig_bankman` }, -- Fleeca Bank (Chumash)
    { coords = vec3(1175.02, 2708.45, 38.09), heading = 180.38, model = `ig_bankman` }, -- Fleeca Bank (Route 68)
    { coords = vec3(-111.92, 6471.32, 31.63), heading = 133.67, model = `ig_bankman` }, -- Blaine County Savings (Paleto Bay)
}

Config.ATMModels = {
    `prop_atm_01`,
    `prop_atm_02`,
    `prop_atm_03`,
    `prop_fleeca_atm`
}

Config.CardCost = 500 -- Coste de solicitar una tarjeta nueva
