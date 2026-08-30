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

-- Pedir los blips al servidor al iniciar
CreateThread(function()
    Wait(1000)
    TriggerServerEvent("mlo_blips:requestBlips")
end)
