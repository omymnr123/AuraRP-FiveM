local isMenuOpen = false

local function ToggleMenu(forceState)
    if forceState ~= nil then
        isMenuOpen = forceState
    else
        isMenuOpen = not isMenuOpen
    end

    if isMenuOpen then
        local ped = PlayerPedId()
        if IsEntityDead(ped) then
            isMenuOpen = false
            return
        end

        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "open",
            config = {
                closeOnSelect = Config.CloseOnSelect,
                showToasts = Config.ShowToasts,
                locale = Config.Locale
            }
        })
    else
        SetNuiFocus(false, false)
        SendNUIMessage({
            action = "close"
        })
    end
end

-- Keymapping para abrir el menú (por defecto F3)
RegisterKeyMapping('aura_animations', 'Abrir Menú de Animaciones AuraRP', 'keyboard', Config.OpenKey or 'F3')
RegisterCommand('aura_animations', function()
    ToggleMenu()
end, false)

if Config.Command and Config.Command ~= '' then
    RegisterCommand(Config.Command, function()
        ToggleMenu()
    end, false)
end

if Config.CommandAlias and Config.CommandAlias ~= '' then
    RegisterCommand(Config.CommandAlias, function()
        ToggleMenu()
    end, false)
end

-- ============================================================================
-- NUI CALLBACKS (PUENTE HACIA RPEMOTES BACKEND)
-- ============================================================================

-- Ejecutar animación / baile / postura / objeto / caminata / expresión
RegisterNUICallback('playAnim', function(data, cb)
    if not data or not data.name then
        cb({ status = 'error', message = 'Missing animation data' })
        return
    end

    local animType = data.type or 'emote'
    local animName = tostring(data.name)

    if animType == 'walk' then
        ExecuteCommand('walk ' .. animName)
    elseif animType == 'expression' then
        ExecuteCommand('mood ' .. animName)
    elseif animType == 'shared' then
        ExecuteCommand('nearby ' .. animName)
    else
        -- 'emote', 'dance', 'prop', etc.
        ExecuteCommand('e ' .. animName)
    end

    if Config.CloseOnSelect then
        ToggleMenu(false)
    end

    cb({ status = 'ok' })
end)

-- Cancelar animación actual (/e c)
RegisterNUICallback('cancelAnim', function(data, cb)
    ExecuteCommand('e c')
    cb({ status = 'ok' })
end)

-- Reiniciar estilo de caminata (/walk reset)
RegisterNUICallback('resetWalk', function(data, cb)
    ExecuteCommand('walk reset')
    cb({ status = 'ok' })
end)

-- Reiniciar expresión facial (/mood reset)
RegisterNUICallback('resetExpression', function(data, cb)
    ExecuteCommand('mood reset')
    cb({ status = 'ok' })
end)

-- Cerrar NUI desde la interfaz (ESC o botón X)
RegisterNUICallback('close', function(data, cb)
    isMenuOpen = false
    SetNuiFocus(false, false)
    cb({ status = 'ok' })
end)

-- Limpieza al reiniciar el recurso
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if isMenuOpen then
            SetNuiFocus(false, false)
        end
    end
end)
