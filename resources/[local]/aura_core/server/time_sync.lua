local currentTime = { h = 8, m = 0 }
local timeMultiplier = 2000 -- 2000 ms (2 segundos reales) = 1 minuto in-game

CreateThread(function()
    while true do
        Wait(timeMultiplier)
        currentTime.m = currentTime.m + 1

        if currentTime.m >= 60 then
            currentTime.m = 0
            currentTime.h = currentTime.h + 1

            if currentTime.h >= 24 then
                currentTime.h = 0
            end
        end

        -- Sincronización pasiva a toda la red sin saturar eventos
        GlobalState.AuraTime = currentTime
    end
end)
