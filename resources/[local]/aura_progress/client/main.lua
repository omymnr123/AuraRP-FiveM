-- ============================================================================
-- AURA RP - UNIVERSAL CLIENT PROGRESS BAR MODULE
-- Standalone Glassmorphic Progress Bar with Zero CEF Bug Guarantee
-- ============================================================================

local activePromise = nil
local isProgressActive = false
local currentAnim = nil
local currentProp = nil

--- Reproduce animación y sincroniza el ped si se especificó
local function PlayProgressAnimation(anim)
    if not anim then return end
    local ped = PlayerPedId()

    if anim.scenario then
        TaskStartScenarioInPlace(ped, anim.scenario, 0, true)
        currentAnim = { type = 'scenario' }
    elseif anim.dict and anim.clip then
        RequestAnimDict(anim.dict)
        local timeout = GetGameTimer() + 4000
        while not HasAnimDictLoaded(anim.dict) and GetGameTimer() < timeout do
            Wait(10)
        end

        if HasAnimDictLoaded(anim.dict) then
            local flag = anim.flag or 49
            TaskPlayAnim(ped, anim.dict, anim.clip, 3.0, 3.0, -1, flag, 0, false, false, false)
            currentAnim = { type = 'anim', dict = anim.dict, clip = anim.clip }
        end
    end
end

--- Limpieza segura de animaciones y props asociados
local function CleanUpAnimation()
    local ped = PlayerPedId()
    if currentAnim then
        if currentAnim.type == 'scenario' then
            ClearPedTasks(ped)
        elseif currentAnim.type == 'anim' then
            StopAnimTask(ped, currentAnim.dict, currentAnim.clip, 1.0)
            Wait(50)
            ClearPedTasks(ped)
        end
        currentAnim = nil
    end

    if currentProp and DoesEntityExist(currentProp) then
        DeleteEntity(currentProp)
        currentProp = nil
    end
end

--- Muestra la barra visualmente para integraciones externas (ej. ox_lib)
local function Show(label, duration, canCancel)
    SendNUIMessage({
        action = 'START_PROGRESS',
        data = {
            label = label or 'PROCESANDO...',
            duration = tonumber(duration) or 3000,
            canCancel = canCancel == true
        }
    })
end

--- Oculta la barra visualmente
local function Hide()
    SendNUIMessage({
        action = 'CANCEL_PROGRESS'
    })
end

--- Cancela la barra de progreso activa inmediatamente
local function Cancel()
    if not isProgressActive then
        Hide()
        return
    end

    isProgressActive = false
    CleanUpAnimation()
    Hide()

    if activePromise then
        activePromise:resolve(false)
        activePromise = nil
    end
end

--- Inicia la barra de progreso universal
--- Soporta tanto argumentos posicionales como objetos tipo tabla
--- @param actionLabel string|table Etiqueta de acción o tabla de configuración
--- @param durationMS number Duración en milisegundos
--- @param canCancel boolean Permitir cancelación con ESC / BACKSPACE
--- @param disableControls boolean Bloquear movimiento y combate durante el proceso
--- @return boolean True si finalizó al 100%, False si fue cancelado
local function Start(actionLabel, durationMS, canCancel, disableControls)
    -- Si ya hay una barra en ejecución, cancelar la anterior limpiamente
    if isProgressActive then
        Cancel()
        Wait(40)
    end

    local label = 'PROCESANDO...'
    local duration = 3000
    local cancellable = false
    local disable = false
    local anim = nil
    local prop = nil

    -- Detección dinámica de parámetros (Tabla o Primitivos)
    if type(actionLabel) == 'table' then
        label = actionLabel.label or actionLabel.title or actionLabel.name or 'PROCESANDO...'
        duration = tonumber(actionLabel.duration) or tonumber(actionLabel.time) or 3000
        cancellable = actionLabel.canCancel == true or actionLabel.cancel == true
        disable = actionLabel.disableControls == true or actionLabel.disable == true or actionLabel.control == true
        anim = actionLabel.anim or actionLabel.animation
        prop = actionLabel.prop
    else
        label = tostring(actionLabel or 'PROCESANDO...')
        duration = tonumber(durationMS) or 3000
        cancellable = canCancel == true
        disable = disableControls == true
    end

    if duration <= 0 then duration = 1000 end

    isProgressActive = true
    activePromise = promise.new()

    -- Ejecutar animación opcional
    if anim then
        PlayProgressAnimation(anim)
    end

    -- Emitir orden de renderizado a NUI
    Show(label, duration, cancellable)

    -- Bucle de bloqueo y escucha por frame
    CreateThread(function()
        while isProgressActive do
            Wait(0)

            -- Deshabilitar Controles (Movimiento y Combate)
            if disable then
                -- Movimiento a pie
                DisableControlAction(0, 30, true)  -- MoveLeftRight
                DisableControlAction(0, 31, true)  -- MoveUpDown
                DisableControlAction(0, 21, true)  -- Sprint
                DisableControlAction(0, 22, true)  -- Jump
                DisableControlAction(0, 23, true)  -- Enter Vehicle
                DisableControlAction(0, 36, true)  -- Duck / Stealth
                DisableControlAction(0, 44, true)  -- Cover

                -- Combate y Armamento
                DisableControlAction(0, 24, true)  -- Attack
                DisableControlAction(0, 25, true)  -- Aim
                DisableControlAction(0, 47, true)  -- Weapon Detonate
                DisableControlAction(0, 58, true)  -- Weapon Light
                DisableControlAction(0, 140, true) -- MeleeAttackLight
                DisableControlAction(0, 141, true) -- MeleeAttackHeavy
                DisableControlAction(0, 142, true) -- MeleeAttackAlternate
                DisableControlAction(0, 257, true) -- Attack 2
                DisableControlAction(0, 263, true) -- Melee Attack 1
                DisableControlAction(0, 264, true) -- Melee Attack 2
                DisablePlayerFiring(PlayerPedId(), true)

                -- Manejo de Vehículo
                DisableControlAction(0, 71, true)  -- Vehicle Accelerate
                DisableControlAction(0, 72, true)  -- Vehicle Brake/Reverse
                DisableControlAction(0, 75, true)  -- Exit Vehicle
            end

            -- Cancelación manual del jugador (ESC: 200/322 | BACKSPACE: 177)
            if cancellable then
                if IsControlJustPressed(0, 200) or IsControlJustPressed(0, 322) or IsControlJustPressed(0, 177) or
                   IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 322) or IsDisabledControlJustPressed(0, 177) then
                    Cancel()
                    break
                end
            end
        end
    end)

    -- Esperar resolución asíncrona de la promesa
    local result = Citizen.Await(activePromise)
    isProgressActive = false
    CleanUpAnimation()
    activePromise = nil

    return result
end

--- Retorna si existe un progreso en curso
local function IsActive()
    return isProgressActive
end

-- ============================================================================
-- NUI CALLBACKS
-- ============================================================================

RegisterNUICallback('progressComplete', function(data, cb)
    if isProgressActive and activePromise then
        isProgressActive = false
        CleanUpAnimation()
        activePromise:resolve(true)
        activePromise = nil
    end
    cb('ok')
end)

RegisterNUICallback('progressCancel', function(data, cb)
    if isProgressActive and activePromise then
        isProgressActive = false
        CleanUpAnimation()
        activePromise:resolve(false)
        activePromise = nil
    end
    cb('ok')
end)

-- ============================================================================
-- EXPORTS
-- ============================================================================

exports('Start', Start)
exports('Cancel', Cancel)
exports('IsActive', IsActive)
exports('Show', Show)
exports('Hide', Hide)

-- ============================================================================
-- COMANDOS DE PRUEBA / DEBUG
-- ============================================================================

RegisterCommand('testprogress', function(source, args)
    local seconds = tonumber(args[1]) or 5
    local ms = seconds * 1000
    local canCancel = args[2] == '1' or args[2] == 'true'
    local disableControls = args[3] == '1' or args[3] == 'true'
    local label = args[4] or 'HACKEANDO TERMINAL...'

    TriggerEvent('chat:addMessage', {
        color = { 64, 224, 208 },
        multiline = true,
        args = { '[AuraRP Progress]', string.format('Iniciando prueba: "%s" (%d s) | Cancelable: %s | Bloqueo: %s', label, seconds, tostring(canCancel), tostring(disableControls)) }
    })

    local success = Start(label, ms, canCancel, disableControls)

    if success then
        TriggerEvent('chat:addMessage', {
            color = { 64, 224, 208 },
            multiline = true,
            args = { '[AuraRP Progress]', '^2PROCESO COMPLETADO AL 100% [true]' }
        })
    else
        TriggerEvent('chat:addMessage', {
            color = { 255, 0, 127 },
            multiline = true,
            args = { '[AuraRP Progress]', '^1PROCESO CANCELADO O INTERRUMPIDO [false]' }
        })
    end
end, false)
