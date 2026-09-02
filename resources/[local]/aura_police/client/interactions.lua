-- ============================================================================
-- AURA POLICE: CLIENT PHYSICAL INTERACTIONS CONTROLLER
-- ox_target Global Player: Cuff, Escort, Vehicle Custody & Inventory Frisk
-- ============================================================================

local isCuffed = false
local isEscorted = false
local escortingCopPed = nil

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

                TriggerServerEvent('aura_police:server:escortPlayer', targetSrc)
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

        -- ACCIÓN 5: REGISTRAR / CACHEAR INVENTARIO (OX_INVENTORY NATIVO)
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

                -- Abrir inventario del jugador sospechoso directamente
                exports.ox_inventory:openInventory('player', targetSrc)
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
