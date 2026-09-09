-- ============================================================================
-- AURA MEDICAL: CLIENT INTERACTION & P2P TELEMETRY SYNC (PHASE 11)
-- ============================================================================

local isUIOpen = false
local currentMode = nil -- 'patient' o 'ems'
local activeMedicSrc = nil
local activePatientSrc = nil
local AdminDummies = {}

--- Control de foco NUI seguro
local function SetMedicalNuiFocus(state)
    isUIOpen = state
    SetNuiFocus(state, state)
end

local function GetTargetPlayerServerId(entity)
    if not entity or not DoesEntityExist(entity) then return nil end
    local playerIndex = NetworkGetPlayerIndexFromPed(entity)
    if playerIndex and playerIndex ~= -1 then
        return GetPlayerServerId(playerIndex)
    end
    return nil
end

-- ============================================================================
-- 1. REGISTRO OX_TARGET EN JUGADORES (DIAGNÓSTICO Y CONSTANTES VITALES)
-- ============================================================================
CreateThread(function()
    -- Si aura_ems ya gestiona la entrada de ox_target, omitir registro redundante
    if GetResourceState('aura_ems') == 'started' or GetResourceState('aura_ems') == 'starting' then
        return
    end

    exports.ox_target:addGlobalPlayer({
        {
            name = 'aura_medical_diagnose',
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
                if not targetSrc or targetSrc <= 0 then
                    lib.notify({
                        title = 'Diagnóstico Médico',
                        description = 'No se ha detectado el identificador del paciente.',
                        type = 'error'
                    })
                    return
                end

                activePatientSrc = targetSrc
                local myPed = PlayerPedId()
                TaskTurnPedToFaceEntity(myPed, targetPed, 800)

                -- 1. Notificar al servidor para abrir la interfaz del paciente
                TriggerServerEvent('aura_medical:server:requestPatientTelemetry', targetSrc)

                -- 2. Iniciar barra de progreso en el médico
                CreateThread(function()
                    local progressSuccess = exports.aura_progress:Start(
                        'Estableciendo telemetría...',
                        10000,
                        true,
                        true,
                        { dict = 'amb@medic@standing@kneel@base', clip = 'base', flag = 1 }
                    )

                    -- Si se canceló la barra manualmente y la UI no se ha abierto, avisar
                    if not progressSuccess and not isUIOpen then
                        TriggerServerEvent('aura_medical:server:cancelTelemetry', targetSrc)
                        lib.notify({
                            title = 'Diagnóstico Cancelado',
                            description = 'Has interrumpido la lectura diagnóstica.',
                            type = 'inform'
                        })
                    end
                end)
            end
        }
    })
end)

-- ============================================================================
-- 2. EVENTOS DE CLIENTE: VISTA DEL PACIENTE (INPUT NUI)
-- ============================================================================

RegisterNetEvent('aura_medical:client:openPatientInput', function(medicSrc, initialBpm)
    activeMedicSrc = medicSrc
    currentMode = 'patient'

    local myPed = PlayerPedId()
    local model = GetEntityModel(myPed)
    local isMale = (model == `mp_m_freemode_01` or IsPedMale(myPed))

    SetMedicalNuiFocus(true)
    SendNUIMessage({
        action = 'openPatientView',
        medicSrc = medicSrc,
        isMale = isMale,
        patientName = GetPlayerName(PlayerId()),
        zones = Config.Zones,
        injuryTypes = Config.InjuryTypes,
        initialBpm = initialBpm or (LocalPlayer.state.isDead and 40 or 75)
    })
end)

-- ============================================================================
-- 3. EVENTOS DE CLIENTE: VISTA DEL MÉDICO (TREATMENT NUI)
-- ============================================================================

RegisterNetEvent('aura_medical:client:openEmsTreatment', function(payload)
    -- Si la barra de progreso de telemetría está activa, cancelarla inmediatamente
    if exports.aura_progress and exports.aura_progress.IsActive and exports.aura_progress:IsActive() then
        exports.aura_progress:Cancel()
    end

    currentMode = 'ems'
    activePatientSrc = payload.patientSrc

    SetMedicalNuiFocus(true)
    SendNUIMessage({
        action = 'openEmsView',
        data = payload,
        zones = Config.Zones,
        injuryTypes = Config.InjuryTypes,
        medications = Config.Medications,
        finalProcedures = Config.FinalProcedures,
        stableBpmRange = Config.StableBpmRange
    })
end)

-- ============================================================================
-- 4. SINCRONIZACIÓN EN TIEMPO REAL P2P (EVENTOS BROADCAST)
-- ============================================================================

RegisterNetEvent('aura_medical:client:syncTreatmentApplied', function(syncData)
    SendNUIMessage({
        action = 'syncTreatmentApplied',
        zone = syncData.zone,
        injuryId = syncData.injuryId,
        remainingInjuries = syncData.remainingInjuries,
        allInjuries = syncData.allInjuries,
        allCured = syncData.allCured,
        bpm = syncData.bpm,
        medicName = syncData.medicName
    })

    -- Si estamos tratando un dummy de pruebas, sincronizar su tabla de lesiones local
    if activePatientSrc and type(activePatientSrc) == "string" then
        local dummyIdNum = tonumber(string.match(activePatientSrc, "%d+"))
        for _, d in ipairs(AdminDummies) do
            if not dummyIdNum or d.id == dummyIdNum then
                d.injuries = syncData.allInjuries or {}
                d.bpm = syncData.bpm or d.bpm
            end
        end
    end
end)

RegisterNetEvent('aura_medical:client:syncBpmUpdated', function(syncData)
    SendNUIMessage({
        action = 'syncBpmUpdated',
        bpm = syncData.bpm,
        medicationLabel = syncData.medicationLabel,
        allCured = syncData.allCured,
        isStable = syncData.isStable
    })

    if activePatientSrc and type(activePatientSrc) == "string" then
        local dummyIdNum = tonumber(string.match(activePatientSrc, "%d+"))
        for _, d in ipairs(AdminDummies) do
            if not dummyIdNum or d.id == dummyIdNum then
                d.bpm = syncData.bpm or d.bpm
            end
        end
    end
end)

RegisterNetEvent('aura_medical:client:closeMedicalUI', function()
    SetMedicalNuiFocus(false)
    SendNUIMessage({
        action = 'forceClose'
    })
    currentMode = nil
    activeMedicSrc = nil
    activePatientSrc = nil
end)

-- ============================================================================
-- 5. NUI CALLBACKS (PUENTES JS -> LUA)
-- ============================================================================

RegisterNUICallback('submitPatientDiagnosis', function(data, cb)
    TriggerServerEvent('aura_medical:server:sendDiagnosisToMedic', data)
    cb(true)
end)

RegisterNUICallback('applyTreatment', function(data, cb)
    local myPed = PlayerPedId()
    lib.requestAnimDict('amb@medic@standing@kneel@base', 2000)
    TaskPlayAnim(myPed, 'amb@medic@standing@kneel@base', 'base', 8.0, -8.0, 2000, 1, 0, false, false, false)

    TriggerServerEvent('aura_medical:server:applyTreatment', {
        patientSrc = activePatientSrc,
        zone = data.zone,
        injuryId = data.injuryId
    })
    cb(true)
end)

RegisterNUICallback('injectMedication', function(data, cb)
    local myPed = PlayerPedId()
    lib.requestAnimDict('amb@medic@standing@kneel@base', 2000)
    TaskPlayAnim(myPed, 'amb@medic@standing@kneel@base', 'base', 8.0, -8.0, 1500, 1, 0, false, false, false)

    TriggerServerEvent('aura_medical:server:adjustBpm', {
        patientSrc = activePatientSrc,
        medication = data.medication
    })
    cb(true)
end)

RegisterNUICallback('applyTourniquetFinal', function(data, cb)
    local myPed = PlayerPedId()
    lib.requestAnimDict('amb@medic@standing@kneel@base', 3000)
    TaskPlayAnim(myPed, 'amb@medic@standing@kneel@base', 'base', 8.0, -8.0, 3500, 1, 0, false, false, false)

    TriggerServerEvent('aura_medical:server:applyTourniquetFinal', {
        patientSrc = activePatientSrc
    })
    cb(true)
end)

RegisterNUICallback('useDefibFinal', function(data, cb)
    local myPed = PlayerPedId()
    lib.requestAnimDict('mini@cpr@char_a@cpr_str', 3000)
    TaskPlayAnim(myPed, 'mini@cpr@char_a@cpr_str', 'cpr_pumpchest', 8.0, -8.0, -1, 1, 0, false, false, false)

    local minigameSuccess = false
    if exports.aura_minigames and exports.aura_minigames.StartDefib then
        minigameSuccess = exports.aura_minigames:StartDefib({ difficulty = 'medium' })
    else
        minigameSuccess = lib.skillCheck({'medium', 'medium'}, {'e'})
    end

    ClearPedTasks(myPed)

    if minigameSuccess then
        lib.requestAnimDict('mini@cpr@char_a@cpr_str', 2000)
        TaskPlayAnim(myPed, 'mini@cpr@char_a@cpr_str', 'cpr_success', 8.0, -8.0, 2000, 0, 0, false, false, false)

        TriggerServerEvent('aura_medical:server:useDefibFinal', {
            patientSrc = activePatientSrc
        })
        cb({ success = true })
    else
        lib.notify({
            title = 'Descarga Fallida',
            description = 'No se ha sincronizado correctamente la descarga DEA. Vuelve a intentarlo.',
            type = 'error'
        })
        cb({ success = false })
    end
end)

RegisterNUICallback('closeUI', function(_, cb)
    SetMedicalNuiFocus(false)
    if currentMode == 'ems' and activePatientSrc then
        TriggerServerEvent('aura_medical:server:closeSession', activePatientSrc)
    elseif currentMode == 'patient' and activeMedicSrc then
        TriggerServerEvent('aura_medical:server:cancelTelemetry', activeMedicSrc)
    end
    currentMode = nil
    activeMedicSrc = nil
    activePatientSrc = nil
    cb(true)
end)

-- ============================================================================
-- 5.5 REANIMACIÓN DE DUMMIES TRAS DESCARGA DEA EXITOSA
-- ============================================================================

RegisterNetEvent('aura_medical:client:reviveDummy', function(dummyKey)
    local dummyIdNum = tonumber(string.match(tostring(dummyKey), "%d+"))
    for _, d in ipairs(AdminDummies) do
        if not dummyIdNum or d.id == dummyIdNum then
            d.bpm = 75
            d.injuries = {
                head = {}, torso = {},
                right_arm = {}, left_arm = {},
                right_hand = {}, left_hand = {},
                right_leg = {}, left_leg = {},
                right_foot = {}, left_foot = {}
            }
            d.isRevived = true
            if DoesEntityExist(d.ped) then
                ClearPedTasksImmediately(d.ped)
                ClearPedBloodDamage(d.ped)
                ResetPedVisibleDamage(d.ped)
                SetEntityHealth(d.ped, 200)
                
                lib.requestAnimDict('mini@cpr@char_b@cpr_str', 3000)
                TaskPlayAnim(d.ped, 'mini@cpr@char_b@cpr_str', 'cpr_success', 8.0, -8.0, 3500, 0, 0, false, false, false)
                SetTimeout(3500, function()
                    if DoesEntityExist(d.ped) then
                        ClearPedTasks(d.ped)
                        TaskStartScenarioInPlace(d.ped, "WORLD_HUMAN_STAND_IMPARTIAL", 0, true)
                    end
                end)
            end
        end
    end
end)

-- Tecla ESC / control de cierre seguro
RegisterCommand('closemedicalui', function()
    if isUIOpen then
        SetMedicalNuiFocus(false)
        SendNUIMessage({ action = 'forceClose' })
    end
end, false)

-- ============================================================================
-- 6. ADMIN & DEVELOPER TESTING SUITE (PHASE 11: SOLO TESTING - 10 ZONAS)
-- ============================================================================

--- Casos clínicos predefinidos para pruebas del administrador (10 zonas anatómicas)
local TestCases = {
    case1 = {
        title = "Caso 1: Politraumatismo Balístico (Grave)",
        desc = "Heridas de bala en tórax y cabeza, hemorragia activa, bradicardia.",
        bpm = 38,
        injuries = {
            head = { "bullet", "contusion" },
            torso = { "bullet", "puncture" },
            right_arm = { "scratch" },
            left_arm = {},
            right_hand = {},
            left_hand = {},
            right_leg = { "muscle_tear" },
            left_leg = {},
            right_foot = {},
            left_foot = { "sprain" }
        }
    },
    case2 = {
        title = "Caso 2: Atropello Vehicular & Quemaduras",
        desc = "Fracturas óseas en piernas, quemaduras en tronco y esguinces.",
        bpm = 155,
        injuries = {
            head = { "contusion" },
            torso = { "burn", "contusion" },
            right_arm = { "bone_break" },
            left_arm = {},
            right_hand = { "burn" },
            left_hand = {},
            right_leg = { "bone_break", "sprain" },
            left_leg = { "contusion" },
            right_foot = { "sprain" },
            left_foot = {}
        }
    },
    case3 = {
        title = "Caso 3: Parada Cardiorrespiratoria / Asistolia (0 BPM)",
        desc = "Paciente en coma clínico, sin pulso, trauma torácico severo.",
        bpm = 0,
        injuries = {
            head = {},
            torso = { "puncture", "contusion" },
            right_arm = { "scratch" },
            left_arm = {},
            right_hand = {},
            left_hand = {},
            right_leg = { "contusion" },
            left_leg = {},
            right_foot = {},
            left_foot = {}
        }
    },
    case4 = {
        title = "Caso 4: Trauma Multizonal Complejo (10 Zonas)",
        desc = "Lesiones en extremidades y tronco para pruebas exhaustivas.",
        bpm = 52,
        injuries = {
            head = { "contusion", "scratch" },
            torso = { "bullet" },
            right_arm = { "bone_break" },
            left_arm = { "scratch" },
            right_hand = { "puncture" },
            left_hand = {},
            right_leg = { "muscle_tear" },
            left_leg = { "bone_break" },
            right_foot = { "sprain" },
            left_foot = { "contusion" }
        }
    }
}

--- Función para spawnear un NPC Dummy de pruebas
local function SpawnAdminTestDummy(isMale, caseKey)
    local myPed = PlayerPedId()
    local coords = GetEntityCoords(myPed)
    local forward = GetEntityForwardVector(myPed)
    local spawnCoords = coords + (forward * 1.6)
    local heading = (GetEntityHeading(myPed) + 180.0) % 360.0

    local modelHash = isMale and `a_m_m_skater_01` or `a_f_y_fitness_01`
    lib.requestModel(modelHash, 5000)

    local dummyPed = CreatePed(4, modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z - 0.95, heading, true, false)
    SetEntityAsMissionEntity(dummyPed, true, true)
    SetBlockingOfNonTemporaryEvents(dummyPed, true)
    SetPedCanRagdollFromPlayerImpact(dummyPed, false)
    SetPedFleeAttributes(dummyPed, 0, false)
    SetPedCombatAttributes(dummyPed, 17, true)
    SetEntityHealth(dummyPed, 105)

    ApplyPedDamagePack(dummyPed, "Fall", 100.0, 100.0)
    ApplyPedDamagePack(dummyPed, "Explosion_Med", 50.0, 50.0)

    lib.requestAnimDict('dead', 3000)
    TaskPlayAnim(dummyPed, 'dead', 'dead_d', 8.0, -8.0, -1, 1, 0, false, false, false)

    local dummyId = #AdminDummies + 1
    local chosenCase = TestCases[caseKey] or TestCases.case1

    local dummyData = {
        id = dummyId,
        ped = dummyPed,
        isMale = isMale,
        bpm = chosenCase.bpm,
        injuries = json.decode(json.encode(chosenCase.injuries)),
        caseTitle = chosenCase.title
    }

    table.insert(AdminDummies, dummyData)

    -- Registrar ox_target en el Dummy
    exports.ox_target:addLocalEntity(dummyPed, {
        {
            name = 'admin_dummy_diag_' .. dummyId,
            icon = 'fa-solid fa-stethoscope',
            label = 'Diagnóstico y Constantes Vitales',
            distance = 2.5,
            onSelect = function()
                local myP = PlayerPedId()
                TaskTurnPedToFaceEntity(myP, dummyPed, 800)

                CreateThread(function()
                    local progressSuccess = exports.aura_progress:Start(
                        'Estableciendo telemetría diagnóstica...',
                        3000,
                        true,
                        true,
                        { dict = 'amb@medic@standing@kneel@base', clip = 'base', flag = 1 }
                    )

                    if progressSuccess then
                        TriggerServerEvent('aura_medical:server:startDummySession', {
                            dummyId = dummyId,
                            isMale = dummyData.isMale,
                            patientName = string.format("Paciente Dummy #%d (Simulación)", dummyId),
                            bpm = dummyData.bpm or 75,
                            injuries = dummyData.injuries or {}
                        })
                    end
                end)
            end
        }
    })

    lib.notify({
        title = 'Paciente Dummy Creado',
        description = string.format('Dummy #%d generado con "%s". Acércate y usa ox_target (ALT).', dummyId, chosenCase.title),
        type = 'success',
        icon = 'user-injured',
        duration = 7000
    })
end

--- Menú interactivo de administración
local function OpenAdminMedicalMenu()
    lib.registerContext({
        id = 'aura_medical_admin_hub',
        title = '🏥 Admin Suite // Aura Medical P2P',
        options = {
            {
                title = '🩺 Probar Vista Paciente (Selección Manual)',
                description = 'Abre la interfaz del paciente en tu pantalla para elegir silueta, marcar lesiones y ajustar BPM.',
                icon = 'user-injured',
                iconColor = '#40E0D0',
                onSelect = function()
                    lib.registerContext({
                        id = 'aura_med_test_patient_gender',
                        title = 'Seleccionar Género de Prueba',
                        menu = 'aura_medical_admin_hub',
                        options = {
                            {
                                title = 'Silueta Masculina',
                                icon = 'mars',
                                onSelect = function()
                                    TriggerEvent('aura_medical:client:openPatientInput', GetPlayerServerId(PlayerId()), 75)
                                end
                            },
                            {
                                title = 'Silueta Femenina',
                                icon = 'venus',
                                onSelect = function()
                                    SetMedicalNuiFocus(true)
                                    currentMode = 'patient'
                                    SendNUIMessage({
                                        action = 'openPatientView',
                                        medicSrc = GetPlayerServerId(PlayerId()),
                                        isMale = false,
                                        patientName = GetPlayerName(PlayerId()) .. " (Prueba)",
                                        zones = Config.Zones,
                                        injuryTypes = Config.InjuryTypes,
                                        initialBpm = 75
                                    })
                                end
                            }
                        }
                    })
                    lib.showContext('aura_med_test_patient_gender')
                end
            },
            {
                title = '💉 Probar Vista Médico (Casos Clínicos)',
                description = 'Abre el monitor quirúrgico del médico con un paciente simulado y lesiones precargadas.',
                icon = 'stethoscope',
                iconColor = '#FF007F',
                onSelect = function()
                    local caseOptions = {}
                    for k, caseData in pairs(TestCases) do
                        table.insert(caseOptions, {
                            title = caseData.title,
                            description = caseData.desc .. string.format(" | BPM: %d", caseData.bpm),
                            icon = 'heart-pulse',
                            onSelect = function()
                                TriggerServerEvent('aura_medical:server:startDummySession', {
                                    dummyId = math.random(100, 999),
                                    isMale = (k ~= 'case2'),
                                    patientName = "Paciente de Prueba (" .. caseData.title .. ")",
                                    bpm = caseData.bpm,
                                    injuries = json.decode(json.encode(caseData.injuries))
                                })
                            end
                        })
                    end

                    lib.registerContext({
                        id = 'aura_med_test_ems_cases',
                        title = 'Seleccionar Caso Clínico Simulado',
                        menu = 'aura_medical_admin_hub',
                        options = caseOptions
                    })
                    lib.showContext('aura_med_test_ems_cases')
                end
            },
            {
                title = '🧍 Generar Dummy Físico en el Suelo',
                description = 'Spawnea un NPC herido frente a ti con ox_target para probar el flujo completo (progreso + cura + DEA).',
                icon = 'person-falling',
                iconColor = '#f59e0b',
                onSelect = function()
                    lib.registerContext({
                        id = 'aura_med_spawn_dummy_opts',
                        title = 'Configurar Paciente Dummy',
                        menu = 'aura_medical_admin_hub',
                        options = {
                            {
                                title = 'Dummy Masculino - Politraumatismo Balístico',
                                icon = 'male',
                                onSelect = function() SpawnAdminTestDummy(true, 'case1') end
                            },
                            {
                                title = 'Dummy Femenino - Atropello y Quemaduras',
                                icon = 'female',
                                onSelect = function() SpawnAdminTestDummy(false, 'case2') end
                            },
                            {
                                title = 'Dummy en Parada Cardíaca (0 BPM)',
                                icon = 'heart-crack',
                                onSelect = function() SpawnAdminTestDummy(true, 'case3') end
                            },
                            {
                                title = 'Dummy Trauma Complejo (6 Zonas)',
                                icon = 'hospital-user',
                                onSelect = function() SpawnAdminTestDummy(false, 'case4') end
                            }
                        }
                    })
                    lib.showContext('aura_med_spawn_dummy_opts')
                end
            },
            {
                title = '🛡️ Activar Servicio EMS + Material Médico',
                description = 'Te pone de servicio como Jefe Médico y te entrega Desfibrilador y Torniquetes.',
                icon = 'kit-medical',
                iconColor = '#10b981',
                onSelect = function()
                    TriggerServerEvent('aura_ems:server:debugSetEmsDuty')
                end
            },
            {
                title = '🧹 Eliminar Dummies Generados',
                description = 'Limpia todos los NPCs de prueba generados en la sesión actual.',
                icon = 'trash-can',
                onSelect = function()
                    local count = 0
                    for _, d in ipairs(AdminDummies) do
                        if DoesEntityExist(d.ped) then
                            DeleteEntity(d.ped)
                            count = count + 1
                        end
                    end
                    AdminDummies = {}
                    lib.notify({ title = 'Dummies Eliminados', description = string.format('Se han eliminado %d pacientes de prueba.', count), type = 'inform' })
                end
            },
            {
                title = '✨ Curar & Resetear Todo (Self)',
                description = 'Restaura tu salud al 100%, repara fracturas y limpia manchas de sangre.',
                icon = 'wand-magic-sparkles',
                iconColor = '#00f2fe',
                onSelect = function()
                    local ped = PlayerPedId()
                    SetEntityHealth(ped, GetEntityMaxHealth(ped))
                    ClearPedBloodDamage(ped)
                    ResetPedVisibleDamage(ped)
                    TriggerEvent('aura_medical:client:resetDamage')
                    lib.notify({ title = 'Salud Restaurada', description = 'Todas las lesiones y fracturas han sido curadas.', type = 'success' })
                end
            },
            {
                title = '🎬 Simulación: Paciente Siendo Curado (Automático)',
                description = 'Abre la vista del paciente y ejecuta una simulación paso a paso con curaciones y fármacos en tiempo real.',
                icon = 'film',
                iconColor = '#a855f7',
                onSelect = function()
                    StartPatientTreatmentSimulation()
                end
            }
        }
    })
    lib.showContext('aura_medical_admin_hub')
end

local isSimulatingPatient = false

function StartPatientTreatmentSimulation()
    if isSimulatingPatient then return end
    isSimulatingPatient = true

    SetMedicalNuiFocus(true)
    currentMode = 'patient'

    local myPed = PlayerPedId()
    local isMale = (GetEntityModel(myPed) == `mp_m_freemode_01` or IsPedMale(myPed))

    local initialInjuries = {
        head = { "contusion" },
        torso = { "bullet", "puncture" },
        right_arm = { "bone_break" },
        left_arm = {},
        right_hand = {},
        left_hand = {},
        right_leg = { "muscle_tear" },
        left_leg = {},
        right_foot = {},
        left_foot = {}
    }

    SendNUIMessage({
        action = 'openPatientView',
        medicSrc = GetPlayerServerId(PlayerId()),
        isMale = isMale,
        patientName = GetPlayerName(PlayerId()) .. " (Paciente Simulado)",
        zones = Config.Zones,
        injuryTypes = Config.InjuryTypes,
        initialBpm = 42
    })

    lib.notify({
        title = 'Simulación P2P Iniciada',
        description = 'Observa cómo el médico aplica procedimientos y fármacos en tu pantalla. Puedes pulsar TAB en cualquier momento para alternar vistas.',
        type = 'inform',
        duration = 7000
    })

    CreateThread(function()
        local currentInjuries = json.decode(json.encode(initialInjuries))
        local currentBpm = 42

        -- Paso 1: Médico extrae proyectil en Torso (3.0s)
        Wait(3000)
        if not isUIOpen then isSimulatingPatient = false return end
        currentInjuries.torso = { "puncture" }
        SendNUIMessage({
            action = 'syncTreatmentApplied',
            zone = 'torso',
            injuryId = 'bullet',
            remainingInjuries = currentInjuries.torso,
            allInjuries = currentInjuries,
            allCured = false,
            bpm = currentBpm,
            medicName = "Dr. Morales (EMS)"
        })
        lib.notify({ title = 'Tratamiento Quirúrgico', description = 'El Dr. Morales ha extraído el proyectil balístico del tórax.', type = 'success' })

        -- Paso 2: Médico sutura herida punzante en Torso (3.0s)
        Wait(3000)
        if not isUIOpen then isSimulatingPatient = false return end
        currentInjuries.torso = {}
        SendNUIMessage({
            action = 'syncTreatmentApplied',
            zone = 'torso',
            injuryId = 'puncture',
            remainingInjuries = {},
            allInjuries = currentInjuries,
            allCured = false,
            bpm = currentBpm,
            medicName = "Dr. Morales (EMS)"
        })
        lib.notify({ title = 'Tratamiento Quirúrgico', description = 'El tórax ha sido suturado y sellado. Zona completamente curada.', type = 'success' })

        -- Paso 3: Médico trata contusión en Cabeza (3.0s)
        Wait(3000)
        if not isUIOpen then isSimulatingPatient = false return end
        currentInjuries.head = {}
        SendNUIMessage({
            action = 'syncTreatmentApplied',
            zone = 'head',
            injuryId = 'contusion',
            remainingInjuries = {},
            allInjuries = currentInjuries,
            allCured = false,
            bpm = currentBpm,
            medicName = "Dr. Morales (EMS)"
        })
        lib.notify({ title = 'Tratamiento Quirúrgico', description = 'Compresa fría y antiinflamatorio aplicados en la cabeza.', type = 'success' })

        -- Paso 4: Médico entablilla fractura en Brazo Derecho (3.0s)
        Wait(3000)
        if not isUIOpen then isSimulatingPatient = false return end
        currentInjuries.right_arm = {}
        SendNUIMessage({
            action = 'syncTreatmentApplied',
            zone = 'right_arm',
            injuryId = 'bone_break',
            remainingInjuries = {},
            allInjuries = currentInjuries,
            allCured = false,
            bpm = currentBpm,
            medicName = "Dr. Morales (EMS)"
        })
        lib.notify({ title = 'Tratamiento Quirúrgico', description = 'Fractura ósea del brazo derecho inmovilizada y estabilizada.', type = 'success' })

        -- Paso 5: Médico trata desgarro muscular en Pierna Derecha (3.0s)
        Wait(3000)
        if not isUIOpen then isSimulatingPatient = false return end
        currentInjuries.right_leg = {}
        SendNUIMessage({
            action = 'syncTreatmentApplied',
            zone = 'right_leg',
            injuryId = 'muscle_tear',
            remainingInjuries = {},
            allInjuries = currentInjuries,
            allCured = true,
            bpm = currentBpm,
            medicName = "Dr. Morales (EMS)"
        })
        lib.notify({ title = 'Heridas 100% Curadas', description = 'Todas las lesiones físicas han sido reparadas con éxito.', type = 'success' })

        -- Paso 6: Médico inyecta Adrenalina (+25 BPM) (3.0s)
        Wait(3000)
        if not isUIOpen then isSimulatingPatient = false return end
        currentBpm = 67
        SendNUIMessage({
            action = 'syncBpmUpdated',
            bpm = currentBpm,
            medicationLabel = '+25 Adrenalina',
            allCured = true,
            isStable = true
        })
        lib.notify({ title = 'Farmacología EMS', description = 'El médico administra Adrenalina (+25 BPM). El pulso aumenta.', type = 'inform' })

        -- Paso 7: Médico administra Atropina (+15 BPM -> 82 BPM Ritmo Sinusal) (3.0s)
        Wait(3000)
        if not isUIOpen then isSimulatingPatient = false return end
        currentBpm = 82
        SendNUIMessage({
            action = 'syncBpmUpdated',
            bpm = currentBpm,
            medicationLabel = '+15 Atropina',
            allCured = true,
            isStable = true
        })
        lib.notify({ title = 'Ritmo Sinusal Óptimo', description = 'Atropina administrada. Ritmo cardíaco estabilizado en 82 BPM.', type = 'success' })

        -- Paso 8: Médico aplica Desfibrilador DEA / Reanimación (3.0s)
        Wait(3000)
        if not isUIOpen then isSimulatingPatient = false return end
        lib.notify({
            title = '⚡ Reanimación Exitosa',
            description = '¡Descarga DEA efectiva! El paciente ha sido totalmente estabilizado y reanimado.',
            type = 'success',
            icon = 'heart-pulse',
            duration = 8000
        })

        isSimulatingPatient = false
    end)
end

-- ============================================================================
-- 7. COMANDOS DE ADMINISTRACIÓN / PRUEBAS
-- ============================================================================

RegisterCommand('testmedical', function()
    OpenAdminMedicalMenu()
end, false)

RegisterCommand('medicaltest', function()
    OpenAdminMedicalMenu()
end, false)

RegisterCommand('medicaldebug', function()
    OpenAdminMedicalMenu()
end, false)

RegisterCommand('simpatient', function()
    StartPatientTreatmentSimulation()
end, false)

RegisterCommand('spawndummy', function(_, args)
    local isMale = (args[1] ~= 'female' and args[1] ~= 'mujer' and args[1] ~= 'f')
    local caseKey = args[2] or 'case1'
    SpawnAdminTestDummy(isMale, caseKey)
end, false)

RegisterCommand('testpatient', function(_, args)
    local isMale = (args[1] ~= 'female' and args[1] ~= 'mujer' and args[1] ~= 'f')
    SetMedicalNuiFocus(true)
    currentMode = 'patient'
    SendNUIMessage({
        action = 'openPatientView',
        medicSrc = GetPlayerServerId(PlayerId()),
        isMale = isMale,
        patientName = GetPlayerName(PlayerId()) .. " (Admin Test)",
        zones = Config.Zones,
        injuryTypes = Config.InjuryTypes,
        initialBpm = 75
    })
end, false)

RegisterCommand('testems', function(_, args)
    local caseKey = args[1] or 'case1'
    local chosenCase = TestCases[caseKey] or TestCases.case1
    TriggerServerEvent('aura_medical:server:startDummySession', {
        dummyId = math.random(100, 999),
        isMale = (args[2] ~= 'female' and args[2] ~= 'f'),
        patientName = "Paciente Simulado (" .. chosenCase.title .. ")",
        bpm = chosenCase.bpm,
        injuries = json.decode(json.encode(chosenCase.injuries))
    })
end, false)
