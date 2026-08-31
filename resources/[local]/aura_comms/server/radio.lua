local AuraComms = {}

-- Validar si el jugador tiene una radio en su inventario
local function HasRadio(source)
    local count = exports.ox_inventory:Search(source, 'count', 'radio')
    return count and count > 0
end

-- Evento invocado desde el cliente para unirse a una frecuencia
RegisterNetEvent('aura_comms:server:joinRadio', function(frequency)
    local src = source
    if not src then return end
    
    if HasRadio(src) then
        -- Permiso concedido
        TriggerClientEvent('aura_comms:client:syncRadio', src, frequency)
    else
        -- Rechazado
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Comunicaciones',
            description = 'No tienes un dispositivo de radio',
            type = 'error',
            style = {
                backgroundColor = '#1e1e2f',
                color = '#f1f1f1',
                ['.description'] = {
                  color = '#9090a0'
                }
            },
            icon = 'walkie-talkie'
        })
    end
end)

-- Cuando el jugador suelta/pierde el item de la radio, desconectarlo
AddEventHandler('ox_inventory:updateInventory', function(action, payload)
    if action == 'remove' and payload.item.name == 'radio' then
        local src = payload.source
        if not HasRadio(src) then
            TriggerClientEvent('aura_comms:client:forceLeaveRadio', src)
        end
    end
end)
