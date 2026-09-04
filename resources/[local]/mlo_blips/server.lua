local blipsData = {}

-- Función auxiliar para enviar mensajes formateados al jugador o consola
local function Notify(src, msgType, message)
    if src == 0 then
        local cleanMsg = message:gsub("%^[0-9]", "")
        print(("[MLO-BLIPS] [%s] %s"):format(string.upper(msgType), cleanMsg))
        return
    end

    local prefix = '^2[Éxito]^0 '
    if msgType == 'error' then
        prefix = '^1[Error]^0 '
    elseif msgType == 'info' then
        prefix = '^3[Info]^0 '
    end

    TriggerClientEvent('chat:addMessage', src, {
        args = { '^4[MLO-BLIPS]^0', prefix .. message }
    })

    -- Compatibilidad con ox_lib si el cliente lo tiene cargado
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Marcadores MLO',
        description = message:gsub("%^[0-9]", ""),
        type = msgType
    })
end

-- Cargar blips desde el archivo JSON al iniciar el recurso
function LoadBlips()
    local loadFile = LoadResourceFile(GetCurrentResourceName(), "blips.json")
    if loadFile then
        local decoded = json.decode(loadFile)
        if decoded and type(decoded) == "table" then
            blipsData = decoded
        else
            blipsData = {}
        end
    else
        blipsData = {}
        SaveResourceFile(GetCurrentResourceName(), "blips.json", "[]", -1)
    end
end

-- Guardar blips en el archivo JSON
function SaveBlips()
    SaveResourceFile(GetCurrentResourceName(), "blips.json", json.encode(blipsData, { indent = true }), -1)
end

LoadBlips()

-- Enviar los blips al jugador cuando entra al servidor o el recurso se inicia
RegisterNetEvent("mlo_blips:requestBlips")
AddEventHandler("mlo_blips:requestBlips", function()
    local _source = source
    TriggerClientEvent("mlo_blips:receiveBlips", _source, blipsData)
end)

-- ==========================================
-- COMANDO: /marcar [Nombre]
-- ==========================================
RegisterCommand("marcar", function(source, args, rawCommand)
    if source == 0 then
        print("[MLO-BLIPS] Este comando solo puede ser ejecutado por un jugador dentro del juego.")
        return
    end
    
    local name = table.concat(args, " ")
    if name == "" then
        Notify(source, 'error', 'Debes indicar un nombre. Uso: ^3/marcar [Nombre del MLO]^0')
        return
    end

    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)

    local newBlip = {
        name = name,
        x = coords.x,
        y = coords.y,
        z = coords.z,
        sprite = 1, -- Blip genérico por defecto
        color = 3,  -- Azul por defecto
        scale = 0.8
    }

    table.insert(blipsData, newBlip)
    SaveBlips()

    -- Sincronizar inmediatamente con todos los jugadores conectados
    TriggerClientEvent("mlo_blips:receiveBlips", -1, blipsData)
    
    Notify(source, 'success', ('Has añadido el marcador ^3"%s"^0 permanentemente al mapa (#%d).'):format(name, #blipsData))
end, true) -- Requiere permisos de admin (add_ace group.admin command allow)

-- ==========================================
-- LÓGICA PRINCIPAL: Borrar Blip
-- ==========================================
local function DeleteBlipHandler(source, args)
    if #blipsData == 0 then
        Notify(source, 'error', 'No hay ningún marcador registrado en el mapa.')
        return
    end

    -- CASO 1: Si no se pasa ningún argumento, borrar por cercanía (máx 50m)
    if #args == 0 or table.concat(args, " ") == "" then
        if source == 0 then
            print("[MLO-BLIPS] En la consola debes especificar el ID o Nombre. Uso: borrarblip [ID o Nombre]")
            return
        end

        local ped = GetPlayerPed(source)
        local pCoords = GetEntityCoords(ped)

        local closestIndex = nil
        local minDistance = 50.0 -- Distancia máxima en metros

        for i, blip in ipairs(blipsData) do
            local bCoords = vector3(blip.x, blip.y, blip.z)
            local dist = #(pCoords - bCoords)
            if dist < minDistance then
                minDistance = dist
                closestIndex = i
            end
        end

        if closestIndex then
            local removedBlip = table.remove(blipsData, closestIndex)
            SaveBlips()
            TriggerClientEvent("mlo_blips:receiveBlips", -1, blipsData)
            Notify(source, 'success', ('Has borrado el marcador ^3"%s"^0 más cercano (a %.1fm de ti).'):format(removedBlip.name, minDistance))
        else
            Notify(source, 'error', 'No hay ningún marcador cerca (< 50m). Uso: ^3/borrarblip [Nombre o ID]^0 o acércate más al blip. Usa ^3/listarblips^0.')
        end
        return
    end

    -- CASO 2: Borrar por ID numérico (ej: /borrarblip 2 o /borrarblip #2)
    local firstArg = args[1]:gsub("^#", "")
    local targetId = tonumber(firstArg)

    if #args == 1 and targetId then
        if targetId >= 1 and targetId <= #blipsData then
            local removedBlip = table.remove(blipsData, targetId)
            SaveBlips()
            TriggerClientEvent("mlo_blips:receiveBlips", -1, blipsData)
            Notify(source, 'success', ('Has eliminado el marcador #%d: ^3"%s"^0.'):format(targetId, removedBlip.name))
        else
            Notify(source, 'error', ('No existe ningún marcador con el ID #%d (total disponibles: %d). Usa ^3/listarblips^0.'):format(targetId, #blipsData))
        end
        return
    end

    -- CASO 3: Borrar por Nombre (Búsqueda exacta o parcial)
    local query = string.lower(table.concat(args, " "))

    -- 3A: Coincidencia exacta
    local exactIndex = nil
    for i, blip in ipairs(blipsData) do
        if string.lower(blip.name) == query then
            exactIndex = i
            break
        end
    end

    if exactIndex then
        local removedBlip = table.remove(blipsData, exactIndex)
        SaveBlips()
        TriggerClientEvent("mlo_blips:receiveBlips", -1, blipsData)
        Notify(source, 'success', ('Has eliminado el marcador ^3"%s"^0 (#%d).'):format(removedBlip.name, exactIndex))
        return
    end

    -- 3B: Coincidencia parcial
    local partialMatches = {}
    for i, blip in ipairs(blipsData) do
        if string.find(string.lower(blip.name), query, 1, true) then
            table.insert(partialMatches, { index = i, blip = blip })
        end
    end

    if #partialMatches == 1 then
        local idx = partialMatches[1].index
        local removedBlip = table.remove(blipsData, idx)
        SaveBlips()
        TriggerClientEvent("mlo_blips:receiveBlips", -1, blipsData)
        Notify(source, 'success', ('Has eliminado el marcador ^3"%s"^0 (#%d).'):format(removedBlip.name, idx))
    elseif #partialMatches > 1 then
        Notify(source, 'info', ('Se encontraron %d marcadores que coinciden con "^1%s^0":'):format(#partialMatches, query))
        for _, match in ipairs(partialMatches) do
            if source == 0 then
                print(("- [#%d] %s"):format(match.index, match.blip.name))
            else
                TriggerClientEvent('chat:addMessage', source, {
                    args = { '^4[MLO-BLIPS]^0', ('- [#%d] ^3%s^0'):format(match.index, match.blip.name) }
                })
            end
        end
        Notify(source, 'info', 'Usa ^3/borrarblip [ID]^0 para especificar cuál quieres eliminar.')
    else
        Notify(source, 'error', ('No se encontró ningún marcador con el nombre "^3%s^0". Usa ^3/listarblips^0.'):format(query))
    end
end

-- ==========================================
-- REGISTRO DE COMANDOS DE BORRADO (Y ALIASES)
-- ==========================================
RegisterCommand("borrarblip", DeleteBlipHandler, true)
RegisterCommand("delblip", DeleteBlipHandler, true)
RegisterCommand("desmarcar", DeleteBlipHandler, true)
RegisterCommand("eliminarblip", DeleteBlipHandler, true)

-- ==========================================
-- COMANDO: /listarblips (y /blips)
-- ==========================================
local function ListBlipsHandler(source, args)
    if #blipsData == 0 then
        Notify(source, 'info', 'No hay marcadores registrados en el mapa.')
        return
    end

    local pCoords = nil
    if source > 0 then
        pCoords = GetEntityCoords(GetPlayerPed(source))
    end

    if source == 0 then
        print(("=== MARCADORES MLO REGISTRADOS (%d) ==="):format(#blipsData))
        for i, blip in ipairs(blipsData) do
            print(("[#%d] %s (x: %.1f, y: %.1f, z: %.1f)"):format(i, blip.name, blip.x, blip.y, blip.z))
        end
    else
        TriggerClientEvent('chat:addMessage', source, {
            args = { '^4[MLO-BLIPS]^0', ('^3=== MARCADORES MLO REGISTRADOS (%d) ===^0'):format(#blipsData) }
        })
        for i, blip in ipairs(blipsData) do
            local distText = ""
            if pCoords then
                local dist = math.floor(#(pCoords - vector3(blip.x, blip.y, blip.z)))
                distText = (' ^7(a ^2%dm^7)^0'):format(dist)
            end
            TriggerClientEvent('chat:addMessage', source, {
                args = { '^4[MLO-BLIPS]^0', ('[#%d] ^3%s^0%s'):format(i, blip.name, distText) }
            })
        end
        TriggerClientEvent('chat:addMessage', source, {
            args = { '^4[MLO-BLIPS]^0', '^7Tip: Usa ^3/borrarblip [ID o Nombre]^7 o ponte cerca y usa ^3/borrarblip^0' }
        })
    end
end

RegisterCommand("listarblips", ListBlipsHandler, true)
RegisterCommand("blips", ListBlipsHandler, true)
RegisterCommand("mloblips", ListBlipsHandler, true)
