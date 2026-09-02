-- ============================================================================
-- AURA POLICE: CLIENT PHYSICAL INTERACTIONS CONTROLLER
-- ox_target Global Player: Cuff, Escort, Vehicle Custody & Inventory Frisk
-- ============================================================================

local isCuffed = false
local isEscorted = false
local escortingCopPed = nil

-- Estado del oficial cuando está escoltando
local isCopEscorting = false
local currentEscortedEntity = nil
local currentEscortedSrc = nil

local function StopCopEscorting()
    if not isCopEscorting then return end
    
    if currentEscortedSrc then
        TriggerServerEvent('aura_police:server:escortPlayer', currentEscortedSrc)
    elseif currentEscortedEntity and DoesEntityExist(currentEscortedEntity) then
        DetachEntity(currentEscortedEntity, true, false)
    end

    isCopEscorting = false
    currentEscortedEntity = nil
    currentEscortedSrc = nil
    lib.hideTextUI()
    lib.notify({ title = 'Custodia Policial', description = 'Has soltado al detenido.', type = 'inform' })
end

local function StartCopEscorting(entity, serverId)
    isCopEscorting = true
    currentEscortedEntity = entity
    currentEscortedSrc = serverId

    lib.showTextUI('[E] o [X] Soltar detenido | /soltar', {
        position = 'top-center',
        icon = 'fa-solid fa-person-walking-arrow-right',
        style = {
            borderRadius = 8,
            backgroundColor = 'rgba(8, 16, 32, 0.92)',
            color = '#00f2fe',
            border = '1px solid rgba(0, 242, 254, 0.4)'
        }
    })

    -- Hilo de escucha de teclas para soltar con un solo clic
    CreateThread(function()
        while isCopEscorting do
            Wait(0)
            -- 38 = E, 73 = X
            if IsControlJustPressed(0, 38) or IsControlJustPressed(0, 73) or IsDisabledControlJustPressed(0, 73) then
                StopCopEscorting()
                break
            end
        end
    end)
end

RegisterCommand('soltar', function()
    StopCopEscorting()
end, false)

RegisterCommand('release', function()
    StopCopEscorting()
end, false)

-- ============================================================================
-- 1. REGISTRO DE ACCIONES EN OX_TARGET SOBRE JUGADORES
-- ============================================================================

CreateThread(function()
    exports.ox_target:addGlobalPlayer({
        -- ACCIÓN 1: ESPOSAR / DESESPOSAR
        {
            name = 'aura_police_cuff',
            icon = 'fa-solid fa-handcuffs',
            label = 'Esposar / Desesposar',
            distance = 2.0,
            canInteract = function(entity, distance, coords, name)
                local pState = LocalPlayer.state
                return pState.job == 'police' and pState.job_duty == true
            end,
            onSelect = function(data)
                local targetPed = data.entity
                if not DoesEntityExist(targetPed) then return end

                local targetIndex = NetworkGetPlayerIndexFromPed(targetPed)
                local targetSrc = GetPlayerServerId(targetIndex)
                if not targetSrc or targetSrc <= 0 then return end

                TriggerServerEvent('aura_police:server:cuffPlayer', targetSrc)
            end
        },

        -- ACCIÓN 2: ESCOLTAR / ARRASTRAR
        {
            name = 'aura_police_escort',
            icon = 'fa-solid fa-person-walking-arrow-right',
            label = 'Escoltar / Soltar',
            distance = 2.0,
            canInteract = function(entity, distance, coords, name)
                local pState = LocalPlayer.state
                return pState.job == 'police' and pState.job_duty == true
            end,
            onSelect = function(data)
                local targetPed = data.entity
                if not DoesEntityExist(targetPed) then return end

                local targetIndex = NetworkGetPlayerIndexFromPed(targetPed)
                local targetSrc = GetPlayerServerId(targetIndex)
                if not targetSrc or targetSrc <= 0 then return end

                if isCopEscorting and currentEscortedSrc == targetSrc then
                    StopCopEscorting()
                else
                    StartCopEscorting(targetPed, targetSrc)
                    TriggerServerEvent('aura_police:server:escortPlayer', targetSrc)
                end
            end
        },

        -- ACCIÓN 3: METER EN VEHÍCULO PATRULLA
        {
            name = 'aura_police_put_vehicle',
            icon = 'fa-solid fa-car-side',
            label = 'Meter en Vehículo',
            distance = 2.5,
            canInteract = function(entity, distance, coords, name)
                local pState = LocalPlayer.state
                return pState.job == 'police' and pState.job_duty == true
            end,
            onSelect = function(data)
                local targetPed = data.entity
                if not DoesEntityExist(targetPed) then return end

                local targetIndex = NetworkGetPlayerIndexFromPed(targetPed)
                local targetSrc = GetPlayerServerId(targetIndex)
                if not targetSrc or targetSrc <= 0 then return end

                if isCopEscorting then
                    StopCopEscorting()
                end

                TriggerServerEvent('aura_police:server:putInVehicle', targetSrc)
            end
        },

        -- ACCIÓN 4: SACAR DEL VEHÍCULO
        {
            name = 'aura_police_out_vehicle',
            icon = 'fa-solid fa-person-walking-dashed-line-arrow-right',
            label = 'Sacar del Vehículo',
            distance = 2.5,
            canInteract = function(entity, distance, coords, name)
                local pState = LocalPlayer.state
                return pState.job == 'police' and pState.job_duty == true
            end,
            onSelect = function(data)
                local targetPed = data.entity
                if not DoesEntityExist(targetPed) then return end

                local targetIndex = NetworkGetPlayerIndexFromPed(targetPed)
                local targetSrc = GetPlayerServerId(targetIndex)
                if not targetSrc or targetSrc <= 0 then return end

                TriggerServerEvent('aura_police:server:takeOutOfVehicle', targetSrc)
            end
        },

        -- ACCIÓN 5: REGISTRAR / CACHEAR INVENTARIO (CON ANIMACIÓN Y OX_INVENTORY)
        {
            name = 'aura_police_frisk',
            icon = 'fa-solid fa-magnifying-glass',
            label = 'Cachear / Registrar',
            distance = 2.0,
            canInteract = function(entity, distance, coords, name)
                local pState = LocalPlayer.state
                return pState.job == 'police' and pState.job_duty == true
            end,
            onSelect = function(data)
                local targetPed = data.entity
                if not DoesEntityExist(targetPed) then return end

                local targetIndex = NetworkGetPlayerIndexFromPed(targetPed)
                local targetSrc = GetPlayerServerId(targetIndex)
                if not targetSrc or targetSrc <= 0 then return end

                -- Animación y barra de progreso de registro
                if lib.progressBar({
                    duration = 3000,
                    label = 'Registrando pertenencias del sospechoso...',
                    useWhileDead = false,
                    canCancel = true,
                    disable = { move = true, car = true, combat = true },
                    anim = {
                        dict = 'mini@repair',
                        clip = 'fixing_a_player',
                        flags = 49
                    }
                }) then
                    exports.ox_inventory:openInventory('player', targetSrc)
                else
                    lib.notify({ title = 'Policía', description = 'Registro cancelado.', type = 'inform' })
                end
            end
        }
    })
end)

-- ============================================================================
-- 2. GESTIÓN Y SINCRONIZACIÓN DEL ESTADO ESPOSADO (CUFFED)
-- ============================================================================

RegisterNetEvent('aura_police:client:playCopCuffAnim', function()
    lib.requestAnimDict("mp_arresting")
    TaskPlayAnim(cache.ped, "mp_arresting", "a_uncuff", 8.0, -8.0, 2500, 48, 0, false, false, false)
end)

RegisterNetEvent('aura_police:client:syncCuff', function(cuffedState, copSrc)
    isCuffed = cuffedState == true
    LocalPlayer.state:set('isCuffed', isCuffed, true)

    local ped = cache.ped

    if isCuffed then
        -- Desarmar
        SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)

        -- Animación de esposado
        lib.requestAnimDict("mp_arresting")
        TaskPlayAnim(ped, "mp_arresting", "idle", 8.0, -8.0, -1, 49, 0, false, false, false)

        -- Hilo de restricción total mientras esté esposado
        CreateThread(function()
            while isCuffed do
                Wait(0)
                -- Deshabilitar combate, saltos, ataques y armas
                DisableControlAction(0, 24, true)  -- Attack
                DisableControlAction(0, 257, true) -- Attack 2
                DisableControlAction(0, 25, true)  -- Aim
                DisableControlAction(0, 263, true) -- Melee Attack 1
                DisableControlAction(0, 45, true)  -- Reload
                DisableControlAction(0, 22, true)  -- Jump
                DisableControlAction(0, 44, true)  -- Cover
                DisableControlAction(0, 37, true)  -- Select Weapon
                DisableControlAction(0, 288, true) -- Phone / F1
                DisableControlAction(0, 289, true) -- Inventory / F2
                DisableControlAction(0, 170, true) -- F3
                DisableControlAction(0, 167, true) -- F6
                DisableControlAction(0, 75, true)  -- Exit Vehicle

                -- Mantener animación si no está en vehículo
                if not IsEntityPlayingAnim(ped, "mp_arresting", "idle", 3) and not IsPedInAnyVehicle(ped, false) then
                    TaskPlayAnim(ped, "mp_arresting", "idle", 8.0, -8.0, -1, 49, 0, false, false, false)
                end
            end

            ClearPedTasks(ped)
        end)
    else
        ClearPedTasks(ped)
    end
end)

-- ============================================================================
-- 3. GESTIÓN Y SINCRONIZACIÓN DE ESCOLTA (ESCORT)
-- ============================================================================

RegisterNetEvent('aura_police:client:syncEscort', function(copServerId)
    if copServerId then
        isEscorted = true
        local copPlayer = GetPlayerFromServerId(copServerId)
        if copPlayer ~= -1 then
            escortingCopPed = GetPlayerPed(copPlayer)
            
            -- Vincular entidad al oficial escoltante
            AttachEntityToEntity(
                cache.ped,
                escortingCopPed,
                11816, -- SKEL_Pelvis
                0.45, 0.45, 0.0,
                0.0, 0.0, 0.0,
                false, false, false, false, 2, true
            )
        end
    else
        isEscorted = false
        escortingCopPed = nil
        DetachEntity(cache.ped, true, false)
    end
end)

-- ============================================================================
-- 4. VEHÍCULOS: METER Y SACAR
-- ============================================================================

RegisterNetEvent('aura_police:client:putInVehicle', function()
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local vehicle = lib.getClosestVehicle(coords, 5.0, true)

    if vehicle and DoesEntityExist(vehicle) then
        local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
        local freeSeat = nil

        for seat = maxSeats - 1, 0, -1 do
            if IsVehicleSeatFree(vehicle, seat) and seat ~= -1 then
                freeSeat = seat
                break
            end
        end

        if freeSeat then
            TaskWarpPedIntoVehicle(ped, vehicle, freeSeat)
        end
    end
end)

RegisterNetEvent('aura_police:client:takeOutOfVehicle', function()
    local ped = cache.ped
    if IsPedInAnyVehicle(ped, false) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        TaskLeaveVehicle(ped, vehicle, 16)
    end
end)

-- ============================================================================
-- 5. MODO DE PRUEBAS LOCAL: NPC DUMMY INTERACTUABLE (/spawndummy /deldummy)
-- Permite a un desarrollador en solitario probar toda la interacción física:
-- Esposar, Escoltar, Meter en Patrulla, Sacar del Patrulla y Cachear.
-- ============================================================================

local testDummyPed = nil
local dummyIsCuffed = false
local dummyIsEscorted = false

RegisterCommand('spawndummy', function()
    if testDummyPed and DoesEntityExist(testDummyPed) then
        DeleteEntity(testDummyPed)
        testDummyPed = nil
    end

    local playerPed = cache.ped
    local coords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 1.8, 0.0)
    local heading = GetEntityHeading(playerPed) + 180.0
    local model = `a_m_y_hipster_01`

    lib.requestModel(model)
    testDummyPed = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, heading, false, true)
    SetEntityAsMissionEntity(testDummyPed, true, true)
    SetBlockingOfNonTemporaryEvents(testDummyPed, true)
    SetPedFleeAttributes(testDummyPed, 0, false)
    SetPedCombatAttributes(testDummyPed, 17, true)
    FreezeEntityPosition(testDummyPed, false)

    dummyIsCuffed = false
    dummyIsEscorted = false

    -- Registrar opciones directas de ox_target sobre el Dummy Ped
    exports.ox_target:addLocalEntity(testDummyPed, {
        {
            name = 'dummy_cuff',
            icon = 'fa-solid fa-handcuffs',
            label = '[TEST] Esposar / Desesposar',
            distance = 2.0,
            onSelect = function(data)
                dummyIsCuffed = not dummyIsCuffed
                lib.requestAnimDict("mp_arresting")
                TaskPlayAnim(cache.ped, "mp_arresting", "a_uncuff", 8.0, -8.0, 2000, 48, 0, false, false, false)

                if dummyIsCuffed then
                    TaskPlayAnim(testDummyPed, "mp_arresting", "idle", 8.0, -8.0, -1, 49, 0, false, false, false)
                    lib.notify({ title = 'Pruebas Dummy', description = 'NPC Dummy ESPOSADO con éxito.', type = 'inform' })
                else
                    ClearPedTasks(testDummyPed)
                    if isCopEscorting then
                        StopCopEscorting()
                    end
                    dummyIsEscorted = false
                    lib.notify({ title = 'Pruebas Dummy', description = 'NPC Dummy DESESPOSADO.', type = 'inform' })
                end
            end
        },
        {
            name = 'dummy_escort',
            icon = 'fa-solid fa-person-walking-arrow-right',
            label = '[TEST] Escoltar / Dejar de escoltar',
            distance = 2.0,
            onSelect = function(data)
                if isCopEscorting then
                    StopCopEscorting()
                    dummyIsEscorted = false
                else
                    dummyIsEscorted = true
                    AttachEntityToEntity(
                        testDummyPed, cache.ped, 11816,
                        0.45, 0.45, 0.0,
                        0.0, 0.0, 0.0,
                        false, false, false, false, 2, true
                    )
                    StartCopEscorting(testDummyPed, nil)
                end
            end
        },
        {
            name = 'dummy_put_car',
            icon = 'fa-solid fa-car-side',
            label = '[TEST] Meter en Patrulla',
            distance = 2.5,
            onSelect = function(data)
                local coords = GetEntityCoords(cache.ped)
                local vehicle = lib.getClosestVehicle(coords, 6.0, true)
                if not vehicle or not DoesEntityExist(vehicle) then
                    lib.notify({ title = 'Pruebas Dummy', description = 'No hay ningún vehículo cercano.', type = 'error' })
                    return
                end

                if isCopEscorting then
                    StopCopEscorting()
                end
                dummyIsEscorted = false

                local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
                local freeSeat = nil
                for seat = maxSeats - 1, 0, -1 do
                    if IsVehicleSeatFree(vehicle, seat) and seat ~= -1 then
                        freeSeat = seat
                        break
                    end
                end

                if freeSeat then
                    TaskWarpPedIntoVehicle(testDummyPed, vehicle, freeSeat)
                    lib.notify({ title = 'Pruebas Dummy', description = 'Dummy introducido en el asiento del patrulla.', type = 'success' })
                else
                    lib.notify({ title = 'Pruebas Dummy', description = 'No hay asientos libres para detenidos.', type = 'error' })
                end
            end
        },
        {
            name = 'dummy_out_car',
            icon = 'fa-solid fa-person-walking-dashed-line-arrow-right',
            label = '[TEST] Sacar del Patrulla',
            distance = 2.5,
            onSelect = function(data)
                if IsPedInAnyVehicle(testDummyPed, false) then
                    local vehicle = GetVehiclePedIsIn(testDummyPed, false)
                    TaskLeaveVehicle(testDummyPed, vehicle, 16)
                    lib.notify({ title = 'Pruebas Dummy', description = 'Dummy retirado del vehículo.', type = 'inform' })
                else
                    lib.notify({ title = 'Pruebas Dummy', description = 'El dummy no está dentro de ningún vehículo.', type = 'inform' })
                end
            end
        },
        {
            name = 'dummy_frisk',
            icon = 'fa-solid fa-magnifying-glass',
            label = '[TEST] Cachear Pertenencias (Abrir Inventario)',
            distance = 2.0,
            onSelect = function(data)
                if lib.progressBar({
                    duration = 3000,
                    label = 'Cacheando pertenencias del sospechoso...',
                    useWhileDead = false,
                    canCancel = true,
                    disable = { move = true, car = true, combat = true },
                    anim = {
                        dict = 'mini@repair',
                        clip = 'fixing_a_player',
                        flags = 49
                    }
                }) then
                    TriggerServerEvent('aura_police:server:prepareDummyStash')
                else
                    lib.notify({ title = 'Policía', description = 'Cacheo cancelado.', type = 'inform' })
                end
            end
        }
    })

    lib.notify({
        title = 'NPC Dummy Creado',
        description = 'Apunta al NPC con [ALT] (ox_target) para probar esposar, escoltar, meter/sacar del patrulla y cachear.',
        type = 'success',
        duration = 8000
    })
end, false)

RegisterCommand('testdummy', function()
    ExecuteCommand('spawndummy')
end, false)

RegisterCommand('deldummy', function()
    if testDummyPed and DoesEntityExist(testDummyPed) then
        exports.ox_target:removeLocalEntity(testDummyPed)
        DeleteEntity(testDummyPed)
        testDummyPed = nil
        dummyIsCuffed = false
        dummyIsEscorted = false
        lib.notify({ title = 'Pruebas Dummy', description = 'NPC Dummy eliminado.', type = 'inform' })
    else
        lib.notify({ title = 'Pruebas Dummy', description = 'No hay ningún dummy activo.', type = 'error' })
    end
end, false)

RegisterCommand('borrardummy', function()
    ExecuteCommand('deldummy')
end, false)

RegisterNetEvent('aura_police:client:openDummyInventory', function()
    exports.ox_inventory:openInventory('stash', 'police_test_dummy')
end)
