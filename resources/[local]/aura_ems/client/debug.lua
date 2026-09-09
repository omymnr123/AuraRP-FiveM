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
    local isMaleModel = true
    if modelHash == `a_f_y_fitness_01` or modelHash == `mp_f_freemode_01` then
        isMaleModel = false
    end

    local dummyData = {
        id = dummyId,
        ped = dummyPed,
        isMale = isMaleModel,
        isDead = true,
        hasPulse = false,
        heartRate = 0,
        bloodPressure = "0/0 mmHg",
        spo2 = 41,
        bleedingLevel = "Grave (Arteria Femoral)",
        isTourniquetApplied = false,
        cprCount = 0,
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
        },
        boneDamage = {
            head = { health = 80, injuries = { { type = "Cut", typeLabel = "Laceración / Corte", severityLabel = "Corte Superficial", damage = 20, badgeColor = "#ff00a0" } } },
            torso = { health = 35, injuries = { { type = "Bullet", typeLabel = "Impacto Balístico", severityLabel = "Impacto Balístico con Hemorragia Interna", damage = 65, badgeColor = "#ff007f" } } },
            right_arm = { health = 55, injuries = { { type = "Blunt", typeLabel = "Contusión / Fractura", severityLabel = "Contusión Fuerte Radio", damage = 45, badgeColor = "#ffaa00" } } },
            left_arm = { health = 65, injuries = { { type = "Blunt", typeLabel = "Contusión", severityLabel = "Traumatismo Húmero", damage = 35, badgeColor = "#ffaa00" } } },
            right_hand = { health = 45, injuries = { { type = "Burn", typeLabel = "Quemadura / Laceración", severityLabel = "Quemadura de 2º Grado", damage = 55, badgeColor = "#ff0055" } } },
            left_hand = { health = 70, injuries = { { type = "Cut", typeLabel = "Laceración Palmar", severityLabel = "Corte Superficial Palma", damage = 30, badgeColor = "#ffaa00" } } },
            right_leg = { health = 20, injuries = { { type = "Cut", typeLabel = "Laceración Vascular", severityLabel = "Sección Vascular / Hemorragia Severa", damage = 80, badgeColor = "#ff007f" } } },
            left_leg = { health = 60, injuries = { { type = "Blunt", typeLabel = "Contusión", severityLabel = "Hematoma Subcutáneo Tibia", damage = 40, badgeColor = "#ffaa00" } } },
            right_foot = { health = 30, injuries = { { type = "Fall", typeLabel = "Traumatismo Óseo", severityLabel = "Aplastamiento Calcáneo", damage = 70, badgeColor = "#ff007f" } } },
            left_foot = { health = 70, injuries = { { type = "Blunt", typeLabel = "Esguince / Fisura", severityLabel = "Esguince Ligamentoso Tobillo", damage = 30, badgeColor = "#ffaa00" } } }
        }
    }

    table.insert(SpawnedDummies, dummyData)

    -- Registrar interacciones ox_target sobre este Dummy
    exports.ox_target:addLocalEntity(dummyPed, {
        -- 1. Diagnóstico y Constantes Vitales
        {
            name = 'ems_dummy_diag_' .. dummyId,
            icon = 'fa-solid fa-stethoscope',
            label = 'Diagnóstico y Constantes Vitales',
            distance = 2.5,
            canInteract = function()
                local pState = LocalPlayer.state
                return pState.job == Config.JobName and pState.job_duty == true
            end,
            onSelect = function()
                OpenDummyDiagnostic(dummyId)
            end
        },

        -- 2. Cargar / Soltar Paciente
        {
            name = 'ems_dummy_carry_' .. dummyId,
            icon = 'fa-solid fa-people-carry-box',
            label = 'Cargar/Soltar Paciente',
            distance = 2.5,
            canInteract = function()
                local pState = LocalPlayer.state
                return pState.job == Config.JobName and pState.job_duty == true
            end,
            onSelect = function()
                ToggleCarryPatient(dummyPed)
            end
        }
    })

    lib.notify({
        title = 'Paciente Dummy Creado',
        description = string.format('Dummy #%d generado (%s). Utiliza ox_target sobre él para diagnosticar, cargar o tratar.', dummyId, isMaleModel and "Masculino" or "Femenino"),
        type = 'success',
        icon = 'user-injured'
    })
end

-- ============================================================================
-- FUNCIONES GLOBALES DE MANEJO DE DUMMIES PARA NUI & TARGET
-- ============================================================================

function GetDummyData(dummyId)
    for _, d in ipairs(SpawnedDummies) do
        if d.id == dummyId then return d end
    end
    return nil
end

function OpenDummyDiagnostic(dummyId)
    local dummyData = GetDummyData(dummyId)
    if not dummyData then
        lib.notify({ title = 'Error', description = 'No se encontró la información del paciente de pruebas.', type = 'error' })
        return
    end

    local myPed = cache.ped or PlayerPedId()
    TaskTurnPedToFaceEntity(myPed, dummyData.ped, 800)

    CreateThread(function()
        local progressSuccess = exports.aura_progress:Start(
            'Estableciendo telemetría...',
            3000,
            true,
            true,
            { dict = 'amb@medic@standing@kneel@base', clip = 'base', flag = 1 }
        )

        if progressSuccess then
            TriggerServerEvent('aura_medical:server:startDummySession', {
                dummyId = dummyId,
                isMale = dummyData.isMale,
                patientName = "Paciente Dummy #" .. dummyId .. " (Simulación)",
                bpm = dummyData.heartRate or 38,
                injuries = dummyData.injuries or {
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
            })
        end
    end)
end

function ApplyTourniquetToDummy(dummyId)
    local dummyData = GetDummyData(dummyId)
    if not dummyData then return false, "Paciente no encontrado." end

    -- Verificación estricta de ítem de inventario
    local hasTourniquet = false
    if exports.ox_inventory then
        hasTourniquet = (exports.ox_inventory:Search('count', 'torniquete') or 0) > 0
    else
        hasTourniquet = true
    end

    if not hasTourniquet then
        lib.notify({
            title = 'Material Insuficiente',
            description = 'No dispones de un Torniquete Táctico C-A-T en tu inventario.',
            type = 'error',
            icon = 'bandage'
        })
        return false, "No dispones de un Torniquete Táctico C-A-T en tu inventario."
    end

    if dummyData.isTourniquetApplied then
        lib.notify({ title = 'Atención Médica', description = 'El paciente ya tiene un torniquete de compresión colocado.', type = 'inform' })
        return false, "El paciente ya tiene un torniquete colocado."
    end

    local myPed = cache.ped or PlayerPedId()
    TaskTurnPedToFaceEntity(myPed, dummyData.ped, 1000)
    Wait(300)

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
        -- Consumir 1 torniquete del inventario
        TriggerServerEvent('aura_ems:server:consumeTestItem', 'torniquete')

        dummyData.isTourniquetApplied = true
        dummyData.bleedingLevel = 'Detenida / Ocluida con Torniquete C-A-T'
        lib.notify({
            title = 'Torniquete Colocado',
            description = 'Hemorragia masiva controlada exitosamente. El flujo arterial ha sido ocluido.',
            type = 'success',
            icon = 'bandage',
            duration = 6000
        })
        return true, "Torniquete C-A-T colocado correctamente. Hemorragia ocluida."
    else
        lib.notify({ title = 'Cancelado', description = 'Procedimiento interrumpido.', type = 'inform' })
        return false, "Procedimiento interrumpido por el usuario."
    end
end

function UseDefibOnDummy(dummyId)
    local dummyData = GetDummyData(dummyId)
    if not dummyData then return false, "Paciente no encontrado." end

    -- Verificación estricta de ítem de inventario
    local hasDefib = false
    if exports.ox_inventory then
        hasDefib = (exports.ox_inventory:Search('count', 'desfibrilador') or 0) > 0
    else
        hasDefib = true
    end

    if not hasDefib then
        lib.notify({
            title = 'Material Insuficiente',
            description = 'No dispones de un Desfibrilador (DEA) en tu inventario.',
            type = 'error',
            icon = 'heart-pulse'
        })
        return false, "No dispones de un Desfibrilador (DEA) en tu inventario."
    end

    if not dummyData.isDead then
        lib.notify({
            title = 'DEA Bifásico',
            description = 'El monitor detecta pulso sinusal (paciente consciente). No se aconseja descarga.',
            type = 'inform'
        })
        return false, "El monitor detecta pulso sinusal (paciente consciente). No se aconseja descarga."
    end

    local myPed = cache.ped or PlayerPedId()
    lib.requestAnimDict('mini@cpr@char_a@cpr_str', 3000)
    TaskTurnPedToFaceEntity(myPed, dummyData.ped, 1000)
    Wait(400)
    TaskPlayAnim(myPed, 'mini@cpr@char_a@cpr_str', 'cpr_pumpchest', 8.0, -8.0, -1, 1, 0, false, false, false)

    lib.notify({
        title = 'Desfibrilador DEA',
        description = 'Parches colocados en el tórax. Analizando ritmo... ¡Descarga recomendada!',
        type = 'inform',
        icon = 'heart-pulse',
        duration = 3000
    })

    local minigameOk = false
    if exports.aura_minigames and exports.aura_minigames.StartDefib then
        minigameOk = exports.aura_minigames:StartDefib(Config.FieldOps.defib.minigameOptions)
    else
        minigameOk = lib.skillCheck({'medium', 'medium', 'hard'}, {'e'})
    end

    ClearPedTasks(myPed)

    if minigameOk then
        lib.requestAnimDict('mini@cpr@char_a@cpr_str', 2000)
        TaskPlayAnim(myPed, 'mini@cpr@char_a@cpr_str', 'cpr_success', 8.0, -8.0, 2500, 0, 0, false, false, false)

        SetPedToRagdoll(dummyData.ped, 1500, 1500, 0, 0, 0, 0)
        Wait(1200)

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

        dummyData.isDead = false
        dummyData.hasPulse = true
        dummyData.heartRate = 78
        dummyData.bloodPressure = "120/80 mmHg"
        dummyData.spo2 = 98
        dummyData.bleedingLevel = "Estable / Sin Hemorragias"
        dummyData.boneDamage = healthyBones

        SendNUIMessage({
            action = 'updateDiagnosticVitals',
            patient = {
                dummyId = dummyId,
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

        if dummyData.isMission then
            TriggerServerEvent('aura_ems:server:resolveMissionCall', dummyData.missionId, dummyId)
            SetTimeout(30000, function()
                if dummyData.ped and DoesEntityExist(dummyData.ped) then
                    DeleteEntity(dummyData.ped)
                end
            end)
        end

        ClearPedTasksImmediately(dummyData.ped)
        SetEntityHealth(dummyData.ped, 200)
        ClearPedBloodDamage(dummyData.ped)

        lib.requestAnimDict('amb@world_human_picnic@male@idle_a', 3000)
        TaskPlayAnim(dummyData.ped, 'amb@world_human_picnic@male@idle_a', 'idle_a', 8.0, -8.0, -1, 1, 0, false, false, false)

        lib.notify({
            title = '⚡ ¡Descarga Exitosa!',
            description = 'El paciente ha recuperado el pulso espontáneo (78 BPM), fracturas curadas y estabilizado.',
            type = 'success',
            icon = 'heart-circle-check',
            duration = 8000
        })
        return true, "¡Descarga sincronizada efectiva! Constantes vitales y topografía ósea restablecidas."
    else
        lib.notify({
            title = 'Fallo en la Desfibrilación',
            description = 'Descarga desincronizada o interrumpida. El paciente sigue en parada.',
            type = 'error',
            icon = 'triangle-exclamation',
            duration = 5000
        })
        return false, "Descarga desincronizada o interrumpida. El paciente sigue en parada."
    end
end

RegisterNetEvent('aura_medical:client:syncTreatmentApplied', function(syncData)
    for _, d in ipairs(SpawnedDummies) do
        d.injuries = syncData.allInjuries or d.injuries
        d.heartRate = syncData.bpm or d.heartRate
    end
end)

RegisterNetEvent('aura_medical:client:syncBpmUpdated', function(syncData)
    for _, d in ipairs(SpawnedDummies) do
        d.heartRate = syncData.bpm or d.heartRate
    end
end)

RegisterNetEvent('aura_medical:client:reviveDummy', function(dummyKey)
    local dummyIdNum = tonumber(string.match(tostring(dummyKey), "%d+"))
    for _, d in ipairs(SpawnedDummies) do
        if not dummyIdNum or d.id == dummyIdNum then
            d.isDead = false
            d.hasPulse = true
            d.heartRate = 78
            d.injuries = {
                head = {}, torso = {},
                right_arm = {}, left_arm = {},
                right_hand = {}, left_hand = {},
                right_leg = {}, left_leg = {},
                right_foot = {}, left_foot = {}
            }
            if d.ped and DoesEntityExist(d.ped) then
                ClearPedTasksImmediately(d.ped)
                SetEntityHealth(d.ped, 200)
                ClearPedBloodDamage(d.ped)
                ResetPedVisibleDamage(d.ped)
                
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
-- 3. SIMULADOR DE ALERTA DE EMERGENCIA 911 / DESPACHO & GENERADOR DE MISIÓN
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

-- Ubicaciones aleatorias realistas de emergencias por todo el mapa
local EmergencyMissionLocations = {
    { coords = vector4(218.42, -912.35, 30.69, 140.0), reason = "Parada Cardiorrespiratoria por Desmayo Repentino" },
    { coords = vector4(-1038.25, -2737.52, 20.17, 330.0), reason = "Colapso Circulatorio e Insolación Severa" },
    { coords = vector4(-1618.15, -1045.22, 13.15, 50.0), reason = "Semiahogamiento y Parada Cardíaca en Playa" },
    { coords = vector4(314.12, -278.45, 54.17, 250.0), reason = "Traumatismo Craneoencefálico por Atropello" },
    { coords = vector4(298.50, -1445.20, 29.80, 140.0), reason = "Herida por Arma Blanca y Shock Hipovolémico" },
    { coords = vector4(1160.25, -315.12, 69.10, 190.0), reason = "Infarto Agudo de Miocardio (IAM)" },
    { coords = vector4(1730.50, 3710.20, 34.15, 210.0), reason = "Accidente de Tráfico Grave con Múltiples Fracturas" },
    { coords = vector4(-210.45, 6380.20, 31.50, 45.0), reason = "Parada Cardiorrespiratoria en Vía Pública" },
    { coords = vector4(890.12, -2120.45, 30.50, 355.0), reason = "Aplastamiento y Politraumatismo Severo" },
    { coords = vector4(-1370.20, -380.45, 36.50, 120.0), reason = "Electrocución y Arritmia Ventricular Mortal" },
    { coords = vector4(-580.45, -890.12, 25.80, 180.0), reason = "Asfixia por Atragantamiento y Parada" },
    { coords = vector4(430.12, -1890.45, 27.20, 290.0), reason = "Pérdida de Consciencia y Hemorragia Activa" }
}

local RandomPatientNames = {
    "Alejandro Navarro", "Lucía Benítez", "Carlos Mendoza", "Elena Rivas",
    "Mateo Herrera", "Sofía Valenzuela", "Javier Castro", "Martina Morales",
    "David Garrido", "Paula Domínguez", "Hugo Santamaría", "Valeria Crespo"
}

function StartEmergencyMedicalMission()
    local randomLoc = EmergencyMissionLocations[math.random(#EmergencyMissionLocations)]
    local randomName = RandomPatientNames[math.random(#RandomPatientNames)]
    local spawnCoords = randomLoc.coords

    local models = {
        `a_m_m_skater_01`,
        `a_m_y_beach_01`,
        `a_m_m_farmer_01`,
        `a_f_y_fitness_01`,
        `a_m_y_business_02`,
        `a_f_y_runner_01`
    }
    local modelHash = models[math.random(#models)]
    lib.requestModel(modelHash, 5000)

    local dummyPed = CreatePed(4, modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z - 0.95, spawnCoords.w or 0.0, true, false)
    SetEntityAsMissionEntity(dummyPed, true, true)
    SetBlockingOfNonTemporaryEvents(dummyPed, true)
    SetPedCanRagdollFromPlayerImpact(dummyPed, false)
    SetPedFleeAttributes(dummyPed, 0, false)
    SetPedCombatAttributes(dummyPed, 17, true)
    SetEntityInvincible(dummyPed, false)
    SetEntityHealth(dummyPed, 105)

    ApplyPedDamagePack(dummyPed, "Fall", 100.0, 100.0)
    ApplyPedDamagePack(dummyPed, "Explosion_Med", 60.0, 60.0)

    lib.requestAnimDict('dead', 3000)
    TaskPlayAnim(dummyPed, 'dead', 'dead_d', 8.0, -8.0, -1, 1, 0, false, false, false)

    local dummyId = #SpawnedDummies + 1
    local isMaleModel = true
    if modelHash == `a_f_y_fitness_01` or modelHash == `a_f_y_runner_01` or modelHash == `mp_f_freemode_01` then
        isMaleModel = false
    end

    local missionId = "MISSION_" .. math.random(1000, 9999)

    local dummyData = {
        id = dummyId,
        missionId = missionId,
        isMission = true,
        patientName = randomName,
        ped = dummyPed,
        isMale = isMaleModel,
        isDead = true,
        hasPulse = false,
        heartRate = 0,
        bloodPressure = "0/0 mmHg",
        spo2 = 38,
        bleedingLevel = "Grave (Arteria Femoral)",
        isTourniquetApplied = false,
        cprCount = 0,
        boneDamage = {
            head = { health = 60, injuries = { { type = "Cut", typeLabel = "Laceración Craneal", severityLabel = "Traumatismo Craneoencefálico", damage = 40, badgeColor = "#ff00a0" } } },
            torso = { health = 25, injuries = { { type = "Bullet", typeLabel = "Trauma Torácico", severityLabel = "Contusión Cardiopulmonar Severa", damage = 75, badgeColor = "#ff007f" } } },
            right_arm = { health = 40, injuries = { { type = "Blunt", typeLabel = "Fractura Ósea", severityLabel = "Fractura Desplazada Radio/Cúbito", damage = 60, badgeColor = "#ffaa00" } } },
            left_arm = { health = 50, injuries = { { type = "Blunt", typeLabel = "Contusión", severityLabel = "Traumatismo Húmero", damage = 50, badgeColor = "#ffaa00" } } },
            right_hand = { health = 45, injuries = { { type = "Burn", typeLabel = "Laceración / Quemadura", severityLabel = "Quemadura de 2º Grado", damage = 55, badgeColor = "#ff0055" } } },
            left_hand = { health = 70, injuries = { { type = "Cut", typeLabel = "Corte Palmar", severityLabel = "Laceración Superficial", damage = 30, badgeColor = "#ffaa00" } } },
            right_leg = { health = 15, injuries = { { type = "Cut", typeLabel = "Sección Vascular", severityLabel = "Sección Arterial Femoral", damage = 85, badgeColor = "#ff007f" } } },
            left_leg = { health = 55, injuries = { { type = "Blunt", typeLabel = "Contusión", severityLabel = "Hematoma Tibial", damage = 45, badgeColor = "#ffaa00" } } },
            right_foot = { health = 30, injuries = { { type = "Fall", typeLabel = "Aplastamiento", severityLabel = "Aplastamiento Calcáneo", damage = 70, badgeColor = "#ff007f" } } },
            left_foot = { health = 65, injuries = { { type = "Blunt", typeLabel = "Esguince", severityLabel = "Esguince Ligamentoso", damage = 35, badgeColor = "#ffaa00" } } }
        }
    }

    table.insert(SpawnedDummies, dummyData)

    -- Registrar ox_target idéntico al sistema oficial
    exports.ox_target:addLocalEntity(dummyPed, {
        {
            name = 'ems_mission_dummy_diag_' .. dummyId,
            icon = 'fa-solid fa-stethoscope',
            label = 'Diagnóstico y Constantes Vitales',
            distance = 2.5,
            canInteract = function()
                local pState = LocalPlayer.state
                return pState.job == Config.JobName and pState.job_duty == true
            end,
            onSelect = function()
                OpenDummyDiagnostic(dummyId)
            end
        },
        {
            name = 'ems_mission_dummy_carry_' .. dummyId,
            icon = 'fa-solid fa-people-carry-box',
            label = 'Cargar/Soltar Paciente',
            distance = 2.5,
            canInteract = function()
                local pState = LocalPlayer.state
                return pState.job == Config.JobName and pState.job_duty == true
            end,
            onSelect = function()
                ToggleCarryPatient(dummyPed)
            end
        }
    })

    -- Obtener nombre de calle y zona
    local s1, s2 = GetStreetNameAtCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z)
    local street = GetStreetNameFromHashKey(s1)
    if s2 ~= 0 then street = street .. " / " .. GetStreetNameFromHashKey(s2) end
    local zone = GetNameOfZone(spawnCoords.x, spawnCoords.y, spawnCoords.z)
    local zoneLabel = GetLabelText(zone)
    if zoneLabel == "NULL" or not zoneLabel then zoneLabel = zone end

    -- Emitir alerta oficial de despacho
    TriggerServerEvent('aura_ems:server:createEmergencyMissionCall', {
        missionId = missionId,
        dummyId = dummyId,
        coords = spawnCoords,
        street = street,
        zone = zoneLabel,
        patientName = randomName,
        deathReason = randomLoc.reason
    })

    lib.notify({
        title = 'Misión Médica Generada',
        description = string.format("Emergencia 10-33 activa en %s (%s). Pulsa [G] para acudir o [U] para ver la central.", street, zoneLabel),
        type = 'success',
        icon = 'truck-medical',
        duration = 8000
    })
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
            { label = '🚑 Generar Misión de Emergencia Médica (NPC en Mapa)', description = 'Spawnea un paciente en zona aleatoria y lanza aviso 10-33 con GPS' },
            { label = '👤 Generar Paciente Local (Dummy)', description = 'Spawnea un dummy frente a ti para pruebas rápidas' },
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
            StartEmergencyMedicalMission()
        elseif selected == 3 then
            SpawnMedicalDummy()
        elseif selected == 4 then
            SimulateComaEmergencyAlert()
        elseif selected == 5 then
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
        elseif selected == 6 then
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
        elseif selected == 7 then
            ExecuteCommand('emsmdt')
        elseif selected == 8 then
            ExecuteCommand('emsmdt')
        elseif selected == 9 then
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

-- Comandos de Misión Médica Aleatoria
RegisterCommand('testemscall', StartEmergencyMedicalMission, false)
RegisterCommand('emsmission', StartEmergencyMedicalMission, false)
RegisterCommand('testemergency', StartEmergencyMedicalMission, false)

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

