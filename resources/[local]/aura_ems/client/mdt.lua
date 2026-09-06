-- ============================================================================
-- AURA EMS: CLIENT MEDICAL TABLET & ENCRYPTED RADIO
-- MDT NUI Bridge, Tablet Prop Animation & pma-voice Radio Connection
-- ============================================================================

local isMdtOpen = false
local tabletProp = 0
local activeMedicBlips = {}

local function AttachTabletProp()
    if DoesEntityExist(tabletProp) then return end
    local ped = PlayerPedId()
    local model = joaat('prop_cs_tablet')

    RequestModel(model)
    local timer = GetGameTimer()
    while not HasModelLoaded(model) do
        Wait(10)
        if GetGameTimer() - timer > 2000 then break end
    end
    if not HasModelLoaded(model) then return end

    local animDict = "amb@world_human_seat_wall_tablet@female@base"
    RequestAnimDict(animDict)
    timer = GetGameTimer()
    while not HasAnimDictLoaded(animDict) do
        Wait(10)
        if GetGameTimer() - timer > 2000 then break end
    end

    local coords = GetEntityCoords(ped)
    tabletProp = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)
    if DoesEntityExist(tabletProp) then
        local boneIndex = GetPedBoneIndex(ped, 60309)
        AttachEntityToEntity(tabletProp, ped, boneIndex, 0.03, 0.002, -0.0, 10.0, 160.0, 0.0, true, false, false, false, 2, true)
        SetModelAsNoLongerNeeded(model)
        if HasAnimDictLoaded(animDict) then
            TaskPlayAnim(ped, animDict, "base", 2.0, 2.0, -1, 49, 0, false, false, false)
        end
    end
end

local function RemoveTabletProp()
    if DoesEntityExist(tabletProp) then
        DetachEntity(tabletProp, true, false)
        DeleteEntity(tabletProp)
        tabletProp = 0
    end
    local ped = PlayerPedId()
    if DoesEntityExist(ped) then
        StopAnimTask(ped, "amb@world_human_seat_wall_tablet@female@base", "base", 3.0)
    end
end

CreateThread(function()
    while true do
        if isMdtOpen then
            DisableControlAction(0, 1, true)   -- LookLeftRight
            DisableControlAction(0, 2, true)   -- LookUpDown
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim
            DisableControlAction(0, 30, true)  -- MoveLR
            DisableControlAction(0, 31, true)  -- MoveUD
            DisableControlAction(0, 32, true)  -- MoveUpOnly (W)
            DisableControlAction(0, 33, true)  -- MoveDownOnly (S)
            DisableControlAction(0, 34, true)  -- MoveLeftOnly (A)
            DisableControlAction(0, 35, true)  -- MoveRightOnly (D)
            DisableControlAction(0, 21, true)  -- Sprint
            DisableControlAction(0, 22, true)  -- Jump
            DisableControlAction(0, 23, true)  -- Enter vehicle
            DisableControlAction(0, 44, true)  -- Cover
            DisableControlAction(0, 140, true) -- MeleeAttackLight
            DisableControlAction(0, 141, true) -- MeleeAttackHeavy
            DisableControlAction(0, 142, true) -- MeleeAttackAlternate
            DisableControlAction(0, 257, true) -- Attack 2
            DisableControlAction(0, 263, true) -- Melee 1
            DisableControlAction(0, 264, true) -- Melee 2
            Wait(0)
        else
            Wait(300)
        end
    end
end)

local function OpenEmsMdt()
    local pState = LocalPlayer.state
    if pState.job ~= Config.JobName then
        lib.notify({ title = 'MDT Médico', description = 'Acceso denegado: Reservado a personal del cuerpo médico.', type = 'error' })
        return
    end

    local hasTablet = false
    if exports.ox_inventory then
        hasTablet = (exports.ox_inventory:Search('count', 'tablet') or 0) > 0
    else
        hasTablet = true
    end

    if not hasTablet then
        lib.notify({ title = 'Tablet', description = 'No dispones de una Tablet en tu inventario.', type = 'error' })
        return
    end

    isMdtOpen = true
    AttachTabletProp()
    SetNuiFocus(true, true)

    lib.callback('aura_ems:server:getMdtOverview', false, function(success, overviewData)
        SendNUIMessage({
            action = 'openEmsMdt',
            overview = success and overviewData or {},
            mySrc = GetPlayerServerId(PlayerId())
        })
    end)
end
exports('OpenEmsMdt', OpenEmsMdt)

local function CloseEmsMdt()
    if not isMdtOpen then return end
    isMdtOpen = false
    RemoveTabletProp()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeEmsMdt' })
end
exports('CloseEmsMdt', CloseEmsMdt)

RegisterCommand('mdt_ems', OpenEmsMdt, false)
RegisterCommand('tablet_ems', OpenEmsMdt, false)

-- ============================================================================
-- EVENTOS DE SINCRONIZACIÓN DE RADIO Y GPS TÁCTICO
-- ============================================================================

RegisterNetEvent('aura_ems:client:syncRadioOverview', function(overview)
    if isMdtOpen then
        SendNUIMessage({
            action = 'syncRadioOverview',
            data = overview
        })
    end
end)

RegisterNetEvent('aura_ems:client:syncRadioChannel', function(freq, label, hexColor)
    local frequency = tonumber(freq) or 0
    if exports['pma-voice'] then
        pcall(function()
            if frequency > 0 then
                exports['pma-voice']:setVoiceProperty('radioEnabled', true)
                exports['pma-voice']:setRadioChannel(frequency)
            else
                exports['pma-voice']:setRadioChannel(0)
            end
        end)
    end

    SendNUIMessage({
        action = 'syncRadioChannel',
        frequency = frequency,
        label = label or "Desconectado",
        color = hexColor or "#40E0D0"
    })
end)

RegisterNetEvent('aura_ems:client:syncTacticalBlips', function(medics)
    local mySrc = GetPlayerServerId(PlayerId())
    local currentServerIds = {}

    for _, m in ipairs(medics or {}) do
        if m.src ~= mySrc then
            currentServerIds[m.src] = true
            local blip = activeMedicBlips[m.src]

            if not blip or not DoesBlipExist(blip) then
                blip = AddBlipForCoord(m.coords.x, m.coords.y, m.coords.z)
                SetBlipSprite(blip, 153) -- Cruz médica
                SetBlipScale(blip, 0.8)
                SetBlipColour(blip, tonumber(m.blipColor) or 1)
                SetBlipAsShortRange(blip, false)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(string.format("[EMS] %s (C#%d)", m.name, m.channelIndex or 1))
                EndTextCommandSetBlipName(blip)
                activeMedicBlips[m.src] = blip
            else
                SetBlipCoords(blip, m.coords.x, m.coords.y, m.coords.z)
                SetBlipColour(blip, tonumber(m.blipColor) or 1)
                SetBlipRotation(blip, math.ceil(m.heading or 0))
            end
        end
    end

    for s, blip in pairs(activeMedicBlips) do
        if not currentServerIds[s] then
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
            activeMedicBlips[s] = nil
        end
    end
end)

-- ============================================================================
-- NUI CALLBACKS: MDT & ENCRYPTED RADIO (20 CANALES)
-- ============================================================================

RegisterNUICallback('closeEmsMdt', function(_, cb)
    CloseEmsMdt()
    cb(true)
end)

RegisterNUICallback('getEmsMdtOverview', function(_, cb)
    lib.callback('aura_ems:server:getMdtOverview', false, function(success, data)
        cb({ success = success, data = data })
    end)
end)

RegisterNUICallback('searchMedicalRecords', function(data, cb)
    lib.callback('aura_ems:server:searchMedicalRecords', false, function(success, results)
        cb({ success = success, results = results or {} })
    end, data.query)
end)

RegisterNUICallback('createMedicalRecord', function(data, cb)
    lib.callback('aura_ems:server:createMedicalRecord', false, function(success, message)
        cb({ success = success, message = message })
    end, data)
end)

RegisterNUICallback('getEmsStaff', function(_, cb)
    lib.callback('aura_ems:server:getStaff', false, function(success, staff)
        cb({ success = success, staff = staff or {} })
    end)
end)

RegisterNUICallback('hireEmsStaff', function(data, cb)
    lib.callback('aura_ems:server:hireStaff', false, function(success, message)
        cb({ success = success, message = message })
    end, data.targetSrc)
end)

RegisterNUICallback('fireEmsStaff', function(data, cb)
    lib.callback('aura_ems:server:fireStaff', false, function(success, message)
        cb({ success = success, message = message })
    end, data.targetCharId)
end)

RegisterNUICallback('setEmsStaffGrade', function(data, cb)
    lib.callback('aura_ems:server:setStaffGrade', false, function(success, message)
        cb({ success = success, message = message })
    end, { targetCharId = data.targetCharId, newGrade = data.newGrade })
end)

-- Callbacks para la Radio Táctica Médica (#01 al #20)
RegisterNUICallback('getEmsRadioOverview', function(_, cb)
    lib.callback('aura_ems:server:getRadioOverview', false, function(data)
        cb(data or { channels = {}, activeChannelIndex = nil })
    end)
end)

RegisterNUICallback('joinEmsRadio', function(data, cb)
    lib.callback('aura_ems:server:joinRadioChannel', false, function(result)
        cb(result or { success = false, message = "Error al conectar con la radio médica." })
    end, data.channelIndex)
end)

RegisterNUICallback('leaveEmsRadio', function(_, cb)
    lib.callback('aura_ems:server:disconnectRadio', false, function(result)
        cb(result or { success = false, message = "Error al desconectar de la radio." })
    end)
end)

RegisterNUICallback('setEmsRadioColor', function(data, cb)
    lib.callback('aura_ems:server:setRadioColor', false, function(result)
        cb(result or { success = false, message = "Error al actualizar color de radio." })
    end, data.channelIndex, data.hexColor, data.blipColor)
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        RemoveTabletProp()
        for _, blip in pairs(activeMedicBlips) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end
        activeMedicBlips = {}
    end
end)
