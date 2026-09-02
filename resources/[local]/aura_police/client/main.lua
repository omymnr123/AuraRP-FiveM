-- ============================================================================
-- AURA POLICE: CLIENT MAIN CONTROLLER
-- Station Blips, Dispatch Alert Audio/HUD & Client Exports
-- ============================================================================

local stationBlips = {}

-- ============================================================================
-- 1. BLIPS DE COMISARÍAS Y BASES POLICIALES
-- ============================================================================

local function InitStationBlips()
    for stationKey, stationData in pairs(Config.Stations) do
        if stationData.blip and stationData.armory then
            local coords = stationData.armory.coords
            local blip = AddBlipForCoord(coords.x, coords.y, coords.z)

            SetBlipSprite(blip, stationData.blip.sprite or 60)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, stationData.blip.scale or 0.85)
            SetBlipColour(blip, stationData.blip.color or 38)
            SetBlipAsShortRange(blip, true)

            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(stationData.blip.name or stationData.label)
            EndTextCommandSetBlipName(blip)

            table.insert(stationBlips, blip)
        end
    end
end

CreateThread(function()
    Wait(1000)
    InitStationBlips()
end)

-- ============================================================================
-- 2. RECEPTOR DE ALERTAS DE DESPACHO 911 EN VIVO
-- ============================================================================

RegisterNetEvent('aura_police:client:receiveDispatchAlert', function(alertData)
    if not alertData then return end

    -- Reproducir sonido policial de despacho
    PlaySoundFrontend(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", true)

    -- Notificación enriquecida con ox_lib
    lib.notify({
        title = string.format("🚨 %s - %s", alertData.code, alertData.title),
        description = string.format("%s\n(Hora: %s)", alertData.description, alertData.time or "AHORA"),
        type = 'inform',
        duration = 8000
    })

    -- Crear blip temporal parpadeante en el minimapa (45 segundos)
    if alertData.coords and alertData.coords.x ~= 0 then
        local alertBlip = AddBlipForCoord(alertData.coords.x, alertData.coords.y, alertData.coords.z)
        SetBlipSprite(alertBlip, 161)
        SetBlipScale(alertBlip, 1.2)
        SetBlipColour(alertBlip, 1) -- Rojo parpadeante
        SetBlipFlashes(alertBlip, true)
        SetBlipAsShortRange(alertBlip, false)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(string.format("[911] %s", alertData.title))
        EndTextCommandSetBlipName(alertBlip)

        SetTimeout(45000, function()
            if DoesBlipExist(alertBlip) then
                RemoveBlip(alertBlip)
            end
        end)
    end
end)

-- ============================================================================
-- 3. EXPORTS DE CLIENTE
-- ============================================================================

exports('IsCuffed', function()
    return LocalPlayer.state.isCuffed == true
end)

exports('IsJailed', function()
    return LocalPlayer.state.isJailed == true
end)

exports('IsCopOnDuty', function()
    local pState = LocalPlayer.state
    return pState.job == 'police' and pState.job_duty == true
end)
