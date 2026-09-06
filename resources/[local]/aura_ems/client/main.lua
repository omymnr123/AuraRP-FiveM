-- ============================================================================
-- AURA EMS: CLIENT MAIN CONTROLLER
-- State initialization, synchronization & exports
-- ============================================================================

local function IsEms()
    local pState = LocalPlayer.state
    return pState.job == Config.JobName
end
exports('IsEms', IsEms)

local function IsEmsOnDuty()
    local pState = LocalPlayer.state
    return pState.job == Config.JobName and pState.job_duty == true
end
exports('IsEmsOnDuty', IsEmsOnDuty)

AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if Config.Debug then
        print("[AURA_EMS] Módulo de Emergencias Sanitarias iniciado.")
    end
end)
