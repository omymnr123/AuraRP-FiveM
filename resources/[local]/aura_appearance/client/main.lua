-- aura_appearance/client/main.lua
-- Bridge de Apariencia para el ecosistema Aura
-- Conecta aura_multichar con illenium-appearance en modo standalone

-- Evento: Nuevo personaje → inicializar con ropa base y abrir creador de apariencia en el mismo escenario
AddEventHandler('aura_appearance:startCustomization', function(gender)
    local genderNum = tonumber(gender) or 0
    local genderStr = (genderNum == 1) and "Female" or "Male"

    -- Setear el género en el bridge de illenium
    pcall(function() exports['illenium-appearance']:setGender(genderNum) end)

    -- Iniciar personalización usando la export nativa
    exports['illenium-appearance']:InitializeCharacter(genderStr, function(appearance)
        if appearance then
            -- Guardar en la base de datos a través de aura_appearance
            TriggerServerEvent('aura_appearance:saveAppearance', appearance)
        end

        -- Transición cinemática de llegada al mundo: Aeropuerto Internacional de Los Santos (LSIA)
        DoScreenFadeOut(800)
        Wait(1000)

        local ped = PlayerPedId()
        local spawnCoords = vector4(-1037.8, -2737.9, 20.17, 330.0) -- Puerta de Llegadas de LSIA
        SetEntityCoords(ped, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false, false)
        SetEntityHeading(ped, spawnCoords.w)
        FreezeEntityPosition(ped, false)
        ClearFocus()

        DisplayHud(true)
        DisplayRadar(true)

        DoScreenFadeIn(1200)

        -- Notificar que el jugador terminó la creación y está listo en el mundo
        TriggerEvent('aura_core:playerSpawnedAndReady')
    end, function()
        -- Si cancela / vuelve atrás, regresar a la pantalla de registro de identidad
        local ped = PlayerPedId()
        FreezeEntityPosition(ped, true)
        TriggerEvent('aura_multichar:backToCreation')
    end)
end)

-- Evento: Personaje existente → aplicar apariencia guardada
AddEventHandler('aura_appearance:applyAppearance', function(appearance)
    if not appearance or next(appearance) == nil then
        FreezeEntityPosition(PlayerPedId(), false)
        return
    end

    -- Establecer el modelo correcto primero si está especificado
    if appearance.model then
        local modelHash = GetHashKey(appearance.model)
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do Wait(0) end
        SetPlayerModel(PlayerId(), modelHash)
        SetModelAsNoLongerNeeded(modelHash)
    end

    -- Aplicar la apariencia completa usando illenium
    exports['illenium-appearance']:setPlayerAppearance(appearance)

    -- Descongelar jugador
    FreezeEntityPosition(PlayerPedId(), false)
end)

-- Menú de Ropa (para tiendas)
RegisterNetEvent('aura_appearance:openClothingMenu', function()
    exports['illenium-appearance']:startPlayerCustomization(function(appearance)
        if appearance then
            TriggerServerEvent('aura_appearance:saveAppearance', appearance)
            TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
        end
    end, {
        ped = false,
        headBlend = false,
        faceFeatures = false,
        headOverlays = true,
        components = true,
        props = true,
        tattoos = false,
        enableExit = true
    })
end)

-- Menú de Barbería
RegisterNetEvent('aura_appearance:openBarberMenu', function()
    exports['illenium-appearance']:startPlayerCustomization(function(appearance)
        if appearance then
            TriggerServerEvent('aura_appearance:saveAppearance', appearance)
            TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
        end
    end, {
        ped = false,
        headBlend = true,
        faceFeatures = true,
        headOverlays = true,
        components = false,
        props = false,
        tattoos = false,
        enableExit = true
    })
end)

-- Menú de Tatuajes
RegisterNetEvent('aura_appearance:openTattooMenu', function()
    exports['illenium-appearance']:startPlayerCustomization(function(appearance)
        if appearance then
            TriggerServerEvent('aura_appearance:saveAppearance', appearance)
            TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
        end
    end, {
        ped = false,
        headBlend = false,
        faceFeatures = false,
        headOverlays = false,
        components = false,
        props = false,
        tattoos = true,
        enableExit = true
    })
end)
