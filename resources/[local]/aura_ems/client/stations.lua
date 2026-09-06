-- ============================================================================
-- AURA EMS: CLIENT STATIONS & HOSPITALS CONTROLLER
-- Duty Toggles, Pharmacy Stashes by Grade, Garage & Helipad Spawners
-- ============================================================================

local SpawnedVehicles = {}

-- ============================================================================
-- 1. BLIPS DE HOSPITALES
-- ============================================================================

CreateThread(function()
    for _, station in pairs(Config.Stations) do
        if station.blip then
            local blip = AddBlipForCoord(station.blip.coords.x, station.blip.coords.y, station.blip.coords.z)
            SetBlipSprite(blip, station.blip.sprite or 61)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, station.blip.scale or 0.85)
            SetBlipColour(blip, station.blip.color or 1)
            SetBlipAsShortRange(blip, true)

            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(station.label)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

-- ============================================================================
-- 2. SPAWN DE VEHÍCULOS Y HELICÓPTEROS MÉDICOS
-- ============================================================================

local function SpawnEmsVehicle(modelName, spawnCoords, heading)
    local model = joaat(modelName)
    lib.requestModel(model, 5000)

    -- Limpiar vehículo anterior si existía en el punto
    local clearRadius = 4.0
    local vehiclesNearby = lib.getNearbyVehicles(vec3(spawnCoords.x, spawnCoords.y, spawnCoords.z), clearRadius, true)
    for _, v in ipairs(vehiclesNearby) do
        if DoesEntityExist(v.vehicle) then
            SetEntityAsMissionEntity(v.vehicle, true, true)
            DeleteVehicle(v.vehicle)
        end
    end

    local vehicle = CreateVehicle(model, spawnCoords.x, spawnCoords.y, spawnCoords.z, heading or spawnCoords.w or 0.0, true, false)
    if DoesEntityExist(vehicle) then
        SetVehicleOnGroundProperly(vehicle)
        SetVehicleNumberPlateText(vehicle, "EMS " .. math.random(100, 999))
        SetVehicleColours(vehicle, 111, 111) -- Blanco puro
        SetVehicleLivery(vehicle, 0)
        SetVehicleEngineOn(vehicle, true, true, false)

        -- Poner al jugador dentro del vehículo
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)

        -- Guardar referencia
        table.insert(SpawnedVehicles, vehicle)

        lib.notify({
            title = 'Parque Móvil EMS',
            description = 'Vehículo de emergencias asignado y listo para el servicio.',
            type = 'success',
            icon = 'truck-medical',
            duration = 5000
        })
    end
    SetModelAsNoLongerNeeded(model)
end

local function OpenGarageMenu(stationKey, stationData, isHelipad)
    local pState = LocalPlayer.state
    if pState.job ~= Config.JobName then
        lib.notify({ title = 'Garaje EMS', description = 'Acceso reservado a personal médico.', type = 'error' })
        return
    end

    if not pState.job_duty then
        lib.notify({ title = 'Garaje EMS', description = 'Debes estar EN SERVICIO para retirar una unidad móvil.', type = 'error' })
        return
    end

    local userGrade = pState.job_grade or 0
    local options = {}

    local catalog = isHelipad and Config.Helicopters or Config.Vehicles
    local spawnTarget = isHelipad and stationData.helipad.spawn or stationData.garage.spawn
    local spawnHeading = isHelipad and stationData.helipad.heading or stationData.garage.heading

    for _, item in ipairs(catalog) do
        local isLocked = userGrade < (item.minGrade or 0)
        table.insert(options, {
            title = item.label,
            description = isLocked and string.format("Requiere Grado %s o superior", item.minGrade) or string.format("Categoría: %s", item.category),
            icon = item.icon or 'fa-solid fa-truck-medical',
            disabled = isLocked,
            onSelect = function()
                SpawnEmsVehicle(item.model, spawnTarget, spawnHeading)
            end
        })
    end

    -- Opción de guardar vehículo
    table.insert(options, {
        title = 'Guardar / Devolver Vehículo',
        description = 'Estaciona y guarda tu vehículo de emergencias en el garaje',
        icon = 'fa-solid fa-square-parking',
        onSelect = function()
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh and veh ~= 0 then
                SetEntityAsMissionEntity(veh, true, true)
                DeleteVehicle(veh)
                lib.notify({ title = 'Garaje EMS', description = 'Vehículo guardado correctamente.', type = 'inform' })
            else
                local nearby = lib.getNearbyVehicles(GetEntityCoords(ped), 6.0, true)
                if nearby and #nearby > 0 then
                    SetEntityAsMissionEntity(nearby[1].vehicle, true, true)
                    DeleteVehicle(nearby[1].vehicle)
                    lib.notify({ title = 'Garaje EMS', description = 'Vehículo cercano guardado.', type = 'inform' })
                else
                    lib.notify({ title = 'Garaje EMS', description = 'No hay ningún vehículo cercano para guardar.', type = 'error' })
                end
            end
        end
    })

    lib.registerContext({
        id = 'ems_garage_context_' .. stationKey,
        title = isHelipad and ('Helipuerto - ' .. (stationData.shortName or stationData.label)) or ('Garaje - ' .. (stationData.shortName or stationData.label)),
        options = options
    })

    lib.showContext('ems_garage_context_' .. stationKey)
end

-- ============================================================================
-- 3. REGISTRO DE PUNTOS OX_TARGET EN CADA ESTACIÓN
-- ============================================================================

CreateThread(function()
    for stationKey, stationData in pairs(Config.Stations) do
        -- 1. ZONA DE ENTRADA / SALIDA DE SERVICIO (DUTY)
        if stationData.duty then
            exports.ox_target:addSphereZone({
                coords = stationData.duty.coords,
                radius = stationData.duty.radius or 1.6,
                debug = Config.Debug,
                options = {
                    {
                        name = 'aura_ems_duty_' .. stationKey,
                        icon = 'fa-solid fa-user-doctor',
                        label = 'Entrar / Salir de Servicio (EMS)',
                        distance = 2.5,
                        canInteract = function()
                            local pState = LocalPlayer.state
                            return pState.job == Config.JobName
                        end,
                        onSelect = function()
                            lib.callback('aura_ems:server:toggleDuty', false, function(success, isDuty, message)
                                if success then
                                    lib.notify({
                                        title = 'Cuerpo Médico',
                                        description = message,
                                        type = isDuty and 'success' or 'inform',
                                        icon = 'user-doctor',
                                        duration = 6000
                                    })
                                else
                                    lib.notify({ title = 'Error', description = message, type = 'error' })
                                end
                            end)
                        end
                    }
                }
            })
        end

        -- 2. FARMACIA Y ARMARIO DE SUMINISTROS MÉDICOS
        if stationData.pharmacy then
            exports.ox_target:addSphereZone({
                coords = stationData.pharmacy.coords,
                radius = stationData.pharmacy.radius or 1.6,
                debug = Config.Debug,
                options = {
                    {
                        name = 'aura_ems_pharmacy_' .. stationKey,
                        icon = 'fa-solid fa-prescription-bottle-medical',
                        label = 'Farmacia Hospitalaria (Suministros)',
                        distance = 2.5,
                        canInteract = function()
                            local pState = LocalPlayer.state
                            return pState.job == Config.JobName
                        end,
                        onSelect = function()
                            local pState = LocalPlayer.state
                            if not pState.job_duty then
                                lib.notify({
                                    title = 'Farmacia Médica',
                                    description = 'Debes entrar EN SERVICIO para retirar material sanitario.',
                                    type = 'error'
                                })
                                return
                            end

                            if exports.ox_inventory then
                                exports.ox_inventory:openInventory('stash', stationData.pharmacy.stashId)
                            end
                        end
                    }
                }
            })
        end

        -- 3. GARAJE DE AMBULANCIAS
        if stationData.garage then
            exports.ox_target:addSphereZone({
                coords = stationData.garage.interact,
                radius = 2.2,
                debug = Config.Debug,
                options = {
                    {
                        name = 'aura_ems_garage_' .. stationKey,
                        icon = 'fa-solid fa-truck-medical',
                        label = 'Garaje de Ambulancias',
                        distance = 3.0,
                        canInteract = function()
                            local pState = LocalPlayer.state
                            return pState.job == Config.JobName
                        end,
                        onSelect = function()
                            OpenGarageMenu(stationKey, stationData, false)
                        end
                    }
                }
            })
        end

        -- 4. HELIPUERTO MEDEVAC
        if stationData.helipad then
            exports.ox_target:addSphereZone({
                coords = stationData.helipad.interact,
                radius = 2.5,
                debug = Config.Debug,
                options = {
                    {
                        name = 'aura_ems_helipad_' .. stationKey,
                        icon = 'fa-solid fa-helicopter',
                        label = 'Helipuerto Air-Ambulance',
                        distance = 3.5,
                        canInteract = function()
                            local pState = LocalPlayer.state
                            return pState.job == Config.JobName
                        end,
                        onSelect = function()
                            OpenGarageMenu(stationKey, stationData, true)
                        end
                    }
                }
            })
        end
    end
end)
