local Inventory = require 'modules.inventory.server'

local function GetPlayerJobGroups(charId)
    if not charId then return {} end
    local row = MySQL.single.await('SELECT job, job_grade FROM characters WHERE id = ?', { charId })
    if row and row.job then
        return { [row.job] = tonumber(row.job_grade) or 0 }
    end
    return {}
end

-- Evento al seleccionar personaje desde aura_multichar
AddEventHandler('aura_economy:server:characterLoaded', function(arg1, arg2, arg3)
    local src, charId, accounts
    if type(arg1) == 'number' and type(arg2) == 'number' then
        src = arg1
        charId = arg2
        accounts = arg3
    else
        src = source
        charId = arg1
        accounts = arg2
    end

    src = tonumber(src)
    if not src or not charId then return end

    local groups = GetPlayerJobGroups(charId)

    local player = {
        source = src,
        identifier = tostring(charId),
        name = GetPlayerName(src) or ('Character %s'):format(charId),
        groups = groups
    }

    server.setPlayerInventory(player, nil)
    
    -- Sincronizar el efectivo físico inicial si aplica (solo si no tenía inventario previo)
    local cash = accounts and accounts.cash or 0
    local currentMoney = Inventory.GetItem(src, 'money', nil, true) or 0
    if currentMoney == 0 and cash > 0 then
        Inventory.SetItem(src, 'money', cash)
    end
end)

---@diagnostic disable-next-line: duplicate-set-field
function server.syncInventory(inv)
    local accounts = Inventory.GetAccountItemCounts(inv)
    if not accounts then return end

    local src = tonumber(inv.id)
    if not src or not GetPlayerName(tostring(src)) then return end

    for account, amount in pairs(accounts) do
        local accountName = account == 'money' and 'cash' or account
        local currentMoney = exports.aura_economy:GetMoney(src, accountName)
        if currentMoney ~= amount then
            exports.aura_economy:SetMoney(src, accountName, amount, string.format("Sync %s con inventario físico", accountName))
        end
    end
end

-- Sincronización en vivo cuando aura_jobs actualiza el trabajo de un jugador
AddEventHandler('aura_jobs:server:jobUpdated', function(src, job, grade)
    local inv = Inventory(src)
    if inv and inv.player then
        inv.player.groups = { [job] = tonumber(grade) or 0 }
    end
end)

-- Auto-inicialización si el recurso se reinicia con jugadores conectados
CreateThread(function()
    Wait(500)
    for _, srcStr in ipairs(GetPlayers()) do
        local src = tonumber(srcStr)
        if src then
            local multicharActive = exports.aura_multichar and exports.aura_multichar:GetActiveCharacter(src)
            if multicharActive and multicharActive.id then
                local groups = GetPlayerJobGroups(multicharActive.id)
                local player = {
                    source = src,
                    identifier = tostring(multicharActive.id),
                    name = GetPlayerName(src) or ('Character %s'):format(multicharActive.id),
                    groups = groups
                }
                server.setPlayerInventory(player, nil)
            end
        end
    end
end)

-- Evento al desconectarse el jugador
AddEventHandler('playerDropped', function()
    local src = source
    if src then
        server.playerDropped(src)
    end
end)

---@diagnostic disable-next-line: duplicate-set-field
function server.setPlayerData(player)
    return {
        source = player.source,
        identifier = player.identifier or player.source,
        name = player.name or GetPlayerName(player.source),
        groups = player.groups or {}
    }
end

---@diagnostic disable-next-line: duplicate-set-field
function server.hasLicense(inv, license)
    return false
end

---@diagnostic disable-next-line: duplicate-set-field
function server.buyLicense(inv, license)
    return false, 'can_not_afford'
end

---@diagnostic disable-next-line: duplicate-set-field
function server.isPlayerBoss(playerId, group)
    local multicharActive = exports.aura_multichar and exports.aura_multichar:GetActiveCharacter(playerId)
    if not multicharActive or not multicharActive.id then return false end
    local jobRow = MySQL.single.await('SELECT job, job_grade FROM characters WHERE id = ?', { multicharActive.id })
    if jobRow and jobRow.job == group then
        return (tonumber(jobRow.job_grade) or 0) >= 3
    end
    return false
end

---@diagnostic disable-next-line: duplicate-set-field
function server.getOwnedVehicleId(entityId)
    return nil
end
