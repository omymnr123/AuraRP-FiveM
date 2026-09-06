-- ============================================================================
-- AURA EMS: CLIENT FIELD OPS & RESUSCITATION CONTROLLER
-- ox_target Interactions: Tourniquet Compression, Defib (DEA) Minigame & Scan
-- ============================================================================

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
-- 1. REGISTRO GLOBAL DE OX_TARGET EN JUGADORES
-- ============================================================================

CreateThread(function()
    exports.ox_target:addGlobalPlayer({
        -- 1. APLICAR TORNIQUETE TÁCTICO
        {
            name = 'aura_ems_apply_tourniquet',
            icon = 'fa-solid fa-bandage',
            label = 'Aplicar Torniquete Táctico C-A-T',
            distance = 2.2,
            canInteract = function(entity)
                if not IsTargetPlayerDead(entity) then return false end
                local hasItem = false
                if exports.ox_inventory then
                    hasItem = (exports.ox_inventory:Search('count', Config.FieldOps.tourniquet.item) or 0) > 0
                else
                    hasItem = true
                end
                return hasItem
            end,
            onSelect = function(data)
                local targetSrc = GetTargetPlayerServerId(data.entity)
                if not targetSrc then
                    lib.notify({ title = 'Error', description = 'No se ha detectado a ningún paciente.', type = 'error' })
                    return
                end

                local targetPed = data.entity
                local myPed = PlayerPedId()

                -- Animación y barra de progreso
                lib.requestAnimDict(Config.FieldOps.tourniquet.animDict, 3000)
                TaskTurnPedToFaceEntity(myPed, targetPed, 1000)
                Wait(500)

                local success = lib.progressBar({
                    duration = Config.FieldOps.tourniquet.duration or 3500,
                    label = 'Colocando y ajustando torniquete de compresión...',
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
                    lib.callback('aura_ems:server:applyTourniquet', false, function(ok, msg)
                        lib.notify({
                            title = 'Atención Médica',
                            description = msg,
                            type = ok and 'success' or 'error',
                            icon = 'bandage'
                        })
                    end, targetSrc)
                else
                    lib.notify({ title = 'Cancelado', description = 'Has interrumpido la colocación del torniquete.', type = 'inform' })
                end
            end
        },

        -- 2. USAR DESFIBRILADOR EXTERNO AUTOMÁTICO (DEA)
        {
            name = 'aura_ems_use_defibrillator',
            icon = 'fa-solid fa-heart-pulse',
            label = 'Usar Desfibrilador (DEA Bifásico)',
            distance = 2.2,
            canInteract = function(entity)
                if not IsTargetPlayerDead(entity) then return false end
                local hasItem = false
                if exports.ox_inventory then
                    hasItem = (exports.ox_inventory:Search('count', Config.FieldOps.defib.item) or 0) > 0
                else
                    hasItem = true
                end
                return hasItem
            end,
            onSelect = function(data)
                local targetSrc = GetTargetPlayerServerId(data.entity)
                if not targetSrc then
                    lib.notify({ title = 'Error', description = 'No se ha detectado al paciente.', type = 'error' })
                    return
                end

                local targetPed = data.entity
                local myPed = PlayerPedId()

                -- Animación de preparación de parches DEA
                lib.requestAnimDict('mini@cpr@char_a@cpr_str', 3000)
                TaskTurnPedToFaceEntity(myPed, targetPed, 1000)
                Wait(400)
                TaskPlayAnim(myPed, 'mini@cpr@char_a@cpr_str', 'cpr_pumpchest', 8.0, -8.0, -1, 1, 0, false, false, false)

                lib.notify({
                    title = 'Desfibrilador DEA',
                    description = 'Colocando parches en el torso del paciente e iniciando análisis ECG...',
                    type = 'inform',
                    icon = 'heart-pulse',
                    duration = 3000
                })

                -- Disparar exportación del minijuego de desfibrilador
                local minigameSuccess = false
                if exports.aura_minigames and exports.aura_minigames.StartDefib then
                    minigameSuccess = exports.aura_minigames:StartDefib(Config.FieldOps.defib.minigameOptions)
                else
                    -- Fallback seguro si por algún motivo no estuviera disponible
                    minigameSuccess = lib.skillCheck({'medium', 'medium'}, {'e'})
                end

                ClearPedTasks(myPed)

                if minigameSuccess then
                    -- Animación de descarga y choque
                    lib.requestAnimDict('mini@cpr@char_a@cpr_str', 2000)
                    TaskPlayAnim(myPed, 'mini@cpr@char_a@cpr_str', 'cpr_success', 8.0, -8.0, 2000, 0, 0, false, false, false)

                    lib.callback('aura_ems:server:resuscitatePatient', false, function(ok, msg)
                        lib.notify({
                            title = 'Reanimación Cardiopulmonar',
                            description = msg,
                            type = ok and 'success' or 'error',
                            icon = 'heart-pulse',
                            duration = 7000
                        })
                    end, targetSrc)
                else
                    lib.notify({
                        title = 'Fallo en la Desfibrilación',
                        description = 'La descarga no se sincronizó con el pico R o se canceló el procedimiento.',
                        type = 'error',
                        icon = 'triangle-exclamation',
                        duration = 5000
                    })
                end
            end
        },

        -- 3. ESCÁNER Y DIAGNÓSTICO MÉDICO
        {
            name = 'aura_ems_diagnose_patient',
            icon = 'fa-solid fa-stethoscope',
            label = 'Diagnóstico y Constantes Vitales',
            distance = 2.2,
            canInteract = function(entity)
                local pState = LocalPlayer.state
                return pState.job == Config.JobName
            end,
            onSelect = function(data)
                local targetSrc = GetTargetPlayerServerId(data.entity)
                if not targetSrc then return end

                local boneDamage = nil
                if exports.aura_medical and exports.aura_medical.GetPlayerBoneDamage then
                    boneDamage = exports.aura_medical:GetPlayerBoneDamage(targetSrc)
                elseif Player(targetSrc).state.bone_damage then
                    boneDamage = Player(targetSrc).state.bone_damage
                end

                local targetPed = data.entity
                local maxHealth = GetEntityMaxHealth(targetPed)
                local curHealth = GetEntityHealth(targetPed)
                local healthPct = math.max(0, math.floor(((curHealth - 100) / (maxHealth - 100)) * 100))

                local injuryDetails = {}
                if boneDamage then
                    for boneKey, bData in pairs(boneDamage) do
                        if bData.health and bData.health < 100 then
                            table.insert(injuryDetails, string.format("• %s: %s%% salud restante (%s heridas)", boneKey:upper(), bData.health, #(bData.injuries or {})))
                        end
                    end
                end

                local diagText = #injuryDetails > 0 and table.concat(injuryDetails, "\n") or "No se aprecian fracturas óseas ni lesiones penetrantes activas."

                lib.alertDialog({
                    header = 'Informe de Evaluación Inicial',
                    content = string.format("**Estado General**: %s%% salud\n**Pulso**: %s\n\n**Traumatismos detectados**:\n%s", healthPct, healthPct > 0 and "Presente" or "PARADA CARDIORESPIRATORIA", diagText),
                    centered = true,
                    cancel = false
                })
            end
        }
    })
end)
