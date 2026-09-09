local HUD_VISIBLE = false
local wasTalking = false

local function ShowHUD()
    TriggerServerEvent('aura_hud:server:RequestPosition')
    SendNUIMessage({
        action = 'showHUD'
    })
    HUD_VISIBLE = true
    DisplayRadar(true)
end

local function HideHUD()
    SendNUIMessage({
        action = 'hideHUD'
    })
    HUD_VISIBLE = false
    DisplayRadar(false)
end

RegisterNetEvent('aura_hud:toggle', function(show)
    if show then
        ShowHUD()
    else
        HideHUD()
    end
end)

RegisterNetEvent('aura_hud:client:toggle', function(show)
    if show then
        ShowHUD()
    else
        HideHUD()
    end
end)

-- Mostrar el HUD cuando el jugador hace spawn o se inicializa
CreateThread(function()
    Wait(1000)
    ShowHUD()
end)

AddEventHandler('playerSpawned', ShowHUD)
RegisterNetEvent('aura_core:client:playerSpawned', ShowHUD)
RegisterNetEvent('aura_core:playerSpawnedAndReady', ShowHUD)
RegisterNetEvent('aura_multichar:client:characterLoaded', ShowHUD)

-- Bucle para mantener el minimapa siempre visible y borrar la vida/armadura nativa
CreateThread(function()
    local minimap = RequestScaleformMovie("minimap")
    SetRadarBigmapEnabled(true, false)
    Wait(0)
    SetRadarBigmapEnabled(false, false)

    while true do
        Wait(0)
        
        -- Forzar visibilidad del mapa según el estado del HUD
        DisplayRadar(HUD_VISIBLE)

        -- Ocultar el punto "N" sobresaliente del borde
        SetBlipAlpha(GetNorthRadarBlip(), 0)

        -- Ocultar vida y armadura nativas de GTA del minimapa
        BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
        ScaleformMovieMethodAddParamInt(3)
        EndScaleformMovieMethod()
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

-- Escuchar datos térmicos desde aura_seasons
RegisterNetEvent('aura_hud:client:updateTemperature')
AddEventHandler('aura_hud:client:updateTemperature', function(coldLevel, heatLevel, coreTemp, ambientTemp)
    if not HUD_VISIBLE then return end

    SendNUIMessage({
        action = 'updateTemperature',
        coldLevel = coldLevel,
        heatLevel = heatLevel,
        coreTemp = coreTemp,
        ambientTemp = ambientTemp
    })
end)

local wasTalking = false
local wasRadio = false
local isRadioActive = false

local function SendVoiceUpdate()
    if not HUD_VISIBLE then return end
    local pState = LocalPlayer.state
    local isRadio = isRadioActive or (pState and (pState.radioActive == true or pState.mandoRadioActive == true)) or false
    local isTalking = NetworkIsPlayerTalking(PlayerId()) or isRadio

    if isTalking ~= wasTalking or isRadio ~= wasRadio then
        wasTalking = isTalking
        wasRadio = isRadio
        SendNUIMessage({
            action = 'updateVoice',
            isTalking = isTalking,
            isRadio = isRadio
        })
    end
end

-- Escuchar eventos de pma-voice para radio
AddEventHandler('pma-voice:radioActive', function(radioTalking)
    isRadioActive = (radioTalking == true)
    SendVoiceUpdate()
end)

-- Escuchar cambios de estado para Malla General o radio policial / bandas
RegisterNetEvent('aura_police:client:radioStateChanged', function(radioTalking)
    isRadioActive = (radioTalking == true)
    SendVoiceUpdate()
end)

RegisterNetEvent('aura_gangs:client:radioStateChanged', function(radioTalking)
    isRadioActive = (radioTalking == true)
    SendVoiceUpdate()
end)

-- Loop optimizado nativo para Voice
CreateThread(function()
    while true do
        Wait(150) -- Revisar cada 150ms si el jugador está hablando o cambió su estado
        if HUD_VISIBLE then
            SendVoiceUpdate()
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
