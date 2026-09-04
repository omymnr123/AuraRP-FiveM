-- ============================================================================
-- AURA GANGS: SERVER CHOP SHOP CONTROLLER
-- Manual Bone-by-Bone Dismantling, StateBag Anti-Dupe & Economy Payouts
-- ============================================================================

--- Comprueba si una entidad se encuentra dentro de alguna bahía de desguace
--- @param coords vector3
--- @return boolean, table | nil
local function IsCoordsInChopBay(coords)
    if not Config.ChopShop or not Config.ChopShop.Locations then return false end
    for _, bay in ipairs(Config.ChopShop.Locations) do
        local dist = #(coords - bay.coords)
        if dist <= (bay.radius + 4.0) then
            return true, bay
        end
    end
    return false, nil
end

--- Comprueba si el jugador pertenece a una organización o banda
--- @param src number
--- @return boolean
local function IsPlayerInGang(src)
    local pState = Player(src).state
    if not pState then return false end
    if pState.isGang == true then return true end
    local pJob = pState.job
    if pJob and Config.Gangs and Config.Gangs[pJob] then
        return true
    end
    return false
end

-- ============================================================================
-- 1. CALLBACK PARA DESMONTAR PIEZA INDIVIDUAL (HOOD, DOORS, WHEELS, ENGINE, EXHAUST)
-- ============================================================================

lib.callback.register('aura_gangs:server:dismantlePart', function(source, netId, partKey, clientVehClass)
    local src = source
    if not src or not netId or not partKey then
        return false, "Petición de despiece inválida."
    end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or not DoesEntityExist(entity) then
        return false, "El vehículo ya no existe o fue retirado."
    end

    local ped = GetPlayerPed(src)
    local pCoords = GetEntityCoords(ped)
    local vCoords = GetEntityCoords(entity)

    -- Validación perimétrica de seguridad (Anticheat)
    if #(pCoords - vCoords) > 15.0 then
        return false, "Estás demasiado lejos del vehículo para despiezarlo."
    end

    -- Validación de zona de desguace físico
    if not IsCoordsInChopBay(vCoords) then
        return false, "El vehículo debe estar posicionado dentro de la bahía de desguace."
    end

    -- Validación de banda / mafia autorizada
    if not IsPlayerInGang(src) then
        return false, "No dispones de la autorización ni los conocimientos criminales para operar aquí."
    end

    -- Validación de configuración de la pieza
    local partConfig = Config.ChopShop.Parts[partKey]
    if not partConfig then
        return false, "La pieza seleccionada no es válida para este chasis."
    end

    -- Validación atómica con StateBag: evitar reclamaciones duplicadas
    local stateKey = 'dismantled_' .. partKey
    local entState = Entity(entity).state
    if entState[stateKey] then
        return false, "Esta pieza ya ha sido desmontada de este vehículo."
    end

    -- Validación de capacidad en inventario (ox_inventory)
    local itemAmount = partConfig.amount or 1
    local canCarry = exports.ox_inventory:CanCarryItem(src, partConfig.item, itemAmount)
    if not canCarry then
        return false, "No tienes suficiente espacio o capacidad de peso en tu inventario para llevar esta pieza."
    end

    -- Replicar estado a través de StateBags sincronizados con la red
    entState:set(stateKey, true, true)

    -- Sincronizar destrucción visual para todos los clientes cercanos
    TriggerClientEvent('aura_gangs:client:syncPartBreak', -1, netId, partKey)

    -- Calcular pago en dinero negro con posibles bonificaciones por categoría
    local minCash = partConfig.cashReward.min or 200
    local maxCash = partConfig.cashReward.max or 500
    local cashReward = math.random(minCash, maxCash)

    local vehClass = tonumber(clientVehClass)
    -- Deportivos (7), Superdeportivos (6), SUVs (2)
    if vehClass and (vehClass == 7 or vehClass == 6 or vehClass == 2) then
        cashReward = math.floor(cashReward * 1.35)
    end

    -- Entrega del ítem y dinero negro en ox_inventory
    local addedItem = exports.ox_inventory:AddItem(src, partConfig.item, itemAmount)
    local addedCash = exports.ox_inventory:AddItem(src, 'black_money', cashReward)

    if not addedItem or not addedCash then
        local dropTable = {}
        if not addedItem then
            table.insert(dropTable, { partConfig.item, itemAmount })
        end
        if not addedCash then
            table.insert(dropTable, { 'black_money', cashReward })
        end
        exports.ox_inventory:CustomDrop('Pieza de Desguace', dropTable, pCoords)
        return true, string.format("Has extraído: %s.\nTu inventario estaba sobrecargado; la pieza ha quedado en una caja en el suelo.", partConfig.label)
    end

    return true, string.format("Has extraído: %s.\nObtenido: +%d %s y +$%s en Dinero Negro.", partConfig.label, itemAmount, partConfig.label, lib.math.groupdigits(cashReward))
end)

-- ============================================================================
-- 2. CALLBACK PARA DESGUAZAR Y COMPACTAR EL CHASIS FINAL
-- ============================================================================

lib.callback.register('aura_gangs:server:scrapChassis', function(source, netId, clientVehClass)
    local src = source
    if not src or not netId then
        return false, "Petición inválida."
    end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or not DoesEntityExist(entity) then
        return false, "El bastidor ya no existe."
    end

    local ped = GetPlayerPed(src)
    local pCoords = GetEntityCoords(ped)
    local vCoords = GetEntityCoords(entity)

    if #(pCoords - vCoords) > 15.0 then
        return false, "Estás demasiado lejos del bastidor."
    end

    if not IsCoordsInChopBay(vCoords) then
        return false, "El vehículo no se encuentra en el área de corte."
    end

    if not IsPlayerInGang(src) then
        return false, "Acceso denegado: solo organizaciones clandestinas."
    end

    local entState = Entity(entity).state
    if entState.dismantled_chassis then
        return false, "Este chasis ya ha sido procesado."
    end

    -- Comprobar que al menos se han extraído las piezas principales
    local dismantledCount = 0
    for key, _ in pairs(Config.ChopShop.Parts) do
        if key ~= 'chassis' and entState['dismantled_' .. key] then
            dismantledCount = dismantledCount + 1
        end
    end

    if dismantledCount < 2 then
        return false, "El vehículo aún contiene piezas valiosas que debes retirar antes de compactar el bastidor."
    end

    local chassisConfig = Config.ChopShop.Parts['chassis']
    local minParts = chassisConfig.amountMin or 3
    local maxParts = chassisConfig.amountMax or 6
    local scrapCount = math.random(minParts, maxParts)

    local vehClass = tonumber(clientVehClass)
    if vehClass and (vehClass == 7 or vehClass == 6 or vehClass == 2) then
        scrapCount = scrapCount + 1
    end

    -- Comprobar capacidad de carga para la chatarra
    local canCarryScrap = exports.ox_inventory:CanCarryItem(src, chassisConfig.item, scrapCount)
    if not canCarryScrap then
        return false, "No tienes suficiente espacio o capacidad de peso en tu inventario para cargar con la chatarra."
    end

    -- Marcar chasis como procesado
    entState:set('dismantled_chassis', true, true)

    -- Borrado seguro del vehículo en el servidor
    DeleteEntity(entity)

    -- Entrega exclusiva de chatarra en ox_inventory (sin dinero)
    local addedScrap = exports.ox_inventory:AddItem(src, chassisConfig.item, scrapCount)

    if not addedScrap then
        exports.ox_inventory:CustomDrop('Chatarra de Chasis', { { chassisConfig.item, scrapCount } }, pCoords)
        return true, string.format("Chasis compactado.\nTu inventario estaba sobrecargado; se han depositado +%d %s en una caja en el suelo.", scrapCount, chassisConfig.label)
    end

    return true, string.format("Chasis cortado y compactado con éxito.\nHas obtenido +%d %s.", scrapCount, chassisConfig.label)
end)
