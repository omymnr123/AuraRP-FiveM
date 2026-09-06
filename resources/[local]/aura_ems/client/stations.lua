-- ============================================================================
-- AURA EMS: CLIENT STATIONS & HOSPITALS CONTROLLER
-- Duty Toggles, Pharmacy Stashes by Grade, Fleet Command Garages & Helipad Spawners
-- ============================================================================

local SpawnedVehicles = {}
local SpawnedStationProps = {}
local currentStationSpawn = nil
local myEmsVehicle = nil

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
-- 2. CONTROLADOR NUI Y SPAWN DE VEHÍCULOS MÉDICOS (FLEET COMMAND)
-- ============================================================================

local function OpenEmsGarageNUI(stationKey, stationData, isHelipad)
    local pState = LocalPlayer.state
    if pState.job ~= Config.JobName then
        lib.notify({
            title = 'Parque Móvil EMS',
            description = 'Acceso reservado a personal médico y sanitario.',
            type = 'error'
        })
        return
    end

    if not pState.job_duty then
        lib.notify({
            title = 'Parque Móvil EMS',
            description = 'Debes entrar EN SERVICIO para solicitar un vehículo de emergencias.',
            type = 'error'
        })
        return
    end

    local grade = pState.job_grade or 0
    local doctorName = pState.name or 'Personal Médico'

    if isHelipad then
        currentStationSpawn = stationData.helipad.spawn
    else
        currentStationSpawn = stationData.garage.spawn
    end

    local vehiclesList = isHelipad and (Config.Helicopters or {}) or (Config.Vehicles or {})

    TriggerScreenblurFadeIn(350)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openEmsGarage',
        vehicles = vehiclesList,
        doctorGrade = grade,
        doctorName = doctorName,
        stationName = stationData.label or 'Hospital General EMS'
    })
end

local function CloseEmsGarageNUI()
    SetNuiFocus(false, false)
    TriggerScreenblurFadeOut(350)
    SendNUIMessage({ action = 'closeEmsGarage' })
end

RegisterNUICallback('closeGarage', function(data, cb)
    CloseEmsGarageNUI()
    cb('ok')
end)

local function ReturnAndStoreEmsVehicle(veh)
    if not DoesEntityExist(veh) then return end

    -- Animación de guardado
    TaskLeaveVehicle(PlayerPedId(), veh, 0)
    Wait(1200)

    SetEntityAsMissionEntity(veh, true, true)
    DeleteVehicle(veh)

    if myEmsVehicle == veh then
        myEmsVehicle = nil
    end

    lib.notify({
        title = 'Garaje Sanitario',
        description = 'Vehículo de emergencias estacionado e inventariado con éxito.',
        type = 'success',
        icon = 'square-parking',
        duration = 5000
    })
end

RegisterNUICallback('storeVehicle', function(data, cb)
    CloseEmsGarageNUI()
    local ped = cache.ped or PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        ReturnAndStoreEmsVehicle(veh)
    else
        local nearbyVeh = lib.getClosestVehicle(GetEntityCoords(ped), 8.0, true)
        if nearbyVeh and DoesEntityExist(nearbyVeh) then
            ReturnAndStoreEmsVehicle(nearbyVeh)
        else
            lib.notify({ title = 'Garaje EMS', description = 'No hay ningún vehículo médico cercano para guardar.', type = 'error' })
        end
    end
    cb('ok')
end)

function SpawnEmsVehicle(modelName, customSpawn)
    local spawnCoords = customSpawn or currentStationSpawn
    if not spawnCoords then
        lib.notify({ title = 'Garaje EMS', description = 'Error al determinar el punto de salida del garaje.', type = 'error' })
        return
    end

    -- 1. Verificar si el punto de salida está bloqueado
    local spawnPos = vec3(spawnCoords.x, spawnCoords.y, spawnCoords.z)
    local blockingVeh = lib.getClosestVehicle(spawnPos, 3.5, true)
    if blockingVeh and DoesEntityExist(blockingVeh) then
        lib.notify({
            title = 'Punto de Salida Ocupado',
            description = 'Hay un vehículo bloqueando la zona de salida. Despeja el área antes de solicitar otro.',
            type = 'error'
        })
        return
    end

    -- 2. Cargar modelo
    local hash = joaat(modelName)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        lib.notify({ title = 'Garaje EMS', description = 'Modelo de vehículo inválido o no disponible.', type = 'error' })
        return
    end

    lib.requestModel(hash, 5000)

    local vehHeading = spawnCoords.w or 0.0
    local vehicle = CreateVehicle(hash, spawnCoords.x, spawnCoords.y, spawnCoords.z, vehHeading, true, false)

    if DoesEntityExist(vehicle) then
        SetEntityAsMissionEntity(vehicle, true, true)
        SetVehicleOnGroundProperly(vehicle)
        SetVehicleNumberPlateText(vehicle, "EMS " .. math.random(100, 999))
        SetVehicleColours(vehicle, 111, 111) -- Blanco puro
        SetVehicleLivery(vehicle, 0)
        SetVehicleEngineOn(vehicle, true, true, false)

        -- Poner al médico dentro del vehículo
        local ped = cache.ped or PlayerPedId()
        TaskWarpPedIntoVehicle(ped, vehicle, -1)

        myEmsVehicle = vehicle
        table.insert(SpawnedVehicles, vehicle)

        lib.notify({
            title = 'Parque Móvil EMS',
            description = string.format("Unidad de emergencias '%s' asignada y lista para el servicio.", modelName),
            type = 'success',
            icon = 'truck-medical',
            duration = 6000
        })
    end

    SetModelAsNoLongerNeeded(hash)
end

RegisterNUICallback('spawnVehicle', function(data, cb)
    CloseEmsGarageNUI()
    if data and data.model then
        SpawnEmsVehicle(data.model)
    end
    cb('ok')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    SetNuiFocus(false, false)
    TriggerScreenblurFadeOut(0)

    for _, prop in ipairs(SpawnedStationProps) do
        if DoesEntityExist(prop) then
            DeleteEntity(prop)
        end
    end
    SpawnedStationProps = {}
end)

-- ============================================================================
-- 3. REGISTRO DE TERMINALES FÍSICOS Y PUNTOS OX_TARGET EN HOSPITALES
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

        -- 3. GARAJE MÉDICO (TERMINAL FÍSICO CON OX_TARGET)
        if stationData.garage then
            local termCoords = stationData.garage.interact
            local termHeading = stationData.garage.heading or (termCoords.w) or 270.0
            local termModel = `prop_parkingpay`
            lib.requestModel(termModel, 5000)

            local terminalObj = CreateObject(termModel, termCoords.x, termCoords.y, termCoords.z - 0.95, false, false, false)
            if terminalObj ~= 0 and DoesEntityExist(terminalObj) then
                SetEntityHeading(terminalObj, termHeading + 0.0)
                PlaceObjectOnGroundProperly(terminalObj)
                FreezeEntityPosition(terminalObj, true)
                SetEntityInvincible(terminalObj, true)
                table.insert(SpawnedStationProps, terminalObj)

                -- Registrar ox_target directamente sobre el terminal físico
                exports.ox_target:addLocalEntity(terminalObj, {
                    {
                        name = 'aura_ems_garage_' .. stationKey,
                        icon = 'fa-solid fa-truck-medical',
                        label = 'Garaje Médico (Flota EMS)',
                        distance = 3.0,
                        canInteract = function()
                            local pState = LocalPlayer.state
                            return pState.job == Config.JobName and pState.job_duty == true
                        end,
                        onSelect = function()
                            OpenEmsGarageNUI(stationKey, stationData, false)
                        end
                    }
                })
            else
                -- Fallback con zona esférica si no se creara el prop
                exports.ox_target:addSphereZone({
                    coords = vec3(termCoords.x, termCoords.y, termCoords.z),
                    radius = 2.0,
                    debug = Config.Debug,
                    options = {
                        {
                            name = 'aura_ems_garage_zone_' .. stationKey,
                            icon = 'fa-solid fa-truck-medical',
                            label = 'Garaje Médico (Flota EMS)',
                            distance = 3.0,
                            canInteract = function()
                                local pState = LocalPlayer.state
                                return pState.job == Config.JobName and pState.job_duty == true
                            end,
                            onSelect = function()
                                OpenEmsGarageNUI(stationKey, stationData, false)
                            end
                        }
                    }
                })
            end
        end

        -- 4. HELIPUERTO MEDEVAC
        if stationData.helipad then
            local heliCoords = stationData.helipad.interact
            exports.ox_target:addSphereZone({
                coords = vec3(heliCoords.x, heliCoords.y, heliCoords.z),
                radius = 2.5,
                debug = Config.Debug,
                options = {
                    {
                        name = 'aura_ems_helipad_' .. stationKey,
                        icon = 'fa-solid fa-helicopter',
                        label = 'Helipuerto Sanitario (Medevac Air Support)',
                        distance = 3.5,
                        canInteract = function()
                            local pState = LocalPlayer.state
                            return pState.job == Config.JobName and pState.job_duty == true
                        end,
                        onSelect = function()
                            OpenEmsGarageNUI(stationKey, stationData, true)
                        end
                    }
                }
            })
        end
    end
end)

