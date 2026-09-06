-- ============================================================================
-- AURA DEATH: CLIENT MAIN CONTROLLER (PHASE 8 CRITICAL STATE & COMA SYSTEM)
-- ============================================================================

local isDead = false
local currentBleedoutRemaining = Config.BleedoutTime
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

-- Desactivar auto-spawn nativo de GTA V para erradicar la pantalla "Wasted"
CreateThread(function()
    if exports.spawnmanager then
        exports.spawnmanager:setAutoSpawn(false)
    end
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

--- Inicia el Estado Crítico / Coma del Jugador
--- @param timeRemaining number Tiempo en segundos de cuenta regresiva
--- @param deathReason string Causa de la muerte o trauma
--- @param killerSource number|string Fuente del atacante si existe
local function EnterCriticalState(timeRemaining, deathReason, killerSource)
    if isDead then return end
    isDead = true
    isInHospitalBed = false
    currentBleedoutRemaining = tonumber(timeRemaining) or Config.BleedoutTime

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    -- 1. Resurrección local instantánea en el sitio para erradicar la pantalla "Wasted" nativa
    if IsEntityDead(ped) then
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
        ped = PlayerPedId()
    end

    -- 2. Configurar salud segura en coma, invencibilidad y forzar ragdoll
    SetEntityHealth(ped, 105)
    SetEntityInvincible(ped, true)
    ClearPedBloodDamage(ped)
    SetPedToRagdoll(ped, 1000, 1000, 0, 0, 0, 0)

    -- 3. Estado en Red (StateBag)
    LocalPlayer.state:set('isDead', true, true)

    -- 4. Silenciar comunicaciones
    MuteVoiceAndComms(true)

    -- 5. Ocultar HUD y Minimapa
    TriggerEvent('aura_hud:toggle', false)
    TriggerEvent('aura_hud:client:toggle', false)
    DisplayRadar(false)

    -- 6. Aplicar filtro cinematográfico desaturado
    SetTimecycleModifier(Config.TimecycleModifier)
    SetTimecycleModifierStrength(Config.TimecycleStrength)

    -- 7. Abrir NUI de Estado Crítico en la parte superior
    SetDeathCursorMode(true)
    SendNUIMessage({
        action = 'openDeathScreen',
        timeRemaining = currentBleedoutRemaining
    })

    -- 8. Notificar al servidor para persistencia atómica en base de datos
    TriggerServerEvent('aura_death:server:playerEnteredComa', currentBleedoutRemaining, deathReason or 'Trauma Crítico', killerSource)

    -- 9. Hilo optimizado a 0.0ms para bloqueo de controles y gestión de cámara/cursor
    CreateThread(function()
        while isDead do
            Wait(0)
            -- Deshabilitar todas las acciones por defecto
            DisableAllControlActions(0)

            -- DETECTAR CLICK DERECHO DEL RATÓN (INPUT_AIM = 25 / INPUT_CONTEXT_SECONDARY = 52)
            -- Alterna entre Modo Cursor (para pulsar botones NUI) y Modo Cámara Libre (para mover la vista 360º)
            if IsDisabledControlJustPressed(0, 25) or IsControlJustPressed(0, 25) or IsDisabledControlJustPressed(0, 52) then
                SetDeathCursorMode(not isCursorActive)
            end

            if isCursorActive then
                -- MODO CURSOR ACTIVO: El ratón mueve el puntero de la interfaz NUI sin girar la cámara del juego
                DisableControlAction(0, 1, true)   -- Look LR bloqueado
                DisableControlAction(0, 2, true)   -- Look UD bloqueado
                EnableControlAction(0, 239, true) -- Cursor X
                EnableControlAction(0, 240, true) -- Cursor Y
            else
                -- MODO CÁMARA LIBRE: El cursor desaparece y el ratón gira libremente la cámara del juego
                EnableControlAction(0, 1, true)   -- Look LR habilitado
                EnableControlAction(0, 2, true)   -- Look UD habilitado
            end

            -- HABILITAR APERTURA DE CHAT PARA COMANDOS DE ROL (/me, /do, /roll)
            EnableControlAction(0, 245, true) -- Chat T (INPUT_MP_TEXT_CHAT_ALL)
            EnableControlAction(0, 246, true) -- Chat Y (INPUT_MP_TEXT_CHAT_TEAM)
            EnableControlAction(0, 199, true) -- Pause Menu / Esc

            -- Silencio estricto de Voz Push-To-Talk
            DisableControlAction(0, 249, true) -- PTT N
            DisableControlAction(0, 19, true)  -- Alt PTT
            DisableControlAction(0, 137, true) -- Caps PTT

            -- Mantener el ped en ragdoll constante si no está en cama
            if not isInHospitalBed then
                local currentPed = PlayerPedId()
                if not IsPedRagdoll(currentPed) then
                    SetPedToRagdoll(currentPed, 1000, 1000, 0, 0, 0, 0)
                end
            end
        end
    end)

    -- 10. Hilo de sincronización periódica del tiempo restante con el servidor
    CreateThread(function()
        while isDead do
            Wait(Config.SyncInterval * 1000)
            if isDead and currentBleedoutRemaining > 0 then
                TriggerServerEvent('aura_death:server:syncBleedoutTime', currentBleedoutRemaining)
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

-- Forzar entrada a coma con tiempo específico (reconectar o comando)
RegisterNetEvent('aura_death:client:setInComa', function(timeRemaining, reason)
    EnterCriticalState(timeRemaining or Config.BleedoutTime, reason or "Estado Crítico Persistente", nil)
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
