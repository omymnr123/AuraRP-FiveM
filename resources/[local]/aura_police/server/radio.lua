-- ============================================================================
-- AURA POLICE: SERVER RADIO-PATRULLAS & LIVE GPS CONTROLLER
-- 21 Tactical Channels (Mando + Patrullas 1-20), PMA-Voice Sync, Colors & GPS
-- ============================================================================

local PoliceChannels = {}
local PoliceRadioMembers = {} -- [src] = { channelId = '...', name = '...', grade = ..., gradeLabel = '...', badge = '...' }

local function IsCopOnDuty(src)
    local pState = Player(src).state
    return pState and pState.job == 'police' and pState.job_duty == true
end

local function GetOfficerInfo(src)
    local pState = Player(src).state
    local name = "Oficial"
    local grade = 0
    local gradeLabel = "Cadete"
    local badge = tostring(src)

    local char = nil
    if GetResourceState('aura_multichar') == 'started' then
        pcall(function()
            char = exports.aura_multichar:GetActiveCharacter(src)
        end)
    end

    if char then
        name = string.format("%s %s", char.firstname or "Oficial", char.lastname or "")
        grade = tonumber(char.job_grade) or (pState and tonumber(pState.job_grade)) or 0
        gradeLabel = char.job_grade_label or (pState and pState.grade_label) or (pState and pState.job_grade_label) or "Oficial"
        badge = char.badge or (pState and pState.badge) or tostring(src)
    elseif pState then
        name = pState.char_name or GetPlayerName(src) or "Oficial"
        grade = tonumber(pState.job_grade) or 0
        gradeLabel = pState.grade_label or pState.job_grade_label or "Oficial"
        badge = pState.badge or tostring(src)
    else
        name = GetPlayerName(src) or "Oficial"
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
-- 1. CARGA INICIAL Y SINCRONIZACIÓN DE CANALES
-- ============================================================================

local function LoadPoliceChannels()
    local rows = MySQL.query.await('SELECT * FROM `aura_police_radio_channels` ORDER BY `frequency` ASC')
    PoliceChannels = {}
    if rows and #rows > 0 then
        for _, r in ipairs(rows) do
            PoliceChannels[r.channel_id] = {
                id = r.channel_id,
                label = r.label,
                color = r.color or '#00f2fe',
                blipColor = tonumber(r.blip_color) or 38,
                frequency = tonumber(r.frequency) or 100,
                isMando = (r.is_mando == 1 or r.is_mando == true),
                members = {}
            }
        end
    end
end

CreateThread(function()
    Wait(1200)
    LoadPoliceChannels()
end)

local function SyncRadioMembersToAllPolice()
    local overview = {}
    for chId, ch in pairs(PoliceChannels) do
        local memberList = {}
        for src, data in pairs(PoliceRadioMembers) do
            if data.channelId == chId and IsCopOnDuty(src) then
                table.insert(memberList, {
                    src = src,
                    name = data.name,
                    grade = data.grade,
                    gradeLabel = data.gradeLabel,
                    badge = data.badge
                })
            end
        end
        ch.members = memberList
        overview[chId] = ch
    end

    for _, pid in ipairs(GetPlayers()) do
        local pSrc = tonumber(pid)
        if pSrc and IsCopOnDuty(pSrc) then
            TriggerClientEvent('aura_police:client:syncRadioOverview', pSrc, overview)
        end
    end
end

-- ============================================================================
-- 2. CALLBACKS Y EVENTOS DE GESTIÓN DE RADIO
-- ============================================================================

lib.callback.register('aura_police:server:getRadioOverview', function(source)
    if not IsCopOnDuty(source) then
        return { success = false, message = "No estás de servicio policial." }
    end

    local offInfo = GetOfficerInfo(source)
    local currentChannelId = PoliceRadioMembers[source] and PoliceRadioMembers[source].channelId or nil

    -- Reconstruir lista de miembros actualizada en formato array ordenado por frecuencia
    local overview = {}
    for chId, ch in pairs(PoliceChannels) do
        local memberList = {}
        for src, data in pairs(PoliceRadioMembers) do
            if data.channelId == chId and IsCopOnDuty(src) then
                table.insert(memberList, {
                    src = src,
                    name = data.name,
                    grade = data.grade,
                    gradeLabel = data.gradeLabel,
                    badge = data.badge
                })
            end
        end
        local chCopy = {
            id = ch.id,
            label = ch.label,
            color = ch.color,
            blipColor = ch.blipColor,
            frequency = ch.frequency,
            isMando = ch.isMando,
            members = memberList
        }
        table.insert(overview, chCopy)
    end

    table.sort(overview, function(a, b)
        return (tonumber(a.frequency) or 0) < (tonumber(b.frequency) or 0)
    end)

    return {
        success = true,
        data = {
            channels = overview,
            activeChannelId = currentChannelId,
            isMandoGrade = (offInfo.grade >= 2)
        }
    }
end)

lib.callback.register('aura_police:server:joinRadioChannel', function(source, channelId)
    local src = source
    if not IsCopOnDuty(src) then
        return { success = false, message = "Debes estar de servicio para conectar a la radio policial." }
    end

    local ch = PoliceChannels[channelId]
    if not ch then
        return { success = false, message = "Canal de radio no encontrado." }
    end

    local offInfo = GetOfficerInfo(src)

    -- Si es Canal de Mando, verificar rango (Sargento hacia arriba: grado >= 2)
    if ch.isMando and offInfo.grade < 2 then
        return { success = false, message = "Acceso denegado: El Canal de Mando está reservado para Mandos y Supervisores." }
    end

    PoliceRadioMembers[src] = {
        channelId = channelId,
        name = offInfo.name,
        grade = offInfo.grade,
        gradeLabel = offInfo.gradeLabel,
        badge = offInfo.badge
    }

    local pState = Player(src).state
    if pState then
        pState:set('police_radio_channel', channelId, true)
        pState:set('police_radio_freq', ch.frequency, true)
        pState:set('police_radio_color', ch.color, true)
        pState:set('police_radio_blip_color', ch.blipColor, true)
    end

    -- Sincronizar pma-voice en el cliente
    TriggerClientEvent('aura_police:client:syncRadioChannel', src, ch.frequency, ch.label, ch.color, ch.isMando)

    -- Sincronizar lista general
    SyncRadioMembersToAllPolice()

    return {
        success = true,
        channelId = channelId,
        frequency = ch.frequency,
        label = ch.label,
        color = ch.color,
        isMando = ch.isMando,
        message = string.format("Conectado a %s (%s MHz)", ch.label, ch.frequency)
    }
end)

lib.callback.register('aura_police:server:leaveRadioChannel', function(source)
    local src = source
    if PoliceRadioMembers[src] then
        PoliceRadioMembers[src] = nil
    end

    local pState = Player(src).state
    if pState then
        pState:set('police_radio_channel', nil, true)
        pState:set('police_radio_freq', 0, true)
        pState:set('police_radio_color', '#00f2fe', true)
        pState:set('police_radio_blip_color', 38, true)
    end

    TriggerClientEvent('aura_police:client:syncRadioChannel', src, 0, "Desconectado", "#00f2fe", false)
    SyncRadioMembersToAllPolice()

    return { success = true, message = "Te has desconectado de la radio policial." }
end)

lib.callback.register('aura_police:server:setChannelColor', function(source, data)
    local src = source
    if not IsCopOnDuty(src) then
        return { success = false, message = "No autorizado." }
    end

    local channelId = data.channelId
    local hexColor = data.hexColor or '#00f2fe'
    local blipColor = tonumber(data.blipColor) or 38

    if not PoliceChannels[channelId] then
        return { success = false, message = "Canal no válido." }
    end

    -- Guardar en MariaDB
    MySQL.update.await('UPDATE `aura_police_radio_channels` SET `color` = ?, `blip_color` = ? WHERE `channel_id` = ?', {
        hexColor, blipColor, channelId
    })

    PoliceChannels[channelId].color = hexColor
    PoliceChannels[channelId].blipColor = blipColor

    -- Actualizar state bags de los miembros conectados en ese canal
    for memSrc, memData in pairs(PoliceRadioMembers) do
        if memData.channelId == channelId then
            local pState = Player(memSrc).state
            if pState then
                pState:set('police_radio_color', hexColor, true)
                pState:set('police_radio_blip_color', blipColor, true)
            end
        end
    end

    SyncRadioMembersToAllPolice()

    return { success = true, message = "Color de canal actualizado correctamente." }
end)

-- ============================================================================
-- 3. TRANSMISIÓN PRIORITARIA DE MANDO (MALLA GENERAL)
-- ============================================================================

RegisterNetEvent('aura_police:server:broadcastMandoTalk', function(isTalking)
    local src = source
    if not IsCopOnDuty(src) then return end

    local currentMem = PoliceRadioMembers[src]
    if not currentMem or currentMem.channelId ~= 'mando' then
        return
    end

    local offInfo = GetOfficerInfo(src)

    -- Enviar a todos los agentes de servicio
    for _, pid in ipairs(GetPlayers()) do
        local pSrc = tonumber(pid)
        if pSrc and IsCopOnDuty(pSrc) and pSrc ~= src then
            TriggerClientEvent('aura_police:client:onMandoBroadcast', pSrc, src, isTalking, offInfo.name, offInfo.gradeLabel)
        end
    end
end)

-- ============================================================================
-- 4. BUCLE DE SINCRONIZACIÓN GPS TÁCTICO DE POLICÍAS EN SERVICIO (MAP BLIPS)
-- ============================================================================

CreateThread(function()
    while true do
        Wait(1500)

        local onDutyCops = {}
        for _, pid in ipairs(GetPlayers()) do
            local pSrc = tonumber(pid)
            if pSrc and IsCopOnDuty(pSrc) then
                local ped = GetPlayerPed(pSrc)
                if DoesEntityExist(ped) then
                    local coords = GetEntityCoords(ped)
                    local heading = GetEntityHeading(ped)
                    local inVeh = IsPedInAnyVehicle(ped, false)
                    local memData = PoliceRadioMembers[pSrc]
                    local chInfo = memData and PoliceChannels[memData.channelId]
                    local offInfo = GetOfficerInfo(pSrc)

                    table.insert(onDutyCops, {
                        src = pSrc,
                        name = offInfo.name,
                        gradeLabel = offInfo.gradeLabel,
                        badge = offInfo.badge,
                        coords = { x = coords.x, y = coords.y, z = coords.z },
                        heading = heading,
                        inVehicle = inVeh,
                        channelId = memData and memData.channelId or "none",
                        channelLabel = chInfo and chInfo.label or "Sin Radio",
                        blipColor = chInfo and chInfo.blipColor or 38,
                        hexColor = chInfo and chInfo.color or "#00f2fe"
                    })
                end
            end
        end

        if #onDutyCops > 0 then
            for _, cop in ipairs(onDutyCops) do
                TriggerClientEvent('aura_police:client:syncPoliceGps', cop.src, onDutyCops)
            end
        end
    end
end)

-- Limpieza al desconectarse o salir de servicio
AddEventHandler('playerDropped', function()
    local src = source
    if PoliceRadioMembers[src] then
        PoliceRadioMembers[src] = nil
        SyncRadioMembersToAllPolice()
    end
end)

RegisterNetEvent('aura_police:server:onDutyChange', function(isDuty)
    local src = source
    if not isDuty and PoliceRadioMembers[src] then
        PoliceRadioMembers[src] = nil
        local pState = Player(src).state
        if pState then
            pState:set('police_radio_channel', nil, true)
            pState:set('police_radio_freq', 0, true)
        end
        TriggerClientEvent('aura_police:client:syncRadioChannel', src, 0, "Desconectado", "#00f2fe", false)
        SyncRadioMembersToAllPolice()
    end
end)
