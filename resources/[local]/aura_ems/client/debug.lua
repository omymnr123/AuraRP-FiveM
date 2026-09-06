-- ============================================================================
-- AURA EMS: DEVELOPER & SOLO TESTING SUITE (ADMIN SUITE)
-- Herramienta integral para probar Reanimación, Desfibrilador DEA, Torniquetes,
-- Escáner 3D, Despacho 911, Radio Táctica y MDT con Dummies de prueba.
-- ============================================================================

local SpawnedDummies = {}

-- ============================================================================
-- 1. GENERADOR DE PACIENTE DUMMY EN PARADA CARDIORRESPIRATORIA
-- ============================================================================

function SpawnMedicalDummy()
    local ped = cache.ped or PlayerPedId()
    local coords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local spawnCoords = coords + (forward * 1.8)
    local heading = (GetEntityHeading(ped) + 180.0) % 360.0

    local models = {
        `a_m_m_skater_01`,
        `a_m_y_beach_01`,
        `a_m_m_farmer_01`,
        `a_f_y_fitness_01`
    }
    local modelHash = models[math.random(#models)]
    lib.requestModel(modelHash, 5000)

    local dummyPed = CreatePed(4, modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z - 0.95, heading, true, false)
    SetEntityAsMissionEntity(dummyPed, true, true)
    SetBlockingOfNonTemporaryEvents(dummyPed, true)
    SetPedCanRagdollFromPlayerImpact(dummyPed, false)
    SetPedFleeAttributes(dummyPed, 0, false)
    SetPedCombatAttributes(dummyPed, 17, true)
    SetEntityInvincible(dummyPed, false)
    SetEntityHealth(dummyPed, 105)

    -- Aplicar manchas de sangre y daño visible en el torso/extremidades
    ApplyPedDamagePack(dummyPed, "Fall", 100.0, 100.0)
    ApplyPedDamagePack(dummyPed, "Explosion_Med", 50.0, 50.0)

    -- Forzar estado de inconsciencia y animación en el suelo
    lib.requestAnimDict('dead', 3000)
    TaskPlayAnim(dummyPed, 'dead', 'dead_d', 8.0, -8.0, -1, 1, 0, false, false, false)

    local dummyId = #SpawnedDummies + 1
    local dummyData = {
        id = dummyId,
        ped = dummyPed,
        isDead = true,
        hasPulse = false,
        heartRate = 0,
        bloodPressure = "0/0 mmHg",
        spo2 = 41,
        bleedingLevel = "Grave (Arteria Femoral)",
        isTourniquetApplied = false,
        cprCount = 0
    }

    table.insert(SpawnedDummies, dummyData)

    -- Registrar interacciones ox_target sobre este Dummy
    exports.ox_target:addLocalEntity(dummyPed, {
        -- 1. Diagnóstico y Constantes Vitales
        {
            name = 'ems_dummy_diag_' .. dummyId,
            icon = 'fa-solid fa-stethoscope',
            label = '🩺 Diagnóstico y Constantes Vitales (Dummy)',
            distance = 2.5,
            onSelect = function()
                local statusTitle = dummyData.isDead and "PARADA CARDIORRESPIRATORIA (CRÍTICO)" or "ESTABLE / CONSCIENTE"
                local statusColor = dummyData.isDead and "#ff2a55" or "#00ff9d"

                lib.registerContext({
                    id = 'dummy_vitals_menu_' .. dummyId,
                    title = '📋 Monitor de Signos Vitales - Paciente #' .. dummyId,
                    options = {
                        {
                            title = 'Estado de Consciencia: ' .. statusTitle,
                            description = dummyData.isDead and 'Sin respuesta a estímulos verbales o dolorosos. Glasgow 3/15.' or 'Paciente consciente y orientado. Glasgow 15/15.',
                            icon = 'heart-pulse',
                            iconColor = statusColor
                        },
                        {
                            title = 'Frecuencia Cardíaca (ECG): ' .. dummyData.heartRate .. ' BPM',
                            description = dummyData.hasPulse and 'Ritmo Sinusal Normal sin arritmias detectadas.' or 'Fibrilación Ventricular sin pulso central detectable.',
                            icon = 'wave-square',
                            iconColor = dummyData.hasPulse and '#00ff9d' or '#ff2a55'
                        },
                        {
                            title = 'Tensión Arterial: ' .. dummyData.bloodPressure,
                            description = dummyData.isDead and 'Hipotensión severa por choque hipovolémico / PCR.' or 'Presión arterial normotensa tras reanimación.',
                            icon = 'gauge-high',
                            iconColor = dummyData.hasPulse and '#40E0D0' or '#f59e0b'
                        },
                        {
                            title = 'Saturación SpO2: ' .. dummyData.spo2 .. '%',
                            description = dummyData.spo2 > 90 and 'Oxigenación tisular óptima.' or 'Hipoxia severa por ausencia de ventilación espontánea.',
                            icon = 'lungs',
                            iconColor = dummyData.spo2 > 90 and '#00ff9d' or '#ff2a55'
                        },
                        {
                            title = 'Hemorragias: ' .. dummyData.bleedingLevel,
                            description = dummyData.isTourniquetApplied and 'Torniquete C-A-T colocado correctamente. Flujo ocluido.' or 'Hemorragia activa no controlada. Requiere compresión inmediata.',
                            icon = 'droplet',
                            iconColor = dummyData.isTourniquetApplied and '#00ff9d' or '#ff2a55'
                        }
                    }
                })
                lib.showContext('dummy_vitals_menu_' .. dummyId)
            end
        },

        -- 2. Aplicar Torniquete Táctico C-A-T
        {
            name = 'ems_dummy_tourniquet_' .. dummyId,
            icon = 'fa-solid fa-bandage',
            label = '🩹 Aplicar Torniquete Táctico C-A-T (Dummy)',
            distance = 2.5,
            onSelect = function()
                if dummyData.isTourniquetApplied then
                    lib.notify({
                        title = 'Atención Médica',
                        description = 'El paciente ya tiene un torniquete de compresión colocado y asegurado.',
                        type = 'inform'
                    })
                    return
                end

                local myPed = cache.ped or PlayerPedId()
                TaskTurnPedToFaceEntity(myPed, dummyPed, 1000)
                Wait(400)

                local success = lib.progressBar({
                    duration = 3500,
                    label = 'Colocando y girando varilla del torniquete C-A-T...',
                    useWhileDead = false,
                    canCancel = true,
                    disable = { move = true, car = true, combat = true },
                    anim = {
                        dict = Config.FieldOps.tourniquet.animDict,
                        clip = Config.FieldOps.tourniquet.animClip,
                        flag = 49
                    }
                })

                ClearPedTasks(myPed)

                if success then
                    dummyData.isTourniquetApplied = true
                    dummyData.bleedingLevel = 'Detenida / Ocluida con Torniquete C-A-T'
                    lib.notify({
                        title = 'Torniquete Colocado',
                        description = 'Hemorragia masiva controlada exitosamente. El paciente ha dejado de desangrarse.',
                        type = 'success',
                        icon = 'bandage',
                        duration = 6000
                    })
                else
                    lib.notify({ title = 'Cancelado', description = 'Procedimiento interrumpido.', type = 'inform' })
                end
            end
        },

        -- 3. Desfibrilador DEA (Minijuego de Reanimación)
        {
            name = 'ems_dummy_defib_' .. dummyId,
            icon = 'fa-solid fa-heart-pulse',
            label = '⚡ Usar Desfibrilador DEA Bifásico (Dummy)',
            distance = 2.5,
            onSelect = function()
                if not dummyData.isDead then
                    lib.notify({
                        title = 'DEA Bifásico',
                        description = 'El monitor detecta pulso sinusal. No se recomienda aplicar descargas a un paciente consciente.',
                        type = 'inform'
                    })
                    return
                end

                local myPed = cache.ped or PlayerPedId()
                lib.requestAnimDict('mini@cpr@char_a@cpr_str', 3000)
                TaskTurnPedToFaceEntity(myPed, dummyPed, 1000)
                Wait(400)
                TaskPlayAnim(myPed, 'mini@cpr@char_a@cpr_str', 'cpr_pumpchest', 8.0, -8.0, -1, 1, 0, false, false, false)

                lib.notify({
                    title = 'Desfibrilador DEA',
                    description = 'Parches adheridos. Analizando ritmo cardíaco... ¡Descarga aconsejada!',
                    type = 'inform',
                    icon = 'heart-pulse',
                    duration = 3000
                })

                -- Iniciar minijuego de desfibrilador
                local minigameOk = false
                if exports.aura_minigames and exports.aura_minigames.StartDefib then
                    minigameOk = exports.aura_minigames:StartDefib(Config.FieldOps.defib.minigameOptions)
                else
                    minigameOk = lib.skillCheck({'medium', 'medium', 'hard'}, {'e'})
                end

                ClearPedTasks(myPed)

                if minigameOk then
                    -- Animación de descarga y choque en el dummy
                    lib.requestAnimDict('mini@cpr@char_a@cpr_str', 2000)
                    TaskPlayAnim(myPed, 'mini@cpr@char_a@cpr_str', 'cpr_success', 8.0, -8.0, 2500, 0, 0, false, false, false)

                    -- Sacudida eléctrica del dummy
                    SetPedToRagdoll(dummyPed, 1500, 1500, 0, 0, 0, 0)
                    Wait(1200)

                    dummyData.isDead = false
                    dummyData.hasPulse = true
                    dummyData.heartRate = 78
                    dummyData.bloodPressure = "120/80 mmHg"
                    dummyData.spo2 = 98

                    -- Levantar al dummy o colocarlo sentado
                    ClearPedTasksImmediately(dummyPed)
                    SetEntityHealth(dummyPed, 200)
                    ClearPedBloodDamage(dummyPed)

                    lib.requestAnimDict('amb@world_human_picnic@male@idle_a', 3000)
                    TaskPlayAnim(dummyPed, 'amb@world_human_picnic@male@idle_a', 'idle_a', 8.0, -8.0, -1, 1, 0, false, false, false)

                    lib.notify({
                        title = '⚡ ¡Descarga Exitosa!',
                        description = 'El paciente ha recuperado el pulso espontáneo (78 BPM) y se encuentra estabilizado.',
                        type = 'success',
                        icon = 'heart-circle-check',
                        duration = 8000
                    })
                else
                    lib.notify({
                        title = 'Fallo en la Desfibrilación',
                        description = 'Descarga desincronizada o interrumpida. El paciente sigue en parada.',
                        type = 'error',
                        icon = 'triangle-exclamation'
                    })
                end
            end
        },

        -- 4. RCP Manual / Compresiones
        {
            name = 'ems_dummy_cpr_' .. dummyId,
            icon = 'fa-solid fa-hand-holding-medical',
            label = '🫀 Realizar RCP / Compresiones Manuales (Dummy)',
            distance = 2.5,
            onSelect = function()
                local myPed = cache.ped or PlayerPedId()
                lib.requestAnimDict('mini@cpr@char_a@cpr_str', 3000)
                TaskTurnPedToFaceEntity(myPed, dummyPed, 1000)
                Wait(400)
                TaskPlayAnim(myPed, 'mini@cpr@char_a@cpr_str', 'cpr_pumpchest', 8.0, -8.0, -1, 1, 0, false, false, false)

                local success = lib.progressBar({
                    duration = 5000,
                    label = 'Realizando 30 compresiones torácicas a ritmo de 100-120 cpm...',
                    useWhileDead = false,
                    canCancel = true,
                    disable = { move = true, car = true, combat = true }
                })

                ClearPedTasks(myPed)

                if success then
                    dummyData.cprCount = dummyData.cprCount + 1
                    lib.notify({
                        title = 'Ciclo RCP Completado',
                        description = string.format("Ciclo #%d finalizado. Manteniendo perfusión cerebral básica.", dummyData.cprCount),
                        type = 'inform',
                        icon = 'lungs'
                    })
                end
            end
        },

        -- 5. Simular Nueva Parada Cardíaca (Colapsar para repetir pruebas)
        {
            name = 'ems_dummy_collapse_' .. dummyId,
            icon = 'fa-solid fa-skull',
            label = '⚠️ Simular Parada Cardíaca / Colapso (Reiniciar Dummy)',
            distance = 2.5,
            onSelect = function()
                dummyData.isDead = true
                dummyData.hasPulse = false
                dummyData.heartRate = 0
                dummyData.bloodPressure = "0/0 mmHg"
                dummyData.spo2 = 41
                dummyData.isTourniquetApplied = false
                dummyData.bleedingLevel = "Grave (Arteria Femoral)"

                ClearPedTasksImmediately(dummyPed)
                ApplyPedDamagePack(dummyPed, "Fall", 100.0, 100.0)
                lib.requestAnimDict('dead', 3000)
                TaskPlayAnim(dummyPed, 'dead', 'dead_d', 8.0, -8.0, -1, 1, 0, false, false, false)

                lib.notify({
                    title = 'Dummy Reiniciado',
                    description = 'El paciente ha vuelto a colapsar en parada cardiorrespiratoria.',
                    type = 'warning'
                })
            end
        },

        -- 6. Eliminar Paciente Dummy
        {
            name = 'ems_dummy_delete_' .. dummyId,
            icon = 'fa-solid fa-trash',
            label = '🗑️ Eliminar Paciente Dummy',
            distance = 2.5,
            onSelect = function()
                if DoesEntityExist(dummyPed) then
                    DeleteEntity(dummyPed)
                end
                for i, d in ipairs(SpawnedDummies) do
                    if d.id == dummyId then
                        table.remove(SpawnedDummies, i)
                        break
                    end
                end
                lib.notify({ title = 'Paciente Eliminado', description = 'Se ha retirado al dummy de pruebas.', type = 'inform' })
            end
        }
    })

    lib.notify({
        title = '👤 Paciente Dummy Generado',
        description = 'Apunta con ALT / ox_target al dummy para realizar diagnóstico, torniquete, DEA con minijuego o RCP.',
        type = 'success',
        icon = 'user-injured',
        duration = 8000
    })
end

-- ============================================================================
-- 2. LIMPIEZA DE DUMMIES
-- ============================================================================

function ClearMedicalDummies()
    local count = 0
    for _, d in ipairs(SpawnedDummies) do
        if d.ped and DoesEntityExist(d.ped) then
            DeleteEntity(d.ped)
            count = count + 1
        end
    end
    SpawnedDummies = {}
    lib.notify({
        title = 'Limpieza de Dummies',
        description = string.format("Se han eliminado %d pacientes de prueba.", count),
        type = 'inform',
        icon = 'trash'
    })
end

-- ============================================================================
-- 3. SIMULADOR DE ALERTA DE EMERGENCIA 911 / DESPACHO
-- ============================================================================

local function SimulateComaEmergencyAlert()
    local coords = GetEntityCoords(cache.ped or PlayerPedId())
    local s1, s2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = GetStreetNameFromHashKey(s1)
    if s2 ~= 0 then
        street = street .. " / " .. GetStreetNameFromHashKey(s2)
    end
    local zone = GetNameOfZone(coords.x, coords.y, coords.z)
    local zoneLabel = GetLabelText(zone)
    if zoneLabel == "NULL" or not zoneLabel then zoneLabel = zone end

    TriggerServerEvent('aura_ems:server:debugSimulateEmergency', coords, street, zoneLabel)
end

-- ============================================================================
-- 4. MENÚ INTERACTIVO DE PRUEBAS (/testems /emstest /emsdebug)
-- ============================================================================

local function OpenEmsDebugMenu()
    lib.registerMenu({
        id = 'aura_ems_debug_menu',
        title = '🩺 Suite de Pruebas EMS (Admin)',
        position = 'top-right',
        options = {
            { label = '👨‍⚕️ Asignarme Jefe Médico (Grado 4 + Material)', description = 'Asigna trabajo, servicio activo, desfibrilador y torniquetes' },
            { label = '👤 Generar Paciente en Parada Cardíaca (Dummy)', description = 'Spawnea un dummy en el suelo con ox_target interactivo' },
            { label = '🚨 Simular Alerta de Emergencia 911 / Despacho', description = 'Genera un aviso 10-33 en el HUD y en la central de avisos' },
            { label = '⚡ Probar Minijuego de Desfibrilador DEA', description = 'Lanza directamente el minijuego de ritmo cardíaco' },
            { label = '🩸 Probar Animación de Torniquete', description = 'Ejecuta la animación y barra de compresión' },
            { label = '📋 Abrir Tableta Médica (MDT)', description = 'Abre la suite clínica y gestión de historiales' },
            { label = '📻 Abrir Malla de Radio (#01 - #20)', description = 'Abre el panel de canales encriptados de radio' },
            { label = '🗑️ Eliminar Todos los Dummies', description = 'Limpia los pacientes generados en el mapa' }
        }
    }, function(selected)
        if selected == 1 then
            TriggerServerEvent('aura_ems:server:debugSetEmsDuty')
        elseif selected == 2 then
            SpawnMedicalDummy()
        elseif selected == 3 then
            SimulateComaEmergencyAlert()
        elseif selected == 4 then
            if exports.aura_minigames and exports.aura_minigames.StartDefib then
                local ok = exports.aura_minigames:StartDefib(Config.FieldOps.defib.minigameOptions)
                lib.notify({
                    title = 'Resultado DEA',
                    description = ok and '¡Descarga sincronizada correctamente!' or 'Descarga fallida.',
                    type = ok and 'success' or 'error'
                })
            else
                local ok = lib.skillCheck({'medium', 'medium'}, {'e'})
                lib.notify({
                    title = 'Resultado Minijuego',
                    description = ok and 'Aprobado' or 'Fallido',
                    type = ok and 'success' or 'error'
                })
            end
        elseif selected == 5 then
            lib.requestAnimDict(Config.FieldOps.tourniquet.animDict, 3000)
            lib.progressBar({
                duration = 3500,
                label = 'Prueba de colocación de torniquete...',
                useWhileDead = false,
                canCancel = true,
                anim = {
                    dict = Config.FieldOps.tourniquet.animDict,
                    clip = Config.FieldOps.tourniquet.animClip,
                    flag = 49
                }
            })
        elseif selected == 6 then
            ExecuteCommand('emsmdt')
        elseif selected == 7 then
            ExecuteCommand('emsmdt')
        elseif selected == 8 then
            ClearMedicalDummies()
        end
    end)

    lib.showMenu('aura_ems_debug_menu')
end

-- ============================================================================
-- 5. REGISTRO DE COMANDOS DE CHAT
-- ============================================================================

RegisterCommand('testems', OpenEmsDebugMenu, false)
RegisterCommand('emstest', OpenEmsDebugMenu, false)
RegisterCommand('emsdebug', OpenEmsDebugMenu, false)

RegisterCommand('setems', function()
    TriggerServerEvent('aura_ems:server:debugSetEmsDuty')
end, false)

RegisterCommand('spawndummy', function()
    SpawnMedicalDummy()
end, false)
RegisterCommand('dummy_ems', function()
    SpawnMedicalDummy()
end, false)
RegisterCommand('spawnpaciente', function()
    SpawnMedicalDummy()
end, false)

RegisterCommand('deldummy', function()
    ClearMedicalDummies()
end, false)
RegisterCommand('cleardummies', function()
    ClearMedicalDummies()
end, false)

RegisterCommand('testdispatch_ems', function()
    SimulateComaEmergencyAlert()
end, false)
RegisterCommand('testcoma', function()
    SimulateComaEmergencyAlert()
end, false)
