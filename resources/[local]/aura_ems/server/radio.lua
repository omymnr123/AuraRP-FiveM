-- ============================================================================
-- AURA EMS: SERVER RADIO-MÉDICA & LIVE GPS CONTROLLER (20 CANALES TÁCTICOS)
-- Encrypted Medical Channels (#01 al #20), PMA-Voice Sync, Colors & GPS Blips
-- ============================================================================

local EmsRadioChannels = {}
local EmsRadioMembers = {} -- [src] = { channelIndex = 1, frequency = 10.1, name = 'Dr. ...', grade = 2, gradeLabel = 'Médico Titular', badge = '1' }

local function IsEmsOnDuty(src)
    local pState = Player(src).state
    return pState and pState.job == Config.JobName and pState.job_duty == true
end

local function GetMedicInfo(src)
    local pState = Player(src).state
    local name = "Médico"
    local grade = 0
    local gradeLabel = "Enfermero"
    local badge = tostring(src)

    local char = nil
    if GetResourceState('aura_multichar') == 'started' then
        pcall(function()
            char = exports.aura_multichar:GetActiveCharacter(src)
        end)
    end

    if char then
        name = string.format("Dr. %s %s", char.firstname or "", char.lastname or "")
        grade = tonumber(char.job_grade) or (pState and tonumber(pState.job_grade)) or 0
        gradeLabel = char.job_grade_label or (pState and pState.grade_label) or (pState and pState.job_grade_label) or "Médico"
        badge = char.badge or (pState and pState.badge) or tostring(src)
    elseif pState then
        name = pState.char_name and ("Dr. " .. pState.char_name) or ("Médico #" .. src)
        grade = tonumber(pState.job_grade) or 0
        gradeLabel = pState.grade_label or pState.job_grade_label or "Médico"
        badge = pState.badge or tostring(src)
    else
        name = "Médico #" .. src
    end

    return {
        src = src,
        name = name,
        grade = grade,
        gradeLabel = gradeLabel,
        badge = badge
    }
end

-- ============================================================================
-- 1. CARGA INICIAL Y ENCRIPTACIÓN PMA-VOICE
-- ============================================================================

local function RegisterEncryptedRadioChecks()
    if not exports['pma-voice'] then return end

    for _, ch in ipairs(EmsRadioChannels) do
        local f = tonumber(ch.frequency)
        if f and f > 0 then
            pcall(function()
                exports['pma-voice']:addChannelCheck(f, function(source)
                    return IsEmsOnDuty(source)
                end)
            end)
        end
    end
end

local function LoadEmsChannels()
    local rows = MySQL.query.await('SELECT * FROM `aura_ems_radio_channels` ORDER BY `channel_index` ASC')
    EmsRadioChannels = {}

    if rows and #rows > 0 then
        for _, r in ipairs(rows) do
            table.insert(EmsRadioChannels, {
                id = tonumber(r.channel_index),
                channelIndex = tonumber(r.channel_index),
                label = r.label,
                color = r.color or '#40E0D0',
                blipColor = tonumber(r.blip_color) or 1,
                frequency = tonumber(r.frequency) or (10.0 + (tonumber(r.channel_index) * 0.1)),
                isEncrypted = (r.is_encrypted == 1 or r.is_encrypted == true or r.is_encrypted == nil),
                members = {}
            })
        end
    else
        -- Fallback a Config.Radio.defaultChannels si la base de datos está vacía
        for _, def in ipairs(Config.Radio.defaultChannels) do
            table.insert(EmsRadioChannels, {
                id = def.index,
                channelIndex = def.index,
                label = def.label,
                color = def.color or '#40E0D0',
                blipColor = def.blipColor or 1,
                frequency = def.frequency,
                isEncrypted = true,
                members = {}
            })
        end
    end

    RegisterEncryptedRadioChecks()
end

CreateThread(function()
    Wait(1000)
    LoadEmsChannels()
end)

local function SyncRadioMembersToAllEms()
    local channelsOverview = {}
    for _, ch in ipairs(EmsRadioChannels) do
        local memberList = {}
        for src, data in pairs(EmsRadioMembers) do
            if data.channelIndex == ch.channelIndex and IsEmsOnDuty(src) then
                table.insert(memberList, {
                    src = src,
                    name = data.name,
                    grade = data.grade,
                    gradeLabel = data.gradeLabel,
                    badge = data.badge
                })
            end
        end

        table.insert(channelsOverview, {
            channelIndex = ch.channelIndex,
            label = ch.label,
            color = ch.color,
            blipColor = ch.blipColor,
            frequency = ch.frequency,
            isEncrypted = ch.isEncrypted,
            members = memberList
        })
    end

    for _, pid in ipairs(GetPlayers()) do
        local pSrc = tonumber(pid)
        if pSrc and IsEmsOnDuty(pSrc) then
            local activeChannelIndex = EmsRadioMembers[pSrc] and EmsRadioMembers[pSrc].channelIndex or nil
            TriggerClientEvent('aura_ems:client:syncRadioOverview', pSrc, {
                channels = channelsOverview,
                activeChannelIndex = activeChannelIndex
            })
        end
    end
end

-- ============================================================================
-- 2. CALLBACKS Y GESTIÓN DE EMISORAS
-- ============================================================================

lib.callback.register('aura_ems:server:getRadioOverview', function(source)
    local src = source
    local channelsOverview = {}

    for _, ch in ipairs(EmsRadioChannels) do
        local memberList = {}
        for s, data in pairs(EmsRadioMembers) do
            if data.channelIndex == ch.channelIndex and IsEmsOnDuty(s) then
                table.insert(memberList, {
                    src = s,
                    name = data.name,
                    grade = data.grade,
                    gradeLabel = data.gradeLabel,
                    badge = data.badge
                })
            end
        end

        table.insert(channelsOverview, {
            channelIndex = ch.channelIndex,
            label = ch.label,
            color = ch.color,
            blipColor = ch.blipColor,
            frequency = ch.frequency,
            isEncrypted = ch.isEncrypted,
            members = memberList
        })
    end

    local activeChannelIndex = EmsRadioMembers[src] and EmsRadioMembers[src].channelIndex or nil
    return {
        channels = channelsOverview,
        activeChannelIndex = activeChannelIndex
    }
end)

lib.callback.register('aura_ems:server:joinRadioChannel', function(source, channelIndex)
    local src = source
    local chIdx = tonumber(channelIndex)

    if not IsEmsOnDuty(src) then
        return { success = false, message = "Debes estar de servicio como personal médico para entrar a la radio." }
    end

    local targetChannel = nil
    for _, ch in ipairs(EmsRadioChannels) do
        if ch.channelIndex == chIdx then
            targetChannel = ch
            break
        end
    end

    if not targetChannel then
        return { success = false, message = "Canal médico no encontrado." }
    end

    -- Validar posesión de transmisor de radio
    local hasRadio = false
    if exports.ox_inventory then
        for _, item in ipairs(Config.Radio.requiredItems or { 'radio', 'radio_satelite' }) do
            if (exports.ox_inventory:Search(src, 'count', item) or 0) > 0 then
                hasRadio = true
                break
            end
        end
    else
        hasRadio = true
    end

    if not hasRadio then
        return { success = false, message = "No dispones de un dispositivo de radio o radio satelital en tu inventario." }
    end

    local info = GetMedicInfo(src)
    EmsRadioMembers[src] = {
        channelIndex = chIdx,
        frequency = targetChannel.frequency,
        name = info.name,
        grade = info.grade,
        gradeLabel = info.gradeLabel,
        badge = info.badge
    }

    local pState = Player(src).state
    if pState then
        pState:set('ems_radio_channel', chIdx, true)
        pState:set('ems_radio_freq', targetChannel.frequency, true)
        pState:set('ems_radio_color', targetChannel.color, true)
        pState:set('ems_radio_blip_color', targetChannel.blipColor, true)
    end

    -- Sintonizar frecuencia en pma-voice
    if exports['pma-voice'] then
        pcall(function()
            exports['pma-voice']:setRadioChannel(src, targetChannel.frequency)
        end)
    end

    TriggerClientEvent('aura_ems:client:syncRadioChannel', src, targetChannel.frequency, targetChannel.label, targetChannel.color)
    SyncRadioMembersToAllEms()

    return {
        success = true,
        message = string.format("Sintonizado en %s (%.1f MHz).", targetChannel.label, targetChannel.frequency)
    }
end)

lib.callback.register('aura_ems:server:disconnectRadio', function(source)
    local src = source
    if EmsRadioMembers[src] then
        EmsRadioMembers[src] = nil
    end

    local pState = Player(src).state
    if pState then
        pState:set('ems_radio_channel', nil, true)
        pState:set('ems_radio_freq', 0, true)
        pState:set('ems_radio_color', nil, true)
        pState:set('ems_radio_blip_color', nil, true)
    end

    if exports['pma-voice'] then
        pcall(function()
            exports['pma-voice']:setRadioChannel(src, 0)
        end)
    end

    TriggerClientEvent('aura_ems:client:syncRadioChannel', src, 0, "Desconectado", "#40E0D0")
    SyncRadioMembersToAllEms()

    return { success = true, message = "Te has desconectado de la red de radio médica." }
end)

lib.callback.register('aura_ems:server:setRadioColor', function(source, channelIndex, hexColor, blipColor)
    local src = source
    local chIdx = tonumber(channelIndex)
    local bColor = tonumber(blipColor) or 1

    if not IsEmsOnDuty(src) then
        return { success = false, message = "Acceso denegado: No estás de servicio." }
    end

    MySQL.update.await('UPDATE `aura_ems_radio_channels` SET `color` = ?, `blip_color` = ? WHERE `channel_index` = ?', {
        hexColor, bColor, chIdx
    })

    for _, ch in ipairs(EmsRadioChannels) do
        if ch.channelIndex == chIdx then
            ch.color = hexColor
            ch.blipColor = bColor
            break
        end
    end

    for memSrc, memData in pairs(EmsRadioMembers) do
        if memData.channelIndex == chIdx then
            local pState = Player(memSrc).state
            if pState then
                pState:set('ems_radio_color', hexColor, true)
                pState:set('ems_radio_blip_color', bColor, true)
            end
        end
    end

    SyncRadioMembersToAllEms()
    return { success = true, message = "Color de canal y blip táctico actualizado." }
end)

-- ============================================================================
-- 3. BUCLE DE SINCRONIZACIÓN GPS TÁCTICO DE MÉDICOS EN RADIO
-- ============================================================================

CreateThread(function()
    while true do
        Wait(2500)
        local activeBlipsPayload = {}

        for src, memData in pairs(EmsRadioMembers) do
            if IsEmsOnDuty(src) then
                local ped = GetPlayerPed(src)
                if DoesEntityExist(ped) then
                    local coords = GetEntityCoords(ped)
                    local heading = GetEntityHeading(ped)
                    local pState = Player(src).state
                    local blipCol = (pState and pState.ems_radio_blip_color) or 1
                    local hexCol = (pState and pState.ems_radio_color) or "#40E0D0"

                    table.insert(activeBlipsPayload, {
                        src = src,
                        name = memData.name,
                        gradeLabel = memData.gradeLabel,
                        badge = memData.badge,
                        channelIndex = memData.channelIndex,
                        coords = coords,
                        heading = heading,
                        blipColor = blipCol,
                        hexColor = hexCol
                    })
                end
            end
        end

        if #activeBlipsPayload > 0 then
            for _, pid in ipairs(GetPlayers()) do
                local pSrc = tonumber(pid)
                if pSrc and IsEmsOnDuty(pSrc) then
                    TriggerClientEvent('aura_ems:client:syncTacticalBlips', pSrc, activeBlipsPayload)
                end
            end
        end
    end
end)

-- Limpieza al desconectar o salir de servicio
AddEventHandler('playerDropped', function()
    local src = source
    if EmsRadioMembers[src] then
        EmsRadioMembers[src] = nil
        SyncRadioMembersToAllEms()
    end
end)

RegisterNetEvent('aura_jobs:server:onDutyChange', function(job, isDuty)
    local src = source
    if job == Config.JobName and not isDuty and EmsRadioMembers[src] then
        EmsRadioMembers[src] = nil
        local pState = Player(src).state
        if pState then
            pState:set('ems_radio_channel', nil, true)
            pState:set('ems_radio_freq', 0, true)
            pState:set('ems_radio_color', nil, true)
            pState:set('ems_radio_blip_color', nil, true)
        end
        if exports['pma-voice'] then
            pcall(function()
                exports['pma-voice']:setRadioChannel(src, 0)
            end)
        end
        TriggerClientEvent('aura_ems:client:syncRadioChannel', src, 0, "Desconectado", "#40E0D0")
        SyncRadioMembersToAllEms()
    end
end)
