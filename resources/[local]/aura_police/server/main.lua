-- ============================================================================
-- AURA POLICE: SERVER MAIN CONTROLLER
-- Custody State Sync, 911 Dispatch Engine, Stash Registration & Armory
-- ============================================================================

local CuffedPlayers = {}   -- [src] = true
local EscortedPlayers = {} -- [suspectSrc] = copSrc

-- ============================================================================
-- 1. REGISTRO DE STASHES CENTRALIZADOS (ARMERÍAS Y DEPÓSITOS DE EVIDENCIAS)
-- ============================================================================

local function RegisterPoliceStashes()
    for stationId, stationData in pairs(Config.Stations) do
        -- Armería
        if stationData.armory then
            exports.ox_inventory:RegisterStash(
                stationData.armory.stashId,
                stationData.label .. " - Armería",
                stationData.armory.slots or 50,
                stationData.armory.maxWeight or 500000,
                nil,
                { ['police'] = 0 }
            )
        end

        -- Depósito de Evidencias
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

    if Config.Debug then
        print("[Aura Police] Stashes de Armerías y Evidencias registrados en ox_inventory.")
    end
end

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

RegisterNetEvent('aura_police:server:putInVehicle', function(targetSrc)
    local copSrc = source
    targetSrc = tonumber(targetSrc)

    if not IsCopOnDuty(copSrc) or not targetSrc or not GetPlayerName(tostring(targetSrc)) then
        return
    end

    -- Cancelar escolta
    EscortedPlayers[targetSrc] = nil
    TriggerClientEvent('aura_police:client:syncEscort', targetSrc, nil)

    -- Meter en vehículo
    TriggerClientEvent('aura_police:client:putInVehicle', targetSrc)
    TriggerClientEvent('ox_lib:notify', copSrc, { title = 'Vehículo', description = 'Has introducido al sospechoso en el vehículo.', type = 'success' })
end)

RegisterNetEvent('aura_police:server:takeOutOfVehicle', function(targetSrc)
    local copSrc = source
    targetSrc = tonumber(targetSrc)

    if not IsCopOnDuty(copSrc) or not targetSrc or not GetPlayerName(tostring(targetSrc)) then
        return
    end

    TriggerClientEvent('aura_police:client:takeOutOfVehicle', targetSrc)
    TriggerClientEvent('ox_lib:notify', copSrc, { title = 'Vehículo', description = 'Has sacado al sospechoso del vehículo.', type = 'success' })
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
    for _, item in ipairs(targetLoadout) do
        exports.ox_inventory:AddItem(src, item.name, item.count)
    end

    return true, "Equipamiento y armamento reglamentario retirado correctamente."
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
