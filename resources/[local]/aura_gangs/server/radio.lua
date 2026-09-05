-- ============================================================================
-- AURA GANGS: SERVER RADIO-CLANDESTINA & LIVE GPS TACTICAL BLIPS
-- Private Encrypted Channels, PMA-Voice Security & Gang Communications
-- ============================================================================

local GangRadioChannels = {} -- [gangName] = { [1..20] = { channelIndex, label, color, blipColor, frequency, isEncrypted, members = {} } }
local GangRadioMembers = {}  -- [source] = { gang, channelIndex, frequency, name, grade, gradeLabel }

-- ============================================================================
-- 0. HELPERS DE MIEMBROS Y ORGANIZACIONES
-- ============================================================================

local function GetPlayerCurrentGang(src)
    local jobData = exports.aura_jobs:GetJob(src)
    if not jobData then return nil, nil, nil end

    local jobName = jobData.name
    local gangConfig = Config.Gangs[jobName]

    if not gangConfig then
        local jobConfig = exports.aura_jobs:GetJobConfig(jobName)
        if jobConfig and jobConfig.isGang then
            gangConfig = {
                label = jobConfig.label,
                society = jobName,
                color = '#40E0D0',
                tag = string.upper(string.sub(jobName, 1, 4))
            }
        end
    end

    return jobName, gangConfig, jobData
end

local function GetMemberInfo(src)
    local char = exports.aura_multichar:GetActiveCharacter(src)
    local pState = Player(src).state
    local name = "Desconocido"
    local grade = 0
    local gradeLabel = "Miembro"

    if char then
        name = string.format("%s %s", char.firstname or "", char.lastname or "")
        grade = tonumber(char.job_grade) or (pState and tonumber(pState.job_grade)) or 0
        gradeLabel = char.job_grade_label or (pState and pState.grade_label) or "Miembro"
    elseif pState then
        name = pState.char_name or GetPlayerName(src) or "Miembro"
        grade = tonumber(pState.job_grade) or 0
        gradeLabel = pState.grade_label or "Miembro"
    else
        name = GetPlayerName(src) or "Miembro"
    end

    return {
        src = src,
        name = name,
        grade = grade,
        gradeLabel = gradeLabel
    }
end

-- ============================================================================
-- 1. CARGA DE CANALES Y ENCRIPTACIÓN PMA-VOICE
-- ============================================================================

local function RegisterEncryptedGangChecks()
    if not exports['pma-voice'] then return end

    for gangName, channels in pairs(GangRadioChannels) do
        for _, ch in ipairs(channels) do
            local f = tonumber(ch.frequency)
            local g = gangName
            if f and f > 0 then
                pcall(function()
                    exports['pma-voice']:addChannelCheck(f, function(source)
                        local pGang = GetPlayerCurrentGang(source)
                        return pGang == g
                    end)
                end)
            end
        end
    end
end

local function LoadGangChannels()
    local rows = MySQL.query.await('SELECT * FROM `aura_gang_radio_channels` ORDER BY `gang` ASC, `channel_index` ASC')
    GangRadioChannels = {}

    if rows and #rows > 0 then
        for _, r in ipairs(rows) do
            local g = r.gang
            if not GangRadioChannels[g] then
                GangRadioChannels[g] = {}
            end

            table.insert(GangRadioChannels[g], {
                id = string.format("%s_%d", g, r.channel_index),
                gang = g,
                channelIndex = tonumber(r.channel_index),
                label = r.label,
                color = r.color or '#00f2fe',
                blipColor = tonumber(r.blip_color) or 38,
                frequency = tonumber(r.frequency) or 201.0,
                isEncrypted = (r.is_encrypted == 1 or r.is_encrypted == true),
                members = {}
            })
        end
    end

    RegisterEncryptedGangChecks()
end

CreateThread(function()
    Wait(1200)
    LoadGangChannels()
end)

local function SyncRadioMembersToGang(targetGang)
    if not targetGang or not GangRadioChannels[targetGang] then return end

    local overview = {}
    for _, ch in ipairs(GangRadioChannels[targetGang]) do
        local memberList = {}
        for src, data in pairs(GangRadioMembers) do
            if data.gang == targetGang and data.channelIndex == ch.channelIndex then
                table.insert(memberList, {
                    src = src,
                    name = data.name,
                    grade = data.grade,
                    gradeLabel = data.gradeLabel
                })
            end
        end

        table.insert(overview, {
            id = ch.id,
            gang = ch.gang,
            channelIndex = ch.channelIndex,
            channel_index = ch.channelIndex,
            label = ch.label,
            color = ch.color,
            color_hex = ch.color,
            blipColor = ch.blipColor,
            frequency = ch.frequency,
            isEncrypted = ch.isEncrypted,
            members = memberList
        })
    end

    for _, pid in ipairs(GetPlayers()) do
        local pSrc = tonumber(pid)
        if pSrc then
            local pGang = GetPlayerCurrentGang(pSrc)
            if pGang == targetGang then
                TriggerClientEvent('aura_gangs:client:syncRadioOverview', pSrc, overview)
            end
        end
    end
end

-- ============================================================================
-- 2. CALLBACKS Y GESTIÓN DE EMISORAS
-- ============================================================================

lib.callback.register('aura_gangs:server:getRadioOverview', function(source)
    local src = source
    local gangName, gangConfig, jobData = GetPlayerCurrentGang(src)

    if not gangConfig or not jobData then
        return { success = false, message = "No perteneces a ninguna organización o banda." }
    end

    if not GangRadioChannels[gangName] then
        LoadGangChannels()
    end

    local channels = GangRadioChannels[gangName] or {}
    local currentMem = GangRadioMembers[src]
    local activeChannelIndex = currentMem and currentMem.channelIndex or nil

    local overview = {}
    for _, ch in ipairs(channels) do
        local memberList = {}
        for memSrc, data in pairs(GangRadioMembers) do
            if data.gang == gangName and data.channelIndex == ch.channelIndex then
                table.insert(memberList, {
                    src = memSrc,
                    name = data.name,
                    grade = data.grade,
                    gradeLabel = data.gradeLabel
                })
            end
        end

        table.insert(overview, {
            id = ch.id,
            gang = ch.gang,
            channelIndex = ch.channelIndex,
            channel_index = ch.channelIndex,
            label = ch.label,
            color = ch.color,
            color_hex = ch.color,
            blipColor = ch.blipColor,
            frequency = ch.frequency,
            isEncrypted = ch.isEncrypted,
            members = memberList
        })
    end

    return {
        success = true,
        gang = gangName,
        gangLabel = gangConfig.label,
        channels = overview,
        activeChannelIndex = activeChannelIndex,
        activeChannelId = activeChannelIndex
    }
end)

lib.callback.register('aura_gangs:server:joinRadioChannel', function(source, channelIndex)
    local src = source
    local gangName, gangConfig, jobData = GetPlayerCurrentGang(src)

    if not gangConfig or not jobData then
        return { success = false, message = "No perteneces a ninguna banda registrada." }
    end

    local chIdx = tonumber(channelIndex)
    if not chIdx or chIdx < 1 or chIdx > 20 then
        return { success = false, message = "Emisora no válida." }
    end

    local channels = GangRadioChannels[gangName] or {}
    local targetChannel = nil
    for _, ch in ipairs(channels) do
        if ch.channelIndex == chIdx then
            targetChannel = ch
            break
        end
    end

    if not targetChannel then
        return { success = false, message = "Emisora no encontrada en la red de la banda." }
    end

    -- Validar tenencia de hardware de radio (Estándar o Satelital)
    local standardCount = exports.ox_inventory:Search(src, 'count', 'radio') or 0
    local satelliteCount = exports.ox_inventory:Search(src, 'count', 'radio_satelite') or 0
    if (standardCount + satelliteCount) <= 0 then
        return { success = false, message = "No dispones de un dispositivo de radio o radio satelital en tu inventario." }
    end

    local memInfo = GetMemberInfo(src)
    GangRadioMembers[src] = {
        gang = gangName,
        channelIndex = chIdx,
        frequency = targetChannel.frequency,
        name = memInfo.name,
        grade = memInfo.grade,
        gradeLabel = memInfo.gradeLabel
    }

    local pState = Player(src).state
    if pState then
        pState:set('gang_radio_channel', chIdx, true)
        pState:set('gang_radio_freq', targetChannel.frequency, true)
        pState:set('gang_radio_color', targetChannel.color, true)
        pState:set('gang_radio_blip_color', targetChannel.blipColor, true)
    end

    TriggerClientEvent('aura_gangs:client:syncRadioChannel', src, targetChannel.frequency, targetChannel.label, targetChannel.color)
    SyncRadioMembersToGang(gangName)

    return {
        success = true,
        message = string.format("Conectado a %s (%.1f MHz).", targetChannel.label, targetChannel.frequency),
        frequency = targetChannel.frequency
    }
end)

lib.callback.register('aura_gangs:server:leaveRadioChannel', function(source)
    local src = source
    local currentMem = GangRadioMembers[src]
    if not currentMem then
        return { success = true, message = "Ya estás desconectado de la radio." }
    end

    local gangName = currentMem.gang
    GangRadioMembers[src] = nil

    local pState = Player(src).state
    if pState then
        pState:set('gang_radio_channel', nil, true)
        pState:set('gang_radio_freq', 0, true)
        pState:set('gang_radio_color', nil, true)
        pState:set('gang_radio_blip_color', nil, true)
    end

    TriggerClientEvent('aura_gangs:client:syncRadioChannel', src, 0, "Desconectado", "#00f2fe")
    SyncRadioMembersToGang(gangName)

    return { success = true, message = "Desconectado de la emisora clandestina." }
end)

lib.callback.register('aura_gangs:server:setRadioColor', function(source, channelIndex, hexColor, blipColor)
    local src = source
    local gangName, gangConfig, jobData = GetPlayerCurrentGang(src)

    if not gangConfig or not jobData then
        return { success = false, message = "No tienes permiso para modificar los colores de la banda." }
    end

    local chIdx = tonumber(channelIndex)
    if not chIdx or chIdx < 1 or chIdx > 20 then
        return { success = false, message = "Emisora no válida." }
    end

    MySQL.update.await('UPDATE `aura_gang_radio_channels` SET `color` = ?, `blip_color` = ? WHERE `gang` = ? AND `channel_index` = ?', {
        hexColor, blipColor, gangName, chIdx
    })

    local channels = GangRadioChannels[gangName] or {}
    for _, ch in ipairs(channels) do
        if ch.channelIndex == chIdx then
            ch.color = hexColor
            ch.blipColor = blipColor
            break
        end
    end

    -- Actualizar state bags de los miembros conectados en esa emisora
    for memSrc, memData in pairs(GangRadioMembers) do
        if memData.gang == gangName and memData.channelIndex == chIdx then
            local pState = Player(memSrc).state
            if pState then
                pState:set('gang_radio_color', hexColor, true)
                pState:set('gang_radio_blip_color', blipColor, true)
            end
        end
    end

    SyncRadioMembersToGang(gangName)

    return { success = true, message = "Color de la emisora actualizado con éxito." }
end)

-- ============================================================================
-- 3. BUCLE DE SINCRONIZACIÓN GPS TÁCTICO DE MIEMBROS DE BANDA EN RADIO
-- ============================================================================

CreateThread(function()
    while true do
        Wait(1500)

        -- Agrupar miembros conectados a radio por banda
        local gangCops = {} -- [gangName] = { list of members }

        for src, data in pairs(GangRadioMembers) do
            local ped = GetPlayerPed(src)
            if DoesEntityExist(ped) then
                local coords = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)
                local inVeh = IsPedInAnyVehicle(ped, false)
                local chInfo = nil

                local channels = GangRadioChannels[data.gang] or {}
                for _, ch in ipairs(channels) do
                    if ch.channelIndex == data.channelIndex then
                        chInfo = ch
                        break
                    end
                end

                if not gangCops[data.gang] then
                    gangCops[data.gang] = {}
                end

                table.insert(gangCops[data.gang], {
                    src = src,
                    name = data.name,
                    gradeLabel = data.gradeLabel,
                    coords = { x = coords.x, y = coords.y, z = coords.z },
                    heading = heading,
                    inVehicle = inVeh,
                    channelIndex = data.channelIndex,
                    channelLabel = chInfo and chInfo.label or string.format("Emisora #%02d", data.channelIndex),
                    blipColor = chInfo and chInfo.blipColor or 38,
                    hexColor = chInfo and chInfo.color or "#00f2fe"
                })
            end
        end

        for gangName, membersList in pairs(gangCops) do
            for _, mem in ipairs(membersList) do
                TriggerClientEvent('aura_gangs:client:syncGangGps', mem.src, membersList)
            end
        end
    end
end)

-- Limpieza al desconectarse o cambiar de facción
AddEventHandler('playerDropped', function()
    local src = source
    if GangRadioMembers[src] then
        local g = GangRadioMembers[src].gang
        GangRadioMembers[src] = nil
        SyncRadioMembersToGang(g)
    end
end)

RegisterNetEvent('aura_gangs:server:onJobChange', function(oldJob, newJob)
    local src = source
    if GangRadioMembers[src] then
        local g = GangRadioMembers[src].gang
        if g ~= newJob then
            GangRadioMembers[src] = nil
            local pState = Player(src).state
            if pState then
                pState:set('gang_radio_channel', nil, true)
                pState:set('gang_radio_freq', 0, true)
            end
            if exports['pma-voice'] then
                pcall(function()
                    exports['pma-voice']:setPlayerRadio(src, 0)
                end)
            end
            TriggerClientEvent('aura_gangs:client:syncRadioChannel', src, 0, "Desconectado", "#00f2fe")
            SyncRadioMembersToGang(g)
        end
    end
end)
