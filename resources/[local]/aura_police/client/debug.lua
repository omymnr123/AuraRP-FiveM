-- ============================================================================
-- AURA POLICE: DEVELOPER & SOLO TESTING SUITE
-- Herramienta para probar Custodia Física, Despacho, Cárcel y MDT en solitario
-- ============================================================================

local SpawnedDummies = {}
local EscortedDummy = nil

-- ============================================================================
-- 1. ACCIONES INDIVIDUALES REUTILIZABLES
-- ============================================================================

local function SimulateGunshotAlert()
    local coords = GetEntityCoords(cache.ped)
    local s1, s2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = GetStreetNameFromHashKey(s1)
    if s2 ~= 0 then
        street = street .. " / " .. GetStreetNameFromHashKey(s2)
    end
    local zone = GetNameOfZone(coords.x, coords.y, coords.z)
    local zoneLabel = GetLabelText(zone)
    if zoneLabel == "NULL" or not zoneLabel then zoneLabel = zone end

    TriggerServerEvent('aura_police:server:reportGunshot', {
        coords = coords,
        street = street,
        zone = zoneLabel
    })
end

local function SimulateVehicleTheftAlert()
    local veh = GetVehiclePedIsIn(cache.ped, false)
    if veh == 0 then
        local coords = GetEntityCoords(cache.ped)
        veh = GetClosestVehicle(coords.x, coords.y, coords.z, 15.0, 0, 71)
    end
    if veh ~= 0 and DoesEntityExist(veh) then
        exports.aura_police:TriggerVehicleTheftAlert(veh)
    else
        lib.notify({
            title = 'Suite de Pruebas',
            description = 'No se encontró ningún vehículo cerca para simular el robo.',
            type = 'error'
        })
    end
end

-- ============================================================================
-- 2. MENÚ INTERACTIVO COMPLETO (/policetest O /testcop)
-- ============================================================================

local function OpenDebugMenu()
    lib.registerMenu({
        id = 'aura_police_debug_menu',
        title = '🛡️ Test Suite Policial',
        position = 'top-right',
        options = {
            { label = '👮 Entrar de Servicio LSPD (Grado 5)', description = 'Comisario y estado de servicio activo' },
            { label = '👤 Generar Sospechoso NPC', description = 'Spawnea un dummy para probar ox_target' },
            { label = '💥 Simular Disparos (10-71)', description = 'Alerta de disparos en tus coordenadas' },
            { label = '🚗 Simular Robo de Vehículo (10-99)', description = 'Alerta de sustracción en coche cercano' },
            { label = '🚗 Generar Coche Bloqueado (Forzado)', description = 'Spawnea coche cerrado con llave para probar ganzúas' },
            { label = '🔒 Auto-Sentencia Prisión (2 Min)', description = 'Prueba celdas, timer y anti-escape' },
            { label = '🔓 Liberar de Prisión Inmediatamente', description = 'Restaura estado fuera del penal' },
            { label = '🗑️ Eliminar Sospechosos NPC', description = 'Limpia todos los dummies generados' }
        }
    }, function(selected, scrollIndex, args)
        if selected == 1 then
            TriggerServerEvent('aura_police:server:debugSetPoliceDuty')
        elseif selected == 2 then
            SpawnTestSuspect()
        elseif selected == 3 then
            SimulateGunshotAlert()
        elseif selected == 4 then
            SimulateVehicleTheftAlert()
        elseif selected == 5 then
            ExecuteCommand('spawnlocked')
        elseif selected == 6 then
            TriggerServerEvent('aura_police:server:debugSelfJail', 2)
        elseif selected == 7 then
            TriggerServerEvent('aura_police:server:debugSelfUnjail')
        elseif selected == 8 then
            ClearTestSuspects()
        end
    end)

    lib.showMenu('aura_police_debug_menu')
end

RegisterCommand('policetest', OpenDebugMenu, false)
RegisterCommand('testcop', OpenDebugMenu, false)

-- ============================================================================
-- 3. COMANDOS DIRECTOS DE CHAT (ACCESO DIRECTO INSTANTÁNEO)
-- ============================================================================

RegisterCommand('setcop', function()
    TriggerServerEvent('aura_police:server:debugSetPoliceDuty')
end, false)

RegisterCommand('spawnsuspect', function()
    SpawnTestSuspect()
end, false)
RegisterCommand('spawndummy', function()
    SpawnTestSuspect()
end, false)

RegisterCommand('clearsuspects', function()
    ClearTestSuspects()
end, false)
RegisterCommand('deldummy', function()
    ClearTestSuspects()
end, false)

RegisterCommand('testshot', function()
    SimulateGunshotAlert()
end, false)
RegisterCommand('testgunshot', function()
    SimulateGunshotAlert()
end, false)

RegisterCommand('testtheft', function()
    SimulateVehicleTheftAlert()
end, false)

RegisterCommand('testjail', function(source, args)
    local mins = tonumber(args[1]) or 2
    TriggerServerEvent('aura_police:server:debugSelfJail', mins)
end, false)

RegisterCommand('testunjail', function()
    TriggerServerEvent('aura_police:server:debugSelfUnjail')
end, false)

-- ============================================================================
-- 4. GENERADOR DE SOSPECHOSO DUMMY CON INTERACCIONES OX_TARGET
-- ============================================================================

function SpawnTestSuspect()
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local spawnCoords = coords + (forward * 1.8)
    local heading = (GetEntityHeading(ped) + 180.0) % 360.0

    local modelHash = `g_m_y_salvagoon_01`
    lib.requestModel(modelHash, 5000)

    local dummyPed = CreatePed(4, modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z - 1.0, heading, true, false)
    SetEntityAsMissionEntity(dummyPed, true, true)
    SetBlockingOfNonTemporaryEvents(dummyPed, true)
    SetPedCanRagdollFromPlayerImpact(dummyPed, false)
    SetPedFleeAttributes(dummyPed, 0, false)
    SetPedCombatAttributes(dummyPed, 17, true)
    SetEntityInvincible(dummyPed, false)
    FreezeEntityPosition(dummyPed, false)

    local dummyId = #SpawnedDummies + 1
    local isCuffed = false
    local isEscorted = false

    -- Inicializar Stash de prueba en el servidor para este Dummy
    TriggerServerEvent('aura_police:server:initDummyStash', dummyId)

    table.insert(SpawnedDummies, dummyPed)

    -- Registrar ox_target específico sobre este Dummy
    exports.ox_target:addLocalEntity(dummyPed, {
        {
            name = 'dummy_cuff_' .. dummyId,
            icon = 'fa-solid fa-handcuffs',
            label = 'Esposar / Desesposar (Sospechoso)',
            distance = 2.0,
            onSelect = function()
                isCuffed = not isCuffed
                lib.requestAnimDict('mp_arresting')
                if isCuffed then
                    TaskPlayAnim(dummyPed, 'mp_arresting', 'idle', 8.0, -8.0, -1, 49, 0, false, false, false)
                    SetEnableHandcuffs(dummyPed, true)
                    lib.notify({ title = 'Sospechoso de Pruebas', description = 'Sospechoso esposado.', type = 'success' })
                else
                    ClearPedTasks(dummyPed)
                    SetEnableHandcuffs(dummyPed, false)
                    if isEscorted then
                        DetachEntity(dummyPed, true, true)
                        isEscorted = false
                    end
                    lib.notify({ title = 'Sospechoso de Pruebas', description = 'Sospechoso desesposado.', type = 'inform' })
                end
            end
        },
        {
            name = 'dummy_escort_' .. dummyId,
            icon = 'fa-solid fa-person-walking-arrow-right',
            label = 'Escoltar / Soltar (Sospechoso)',
            distance = 2.0,
            onSelect = function()
                if not isCuffed then
                    lib.notify({ title = 'Sospechoso de Pruebas', description = 'Debes esposar primero al sospechoso.', type = 'error' })
                    return
                end
                isEscorted = not isEscorted
                if isEscorted then
                    AttachEntityToEntity(dummyPed, cache.ped, 11816, 0.45, 0.45, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                    EscortedDummy = dummyPed
                    lib.notify({ title = 'Sospechoso de Pruebas', description = 'Escoltando al sospechoso.', type = 'success' })
                else
                    DetachEntity(dummyPed, true, true)
                    EscortedDummy = nil
                    lib.notify({ title = 'Sospechoso de Pruebas', description = 'Sospechoso liberado de escolta.', type = 'inform' })
                end
            end
        },
        {
            name = 'dummy_vehicle_in_' .. dummyId,
            icon = 'fa-solid fa-car-side',
            label = 'Meter en Patrulla (Sospechoso)',
            distance = 3.0,
            onSelect = function()
                local c = GetEntityCoords(cache.ped)
                local veh = GetClosestVehicle(c.x, c.y, c.z, 6.0, 0, 71)
                if veh == 0 or not DoesEntityExist(veh) then
                    lib.notify({ title = 'Sospechoso de Pruebas', description = 'No hay ningún vehículo cerca.', type = 'error' })
                    return
                end

                if isEscorted then
                    DetachEntity(dummyPed, true, true)
                    isEscorted = false
                    EscortedDummy = nil
                end

                local maxSeats = GetVehicleMaxNumberOfPassengers(veh)
                local targetSeat = nil
                for seat = 1, maxSeats - 1 do
                    if IsVehicleSeatFree(veh, seat) then
                        targetSeat = seat
                        break
                    end
                end
                if not targetSeat and IsVehicleSeatFree(veh, 0) then targetSeat = 0 end

                if targetSeat ~= nil then
                    TaskWarpPedIntoVehicle(dummyPed, veh, targetSeat)
                    lib.notify({ title = 'Sospechoso de Pruebas', description = string.format("Sospechoso introducido en el asiento #%d del patrulla.", targetSeat), type = 'success' })
                else
                    lib.notify({ title = 'Sospechoso de Pruebas', description = 'No hay asientos libres para el detenido.', type = 'error' })
                end
            end
        },
        {
            name = 'dummy_vehicle_out_' .. dummyId,
            icon = 'fa-solid fa-person-walking-dashed-line-arrow-right',
            label = 'Sacar de Patrulla (Sospechoso)',
            distance = 3.0,
            onSelect = function()
                if IsPedInAnyVehicle(dummyPed, false) then
                    local veh = GetVehiclePedIsIn(dummyPed, false)
                    local outCoords = GetOffsetFromEntityInWorldCoords(veh, 1.5, 0.0, 0.0)
                    TaskLeaveVehicle(dummyPed, veh, 16)
                    Wait(600)
                    SetEntityCoords(dummyPed, outCoords.x, outCoords.y, outCoords.z, false, false, false, false)
                    if isCuffed then
                        TaskPlayAnim(dummyPed, 'mp_arresting', 'idle', 8.0, -8.0, -1, 49, 0, false, false, false)
                    end
                    lib.notify({ title = 'Sospechoso de Pruebas', description = 'Sospechoso retirado del vehículo.', type = 'success' })
                else
                    lib.notify({ title = 'Sospechoso de Pruebas', description = 'El sospechoso no está dentro de ningún vehículo.', type = 'error' })
                end
            end
        },
        {
            name = 'dummy_frisk_' .. dummyId,
            icon = 'fa-solid fa-magnifying-glass',
            label = 'Cachear / Registrar Inventario (Sospechoso)',
            distance = 2.0,
            onSelect = function()
                if lib.progressBar({
                        duration = 2500,
                        label = 'Cacheando al sospechoso de pruebas...',
                        useWhileDead = false,
                        canCancel = true,
                        disable = { move = true, car = true, combat = true },
                        anim = { dict = 'mini@repair', clip = 'fixing_a_player', flags = 49 }
                    }) then
                    exports.ox_inventory:openInventory('stash', 'dummy_suspect_inv_' .. dummyId)
                end
            end
        },
        {
            name = 'dummy_delete_' .. dummyId,
            icon = 'fa-solid fa-user-xmark',
            label = 'Eliminar Sospechoso de Pruebas',
            distance = 2.5,
            onSelect = function()
                if isEscorted then DetachEntity(dummyPed, true, true) end
                DeleteEntity(dummyPed)
                lib.notify({ title = 'Sospechoso de Pruebas', description = 'Sospechoso eliminado.', type = 'inform' })
            end
        }
    })

    lib.notify({
        title = 'Sospechoso Spawneado',
        description = 'Apunta con el botón derecho (ox_target) al NPC para probar todas las interacciones físicas.',
        type = 'success',
        duration = 8000
    })
end

-- ============================================================================
-- 5. LIMPIEZA DE DUMMIES
-- ============================================================================

function ClearTestSuspects()
    for _, dummyPed in ipairs(SpawnedDummies) do
        if DoesEntityExist(dummyPed) then
            DetachEntity(dummyPed, true, true)
            DeleteEntity(dummyPed)
        end
    end
    SpawnedDummies = {}
    EscortedDummy = nil
    lib.notify({ title = 'Suite de Pruebas', description = 'Todos los sospechosos de prueba han sido eliminados.', type = 'inform' })
end
