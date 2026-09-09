--[[
    ===================================================================
    AuraRP Chat - Client Controller
    Gestiona el ciclo de vida de la UI, la captura de foco NUI y
    la anulación total del chat nativo de FiveM.
    ===================================================================
]]

local isChatOpen = false

-- Inicialización y anulación permanente del chat nativo
local function InitChat()
    -- Desactivar el subsistema de chat nativo de FiveM
    SetTextChatEnabled(false)

    -- Cargar sugerencias predeterminadas en el NUI
    if Config.DefaultSuggestions and #Config.DefaultSuggestions > 0 then
        SendNUIMessage({
            action = 'addSuggestions',
            suggestions = Config.DefaultSuggestions
        })
    end
end

AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    InitChat()
end)

AddEventHandler('playerSpawned', function()
    SetTextChatEnabled(false)
end)

-- ===================================================================
-- REGISTRO DE CONTROLES Y COMANDOS
-- ===================================================================

-- Apertura mediante tecla estándar (T)
RegisterCommand('open_aura_chat', function()
    if isChatOpen or IsPauseMenuActive() then return end
    
    isChatOpen = true
    SetNuiFocus(true, false)
    SendNUIMessage({
        action = 'openChat',
        prefix = ''
    })
end, false)

-- Apertura directa con barra de comandos (/)
RegisterCommand('open_aura_chat_cmd', function()
    if isChatOpen or IsPauseMenuActive() then return end
    
    isChatOpen = true
    SetNuiFocus(true, false)
    SendNUIMessage({
        action = 'openChat',
        prefix = '/'
    })
end, false)

RegisterKeyMapping('open_aura_chat', 'Abrir Chat AuraRP', 'keyboard', 'T')
RegisterKeyMapping('open_aura_chat_cmd', 'Abrir Chat con Comando', 'keyboard', 'SLASH')

-- ===================================================================
-- MODO DE VISIBILIDAD DEL CHAT (TECLA L)
-- Opciones: 'activity' (solo actividad), 'always' (siempre visible), 'hidden' (oculto)
-- ===================================================================

local chatModes = { 'activity', 'always', 'hidden' }
local currentModeIndex = 1

local modeLabels = {
    activity = 'Solo con Actividad (Auto-ocultar)',
    always = 'Siempre Visible',
    hidden = 'Completamente Oculto'
}

local function SetChatVisibilityMode(newMode, notify)
    SetResourceKvp('aura_chat_visibility_mode', newMode)
    
    SendNUIMessage({
        action = 'setChatMode',
        mode = newMode
    })

    if notify then
        if lib and lib.notify then
            lib.notify({
                title = 'Chat AuraRP',
                description = 'Modo: ' .. (modeLabels[newMode] or newMode),
                type = 'inform',
                position = 'top-right'
            })
        end
    end
end

RegisterCommand('toggle_aura_chat_mode', function()
    currentModeIndex = (currentModeIndex % #chatModes) + 1
    local newMode = chatModes[currentModeIndex]
    SetChatVisibilityMode(newMode, true)
end, false)

RegisterKeyMapping('toggle_aura_chat_mode', 'Alternar Visibilidad de Chat (Siempre / Actividad / Oculto)', 'keyboard', 'L')

-- Restaurar modo guardado al iniciar
CreateThread(function()
    Wait(500)
    local savedMode = GetResourceKvpString('aura_chat_visibility_mode')
    if savedMode then
        for i, mode in ipairs(chatModes) do
            if mode == savedMode then
                currentModeIndex = i
                SetChatVisibilityMode(savedMode, false)
                break
            end
        end
    end
end)

-- Comando local para limpiar la pantalla de chat
RegisterCommand('clear', function()
    SendNUIMessage({
        action = 'clearChat'
    })
end, false)

-- ===================================================================
-- NUI CALLBACKS (Comunicación Web -> Lua)
-- ===================================================================

RegisterNUICallback('closeChat', function(data, cb)
    isChatOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('sendMessage', function(data, cb)
    isChatOpen = false
    SetNuiFocus(false, false)

    local message = data.message
    if message and type(message) == 'string' and string.len(string.gsub(message, "^%s*(.-)%s*$", "%1")) > 0 then
        TriggerServerEvent('aura_chat:server:processMessage', message)
    end

    cb('ok')
end)

-- Delegación y ejecución de comandos en el cliente
RegisterNetEvent('aura_chat:client:executeCommand', function(commandString)
    if commandString and type(commandString) == 'string' and string.len(commandString) > 0 then
        ExecuteCommand(commandString)
    end
end)

