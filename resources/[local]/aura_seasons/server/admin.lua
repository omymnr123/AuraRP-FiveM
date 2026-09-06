-- ============================================================================
-- AURARP SEASONS & SURVIVAL ADMIN & DEBUG SUITE (SERVER)
-- ============================================================================

local function IsAdmin(source)
    if source == 0 then return true end
    if Config.AllowDevMode == true then return true end

    local srcStr = tostring(source)
    if IsPlayerAceAllowed(srcStr, 'group.admin') or IsPlayerAceAllowed(srcStr, 'command') or IsPlayerAceAllowed(srcStr, 'command.seasonmenu') then
        return true
    end

    if exports.aura_core and exports.aura_core.GetPlayer then
        local player = exports.aura_core:GetPlayer(source)
        if player and player.group then
            local pGroup = string.lower(tostring(player.group))
            for _, adminGroup in ipairs(Config.AdminGroups or { 'admin', 'god', 'superadmin' }) do
                if pGroup == string.lower(adminGroup) then
                    return true
                end
            end
        end
    end

    return false
end

-- ============================================================================
-- EVENT HANDLERS PARA EL MENÚ INTERACTIVO
-- ============================================================================

RegisterNetEvent('aura_seasons:server:requestAdminMenu', function()
    local src = source
    if not IsAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Acceso Denegado',
            description = 'No tienes permisos de administrador para abrir este panel.',
            type = 'error'
        })
        return
    end

    TriggerClientEvent('aura_seasons:client:openAdminMenu', src)
end)

RegisterNetEvent('aura_seasons:server:adminSetSeason', function(targetSeason)
    local src = source
    if not IsAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Error', description = 'Permiso denegado.', type = 'error' })
        return
    end

    if Config.Seasons[targetSeason] then
        exports['aura_seasons']:SetSeason(targetSeason)
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Sistema Estacional',
            description = ('Estación cambiada con éxito a %s'):format(Config.Seasons[targetSeason].label),
            type = 'success',
            duration = 5000
        })
    end
end)

RegisterNetEvent('aura_seasons:server:adminSetWeather', function(weatherType)
    local src = source
    if not IsAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Error', description = 'Permiso denegado.', type = 'error' })
        return
    end

    exports['aura_seasons']:SetWeather(weatherType)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Control Meteorológico',
        description = ('Clima establecido en %s'):format(weatherType),
        type = 'success',
        duration = 5000
    })
end)

RegisterNetEvent('aura_seasons:server:adminSetSeasonDay', function(newDay)
    local src = source
    if not IsAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Error', description = 'Permiso denegado.', type = 'error' })
        return
    end

    exports['aura_seasons']:SetSeasonDay(newDay)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Calendario Estacional',
        description = ('Día fijado en %d/%d'):format(newDay, Config.SeasonDurationDays or 7),
        type = 'inform',
        duration = 5000
    })
end)

RegisterNetEvent('aura_seasons:server:adminAdvanceDay', function(delta)
    local src = source
    if not IsAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Error', description = 'Permiso denegado.', type = 'error' })
        return
    end

    exports['aura_seasons']:AdvanceDay(delta)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Calendario Estacional',
        description = ('Días modificados en %+d'):format(delta),
        type = 'inform',
        duration = 5000
    })
end)

RegisterNetEvent('aura_seasons:server:adminSetTime', function(hour, minute)
    local src = source
    if not IsAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Error', description = 'Permiso denegado.', type = 'error' })
        return
    end

    local h = tonumber(hour) or 12
    local m = tonumber(minute) or 0
    exports['aura_seasons']:SetTime(h, m)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Control de Tiempo',
        description = string.format('Hora fijada en %02d:%02d', h, m),
        type = 'success',
        duration = 5000
    })
end)

RegisterNetEvent('aura_seasons:server:adminToggleFreezeTime', function(freezeState)
    local src = source
    if not IsAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Error', description = 'Permiso denegado.', type = 'error' })
        return
    end

    local isFrozen = (freezeState == true or freezeState == 1)
    exports['aura_seasons']:SetTimeFrozen(isFrozen)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Control de Tiempo',
        description = isFrozen and 'Tiempo pausado/congelado.' or 'Tiempo reanudado.',
        type = 'inform',
        duration = 5000
    })
end)

RegisterNetEvent('aura_seasons:server:adminSetTimeSpeed', function(dayMs, nightMs)
    local src = source
    if not IsAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Error', description = 'Permiso denegado.', type = 'error' })
        return
    end

    local dMs = tonumber(dayMs) or 2000
    local nMs = tonumber(nightMs) or 2000
    exports['aura_seasons']:SetTimeSpeed(dMs, nMs)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Velocidad de Tiempo',
        description = string.format('Velocidad guardada: Día (%d ms/min), Noche (%d ms/min)', dMs, nMs),
        type = 'success',
        duration = 5000
    })
end)

RegisterNetEvent('aura_seasons:server:adminGiveTestItems', function()
    local src = source
    if not IsAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Error', description = 'Permiso denegado.', type = 'error' })
        return
    end

    if exports.ox_inventory then
        exports.ox_inventory:AddItem(src, 'coffee', 2)
        exports.ox_inventory:AddItem(src, 'water', 2)
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Inventario',
            description = 'Has recibido 2x Café y 2x Botellas de Agua para pruebas térmicas.',
            type = 'success'
        })
    end
end)

-- ============================================================================
-- COMANDOS DE ADMINISTRADOR
-- ============================================================================

RegisterCommand('seasonmenu', function(source)
    if not IsAdmin(source) then
        if source > 0 then
            TriggerClientEvent('ox_lib:notify', source, { title = 'Acceso Denegado', description = 'No eres administrador.', type = 'error' })
        end
        return
    end
    TriggerClientEvent('aura_seasons:client:openAdminMenu', source)
end, false)

RegisterCommand('seasonsadmin', function(source)
    if not IsAdmin(source) then
        if source > 0 then
            TriggerClientEvent('ox_lib:notify', source, { title = 'Acceso Denegado', description = 'No eres administrador.', type = 'error' })
        end
        return
    end
    TriggerClientEvent('aura_seasons:client:openAdminMenu', source)
end, false)

RegisterCommand('setseasonday', function(source, args)
    if not IsAdmin(source) then return end
    local day = tonumber(args[1]) or 1
    exports['aura_seasons']:SetSeasonDay(day)
    if source > 0 then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Calendario',
            description = ('Día fijado en %d de %d'):format(day, Config.SeasonDurationDays or 7),
            type = 'success'
        })
    end
end, false)

RegisterCommand('advanceday', function(source, args)
    if not IsAdmin(source) then return end
    local amount = tonumber(args[1]) or 1
    exports['aura_seasons']:AdvanceDay(amount)
    if source > 0 then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Calendario',
            description = ('Calendario modificado en %+d días'):format(amount),
            type = 'success'
        })
    end
end, false)

RegisterCommand('testbuff', function(source, args)
    if not IsAdmin(source) then return end
    local buffType = string.lower(args[1] or 'warmth')
    local dur = tonumber(args[2]) or 600
    if buffType == 'warmth' or buffType == 'cooling' then
        exports['aura_seasons']:ApplyThermalBuff(source, buffType, dur, 0.50, buffType == 'warmth' and 1.5 or -1.2)
    else
        if source > 0 then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Error',
                description = 'Tipo de buff inválido. Usa: warmth o cooling.',
                type = 'error'
            })
        end
    end
end, false)
