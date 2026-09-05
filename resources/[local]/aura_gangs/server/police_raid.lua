-- ============================================================================
-- AURA GANGS: SERVER POLICE RAID CONTROLLER (PROJECT GREENHOUSE)
-- Tactical Breaching, Lock Destruction, Dispatch Alerts & Evidence Seizure
-- ============================================================================

local function IsOfficerOnDuty(src)
    local pState = Player(src).state
    return (pState.job == Config.Greenhouse.PoliceRaid.policeJob) and (pState.job_duty == true)
end

--- Ejecutar allanamiento policial táctico con ariete
lib.callback.register('aura_gangs:server:executePoliceRaid', function(source, gangId)
    local src = source
    if not src or not gangId then return false, "Parámetros inválidos." end

    if not IsOfficerOnDuty(src) then
        return false, "Solo agentes de policía en servicio activo pueden ejecutar un allanamiento táctico."
    end

    local hasRam = exports.ox_inventory:GetItemCount(src, Config.Greenhouse.PoliceRaid.requiredItem) >= 1
    if not hasRam then
        return false, "Necesitas equipar un Ariete Táctico LSPD (ariete_policial) para forzar la cerradura blindada."
    end

    local ghList = exports.aura_gangs:GetGreenhouses()
    local gh = ghList[gangId]
    if not gh then
        return false, "Invernadero no localizado."
    end

    local bucketId = exports.aura_gangs:GetGangBucket(gangId)
    local interior = Config.Greenhouse.Interior
    local pState = Player(src).state

    -- Colocar al policía en la dimensión de la banda allanada
    SetPlayerRoutingBucket(src, bucketId)
    pState:set('greenhouse_bucket', bucketId, true)
    pState:set('in_greenhouse_gang', gangId, true)

    -- Sincronizar las plantas de esa dimensión con el agente
    TriggerEvent('aura_gangs:server:syncPlantsToPlayer', src, gangId)

    -- Emitir alerta a la central de policía LSPD
    local char = exports.aura_multichar:GetActiveCharacter(src)
    local officerName = char and (char.firstname .. " " .. char.lastname) or "Agente LSPD"

    -- Notificar a los miembros conectados de la banda allanada
    for _, pid in ipairs(GetPlayers()) do
        local pSrc = tonumber(pid)
        if pSrc and Player(pSrc).state.job == gangId then
            TriggerClientEvent('ox_lib:notify', pSrc, {
                title = '¡INTRUSIÓN EN INVERNADERO!',
                description = '¡ALERTA ROJA! La Policía ha reventado el acceso de vuestro laboratorio de cultivo.',
                type = 'error',
                duration = 10000
            })
        end
    end

    print(string.format('^3[AURA POLICE RAID]^7 El oficial ^2%s^7 ha irrumpido en el invernadero de ^1%s^7 (Bucket: %d).', officerName, gangId, bucketId))
    return true, interior.spawnCoords
end)

--- Destrucción e incautación de cultivos por parte de la policía
lib.callback.register('aura_gangs:server:destroyPlant', function(source, plantId)
    local src = source
    if not src or not plantId then return false, "Datos inválidos." end

    if not IsOfficerOnDuty(src) then
        return false, "Solo agentes de la ley autorizados pueden incautar y destruir plantaciones ilegales."
    end

    local pState = Player(src).state
    local gangId = pState.in_greenhouse_gang
    if not gangId then
        return false, "No te encuentras dentro de un recinto de cultivo registrado."
    end

    local deleted = exports.aura_gangs:DeletePlant(gangId, plantId)
    if not deleted then
        return false, "No se ha podido incautar la planta o ya ha sido removida."
    end

    local char = exports.aura_multichar:GetActiveCharacter(src)
    local officerName = char and (char.firstname .. " " .. char.lastname) or "Agente LSPD"
    print(string.format('^3[AURA POLICE RAID]^7 Cultivo #%d destruido en el invernadero de ^1%s^7 por ^2%s^7.', plantId, gangId, officerName))

    return true, "Plantación ilegal incinerada e incautada según el protocolo de narcóticos LSPD."
end)
