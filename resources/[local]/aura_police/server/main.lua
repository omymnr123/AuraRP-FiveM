-- ============================================================================
-- AURA POLICE: SERVER MAIN CONTROLLER
-- Custody State Sync, 911 Dispatch Engine, Stash Registration & Armory
-- ============================================================================

local CuffedPlayers = {}   -- [src] = true
local EscortedPlayers = {} -- [suspectSrc] = copSrc
local DisposalStashes = {} -- [stashId] = true (Stashes con auto-vaciado a los 60s)

-- ============================================================================
-- 1. REGISTRO DE STASHES CENTRALIZADOS (ARMERÍAS, DEVOLUCIÓN Y EVIDENCIAS)
-- ============================================================================

local function RegisterPoliceStashes()
    for stationId, stationData in pairs(Config.Stations) do
        -- 1. Armería
        if stationData.armory then
            exports.ox_inventory:RegisterStash(
                stationData.armory.stashId,
                stationData.label .. " - Armería",
                stationData.armory.slots or 50,
                stationData.armory.maxWeight or 1000000,
                nil,
                { ['police'] = 0 }
            )

            -- 2. Buzón de Devolución de Dotación (Auto-Vaciado en 1 minuto)
            local disposalId = stationData.armory.returnStashId or ('police_disposal_' .. stationId)
            DisposalStashes[disposalId] = true
            exports.ox_inventory:RegisterStash(
                disposalId,
                stationData.label .. " - Buzón de Devolución (Auto-Vaciado 1 min)",
                50,
                1000000,
                nil,
                { ['police'] = 0 }
            )
        end

        -- 3. Depósito de Evidencias
        if stationData.evidence then
            exports.ox_inventory:RegisterStash(
                stationData.evidence.stashId,
                stationData.label .. " - Depósito de Evidencias",
                stationData.evidence.slots or 100,
                stationData.evidence.maxWeight or 1000000,
                nil,
                { ['police'] = 0 }
            )
        end
    end

    -- Stash de prueba para NPC Dummy de desarrollo
    exports.ox_inventory:RegisterStash(
        'police_test_dummy',
        'Sospechoso - Pertenencias (Test Dummy)',
        30,
        100000,
        nil,
        { ['police'] = 0 }
    )

    if Config.Debug then
        print("[Aura Police] Stashes de Armerías, Devolución, Evidencias y Test Dummy registrados en ox_inventory.")
    end
end

-- ============================================================================
-- MOTOR DE AUTO-VACIADO EXCLUSIVO PARA BUZONES DE DEVOLUCIÓN (CADA 60 SEGUNDOS)
-- ============================================================================
CreateThread(function()
    while true do
        Wait(60000) -- Ejecuta cada 1 minuto
        for stashId in pairs(DisposalStashes) do
            local items = exports.ox_inventory:GetInventoryItems(stashId)
            if items and next(items) then
                exports.ox_inventory:ClearInventory(stashId)
                if Config.Debug then
                    print(string.format("[Aura Police] Auto-vaciado completado en buzón: %s", stashId))
                end
            end
        end
    end
end)

RegisterNetEvent('aura_police:server:prepareDummyStash', function()
    local src = source
    if not IsCopOnDuty(src) then return end
    
    -- Inicializar con items de sospechoso si está vacío
    local items = exports.ox_inventory:GetInventoryItems('police_test_dummy')
    if not items or #items == 0 then
        exports.ox_inventory:AddItem('police_test_dummy', 'lockpick', 2)
        exports.ox_inventory:AddItem('police_test_dummy', 'phone', 1)
        exports.ox_inventory:AddItem('police_test_dummy', 'money', 450)
        exports.ox_inventory:AddItem('police_test_dummy', 'bandage', 3)
    end

    TriggerClientEvent('aura_police:client:openDummyInventory', src)
end)

AddEventHandler('onResourceStart', function(res)
    if GetCurrentResourceName() ~= res then return end
    RegisterPoliceStashes()
end)

-- ============================================================================
-- 2. CUSTODIA FÍSICA: ESPOSAS (CUFF / UNCUFF)
-- ============================================================================

local function IsCopOnDuty(src)
    local pState = Player(src).state
    return pState.job == 'police' and pState.job_duty == true
end

RegisterNetEvent('aura_police:server:cuffPlayer', function(targetSrc)
    local copSrc = source
    targetSrc = tonumber(targetSrc)

    if not IsCopOnDuty(copSrc) or not targetSrc or not GetPlayerName(tostring(targetSrc)) then
        return
    end

    -- Validación de proximidad
    local copPed = GetPlayerPed(copSrc)
    local targetPed = GetPlayerPed(targetSrc)
    if #(GetEntityCoords(copPed) - GetEntityCoords(targetPed)) > 3.5 then
        TriggerClientEvent('ox_lib:notify', copSrc, { title = 'Policía', description = 'El sospechoso está demasiado lejos.', type = 'error' })
        return
    end

    local isCuffed = CuffedPlayers[targetSrc] == true
    local newCuffedState = not isCuffed

    CuffedPlayers[targetSrc] = newCuffedState and true or nil
    Player(targetSrc).state:set('isCuffed', newCuffedState, true)

    -- Sincronizar animaciones
    TriggerClientEvent('aura_police:client:syncCuff', targetSrc, newCuffedState, copSrc)
    TriggerClientEvent('aura_police:client:playCopCuffAnim', copSrc)

    -- Si se desesposa, cancelar escolta si estaba activo
    if not newCuffedState and EscortedPlayers[targetSrc] then
        EscortedPlayers[targetSrc] = nil
        TriggerClientEvent('aura_police:client:syncEscort', targetSrc, nil)
    end

    TriggerClientEvent('ox_lib:notify', copSrc, {
        title = 'Custodia Policial',
        description = newCuffedState and 'Has esposado al sospechoso.' or 'Has retirado las esposas.',
        type = newCuffedState and 'inform' or 'success'
    })
end)

-- ============================================================================
-- 3. CUSTODIA FÍSICA: ESCOLTA / ARRASTRE (ESCORT / DRAG)
-- ============================================================================

RegisterNetEvent('aura_police:server:escortPlayer', function(targetSrc)
    local copSrc = source
    targetSrc = tonumber(targetSrc)

    if not IsCopOnDuty(copSrc) or not targetSrc or not GetPlayerName(tostring(targetSrc)) then
        return
    end

    -- Debe estar esposado
    if not CuffedPlayers[targetSrc] then
        TriggerClientEvent('ox_lib:notify', copSrc, { title = 'Custodia', description = 'El sospechoso debe estar esposado para poder escoltarlo.', type = 'error' })
        return
    end

    if EscortedPlayers[targetSrc] then
        -- Detener escolta
        EscortedPlayers[targetSrc] = nil
        TriggerClientEvent('aura_police:client:syncEscort', targetSrc, nil)
        TriggerClientEvent('ox_lib:notify', copSrc, { title = 'Custodia', description = 'Has soltado al sospechoso.', type = 'inform' })
    else
        -- Iniciar escolta
        EscortedPlayers[targetSrc] = copSrc
        TriggerClientEvent('aura_police:client:syncEscort', targetSrc, copSrc)
        TriggerClientEvent('ox_lib:notify', copSrc, { title = 'Custodia', description = 'Has comenzado a escoltar al sospechoso.', type = 'inform' })
    end
end)

-- ============================================================================
-- 4. VEHÍCULOS POLICIALES: METER Y SACAR SOSPECHOSOS
-- ============================================================================

RegisterNetEvent('aura_police:server:putInVehicle', function(targetSrc, vehNetId, chosenSeat)
    local copSrc = source
    targetSrc = tonumber(targetSrc)
    chosenSeat = tonumber(chosenSeat)

    if not IsCopOnDuty(copSrc) or not targetSrc or not GetPlayerName(tostring(targetSrc)) then
        return
    end

    -- Cancelar escolta
    EscortedPlayers[targetSrc] = nil
    TriggerClientEvent('aura_police:client:syncEscort', targetSrc, nil)

    -- Meter en vehículo en el asiento asignado
    TriggerClientEvent('aura_police:client:putInVehicle', targetSrc, vehNetId, chosenSeat)
    TriggerClientEvent('ox_lib:notify', copSrc, { title = 'Vehículo', description = 'Has introducido al sospechoso en el vehículo.', type = 'success' })
end)

RegisterNetEvent('aura_police:server:takeOutOfVehicle', function(targetSrc)
    local copSrc = source
    targetSrc = tonumber(targetSrc)

    if not IsCopOnDuty(copSrc) or not targetSrc or not GetPlayerName(tostring(targetSrc)) then
        return
    end

    -- Sacar del vehículo
    TriggerClientEvent('aura_police:client:takeOutOfVehicle', targetSrc)

    -- Iniciar escolta automáticamente
    EscortedPlayers[targetSrc] = copSrc
    TriggerClientEvent('aura_police:client:syncEscort', targetSrc, copSrc)
    TriggerClientEvent('aura_police:client:startCopEscortDirect', copSrc, targetSrc)
    TriggerClientEvent('ox_lib:notify', copSrc, { title = 'Custodia Policial', description = 'Has sacado al sospechoso del vehículo escoltado.', type = 'success' })
end)

-- Limpieza si el sospechoso o el oficial se desconectan
AddEventHandler('playerDropped', function()
    local src = source
    CuffedPlayers[src] = nil
    if EscortedPlayers[src] then
        EscortedPlayers[src] = nil
    end
    for suspect, cop in pairs(EscortedPlayers) do
        if cop == src then
            EscortedPlayers[suspect] = nil
            TriggerClientEvent('aura_police:client:syncEscort', suspect, nil)
        end
    end
end)

-- ============================================================================
-- 5. DOTACIÓN DE ARMERÍA REGLAMENTARIA SEGÚN RANGO
-- ============================================================================

lib.callback.register('aura_police:server:claimArmoryLoadout', function(source)
    local src = source
    if not IsCopOnDuty(src) then
        return false, "Debes estar de servicio como policía para retirar armamento reglamentario."
    end

    local grade = Player(src).state.job_grade or 0
    -- Obtener equipamiento para este rango o el más alto disponible hasta su grado
    local targetLoadout = nil
    for g = grade, 0, -1 do
        if Config.ArmoryWeapons[g] then
            targetLoadout = Config.ArmoryWeapons[g]
            break
        end
    end

    if not targetLoadout then
        return false, "No hay lote de armamento asignado a tu rango."
    end

    -- Entregar ítems reglamentarios al inventario del agente
    local char = exports.aura_multichar:GetActiveCharacter(src)
    local officerName = char and string.format("%s %s", char.firstname or "", char.lastname or "") or GetPlayerName(src)
    local badgeNum = Player(src).state.badge or (char and char.badge) or "101"
    local gradeLabel = Player(src).state.grade_label or ("Rango " .. grade)

    local givenCount = 0
    for _, item in ipairs(targetLoadout) do
        local metadata = nil
        if item.name == 'police_badge' then
            metadata = {
                badge = badgeNum,
                officer_name = officerName,
                grade_label = gradeLabel,
                citizenid = char and char.citizenid or "",
                description = string.format("Placa Nº: %s\nOficial: %s\nRango: %s\nDepartamento: LSPD", badgeNum, officerName, gradeLabel)
            }
        end

        local success, resp = exports.ox_inventory:AddItem(src, item.name, item.count, metadata)
        if success then
            givenCount = givenCount + 1
        else
            print(string.format("[Aura Police Armory] Aviso: No se pudo entregar '%s' x%d al jugador %d: %s", item.name, item.count, src, tostring(resp)))
        end
    end

    return true, string.format("Dotación reglamentaria entregada (%d equipos/armas retiradas). Placa asignada: #%s.", givenCount, badgeNum)
end)

-- ============================================================================
-- 6. MOTOR DE DESPACHO 911 / 112 Y ALERTAS EN TIEMPO REAL
-- ============================================================================

local RecentDispatchCalls = {} -- Buffer de últimas 30 llamadas

local function BroadcastDispatchAlert(alertData)
    if not alertData then return end

    local alert = {
        id = #RecentDispatchCalls + 1,
        code = alertData.code or "10-99",
        title = alertData.title or "Aviso de Emergencia 911",
        description = alertData.description or "Sin detalles adicionales",
        coords = alertData.coords or vec3(0, 0, 0),
        time = os.date("%H:%M:%S")
    }

    table.insert(RecentDispatchCalls, 1, alert)
    if #RecentDispatchCalls > 30 then
        table.remove(RecentDispatchCalls)
    end

    -- Enviar solo a oficiales de servicio
    for _, pid in ipairs(GetPlayers()) do
        local pSrc = tonumber(pid)
        if pSrc and IsCopOnDuty(pSrc) then
            TriggerClientEvent('aura_police:client:receiveDispatchAlert', pSrc, alert)
        end
    end
end
exports('BroadcastDispatchAlert', BroadcastDispatchAlert)

RegisterNetEvent('aura_police:server:send911Call', function(message, coords)
    local src = source
    local charData = exports.aura_multichar:GetActiveCharacter(src)
    local callerName = charData and (charData.firstname .. " " .. charData.lastname) or GetPlayerName(src)
    local phone = charData and charData.phone_number or "Desconocido"

    BroadcastDispatchAlert({
        code = "10-00 (911)",
        title = "Llamada de Emergencia Ciudadana",
        description = string.format("Llamante: %s (Tel: %s) | Motivo: %s", callerName, phone, tostring(message)),
        coords = coords or GetEntityCoords(GetPlayerPed(src))
    })

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Servicio 911',
        description = 'Tu llamada de emergencia ha sido transmitida a las unidades de patrulla en servicio.',
        type = 'success'
    })
end)

lib.callback.register('aura_police:server:getDispatchHistory', function(source)
    if not IsCopOnDuty(source) then return {} end
    return RecentDispatchCalls
end)

-- ============================================================================
-- 7. EXHIBICIÓN DE PLACA POLICIAL E IDENTIFICACIÓN
-- ============================================================================

RegisterNetEvent('aura_police:server:showBadgeToNearby', function(badgeNum, officerName, gradeLabel)
    local src = source
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local char = exports.aura_multichar:GetActiveCharacter(src)

    officerName = officerName or (char and string.format("%s %s", char.firstname or "", char.lastname or "")) or GetPlayerName(src)
    badgeNum = badgeNum or Player(src).state.badge or (char and char.badge) or "101"
    gradeLabel = gradeLabel or Player(src).state.grade_label or "Oficial"

    for _, pid in ipairs(GetPlayers()) do
        local tPed = GetPlayerPed(pid)
        if #(coords - GetEntityCoords(tPed)) <= 4.0 then
            TriggerClientEvent('ox_lib:notify', pid, {
                title = '🛡️ Placa Policial LSPD',
                description = string.format("El oficial %s te muestra su placa reglamentaria.\nPlaca Nº: #%s | %s", officerName, badgeNum, gradeLabel),
                type = 'inform',
                duration = 7000
            })
        end
    end
end)

RegisterCommand('placa', function(source)
    local src = source
    if not IsCopOnDuty(src) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Placa Policial',
            description = 'Debes estar en servicio como policía para mostrar tu placa.',
            type = 'error'
        })
        return
    end

    local char = exports.aura_multichar:GetActiveCharacter(src)
    local officerName = char and string.format("%s %s", char.firstname or "", char.lastname or "") or GetPlayerName(src)
    local badgeNum = Player(src).state.badge or (char and char.badge) or "101"
    local gradeLabel = Player(src).state.grade_label or "Oficial"

    TriggerEvent('aura_police:server:showBadgeToNearby', badgeNum, officerName, gradeLabel)
end)

-- ============================================================================
-- 8. GESTIÓN DE VESTUARIO POLICIAL Y COPIA DE SEGURIDAD DE ROPA CIVIL
-- ============================================================================

local CivilianSkins = {} -- [src] = skinData (apariencia civil guardada)

RegisterNetEvent('aura_police:server:saveCivilianSkin', function(skinData)
    local src = source
    if not src or not skinData then return end
    CivilianSkins[src] = skinData
    if Config.Debug then
        print(string.format("[Aura Police] Apariencia civil guardada en sesión para jugador #%d", src))
    end
end)

lib.callback.register('aura_police:server:getCivilianSkin', function(source)
    local src = source
    if CivilianSkins[src] then
        return CivilianSkins[src]
    end

    local charId = Player(src).state.charId
    if not charId then
        local pData = exports.aura_jobs and exports.aura_jobs:GetPlayerJobData(src)
        charId = pData and pData.charId
    end

    if charId then
        local row = MySQL.single.await('SELECT metadata FROM characters WHERE id = ?', { charId })
        if row and row.metadata then
            local meta = json.decode(row.metadata)
            if meta and meta.appearance then
                return meta.appearance
            end
        end
    end

    return nil
end)

AddEventHandler('playerDropped', function()
    local src = source
    CivilianSkins[src] = nil
    CuffedPlayers[src] = nil
    EscortedPlayers[src] = nil
end)

