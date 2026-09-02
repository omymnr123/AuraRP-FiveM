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
-- 1. LÓGICA DE DETECCIÓN Y ASIGNACIÓN DE ASIENTOS SEGÚN POSICIÓN DEL OFICIAL
-- ============================================================================

local function GetSeatName(seat)
    if seat == -1 then return 'Conductor'
    elseif seat == 0 then return 'Copiloto'
    elseif seat == 1 then return 'Trasero Izquierdo'
    elseif seat == 2 then return 'Trasero Derecho'
    elseif seat == 3 then return 'Tercera Fila Izquierda'
    elseif seat == 4 then return 'Tercera Fila Derecha'
    else return 'Asiento #' .. tostring(seat)
    end
end

local function FindBestFreeSeatForPed(vehicle, referenceCoords)
    if not DoesEntityExist(vehicle) then return nil end
    local maxPassengers = GetVehicleMaxNumberOfPassengers(vehicle)

    -- Candidatos a asientos de pasajeros
    -- Prioridad: 1 (Trasero Izq), 2 (Trasero Der), 3/4 (Filas adicionales), 0 (Copiloto)
    local candidateSeats = {}
    for s = 1, maxPassengers - 1 do
        table.insert(candidateSeats, s)
    end
    if maxPassengers > 0 then
        table.insert(candidateSeats, 0)
    end

    local freeCandidates = {}
    for _, seat in ipairs(candidateSeats) do
        local pedInSeat = GetPedInVehicleSeat(vehicle, seat)
        if pedInSeat == 0 and IsVehicleSeatFree(vehicle, seat) then
            local seatPos = nil
            if seat == 1 then
                seatPos = GetOffsetFromEntityInWorldCoords(vehicle, -0.9, -0.9, 0.0)
            elseif seat == 2 then
                seatPos = GetOffsetFromEntityInWorldCoords(vehicle, 0.9, -0.9, 0.0)
            elseif seat == 0 then
                seatPos = GetOffsetFromEntityInWorldCoords(vehicle, 0.9, 0.4, 0.0)
            elseif seat == 3 then
                seatPos = GetOffsetFromEntityInWorldCoords(vehicle, -0.9, -1.8, 0.0)
            elseif seat == 4 then
                seatPos = GetOffsetFromEntityInWorldCoords(vehicle, 0.9, -1.8, 0.0)
            else
                seatPos = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -1.0, 0.0)
            end

            local dist = #(referenceCoords - seatPos)
            table.insert(freeCandidates, {
                seat = seat,
                dist = dist
            })
        end
    end

    if #freeCandidates == 0 then
        return nil
    end

    -- Ordenar por el asiento más cercano al lado donde está parado el oficial
    table.sort(freeCandidates, function(a, b)
        return a.dist < b.dist
    end)

    return freeCandidates[1].seat
end

local function HandleTakeOutOfVehicle(vehicle)
    if not DoesEntityExist(vehicle) then return end
    local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
    local occupants = {}

    for seat = -1, maxSeats - 1 do
        local pedInSeat = GetPedInVehicleSeat(vehicle, seat)
        if pedInSeat ~= 0 and pedInSeat ~= cache.ped then
            local seatLabel = GetSeatName(seat)
            local isPlayer = false
            local targetSrc = nil
            local name = 'Sujeto Desconocido'

            if IsPedAPlayer(pedInSeat) then
                local targetIndex = NetworkGetPlayerIndexFromPed(pedInSeat)
                if targetIndex and targetIndex ~= -1 then
                    targetSrc = GetPlayerServerId(targetIndex)
                    if targetSrc and targetSrc > 0 then
                        isPlayer = true
                        name = GetPlayerName(targetIndex) or ('Sospechoso (ID #' .. targetSrc .. ')')
                    end
                end
            elseif testDummyPed and pedInSeat == testDummyPed then
                name = 'NPC Sospechoso (Dummy de Pruebas)'
            else
                name = 'Ocupante (NPC)'
            end

            table.insert(occupants, {
                ped = pedInSeat,
                seat = seat,
                seatLabel = seatLabel,
                isPlayer = isPlayer,
                targetSrc = targetSrc,
                name = name
            })
        end
    end

    if #occupants == 0 then
        lib.notify({ title = 'Vehículo', description = 'No hay ningún ocupante dentro del vehículo.', type = 'inform' })
        return
    end

    local function ExtractOccupant(occ)
        if occ.isPlayer and occ.targetSrc then
            TriggerServerEvent('aura_police:server:takeOutOfVehicle', occ.targetSrc)
        elseif occ.ped and DoesEntityExist(occ.ped) then
            TaskLeaveVehicle(occ.ped, vehicle, 16)
            Wait(400)
            AttachEntityToEntity(
                occ.ped,
                cache.ped,
                11816, -- SKEL_Pelvis
                0.45, 0.45, 0.0,
                0.0, 0.0, 0.0,
                false, false, false, false, 2, true
            )
            dummyIsEscorted = true
            StartCopEscorting(occ.ped, nil)
            lib.notify({ title = 'Custodia Policial', description = 'Has sacado al sujeto del vehículo escoltado.', type = 'success' })
        end
    end

    if #occupants == 1 then
        ExtractOccupant(occupants[1])
    else
        local options = {}
        for _, occ in ipairs(occupants) do
            table.insert(options, {
                title = string.format('%s (%s)', occ.name, occ.seatLabel),
                description = 'Haz clic para sacar al detenido del vehículo y escoltarlo',
                icon = 'fa-solid fa-person-walking-arrow-right',
                onSelect = function()
                    ExtractOccupant(occ)
                end
            })
        end

        lib.registerContext({
            id = 'aura_police_vehicle_occupants_menu',
            title = 'Ocupantes del Vehículo',
            options = options
        })
        lib.showContext('aura_police_vehicle_occupants_menu')
    end
end

-- ============================================================================
-- 2. REGISTRO DE ACCIONES EN OX_TARGET (JUGADORES Y VEHÍCULOS)
-- ============================================================================

CreateThread(function()
    -- ACCIONES EN VEHÍCULOS: SACAR DETENIDOS DEL VEHÍCULO ESCOLTADOS
    exports.ox_target:addGlobalVehicle({
        {
            name = 'aura_police_veh_take_out',
            icon = 'fa-solid fa-person-walking-dashed-line-arrow-right',
            label = 'Sacar Sujeto del Vehículo',
            distance = 3.0,
            canInteract = function(entity, distance, coords, name)
                local pState = LocalPlayer.state
                if not (pState.job == 'police' and pState.job_duty == true) then return false end
                if not DoesEntityExist(entity) then return false end

                local maxSeats = GetVehicleMaxNumberOfPassengers(entity)
                for seat = -1, maxSeats - 1 do
                    local pedInSeat = GetPedInVehicleSeat(entity, seat)
                    if pedInSeat ~= 0 and pedInSeat ~= cache.ped then
                        return true
                    end
                end
                return false
            end,
            onSelect = function(data)
                local vehicle = data.entity
                if not DoesEntityExist(vehicle) then return end
                HandleTakeOutOfVehicle(vehicle)
            end
        }
    })

    -- ACCIONES SOBRE JUGADORES
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

                local copCoords = GetEntityCoords(cache.ped)
                local vehicle = lib.getClosestVehicle(copCoords, 6.0, true)
                if not vehicle or not DoesEntityExist(vehicle) then
                    lib.notify({ title = 'Vehículo', description = 'No hay ningún vehículo cercano para meter al detenido.', type = 'error' })
                    return
                end

                local chosenSeat = FindBestFreeSeatForPed(vehicle, copCoords)
                if not chosenSeat then
                    lib.notify({ title = 'Vehículo', description = 'No quedan asientos libres para detenidos en el vehículo.', type = 'error' })
                    return
                end

                if isCopEscorting then
                    StopCopEscorting()
                end

                local vehNetId = NetworkGetNetworkIdFromEntity(vehicle)
                TriggerServerEvent('aura_police:server:putInVehicle', targetSrc, vehNetId, chosenSeat)
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
                return pState.job == 'police' and pState.job_duty == true and IsPedInAnyVehicle(entity, false)
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

RegisterNetEvent('aura_police:client:putInVehicle', function(vehNetId, chosenSeat)
    local ped = cache.ped
    DetachEntity(ped, true, false)

    local vehicle = nil
    if vehNetId then
        vehicle = NetworkGetEntityFromNetworkId(vehNetId)
    end

    if not vehicle or not DoesEntityExist(vehicle) then
        local coords = GetEntityCoords(ped)
        vehicle = lib.getClosestVehicle(coords, 6.0, true)
    end

    if vehicle and DoesEntityExist(vehicle) then
        local seat = chosenSeat
        if not seat then
            seat = FindBestFreeSeatForPed(vehicle, GetEntityCoords(ped)) or 1
        end

        TaskWarpPedIntoVehicle(ped, vehicle, seat)
    end
end)

RegisterNetEvent('aura_police:client:takeOutOfVehicle', function()
    local ped = cache.ped
    if IsPedInAnyVehicle(ped, false) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        TaskLeaveVehicle(ped, vehicle, 16)
    end
end)

RegisterNetEvent('aura_police:client:startCopEscortDirect', function(targetSrc)
    local targetPlayer = GetPlayerFromServerId(targetSrc)
    if targetPlayer ~= -1 then
        local targetPed = GetPlayerPed(targetPlayer)
        StartCopEscorting(targetPed, targetSrc)
    end
end)

-- ============================================================================
-- 5. MODO DE PRUEBAS LOCAL: NPC DUMMY INTERACTUABLE (/spawndummy /deldummy)
-- Permite a un desarrollador en solitario probar toda la interacción física:
-- Esposar, Escoltar, Meter en Patrulla (lado izq y der) y Sacar del Patrulla.
-- ============================================================================

local activeDummyPeds = {}
local dummyCuffedStates = {}

RegisterCommand('spawndummy', function()
    local playerPed = cache.ped
    local spawnOffset = 1.8 + (#activeDummyPeds * 0.8)
    local coords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, spawnOffset, 0.0)
    local heading = GetEntityHeading(playerPed) + 180.0
    local model = `a_m_y_hipster_01`

    lib.requestModel(model)
    local dummyPed = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, heading, false, true)
    SetEntityAsMissionEntity(dummyPed, true, true)
    SetBlockingOfNonTemporaryEvents(dummyPed, true)
    SetPedFleeAttributes(dummyPed, 0, false)
    SetPedCombatAttributes(dummyPed, 17, true)
    FreezeEntityPosition(dummyPed, false)

    table.insert(activeDummyPeds, dummyPed)
    dummyCuffedStates[dummyPed] = false
    testDummyPed = dummyPed

    local dummyNumber = #activeDummyPeds

    -- Registrar opciones directas de ox_target sobre este Dummy Ped
    exports.ox_target:addLocalEntity(dummyPed, {
        {
            name = 'dummy_cuff_' .. dummyNumber,
            icon = 'fa-solid fa-handcuffs',
            label = string.format('[TEST #%d] Esposar / Desesposar', dummyNumber),
            distance = 2.0,
            onSelect = function(data)
                local targetPed = data.entity or dummyPed
                dummyCuffedStates[targetPed] = not dummyCuffedStates[targetPed]
                lib.requestAnimDict("mp_arresting")
                TaskPlayAnim(cache.ped, "mp_arresting", "a_uncuff", 8.0, -8.0, 2000, 48, 0, false, false, false)

                if dummyCuffedStates[targetPed] then
                    TaskPlayAnim(targetPed, "mp_arresting", "idle", 8.0, -8.0, -1, 49, 0, false, false, false)
                    lib.notify({ title = 'Pruebas Dummy', description = string.format('Dummy #%d ESPOSADO con éxito.', dummyNumber), type = 'inform' })
                else
                    ClearPedTasks(targetPed)
                    if isCopEscorting and currentEscortedEntity == targetPed then
                        StopCopEscorting()
                    end
                    lib.notify({ title = 'Pruebas Dummy', description = string.format('Dummy #%d DESESPOSADO.', dummyNumber), type = 'inform' })
                end
            end
        },
        {
            name = 'dummy_escort_' .. dummyNumber,
            icon = 'fa-solid fa-person-walking-arrow-right',
            label = string.format('[TEST #%d] Escoltar / Dejar de escoltar', dummyNumber),
            distance = 2.0,
            onSelect = function(data)
                local targetPed = data.entity or dummyPed
                if isCopEscorting and currentEscortedEntity == targetPed then
                    StopCopEscorting()
                else
                    if isCopEscorting then
                        StopCopEscorting()
                    end
                    AttachEntityToEntity(
                        targetPed, cache.ped, 11816,
                        0.45, 0.45, 0.0,
                        0.0, 0.0, 0.0,
                        false, false, false, false, 2, true
                    )
                    StartCopEscorting(targetPed, nil)
                end
            end
        },
        {
            name = 'dummy_put_car_' .. dummyNumber,
            icon = 'fa-solid fa-car-side',
            label = string.format('[TEST #%d] Meter en Patrulla', dummyNumber),
            distance = 2.5,
            onSelect = function(data)
                local targetPed = data.entity or dummyPed
                local coords = GetEntityCoords(cache.ped)
                local vehicle = lib.getClosestVehicle(coords, 6.0, true)
                if not vehicle or not DoesEntityExist(vehicle) then
                    lib.notify({ title = 'Pruebas Dummy', description = 'No hay ningún vehículo cercano.', type = 'error' })
                    return
                end

                if isCopEscorting and currentEscortedEntity == targetPed then
                    StopCopEscorting()
                end

                local chosenSeat = FindBestFreeSeatForPed(vehicle, coords)
                if chosenSeat then
                    TaskWarpPedIntoVehicle(targetPed, vehicle, chosenSeat)
                    lib.notify({ 
                        title = 'Pruebas Dummy', 
                        description = string.format('Dummy #%d introducido en: %s.', dummyNumber, GetSeatName(chosenSeat)), 
                        type = 'success' 
                    })
                else
                    lib.notify({ title = 'Pruebas Dummy', description = 'No quedan asientos libres para detenidos en el vehículo.', type = 'error' })
                end
            end
        },
        {
            name = 'dummy_out_car_' .. dummyNumber,
            icon = 'fa-solid fa-person-walking-dashed-line-arrow-right',
            label = string.format('[TEST #%d] Sacar del Patrulla', dummyNumber),
            distance = 2.5,
            onSelect = function(data)
                local targetPed = data.entity or dummyPed
                if IsPedInAnyVehicle(targetPed, false) then
                    local vehicle = GetVehiclePedIsIn(targetPed, false)
                    TaskLeaveVehicle(targetPed, vehicle, 16)
                    Wait(400)
                    AttachEntityToEntity(
                        targetPed, cache.ped, 11816,
                        0.45, 0.45, 0.0,
                        0.0, 0.0, 0.0,
                        false, false, false, false, 2, true
                    )
                    StartCopEscorting(targetPed, nil)
                    lib.notify({ title = 'Pruebas Dummy', description = string.format('Dummy #%d extraído del vehículo escoltado.', dummyNumber), type = 'inform' })
                else
                    lib.notify({ title = 'Pruebas Dummy', description = 'El dummy no está dentro de ningún vehículo.', type = 'inform' })
                end
            end
        },
        {
            name = 'dummy_frisk_' .. dummyNumber,
            icon = 'fa-solid fa-magnifying-glass',
            label = string.format('[TEST #%d] Cachear Pertenencias (Inventario)', dummyNumber),
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
        title = string.format('NPC Dummy #%d Creado', dummyNumber),
        description = 'Apunta con [ALT] al NPC o al vehículo. Puedes crear más con /spawndummy.',
        type = 'success',
        duration = 6000
    })
end, false)

RegisterCommand('testdummy', function()
    ExecuteCommand('spawndummy')
end, false)

RegisterCommand('deldummy', function()
    local count = #activeDummyPeds
    for _, ped in ipairs(activeDummyPeds) do
        if DoesEntityExist(ped) then
            exports.ox_target:removeLocalEntity(ped)
            DeleteEntity(ped)
        end
    end
    activeDummyPeds = {}
    dummyCuffedStates = {}
    testDummyPed = nil

    if count > 0 then
        lib.notify({ title = 'Pruebas Dummy', description = string.format('%d NPC(s) Dummy eliminados.', count), type = 'inform' })
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
