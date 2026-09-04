local activeBlips = {}

-- Función para limpiar todos los blips actuales
function ClearBlips()
    for _, blip in pairs(activeBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    activeBlips = {}
end

-- Función para crear los blips recibidos del servidor
function CreateBlips(blipsData)
    ClearBlips()
    
    for _, info in pairs(blipsData) do
        local blip = AddBlipForCoord(info.x, info.y, info.z)
        SetBlipSprite(blip, info.sprite or 1)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, info.scale or 0.8)
        SetBlipColour(blip, info.color or 3)
        SetBlipAsShortRange(blip, true)
        
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(info.name)
        EndTextCommandSetBlipName(blip)
        
        table.insert(activeBlips, blip)
    end
end

-- Recibir los blips del servidor
RegisterNetEvent("mlo_blips:receiveBlips")
AddEventHandler("mlo_blips:receiveBlips", function(blipsData)
    CreateBlips(blipsData)
end)

-- Pedir los blips al servidor al iniciar y registrar sugerencias de chat
CreateThread(function()
    Wait(1000)
    TriggerServerEvent("mlo_blips:requestBlips")

    -- Sugerencias para el chat
    TriggerEvent('chat:addSuggestion', '/marcar', 'Añadir un marcador permanente en el mapa en tu posición actual', {
        { name = 'nombre', help = 'Nombre que aparecerá en el mapa para este MLO/Lugar' }
    })

    TriggerEvent('chat:addSuggestion', '/borrarblip', 'Borrar un marcador del mapa (por cercanía, nombre o ID)', {
        { name = 'nombre o ID', help = '(Opcional) Nombre o número #ID del blip. Si lo dejas vacío, borra el más cercano.' }
    })

    TriggerEvent('chat:addSuggestion', '/delblip', 'Borrar un marcador del mapa (alias de /borrarblip)', {
        { name = 'nombre o ID', help = '(Opcional) Nombre o número #ID del blip.' }
    })

    TriggerEvent('chat:addSuggestion', '/desmarcar', 'Borrar un marcador del mapa (alias de /borrarblip)', {
        { name = 'nombre o ID', help = '(Opcional) Nombre o número #ID del blip.' }
    })

    TriggerEvent('chat:addSuggestion', '/listarblips', 'Listar todos los marcadores guardados en el mapa con su ID y distancia')
    TriggerEvent('chat:addSuggestion', '/blips', 'Listar todos los marcadores guardados en el mapa (alias de /listarblips)')
end)
