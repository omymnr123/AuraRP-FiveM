-- ============================================================================
-- AURA JOBS: CLIENT CORE & STATEBAG CONTROLLER
-- ============================================================================

-- Exportaciones de cliente
exports('GetJob', function()
    local pState = LocalPlayer.state
    return {
        job = pState.job or 'unemployed',
        grade = pState.job_grade or 0,
        duty = pState.job_duty == true,
        label = pState.job_label or 'Desempleado',
        gradeLabel = pState.grade_label or 'Sin Rango'
    }
end)

exports('IsOnDuty', function()
    return LocalPlayer.state.job_duty == true
end)

-- Listener de cambios de StateBag para respuesta en tiempo real en HUD u otros recursos
AddStateBagChangeHandler('job_duty', nil, function(bagName, key, value, _unused, replicated)
    local playerNet = GetPlayerFromStateBagName(bagName)
    if playerNet and playerNet == PlayerId() then
        if Config.Debug then
            print(string.format("[Aura Jobs Client] Estado de servicio actualizado: %s", tostring(value)))
        end
    end
end)
