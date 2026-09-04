-- ============================================================================
-- AURA GANGS: CLIENT THEFT & CHOP SHOP CONTROLLER
-- 2-Lockpick System (Doors & Hotwire) + Physical Chop Shop Dismantling
-- ============================================================================

local isLockpicking = false

--- Obtiene el vehículo más cercano frente al jugador
--- @param maxDist number
--- @return number | nil, vector3 | nil
local function GetClosestVehicleInFront(maxDist)
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local targetCoords = coords + (forward * (maxDist or 2.5))

    local ray = StartShapeTestSweptSphere(coords.x, coords.y, coords.z, targetCoords.x, targetCoords.y, targetCoords.z, 0.5, 10, ped, 7)
    local _, hit, _, _, entity = GetShapeTestResult(ray)

    if hit == 1 and DoesEntityExist(entity) and IsEntityAVehicle(entity) then
        return entity, GetEntityCoords(entity)
    end

    local closeVeh = lib.getClosestVehicle(coords, maxDist or 2.5, true)
    if closeVeh and DoesEntityExist(closeVeh) then
        return closeVeh, GetEntityCoords(closeVeh)
    end

    return nil, nil
end

-- ============================================================================
-- 1. GANZÚA BÁSICA (CERRADURAS EXTERIORES DE VEHÍCULOS)
-- ============================================================================

local function UseLockpick()
    if isLockpicking then return end
    local ped = cache.ped

    if IsPedInAnyVehicle(ped, false) then
        lib.notify({ title = 'Cerrajería', description = 'No puedes usar la ganzúa básica desde el interior.', type = 'error' })
        return
    end

    local vehicle = GetClosestVehicleInFront(2.5)
    if not vehicle or not DoesEntityExist(vehicle) then
        lib.notify({ title = 'Cerrajería', description = 'No hay ningún vehículo cerca para forzar.', type = 'error' })
        return
    end

    local lockStatus = GetVehicleDoorLockStatus(vehicle)
    if lockStatus <= 1 then
        lib.notify({ title = 'Cerrajería', description = 'Las puertas de este vehículo ya están abiertas.', type = 'inform' })
        return
    end

    isLockpicking = true

    -- Animación de forzado de cerradura
    lib.requestAnimDict('anim@amb@clubhouse@tutorial@bkr_tut_ig3@')
    TaskPlayAnim(ped, 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', 'machinic_loop_mechandplayer', 3.0, 3.0, -1, 49, 0, false, false, false)

    local success = false
    if GetResourceState('aura_minigames') == 'started' then
        success = exports.aura_minigames:Lockpick({ pins = 4, difficulty = 'medium' })
    else
        success = lib.skillCheck(Config.Theft.doorSkillCheck, Config.Theft.skillCheckInputs)
    end
    ClearPedTasks(ped)
    isLockpicking = false

    if success then
        SetVehicleDoorsLocked(vehicle, 1)
        SetVehicleDoorsLockedForAllPlayers(vehicle, false)
        SetVehicleNeedsToBeHotwired(vehicle, false)
        SetVehicleEngineOn(vehicle, false, true, true)
        Entity(vehicle).state:set('stolenLocked', true, true)
        Entity(vehicle).state:set('hotwired', false, true)
        PlaySoundFrontend(-1, "Pin_Good", "DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS", true)

        -- Alerta inmediata al Despacho Inteligente de LSPD
        pcall(function()
            exports.aura_police:TriggerVehicleTheftAlert(vehicle)
        end)

        lib.notify({
            title = 'Cerrajería',
            description = 'Has forzado la puerta. Sube y usa la Ganzúa Electrónica (adv_lockpick) para puentear el motor.',
            type = 'success',
            duration = 6000
        })
    else
        PlaySoundFrontend(-1, "Pin_Bad", "DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS", true)
        SetVehicleAlarm(vehicle, true)
        SetVehicleAlarmTimeLeft(vehicle, 30000)
        StartVehicleAlarm(vehicle)

        -- Disparar alerta policial por saltar la alarma
        pcall(function()
            exports.aura_police:TriggerVehicleTheftAlert(vehicle)
        end)

        -- Probabilidad de que la ganzúa se rompa
        local roll = math.random(1, 100)
        if roll <= Config.Theft.breakChance then
            TriggerServerEvent('aura_gangs:server:breakItem', Config.Theft.lockpickItem)
            lib.notify({
                title = 'Cerrajería',
                description = '¡La ganzúa se ha quebrado dentro del bombín de la cerradura!',
                type = 'error'
            })
        else
            lib.notify({
                title = 'Cerrajería',
                description = 'Has fallado al forzar la cerradura.',
                type = 'error'
            })
        end
    end
end
exports('useLockpick', UseLockpick)

-- ============================================================================
-- 2. GANZÚA AVANZADA (PUENTEO DE MOTOR / HOTWIRE)
-- ============================================================================

local function UseAdvLockpick()
    if isLockpicking then return end
    local ped = cache.ped

    if not IsPedInAnyVehicle(ped, false) then
        lib.notify({ title = 'Encendido', description = 'Debes estar dentro del vehículo para puentear el encendido.', type = 'error' })
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if GetPedInVehicleSeat(vehicle, -1) ~= ped then
        lib.notify({ title = 'Encendido', description = 'Debes estar sentado en el asiento del conductor.', type = 'error' })
        return
    end

    local vehState = Entity(vehicle).state
    if vehState.hotwired or GetIsVehicleEngineRunning(vehicle) then
        lib.notify({ title = 'Encendido', description = 'El motor de este vehículo ya está puenteado y en marcha.', type = 'inform' })
        return
    end

    isLockpicking = true

    -- Animación de toqueteo de cables bajo el volante
    lib.requestAnimDict('anim@veh@std@panto@ds@base')
    TaskPlayAnim(ped, 'anim@veh@std@panto@ds@base', 'hotwire', 3.0, 3.0, -1, 49, 0, false, false, false)

    local success = false
    if GetResourceState('aura_minigames') == 'started' then
        success = exports.aura_minigames:ECUBypass({ timeLimit = 35, syncHoldTime = 1.6 })
    else
        success = lib.skillCheck(Config.Theft.hotwireSkillCheck, Config.Theft.skillCheckInputs)
    end
    ClearPedTasks(ped)
    isLockpicking = false

    if success then
        SetVehicleNeedsToBeHotwired(vehicle, false)
        SetVehicleEngineOn(vehicle, true, true, false)
        Entity(vehicle).state:set('hotwired', true, true)
        PlaySoundFrontend(-1, "Pin_Good", "DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS", true)

        if shownHotwirePrompt then
            shownHotwirePrompt = false
            lib.hideTextUI()
        end

        lib.notify({
            title = 'Puenteo Electrónico',
            description = 'Has decodificado la centralita y encendido el motor con éxito.',
            type = 'success',
            duration = 6000
        })
    else
        PlaySoundFrontend(-1, "Pin_Bad", "DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS", true)
        SetVehicleAlarm(vehicle, true)
        SetVehicleAlarmTimeLeft(vehicle, 25000)
        StartVehicleAlarm(vehicle)

        -- Alerta policial por manipulación electrónica
        pcall(function()
            exports.aura_police:TriggerVehicleTheftAlert(vehicle)
        end)

        local roll = math.random(1, 100)
        if roll <= Config.Theft.advBreakChance then
            TriggerServerEvent('aura_gangs:server:breakItem', Config.Theft.advLockpickItem)
            lib.notify({
                title = 'Puenteo Electrónico',
                description = '¡Cortocircuito en el chip! La ganzúa electrónica se ha quemado.',
                type = 'error'
            })
        else
            lib.notify({
                title = 'Puenteo Electrónico',
                description = 'Fallo al puentear la centralita del vehículo.',
                type = 'error'
            })
        end
    end
end
exports('useAdvLockpick', UseAdvLockpick)

-- ============================================================================
-- CONTROL DE IGNICIÓN: PREVENCIÓN DE ARRANQUE Y PUENTEO NATIVO DE GTA V
-- ============================================================================

local shownHotwirePrompt = false

CreateThread(function()
    while true do
        local sleep = 1000
        local veh = cache.vehicle
        local seat = cache.seat

        if veh and DoesEntityExist(veh) and seat == -1 then
            local vehState = Entity(veh).state
            -- Si el vehículo fue forzado/robado o está marcado y no ha sido puenteado con éxito
            if vehState.stolenLocked and not vehState.hotwired then
                sleep = 0

                -- Desactivar completamente la secuencia nativa de GTA V de puenteo automático
                SetVehicleNeedsToBeHotwired(veh, false)
                SetVehicleEngineOn(veh, false, true, true)

                -- Desactivar acelerador y freno/marcha atrás
                DisableControlAction(0, 71, true) -- INPUT_VEH_ACCELERATE
                DisableControlAction(0, 72, true) -- INPUT_VEH_BRAKE

                if not shownHotwirePrompt then
                    shownHotwirePrompt = true
                    lib.showTextUI('[adv_lockpick] Puentear Encendido del Motor', {
                        position = 'top-center',
                        icon = 'bolt',
                        style = {
                            borderRadius = 8,
                            backgroundColor = 'rgba(10, 15, 29, 0.92)',
                            color = '#40E0D0',
                            border = '1px solid #FF007F'
                        }
                    })
                end

                -- Si intenta acelerar, avisar con notificación flotante
                if IsDisabledControlJustPressed(0, 71) or IsDisabledControlJustPressed(0, 72) then
                    lib.notify({
                        title = 'Sin Contacto',
                        description = 'El vehículo no tiene las llaves ni el encendido puenteado. Usa tu Ganzúa Electrónica (adv_lockpick).',
                        type = 'error',
                        duration = 4000
                    })
                end
            else
                if shownHotwirePrompt then
                    shownHotwirePrompt = false
                    lib.hideTextUI()
                end
            end
        else
            if shownHotwirePrompt then
                shownHotwirePrompt = false
                lib.hideTextUI()
            end
        end

        Wait(sleep)
    end
end)

-- ============================================================================
-- 3. HERRAMIENTAS DE ADMINISTRACIÓN / TEST (SPAWN Y BLOQUEO DE VEHÍCULOS)
-- ============================================================================

local function SpawnLockedVehicle(modelName)
    local ped = cache.ped
    local modelStr = (modelName and tostring(modelName):lower()) or 'sultan'
    local modelHash = joaat(modelStr)

    if not IsModelInCdimage(modelHash) or not IsModelAVehicle(modelHash) then
        lib.notify({
            title = 'Admin Vehículos',
            description = string.format("El modelo '%s' no existe o no es un vehículo válido.", modelStr),
            type = 'error'
        })
        return
    end

    lib.requestModel(modelHash, 5000)

    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local forward = GetEntityForwardVector(ped)
    local spawnCoords = coords + (forward * 3.8)

    local success, groundZ = GetGroundZFor_3dCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z + 1.0, false)
    if success then
        spawnCoords = vec3(spawnCoords.x, spawnCoords.y, groundZ + 0.1)
    end

    local veh = CreateVehicle(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, heading, true, false)
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehicleDirtLevel(veh, 0.0)
    SetVehicleEngineOn(veh, false, true, true)
    
    -- Bloquear cerraduras por completo (Estado 2 = Locked)
    SetVehicleDoorsLocked(veh, 2)
    SetVehicleDoorsLockedForAllPlayers(veh, true)

    Entity(veh).state:set('stolenLocked', true, true)
    Entity(veh).state:set('hotwired', false, true)

    local plate = "LOCK" .. tostring(math.random(100, 999))
    SetVehicleNumberPlateText(veh, plate)

    SetModelAsNoLongerNeeded(modelHash)

    -- Entregar ganzúas de prueba automáticamente al admin
    TriggerServerEvent('aura_gangs:server:giveTestLockpicks')

    lib.notify({
        title = 'Vehículo Bloqueado Generado',
        description = string.format("Modelo: %s | Matrícula: [%s]\nCerraduras bloqueadas (Estado 2). Usa 'lockpick' en la puerta y 'adv_lockpick' para puentear.", modelStr:upper(), plate),
        type = 'success',
        duration = 8000
    })
end

RegisterCommand('spawnlocked', function(source, args)
    local model = args and args[1]
    SpawnLockedVehicle(model)
end, false)

RegisterCommand('vehlocked', function(source, args)
    local model = args and args[1]
    SpawnLockedVehicle(model)
end, false)

RegisterCommand('carrolocked', function(source, args)
    local model = args and args[1]
    SpawnLockedVehicle(model)
end, false)

RegisterCommand('spawntheft', function(source, args)
    local model = args and args[1]
    SpawnLockedVehicle(model)
end, false)

-- Comando para bloquear cualquier vehículo cercano de forma manual
RegisterCommand('lockveh', function()
    local ped = cache.ped
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        local coords = GetEntityCoords(ped)
        veh = lib.getClosestVehicle(coords, 5.0, true)
    end

    if not veh or not DoesEntityExist(veh) then
        lib.notify({ title = 'Admin Vehículos', description = 'No hay ningún vehículo cerca para bloquear.', type = 'error' })
        return
    end

    SetVehicleDoorsLocked(veh, 2)
    SetVehicleDoorsLockedForAllPlayers(veh, true)
    SetVehicleEngineOn(veh, false, true, true)
    SetVehicleNeedsToBeHotwired(veh, false)

    Entity(veh).state:set('stolenLocked', true, true)
    Entity(veh).state:set('hotwired', false, true)

    local plate = GetVehicleNumberPlateText(veh)
    lib.notify({
        title = 'Admin Vehículos',
        description = string.format('Vehículo [%s] bloqueado manualmente (cerrado y motor apagado).', plate),
        type = 'inform'
    })
end, false)

RegisterCommand('bloquearveh', function()
    ExecuteCommand('lockveh')
end, false)

-- Comando para borrar el vehículo de prueba
RegisterCommand('delveh', function()
    local ped = cache.ped
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        local coords = GetEntityCoords(ped)
        veh = lib.getClosestVehicle(coords, 5.0, true)
    end

    if not veh or not DoesEntityExist(veh) then
        lib.notify({ title = 'Admin Vehículos', description = 'No hay ningún vehículo cerca para eliminar.', type = 'error' })
        return
    end

    SetEntityAsMissionEntity(veh, true, true)
    DeleteVehicle(veh)
    lib.notify({ title = 'Admin Vehículos', description = 'Vehículo eliminado con éxito.', type = 'success' })
end, false)

RegisterCommand('borrarveh', function()
    ExecuteCommand('delveh')
end, false)

