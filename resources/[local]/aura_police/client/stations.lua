-- ============================================================================
-- AURA POLICE: CLIENT STATIONS CONTROLLER
-- Armory Stashes, illenium-appearance Wardrobes, Evidence Locker & Garages
-- ============================================================================

local CivilianAppearanceBackup = nil
local IsWearingPoliceUniform = false

local function EquipPoliceUniform()
    local ped = cache.ped
    local pState = LocalPlayer.state
    local grade = pState.job_grade or 0

    -- Determinar género (Male / Female)
    local model = GetEntityModel(ped)
    local gender = 'Male'
    if model == `mp_f_freemode_01` or not IsPedMale(ped) then
        gender = 'Female'
    end

    -- Obtener la configuración del uniforme según el grado policial
    local uniformConfig = Config.Uniforms[grade]
    if not uniformConfig then
        for g = grade, 0, -1 do
            if Config.Uniforms[g] then
                uniformConfig = Config.Uniforms[g]
                break
            end
        end
    end

    if not uniformConfig or not uniformConfig[gender] then
        lib.notify({
            title = 'Vestuario LSPD',
            description = 'No se encontró un uniforme asignado para tu rango.',
            type = 'error'
        })
        return
    end

    -- Guardar copia de seguridad de la ropa civil del personaje ANTES de vestirse
    if not IsWearingPoliceUniform then
        local currentAppearance = nil
        pcall(function()
            if exports['illenium-appearance'] then
                currentAppearance = exports['illenium-appearance']:getPedAppearance(ped)
            end
        end)

        if currentAppearance then
            CivilianAppearanceBackup = currentAppearance
            TriggerServerEvent('aura_police:server:saveCivilianSkin', currentAppearance)
        end
    end

    -- Animación de vestirse
    lib.requestAnimDict('clothingshirt')
    local dressed = lib.progressBar({
        duration = 2000,
        label = 'Equipando ' .. (uniformConfig.label or 'uniforme policial') .. '...',
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = true,
            car = true,
            combat = true
        },
        anim = {
            dict = 'clothingshirt',
            clip = 'try_shirt_positive_d'
        }
    })

    if not dressed then return end

    -- Aplicar componentes de ropa
    local outfit = uniformConfig[gender]
    if outfit.components then
        for _, comp in ipairs(outfit.components) do
            SetPedComponentVariation(ped, comp.component_id, comp.drawable, comp.texture, 0)
        end
    end

    -- Aplicar accesorios y complementos (props)
    if outfit.props then
        for _, prop in ipairs(outfit.props) do
            if prop.drawable == -1 then
                ClearPedProp(ped, prop.prop_id)
            else
                SetPedPropIndex(ped, prop.prop_id, prop.drawable, prop.texture, true)
            end
        end
    end

    IsWearingPoliceUniform = true

    lib.notify({
        title = 'Vestuario LSPD',
        description = string.format("Te has equipado: %s", uniformConfig.label or 'Uniforme Reglamentario'),
        type = 'success'
    })
end

local function RemovePoliceUniform()
    local ped = cache.ped

    -- Animación de desvestirse
    lib.requestAnimDict('clothingshirt')
    local undressed = lib.progressBar({
        duration = 2000,
        label = 'Quitándose el uniforme policial...',
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = true,
            car = true,
            combat = true
        },
        anim = {
            dict = 'clothingshirt',
            clip = 'try_shirt_positive_d'
        }
    })

    if not undressed then return end

    -- 1. Si tenemos copia local directa, la aplicamos
    if CivilianAppearanceBackup then
        pcall(function()
            exports['illenium-appearance']:setPedAppearance(ped, CivilianAppearanceBackup)
        end)
        CivilianAppearanceBackup = nil
        IsWearingPoliceUniform = false
        lib.notify({
            title = 'Vestuario LSPD',
            description = 'Te has quitado el uniforme y has vuelto a tu ropa civil.',
            type = 'inform'
        })
        return
    end

    -- 2. Si no había copia local (ej: reconexión), recuperar del servidor / DB
    lib.callback('aura_police:server:getCivilianSkin', false, function(savedAppearance)
        if savedAppearance then
            pcall(function()
                exports['illenium-appearance']:setPedAppearance(ped, savedAppearance)
            end)
            IsWearingPoliceUniform = false
            lib.notify({
                title = 'Vestuario LSPD',
                description = 'Te has quitado el uniforme y has vuelto a tu ropa civil.',
                type = 'inform'
            })
        else
            -- Fallback a reloadSkin de illenium
            TriggerEvent('illenium-appearance:client:reloadSkin')
            IsWearingPoliceUniform = false
            lib.notify({
                title = 'Vestuario LSPD',
                description = 'Te has quitado el uniforme policial.',
                type = 'inform'
            })
        end
    end)
end

local function InitStationPoints()
    for stationKey, stationData in pairs(Config.Stations) do
        -- 1. ARMERÍA POLICIAL
        if stationData.armory then
            exports.ox_target:addBoxZone({
                coords = stationData.armory.coords,
                size = vec3(2.5, 2.5, 2.5),
                rotation = 0.0,
                debug = Config.Debug,
                options = {
                    {
                        name = 'aura_police_armory_loadout_' .. stationKey,
                        icon = 'fa-solid fa-gun',
                        label = 'Retirar Dotación Reglamentaria',
                        distance = 2.8,
                        canInteract = function()
                            local pState = LocalPlayer.state
                            return pState.job == 'police'
                        end,
                        onSelect = function()
                            local pState = LocalPlayer.state
                            if not pState.job_duty then
                                lib.notify({
                                    title = 'Armería Policial',
                                    description = 'Debes entrar EN SERVICIO para retirar tu armamento reglamentario.',
                                    type = 'error'
                                })
                                return
                            end

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
                        name = 'aura_police_armory_return_' .. stationKey,
                        icon = 'fa-solid fa-trash-can-arrow-up',
                        label = 'Buzón de Devolución de Dotación (Auto-Vaciado 1 min)',
                        distance = 2.8,
                        canInteract = function()
                            local pState = LocalPlayer.state
                            return pState.job == 'police'
                        end,
                        onSelect = function()
                            local disposalStash = (stationData.armory and stationData.armory.returnStashId) or ('police_disposal_' .. stationKey)
                            lib.notify({
                                title = 'Buzón de Devolución',
                                description = 'Deposita tu dotación. Todo objeto depositado aquí será eliminado en 1 minuto.',
                                type = 'inform'
                            })
                            exports.ox_inventory:openInventory('stash', disposalStash)
                        end
                    }
                }
            })
        end

        -- 2. DEPÓSITO DE EVIDENCIAS
        if stationData.evidence then
            exports.ox_target:addBoxZone({
                coords = stationData.evidence.coords,
                size = vec3(2.5, 2.5, 2.5),
                rotation = 0.0,
                debug = Config.Debug,
                options = {
                    {
                        name = 'aura_police_evidence_' .. stationKey,
                        icon = 'fa-solid fa-fingerprint',
                        label = 'Depósito de Evidencias (LSPD)',
                        distance = 2.8,
                        canInteract = function()
                            local pState = LocalPlayer.state
                            return pState.job == 'police'
                        end,
                        onSelect = function()
                            local pState = LocalPlayer.state
                            if not pState.job_duty then
                                lib.notify({
                                    title = 'Depósito de Evidencias',
                                    description = 'Debes entrar EN SERVICIO como policía para acceder a las evidencias.',
                                    type = 'error'
                                })
                                return
                            end

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
                size = vec3(2.5, 2.5, 2.5),
                rotation = 0.0,
                debug = Config.Debug,
                options = {
                    {
                        name = 'aura_police_wardrobe_equip_' .. stationKey,
                        icon = 'fa-solid fa-shirt',
                        label = 'Abrir Vestuario (Uniformes LSPD)',
                        distance = 2.8,
                        canInteract = function()
                            local pState = LocalPlayer.state
                            return pState.job == 'police'
                        end,
                        onSelect = function()
                            EquipPoliceUniform()
                        end
                    },
                    {
                        name = 'aura_police_wardrobe_remove_' .. stationKey,
                        icon = 'fa-solid fa-person-arrow-down-to-line',
                        label = 'Quitar (Uniforme LSPD)',
                        distance = 2.8,
                        canInteract = function()
                            local pState = LocalPlayer.state
                            return pState.job == 'police'
                        end,
                        onSelect = function()
                            RemovePoliceUniform()
                        end
                    }
                }
            })
        end

        -- 4. GARAJE POLICIAL
        if stationData.garage then
            exports.ox_target:addBoxZone({
                coords = stationData.garage.interact,
                size = vec3(3.0, 3.0, 3.0),
                rotation = 0.0,
                debug = Config.Debug,
                options = {
                    {
                        name = 'aura_police_garage_' .. stationKey,
                        icon = 'fa-solid fa-car',
                        label = 'Garaje Policial (Vehículos de Patrulla)',
                        distance = 3.0,
                        canInteract = function()
                            local pState = LocalPlayer.state
                            return pState.job == 'police'
                        end,
                        onSelect = function()
                            local pState = LocalPlayer.state
                            if not pState.job_duty then
                                lib.notify({
                                    title = 'Garaje Policial',
                                    description = 'Debes entrar EN SERVICIO para solicitar un vehículo de patrulla.',
                                    type = 'error'
                                })
                                return
                            end

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
                size = vec3(3.0, 3.0, 3.0),
                rotation = 0.0,
                debug = Config.Debug,
                options = {
                    {
                        name = 'aura_police_helipad_' .. stationKey,
                        icon = 'fa-solid fa-helicopter',
                        label = 'Helipuerto Policial (Air-1)',
                        distance = 3.0,
                        canInteract = function()
                            local pState = LocalPlayer.state
                            return pState.job == 'police'
                        end,
                        onSelect = function()
                            local pState = LocalPlayer.state
                            if not pState.job_duty then
                                lib.notify({
                                    title = 'Helipuerto Policial',
                                    description = 'Debes entrar EN SERVICIO para solicitar apoyo aéreo.',
                                    type = 'error'
                                })
                                return
                            end

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
