--[[
    ===================================================================
    AuraRP Chat - Server Main Controller
    Recepción de mensajes desde el NUI, despacho de comandos y compatibilidad.
    ===================================================================
]]

RegisterNetEvent('aura_chat:server:processMessage', function(rawMessage)
    local src = source
    if not src or src <= 0 then return end
    if not rawMessage or type(rawMessage) ~= 'string' then return end

    -- Limpieza de espacios en blanco
    local message = string.gsub(rawMessage, "^%s*(.-)%s*$", "%1")
    if string.len(message) == 0 then return end

    -- Detección de comandos
    if string.sub(message, 1, 1) == '/' then
        local commandText = string.sub(message, 2)
        local spaceIndex = string.find(commandText, " ")
        local commandName = ""
        local argsText = ""

        if spaceIndex then
            commandName = string.lower(string.sub(commandText, 1, spaceIndex - 1))
            argsText = string.sub(commandText, spaceIndex + 1)
        else
            commandName = string.lower(commandText)
        end

        if commandName == 'me' then
            ProcessMe(src, argsText)
        elseif commandName == 'do' then
            ProcessDo(src, argsText)
        elseif commandName == 'ooc' then
            ProcessOOC(src, argsText)
        else
            -- Ejecución delegada de otros comandos externos (/entorno, /auxilio, etc.)
            TriggerClientEvent('aura_chat:client:executeCommand', src, commandText)
        end
    else
        -- Mensaje por defecto sin barra: Canal OOC Global
        ProcessOOC(src, message)
    end
end)

-- Compatibilidad con el evento legacy interno de FiveM
RegisterNetEvent('_chat:messageEntered', function(author, color, message)
    local src = source
    if not src or src <= 0 then return end
    if not message or message == '' then return end

    if string.sub(message, 1, 1) == '/' then
        local commandText = string.sub(message, 2)
        TriggerClientEvent('aura_chat:client:executeCommand', src, commandText)
    else
        ProcessOOC(src, message)
    end
end)
