-- ============================================================================
-- AURA POLICE: CLIENT STATIONS CONTROLLER
-- Armory Stashes, illenium-appearance Wardrobes, Evidence Locker & Garages
-- ============================================================================

local function InitStationPoints()
    for stationKey, stationData in pairs(Config.Stations) do
        -- 1. ARMERÍA POLICIAL
        if stationData.armory then
            exports.ox_target:addBoxZone({
                coords = stationData.armory.coords,
                size = vec3(1.5, 1.5, 2.0),
                rotation = 0.0,
                debug = Config.Debug,
                options = {
                    {
                        name = 'aura_police_armory_loadout_' .. stationKey,
                        icon = 'fa-solid fa-gun',
                        label = 'Retirar Dotación Reglamentaria',
                        distance = 2.0,
                        canInteract = function()
                            local pState = LocalPlayer.state
                            return pState.job == 'police' and pState.job_duty == true
                        end,
                        onSelect = function()
                            lib.callback('aura_police:server:claimArmoryLoadout', false, function(success, message)
                                lib.notify({
                                    title = 'Armería Policial',
                                    description = message,
                                    type = success and 'success' or 'error'
                                })
                            end)
                        end
                    },
                    {
                        name = 'aura_police_armory_stash_' .. stationKey,
                        icon = 'fa-solid fa-box-archive',
                        label = 'Abrir Almacén de Armería',
                        distance = 2.0,
                        canInteract = function()
                            local pState = LocalPlayer.state
                            return pState.job == 'police' and pState.job_duty == true
                        end,
                        onSelect = function()
                            exports.ox_inventory:openInventory('stash', stationData.armory.stashId)
                        end
                    }
                }
            })
        end

        -- 2. DEPÓSITO DE EVIDENCIAS
        if stationData.evidence then
            exports.ox_target:addBoxZone({
                coords = stationData.evidence.coords,
                size = vec3(1.5, 1.5, 2.0),
                rotation = 0.0,
                debug = Config.Debug,
                options = {
                    {
                        name = 'aura_police_evidence_' .. stationKey,
                        icon = 'fa-solid fa-boxes-stacked',
                        label = 'Abrir Depósito de Evidencias (Confiscaciones)',
                        distance = 2.0,
                        canInteract = function()
                            local pState = LocalPlayer.state
                            return pState.job == 'police' and pState.job_duty == true
                        end,
                        onSelect = function()
                            exports.ox_inventory:openInventory('stash', stationData.evidence.stashId)
                        end
                    }
                }
            })
        end

        -- 3. VESTUARIO / TAQUILLAS
        if stationData.wardrobe then
            exports.ox_target:addBoxZone({
                coords = stationData.wardrobe.coords,
                size = vec3(1.5, 1.5, 2.0),
                rotation = 0.0,
                debug = Config.Debug,
                options = {
                    {
                        name = 'aura_police_wardrobe_' .. stationKey,
                        icon = 'fa-solid fa-shirt',
                        label = 'Abrir Vestuario (Uniformes LSPD)',
                        distance = 2.0,
                        canInteract = function()
                            local pState = LocalPlayer.state
                            return pState.job == 'police' and pState.job_duty == true
                        end,
                        onSelect = function()
                            -- Trigger a illenium-appearance si está disponible
                            TriggerEvent('illenium-appearance:client:openJobOutfitsMenu')
                        end
                    }
                }
            })
        end

        -- 4. GARAJE POLICIAL
        if stationData.garage then
            exports.ox_target:addBoxZone({
                coords = stationData.garage.interact,
                size = vec3(2.0, 2.0, 2.0),
                rotation = 0.0,
                debug = Config.Debug,
                options = {
                    {
                        name = 'aura_police_garage_' .. stationKey,
                        icon = 'fa-solid fa-car',
                        label = 'Garaje Policial (Vehículos de Patrulla)',
                        distance = 2.5,
                        canInteract = function()
                            local pState = LocalPlayer.state
                            return pState.job == 'police' and pState.job_duty == true
                        end,
                        onSelect = function()
                            local grade = LocalPlayer.state.job_grade or 0
                            local menuOptions = {}

                            for _, veh in ipairs(Config.Vehicles) do
                                if grade >= veh.minGrade then
                                    table.insert(menuOptions, {
                                        title = veh.label,
                                        description = string.format("Modelo: %s | Rango Mín: Grado %d", veh.model, veh.minGrade),
                                        icon = 'fa-solid fa-car',
                                        onSelect = function()
                                            SpawnPoliceVehicle(veh.model, stationData.garage.spawn)
                                        end
                                    })
                                end
                            end

                            -- Opción de guardar vehículo
                            table.insert(menuOptions, {
                                title = 'Guardar Vehículo de Patrulla',
                                description = 'Elimina y estaciona la patrulla en el garaje.',
                                icon = 'fa-solid fa-square-parking',
                                onSelect = function()
                                    local ped = cache.ped
                                    local veh = GetVehiclePedIsIn(ped, false)
                                    if veh ~= 0 then
                                        DeleteVehicle(veh)
                                        lib.notify({ title = 'Garaje', description = 'Vehículo guardado correctamente.', type = 'success' })
                                    else
                                        local nearbyVeh = lib.getClosestVehicle(stationData.garage.spawn.xyz, 6.0, true)
                                        if nearbyVeh then
                                            DeleteVehicle(nearbyVeh)
                                            lib.notify({ title = 'Garaje', description = 'Vehículo guardado correctamente.', type = 'success' })
                                        else
                                            lib.notify({ title = 'Garaje', description = 'No hay ningún vehículo cerca para guardar.', type = 'error' })
                                        end
                                    end
                                end
                            })

                            lib.registerContext({
                                id = 'aura_police_garage_menu',
                                title = 'Flota de Vehículos Policiales',
                                options = menuOptions
                            })
                            lib.showContext('aura_police_garage_menu')
                        end
                    }
                }
            })
        end

        -- 5. HELIPUERTO POLICIAL
        if stationData.helipad then
            exports.ox_target:addBoxZone({
                coords = stationData.helipad.interact,
                size = vec3(2.0, 2.0, 2.0),
                rotation = 0.0,
                debug = Config.Debug,
                options = {
                    {
                        name = 'aura_police_helipad_' .. stationKey,
                        icon = 'fa-solid fa-helicopter',
                        label = 'Helipuerto Policial (Air-1)',
                        distance = 2.5,
                        canInteract = function()
                            local pState = LocalPlayer.state
                            return pState.job == 'police' and pState.job_duty == true
                        end,
                        onSelect = function()
                            local grade = LocalPlayer.state.job_grade or 0
                            local menuOptions = {}

                            for _, heli in ipairs(Config.Helicopters or {}) do
                                if grade >= heli.minGrade then
                                    table.insert(menuOptions, {
                                        title = heli.label,
                                        description = string.format("Modelo: %s | Equipado con Cámara Helicam", heli.model),
                                        icon = 'fa-solid fa-helicopter',
                                        onSelect = function()
                                            SpawnPoliceVehicle(heli.model, stationData.helipad.spawn)
                                        end
                                    })
                                end
                            end

                            -- Opción de guardar helicóptero
                            table.insert(menuOptions, {
                                title = 'Guardar Helicóptero',
                                icon = 'fa-solid fa-square-parking',
                                onSelect = function()
                                    local ped = cache.ped
                                    local veh = GetVehiclePedIsIn(ped, false)
                                    if veh ~= 0 then
                                        DeleteVehicle(veh)
                                        lib.notify({ title = 'Helipuerto', description = 'Helicóptero guardado.', type = 'success' })
                                    else
                                        local nearbyVeh = lib.getClosestVehicle(stationData.helipad.spawn.xyz, 10.0, true)
                                        if nearbyVeh then
                                            DeleteVehicle(nearbyVeh)
                                            lib.notify({ title = 'Helipuerto', description = 'Helicóptero guardado.', type = 'success' })
                                        end
                                    end
                                end
                            })

                            lib.registerContext({
                                id = 'aura_police_helipad_menu',
                                title = 'Helipuerto Policial Air Support',
                                options = menuOptions
                            })
                            lib.showContext('aura_police_helipad_menu')
                        end
                    }
                }
            })
        end
    end
end

function SpawnPoliceVehicle(model, spawnCoords)
    local hash = joaat(model)
    lib.requestModel(hash)

    local veh = CreateVehicle(hash, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, false)
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetVehicleNumberPlateText(veh, "LSPD" .. tostring(math.random(100, 999)))

    -- Colocar al policía en el asiento del conductor
    TaskWarpPedIntoVehicle(cache.ped, veh, -1)

    lib.notify({
        title = 'Garaje Policial',
        description = 'Vehículo de dotación asignado correctamente.',
        type = 'success'
    })
end

CreateThread(function()
    Wait(500)
    InitStationPoints()
end)
