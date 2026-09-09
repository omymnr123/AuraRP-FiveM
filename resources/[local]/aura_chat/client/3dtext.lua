local active3DTexts = {}
local isRendering = false

-- Función matemática para calcular escala visual proporcional y perspectiva con fuente fina
local function Draw3DMeText(coords, text, alpha, dist)
    local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
    if not onScreen then return end

    local camFov = GetGameplayCamFov()
    local fovMultiplier = (1.0 / camFov) * 100.0

    -- ==============================================================================
    -- >>> [TAMAÑO BASE DE LA FUENTE 3D DEFINIDO EN CONFIG.LUA] <<<
    -- ==============================================================================
    local baseScale = Config.Text3D.scale or 0.22
    local scale = ((1.0 / dist) * 2.0) * fovMultiplier * baseScale

    -- Clamping adaptado a tamaños reducidos y estilizados
    if scale < 0.12 then scale = 0.12 end
    if scale > 0.32 then scale = 0.32 end

    SetTextScale(0.0, scale)
    SetTextFont(Config.Text3D.font or 0)
    SetTextProportional(true)
    SetTextColour(Config.Text3D.primaryColor.r, Config.Text3D.primaryColor.g, Config.Text3D.primaryColor.b, alpha)
    SetTextDropshadow(1, 0, 0, 0, math.floor(alpha * 0.85))
    if Config.Text3D.outline then
        SetTextOutline()
    end
    SetTextCentre(true)

    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(screenX, screenY)
end

-- Bucle de renderizado de alto rendimiento (0.0ms en reposo)
local function StartRenderLoop()
    if isRendering then return end
    isRendering = true

    CreateThread(function()
        while isRendering do
            local count = #active3DTexts
            if count == 0 then
                isRendering = false
                break
            end

            local now = GetGameTimer()
            local myPed = PlayerPedId()
            local myCoords = GetEntityCoords(myPed)
            local myServerId = GetPlayerServerId(PlayerId())

            local i = 1
            while i <= #active3DTexts do
                local item = active3DTexts[i]
                local elapsed = now - item.startTime

                if elapsed >= item.duration then
                    table.remove(active3DTexts, i)
                else
                    -- Progreso normalizado de 0.0 a 1.0
                    local progress = elapsed / item.duration
                    
                    -- Desvanecimiento suave al final del tiempo
                    local alpha = 255
                    if progress > 0.70 then
                        alpha = math.floor(255 * (1.0 - ((progress - 0.70) / 0.30)))
                    end
                    if alpha < 0 then alpha = 0 end

                    -- Resolución dinámica del ped objetivo
                    local targetPed = nil
                    if item.targetServerId == myServerId then
                        targetPed = myPed
                    else
                        local targetPlayer = GetPlayerFromServerId(item.targetServerId)
                        if targetPlayer and targetPlayer ~= -1 and NetworkIsPlayerActive(targetPlayer) then
                            targetPed = GetPlayerPed(targetPlayer)
                        end
                    end

                    if targetPed and DoesEntityExist(targetPed) then
                        local targetCoords = GetEntityCoords(targetPed)
                        local dist = #(myCoords - targetCoords)

                        if dist <= Config.Text3D.maxDistance then
                            -- Obtención de la coordenada ósea de la cabeza (Bone 31086: SKEL_Head)
                            local headCoords = GetPedBoneCoords(targetPed, 31086, 0.0, 0.0, 0.0)
                            if #(headCoords) < 1.0 then
                                headCoords = targetCoords + vector3(0.0, 0.0, 0.8)
                            end

                            -- Posición fija sin desplazamiento vertical (No Drift)
                            local renderZ = headCoords.z + Config.Text3D.baseOffsetZ + (item.stackOffset or 0.0)
                            local renderCoords = vector3(headCoords.x, headCoords.y, renderZ)

                            Draw3DMeText(renderCoords, item.text, alpha, dist)
                        end
                    end

                    i = i + 1
                end
            end

            Wait(0)
        end
    end)
end

RegisterNetEvent('aura_chat:client:show3DMe', function(targetServerId, text)
    if not targetServerId or not text or text == '' then return end

    -- Limpieza estricta de cualquier asterisco que pudiera venir en el texto
    local cleanText = string.gsub(text, "^%*%s*", "")
    cleanText = string.gsub(cleanText, "%s*%*$", "")

    local existingCount = 0
    for _, item in ipairs(active3DTexts) do
        if item.targetServerId == targetServerId then
            existingCount = existingCount + 1
        end
    end

    table.insert(active3DTexts, {
        targetServerId = targetServerId,
        text = cleanText,
        startTime = GetGameTimer(),
        duration = Config.Text3D.duration,
        stackOffset = existingCount * 0.16
    })

    StartRenderLoop()
end)

exports('show3DText', function(targetServerId, text, customDuration)
    if not targetServerId or not text then return end

    local cleanText = string.gsub(text, "^%*%s*", "")
    cleanText = string.gsub(cleanText, "%s*%*$", "")

    local existingCount = 0
    for _, item in ipairs(active3DTexts) do
        if item.targetServerId == targetServerId then
            existingCount = existingCount + 1
        end
    end

    table.insert(active3DTexts, {
        targetServerId = targetServerId,
        text = cleanText,
        startTime = GetGameTimer(),
        duration = customDuration or Config.Text3D.duration,
        stackOffset = existingCount * 0.16
    })

    StartRenderLoop()
end)
