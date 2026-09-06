-- ============================================================================
-- AURA MEDICAL: ESCÁNER DIAGNÓSTICO 3D WORLD-TO-SCREEN (CLIENT SCANNER)
-- ============================================================================

local isScannerOpen = false
local scannerCam = nil
local targetPed = nil

-- ============================================================================
-- OBTENCIÓN DINÁMICA DE CONSTANTES VITALES (PUENTES DE DATOS)
-- ============================================================================

local function GetLiveVitalSigns()
    local ped = PlayerPedId()
    
    -- 1. Salud General
    local maxHealth = GetEntityMaxHealth(ped)
    local curHealth = GetEntityHealth(ped)
    local healthPercent = 0
    if maxHealth > 100 then
        healthPercent = math.max(0, math.min(100, math.floor(((curHealth - 100) / (maxHealth - 100)) * 100)))
    else
        healthPercent = math.max(0, math.min(100, math.floor((curHealth / maxHealth) * 100)))
    end

    -- 2. Blindaje / Armadura
    local armor = math.min(100, GetPedArmour(ped))

    -- 3. Hambre y Sed (Puente con aura_status vía StateBags / Exports)
    local hunger = 100
    local thirst = 100
    if LocalPlayer.state.hunger ~= nil then
        hunger = math.floor(LocalPlayer.state.hunger)
    elseif exports.aura_status and exports.aura_status.GetStatus then
        local st = exports.aura_status:GetStatus()
        if st and st.hunger then hunger = math.floor(st.hunger) end
    end

    if LocalPlayer.state.thirst ~= nil then
        thirst = math.floor(LocalPlayer.state.thirst)
    elseif exports.aura_status and exports.aura_status.GetStatus then
        local st = exports.aura_status:GetStatus()
        if st and st.thirst then thirst = math.floor(st.thirst) end
    end

    -- 4. Temperatura Corporal (Puente con aura_seasons vía StateBags / Exports)
    local bodyTemp = 36.8
    if LocalPlayer.state.body_temperature ~= nil then
        bodyTemp = LocalPlayer.state.body_temperature
    elseif exports.aura_seasons and exports.aura_seasons.GetCoreTemperature then
        local t = exports.aura_seasons:GetCoreTemperature()
        if t then bodyTemp = t end
    end

    -- 5. Frecuencia Cardíaca Dinámica (BPM)
    local bpm = 72
    if healthPercent < 30 then
        bpm = 138
    elseif healthPercent < 60 then
        bpm = 112
    elseif healthPercent < 85 then
        bpm = 88
    end
    if bodyTemp > 38.5 then
        bpm = bpm + 12
    elseif bodyTemp < 35.0 then
        bpm = bpm - 15
    end

    -- 6. Estado térmico descriptivo
    local tempStatus = "Normal"
    local tempColor = "#00f2fe"
    if bodyTemp < 35.0 then
        tempStatus = "Hipotermia Severa"
        tempColor = "#3b82f6"
    elseif bodyTemp < 36.2 then
        tempStatus = "Hipotermia Leve"
        tempColor = "#00f2fe"
    elseif bodyTemp > 39.0 then
        tempStatus = "Hipertermia Crítica"
        tempColor = "#ff0055"
    elseif bodyTemp > 37.5 then
        tempStatus = "Fiebre Moderada"
        tempColor = "#ffaa00"
    end

    return {
        health = healthPercent,
        armor = armor,
        hunger = hunger,
        thirst = thirst,
        temperature = bodyTemp,
        tempStatus = tempStatus,
        tempColor = tempColor,
        bpm = bpm,
        bloodType = "O+",
        statusText = healthPercent > 75 and "ESTABLE" or (healthPercent > 35 and "COMPROMETIDO" or "CRÍTICO")
    }
end

-- ============================================================================
-- APERTURA / CIERRE DEL ESCÁNER 3D
-- ============================================================================

local function OpenMedicalScanner()
    if isScannerOpen then return end
    isScannerOpen = true

    local ped = PlayerPedId()
    targetPed = ped

    -- 1. Cámara Cinemática Enfocada
    local camOffset = Config.Camera.Offset
    local pointOffset = Config.Camera.PointOffset

    local camCoords = GetOffsetFromEntityInWorldCoords(targetPed, camOffset.x, camOffset.y, camOffset.z)
    local pointCoords = GetOffsetFromEntityInWorldCoords(targetPed, pointOffset.x, pointOffset.y, pointOffset.z)

    scannerCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(scannerCam, camCoords.x, camCoords.y, camCoords.z)
    PointCamAtCoord(scannerCam, pointCoords.x, pointCoords.y, pointCoords.z)
    SetCamFov(scannerCam, Config.Camera.Fov)
    SetCamActive(scannerCam, true)
    RenderScriptCams(true, true, Config.Camera.TransitionDuration, true, true)

    -- 2. Post-procesado Visual
    SetTimecycleModifier(Config.Camera.Timecycle)
    SetTimecycleModifierStrength(Config.Camera.TimecycleStrength)

    -- 3. Compilación de Datos
    local vitals = GetLiveVitalSigns()
    local boneDamage = exports['aura_medical']:GetBoneDamage()

    -- 4. Activar NUI Focus
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openScanner',
        vitals = vitals,
        bones = boneDamage,
        boneConfig = Config.Bones
    })

    -- 5. Bucle de Proyección World-to-Screen en Tiempo Real (60 FPS)
    CreateThread(function()
        while isScannerOpen do
            Wait(0)
            
            local nodePositions = {}
            local currentBones = exports['aura_medical']:GetBoneDamage()

            for groupKey, groupConfig in pairs(Config.Bones) do
                local boneIndex = GetPedBoneIndex(targetPed, groupConfig.primaryBone)
                local boneCoords = GetWorldPositionOfEntityBone(targetPed, boneIndex)
                
                -- Fallback si el hueso específico falla
                if boneCoords.x == 0.0 and boneCoords.y == 0.0 and boneCoords.z == 0.0 then
                    boneCoords = GetPedBoneCoords(targetPed, groupConfig.primaryBone, 0.0, 0.0, 0.0)
                end

                local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(boneCoords.x, boneCoords.y, boneCoords.z)
                
                local boneInfo = currentBones[groupKey] or { health = 100, injuries = {} }
                local isInjured = (boneInfo.health < 100 or #boneInfo.injuries > 0)

                nodePositions[groupKey] = {
                    onScreen = onScreen,
                    x = screenX * 100.0,
                    y = screenY * 100.0,
                    health = boneInfo.health,
                    injuriesCount = #boneInfo.injuries,
                    isInjured = isInjured,
                    label = groupConfig.label
                }
            end

            SendNUIMessage({
                action = 'updateBoneNodes',
                nodes = nodePositions
            })
        end
    end)
end

local function CloseMedicalScanner()
    if not isScannerOpen then return end
    isScannerOpen = false

    -- 1. Restaurar Cámara
    RenderScriptCams(false, true, 600, true, true)
    if scannerCam then
        DestroyCam(scannerCam, false)
        scannerCam = nil
    end

    -- 2. Limpiar Post-procesado
    ClearTimecycleModifier()

    -- 3. Desactivar NUI Focus
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeScanner'
    })
end

-- ============================================================================
-- EVENTOS Y CALLBACKS NUI
-- ============================================================================

RegisterNetEvent('aura_medical:client:openScanner', function()
    OpenMedicalScanner()
end)

RegisterNetEvent('aura_medical:client:closeScanner', function()
    CloseMedicalScanner()
end)

RegisterNUICallback('close', function(_, cb)
    CloseMedicalScanner()
    cb(1)
end)

RegisterNUICallback('requestVitals', function(_, cb)
    cb(GetLiveVitalSigns())
end)

RegisterNUICallback('playSound', function(data, cb)
    if data and data.sound then
        PlaySoundFrontend(-1, data.sound, data.soundSet or "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end
    cb(1)
end)

-- ============================================================================
-- KEYBIND OPCIONAL (F6)
-- ============================================================================

if Config.Keybind and Config.Keybind.Enabled then
    RegisterCommand('auramedical', function()
        if isScannerOpen then
            CloseMedicalScanner()
        else
            OpenMedicalScanner()
        end
    end, false)

    RegisterKeyMapping('auramedical', Config.Keybind.Description, 'keyboard', Config.Keybind.Key)
end

exports('OpenScanner', OpenMedicalScanner)
exports('CloseScanner', CloseMedicalScanner)
exports('IsScannerOpen', function() return isScannerOpen end)
