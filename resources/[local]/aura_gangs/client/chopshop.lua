-- ============================================================================
-- AURA GANGS: CLIENT CHOP SHOP CONTROLLER
-- Ultra-Realistic Bone-Specific Dismantling, Procedural Destruction & Particles
-- ============================================================================

local isDismantling = false

--- Lista de piezas y huesos requeridos para validar si el chasis puede ser compactado
local BONE_PARTS_SCHEMA = {
    { key = 'hood', bone = 'bonnet' },
    { key = 'door_dside_f', bone = 'door_dside_f' },
    { key = 'door_pside_f', bone = 'door_pside_f' },
    { key = 'door_dside_r', bone = 'door_dside_r' },
    { key = 'door_pside_r', bone = 'door_pside_r' },
    { key = 'wheel_lf', bone = 'wheel_lf' },
    { key = 'wheel_rf', bone = 'wheel_rf' },
    { key = 'wheel_lr', bone = 'wheel_lr' },
    { key = 'wheel_rr', bone = 'wheel_rr' },
    { key = 'engine', bone = 'engine' },
    { key = 'exhaust', bone = 'exhaust', alt = 'exhaust_2' }
}

--- Comprueba si una posición está dentro de alguna bahía de desguace físico
--- @param coords vector3
--- @return boolean, table | nil
local function IsInChopShopBay(coords)
    if not Config.ChopShop or not Config.ChopShop.Locations then return false end
    for _, bay in ipairs(Config.ChopShop.Locations) do
        local dist = #(coords - bay.coords)
        if dist <= bay.radius then
            return true, bay
        end
    end
    return false, nil
end

--- Comprueba si el jugador pertenece a una banda registrada
--- @return boolean
local function IsPlayerInGang()
    local pJob = LocalPlayer.state.job
    if not pJob then return false end
    if LocalPlayer.state.isGang == true then return true end
    if Config.Gangs and Config.Gangs[pJob] then
        return true
    end
    return false
end

--- Comprueba si todos los componentes existentes en el vehículo han sido ya retirados
--- @param veh number Entity handle
--- @return boolean
local function CanChopChassis(veh)
    local state = Entity(veh).state
    if state.dismantled_chassis then return false end

    for _, part in ipairs(BONE_PARTS_SCHEMA) do
        local boneIdx = GetEntityBoneIndexByName(veh, part.bone)
        if boneIdx == -1 and part.alt then
            boneIdx = GetEntityBoneIndexByName(veh, part.alt)
        end

        -- Si el modelo físico del coche contiene este hueso, debe estar desmontado
        if boneIdx ~= -1 then
            if not state['dismantled_' .. part.key] then
                return false
            end
        end
    end

    return true
end

-- ============================================================================
-- CONTROL DE PARTÍCULAS DE SOPLETE / CORTE
-- ============================================================================

local function StartWeldingSparks(entity, boneName)
    local coords
    local boneIdx = GetEntityBoneIndexByName(entity, boneName)
    if boneIdx ~= -1 then
        coords = GetWorldPositionOfEntityBone(entity, boneIdx)
    else
        coords = GetEntityCoords(entity)
    end

    lib.requestNamedPtfxAsset('core', 2000)
    UseParticleFxAssetNextCall('core')
    local ptfx = StartParticleFxLoopedAtCoord(
        'ent_sht_petrol_spark',
        coords.x, coords.y, coords.z,
        0.0, 0.0, 0.0,
        1.2,
        false, false, false, false
    )
    return ptfx
end

local function StopWeldingSparks(ptfx)
    if ptfx and DoesParticleFxLoopedExist(ptfx) then
        StopParticleFxLooped(ptfx, false)
    end
end

-- ============================================================================
-- SINCRONIZACIÓN VISUAL DE DAÑO Y DESPRENDIMIENTO FÍSICO
-- ============================================================================

local function ApplyVisualBreak(veh, partKey)
    if not veh or not DoesEntityExist(veh) then return end

    -- Las puertas y capó desaparecen directamente de la carrocería sin caer al suelo (deleteDoor = true)
    if partKey == 'hood' then
        SetVehicleDoorBroken(veh, 4, true)
    elseif partKey == 'door_dside_f' then
        SetVehicleDoorBroken(veh, 0, true)
    elseif partKey == 'door_pside_f' then
        SetVehicleDoorBroken(veh, 1, true)
    elseif partKey == 'door_dside_r' then
        SetVehicleDoorBroken(veh, 2, true)
    elseif partKey == 'door_pside_r' then
        SetVehicleDoorBroken(veh, 3, true)
    -- Desaparición completa de ruedas completas (neumático + llanta) desanclándolas y borrándolas
    elseif partKey == 'wheel_lf' then
        SetVehicleTyreBurst(veh, 0, true, 1000.0)
        BreakOffVehicleWheel(veh, 0, false, true, true, false)
    elseif partKey == 'wheel_rf' then
        SetVehicleTyreBurst(veh, 1, true, 1000.0)
        BreakOffVehicleWheel(veh, 1, false, true, true, false)
    elseif partKey == 'wheel_lr' then
        SetVehicleTyreBurst(veh, 4, true, 1000.0)
        BreakOffVehicleWheel(veh, 4, false, true, true, false)
    elseif partKey == 'wheel_rr' then
        SetVehicleTyreBurst(veh, 5, true, 1000.0)
        BreakOffVehicleWheel(veh, 5, false, true, true, false)
    -- Motor: deshabilitación total y retirada de todas las piezas y tapas mecánicas
    elseif partKey == 'engine' then
        SetVehicleEngineHealth(veh, -4000.0)
        SetVehicleUndriveable(veh, true)
        SetVehicleEngineOn(veh, false, true, true)
        SetVehicleMod(veh, 11, -1, false) -- Motor
        SetVehicleMod(veh, 39, -1, false) -- Tapa/bloque motor
        SetVehicleMod(veh, 40, -1, false) -- Filtro de aire
        SetVehicleMod(veh, 41, -1, false) -- Torretas y refuerzos
        SetVehicleMod(veh, 45, -1, false) -- Depósito / accesorios
    -- Escape: retirada de la línea y embellecedores de escape
    elseif partKey == 'exhaust' then
        SetVehicleMod(veh, 4, -1, false) -- Retirar escape
    end
end

-- Evento de sincronización broadcast
RegisterNetEvent('aura_gangs:client:syncPartBreak', function(netId, partKey)
    if not NetworkDoesNetworkIdExist(netId) then return end
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not veh or not DoesEntityExist(veh) then return end
    ApplyVisualBreak(veh, partKey)
end)

-- Listener de StateBags para sincronización continua al entrar en zona de streaming
AddStateBagChangeHandler(nil, nil, function(bagName, key, value, _unused, replicated)
    if not string.find(key, '^dismantled_') or not value then return end
    local netId = tonumber(string.match(bagName, 'entity:(%d+)'))
    if not netId or not NetworkDoesNetworkIdExist(netId) then return end

    local veh = NetworkGetEntityFromNetworkId(netId)
    if not veh or not DoesEntityExist(veh) then return end

    local partKey = string.gsub(key, '^dismantled_', '')
    ApplyVisualBreak(veh, partKey)
end)

-- ============================================================================
-- LÓGICA DE INTERACCIÓN Y DESMONTAJE
-- ============================================================================

local function DismantlePart(veh, partKey, opts)
    if isDismantling then return end
    if not veh or not DoesEntityExist(veh) then return end

    local netId = NetworkGetNetworkIdFromEntity(veh)
    if not netId or netId == 0 then return end

    isDismantling = true

    local ptfx = nil
    if opts.isWelding then
        ptfx = StartWeldingSparks(veh, opts.bone or 'engine')
    end

    local success = lib.progressBar({
        duration = opts.duration or 8000,
        label = opts.progressLabel or 'Desmontando componente...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = opts.anim,
        prop = opts.prop
    })

    if ptfx then
        StopWeldingSparks(ptfx)
    end

    if not success then
        isDismantling = false
        lib.notify({
            title = 'Desguace Cancelado',
            description = 'Has interrumpido el proceso de desmontaje.',
            type = 'inform'
        })
        return
    end

    local vehClass = GetVehicleClass(veh)
    -- Notificar al servidor para entrega segura y replicación en StateBag
    lib.callback('aura_gangs:server:dismantlePart', false, function(granted, msg)
        isDismantling = false
        if granted then
            -- Aplicar efecto visual garantizado en cliente
            ApplyVisualBreak(veh, partKey)
            lib.notify({
                title = 'Pieza Obtenida',
                description = msg,
                type = 'success',
                duration = 5000
            })
        else
            lib.notify({
                title = 'Desguace',
                description = msg or 'No se pudo retirar la pieza.',
                type = 'error'
            })
        end
    end, netId, partKey, vehClass)
end

local function ScrapChassis(veh)
    if isDismantling then return end
    if not veh or not DoesEntityExist(veh) then return end

    local netId = NetworkGetNetworkIdFromEntity(veh)
    if not netId or netId == 0 then return end

    local confirm = lib.alertDialog({
        header = 'Desguace Final de Chasis',
        content = '¿Deseas cortar y compactar el chasis restante con el soplete? El vehículo será destruido de forma permanente y recibirás el remanente de chatarra.',
        centered = true,
        cancel = true
    })

    if confirm ~= 'confirm' then return end

    isDismantling = true

    local coords = GetEntityCoords(veh)
    lib.requestNamedPtfxAsset('core', 2000)
    UseParticleFxAssetNextCall('core')
    local ptfx = StartParticleFxLoopedAtCoord(
        'ent_sht_petrol_spark',
        coords.x, coords.y, coords.z,
        0.0, 0.0, 0.0,
        1.2,
        false, false, false, false
    )

    local chassisCfg = Config.ChopShop.Parts['chassis']
    local success = lib.progressBar({
        duration = (chassisCfg and chassisCfg.duration) or 12000,
        label = 'Cortando pilares y compactando chasis...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'amb@world_human_welding@male@base', clip = 'base' },
        prop = { model = 'prop_weld_torch', bone = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }
    })

    if ptfx and DoesParticleFxLoopedExist(ptfx) then
        StopParticleFxLooped(ptfx, false)
    end

    if not success then
        isDismantling = false
        lib.notify({ title = 'Desguace', description = 'Cancelado el corte del bastidor.', type = 'inform' })
        return
    end

    local vehClass = GetVehicleClass(veh)
    lib.callback('aura_gangs:server:scrapChassis', false, function(granted, msg)
        isDismantling = false
        if granted then
            lib.notify({
                title = 'Chasis Desguazado',
                description = msg,
                type = 'success',
                duration = 7000
            })
        else
            lib.notify({
                title = 'Error de Desguace',
                description = msg or 'No se pudo compactar el bastidor.',
                type = 'error'
            })
        end
    end, netId, vehClass)
end

-- ============================================================================
-- REGISTRO DE PUNTOS DE INTERACCIÓN EN OX_TARGET POR HUESOS (BONES)
-- ============================================================================

CreateThread(function()
    -- 1. Marcadores de mapa (Blips) para miembros de bandas
    for _, bay in ipairs(Config.ChopShop.Locations) do
        local blip = AddBlipForCoord(bay.coords.x, bay.coords.y, bay.coords.z)
        SetBlipSprite(blip, 227) -- Icono de garaje/herramienta
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.75)
        SetBlipColour(blip, 1)   -- Rojo / Clandestino
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName("Desguace Clandestino (" .. bay.name .. ")")
        EndTextCommandSetBlipName(blip)
    end

    -- 2. Integración de ox_target con detección de Huesos
    exports.ox_target:addGlobalVehicle({
        -- A. CAPÓ (HOOD)
        {
            name = 'aura_chop_hood',
            icon = 'fa-solid fa-car',
            label = 'Desmontar Capó',
            bones = { 'bonnet' },
            distance = 2.2,
            canInteract = function(entity)
                if isDismantling then return false end
                if not IsInChopShopBay(GetEntityCoords(entity)) then return false end
                if not IsPlayerInGang() then return false end
                if not IsVehicleSeatFree(entity, -1) or GetVehicleNumberOfPassengers(entity) > 0 then return false end
                return not Entity(entity).state.dismantled_hood
            end,
            onSelect = function(data)
                DismantlePart(data.entity, 'hood', {
                    doorIndex = 4,
                    progressLabel = 'Desatornillando bisagras y retirando capó...',
                    duration = Config.ChopShop.Parts['hood'].duration or 8000,
                    anim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer' },
                    prop = { model = 'prop_tool_screwdvr01', bone = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }
                })
            end
        },

        -- B. PUERTA DELANTERA IZQUIERDA (CONDUCTOR)
        {
            name = 'aura_chop_door_dside_f',
            icon = 'fa-solid fa-door-open',
            label = 'Desmontar Puerta Conductor',
            bones = { 'door_dside_f' },
            distance = 2.2,
            canInteract = function(entity)
                if isDismantling then return false end
                if not IsInChopShopBay(GetEntityCoords(entity)) then return false end
                if not IsPlayerInGang() then return false end
                if not IsVehicleSeatFree(entity, -1) or GetVehicleNumberOfPassengers(entity) > 0 then return false end
                return not Entity(entity).state.dismantled_door_dside_f
            end,
            onSelect = function(data)
                DismantlePart(data.entity, 'door_dside_f', {
                    doorIndex = 0,
                    progressLabel = 'Desmontando cerradura y paneles de puerta...',
                    duration = Config.ChopShop.Parts['door_dside_f'].duration or 8000,
                    anim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer' },
                    prop = { model = 'prop_tool_screwdvr01', bone = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }
                })
            end
        },

        -- C. PUERTA DELANTERA DERECHA (COPILOTO)
        {
            name = 'aura_chop_door_pside_f',
            icon = 'fa-solid fa-door-open',
            label = 'Desmontar Puerta Copiloto',
            bones = { 'door_pside_f' },
            distance = 2.2,
            canInteract = function(entity)
                if isDismantling then return false end
                if not IsInChopShopBay(GetEntityCoords(entity)) then return false end
                if not IsPlayerInGang() then return false end
                if not IsVehicleSeatFree(entity, -1) or GetVehicleNumberOfPassengers(entity) > 0 then return false end
                return not Entity(entity).state.dismantled_door_pside_f
            end,
            onSelect = function(data)
                DismantlePart(data.entity, 'door_pside_f', {
                    doorIndex = 1,
                    progressLabel = 'Desmontando cerradura y paneles de puerta...',
                    duration = Config.ChopShop.Parts['door_pside_f'].duration or 8000,
                    anim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer' },
                    prop = { model = 'prop_tool_screwdvr01', bone = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }
                })
            end
        },

        -- D. PUERTA TRASERA IZQUIERDA
        {
            name = 'aura_chop_door_dside_r',
            icon = 'fa-solid fa-door-open',
            label = 'Desmontar Puerta Trasera Izquierda',
            bones = { 'door_dside_r' },
            distance = 2.2,
            canInteract = function(entity)
                if isDismantling then return false end
                if not IsInChopShopBay(GetEntityCoords(entity)) then return false end
                if not IsPlayerInGang() then return false end
                if not IsVehicleSeatFree(entity, -1) or GetVehicleNumberOfPassengers(entity) > 0 then return false end
                return not Entity(entity).state.dismantled_door_dside_r
            end,
            onSelect = function(data)
                DismantlePart(data.entity, 'door_dside_r', {
                    doorIndex = 2,
                    progressLabel = 'Descolgando puerta y soltando bisagras...',
                    duration = Config.ChopShop.Parts['door_dside_r'].duration or 8000,
                    anim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer' },
                    prop = { model = 'prop_tool_screwdvr01', bone = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }
                })
            end
        },

        -- E. PUERTA TRASERA DERECHA
        {
            name = 'aura_chop_door_pside_r',
            icon = 'fa-solid fa-door-open',
            label = 'Desmontar Puerta Trasera Derecha',
            bones = { 'door_pside_r' },
            distance = 2.2,
            canInteract = function(entity)
                if isDismantling then return false end
                if not IsInChopShopBay(GetEntityCoords(entity)) then return false end
                if not IsPlayerInGang() then return false end
                if not IsVehicleSeatFree(entity, -1) or GetVehicleNumberOfPassengers(entity) > 0 then return false end
                return not Entity(entity).state.dismantled_door_pside_r
            end,
            onSelect = function(data)
                DismantlePart(data.entity, 'door_pside_r', {
                    doorIndex = 3,
                    progressLabel = 'Descolgando puerta y soltando bisagras...',
                    duration = Config.ChopShop.Parts['door_pside_r'].duration or 8000,
                    anim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer' },
                    prop = { model = 'prop_tool_screwdvr01', bone = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }
                })
            end
        },

        -- F. RUEDA DELANTERA IZQUIERDA
        {
            name = 'aura_chop_wheel_lf',
            icon = 'fa-solid fa-compact-disc',
            label = 'Desmontar Rueda Delantera Izquierda',
            bones = { 'wheel_lf' },
            distance = 1.8,
            canInteract = function(entity)
                if isDismantling then return false end
                if not IsInChopShopBay(GetEntityCoords(entity)) then return false end
                if not IsPlayerInGang() then return false end
                if not IsVehicleSeatFree(entity, -1) or GetVehicleNumberOfPassengers(entity) > 0 then return false end
                return not Entity(entity).state.dismantled_wheel_lf
            end,
            onSelect = function(data)
                DismantlePart(data.entity, 'wheel_lf', {
                    wheelIndex = 0,
                    progressLabel = 'Aflojando tuercas y retirando rueda...',
                    duration = Config.ChopShop.Parts['wheel_lf'].duration or 10000,
                    anim = { dict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@', clip = 'weed_crouch_checkingleaves_idle_01_inspector' },
                    prop = { model = 'prop_wrench_01', bone = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }
                })
            end
        },

        -- G. RUEDA DELANTERA DERECHA
        {
            name = 'aura_chop_wheel_rf',
            icon = 'fa-solid fa-compact-disc',
            label = 'Desmontar Rueda Delantera Derecha',
            bones = { 'wheel_rf' },
            distance = 1.8,
            canInteract = function(entity)
                if isDismantling then return false end
                if not IsInChopShopBay(GetEntityCoords(entity)) then return false end
                if not IsPlayerInGang() then return false end
                if not IsVehicleSeatFree(entity, -1) or GetVehicleNumberOfPassengers(entity) > 0 then return false end
                return not Entity(entity).state.dismantled_wheel_rf
            end,
            onSelect = function(data)
                DismantlePart(data.entity, 'wheel_rf', {
                    wheelIndex = 1,
                    progressLabel = 'Aflojando tuercas y retirando rueda...',
                    duration = Config.ChopShop.Parts['wheel_rf'].duration or 10000,
                    anim = { dict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@', clip = 'weed_crouch_checkingleaves_idle_01_inspector' },
                    prop = { model = 'prop_wrench_01', bone = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }
                })
            end
        },

        -- H. RUEDA TRASERA IZQUIERDA
        {
            name = 'aura_chop_wheel_lr',
            icon = 'fa-solid fa-compact-disc',
            label = 'Desmontar Rueda Trasera Izquierda',
            bones = { 'wheel_lr' },
            distance = 1.8,
            canInteract = function(entity)
                if isDismantling then return false end
                if not IsInChopShopBay(GetEntityCoords(entity)) then return false end
                if not IsPlayerInGang() then return false end
                if not IsVehicleSeatFree(entity, -1) or GetVehicleNumberOfPassengers(entity) > 0 then return false end
                return not Entity(entity).state.dismantled_wheel_lr
            end,
            onSelect = function(data)
                DismantlePart(data.entity, 'wheel_lr', {
                    wheelIndex = 4,
                    progressLabel = 'Aflojando tuercas y retirando rueda...',
                    duration = Config.ChopShop.Parts['wheel_lr'].duration or 10000,
                    anim = { dict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@', clip = 'weed_crouch_checkingleaves_idle_01_inspector' },
                    prop = { model = 'prop_wrench_01', bone = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }
                })
            end
        },

        -- I. RUEDA TRASERA DERECHA
        {
            name = 'aura_chop_wheel_rr',
            icon = 'fa-solid fa-compact-disc',
            label = 'Desmontar Rueda Trasera Derecha',
            bones = { 'wheel_rr' },
            distance = 1.8,
            canInteract = function(entity)
                if isDismantling then return false end
                if not IsInChopShopBay(GetEntityCoords(entity)) then return false end
                if not IsPlayerInGang() then return false end
                if not IsVehicleSeatFree(entity, -1) or GetVehicleNumberOfPassengers(entity) > 0 then return false end
                return not Entity(entity).state.dismantled_wheel_rr
            end,
            onSelect = function(data)
                DismantlePart(data.entity, 'wheel_rr', {
                    wheelIndex = 5,
                    progressLabel = 'Aflojando tuercas y retirando rueda...',
                    duration = Config.ChopShop.Parts['wheel_rr'].duration or 10000,
                    anim = { dict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@', clip = 'weed_crouch_checkingleaves_idle_01_inspector' },
                    prop = { model = 'prop_wrench_01', bone = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }
                })
            end
        },

        -- J. MOTOR (REQUIERE CAPÓ RETIRADO O ABIERTO)
        {
            name = 'aura_chop_engine',
            icon = 'fa-solid fa-gears',
            label = 'Extraer Bloque Motor',
            bones = { 'engine' },
            distance = 2.2,
            canInteract = function(entity)
                if isDismantling then return false end
                if not IsInChopShopBay(GetEntityCoords(entity)) then return false end
                if not IsPlayerInGang() then return false end
                if not IsVehicleSeatFree(entity, -1) or GetVehicleNumberOfPassengers(entity) > 0 then return false end

                local entState = Entity(entity).state
                if entState.dismantled_engine then return false end

                -- Prerrequisito: el capó debe haber sido desmontado o estar abierto
                local hoodRemoved = (entState.dismantled_hood == true)
                local hoodOpen = (GetVehicleDoorAngleRatio(entity, 4) > 0.1)
                return hoodRemoved or hoodOpen
            end,
            onSelect = function(data)
                DismantlePart(data.entity, 'engine', {
                    bone = 'engine',
                    isWelding = true,
                    progressLabel = 'Cortando anclajes y descolgando bloque motor...',
                    duration = Config.ChopShop.Parts['engine'].duration or 15000,
                    anim = { dict = 'amb@world_human_welding@male@base', clip = 'base' },
                    prop = { model = 'prop_weld_torch', bone = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }
                })
            end
        },

        -- K. TUBO DE ESCAPE
        {
            name = 'aura_chop_exhaust',
            icon = 'fa-solid fa-wind',
            label = 'Seccionar Línea de Escape',
            bones = { 'exhaust', 'exhaust_2' },
            distance = 2.0,
            canInteract = function(entity)
                if isDismantling then return false end
                if not IsInChopShopBay(GetEntityCoords(entity)) then return false end
                if not IsPlayerInGang() then return false end
                if not IsVehicleSeatFree(entity, -1) or GetVehicleNumberOfPassengers(entity) > 0 then return false end
                return not Entity(entity).state.dismantled_exhaust
            end,
            onSelect = function(data)
                DismantlePart(data.entity, 'exhaust', {
                    bone = 'exhaust',
                    isWelding = true,
                    progressLabel = 'Seccionando tubo de escape y silenciador...',
                    duration = Config.ChopShop.Parts['exhaust'].duration or 15000,
                    anim = { dict = 'amb@world_human_welding@male@base', clip = 'base' },
                    prop = { model = 'prop_weld_torch', bone = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }
                })
            end
        },

        -- L. CHASIS FINAL (DISPONIBLE CUANDO TODAS LAS PIEZAS SE HAN RETIRADO)
        {
            name = 'aura_chop_chassis',
            icon = 'fa-solid fa-recycle',
            label = 'Desguazar y Compactar Chasis',
            distance = 2.8,
            canInteract = function(entity)
                if isDismantling then return false end
                if not IsInChopShopBay(GetEntityCoords(entity)) then return false end
                if not IsPlayerInGang() then return false end
                if not IsVehicleSeatFree(entity, -1) or GetVehicleNumberOfPassengers(entity) > 0 then return false end
                return CanChopChassis(entity)
            end,
            onSelect = function(data)
                ScrapChassis(data.entity)
            end
        }
    })
end)
