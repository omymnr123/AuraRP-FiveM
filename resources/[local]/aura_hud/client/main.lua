local HUD_VISIBLE = false
local wasTalking = false

local function ShowHUD()
    TriggerServerEvent('aura_hud:server:RequestPosition')
    SendNUIMessage({
        action = 'showHUD'
    })
    HUD_VISIBLE = true
end

-- Mostrar el HUD cuando el jugador hace spawn o se inicializa
CreateThread(function()
    Wait(1000)
    ShowHUD()
end)

AddEventHandler('playerSpawned', ShowHUD)
RegisterNetEvent('aura_core:client:playerSpawned', ShowHUD)
RegisterNetEvent('aura_core:playerSpawnedAndReady', ShowHUD)
RegisterNetEvent('aura_multichar:client:characterLoaded', ShowHUD)

-- Obtener dimensiones del minimapa de GTA V (Resolución Responsiva)
function GetMinimapAnchor()
    local safezone = GetSafeZoneSize()
    local safezone_x = 1.0 / 20.0
    local safezone_y = 1.0 / 20.0
    local aspect_ratio = GetAspectRatio(0)
    if aspect_ratio <= 0.0 then aspect_ratio = GetAspectRatio(1) end
    if aspect_ratio <= 0.0 then aspect_ratio = 16.0 / 9.0 end

    local res_x, res_y = GetActiveScreenResolution()
    local xscale = 1.0 / res_x
    local yscale = 1.0 / res_y

    local total_width = xscale * (res_x / (4 * aspect_ratio))
    local total_height = yscale * (res_y / 5.674)
    local left_x = xscale * (res_x * (safezone_x * ((math.abs(safezone - 1.0)) * 10)))
    local bottom_y = 1.0 - yscale * (res_y * (safezone_y * ((math.abs(safezone - 1.0)) * 10)))
    
    -- El radar de GTA V inicia exactamente en top_y y cubre hasta el 93% de la altura total
    local top_y = bottom_y - total_height
    local radar_height = total_height * 0.93

    return {
        x = left_x,
        y = top_y,
        width = total_width,
        height = radar_height
    }
end

-- Bucle para mantener el minimapa siempre visible, borrar la vida/armadura nativa y actualizar el marco
CreateThread(function()
    local minimap = RequestScaleformMovie("minimap")
    SetRadarBigmapEnabled(true, false)
    Wait(0)
    SetRadarBigmapEnabled(false, false)

    local lastUpdate = 0
    while true do
        Wait(0)
        
        -- Forzar que el mapa siempre esté visible (incluso a pie)
        DisplayRadar(true)

        -- Ocultar el punto "N" sobresaliente del borde
        SetBlipAlpha(GetNorthRadarBlip(), 0)

        -- Ocultar vida y armadura nativas de GTA del minimapa
        BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
        ScaleformMovieMethodAddParamInt(3)
        EndScaleformMovieMethod()

        -- Enviar coordenadas del mapa al NUI para posicionar el marco gradiente
        local now = GetGameTimer()
        if HUD_VISIBLE and (now - lastUpdate > 500) then
            lastUpdate = now
            SendNUIMessage({
                action = 'updateMinimapBorder',
                rect = GetMinimapAnchor()
            })
        end
    end
end)

-- Escuchar datos desde aura_status
RegisterNetEvent('aura_hud:updateStatus')
AddEventHandler('aura_hud:updateStatus', function(health, armor, hunger, thirst, stamina)
    if not HUD_VISIBLE then return end
    
    SendNUIMessage({
        action = 'updateStatus',
        health = health,
        armor = armor,
        hunger = hunger,
        thirst = thirst,
        stamina = stamina
    })
end)

-- Loop optimizado nativo para Voice
CreateThread(function()
    while true do
        Wait(200) -- Revisar cada 200ms si el jugador está hablando o cambió su estado
        if HUD_VISIBLE then
            local isTalking = NetworkIsPlayerTalking(PlayerId())
            if isTalking ~= wasTalking then
                wasTalking = isTalking
                SendNUIMessage({
                    action = 'updateVoice',
                    isTalking = isTalking
                })
            end
        end
    end
end)

-- Compatibilidad con pma-voice para mostrar el HUD al cambiar el rango de voz
AddEventHandler('pma-voice:setTalkingMode', function(mode)
    if not HUD_VISIBLE then return end
    
    -- mode suele ser 1 (Whisper), 2 (Normal), 3 (Shouting)
    local ranges = { [1] = 33, [2] = 66, [3] = 100 }
    local percent = ranges[mode] or 100
    
    SendNUIMessage({
        action = 'showVoiceTemporary',
        rangePercent = percent
    })
end)

-- Comando /hud para mover la interfaz
RegisterCommand('hud', function()
    if not HUD_VISIBLE then return end
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'editMode'
    })
end)

-- NUI Callback para guardar las posiciones del HUD y Cinturón de Items
RegisterNUICallback('savePos', function(data, cb)
    SetNuiFocus(false, false)
    
    -- Notificamos al servidor para guardar en la BD/Metadata
    TriggerServerEvent('aura_hud:server:SavePosition', data)
    
    -- Guardar también en KVP local para carga instantánea
    if data and type(data) == 'table' then
        if data.hud then
            SetResourceKvp('aura_hud_pos', json.encode(data.hud))
        end
        if data.hotbar then
            SetResourceKvp('aura_hotbar_pos', json.encode(data.hotbar))
            TriggerEvent('ox_inventory:client:setHotbarPosition', data.hotbar.x, data.hotbar.y)
        end
    end
    
    if lib and lib.notify then
        lib.notify({
            title = 'HUD & Cinturón',
            description = 'Posiciones guardadas correctamente.',
            type = 'success',
            duration = 3500
        })
    end
    
    cb('ok')
end)

-- NUI Callback para cancelar o cerrar el modo edición
RegisterNUICallback('closeEdit', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Evento para recibir las posiciones desde el servidor al loguear
RegisterNetEvent('aura_hud:client:SetPosition')
AddEventHandler('aura_hud:client:SetPosition', function(hudPos, hotbarPos)
    local finalHud = hudPos
    local finalHotbar = hotbarPos
    
    -- Compatibilidad con formato antiguo numérico
    if type(hudPos) == 'number' then
        finalHud = { x = hudPos, y = hotbarPos }
        finalHotbar = { x = 50.0, y = 3.5 }
    end
    
    -- Enviar a la UI de aura_hud
    SendNUIMessage({
        action = 'setPosition',
        hud = finalHud,
        hotbar = finalHotbar
    })
    
    -- Sincronizar el cinturón de ox_inventory
    if finalHotbar and finalHotbar.x and finalHotbar.y then
        TriggerEvent('ox_inventory:client:setHotbarPosition', finalHotbar.x, finalHotbar.y)
    end
end)

-- Restaurar posiciones locales al iniciar el recurso
CreateThread(function()
    Wait(500)
    local savedHud = GetResourceKvpString('aura_hud_pos')
    local savedHotbar = GetResourceKvpString('aura_hotbar_pos')
    
    local hudPos = savedHud and json.decode(savedHud) or nil
    local hotbarPos = savedHotbar and json.decode(savedHotbar) or nil
    
    if hudPos or hotbarPos then
        SendNUIMessage({
            action = 'setPosition',
            hud = hudPos or { x = 17.5, y = 3.5 },
            hotbar = hotbarPos or { x = 50.0, y = 3.5 }
        })
        if hotbarPos then
            TriggerEvent('ox_inventory:client:setHotbarPosition', hotbarPos.x, hotbarPos.y)
        end
    end
end)
