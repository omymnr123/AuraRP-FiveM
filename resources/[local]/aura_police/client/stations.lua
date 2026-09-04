-- ============================================================================
-- AURA POLICE: CLIENT STATIONS CONTROLLER
-- Armory Stashes, illenium-appearance Wardrobes, Evidence Locker & Garages
-- ============================================================================

local CivilianAppearanceBackup = nil
local IsWearingPoliceUniform = false
local SpawnedStationProps = {}

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
                        name = 'aura_police_armory_stash_' .. stationKey,
                        icon = 'fa-solid fa-boxes-stacked',
                        label = 'Abrir Almacén de Armería (Stash)',
                        distance = 2.8,
                        canInteract = function()
                            local pState = LocalPlayer.state
                            return pState.job == 'police' and (pState.job_grade or 0) >= (stationData.armory.minGrade or 1)
                        end,
                        onSelect = function()
                            local pState = LocalPlayer.state
                            if not pState.job_duty then
                                lib.notify({
                                    title = 'Armería Policial',
                                    description = 'Debes entrar EN SERVICIO para acceder al almacén de armería.',
                                    type = 'error'
                                })
                                return
                            end

                            exports.ox_inventory:openInventory('stash', stationData.armory.stashId)
                        end
                    },
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

        -- 4. GARAJE POLICIAL (TERMINAL FÍSICO CON OX_TARGET)
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

                -- Registrar ox_target únicamente sobre el objeto físico (1 solo tooltip con precisión 100%)
                exports.ox_target:addLocalEntity(terminalObj, {
                    {
                        name = 'aura_police_garage_' .. stationKey,
                        icon = 'fa-solid fa-car',
                        label = 'Garaje Policial (Flota LSPD)',
                        distance = 3.0,
                        canInteract = function()
                            local pState = LocalPlayer.state
                            return pState.job == 'police'
                        end,
                        onSelect = function()
                            OpenPoliceGarageNUI(stationKey, stationData, false)
                        end
                    }
                })
            else
                -- Fallback solo si por algún motivo no se creara el objeto
                exports.ox_target:addSphereZone({
                    coords = vec3(termCoords.x, termCoords.y, termCoords.z),
                    radius = 1.6,
                    debug = Config.Debug,
                    options = {
                        {
                            name = 'aura_police_garage_zone_' .. stationKey,
                            icon = 'fa-solid fa-car',
                            label = 'Garaje Policial (Flota LSPD)',
                            distance = 3.0,
                            canInteract = function()
                                local pState = LocalPlayer.state
                                return pState.job == 'police'
                            end,
                            onSelect = function()
                                OpenPoliceGarageNUI(stationKey, stationData, false)
                            end
                        }
                    }
                })
            end
        end

        -- 5. HELIPUERTO POLICIAL
        if stationData.helipad then
            local heliCoords = stationData.helipad.interact
            exports.ox_target:addSphereZone({
                coords = vec3(heliCoords.x, heliCoords.y, heliCoords.z),
                radius = 2.0,
                debug = Config.Debug,
                options = {
                    {
                        name = 'aura_police_helipad_' .. stationKey,
                        icon = 'fa-solid fa-helicopter',
                        label = 'Helipuerto Policial (Air-1 Support)',
                        distance = 3.0,
                        canInteract = function()
                            local pState = LocalPlayer.state
                            return pState.job == 'police'
                        end,
                        onSelect = function()
                            OpenPoliceGarageNUI(stationKey, stationData, true)
                        end
                    }
                }
            })
        end
    end
end

-- ============================================================================
-- 5. CONTROLADOR NUI Y SPAWN DE VEHÍCULOS POLICIALES
-- ============================================================================

local currentStationSpawn = nil
local myPoliceVehicle = nil

function OpenPoliceGarageNUI(stationKey, stationData, isHelipad)
    local pState = LocalPlayer.state
    if not pState.job_duty then
        lib.notify({
            title = 'Parque Móvil LSPD',
            description = 'Debes entrar EN SERVICIO para solicitar un vehículo de dotación.',
            type = 'error'
        })
        return
    end

    local grade = pState.job_grade or 0
    local officerName = pState.name or 'Oficial'

    if isHelipad then
        currentStationSpawn = stationData.helipad.spawn
    else
        currentStationSpawn = stationData.garage.spawn
    end

    local vehiclesList = isHelipad and (Config.Helicopters or {}) or (Config.Vehicles or {})

    TriggerScreenblurFadeIn(350)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openPoliceGarage',
        vehicles = vehiclesList,
        officerGrade = grade,
        officerName = officerName,
        stationName = stationData.label or 'Comisaría LSPD'
    })
end

local function ClosePoliceGarageNUI()
    SetNuiFocus(false, false)
    TriggerScreenblurFadeOut(350)
    SendNUIMessage({ action = 'closePoliceGarage' })
end

RegisterNUICallback('closeGarage', function(data, cb)
    ClosePoliceGarageNUI()
    cb('ok')
end)

RegisterNUICallback('storeVehicle', function(data, cb)
    ClosePoliceGarageNUI()
    local ped = cache.ped
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        ReturnAndStorePoliceVehicle(veh)
    else
        local nearbyVeh = lib.getClosestVehicle(GetEntityCoords(ped), 8.0, true)
        if nearbyVeh and DoesEntityExist(nearbyVeh) then
            ReturnAndStorePoliceVehicle(nearbyVeh)
        else
            lib.notify({ title = 'Garaje', description = 'No hay ningún vehículo policial cercano para guardar.', type = 'error' })
        end
    end
    cb('ok')
end)

RegisterNUICallback('spawnVehicle', function(data, cb)
    ClosePoliceGarageNUI()
    if data and data.model then
        SpawnPoliceVehicle(data.model)
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

function SpawnPoliceVehicle(model, customSpawn)
    local spawnCoords = customSpawn or currentStationSpawn
    if not spawnCoords then
        lib.notify({ title = 'Garaje', description = 'Error al determinar el punto de salida del garaje.', type = 'error' })
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
    local hash = joaat(model)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        lib.notify({ title = 'Garaje', description = 'Modelo de vehículo inválido o no disponible.', type = 'error' })
        return
    end

    lib.requestModel(hash, 8000)

    -- 3. Eliminar patrulla anterior si estaba en las inmediaciones
    if myPoliceVehicle and DoesEntityExist(myPoliceVehicle) then
        local dist = #(GetEntityCoords(myPoliceVehicle) - spawnPos)
        if dist < 60.0 then
            DeleteVehicle(myPoliceVehicle)
        end
    end

    -- 4. Crear vehículo
    local heading = spawnCoords.w or 90.0
    local veh = CreateVehicle(hash, spawnCoords.x, spawnCoords.y, spawnCoords.z, heading, true, false)
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetVehicleDirtLevel(veh, 0.0)
    SetVehicleEngineOn(veh, true, true, false)
    
    local plate = "LSPD " .. tostring(math.random(100, 999))
    SetVehicleNumberPlateText(veh, plate)

    -- 5. Vincular vehículo al oficial para control de cierre con tecla I
    myPoliceVehicle = veh
    Entity(veh).state:set('policeVehicle', true, true)
    Entity(veh).state:set('policeOwner', GetPlayerServerId(PlayerId()), true)
    SetVehicleDoorsLocked(veh, 1) -- Inicialmente abierto para el oficial

    -- 6. Teletransportar al oficial al asiento del conductor
    TaskWarpPedIntoVehicle(cache.ped, veh, -1)

    lib.notify({
        title = 'Parque Móvil LSPD',
        description = string.format('Patrulla [%s] asignada. Pulsa [I] para bloquear o desbloquear puertas.', plate),
        type = 'success'
    })
end

-- ============================================================================
-- 6. ZONAS DE DEVOLUCIÓN AUTOMÁTICA DE VEHÍCULOS (MRPD Y DEMÁS COMISARÍAS)
-- Auto-expulsa a todos los ocupantes/detenidos y guarda el vehículo
-- ============================================================================

function ReturnAndStorePoliceVehicle(veh)
    if not DoesEntityExist(veh) then return end

    -- 1. Expulsar a todos los ocupantes (conductor, copiloto y detenidos)
    local maxSeats = GetVehicleMaxNumberOfPassengers(veh)
    for seat = -1, maxSeats - 1 do
        local pedInSeat = GetPedInVehicleSeat(veh, seat)
        if pedInSeat ~= 0 and DoesEntityExist(pedInSeat) then
            TaskLeaveVehicle(pedInSeat, veh, 16)
        end
    end

    Wait(400)

    -- 2. Eliminar vehículo
    local plate = GetVehicleNumberPlateText(veh) or "LSPD"
    DeleteVehicle(veh)
    if myPoliceVehicle == veh then
        myPoliceVehicle = nil
    end

    lib.notify({
        title = 'Garaje LSPD',
        description = string.format('Patrulla [%s] devuelta y guardada correctamente.', plate),
        type = 'success'
    })
end

CreateThread(function()
    local showingReturnUI = false

    while true do
        local sleep = 1000
        local ped = cache.ped
        local inVehicle = IsPedInAnyVehicle(ped, false)

        if inVehicle then
            local veh = GetVehiclePedIsIn(ped, false)
            local isDriver = (GetPedInVehicleSeat(veh, -1) == ped)
            local pState = LocalPlayer.state
            local isCop = (pState.job == 'police' and pState.job_duty == true)

            if isDriver and isCop then
                local vehCoords = GetEntityCoords(veh)
                local inZone = false

                -- Recorrer puntos de retorno configurados
                for _, station in pairs(Config.Stations) do
                    if station.garage and station.garage.returns then
                        for _, rPoint in ipairs(station.garage.returns) do
                            local dist = #(vehCoords - rPoint)
                            if dist < 22.0 then
                                sleep = 0
                                -- Dibujar marcador cilíndrico / anillo con brillo de AuraRP
                                DrawMarker(
                                    25,
                                    rPoint.x, rPoint.y, rPoint.z - 0.95,
                                    0.0, 0.0, 0.0,
                                    0.0, 0.0, 0.0,
                                    3.8, 3.8, 0.8,
                                    0, 242, 254, 180,
                                    false, false, 2, false, nil, nil, false
                                )

                                if dist < 3.2 then
                                    inZone = true
                                    lib.showTextUI('[E] Devolver y Guardar Patrulla', {
                                        position = 'top-center',
                                        icon = 'fa-solid fa-square-parking',
                                        style = {
                                            borderRadius = 8,
                                            backgroundColor = 'rgba(8, 16, 32, 0.94)',
                                            color = '#00f2fe',
                                            border = '1px solid rgba(0, 242, 254, 0.5)'
                                        }
                                    })

                                    if IsControlJustPressed(0, 38) then -- Tecla E
                                        lib.hideTextUI()
                                        showingReturnUI = false
                                        ReturnAndStorePoliceVehicle(veh)
                                        Wait(1000)
                                    end
                                    break
                                end
                            end
                        end
                    end
                end

                if not inZone and showingReturnUI then
                    lib.hideTextUI()
                    showingReturnUI = false
                elseif inZone then
                    showingReturnUI = true
                end
            end
        else
            if showingReturnUI then
                lib.hideTextUI()
                showingReturnUI = false
            end
        end

        Wait(sleep)
    end
end)

-- ============================================================================
-- 7. BLOQUEO Y DESBLOQUEO DE PATRULLA CON LA TECLA "I"
-- Vincula el vehículo al oficial para cierre remoto/interno con luces y sonido
-- ============================================================================

local function TogglePoliceVehicleLock()
    local pState = LocalPlayer.state
    if not (pState.job == 'police' and pState.job_duty == true) then
        return
    end

    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local targetVeh = nil

    -- 1. Si está dentro del vehículo
    if IsPedInAnyVehicle(ped, false) then
        targetVeh = GetVehiclePedIsIn(ped, false)
    else
        -- 2. Si está cerca de su vehículo asignado o de un vehículo policial cercano
        if myPoliceVehicle and DoesEntityExist(myPoliceVehicle) and #(coords - GetEntityCoords(myPoliceVehicle)) <= 7.0 then
            targetVeh = myPoliceVehicle
        else
            local closest = lib.getClosestVehicle(coords, 6.0, true)
            if closest and DoesEntityExist(closest) then
                local vehClass = GetVehicleClass(closest)
                local plate = GetVehicleNumberPlateText(closest) or ""
                if vehClass == 18 or Entity(closest).state.policeVehicle or string.find(plate, "LSPD") then
                    targetVeh = closest
                end
            end
        end
    end

    if not targetVeh or not DoesEntityExist(targetVeh) then
        return
    end

    local currentLock = GetVehicleDoorLockStatus(targetVeh)
    local newLock = 1
    local isLocked = false

    if currentLock == 1 or currentLock == 0 then
        newLock = 2
        isLocked = true
    else
        newLock = 1
        isLocked = false
    end

    SetVehicleDoorsLocked(targetVeh, newLock)
    SetVehicleDoorsLockedForAllPlayers(targetVeh, isLocked)

    -- Animación de mando a distancia si está fuera
    if not IsPedInAnyVehicle(ped, false) then
        lib.requestAnimDict("anim@mp_player_intmenu@key_fob@")
        TaskPlayAnim(ped, "anim@mp_player_intmenu@key_fob@", "fob_click", 8.0, -8.0, 1000, 49, 0, false, false, false)
    end

    -- Destello de luces del vehículo
    CreateThread(function()
        SetVehicleLights(targetVeh, 2)
        Wait(140)
        SetVehicleLights(targetVeh, 0)
        Wait(100)
        SetVehicleLights(targetVeh, 2)
        Wait(140)
        SetVehicleLights(targetVeh, 0)
    end)

    PlaySoundFrontend(-1, "Beep_Red", "DLC_HEIST_HACKING_SNAKE_SOUNDS", true)

    local plate = GetVehicleNumberPlateText(targetVeh) or "LSPD"
    if isLocked then
        lib.notify({
            title = 'Seguridad LSPD',
            description = string.format('🔒 Patrulla [%s] BLOQUEADA.', plate),
            type = 'error'
        })
    else
        lib.notify({
            title = 'Seguridad LSPD',
            description = string.format('🔓 Patrulla [%s] DESBLOQUEADA.', plate),
            type = 'success'
        })
    end
end

RegisterCommand('police_vehlock', function()
    TogglePoliceVehicleLock()
end, false)

RegisterKeyMapping('police_vehlock', 'LSPD: Bloquear/Desbloquear Patrulla', 'keyboard', 'I')

-- ============================================================================
-- 8. APERTURA RÁPIDA CON TECLA "E" A PIE FRENTE AL TERMINAL DEL GARAJE
-- ============================================================================

CreateThread(function()
    local showingGaragePrompt = false
    local currentNearStation = nil
    local currentNearData = nil

    while true do
        local sleep = 1000
        local ped = cache.ped

        if not IsPedInAnyVehicle(ped, false) then
            local pState = LocalPlayer.state
            if pState.job == 'police' and pState.job_duty then
                local coords = GetEntityCoords(ped)
                local inRange = false

                for sKey, sData in pairs(Config.Stations) do
                    if sData.garage and sData.garage.interact then
                        local gInteract = sData.garage.interact
                        local dist = #(coords - vec3(gInteract.x, gInteract.y, gInteract.z))
                        if dist < 2.3 then
                            inRange = true
                            currentNearStation = sKey
                            currentNearData = sData
                            sleep = 0

                            if not showingGaragePrompt then
                                lib.showTextUI('[E] Abrir Garaje Policial | [ALT] Interactuar', {
                                    position = 'top-center',
                                    icon = 'fa-solid fa-car',
                                    style = {
                                        borderRadius = 8,
                                        backgroundColor = 'rgba(8, 16, 32, 0.94)',
                                        color = '#00f2fe',
                                        border = '1px solid rgba(0, 242, 254, 0.5)'
                                    }
                                })
                                showingGaragePrompt = true
                            end

                            if IsControlJustPressed(0, 38) then -- Tecla E
                                lib.hideTextUI()
                                showingGaragePrompt = false
                                OpenPoliceGarageNUI(currentNearStation, currentNearData, false)
                                Wait(1000)
                            end
                            break
                        end
                    end
                end

                if not inRange and showingGaragePrompt then
                    lib.hideTextUI()
                    showingGaragePrompt = false
                    currentNearStation = nil
                    currentNearData = nil
                end
            elseif showingGaragePrompt then
                lib.hideTextUI()
                showingGaragePrompt = false
            end
        elseif showingGaragePrompt then
            lib.hideTextUI()
            showingGaragePrompt = false
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    Wait(500)
    InitStationPoints()
end)
