-- ============================================================================
-- AURA INVENTORY: CLIENT SUBSYSTEM & CLOTHING SHORTCUTS
-- ============================================================================

RegisterNetEvent('aura_inventory:client:notifyTransaction', function(title, description, type)
    if lib and lib.notify then
        lib.notify({
            title = title or 'Inventario',
            description = description,
            type = type or 'info',
            position = 'top-right'
        })
    end
end)

--- Comprueba si el jugador local dispone de una tablet en su inventario
--- @return boolean
exports('HasTablet', function()
    if not exports.ox_inventory then return false end
    return (exports.ox_inventory:Search('count', 'tablet') or 0) > 0
end)

--- Comprueba si el jugador local dispone de un ítem y cantidad específica
--- @param itemName string
--- @param count? number
--- @return boolean
exports('HasItem', function(itemName, count)
    if not exports.ox_inventory then return false end
    local required = count or 1
    return (exports.ox_inventory:Search('count', itemName) or 0) >= required
end)

-- ============================================================================
-- COMANDOS Y PUENTES DE ROPA / INDUMENTARIA
-- ============================================================================

local aliasMap = {
    ['gorro'] = 'hat', ['sombrero'] = 'hat', ['casco'] = 'hat', ['hat'] = 'hat',
    ['mascara'] = 'mask', ['careta'] = 'mask', ['mask'] = 'mask',
    ['gafas'] = 'glasses', ['lentes'] = 'glasses', ['glasses'] = 'glasses',
    ['pendiente'] = 'ear', ['pendientes'] = 'ear', ['oreja'] = 'ear', ['ear'] = 'ear',
    ['cadena'] = 'chain', ['collar'] = 'chain', ['cuello'] = 'chain', ['chain'] = 'chain',
    ['chaqueta'] = 'jacket', ['abrigo'] = 'jacket', ['torso'] = 'jacket', ['top'] = 'jacket', ['jacket'] = 'jacket',
    ['camiseta'] = 'tshirt', ['interior'] = 'tshirt', ['remera'] = 'tshirt', ['tshirt'] = 'tshirt', ['shirt'] = 'tshirt',
    ['chaleco'] = 'vest', ['blindaje'] = 'vest', ['vest'] = 'vest', ['armor'] = 'vest',
    ['guantes'] = 'gloves', ['manos'] = 'gloves', ['gloves'] = 'gloves',
    ['pantalones'] = 'pants', ['pantalon'] = 'pants', ['legs'] = 'pants', ['pants'] = 'pants',
    ['zapatos'] = 'shoes', ['calzado'] = 'shoes', ['zapas'] = 'shoes', ['shoes'] = 'shoes', ['feet'] = 'shoes',
    ['mochila'] = 'bag', ['bolsa'] = 'bag', ['bag'] = 'bag', ['backpack'] = 'bag',
    ['reloj'] = 'watch', ['watch'] = 'watch',
    ['pulsera'] = 'bracelet', ['brazalete'] = 'bracelet', ['bracelet'] = 'bracelet'
}

local function ExecuteClothingToggle(arg)
    if not arg or arg == '' then
        if lib and lib.notify then
            lib.notify({
                title = 'Indumentaria Aura',
                description = 'Uso: /ropa [gorro|mascara|gafas|chaqueta|camiseta|chaleco|guantes|pantalones|zapatos|mochila|reloj|pulsera|cadena|oreja]',
                type = 'inform',
                position = 'top-right'
            })
        end
        return
    end

    local cleanKey = string.lower(string.gsub(arg, '^%s*(.-)%s*$', '%1'))
    local resolvedType = aliasMap[cleanKey]

    if resolvedType and exports.ox_inventory and exports.ox_inventory.ToggleClothing then
        exports.ox_inventory:ToggleClothing(resolvedType)
    else
        if lib and lib.notify then
            lib.notify({
                title = 'Prenda no reconocida',
                description = ('La prenda "%s" no es válida. Consulta /ropa para ver la lista.'):format(cleanKey),
                type = 'error',
                position = 'top-right'
            })
        end
    end
end

RegisterCommand('ropa', function(_, args)
    ExecuteClothingToggle(args[1])
end, false)

RegisterCommand('quitar', function(_, args)
    ExecuteClothingToggle(args[1])
end, false)

RegisterCommand('poner', function(_, args)
    ExecuteClothingToggle(args[1])
end, false)

-- Añadir sugerencias al chat
CreateThread(function()
    TriggerEvent('chat:addSuggestion', '/ropa', 'Alternar prenda de vestir', {
        { name = 'prenda', help = 'gorro, mascara, gafas, chaqueta, camiseta, chaleco, guantes, pantalones, zapatos, mochila, reloj, pulsera, cadena, oreja' }
    })
    TriggerEvent('chat:addSuggestion', '/quitar', 'Quitar o poner una prenda de vestir', {
        { name = 'prenda', help = 'gorro, mascara, gafas, chaqueta, camiseta, chaleco, guantes, pantalones, zapatos, mochila, reloj, pulsera, cadena, oreja' }
    })
    TriggerEvent('chat:addSuggestion', '/poner', 'Poner o quitar una prenda de vestir', {
        { name = 'prenda', help = 'gorro, mascara, gafas, chaqueta, camiseta, chaleco, guantes, pantalones, zapatos, mochila, reloj, pulsera, cadena, oreja' }
    })
end)

-- Exports públicos hacia otros scripts
exports('ToggleClothing', function(pieceType)
    local resolved = aliasMap[pieceType] or pieceType
    if exports.ox_inventory and exports.ox_inventory.ToggleClothing then
        return exports.ox_inventory:ToggleClothing(resolved)
    end
    return false
end)

exports('GetClothingState', function()
    if exports.ox_inventory and exports.ox_inventory.GetClothingState then
        return exports.ox_inventory:GetClothingState()
    end
    return {}
end)


