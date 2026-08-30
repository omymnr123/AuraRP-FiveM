local blipsData = {}

-- Cargar blips desde el archivo JSON al iniciar el recurso
function LoadBlips()
    local loadFile = LoadResourceFile(GetCurrentResourceName(), "blips.json")
    if loadFile then
        local decoded = json.decode(loadFile)
        if decoded then
            blipsData = decoded
        end
    else
        SaveResourceFile(GetCurrentResourceName(), "blips.json", "[]", -1)
    end
end

-- Guardar blips en el archivo JSON
function SaveBlips()
    SaveResourceFile(GetCurrentResourceName(), "blips.json", json.encode(blipsData, {indent = true}), -1)
end

LoadBlips()

-- Enviar los blips al jugador cuando entra al servidor o el recurso se inicia
RegisterNetEvent("mlo_blips:requestBlips")
AddEventHandler("mlo_blips:requestBlips", function()
    local _source = source
    TriggerClientEvent("mlo_blips:receiveBlips", _source, blipsData)
end)

-- Comando para que los administradores guarden una nueva ubicacion de MLO en el mapa
RegisterCommand("marcar", function(source, args, rawCommand)
    if source == 0 then return end -- No ejecutar desde la consola
    
    local name = table.concat(args, " ")
    if name == "" then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1Error', 'Debes poner un nombre. Uso: /marcar [Nombre del MLO]' } })
        return
    end

    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)

    local newBlip = {
        name = name,
        x = coords.x,
        y = coords.y,
        z = coords.z,
        sprite = 1, -- Blip generico
        color = 3, -- Azul por defecto
        scale = 0.8
    }

    table.insert(blipsData, newBlip)
    SaveBlips()

    -- Actualizar a todos los jugadores
    TriggerClientEvent("mlo_blips:receiveBlips", -1, blipsData)
    
    TriggerClientEvent('chat:addMessage', source, { args = { '^2Éxito', 'Has añadido el marcador "' .. name .. '" permanentemente al mapa.' } })
end, true) -- true significa que requiere permisos de admin (add_ace group.admin command.marcar allow)
