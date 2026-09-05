-- ============================================================================
-- AURA CORE: CLIENT RADIO CHECKS & DEVICE VALIDATION
-- Global Export for Radio Connection Eligibility (Standard & Satellite)
-- ============================================================================

--- Comprueba si el jugador posee al menos un dispositivo de radio válido en su inventario.
--- @return boolean
local function CanConnectToRadio()
    local standardRadio = exports.ox_inventory:Search('count', 'radio') or 0
    local satelliteRadio = exports.ox_inventory:Search('count', 'radio_satelite') or 0
    
    return (standardRadio > 0) or (satelliteRadio > 0)
end

--- Obtiene el tipo de dispositivo de más alto rango que posee el jugador ('satellite', 'standard', o nil)
--- @return string|nil
local function GetActiveRadioType()
    local satelliteRadio = exports.ox_inventory:Search('count', 'radio_satelite') or 0
    if satelliteRadio > 0 then
        return 'satellite'
    end

    local standardRadio = exports.ox_inventory:Search('count', 'radio') or 0
    if standardRadio > 0 then
        return 'standard'
    end

    return nil
end

-- Export global para llamadas externas (MDT, Dark Web, HUD, scripts de facciones)
exports('CanConnectToRadio', CanConnectToRadio)
exports('GetActiveRadioType', GetActiveRadioType)
