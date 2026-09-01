-- ===================================================
-- AURA PHONE - DUAL-STATE NATIVE CAMERA ENGINE (Phase 8.4)
-- ===================================================

local isCameraActive = false
local isFrontCam = false
local isFlashOn = false
local currentZoom = 1.0
local isTakingPhoto = false
local isCursorActive = false

-- Función auxiliar para captura en Base64 (Fallback si el webhook de Discord falla o no está configurado)
local function CaptureBase64Fallback()
    local success, err = pcall(function()
        exports['screenshot-basic']:requestScreenshot({ encoding = 'jpg', quality = 0.85 }, function(base64)
            if base64 and base64 ~= "" then
                local formattedUrl = "data:image/jpeg;base64," .. base64
                TriggerServerEvent("aura_phone:server:saveGalleryPhoto", formattedUrl)
                SendNUIMessage({
                    action = "photoSaved",
                    url = formattedUrl
                })
                if lib and lib.notify then
                    lib.notify({
                        title = "Aura Galería",
                        description = "Foto capturada y guardada en el dispositivo",
                        type = "success"
                    })
                end
            end
            isTakingPhoto = false
        end)
    end)

    if not success then
        isTakingPhoto = false
        if lib and lib.notify then
            lib.notify({
                title = "Error de Cámara",
                description = "Configura el Webhook de Discord. Tu screenshot-basic no soporta Base64.",
                type = "error"
            })
        else
            print("^1[AURA PHONE] Error: screenshot-basic no soporta requestScreenshot (Base64). Configura el webhook de Discord.^7")
        end
    end
end

-- Ejecutar secuencia completa de captura de fotografía
local function ExecutePhotoCapture()
    if isTakingPhoto then return end
    isTakingPhoto = true

    -- 1. Sonido nativo de obturador y animación visual en el NUI
    PlaySoundFrontend(-1, "Camera_Shoot", "Phone_Soundset_Franklin", true)
    SendNUIMessage({ action = "shutterAnimation" })

    -- 2. Destello de flash intenso en las coordenadas de la cámara
    local camCoords = GetGameplayCamCoords()
    DrawLightWithRange(camCoords.x, camCoords.y, camCoords.z, 255, 255, 255, 30.0, 12.0)

    -- 3. Captura y subida por Webhook o Base64
    local webhook = (AuraConfig and AuraConfig.DiscordWebhook)
    local isWebhookConfigured = webhook and webhook ~= "" and not string.find(webhook, "placeholder")

    if isWebhookConfigured then
        local success = pcall(function()
            exports['screenshot-basic']:requestScreenshotUpload(webhook, "files[]", function(data)
                local resp = json.decode(data)
                if resp and resp.attachments and resp.attachments[1] then
                    local url = resp.attachments[1].url
                    TriggerServerEvent("aura_phone:server:saveGalleryPhoto", url)
                    SendNUIMessage({
                        action = "photoSaved",
                        url = url
                    })
                    if lib and lib.notify then
                        lib.notify({
                            title = "Aura Galería",
                            description = "Foto subida y guardada en tu Galería",
                            type = "success"
                        })
                    end
                else
                    CaptureBase64Fallback()
                end
                isTakingPhoto = false
            end)
        end)
        if not success then
            CaptureBase64Fallback()
        end
    else
        CaptureBase64Fallback()
    end

    Wait(1000)
end

-- Dibujar caja de instrucciones en la esquina superior izquierda (Estética HUD Nativa de AuraRP)
local function DrawInstructionalHUD()
    if not (AuraConfig and AuraConfig.Camera and AuraConfig.Camera.InstructionalHUD ~= false) then return end

    local x = 0.015
    local y = 0.02
    local width = 0.195
    local height = 0.165

    -- Caja de fondo translúcida (Glassmorphism oscuro)
    DrawRect(x + (width / 2), y + (height / 2), width, height, 5, 5, 8, 195)
    
    -- Borde de acento Cyan a la izquierda (Aura Brand)
    DrawRect(x + 0.001, y + (height / 2), 0.0022, height, 0, 240, 255, 220)

    -- Función para renderizar cada línea con tipografía nativa GTA
    local function DrawInstructionLine(text, lineIdx)
        SetTextFont(4)
        SetTextProportional(true)
        SetTextScale(0.31, 0.31)
        SetTextColour(255, 255, 255, 245)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(1, 0, 0, 0, 255)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        AddTextComponentSubstringPlayerName(text)
        DrawText(x + 0.008, y + 0.006 + (lineIdx * 0.025))
    end

    local cursorStateText = isCursorActive and "~r~[CLICK DER]~s~ Bloquear Ratón" or "~g~[CLICK DER]~s~ Liberar Ratón"
    DrawInstructionLine("~g~[CLICK IZQ / ENTER]~s~ Tomar foto", 0)
    DrawInstructionLine(cursorStateText, 1)
    DrawInstructionLine("~b~[FLECHA ARRIBA]~s~ Voltear cámara", 2)
    DrawInstructionLine("~y~[E]~s~ Alternar flash", 3)
    DrawInstructionLine("~c~[RUEDA / Z / C]~s~ Zoom", 4)
    DrawInstructionLine("~r~[ESC / BORRAR]~s~ Salir", 5)
end

-- Detener la Cámara y restaurar la vista normal en 3ra persona y el HUD
function StopNativeCamera()
    if not isCameraActive then return end
    isCameraActive = false
    isTakingPhoto = false
    isFlashOn = false
    isFrontCam = false
    isCursorActive = false
    currentZoom = 1.0

    -- 1. Desactivar cámara móvil nativa de GTA V
    CellCamActivate(false, false)
    DestroyMobilePhone()
    
    -- 2. Limpiar tareas/animaciones del ped
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    StopAnimTask(ped, "cellphone@", "cellphone_text_in", 1.0)
    StopAnimTask(ped, "cellphone@self@male", "selfie", 1.0)

    -- 3. Restaurar Radar y HUD
    DisplayRadar(true)

    -- 4. Devolver foco NUI seguro para interacción con el teléfono
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)

    -- 5. Notificar a NUI
    SendNUIMessage({
        action = "exitCameraMode"
    })
end

-- Iniciar el Modo de Cámara Nativo
local function StartNativeCamera()
    if isCameraActive then return end
    isCameraActive = true
    isFrontCam = false
    isFlashOn = false
    currentZoom = 1.0
    isTakingPhoto = false
    isCursorActive = false

    -- 1. Quitar Foco NUI por defecto para permitir apuntar con el ratón libremente
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    -- 2. Notificar inmediatamente al frontend para aplicar el visor transparente
    SendNUIMessage({
        action = "enterCameraMode",
        isFront = isFrontCam,
        zoom = currentZoom
    })

    -- 3. Activar cámara nativa de Snapmatic en GTA V (false = cámara trasera por defecto)
    CreateMobilePhone(1)
    CellCamActivate(true, false)
    
    -- 4. Destruir modelo 3D del iFruit para que solo se vea la UI de Aura Phone
    DestroyMobilePhone()

    -- 5. Bucle optimizado de input y renderizado (Solo activo mientras la cámara está abierta)
    CreateThread(function()
        while isCameraActive do
            Wait(0)

            -- Deshabilitar acciones de ataque, disparo y apuntado de armas en GTA
            DisableControlAction(0, 24, true)  -- Attack / Left Click
            DisableControlAction(0, 25, true)  -- Aim / Right Click
            DisableControlAction(0, 140, true) -- Melee Light
            DisableControlAction(0, 141, true) -- Melee Heavy
            DisableControlAction(0, 142, true) -- Melee Alternate
            DisableControlAction(0, 257, true) -- Attack 2
            DisableControlAction(0, 37, true)  -- Weapon Wheel
            DisablePlayerFiring(PlayerId(), true)

            -- Ocultar HUD y Minimapa del juego
            DisplayRadar(false)
            HideHudAndRadarThisFrame()
            HideHudComponentThisFrame(1)  -- Wanted Stars
            HideHudComponentThisFrame(2)  -- Weapon Icon
            HideHudComponentThisFrame(3)  -- Cash
            HideHudComponentThisFrame(4)  -- MP Cash
            HideHudComponentThisFrame(6)  -- Vehicle Name
            HideHudComponentThisFrame(7)  -- Area Name
            HideHudComponentThisFrame(8)  -- Vehicle Class
            HideHudComponentThisFrame(9)  -- Street Name
            HideHudComponentThisFrame(13) -- Cash Change
            HideHudComponentThisFrame(19) -- Weapon Wheel
            HideHudComponentThisFrame(20) -- Weapon Wheel Stats

            -- Dibujar HUD con las instrucciones en la esquina superior izquierda
            DrawInstructionalHUD()

            -- Iluminación en tiempo real si el flash está activado
            if isFlashOn then
                local camCoords = GetGameplayCamCoords()
                DrawLightWithRange(camCoords.x, camCoords.y, camCoords.z, 255, 255, 235, 18.0, 3.5)
            end

            -- ==========================================
            -- CONTROLES DUAL-STATE (LB-PHONE STYLE)
            -- ==========================================

            -- 1. CLICK DERECHO -> Alternar Cursor NUI (Libera o bloquea ratón para interactuar con botones HTML)
            if IsDisabledControlJustPressed(0, 25) or IsControlJustPressed(0, 25) then
                isCursorActive = not isCursorActive
                SetNuiFocus(isCursorActive, isCursorActive)
                SetNuiFocusKeepInput(not isCursorActive)
                PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                SendNUIMessage({
                    action = "toggleCursorState",
                    active = isCursorActive
                })
            end

            -- 2. CLICK IZQUIERDO -> Disparador de Foto (Solo cuando el cursor está oculto / modo apuntado)
            if not isCursorActive then
                if (IsDisabledControlJustPressed(0, 24) or IsControlJustPressed(0, 24) or IsControlJustPressed(0, 191) or IsControlJustPressed(0, 18) or IsControlJustPressed(0, 176) or IsControlJustPressed(0, 201) or IsControlJustPressed(0, 22)) and not isTakingPhoto then
                    ExecutePhotoCapture()
                end
            end

            -- 3. Voltear Cámara (Selfie / Trasera) -> [Flecha Arriba] (172 / 27)
            if IsControlJustPressed(0, 172) or IsControlJustPressed(0, 27) then
                isFrontCam = not isFrontCam
                CellCamActivate(true, isFrontCam)
                
                local ped = PlayerPedId()
                if isFrontCam then
                    RequestAnimDict("cellphone@self@male")
                    while not HasAnimDictLoaded("cellphone@self@male") do Wait(10) end
                    TaskPlayAnim(ped, "cellphone@self@male", "selfie", 3.0, -1, -1, 50, 0, false, false, false)
                else
                    StopAnimTask(ped, "cellphone@self@male", "selfie", 1.0)
                    RequestAnimDict("cellphone@")
                    while not HasAnimDictLoaded("cellphone@") do Wait(10) end
                    TaskPlayAnim(ped, "cellphone@", "cellphone_text_in", 3.0, -1, -1, 50, 0, false, false, false)
                end

                SendNUIMessage({
                    action = "updateCameraFlipState",
                    isFront = isFrontCam
                })
                PlaySoundFrontend(-1, "Phone_Generic_Key_01", "HUD_MINIGAME_SOUNDSET", true)
            end

            -- 4. Alternar Flash -> [E] (38 / 51)
            if IsControlJustPressed(0, 38) or IsControlJustPressed(0, 51) then
                isFlashOn = not isFlashOn
                SendNUIMessage({
                    action = "toggleFlashUI",
                    active = isFlashOn
                })
                PlaySoundFrontend(-1, "Toggle_Bar_Beep", "DLC_EXEC_DOCK_SOUNDSET", true)
            end

            -- 5. Control de Zoom -> [Rueda del Ratón] o [Z] (48) / [C] (26)
            if IsControlJustPressed(0, 241) or IsControlJustPressed(0, 48) then -- Zoom In
                currentZoom = math.min(3.0, currentZoom + 0.5)
                SendNUIMessage({ action = "updateCameraZoom", zoom = currentZoom })
            elseif IsControlJustPressed(0, 242) or IsControlJustPressed(0, 26) then -- Zoom Out
                currentZoom = math.max(0.5, currentZoom - 0.5)
                SendNUIMessage({ action = "updateCameraZoom", zoom = currentZoom })
            end

            -- 6. Salir de la Cámara -> [RETROCESO / ESC] (177 / 194 / 200 / 202)
            if IsControlJustPressed(0, 177) or IsControlJustPressed(0, 194) or IsControlJustPressed(0, 200) or IsControlJustPressed(0, 202) then
                StopNativeCamera()
            end
        end
    end)
end

-- ==========================================
-- NUI CALLBACKS (Frontend -> Client)
-- ==========================================

RegisterNUICallback('openCamera', function(data, cb)
    StartNativeCamera()
    cb('ok')
end)

RegisterNUICallback('closeCamera', function(data, cb)
    StopNativeCamera()
    cb('ok')
end)

RegisterNUICallback('takePhoto', function(data, cb)
    if isCameraActive and not isTakingPhoto then
        ExecutePhotoCapture()
    end
    cb('ok')
end)

RegisterNUICallback('toggleCameraFlip', function(data, cb)
    if isCameraActive then
        isFrontCam = not isFrontCam
        CellCamActivate(true, isFrontCam)
        local ped = PlayerPedId()
        if isFrontCam then
            RequestAnimDict("cellphone@self@male")
            while not HasAnimDictLoaded("cellphone@self@male") do Wait(10) end
            TaskPlayAnim(ped, "cellphone@self@male", "selfie", 3.0, -1, -1, 50, 0, false, false, false)
        else
            StopAnimTask(ped, "cellphone@self@male", "selfie", 1.0)
            RequestAnimDict("cellphone@")
            while not HasAnimDictLoaded("cellphone@") do Wait(10) end
            TaskPlayAnim(ped, "cellphone@", "cellphone_text_in", 3.0, -1, -1, 50, 0, false, false, false)
        end
        SendNUIMessage({
            action = "updateCameraFlipState",
            isFront = isFrontCam
        })
    end
    cb('ok')
end)

RegisterNUICallback('setCameraZoom', function(data, cb)
    if isCameraActive and data.zoom then
        currentZoom = tonumber(data.zoom) or 1.0
        SendNUIMessage({ action = "updateCameraZoom", zoom = currentZoom })
    end
    cb('ok')
end)

RegisterNUICallback('toggleCameraCursor', function(data, cb)
    if isCameraActive and isCursorActive then
        isCursorActive = false
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
        SendNUIMessage({
            action = "toggleCursorState",
            active = isCursorActive
        })
    end
    cb('ok')
end)

-- Limpieza preventiva si el recurso se reinicia
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if isCameraActive then
            CellCamActivate(false, false)
            DestroyMobilePhone()
            ClearPedTasks(PlayerPedId())
            DisplayRadar(true)
        end
    end
end)
