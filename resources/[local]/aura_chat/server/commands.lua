--[[
    ===================================================================
    AuraRP Chat - Server Commands & Message Routing
    Enrutamiento aislado para OOC global, /do local (2D) y /me local (2D + 3D).
    Envía la ID del jugador como etiqueta independiente (badge) al lado del comando.
    ===================================================================
]]

function GetPlayerRoleplayName(src)
    local rpName = nil

    if GetResourceState('aura_multichar') == 'started' then
        pcall(function()
            local char = exports['aura_multichar']:GetActiveCharacter(src)
            if char then
                if char.firstname and char.lastname then
                    rpName = string.format("%s %s", char.firstname, char.lastname)
                elseif char.name then
                    rpName = char.name
                elseif char.metadata and char.metadata.charinfo then
                    local ci = char.metadata.charinfo
                    if ci.firstname and ci.lastname then
                        rpName = string.format("%s %s", ci.firstname, ci.lastname)
                    end
                end
            end
        end)
    end

    if not rpName and GetResourceState('aura_core') == 'started' then
        pcall(function()
            if AuraCore and AuraCore.Players and AuraCore.Players[src] then
                local p = AuraCore.Players[src]
                if p.name then rpName = p.name end
            end
        end)
    end

    return rpName or GetPlayerName(src) or ('Jugador [' .. tostring(src) .. ']')
end

function GetPlayersInProximity(src, maxDistance)
    local srcPed = GetPlayerPed(src)
    if not srcPed or srcPed == 0 then return { src } end
    
    local srcCoords = GetEntityCoords(srcPed)
    local inRange = {}

    for _, playerId in ipairs(GetPlayers()) do
        local targetPed = GetPlayerPed(playerId)
        if targetPed and targetPed ~= 0 then
            local targetCoords = GetEntityCoords(targetPed)
            if #(srcCoords - targetCoords) <= maxDistance then
                table.insert(inRange, tonumber(playerId))
            end
        end
    end

    return inRange
end

-- ===================================================================
-- PROCESAMIENTO DE COMANDOS DE ROL
-- ===================================================================

-- 1. OOC (Global)
function ProcessOOC(src, message)
    if not message or string.len(message) == 0 then return end

    local playerName = GetPlayerName(src) or ('ID: ' .. tostring(src))
    local timeStr = os.date('%H:%M')

    local payload = {
        type = 'ooc',
        badge = 'OOC',
        badgeColor = Config.Colors.oocAuthor,
        playerId = src,
        author = playerName,
        authorColor = Config.Colors.oocAuthor,
        content = message,
        contentColor = Config.Colors.ooc,
        time = timeStr
    }

    TriggerClientEvent('aura_chat:client:addMessage', -1, payload)
end

-- 2. /me (Local 15m -> 2D UI + 3D Text Engine)
-- 2D UI: Badge [ME] + Badge [ID: X] + * Nombre Acción *
-- 3D Text: Texto limpio sin ** y sin ID
function ProcessMe(src, message)
    if not message or string.len(message) == 0 then return end

    local rpName = GetPlayerRoleplayName(src)
    local inRange = GetPlayersInProximity(src, Config.Proximity.me)
    local timeStr = os.date('%H:%M')

    local formattedContent = string.format("* %s %s *", rpName, message)

    local payload2D = {
        type = 'me',
        badge = 'ME',
        badgeColor = Config.Colors.turquoise,
        playerId = src,
        author = rpName,
        authorColor = Config.Colors.turquoise,
        content = formattedContent,
        contentColor = Config.Colors.turquoise,
        time = timeStr
    }

    -- Texto 3D limpio: Sin símbolos ** ni ID
    local text3D = tostring(message)

    for _, targetSrc in ipairs(inRange) do
        -- 2D UI
        TriggerClientEvent('aura_chat:client:addMessage', targetSrc, payload2D)
        -- 3D Text Engine
        TriggerClientEvent('aura_chat:client:show3DMe', targetSrc, src, text3D)
    end
end

-- 3. /do (Local 15m -> 2D UI Únicamente)
-- 2D UI: Badge [DO] + Badge [ID: X] + * Descripción del entorno * (SIN nombre de personaje)
function ProcessDo(src, message)
    if not message or string.len(message) == 0 then return end

    local inRange = GetPlayersInProximity(src, Config.Proximity.doCmd)
    local timeStr = os.date('%H:%M')

    local formattedContent = string.format("* %s *", message)

    local payload2D = {
        type = 'do',
        badge = 'DO',
        badgeColor = Config.Colors.neonPink,
        playerId = src,
        author = '',
        authorColor = Config.Colors.neonPink,
        content = formattedContent,
        contentColor = Config.Colors.neonPink,
        time = timeStr
    }

    for _, targetSrc in ipairs(inRange) do
        -- 2D UI Únicamente
        TriggerClientEvent('aura_chat:client:addMessage', targetSrc, payload2D)
    end
end

-- ===================================================================
-- REGISTRO DE COMANDOS DE ROL
-- ===================================================================

RegisterCommand('me', function(source, args, rawCommand)
    if source <= 0 then return end
    local message = table.concat(args, " ")
    ProcessMe(source, message)
end, false)

RegisterCommand('do', function(source, args, rawCommand)
    if source <= 0 then return end
    local message = table.concat(args, " ")
    ProcessDo(source, message)
end, false)

RegisterCommand('ooc', function(source, args, rawCommand)
    if source <= 0 then return end
    local message = table.concat(args, " ")
    ProcessOOC(source, message)
end, false)
