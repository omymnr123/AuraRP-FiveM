local currentFrequency = 0
local radioOpen = false

-- Export para abrir la UI de la radio (se puede llamar desde un item usable en ox_inventory)
exports('openRadio', function()
    -- Aquí podrías añadir una UI nativa NUI para la radio,
    -- por ahora, usaremos un input rápido con ox_lib
    local input = lib.inputDialog('Comunicador Táctico', {
        {type = 'number', label = 'Frecuencia (MHz)', description = 'Ingresa una frecuencia entre 1 y 999', icon = 'hashtag'},
    })

    if not input then return end
    
    local freq = tonumber(input[1])
    if freq and freq > 0 and freq < 1000 then
        TriggerServerEvent('aura_comms:server:joinRadio', freq)
    else
        lib.notify({
            title = 'Error',
            description = 'Frecuencia inválida.',
            type = 'error'
        })
    end
end)

-- Cerrar radio
exports('leaveRadio', function()
    TriggerServerEvent('aura_comms:server:joinRadio', 0)
end)

-- Sincronizar desde el servidor (aprobado)
RegisterNetEvent('aura_comms:client:syncRadio', function(frequency)
    currentFrequency = frequency
    
    if frequency > 0 then
        exports["pma-voice"]:setRadioChannel(frequency)
        lib.notify({
            title = 'Radio',
            description = string.format('Conectado a la frecuencia %s MHz', frequency),
            type = 'success',
            icon = 'satellite-dish',
            style = {
                backgroundColor = 'rgba(20, 20, 30, 0.8)',
                backdropFilter = 'blur(10px)',
                color = '#00F0FF'
            }
        })
    else
        exports["pma-voice"]:setRadioChannel(0)
        lib.notify({
            title = 'Radio',
            description = 'Desconectado de la frecuencia.',
            type = 'info',
            icon = 'volume-xmark',
            style = {
                backgroundColor = 'rgba(20, 20, 30, 0.8)',
                backdropFilter = 'blur(10px)',
                color = '#FF0055'
            }
        })
    end
end)

-- Forzado a salir si el servidor detecta pérdida del item
RegisterNetEvent('aura_comms:client:forceLeaveRadio', function()
    if currentFrequency > 0 then
        exports["pma-voice"]:setRadioChannel(0)
        currentFrequency = 0
        lib.notify({
            title = 'Radio Perdida',
            description = 'Se ha desconectado la señal.',
            type = 'error',
            icon = 'link-slash'
        })
    end
end)
