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
-- 2. EXPORTS DE CLIENTE
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
