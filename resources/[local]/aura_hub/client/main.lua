-- ============================================================================
-- AURA HUB: CLIENT MASTER PAUSE CONTROLLER
-- Native ESC Intercept, Dashboard NUI, Safe Map Trigger & Real Headshot Engine
-- ============================================================================

local isHubOpen = false
local isOpeningMap = false
local isOpeningSettings = false
local isLoadingHub = false
local currentHeadshotHandle = nil
local currentMugshotTxd = nil
local lastExternalNuiTime = 0
local lastHubCloseTime = 0

-- ============================================================================
-- GENERADOR DE AVATAR REAL DEL PED DEL JUGADOR (MUGSHOT NUI ULTRA-SEGURO)
-- ============================================================================

local isFetchingMugshot = false

local function RefreshPlayerMugshot()
    if isFetchingMugshot then return currentMugshotTxd end
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return nil end

    if currentHeadshotHandle and IsPedheadshotValid(currentHeadshotHandle) and IsPedheadshotReady(currentHeadshotHandle) then
        return currentMugshotTxd
    end

    isFetchingMugshot = true
    CreateThread(function()
        local newHandle = RegisterPedheadshotTransparent(ped)
        local timer = GetGameTimer()
        while not IsPedheadshotReady(newHandle) or not IsPedheadshotValid(newHandle) do
            Wait(100)
            if GetGameTimer() - timer > 3000 then break end
        end

        if IsPedheadshotReady(newHandle) and IsPedheadshotValid(newHandle) then
            local oldHandle = currentHeadshotHandle
            currentHeadshotHandle = newHandle
            currentMugshotTxd = GetPedheadshotTxdString(newHandle)
            if oldHandle and oldHandle ~= newHandle and IsPedheadshotValid(oldHandle) then
                UnregisterPedheadshot(oldHandle)
            end
        else
            UnregisterPedheadshot(newHandle)
            newHandle = RegisterPedheadshot(ped)
            timer = GetGameTimer()
            while not IsPedheadshotReady(newHandle) or not IsPedheadshotValid(newHandle) do
                Wait(100)
                if GetGameTimer() - timer > 3000 then break end
            end
            if IsPedheadshotReady(newHandle) and IsPedheadshotValid(newHandle) then
                local oldHandle = currentHeadshotHandle
                currentHeadshotHandle = newHandle
                currentMugshotTxd = GetPedheadshotTxdString(newHandle)
                if oldHandle and oldHandle ~= newHandle and IsPedheadshotValid(oldHandle) then
                    UnregisterPedheadshot(oldHandle)
                end
            end
        end
        isFetchingMugshot = false
    end)

    return currentMugshotTxd
end

-- Generar headshot inicial en segundo plano al cargar el personaje
RegisterNetEvent('aura_economy:server:characterLoaded', function()
    Wait(1500)
    RefreshPlayerMugshot()
end)

-- ============================================================================
-- VALIDACIÓN DE PANTALLA LIMPIA PARA APERTURA DE AURA HUB
-- ============================================================================

local function CanOpenAuraHub()
    -- Si el Hub ya está abierto o cargando, o abriendo mapa o ajustes nativos
    if isHubOpen or isLoadingHub or isOpeningMap or isOpeningSettings then
        return false
    end

    -- 1. Comprobación de NUI activa externa (Inventario, Teléfono, Banco, Menús, etc.)
    if IsNuiFocused() then
        return false
    end

    -- 2. Buffer/Cooldown tras haber cerrado otra NUI o el propio Hub (450 ms)
    -- Evita que la liberación de la tecla ESC tras cerrar otra ventana abra el Hub
    local now = GetGameTimer()
    if (now - lastExternalNuiTime) < 450 then
        return false
    end
    if (now - lastHubCloseTime) < 450 then
        return false
    end

    -- 3. Menú de pausa nativo de GTA V o mapa
    if IsPauseMenuActive() or (GetPauseMenuState and GetPauseMenuState() ~= 0) then
        return false
    end

    -- 4. Mensajes de advertencia nativos o frontend no disponible
    if IsWarningMessageActive and IsWarningMessageActive() then
        return false
    end

    -- 5. Transiciones de pantalla (pantalla negra, fundidos, cinemáticas, respawn)
    if IsScreenFadedOut() or IsScreenFadingOut() or IsScreenFadingIn() then
        return false
    end
    if IsPlayerSwitchInProgress and IsPlayerSwitchInProgress() then
        return false
    end

    -- 6. Estado del jugador (muerto, muriendo, inconsciente)
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) or IsPedDeadOrDying(ped, true) or IsEntityDead(ped) then
        return false
    end

    -- 7. State Bags de Aura RP / Ox (Muerte, Esposado, Encarcelado, Inventario abierto o busy)
    local pState = LocalPlayer.state
    if pState then
        if pState.isDead or pState.isCuffed or pState.isJailed or pState.invOpen or pState.invBusy then
            return false
        end
    end

    -- 8. Menús y elementos interactivos de ox_lib (Context Menus, Menús desplegables, Barras de progreso)
    if lib then
        if lib.progressActive and lib.progressActive() then
            return false
        end
        if lib.getOpenContextMenu and lib.getOpenContextMenu() ~= nil then
            return false
        end
        if lib.getOpenMenu and lib.getOpenMenu() ~= nil then
            return false
        end
    end

    return true
end

-- ============================================================================
-- APERTURA Y CIERRE DEL HUB
-- ============================================================================

local function OpenAuraHub()
    if not CanOpenAuraHub() then return end

    isLoadingHub = true

    lib.callback('aura_hub:server:getHubData', false, function(data)
        isLoadingHub = false

        if not data then
            lib.notify({
                title = 'Aura Hub',
                description = 'No se pudo cargar la información del personaje.',
                type = 'error'
            })
            return
        end

        -- Si el jugador abrió otra interfaz o cambió de estado mientras se esperaba la respuesta del servidor
        if not CanOpenAuraHub() and not isHubOpen then
            return
        end

        -- Inyectar el Mugshot real en caché o refrescarlo en segundo plano
        data.mugshot = currentMugshotTxd or RefreshPlayerMugshot()

        isHubOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openHub',
            data = data
        })
    end)
end

local function CloseAuraHub()
    if not isHubOpen and not isLoadingHub then return end
    isHubOpen = false
    isLoadingHub = false
    lastHubCloseTime = GetGameTimer()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeHub' })
end

-- ============================================================================
-- INTERCEPCIÓN SEGURA DEL MENÚ DE PAUSA (SIN CORRUPCIÓN RAGE GUI)
-- ============================================================================

CreateThread(function()
    while true do
        Wait(0)

        -- Monitorizar continuamente si hay alguna NUI externa activa en el juego
        if IsNuiFocused() and not isHubOpen then
            lastExternalNuiTime = GetGameTimer()
        end

        local pauseActive = IsPauseMenuActive()

        if not pauseActive and not isOpeningMap and not isOpeningSettings then
            -- Deshabilitar el control de pausa nativo para capturarlo nosotros
            DisableControlAction(0, 199, true) -- INPUT_FRONTEND_PAUSE
            DisableControlAction(0, 200, true) -- INPUT_FRONTEND_PAUSE_ALTERNATE

            if IsDisabledControlJustReleased(0, 199) or IsDisabledControlJustReleased(0, 200) then
                if isHubOpen then
                    CloseAuraHub()
                else
                    if CanOpenAuraHub() then
                        OpenAuraHub()
                    end
                end
            end
        else
            -- Si el jugador está dentro del mapa nativo de GTA V, permitimos el flujo normal
            Wait(150)
        end
    end
end)

-- ============================================================================
-- ESCUCHA DE ANUNCIOS GLOBALES (BANNER SUPERIOR DE APERTURA/CIERRE)
-- ============================================================================

RegisterNetEvent('aura_hub:client:showAnnouncement', function(announcementData)
    if not announcementData then return end

    SendNUIMessage({
        action = 'showAnnouncement',
        data = {
            business = announcementData.business or "Comercio",
            isOpen = announcementData.isOpen == true,
            openBusinesses = announcementData.openBusinesses,
            duration = announcementData.duration or 7000
        }
    })
end)

RegisterNetEvent('aura_hub:client:showDutyAnnouncement', function(dutyData)
    if not dutyData then return end

    SendNUIMessage({
        action = 'showDutyAnnouncement',
        data = {
            job = dutyData.job,
            label = dutyData.label or "Servicio Oficial",
            isDuty = dutyData.isDuty == true,
            isPolice = dutyData.isPolice == true,
            duration = 6500
        }
    })
end)

-- ============================================================================
-- NUI CALLBACKS
-- ============================================================================

RegisterNUICallback('closeHub', function(_, cb)
    CloseAuraHub()
    cb('ok')
end)

-- Apertura SEGURA del mapa nativo de GTA V sin error ERR_GUI_MENU_VER
RegisterNUICallback('openMap', function(_, cb)
    isHubOpen = false
    isLoadingHub = false
    isOpeningMap = true
    lastHubCloseTime = GetGameTimer()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeHub' })
    cb('ok')

    CreateThread(function()
        Wait(100)
        SetFrontendActive(true)
        ActivateFrontendMenu(GetHashKey('FE_MENU_VERSION_SP_PAUSE'), false, -1)
        
        -- Esperar a que el jugador cierre el mapa nativo
        while IsPauseMenuActive() do
            Wait(150)
        end
        Wait(350)
        isOpeningMap = false
    end)
end)

-- Apertura SEGURA de los Ajustes / Opciones de GTA V (Gráficos, Teclas, Audio, etc.)
RegisterNUICallback('openSettings', function(_, cb)
    isHubOpen = false
    isLoadingHub = false
    isOpeningSettings = true
    lastHubCloseTime = GetGameTimer()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeHub' })
    cb('ok')

    CreateThread(function()
        Wait(100)
        SetFrontendActive(true)
        ActivateFrontendMenu(GetHashKey('FE_MENU_VERSION_SP_PAUSE'), false, 6)
        
        -- Esperar a que el jugador cierre el menú de ajustes nativo
        while IsPauseMenuActive() do
            Wait(150)
        end
        Wait(350)
        isOpeningSettings = false
    end)
end)

RegisterNUICallback('toggleBusinessState', function(_, cb)
    lib.callback('aura_hub:server:toggleBusinessState', false, function(success, result, openBusinesses)
        cb({ success = success, result = result, openBusinesses = openBusinesses })
    end)
end)

RegisterNUICallback('fetchEmployees', function(_, cb)
    lib.callback('aura_hub:server:getEmployees', false, function(success, data)
        cb({ success = success, data = data })
    end)
end)

RegisterNUICallback('hireEmployee', function(data, cb)
    local targetSrc = tonumber(data.targetSrc)
    if not targetSrc then
        cb({ success = false, message = "ID de jugador inválido" })
        return
    end

    lib.callback('aura_hub:server:hireEmployee', false, function(success, message)
        cb({ success = success, message = message })
    end, targetSrc)
end)

RegisterNUICallback('fireEmployee', function(data, cb)
    local targetCharId = tonumber(data.targetCharId)
    if not targetCharId then
        cb({ success = false, message = "ID de personaje inválido" })
        return
    end

    lib.callback('aura_hub:server:fireEmployee', false, function(success, message)
        cb({ success = success, message = message })
    end, targetCharId)
end)

RegisterNUICallback('setEmployeeGrade', function(data, cb)
    lib.callback('aura_hub:server:setEmployeeGrade', false, function(success, message)
        cb({ success = success, message = message })
    end, { targetCharId = data.targetCharId, newGrade = data.newGrade })
end)

RegisterNUICallback('corporateWireTransfer', function(data, cb)
    lib.callback('aura_hub:server:corporateWireTransfer', false, function(success, message, newBalance)
        cb({ success = success, message = message, newBalance = newBalance })
    end, {
        targetIban = data.targetIban,
        amount = data.amount,
        reason = data.reason
    })
end)

RegisterNUICallback('disconnect', function(_, cb)
    CloseAuraHub()
    TriggerServerEvent('aura_hub:server:disconnect')
    cb('ok')
end)

RegisterNUICallback('toggleDuty', function(_, cb)
    lib.callback('aura_hub:server:toggleDuty', false, function(success, newDuty)
        cb({ success = success, newDuty = newDuty })
    end)
end)

-- ============================================================================
-- NUI CALLBACKS: MDT POLICIAL LSPD
-- ============================================================================

RegisterNUICallback('getPoliceMdtOverview', function(_, cb)
    lib.callback('aura_hub:server:getPoliceMdtOverview', false, function(success, data)
        cb({ success = success, data = data })
    end)
end)

RegisterNUICallback('policeSearchCitizen', function(data, cb)
    lib.callback('aura_hub:server:policeSearchCitizen', false, function(success, results)
        cb({ success = success, results = results })
    end, data.query)
end)

RegisterNUICallback('policeSearchVehicle', function(data, cb)
    lib.callback('aura_hub:server:policeSearchVehicle', false, function(success, result)
        cb({ success = success, result = result })
    end, data.plate)
end)

RegisterNUICallback('policeToggleVehicleBolo', function(data, cb)
    lib.callback('aura_hub:server:policeToggleVehicleBolo', false, function(success, message, isBolo)
        cb({ success = success, message = message, isBolo = isBolo })
    end, { plate = data.plate, reason = data.reason })
end)

RegisterNUICallback('policeIssueFine', function(data, cb)
    lib.callback('aura_hub:server:policeIssueFine', false, function(success, message)
        cb({ success = success, message = message })
    end, data)
end)

RegisterNUICallback('policeJailSuspect', function(data, cb)
    lib.callback('aura_hub:server:policeJailSuspect', false, function(success, message)
        cb({ success = success, message = message })
    end, data)
end)

RegisterNUICallback('policeGetWarrants', function(_, cb)
    lib.callback('aura_hub:server:policeGetWarrants', false, function(success, warrants)
        cb({ success = success, warrants = warrants })
    end)
end)

RegisterNUICallback('policeCreateWarrant', function(data, cb)
    lib.callback('aura_hub:server:policeCreateWarrant', false, function(success, message)
        cb({ success = success, message = message })
    end, data)
end)

RegisterNUICallback('policeDeleteWarrant', function(data, cb)
    lib.callback('aura_hub:server:policeDeleteWarrant', false, function(success, message)
        cb({ success = success, message = message })
    end, data.warrantId)
end)

RegisterNUICallback('policeGetActiveInmates', function(_, cb)
    lib.callback('aura_hub:server:policeGetActiveInmates', false, function(success, inmates)
        cb({ success = success, inmates = inmates })
    end)
end)

RegisterNUICallback('policeGetDispatchHistory', function(_, cb)
    lib.callback('aura_police:server:getDispatchHistory', false, function(calls)
        cb({ success = true, calls = calls or {} })
    end)
end)

RegisterNUICallback('policeGetStaff', function(_, cb)
    lib.callback('aura_hub:server:policeGetStaff', false, function(success, data)
        cb({ success = success, data = data })
    end)
end)

RegisterNUICallback('policeHireOfficer', function(data, cb)
    lib.callback('aura_hub:server:policeHireOfficer', false, function(success, message)
        cb({ success = success, message = message })
    end, data.targetSrc)
end)

RegisterNUICallback('policeSetOfficerGrade', function(data, cb)
    lib.callback('aura_hub:server:policeSetOfficerGrade', false, function(success, message)
        cb({ success = success, message = message })
    end, { targetCharId = data.targetCharId, newGrade = data.newGrade })
end)

RegisterNUICallback('policeFireOfficer', function(data, cb)
    lib.callback('aura_hub:server:policeFireOfficer', false, function(success, message)
        cb({ success = success, message = message })
    end, data.targetCharId)
end)

RegisterNUICallback('setGpsWaypoint', function(data, cb)
    if data and data.x and data.y then
        SetNewWaypoint(tonumber(data.x) + 0.0, tonumber(data.y) + 0.0)
        lib.notify({
            title = 'GPS Táctico Policial',
            description = 'Ruta fijada hacia la ubicación de la llamada de emergencia 911.',
            type = 'success'
        })
        cb({ success = true })
    else
        cb({ success = false, message = "Coordenadas inválidas" })
    end
end)

RegisterNUICallback('policeGetRadioOverview', function(_, cb)
    lib.callback('aura_police:server:getRadioOverview', false, function(result)
        cb(result or { success = false })
    end)
end)

RegisterNUICallback('policeJoinRadio', function(data, cb)
    lib.callback('aura_police:server:joinRadioChannel', false, function(result)
        cb(result or { success = false })
    end, data.channelId)
end)

RegisterNUICallback('policeLeaveRadio', function(_, cb)
    lib.callback('aura_police:server:leaveRadioChannel', false, function(result)
        cb(result or { success = false })
    end)
end)

RegisterNUICallback('policeSetRadioColor', function(data, cb)
    lib.callback('aura_police:server:setChannelColor', false, function(result)
        cb(result or { success = false })
    end, data)
end)

-- ============================================================================
-- NUI CALLBACKS: TERMINAL DARK WEB (BANDAS Y CÁRTELES)
-- ============================================================================

RegisterNUICallback('darkWebGetData', function(_, cb)
    lib.callback('aura_gangs:server:getDarkWebData', false, function(data)
        cb({ success = data ~= nil, data = data })
    end)
end)

RegisterNUICallback('darkWebHire', function(data, cb)
    lib.callback('aura_gangs:server:hireMember', false, function(success, message)
        cb({ success = success, message = message })
    end, data.targetSrc)
end)

RegisterNUICallback('darkWebFire', function(data, cb)
    lib.callback('aura_gangs:server:fireMember', false, function(success, message)
        cb({ success = success, message = message })
    end, data.charId)
end)

RegisterNUICallback('darkWebSetGrade', function(data, cb)
    lib.callback('aura_gangs:server:setMemberGrade', false, function(success, message)
        cb({ success = success, message = message })
    end, data.charId, data.newGrade)
end)

RegisterNUICallback('darkWebDeposit', function(data, cb)
    lib.callback('aura_gangs:server:depositOffshore', false, function(success, message, newBalance)
        cb({ success = success, message = message, newBalance = newBalance })
    end, data.amount, data.account)
end)

RegisterNUICallback('darkWebWithdraw', function(data, cb)
    lib.callback('aura_gangs:server:withdrawOffshore', false, function(success, message, newBalance)
        cb({ success = success, message = message, newBalance = newBalance })
    end, data.amount)
end)

-- Callbacks para Radio Clandestina (Dark Web Gang Radio)
RegisterNUICallback('gangGetRadioOverview', function(_, cb)
    lib.callback('aura_gangs:server:getRadioOverview', false, function(res)
        cb(res or { success = false, message = "Error al conectar con la red de radio." })
    end)
end)

RegisterNUICallback('gangJoinRadio', function(data, cb)
    lib.callback('aura_gangs:server:joinRadioChannel', false, function(res)
        cb(res or { success = false, message = "Error al unirse a la emisora." })
    end, data.channelIndex)
end)

RegisterNUICallback('gangLeaveRadio', function(_, cb)
    lib.callback('aura_gangs:server:leaveRadioChannel', false, function(res)
        cb(res or { success = false, message = "Error al desconectar de la emisora." })
    end)
end)

RegisterNUICallback('gangSetRadioColor', function(data, cb)
    lib.callback('aura_gangs:server:setRadioColor', false, function(res)
        cb(res or { success = false, message = "Error al actualizar color de la emisora." })
    end, data.channelIndex, data.hexColor, data.blipColor)
end)

-- Limpieza de memoria gráfica al detener el recurso
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        if currentHeadshotHandle then
            UnregisterPedheadshot(currentHeadshotHandle)
            currentHeadshotHandle = nil
        end
    end
end)
