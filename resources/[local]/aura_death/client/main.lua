-- ============================================================================
-- AURA DEATH: CLIENT MAIN CONTROLLER (PHASE 8 CRITICAL STATE & COMA SYSTEM)
-- ============================================================================

local isDead = false
local currentBleedoutRemaining = Config.BleedoutTime
local deathState = "injured" -- "injured" o "unconscious"
local crawlRemaining = Config.CrawlDuration or 60
local isInHospitalBed = false
local isCursorActive = true

--- Alterna o establece el modo de cursor NUI / cámara libre
--- @param active boolean|nil Estado deseado o nil para alternar
local function SetDeathCursorMode(active)
    if active ~= nil then
        isCursorActive = active
    else
        isCursorActive = not isCursorActive
    end

    if isDead then
        SetNuiFocus(isCursorActive, isCursorActive)
        SetNuiFocusKeepInput(true)
    end
end
exports('SetDeathCursorMode', SetDeathCursorMode)

-- Desactivar auto-spawn nativo de GTA V y precargar animaciones críticas de trauma en memoria
CreateThread(function()
    if exports.spawnmanager then
        exports.spawnmanager:setAutoSpawn(false)
    end
    -- Precarga inmediata de animaciones de dolor, arrastre y hospital
    RequestAnimDict("move_crawl")
    RequestAnimDict("combat@damage@writheidle_a")
    RequestAnimDict("combat@damage@writheidle_b")
    RequestAnimDict("combat@damage@writheidle_c")
    RequestAnimDict("combat@damage@rb_writhe")
    RequestAnimDict("anim@gangops@morgue@table@")
end)

--- Control estricto de silencio de voz, radio y canales pma-voice
--- @param mute boolean True para silenciar totalmente, False para restaurar
local function MuteVoiceAndComms(mute)
    if mute then
        if exports['pma-voice'] then
            pcall(function()
                exports['pma-voice']:overrideProximityRange(0.0, true)
                exports['pma-voice']:setVoiceProperty('radioEnabled', false)
                exports['pma-voice']:setVoiceProperty('callEnabled', false)
                exports['pma-voice']:setVoiceProperty('micClicks', false)
                exports['pma-voice']:setRadioChannel(0)
                exports['pma-voice']:setCallChannel(0)
            end)
        end
        NetworkSetVoiceActive(false)
        NetworkSetTalkerProximity(0.0)
        MumbleSetAudioInputIntent(GetHashKey('speech'))
    else
        if exports['pma-voice'] then
            pcall(function()
                exports['pma-voice']:clearProximityOverride()
                exports['pma-voice']:setVoiceProperty('radioEnabled', true)
                exports['pma-voice']:setVoiceProperty('callEnabled', true)
                exports['pma-voice']:setVoiceProperty('micClicks', true)
                exports['pma-voice']:setTalkingMode(2)
            end)
        end
        NetworkSetVoiceActive(true)
    end
end

--- Obtiene la cama de hospital más cercana al jugador
--- @param coords vector3|vector4 Coordenadas actuales
--- @return vector4 Cama más cercana
local function GetNearestHospitalBed(coords)
    if not coords then
        coords = GetEntityCoords(PlayerPedId())
    end

    local nearestBed = Config.RespawnCoords
    local minDistance = 999999.0

    if Config.HospitalBeds and #Config.HospitalBeds > 0 then
        for _, bed in ipairs(Config.HospitalBeds) do
            local bCoords = vector3(bed.coords.x, bed.coords.y, bed.coords.z)
            local dist = #(vector3(coords.x, coords.y, coords.z) - bCoords)
            if dist < minDistance then
                minDistance = dist
                nearestBed = bed.coords
            end
        end
    end

    return nearestBed
end

--- Inicia el Estado Crítico / Coma del Jugador en sus 2 fases progresivas
--- @param timeRemaining number Tiempo en segundos de cuenta regresiva
--- @param deathReason string Causa de la muerte o trauma
--- @param killerSource number|string Fuente del atacante si existe
--- @param initialDeathState string|nil Estado inicial ("injured" o "unconscious")
--- @param initialCrawlRemaining number|nil Segundos restantes de arrastre
local function EnterCriticalState(timeRemaining, deathReason, killerSource, initialDeathState, initialCrawlRemaining)
    if isDead then return end
    isDead = true
    isInHospitalBed = false
    currentBleedoutRemaining = tonumber(timeRemaining) or Config.BleedoutTime

    local totalElapsed = Config.BleedoutTime - currentBleedoutRemaining
    if initialDeathState then
        deathState = initialDeathState
    else
        deathState = (totalElapsed >= (Config.UnconsciousDelay or 300)) and "unconscious" or "injured"
    end

    if initialCrawlRemaining ~= nil then
        crawlRemaining = math.max(0, tonumber(initialCrawlRemaining))
    else
        crawlRemaining = (deathState == "injured") and math.max(0, (Config.CrawlDuration or 60) - totalElapsed) or 0
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    -- 1. Resurrección local instantánea en el sitio para erradicar la pantalla "Wasted" nativa
    if IsEntityDead(ped) then
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
        ped = PlayerPedId()
    end

    -- 2. Configurar salud segura en trauma, invencibilidad y desarmar
    SetEntityHealth(ped, 105)
    SetEntityInvincible(ped, true)
    ClearPedBloodDamage(ped)
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)

    -- 3. Forzar caída física INMEDIATA al suelo y expresión facial de dolor
    SetFacialIdleAnimOverride(ped, "mood_injured_1", 0)
    ClearPedTasksImmediately(ped)
    SetPedToRagdoll(ped, 1200, 1200, 0, 0, 0, 0)

    -- 4. Estado en Red (StateBag)
    LocalPlayer.state:set('isDead', true, true)
    LocalPlayer.state:set('deathState', deathState, true)

    -- 5. Silenciar comunicaciones
    MuteVoiceAndComms(true)

    -- 6. Ocultar HUD y Minimapa
    TriggerEvent('aura_hud:toggle', false)
    TriggerEvent('aura_hud:client:toggle', false)
    DisplayRadar(false)

    -- 7. Aplicar filtro cinematográfico según fase
    if deathState == "unconscious" then
        SetTimecycleModifier(Config.TimecycleUnconscious or 'DeathFailMPDark')
        SetTimecycleModifierStrength(Config.TimecycleUnconsciousStrength or 0.92)
    else
        SetTimecycleModifier(Config.TimecycleInjured or 'DeathFailMPDark')
        SetTimecycleModifierStrength(Config.TimecycleInjuredStrength or 0.50)
    end

    -- 8. Abrir NUI de Estado Crítico en la parte superior
    SetDeathCursorMode(true)
    SendNUIMessage({
        action = 'openDeathScreen',
        timeRemaining = currentBleedoutRemaining,
        deathState = deathState,
        canCrawl = (deathState == "injured" and crawlRemaining > 0),
        crawlRemaining = crawlRemaining,
        unconsciousDelay = Config.UnconsciousDelay or 300
    })

    -- 9. Notificar al servidor para persistencia atómica en base de datos
    TriggerServerEvent('aura_death:server:playerEnteredComa', currentBleedoutRemaining, deathReason or 'Trauma Crítico', killerSource, deathState)

    -- 10. Hilo de bloqueo de controles y gestión de cámara/cursor (0.0ms)
    CreateThread(function()
        while isDead do
            Wait(0)
            -- Deshabilitar todas las acciones por defecto
            DisableAllControlActions(0)

            -- DETECTAR CLICK DERECHO DEL RATÓN (INPUT_AIM = 25 / INPUT_CONTEXT_SECONDARY = 52)
            if IsDisabledControlJustPressed(0, 25) or IsControlJustPressed(0, 25) or IsDisabledControlJustPressed(0, 52) then
                SetDeathCursorMode(not isCursorActive)
            end

            -- ACCESO DIRECTO TECLA [G] (INPUT_DETONATE = 47) PARA LLAMAR A AUXILIO
            if IsDisabledControlJustPressed(0, 47) or IsControlJustPressed(0, 47) then
                SendNUIMessage({ action = 'triggerDispatchKey' })
            end

            if isCursorActive then
                -- MODO CURSOR ACTIVO
                DisableControlAction(0, 1, true)   -- Look LR bloqueado
                DisableControlAction(0, 2, true)   -- Look UD bloqueado
                EnableControlAction(0, 237, true) -- Cursor Accept (Click Izquierdo)
                EnableControlAction(0, 238, true) -- Cursor Cancel (Click Derecho)
                EnableControlAction(0, 239, true) -- Cursor X
                EnableControlAction(0, 240, true) -- Cursor Y
                EnableControlAction(0, 24, true)  -- Attack / Left Click
                EnableControlAction(0, 18, true)  -- Enter
            else
                -- MODO CÁMARA LIBRE
                EnableControlAction(0, 1, true)   -- Look LR habilitado
                EnableControlAction(0, 2, true)   -- Look UD habilitado
            end

            -- Habilitar teclas de movimiento para arrastrarse si está en fase de arrastre
            if deathState == "injured" and crawlRemaining > 0 and not isInHospitalBed then
                EnableControlAction(0, 32, true) -- W (Move Up)
                EnableControlAction(0, 33, true) -- S (Move Down)
                EnableControlAction(0, 34, true) -- A (Move Left)
                EnableControlAction(0, 35, true) -- D (Move Right)
                EnableControlAction(0, 71, true) -- Accel
                EnableControlAction(0, 72, true) -- Brake
            end

            -- HABILITAR APERTURA DE CHAT PARA COMANDOS DE ROL (/me, /do, /roll)
            EnableControlAction(0, 245, true) -- Chat T (INPUT_MP_TEXT_CHAT_ALL)
            EnableControlAction(0, 246, true) -- Chat Y (INPUT_MP_TEXT_CHAT_TEAM)
            EnableControlAction(0, 199, true) -- Pause Menu / Esc
            EnableControlAction(0, 47, true)  -- Tecla G (Auxilio)

            -- Silencio estricto de Voz Push-To-Talk
            DisableControlAction(0, 249, true) -- PTT N
            DisableControlAction(0, 19, true)  -- Alt PTT
            DisableControlAction(0, 137, true) -- Caps PTT
        end
    end)

    -- 11. Hilo de Movimiento y Animaciones de Trauma (Dolor en Suelo vs Arrastre Doloroso vs Inconsciente)
    CreateThread(function()
        local lastPainSound = GetGameTimer()
        local currentAnimState = nil -- "idle_pain", "crawling_fwd", "crawling_bwd", "immobile_pain", "ragdoll"

        -- Asegurar diccionarios cargados
        if not HasAnimDictLoaded("move_crawl") then RequestAnimDict("move_crawl") end
        if not HasAnimDictLoaded("combat@damage@writheidle_a") then RequestAnimDict("combat@damage@writheidle_a") end

        -- Breve pausa para permitir que el ragdoll inicial desplome al personaje al suelo
        Wait(400)

        while isDead do
            Wait(0)
            if not isInHospitalBed then
                local currentPed = PlayerPedId()
                local now = GetGameTimer()

                if deathState == "injured" then
                    if crawlRemaining > 0 then
                        -- FASE 1.A: HERIDO CON CAPACIDAD DE ARRASTRE DOLOROSO (0s - 60s)
                        local isMovingFwd = IsDisabledControlPressed(0, 32) or IsControlPressed(0, 32) or IsDisabledControlPressed(0, 71)
                        local isMovingBwd = IsDisabledControlPressed(0, 33) or IsControlPressed(0, 33) or IsDisabledControlPressed(0, 72)
                        local isTurningLeft = IsDisabledControlPressed(0, 34) or IsControlPressed(0, 34)
                        local isTurningRight = IsDisabledControlPressed(0, 35) or IsControlPressed(0, 35)

                        -- Rotación suave en el suelo con A y D
                        if isTurningLeft then
                            SetEntityHeading(currentPed, GetEntityHeading(currentPed) + 0.60)
                        elseif isTurningRight then
                            SetEntityHeading(currentPed, GetEntityHeading(currentPed) - 0.60)
                        end

                        if isMovingFwd then
                            -- Arrastrándose hacia adelante con esfuerzo y dolor
                            if currentAnimState ~= "crawling_fwd" or not IsEntityPlayingAnim(currentPed, "move_crawl", "onfront_fwd", 3) then
                                TaskPlayAnim(currentPed, "move_crawl", "onfront_fwd", 4.0, -4.0, -1, 1, 0, false, false, false)
                                currentAnimState = "crawling_fwd"
                            end
                            local fwd = GetEntityForwardVector(currentPed)
                            SetEntityVelocity(currentPed, fwd.x * 0.32, fwd.y * 0.32, -0.2)

                            -- Quejidos de dolor por el esfuerzo de arrastrarse cada 2.5 segundos
                            if now - lastPainSound > 2500 then
                                lastPainSound = now
                                PlayPain(currentPed, math.random(6, 8), 0, 0)
                            end
                        elseif isMovingBwd then
                            -- Arrastrándose hacia atrás
                            if currentAnimState ~= "crawling_bwd" or not IsEntityPlayingAnim(currentPed, "move_crawl", "onfront_bwd", 3) then
                                TaskPlayAnim(currentPed, "move_crawl", "onfront_bwd", 4.0, -4.0, -1, 1, 0, false, false, false)
                                currentAnimState = "crawling_bwd"
                            end
                            local fwd = GetEntityForwardVector(currentPed)
                            SetEntityVelocity(currentPed, -fwd.x * 0.20, -fwd.y * 0.20, -0.2)

                            if now - lastPainSound > 2500 then
                                lastPainSound = now
                                PlayPain(currentPed, math.random(6, 8), 0, 0)
                            end
                        else
                            -- EN REPOSO: TIRADO EN EL SUELO QUEJÁNDOSE DE DOLOR
                            if currentAnimState ~= "idle_pain" or not IsEntityPlayingAnim(currentPed, "combat@damage@writheidle_a", "writhe_idle_a", 3) then
                                TaskPlayAnim(currentPed, "combat@damage@writheidle_a", "writhe_idle_a", 4.0, -4.0, -1, 1, 0, false, false, false)
                                currentAnimState = "idle_pain"
                            end

                            -- Gemidos y quejidos de dolor periódicos en el suelo cada 4.5 segundos
                            if now - lastPainSound > 4500 then
                                lastPainSound = now
                                PlayPain(currentPed, math.random(6, 8), 0, 0)
                            end
                        end
                    else
                        -- FASE 1.B: HERIDO AGOTADO / INMÓVIL EN EL SUELO SUFRIENDO DOLOR (60s - 300s)
                        if currentAnimState ~= "immobile_pain" or not IsEntityPlayingAnim(currentPed, "combat@damage@writheidle_a", "writhe_idle_a", 3) then
                            TaskPlayAnim(currentPed, "combat@damage@writheidle_a", "writhe_idle_a", 4.0, -4.0, -1, 1, 0, false, false, false)
                            currentAnimState = "immobile_pain"
                        end

                        if now - lastPainSound > 5500 then
                            lastPainSound = now
                            PlayPain(currentPed, math.random(6, 8), 0, 0)
                        end
                    end
                else
                    -- FASE 2: INCONSCIENTE / COMA PROFUNDO (300s - 600s)
                    currentAnimState = "ragdoll"
                    if not IsPedRagdoll(currentPed) then
                        SetPedToRagdoll(currentPed, 1000, 1000, 0, 0, 0, 0)
                    end
                end
            end
        end
    end)

    -- 11. Hilo de Control Temporal (Arrastre, Transición a Inconsciencia y Sincronización)
    CreateThread(function()
        local syncCounter = 0
        while isDead do
            Wait(1000)
            if not isDead then break end

            syncCounter = syncCounter + 1

            -- Reducción del tiempo de desangrado (5 minutos = 300 segundos)
            if currentBleedoutRemaining > 0 then
                currentBleedoutRemaining = currentBleedoutRemaining - 1
            end

            -- Reducción de tiempo de arrastre si está en fase de herido (1 minuto = 60 segundos)
            if deathState == "injured" and crawlRemaining > 0 then
                crawlRemaining = crawlRemaining - 1
                if crawlRemaining == 0 then
                    SendNUIMessage({ action = 'crawlExpired' })
                    if lib and lib.notify then
                        lib.notify({
                            title = 'Agotamiento Físico',
                            description = 'Tus fuerzas se han agotado. Ya no puedes seguir arrastrándote por el suelo.',
                            type = 'inform',
                            icon = 'person-falling',
                            duration = 4000
                        })
                    end
                end
            end

            -- Transición automática a INCONSCIENTE al terminar los 5 minutos de desangrado
            if deathState == "injured" and currentBleedoutRemaining <= 0 then
                deathState = "unconscious"
                LocalPlayer.state:set('deathState', 'unconscious', true)

                -- Aplicar filtro visual más oscuro
                SetTimecycleModifier(Config.TimecycleUnconscious or 'DeathFailMPDark')
                SetTimecycleModifierStrength(Config.TimecycleUnconsciousStrength or 0.92)

                -- Notificar a la interfaz NUI para desbloquear el botón de Hospital y cambiar badge
                SendNUIMessage({ action = 'setUnconscious' })

                if lib and lib.notify then
                    lib.notify({
                        title = 'Pérdida de Consciencia',
                        description = 'Has perdido el conocimiento y entrado en coma. El traslado al hospital ya está disponible.',
                        type = 'error',
                        icon = 'bed-pulse',
                        duration = 6000
                    })
                end

                local p = PlayerPedId()
                ClearPedTasksImmediately(p)
                SetPedToRagdoll(p, 1000, 1000, 0, 0, 0, 0)
            end

            -- Sincronizar periódicamente con el servidor
            if syncCounter >= Config.SyncInterval and isDead then
                syncCounter = 0
                TriggerServerEvent('aura_death:server:syncBleedoutTime', currentBleedoutRemaining, deathState)
            end
        end
    end)
end

--- Finaliza el Estado Crítico y restaura al personaje
--- @param reviveCoords vector4|nil Coordenadas de reaparición o nil para mantener posición
--- @param isHospitalRespawn boolean Si es un respawn por PK en hospital
local function ExitCriticalState(reviveCoords, isHospitalRespawn)
    if not isDead then return end
    isDead = false
    currentBleedoutRemaining = Config.BleedoutTime

    LocalPlayer.state:set('isDead', false, true)
    ClearTimecycleModifier()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeDeathScreen' })

    MuteVoiceAndComms(false)

    local ped = PlayerPedId()
    SetEntityInvincible(ped, false)
    ClearPedTasksImmediately(ped)
    ClearPedBloodDamage(ped)
    ClearFacialIdleAnimOverride(ped)

    local finalHealth = isHospitalRespawn and Config.HospitalReviveHealth or 200
    SetEntityHealth(ped, finalHealth)

    if reviveCoords then
        SetEntityCoords(ped, reviveCoords.x, reviveCoords.y, reviveCoords.z, false, false, false, true)
        SetEntityHeading(ped, reviveCoords.w or 0.0)
    end

    TriggerEvent('aura_medical:client:resetDamage')
    TriggerEvent('aura_hud:toggle', true)
    TriggerEvent('aura_hud:client:toggle', true)
    DisplayRadar(true)
end

--- Coloca al jugador tumbado en una cama de hospital con prompt para levantarse
--- @param bedCoords vector4 Coordenadas de la cama
local function SetupHospitalBedInteraction(bedCoords)
    local ped = PlayerPedId()
    isInHospitalBed = true

    -- Cargar diccionario de animación
    local dict = Config.BedAnimation.dict
    local anim = Config.BedAnimation.anim
    lib.requestAnimDict(dict, 5000)

    -- Posicionar en la cama y reproducir animación tumbado boca arriba
    SetEntityCoords(ped, bedCoords.x, bedCoords.y, bedCoords.z, false, false, false, true)
    SetEntityHeading(ped, bedCoords.w or 0.0)
    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 1, 0, false, false, false)

    -- Mostrar TextUI de ox_lib
    if lib and lib.showTextUI then
        lib.showTextUI('[E] o [ESPACIO] - Levantarse de la cama', {
            position = 'top-center',
            icon = 'bed-pulse',
            style = {
                borderRadius = '12px',
                backgroundColor = 'rgba(10, 15, 29, 0.92)',
                color = '#40E0D0',
                border = '1px solid rgba(255, 255, 255, 0.15)'
            }
        })
    end

    -- Hilo para escuchar pulsación de tecla para levantarse
    CreateThread(function()
        while isInHospitalBed do
            Wait(0)
            local currentPed = PlayerPedId()

            -- Mantener la animación mientras esté en la cama
            if not IsEntityPlayingAnim(currentPed, dict, anim, 3) then
                TaskPlayAnim(currentPed, dict, anim, 8.0, -8.0, -1, 1, 0, false, false, false)
            end

            -- Tecla E (Control 38/51) o Espacio (Control 22) para levantarse
            if IsControlJustPressed(0, 38) or IsControlJustPressed(0, 22) then
                isInHospitalBed = false
                if lib and lib.hideTextUI then
                    lib.hideTextUI()
                end

                ClearPedTasksImmediately(currentPed)

                if lib and lib.notify then
                    lib.notify({
                        title = 'Alta Médica',
                        description = 'Te has levantado de la cama. Tus pertenencias ilícitas y objetos no personales han sido retirados.',
                        type = 'inform',
                        icon = 'hospital',
                        duration = 6000
                    })
                end
                break
            end
        end
    end)
end

-- ============================================================================
-- DETECCIÓN DE DAÑO Y MUERTE NATIVA
-- ============================================================================

-- Detección por Game Event CEventNetworkEntityDamage
AddEventHandler('gameEventTriggered', function(eventName, data)
    if eventName == 'CEventNetworkEntityDamage' then
        local victim = data[1]
        local attacker = data[2]
        local isFatal = data[6] == 1

        if victim == PlayerPedId() and not isDead then
            local health = GetEntityHealth(victim)
            if health <= Config.DeathHealthThreshold or isFatal or IsEntityDead(victim) then
                local killerServerId = nil
                if attacker and attacker ~= 0 and IsPedAPlayer(attacker) then
                    local killerPlayerId = NetworkGetPlayerIndexFromPed(attacker)
                    if killerPlayerId and killerPlayerId ~= -1 then
                        killerServerId = GetPlayerServerId(killerPlayerId)
                    end
                end
                EnterCriticalState(Config.BleedoutTime, "Trauma Físico / Heridas Graves", killerServerId)
            end
        end
    end
end)

-- Bucle de comprobación de reserva
CreateThread(function()
    while true do
        Wait(250)
        if not isDead then
            local ped = PlayerPedId()
            if DoesEntityExist(ped) then
                local health = GetEntityHealth(ped)
                if (health <= Config.DeathHealthThreshold or IsEntityDead(ped) or IsPedFatallyInjured(ped)) and not isDead then
                    EnterCriticalState(Config.BleedoutTime, "Pérdida de Signos Vitales", nil)
                end
            end
        end
    end
end)

-- ============================================================================
-- EVENTOS DE RED (CLIENT EVENTS)
-- ============================================================================

-- Reaparición en Cama de Hospital tras PK o botón
RegisterNetEvent('aura_death:client:respawnAtHospital', function(targetCoords)
    DoScreenFadeOut(1000)
    while not IsScreenFadedOut() do
        Wait(50)
    end

    local currentCoords = GetEntityCoords(PlayerPedId())
    local bedCoords = targetCoords or GetNearestHospitalBed(currentCoords)

    ExitCriticalState(bedCoords, true)

    -- Sincronizar estado vital saludable tras atención médica
    TriggerServerEvent('aura_status:server:UpdateStatus', {
        hunger = Config.HospitalReviveHunger,
        thirst = Config.HospitalReviveThirst,
        health = Config.HospitalReviveHealth,
        armor = Config.HospitalReviveArmor
    })

    SetupHospitalBedInteraction(bedCoords)

    Wait(500)
    DoScreenFadeIn(1000)
end)

-- Reanimación médica o por comando administrativo /revive
RegisterNetEvent('aura_death:client:revivePlayer', function(coords)
    if isInHospitalBed then
        isInHospitalBed = false
        if lib and lib.hideTextUI then lib.hideTextUI() end
    end
    ExitCriticalState(coords or nil, false)

    if lib and lib.notify then
        lib.notify({
            title = 'Atención Médica',
            description = 'Has sido reanimado y tus signos vitales se han estabilizado.',
            type = 'success',
            icon = 'heart-pulse',
            duration = 5000
        })
    end
end)

-- Forzar entrada a coma con tiempo específico y fase (reconectar o comando)
RegisterNetEvent('aura_death:client:setInComa', function(timeRemaining, reason, calculatedState, initialCrawlRemaining)
    EnterCriticalState(timeRemaining or Config.BleedoutTime, reason or "Estado Crítico Persistente", nil, calculatedState, initialCrawlRemaining)
end)

-- Pausar desangrado por aplicación de torniquete táctico
RegisterNetEvent('aura_death:client:pauseBleedout', function()
    if isDead then
        LocalPlayer.state:set('bleedoutPaused', true, true)
        SendNUIMessage({
            action = 'pauseBleedout'
        })
        if lib and lib.notify then
            lib.notify({
                title = 'Torniquete Aplicado',
                description = 'Se te ha colocado un torniquete táctico. La hemorragia y el desangrado se han pausado.',
                type = 'inform',
                icon = 'kit-medical',
                duration = 6000
            })
        end
    end
end)

-- Forzar ejecución de muerte para pruebas (/kill)
RegisterNetEvent('aura_death:client:killPlayer', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, 0)
    EnterCriticalState(Config.BleedoutTime, "Muerte Provocada", nil)
end)

-- Verificación de estado de muerte al cargar el personaje o reconectar
local function CheckPlayerDeathStatus()
    Wait(500)
    TriggerServerEvent('aura_death:server:checkDeathState')
end

AddEventHandler('playerSpawned', CheckPlayerDeathStatus)
RegisterNetEvent('aura_core:client:playerSpawned', CheckPlayerDeathStatus)
RegisterNetEvent('aura_core:playerSpawnedAndReady', CheckPlayerDeathStatus)
RegisterNetEvent('aura_multichar:client:characterLoaded', CheckPlayerDeathStatus)

-- Soporte en reinicio de recurso
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Wait(500)
    TriggerServerEvent('aura_death:server:checkDeathState')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if isDead then
        ClearTimecycleModifier()
        SetNuiFocus(false, false)
        MuteVoiceAndComms(false)
    end
    if isInHospitalBed and lib and lib.hideTextUI then
        lib.hideTextUI()
    end
end)

-- ============================================================================
-- EXPORTS
-- ============================================================================

exports('isPlayerDead', function()
    return isDead
end)

exports('getBleedoutRemaining', function()
    return currentBleedoutRemaining
end)

exports('revivePlayer', function()
    ExitCriticalState(nil, false)
end)
