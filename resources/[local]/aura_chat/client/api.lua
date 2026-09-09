--[[
    ===================================================================
    AuraRP Chat - Client API & Event Bridge
    Permite a scripts externos (ej: aura_police, rpemotes, ox_lib)
    inyectar mensajes, notificaciones y sugerencias sin alterar el núcleo.
    ===================================================================
]]

local function FormatMessagePayload(data)
    if type(data) == 'string' then
        return {
            type = 'ooc',
            badge = 'OOC',
            badgeColor = Config.Colors.oocAuthor,
            author = 'Sistema',
            authorColor = Config.Colors.system,
            content = data,
            contentColor = Config.Colors.ooc,
            time = GetCurrentTimeString()
        }
    end

    -- Soporte para formato nativo antiguo FiveM (args = { author, message })
    if data.args and type(data.args) == 'table' then
        local author = data.args[1] or 'Sistema'
        local content = data.args[2] or ''
        
        -- Si sólo hay un argumento, es un mensaje directo
        if #data.args == 1 then
            content = data.args[1]
            author = 'Notificación'
        end

        local badge = 'INFO'
        local badgeColor = Config.Colors.system
        
        -- Detección de prefijos estándar en texto antiguo
        if string.find(author, 'OOC') then
            badge = 'OOC'
            badgeColor = Config.Colors.oocAuthor
        elseif string.find(author, 'ME') or string.find(author, 'me') then
            badge = 'ME'
            badgeColor = Config.Colors.turquoise
        elseif string.find(author, 'DO') or string.find(author, 'do') then
            badge = 'DO'
            badgeColor = Config.Colors.neonPink
        end

        return {
            type = data.type or 'system',
            badge = data.badge or badge,
            badgeColor = data.badgeColor or badgeColor,
            author = author,
            authorColor = data.authorColor or Config.Colors.turquoise,
            content = content,
            contentColor = data.contentColor or Config.Colors.ooc,
            time = GetCurrentTimeString()
        }
    end

    -- Formato estándar AuraRP
    return {
        type = data.type or 'system',
        badge = data.badge or 'INFO',
        badgeColor = data.badgeColor or Config.Colors.system,
        playerId = data.playerId or data.src or data.source or nil,
        author = data.author or '',
        authorColor = data.authorColor or Config.Colors.turquoise,
        content = data.content or data.message or '',
        contentColor = data.contentColor or Config.Colors.ooc,
        time = data.time or GetCurrentTimeString(),
        customClass = data.customClass or nil
    }
end

function GetCurrentTimeString()
    -- Obtenemos la hora del juego o local
    local hour = GetClockHours()
    local minute = GetClockMinutes()
    return string.format("%02d:%02d", hour, minute)
end

-- Función interna de despacho al NUI
local function DispatchMessageToNui(payload)
    local formatted = FormatMessagePayload(payload)
    SendNUIMessage({
        action = 'addMessage',
        message = formatted
    })
end

-- ===================================================================
-- EVENTOS DE RED CLIENTE
-- ===================================================================

-- Evento principal AuraRP
RegisterNetEvent('aura_chat:client:addMessage', function(data)
    DispatchMessageToNui(data)
end)

-- Evento de compatibilidad con estándar FiveM (`chat:addMessage`)
RegisterNetEvent('chat:addMessage', function(data)
    DispatchMessageToNui(data)
end)

-- Manejo de sugerencias de autocompletado
RegisterNetEvent('chat:addSuggestion', function(name, help, params)
    SendNUIMessage({
        action = 'addSuggestion',
        suggestion = {
            name = name,
            help = help or '',
            params = params or {}
        }
    })
end)

RegisterNetEvent('chat:addSuggestions', function(suggestions)
    SendNUIMessage({
        action = 'addSuggestions',
        suggestions = suggestions
    })
end)

RegisterNetEvent('chat:removeSuggestion', function(name)
    SendNUIMessage({
        action = 'removeSuggestion',
        name = name
    })
end)

-- Limpieza de chat
RegisterNetEvent('chat:clear', function()
    SendNUIMessage({
        action = 'clearChat'
    })
end)

RegisterNetEvent('aura_chat:client:clear', function()
    SendNUIMessage({
        action = 'clearChat'
    })
end)

-- ===================================================================
-- EXPORTS DEL CLIENTE
-- ===================================================================

exports('addMessage', function(data)
    DispatchMessageToNui(data)
end)

exports('addSuggestion', function(name, help, params)
    SendNUIMessage({
        action = 'addSuggestion',
        suggestion = {
            name = name,
            help = help or '',
            params = params or {}
        }
    })
end)

exports('removeSuggestion', function(name)
    SendNUIMessage({
        action = 'removeSuggestion',
        name = name
    })
end)

exports('clearChat', function()
    SendNUIMessage({
        action = 'clearChat'
    })
end)
