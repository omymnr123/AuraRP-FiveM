-- ============================================================================
-- AURA MEDICAL: CLIENT MAIN CONTROLLER
-- ============================================================================

CreateThread(function()
    if Config.Debug then
        print("[AURA_MEDICAL] Cliente inicializado correctamente.")
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if exports.aura_medical and exports.aura_medical.IsScannerOpen and exports.aura_medical:IsScannerOpen() then
        exports.aura_medical:CloseScanner()
    end
end)
