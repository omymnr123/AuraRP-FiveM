Framework = {}

function Framework.ESX()
    return GetResourceState("es_extended") ~= "missing"
end

function Framework.QBCore()
    return GetResourceState("qb-core") ~= "missing"
end

function Framework.Ox()
    return GetResourceState("ox_core") ~= "missing"
end

function Framework.Aura()
    return GetResourceState("aura_core") ~= "missing" or (not Framework.ESX() and not Framework.QBCore() and not Framework.Ox())
end
