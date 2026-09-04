local isMenuOpen = false
local cam = nil
local spawnedPed = nil
local headshotHandles = {}

local function cleanMugshots()
    for _, handle in ipairs(headshotHandles) do
        UnregisterPedheadshot(handle)
    end
    headshotHandles = {}
end

local function generateMugshots(chars, cb)
    local results = {}
    if #chars == 0 then
        cb(results)
        return
    end
    
    CreateThread(function()
        for i=1, #chars do
            local char = chars[i]
            local genderNum = tonumber(char.gender)
            local model = (genderNum == 0) and `mp_m_freemode_01` or `mp_f_freemode_01`
            RequestModel(model)
            while not HasModelLoaded(model) do Wait(0) end
            
            -- Spawn detrás de la cámara para que el motor gráfico lo renderice bien sin que el jugador lo vea
            local hiddenPed = CreatePed(4, model, Config.CamCoords.x + (i * 1.5), Config.CamCoords.y - 5.0, Config.CamCoords.z, 0.0, false, false)
            SetEntityCollision(hiddenPed, false, false)
            SetModelAsNoLongerNeeded(model)
            
            if char.metadata and char.metadata.appearance then
                pcall(function() exports['fivem-appearance']:setPedAppearance(hiddenPed, char.metadata.appearance) end)
                pcall(function() exports['illenium-appearance']:setPedAppearance(hiddenPed, char.metadata.appearance) end)
                TriggerEvent('aura_multichar:applyPedAppearance', hiddenPed, char.metadata.appearance)
            end
            
            Wait(500) -- Dar tiempo a cargar texturas y ropa
            
            local handle = RegisterPedheadshotTransparent(hiddenPed)
            local timer = GetGameTimer()
            while not IsPedheadshotReady(handle) or not IsPedheadshotValid(handle) do
                Wait(0)
                if GetGameTimer() - timer > 5000 then break end
            end
            
            if IsPedheadshotReady(handle) and IsPedheadshotValid(handle) then
                char.mugshot = GetPedheadshotTxdString(handle)
                table.insert(headshotHandles, handle)
            else
                UnregisterPedheadshot(handle)
                handle = RegisterPedheadshot(hiddenPed)
                timer = GetGameTimer()
                while not IsPedheadshotReady(handle) or not IsPedheadshotValid(handle) do
                    Wait(0)
                    if GetGameTimer() - timer > 5000 then break end
                end
                if IsPedheadshotReady(handle) and IsPedheadshotValid(handle) then
                    char.mugshot = GetPedheadshotTxdString(handle)
                    table.insert(headshotHandles, handle)
                else
                    char.mugshot = "none"
                end
            end
            
            DeleteEntity(hiddenPed)
            table.insert(results, char)
        end
        cb(results)
    end)
end

local function setupCam()
    DoScreenFadeOut(500)
    Wait(1000)
    SetFocusArea(Config.PedCoords.x, Config.PedCoords.y, Config.PedCoords.z, 0.0, 0.0, 0.0)
    
    -- Cinematic Orbital Camera Setup
    cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", Config.CamCoords.x, Config.CamCoords.y, Config.CamCoords.z, 0.0, 0.0, 0.0, 45.0, false, 0)
    PointCamAtCoord(cam, Config.PedCoords.x, Config.PedCoords.y, Config.PedCoords.z + 0.9)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 1500, true, false)
    
    -- Next-Gen Depth of Field (DoF) Effect
    SetCamUseShallowDofMode(cam, true)
    SetCamNearDof(cam, 1.2)
    SetCamFarDof(cam, 5.0)
    SetCamDofStrength(cam, 1.5)

    DoScreenFadeIn(1500)
end

local function spawnCharPed(gender, metadata)
    if spawnedPed then
        DeleteEntity(spawnedPed)
    end
    
    local genderNum = tonumber(gender)
    local model = (genderNum == 0) and `mp_m_freemode_01` or `mp_f_freemode_01`
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    spawnedPed = CreatePed(4, model, Config.PedCoords.x, Config.PedCoords.y, Config.PedCoords.z, Config.PedCoords.w, false, false)
    SetModelAsNoLongerNeeded(model)
    SetEntityHeading(spawnedPed, Config.PedCoords.w)
    FreezeEntityPosition(spawnedPed, true)
    SetEntityInvincible(spawnedPed, true)
    SetBlockingOfNonTemporaryEvents(spawnedPed, true)
    
    if metadata and metadata.appearance then
        pcall(function() exports['fivem-appearance']:setPedAppearance(spawnedPed, metadata.appearance) end)
        pcall(function() exports['illenium-appearance']:setPedAppearance(spawnedPed, metadata.appearance) end)
        TriggerEvent('aura_multichar:applyPedAppearance', spawnedPed, metadata.appearance)
    end
    
    -- Animación idle para dar vida al personaje
    RequestAnimDict("anim@heists@heist_corona@single_team")
    while not HasAnimDictLoaded("anim@heists@heist_corona@single_team") do Wait(0) end
    TaskPlayAnim(spawnedPed, "anim@heists@heist_corona@single_team", "single_team_loop_boss", 8.0, 0.0, -1, 1, 0, 0, 0, 0)

    SetEntityAlpha(spawnedPed, 0, false)
    for i=0, 255, 51 do
        SetEntityAlpha(spawnedPed, i, false)
        Wait(50)
    end
end



-- Interceptar el inicio y forzar la selección de personaje
CreateThread(function()
    while true do
        Wait(100)
        if NetworkIsPlayerActive(PlayerId()) then
            pcall(function() exports.spawnmanager:setAutoSpawn(false) end)
            TriggerEvent('aura_multichar:openMenu')
            break
        end
    end
end)

AddEventHandler('aura_multichar:openMenu', function()
    if isMenuOpen then return end
    isMenuOpen = true
    pcall(function() exports.spawnmanager:setAutoSpawn(false) end)
    
    -- Desactivar hud
    DisplayHud(false)
    DisplayRadar(false)

    setupCam()

    lib.callback('aura_multichar:getCharacters', false, function(chars)
        generateMugshots(chars, function(updatedChars)
            SetNuiFocus(true, true)
            SendNUIMessage({
                action = "setupCharacters",
                characters = updatedChars,
                maxSlots = Config.MaxCharacters
            })
            ShutdownLoadingScreenNui()
            ShutdownLoadingScreen()
        end)
    end)
end)

RegisterNUICallback('previewCharacter', function(data, cb)
    spawnCharPed(data.gender, data.metadata)
    cb('ok')
end)

RegisterNUICallback('hidePed', function(data, cb)
    if spawnedPed then
        DeleteEntity(spawnedPed)
        spawnedPed = nil
    end
    cb('ok')
end)

local lastCreationData = nil

RegisterNUICallback('createCharacter', function(data, cb)
    lastCreationData = data
    lib.callback('aura_multichar:createCharacter', false, function(newChar)
        if newChar then
            isMenuOpen = false
            SetNuiFocus(false, false)
            SendNUIMessage({action = "hideUI"})

            -- Eliminar ped dummy preview
            if spawnedPed then
                DeleteEntity(spawnedPed)
                spawnedPed = nil
            end
            cleanMugshots()

            -- Destruir cámara estática de multichar para dar paso a la cámara dinámica 3D de apariencia
            if cam then
                RenderScriptCams(false, false, 0, true, true)
                DestroyCam(cam, false)
                cam = nil
            end

            -- Posicionar al jugador REAL exactamente en el mismo lugar del escenario
            local ped = PlayerPedId()
            SetEntityCoords(ped, Config.PedCoords.x, Config.PedCoords.y, Config.PedCoords.z, false, false, false, false)
            SetEntityHeading(ped, Config.PedCoords.w)
            FreezeEntityPosition(ped, true)

            -- Iniciar directamente la personalización de apariencia 3D en el mismo escenario
            TriggerEvent('aura_appearance:startCustomization', newChar.gender, newChar)
            cb('ok')
        else
            cb('error')
        end
    end, data)
end)

RegisterNetEvent('aura_multichar:backToCreation', function()
    TriggerServerEvent('aura_multichar:cancelPendingCharacter')
    TriggerEvent('aura_multichar:openMenu')
    CreateThread(function()
        Wait(400)
        SendNUIMessage({
            action = "reopenCreation",
            lastData = lastCreationData
        })
    end)
end)

RegisterNUICallback('selectCharacter', function(data, cb)
    cb('ok')
    CreateThread(function()
        isMenuOpen = false

        DoScreenFadeOut(500)
        Wait(500)

        SetNuiFocus(false, false)
        SendNUIMessage({action = "hideUI"})

        if cam then
            RenderScriptCams(false, false, 0, true, true)
            DestroyCam(cam, false)
            cam = nil
        end
        ClearFocus()

        if spawnedPed then
            DeleteEntity(spawnedPed)
            spawnedPed = nil
        end
        cleanMugshots()
        
        lib.callback('aura_multichar:selectCharacter', false, function(charData)
            if not charData then return end
            
            local spawnCoords = charData.metadata.last_location or {x = -1037.8, y = -2737.9, z = 20.17, heading = 330.0}
            
            local hash = `mp_m_freemode_01`
            if charData.gender and tonumber(charData.gender) == 1 then
                hash = `mp_f_freemode_01`
            end
            
            RequestModel(hash)
            while not HasModelLoaded(hash) do Wait(0) end
            
            SetPlayerModel(PlayerId(), hash)
            SetModelAsNoLongerNeeded(hash)
            
            local ped = PlayerPedId()
            
            RequestCollisionAtCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z)
            SetEntityCoordsNoOffset(ped, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false, true)
            SetEntityHeading(ped, spawnCoords.heading or 330.0)
            
            local timer = GetGameTimer() + 5000
            while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < timer do 
                Wait(0)
            end
            
            SetEntityCoordsNoOffset(ped, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false, true)
            FreezeEntityPosition(ped, false)
            
            local isNew = (not charData.metadata.appearance or next(charData.metadata.appearance) == nil)
            if isNew then
                TriggerEvent('aura_appearance:startCustomization', charData.gender, charData)
            else
                TriggerEvent('aura_appearance:applyAppearance', charData.metadata.appearance)
            end
            
            DisplayHud(true)
            DisplayRadar(true)
            TriggerEvent('aura_multichar:client:characterLoaded', charData)
            TriggerServerEvent('aura_multichar:server:characterLoaded', charData.id)
            
            DoScreenFadeIn(1000)
            TriggerEvent('aura_core:client:playerSpawned')
        end, data.id)
    end)
end)

RegisterNUICallback('deleteCharacter', function(data, cb)
    lib.callback('aura_multichar:deleteCharacter', false, function(success)
        if success then
            lib.callback('aura_multichar:getCharacters', false, function(chars)
                cleanMugshots()
                generateMugshots(chars, function(updatedChars)
                    SendNUIMessage({
                        action = "setupCharacters",
                        characters = updatedChars,
                        maxSlots = Config.MaxCharacters
                    })
                end)
            end)
            cb('ok')
        else
            cb('error')
        end
    end, data.slot)
end)

-- Sincronización periódica de ubicación del personaje (cada 15 segundos)
CreateThread(function()
    while true do
        Wait(15000)
        if not isMenuOpen then
            local ped = PlayerPedId()
            if DoesEntityExist(ped) and not IsEntityDead(ped) then
                local coords = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)
                if coords and (coords.x ~= 0.0 or coords.y ~= 0.0) then
                    TriggerServerEvent('aura_multichar:server:updateLocation', {
                        x = coords.x,
                        y = coords.y,
                        z = coords.z,
                        heading = heading
                    })
                end
            end
        end
    end
end)
