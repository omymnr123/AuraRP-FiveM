-- ============================================================================
-- AURA GANGS: SERVER DARK WEB & UNDERGROUND ROSTER HUB
-- Anonymous Roster Management, Offshore Finances & Database Bridges
-- ============================================================================

--- Obtiene de forma certera la banda y rol actual del jugador
--- @param src number
--- @return string | nil, table | nil, table | nil
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

--- Obtiene los datos del terminal Dark Web para la organización del jugador
lib.callback.register('aura_gangs:server:getDarkWebData', function(source)
    local src = source
    local gangName, gangConfig, jobData = GetPlayerCurrentGang(src)

    if not gangConfig or not jobData then
        return nil -- El jugador no pertenece a una banda reconocida
    end

    local isBoss = (jobData.isBoss == true)

    -- Obtener todos los miembros de la banda en la base de datos
    local members = MySQL.query.await([[
        SELECT id, citizenid, firstname, lastname, job_grade, phone_number, last_played 
        FROM characters 
        WHERE job = ? 
        ORDER BY job_grade DESC, firstname ASC
    ]], { gangName }) or {}

    -- Obtener saldo offshore de la sociedad
    local balance = exports.aura_jobs:GetSocietyBalance(gangName) or 0

    local allJobs = exports.aura_jobs:GetAllJobs()
    local grades = (allJobs and allJobs[gangName] and allJobs[gangName].grades) or {}

    return {
        gang = gangName,
        label = gangConfig.label,
        tag = gangConfig.tag or string.upper(string.sub(gangName, 1, 4)),
        isBoss = isBoss,
        balance = balance,
        members = members,
        grades = grades
    }
end)

--- Reclutar a un nuevo miembro para la organización
lib.callback.register('aura_gangs:server:hireMember', function(source, targetServerId)
    local src = source
    local gangName, gangConfig, jobData = GetPlayerCurrentGang(src)

    if not gangConfig or not jobData or not jobData.isBoss then
        return false, "Solo los líderes de la organización tienen autorización para reclutar."
    end

    local targetSrc = tonumber(targetServerId)
    if not targetSrc or not GetPlayerPing(targetSrc) or targetSrc <= 0 then
        return false, "El jugador especificado no se encuentra en línea."
    end

    local pPed = GetPlayerPed(src)
    local tPed = GetPlayerPed(targetSrc)
    if #(GetEntityCoords(pPed) - GetEntityCoords(tPed)) > 15.0 then
        return false, "El recluta debe estar físicamente cerca de ti."
    end

    local success, err = exports.aura_jobs:SetJob(targetSrc, gangName, 0)
    if success then
        local tChar = exports.aura_multichar:GetActiveCharacter(targetSrc)
        local tName = tChar and string.format("%s %s", tChar.firstname or "", tChar.lastname or "") or ("ID " .. targetSrc)

        TriggerClientEvent('ox_lib:notify', targetSrc, {
            title = 'Red Clandestina',
            description = string.format("Has sido reclutado en la organización %s.", gangConfig.label),
            type = 'success',
            duration = 8000
        })

        return true, string.format("Has reclutado a %s en la organización con rango inicial.", tName)
    else
        return false, err or "No se pudo asignar el rango."
    end
end)

--- Expulsar a un miembro de la banda
lib.callback.register('aura_gangs:server:fireMember', function(source, targetCharId)
    local src = source
    local gangName, gangConfig, jobData = GetPlayerCurrentGang(src)

    if not gangConfig or not jobData or not jobData.isBoss then
        return false, "Solo los líderes pueden expulsar miembros."
    end

    targetCharId = tonumber(targetCharId)
    local myChar = exports.aura_multichar:GetActiveCharacter(src)
    if myChar and targetCharId == myChar.id then
        return false, "No puedes expulsarte a ti mismo de tu propia organización."
    end

    -- Asignar desempleado mediante aura_jobs
    local success, err = exports.aura_jobs:SetJob(targetCharId, 'unemployed', 0)
    if success then
        return true, "El miembro ha sido expulsado definitivamente de la organización."
    else
        return false, err or "Error al actualizar la base de datos."
    end
end)

--- Ascender o degradar de rango a un miembro
lib.callback.register('aura_gangs:server:setMemberGrade', function(source, targetCharId, newGrade)
    local src = source
    local gangName, gangConfig, jobData = GetPlayerCurrentGang(src)

    if not gangConfig or not jobData or not jobData.isBoss then
        return false, "Solo los líderes pueden modificar rangos."
    end

    targetCharId = tonumber(targetCharId)
    newGrade = tonumber(newGrade)

    local success, err = exports.aura_jobs:SetJob(targetCharId, gangName, newGrade)
    if success then
        return true, "Rango actualizado con éxito en la red clandestina."
    else
        return false, err or "Error al actualizar el rango."
    end
end)

--- Depositar fondos en la cuenta offshore de la organización
lib.callback.register('aura_gangs:server:depositOffshore', function(source, amount, accountType)
    local src = source
    local gangName, gangConfig, jobData = GetPlayerCurrentGang(src)

    if not gangConfig or not jobData then
        return false, "Banda u organización no reconocida."
    end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false, "Cantidad no válida." end

    local itemToDeduct = (accountType == 'black_money') and 'black_money' or 'money'
    local removed = exports.ox_inventory:RemoveItem(src, itemToDeduct, amount)
    if not removed then
        return false, string.format("No tienes suficiente %s.", (accountType == 'black_money') and "dinero negro" or "dinero en efectivo")
    end

    local myChar = exports.aura_multichar:GetActiveCharacter(src)
    local citizenId = myChar and myChar.citizenid or ("SRC_" .. src)

    local success, newBalance = exports.aura_jobs:AddSocietyMoney(gangName, amount, string.format("Depósito Offshore (%s)", citizenId))
    if success then
        return true, string.format("Has depositado con éxito $%s en la cuenta offshore.", lib.math.groupdigits(amount)), newBalance
    else
        exports.ox_inventory:AddItem(src, itemToDeduct, amount)
        return false, "Error al procesar el ingreso offshore."
    end
end)

--- Retirar fondos de la cuenta offshore de la organización (Solo líderes)
lib.callback.register('aura_gangs:server:withdrawOffshore', function(source, amount)
    local src = source
    local gangName, gangConfig, jobData = GetPlayerCurrentGang(src)

    if not gangConfig or not jobData or not jobData.isBoss then
        return false, "Solo los líderes de la organización pueden autorizar retiradas offshore."
    end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false, "Cantidad no válida." end

    local currentBalance = exports.aura_jobs:GetSocietyBalance(gangName) or 0
    if currentBalance < amount then
        return false, "La cuenta offshore no dispone de suficiente saldo."
    end

    local myChar = exports.aura_multichar:GetActiveCharacter(src)
    local citizenId = myChar and myChar.citizenid or ("SRC_" .. src)

    local success, newBalance = exports.aura_jobs:RemoveSocietyMoney(gangName, amount, string.format("Retirada Offshore (%s)", citizenId))
    if success then
        exports.ox_inventory:AddItem(src, 'money', amount)
        return true, string.format("Has retirado $%s de la cuenta offshore.", lib.math.groupdigits(amount)), newBalance
    else
        return false, "No se pudo completar la transferencia."
    end
end)
