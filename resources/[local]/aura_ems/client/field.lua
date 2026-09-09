-- ============================================================================
-- AURA EMS: CLIENT FIELD OPS & RESUSCITATION CONTROLLER
-- ox_target Interactions: Tourniquet Compression, Defib (DEA) Minigame & Scan
-- ============================================================================

local isDiagnosticOpen = false
local isCarrying = false
local carriedTarget = nil
local isDummyTarget = false

function SetDiagnosticFocus(state)
    isDiagnosticOpen = state
    SetNuiFocus(state, state)
end

CreateThread(function()
    while true do
        if isCarrying then
            Wait(0)
            local myPed = PlayerPedId()
            DisableControlAction(0, 21, true)  -- Sprint
            DisableControlAction(0, 22, true)  -- Jump
            DisableControlAction(0, 23, true)  -- Enter vehicle
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim
            DisableControlAction(0, 140, true) -- Melee
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)

            -- Pulsar [E] o [X] para soltar paciente
            if IsControlJustPressed(0, 38) or IsControlJustPressed(0, 73) then
                StopCarryingPatient()
            end

            if IsPedRagdoll(myPed) or IsEntityDead(myPed) or IsPedInAnyVehicle(myPed, true) then
                StopCarryingPatient()
            end
        else
            Wait(300)
        end
    end
end)

local function GetTargetPlayerServerId(entity)
    if not entity or not DoesEntityExist(entity) then return nil end
    local playerIndex = NetworkGetPlayerIndexFromPed(entity)
    if playerIndex and playerIndex ~= -1 then
        return GetPlayerServerId(playerIndex)
    end
    return nil
end

local function IsTargetPlayerDead(entity)
    local targetSrc = GetTargetPlayerServerId(entity)
    if not targetSrc then return false end
    local pState = Player(targetSrc).state
    if pState and pState.isDead == true then
        return true
    end
    if exports.aura_death and exports.aura_death.isPlayerDead then
        return exports.aura_death:isPlayerDead(targetSrc)
    end
    return false
end

-- ============================================================================
-- LÓGICA DE TRANSPORTE Y CARGA DE PACIENTES (FIREMAN CARRY)
-- ============================================================================

function StartCarryingPatient(targetSrc, targetPed)
    if isCarrying then return end
    local myPed = PlayerPedId()

    lib.requestAnimDict('missfinale_c2mcs_1', 3000)
    TaskPlayAnim(myPed, 'missfinale_c2mcs_1', 'fin_c2_mcs_1_camman', 8.0, -8.0, -1, 49, 0, false, false, false)

    isCarrying = true
    carriedTarget = targetSrc
    isDummyTarget = false

    TriggerServerEvent('aura_ems:server:carryTarget', targetSrc)

    lib.notify({
        title = 'Cargando Paciente',
        description = 'Transportando al paciente a hombros. Pulsa [E] o [X] para depositarlo en el suelo.',
        type = 'inform',
        icon = 'people-carry-box',
        duration = 5000
    })
end

function StartCarryingDummy(dummyPed)
    if isCarrying then return end
    local myPed = PlayerPedId()

    lib.requestAnimDict('missfinale_c2mcs_1', 3000)
    TaskPlayAnim(myPed, 'missfinale_c2mcs_1', 'fin_c2_mcs_1_camman', 8.0, -8.0, -1, 49, 0, false, false, false)

    lib.requestAnimDict('nm', 3000)
    AttachEntityToEntity(dummyPed, myPed, 0, 0.27, 0.15, 0.63, 0.5, 0.5, 0.0, false, false, false, false, 2, false)
    TaskPlayAnim(dummyPed, 'nm', 'firemans_carry', 8.0, -8.0, -1, 33, 0, false, false, false)

    isCarrying = true
    carriedTarget = dummyPed
    isDummyTarget = true

    lib.notify({
        title = 'Cargando Paciente Dummy',
        description = 'Transportando al simulador. Pulsa [E] o [X] para depositarlo en el suelo o camilla.',
        type = 'inform',
        icon = 'people-carry-box',
        duration = 5000
    })
end

function StopCarryingPatient()
    if not isCarrying then return end
    local myPed = PlayerPedId()
    ClearPedTasks(myPed)

    if isDummyTarget and carriedTarget and DoesEntityExist(carriedTarget) then
        DetachEntity(carriedTarget, true, false)
        PlaceObjectOnGroundProperly(carriedTarget)
        lib.requestAnimDict('dead', 2000)
        TaskPlayAnim(carriedTarget, 'dead', 'dead_d', 8.0, -8.0, -1, 1, 0, false, false, false)
    elseif carriedTarget then
        TriggerServerEvent('aura_ems:server:stopCarryTarget', carriedTarget)
    end

    isCarrying = false
    carriedTarget = nil
    isDummyTarget = false

    lib.notify({
        title = 'Paciente Depositado',
        description = 'Has soltado al paciente de manera segura.',
        type = 'inform',
        icon = 'person'
    })
end

function ToggleCarryPatient(targetEntity)
    if isCarrying then
        StopCarryingPatient()
        return
    end

    if not DoesEntityExist(targetEntity) then return end
    local targetSrc = GetTargetPlayerServerId(targetEntity)
    if targetSrc then
        StartCarryingPatient(targetSrc, targetEntity)
    else
        StartCarryingDummy(targetEntity)
    end
end


-- ============================================================================
-- 1. REGISTRO GLOBAL DE OX_TARGET EN JUGADORES
-- ============================================================================

CreateThread(function()
    exports.ox_target:addGlobalPlayer({
        -- 1. DIAGNÓSTICO Y CONSTANTES VITALES (FASE 11: AURA MEDICAL P2P)
        {
            name = 'aura_ems_diagnose_patient',
            icon = 'fa-solid fa-stethoscope',
            label = 'Diagnóstico y Constantes Vitales',
            distance = 2.5,
            canInteract = function(entity)
                local pState = LocalPlayer.state
                return pState.job == Config.JobName and pState.job_duty == true
            end,
            onSelect = function(data)
                local targetPed = data.entity
                if not DoesEntityExist(targetPed) then return end

                local targetSrc = GetTargetPlayerServerId(targetPed)
                if not targetSrc then
                    lib.notify({ title = 'Diagnóstico', description = 'No se ha podido identificar al paciente.', type = 'error' })
                    return
                end

                local myPed = PlayerPedId()
                TaskTurnPedToFaceEntity(myPed, targetPed, 800)

                -- 1. Notificar al servidor para abrir la interfaz del paciente
                TriggerServerEvent('aura_medical:server:requestPatientTelemetry', targetSrc)

                -- 2. Iniciar barra de progreso en el médico
                CreateThread(function()
                    exports.aura_progress:Start(
                        'Estableciendo telemetría...',
                        10000,
                        true,
                        true,
                        { dict = 'amb@medic@standing@kneel@base', clip = 'base', flag = 1 }
                    )
                end)
            end
        },

        -- 2. CARGAR / SOLTAR PACIENTE
        {
            name = 'aura_ems_carry_patient',
            icon = 'fa-solid fa-people-carry-box',
            label = 'Cargar/Soltar Paciente',
            distance = 2.5,
            canInteract = function(entity)
                local pState = LocalPlayer.state
                if pState.job ~= Config.JobName or pState.job_duty ~= true then return false end
                if isCarrying then return true end
                return IsTargetPlayerDead(entity) or (GetEntityHealth(entity) < 150)
            end,
            onSelect = function(data)
                ToggleCarryPatient(data.entity)
            end
        }
    })

    -- ========================================================================
    -- 2. REGISTRO DE OX_TARGET EN VEHÍCULOS MÉDICOS / AMBULANCIAS (CAMILLA)
    -- ========================================================================
    exports.ox_target:addGlobalVehicle({
        -- Subir Paciente a la Camilla / Ambulancia
        {
            name = 'aura_ems_put_stretcher',
            icon = 'fa-solid fa-bed-pulse',
            label = 'Subir Paciente a Camilla / Ambulancia',
            distance = 4.0,
            canInteract = function(entity)
                local pState = LocalPlayer.state
                if pState.job ~= Config.JobName or pState.job_duty ~= true then return false end
                local model = GetEntityModel(entity)
                local isAmbulance = (model == `ambulance` or model == `granger2` or model == `polalamo` or GetVehicleClass(entity) == 18)
                if not isAmbulance then return false end
                return isCarrying
            end,
            onSelect = function(data)
                PutPatientInAmbulance(data.entity)
            end
        },

        -- Bajar Paciente de la Camilla / Ambulancia
        {
            name = 'aura_ems_out_stretcher',
            icon = 'fa-solid fa-person-walking-arrow-right',
            label = 'Bajar Paciente de Camilla / Ambulancia',
            distance = 4.0,
            canInteract = function(entity)
                local pState = LocalPlayer.state
                if pState.job ~= Config.JobName or pState.job_duty ~= true then return false end
                local model = GetEntityModel(entity)
                local isAmbulance = (model == `ambulance` or model == `granger2` or model == `polalamo` or GetVehicleClass(entity) == 18)
                if not isAmbulance then return false end
                for seat = 1, 2 do
                    local pedInSeat = GetPedInVehicleSeat(entity, seat)
                    if DoesEntityExist(pedInSeat) and pedInSeat ~= PlayerPedId() then
                        return true
                    end
                end
                return false
            end,
            onSelect = function(data)
                OutPatientFromAmbulance(data.entity)
            end
        }
    })
end)

-- ============================================================================
-- FUNCIONES DE CAMILLA Y SUBIDA / BAJADA DE VEHÍCULOS MÉDICOS
-- ============================================================================

function PutPatientInAmbulance(vehicle)
    if not DoesEntityExist(vehicle) then return end
    if not isCarrying then
        lib.notify({ title = 'Camilla', description = 'Debes estar cargando al paciente para subirlo a la camilla.', type = 'error' })
        return
    end

    local targetSeat = 1
    if not IsVehicleSeatFree(vehicle, 1) then
        if IsVehicleSeatFree(vehicle, 2) then
            targetSeat = 2
        else
            lib.notify({ title = 'Camilla Ocupada', description = 'Todos los puestos de camilla traseros están ocupados.', type = 'error' })
            return
        end
    end

    local vehNet = NetworkGetNetworkIdFromEntity(vehicle)

    if isDummyTarget and carriedTarget and DoesEntityExist(carriedTarget) then
        local dummyPed = carriedTarget
        StopCarryingPatient()
        TaskWarpPedIntoVehicle(dummyPed, vehicle, targetSeat)
        lib.notify({ title = 'Camilla Médica', description = 'Has asegurado al paciente en la camilla de la ambulancia.', type = 'success', icon = 'bed-pulse' })
    elseif carriedTarget then
        local targetSrc = carriedTarget
        StopCarryingPatient()
        TriggerServerEvent('aura_ems:server:putInAmbulance', vehNet, targetSrc, targetSeat)
        lib.notify({ title = 'Camilla Médica', description = 'Has asegurado al paciente en la camilla de la unidad médica.', type = 'success', icon = 'bed-pulse' })
    end
end

function OutPatientFromAmbulance(vehicle)
    if not DoesEntityExist(vehicle) then return end

    local targetPed = nil
    for seat = 1, 2 do
        local ped = GetPedInVehicleSeat(vehicle, seat)
        if DoesEntityExist(ped) and ped ~= PlayerPedId() then
            targetPed = ped
            break
        end
    end

    if not targetPed then
        lib.notify({ title = 'Camilla Vacía', description = 'No hay pacientes en los puestos de camilla.', type = 'inform' })
        return
    end

    local targetSrc = GetTargetPlayerServerId(targetPed)
    if targetSrc then
        local vehNet = NetworkGetNetworkIdFromEntity(vehicle)
        TriggerServerEvent('aura_ems:server:outOfAmbulance', vehNet, targetSrc)
        Wait(500)
        StartCarryingPatient(targetSrc, targetPed)
    else
        TaskLeaveVehicle(targetPed, vehicle, 0)
        Wait(600)
        StartCarryingDummy(targetPed)
    end
end

-- ============================================================================
-- EVENTOS DE RED DE CLIENTE: CARGA Y CAMILLAS (SINCRONIZACIÓN)
-- ============================================================================

RegisterNetEvent('aura_ems:client:getCarried', function(carrierSrc)
    local carrierPed = GetPlayerPed(GetPlayerFromServerId(carrierSrc))
    local myPed = PlayerPedId()

    if DoesEntityExist(carrierPed) then
        lib.requestAnimDict('nm', 3000)
        AttachEntityToEntity(myPed, carrierPed, 0, 0.27, 0.15, 0.63, 0.5, 0.5, 0.0, false, false, false, false, 2, false)
        TaskPlayAnim(myPed, 'nm', 'firemans_carry', 8.0, -8.0, -1, 33, 0, false, false, false)
    end
end)

RegisterNetEvent('aura_ems:client:getReleased', function()
    local myPed = PlayerPedId()
    DetachEntity(myPed, true, false)
    ClearPedTasksImmediately(myPed)

    local isDead = LocalPlayer.state.isDead
    if isDead then
        lib.requestAnimDict('dead', 2000)
        TaskPlayAnim(myPed, 'dead', 'dead_d', 8.0, -8.0, -1, 1, 0, false, false, false)
    end
end)

RegisterNetEvent('aura_ems:client:putInAmbulanceSeat', function(vehNet, seatIndex)
    local vehicle = NetworkGetEntityFromNetworkId(vehNet)
    if DoesEntityExist(vehicle) then
        local myPed = PlayerPedId()
        DetachEntity(myPed, true, false)
        ClearPedTasksImmediately(myPed)
        TaskWarpPedIntoVehicle(myPed, vehicle, seatIndex or 1)
        lib.notify({ title = 'Unidad Médica', description = 'Has sido colocado en la camilla de la ambulancia.', type = 'inform', icon = 'bed-pulse' })
    end
end)

RegisterNetEvent('aura_ems:client:leaveAmbulanceSeat', function()
    local myPed = PlayerPedId()
    local veh = GetVehiclePedIsIn(myPed, false)
    if DoesEntityExist(veh) then
        TaskLeaveVehicle(myPed, veh, 0)
    end
end)

-- ============================================================================
-- NUI CALLBACKS: DIAGNÓSTICO CLÍNICO AVANZADO
-- ============================================================================

RegisterNUICallback('closeDiagnosticModal', function(_, cb)
    SetDiagnosticFocus(false)
    cb(true)
end)

RegisterNUICallback('applyTourniquetFromModal', function(data, cb)
    local targetSrc = tonumber(data.targetSrc)
    local dummyId = tonumber(data.dummyId)

    -- Verificación estricta de servicio oficial (EMS Duty)
    local pState = LocalPlayer.state
    if pState.job ~= Config.JobName or pState.job_duty ~= true then
        cb({ success = false, message = "Debes estar de servicio como personal médico (EMS)." })
        return
    end

    -- Verificación estricta de ítem de inventario (Torniquete)
    local hasTourniquet = false
    if exports.ox_inventory then
        hasTourniquet = (exports.ox_inventory:Search('count', Config.FieldOps.tourniquet.item) or 0) > 0
    else
        hasTourniquet = true
    end

    if not hasTourniquet then
        cb({ success = false, message = "No dispones de un Torniquete Táctico C-A-T en tu inventario." })
        return
    end

    if dummyId and ApplyTourniquetToDummy then
        local success, msg = ApplyTourniquetToDummy(dummyId)
        cb({ success = success, message = msg })
        return
    end

    if not targetSrc or targetSrc <= 0 then
        cb({ success = false, message = "Paciente no válido." })
        return
    end

    -- Animación de colocación de torniquete
    local myPed = PlayerPedId()
    lib.requestAnimDict(Config.FieldOps.tourniquet.animDict, 3000)
    TaskPlayAnim(myPed, Config.FieldOps.tourniquet.animDict, Config.FieldOps.tourniquet.animClip, 8.0, -8.0, 3500, 49, 0, false, false, false)

    lib.callback('aura_ems:server:applyTourniquet', false, function(ok, msg)
        ClearPedTasks(myPed)
        cb({ success = ok, message = msg })
    end, targetSrc)
end)

RegisterNUICallback('useDefibFromModal', function(data, cb)
    local targetSrc = tonumber(data.targetSrc)
    local dummyId = tonumber(data.dummyId)

    -- Verificación estricta de servicio oficial (EMS Duty)
    local pState = LocalPlayer.state
    if pState.job ~= Config.JobName or pState.job_duty ~= true then
        cb({ success = false, message = "Debes estar de servicio como personal médico (EMS)." })
        return
    end

    -- Verificación estricta de ítem de inventario (Desfibrilador DEA)
    local hasDefib = false
    if exports.ox_inventory then
        hasDefib = (exports.ox_inventory:Search('count', Config.FieldOps.defib.item) or 0) > 0
    else
        hasDefib = true
    end

    if not hasDefib then
        cb({ success = false, message = "No dispones de un Desfibrilador (DEA) en tu inventario." })
        return
    end

    if dummyId and UseDefibOnDummy then
        local ok, msg = UseDefibOnDummy(dummyId)
        cb({ success = ok, message = msg })
        return
    end

    if not targetSrc or targetSrc <= 0 then
        cb({ success = false, message = "Paciente no válido." })
        return
    end

    -- Ejecutar protocolo DEA en el campo
    local myPed = PlayerPedId()
    lib.requestAnimDict('mini@cpr@char_a@cpr_str', 3000)
    TaskPlayAnim(myPed, 'mini@cpr@char_a@cpr_str', 'cpr_pumpchest', 8.0, -8.0, -1, 1, 0, false, false, false)

    local minigameSuccess = false
    if exports.aura_minigames and exports.aura_minigames.StartDefib then
        minigameSuccess = exports.aura_minigames:StartDefib(Config.FieldOps.defib.minigameOptions)
    else
        minigameSuccess = lib.skillCheck({'medium', 'medium'}, {'e'})
    end

    ClearPedTasks(myPed)

    if minigameSuccess then
        lib.requestAnimDict('mini@cpr@char_a@cpr_str', 2000)
        TaskPlayAnim(myPed, 'mini@cpr@char_a@cpr_str', 'cpr_success', 8.0, -8.0, 2000, 0, 0, false, false, false)

        lib.callback('aura_ems:server:resuscitatePatient', false, function(ok, msg)
            if ok then
                local healthyBones = {
                    head = { health = 100, injuries = {} },
                    torso = { health = 100, injuries = {} },
                    right_arm = { health = 100, injuries = {} },
                    left_arm = { health = 100, injuries = {} },
                    right_hand = { health = 100, injuries = {} },
                    left_hand = { health = 100, injuries = {} },
                    right_leg = { health = 100, injuries = {} },
                    left_leg = { health = 100, injuries = {} },
                    right_foot = { health = 100, injuries = {} },
                    left_foot = { health = 100, injuries = {} }
                }

                SendNUIMessage({
                    action = 'updateDiagnosticVitals',
                    patient = {
                        targetSrc = targetSrc,
                        isDead = false,
                        hasPulse = true,
                        bpm = 78,
                        bloodPressure = "120/80 mmHg",
                        spo2 = 98,
                        health = 100,
                        glasgow = 15,
                        bleedingLevel = "Estable / Sin Hemorragias",
                        boneDamage = healthyBones
                    }
                })
            end
            cb({ success = ok, message = msg })
        end, targetSrc)
    else
        cb({ success = false, message = "Descarga desfibrilador fallida o no sincronizada." })
    end
end)


