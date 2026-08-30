-- Client Script para desactivar NPCs de policía, dispatch y wanted level

CreateThread(function()
    while true do
        Wait(0)
        
        local player = PlayerId()
        
        -- Desactivar nivel de búsqueda (estrellas)
        if GetPlayerWantedLevel(player) ~= 0 then
            SetPlayerWantedLevel(player, 0, false)
            SetPlayerWantedLevelNow(player, false)
        end
        
        -- Configurar para que la policía ignore al jugador
        SetPoliceIgnorePlayer(player, true)
        SetDispatchCopsForPlayer(player, false)
        
        -- Desactivar la interfaz visual de estrellas por si acaso
        SetMaxWantedLevel(0)
    end
end)

CreateThread(function()
    -- Desactivar todos los servicios de Dispatch del juego (policía, bomberos, ambulancias, etc.)
    -- Hay 15 tipos de servicios (de 1 a 15)
    for i = 1, 15 do
        EnableDispatchService(i, false)
    end
    
    -- Deshabilitar la creación aleatoria de policías y vehículos policiales por el mundo
    SetCreateRandomCops(false)
    SetCreateRandomCopsNotOnScenarios(false)
    SetCreateRandomCopsOnScenarios(false)
    
    -- Para limpiar un poco la densidad de policías aleatorios en caso de que alguno intente spawnear
    SetVehicleModelIsSuppressed(`police`, true)
    SetVehicleModelIsSuppressed(`police2`, true)
    SetVehicleModelIsSuppressed(`police3`, true)
    SetVehicleModelIsSuppressed(`police4`, true)
    SetVehicleModelIsSuppressed(`policeb`, true)
    SetVehicleModelIsSuppressed(`policet`, true)
    SetVehicleModelIsSuppressed(`policeold1`, true)
    SetVehicleModelIsSuppressed(`policeold2`, true)
    SetVehicleModelIsSuppressed(`fbi`, true)
    SetVehicleModelIsSuppressed(`fbi2`, true)
    SetVehicleModelIsSuppressed(`sheriff`, true)
    SetVehicleModelIsSuppressed(`sheriff2`, true)
    SetVehicleModelIsSuppressed(`pranger`, true)
    SetVehicleModelIsSuppressed(`riot`, true)
end)
