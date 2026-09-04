-- ============================================================================
-- AURA POLICE: CLIENT JAIL & ANTI-ESCAPE CONTROLLER
-- Perimeter Boundary Guard, Prison Control Restriction & Sentence Display
-- ============================================================================

local isJailed = false
local remainingMinutes = 0
local jailReason = ""

RegisterNetEvent('aura_police:client:onJailed', function(minutes, reason)
    isJailed = true
    remainingMinutes = minutes
    jailReason = reason or "Condena Penitenciaria"
    LocalPlayer.state:set('isJailed', true, true)
    LocalPlayer.state:set('invBusy', true, false)

    DoScreenFadeOut(500)
    Wait(600)
    
    local cell = Config.Jail.cellCoords
    SetEntityCoords(cache.ped, cell.x, cell.y, cell.z, false, false, false, false)
    SetEntityHeading(cache.ped, cell.w or 35.0)

    Wait(500)
    DoScreenFadeIn(800)

    StartJailBoundaryThread()
end)

RegisterNetEvent('aura_police:client:onUnjailed', function()
    isJailed = false
    remainingMinutes = 0
    LocalPlayer.state:set('isJailed', false, true)
    LocalPlayer.state:set('invBusy', false, false)

    DoScreenFadeOut(500)
    Wait(600)

    local release = Config.Jail.releaseCoords
    SetEntityCoords(cache.ped, release.x, release.y, release.z, false, false, false, false)
    SetEntityHeading(cache.ped, release.w or 270.0)

    Wait(500)
    DoScreenFadeIn(800)
end)

function StartJailBoundaryThread()
    CreateThread(function()
        local cell = Config.Jail.cellCoords.xyz
        local radius = Config.Jail.escapeRadius or 85.0

        while isJailed do
            Wait(1000)
            local myCoords = GetEntityCoords(cache.ped)
            local dist = #(myCoords - cell)

            -- Medida Anti-Fuga: Si el recluso supera el radio perimetral, teletransportarlo de vuelta
            if dist > radius then
                DoScreenFadeOut(300)
                Wait(350)
                SetEntityCoords(cache.ped, cell.x, cell.y, cell.z, false, false, false, false)
                DoScreenFadeIn(500)

                lib.notify({
                    title = 'Seguridad Penitenciaria',
                    description = '¡Intento de evasión detectado! Has sido devuelto al patio central de la prisión.',
                    type = 'error'
                })
            end
        end
    end)

    -- Hilo de restricción de acciones mientras esté en la cárcel
    CreateThread(function()
        while isJailed do
            Wait(0)
            -- Restringir inventario, armas y vehículos
            DisableControlAction(0, 37, true)  -- Weapon Wheel
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim
            DisableControlAction(0, 289, true) -- Inventory
        end
    end)
end

-- Listener de StateBag para sincronización de minutos en caliente
AddStateBagChangeHandler('jailMinutes', nil, function(bagName, key, value)
    local playerNet = GetPlayerFromStateBagName(bagName)
    if playerNet and playerNet == PlayerId() then
        remainingMinutes = tonumber(value) or 0
        if remainingMinutes > 0 and isJailed then
            lib.notify({
                title = 'Bolingbroke Penitentiary',
                description = string.format("Tiempo restante de condena: %d minutos.", remainingMinutes),
                type = 'inform',
                duration = 4000
            })
        end
    end
end)
