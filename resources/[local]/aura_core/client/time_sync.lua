CreateThread(function()
    -- Detener el reloj nativo del motor de GTA V
    PauseClock(true)

    while true do
        Wait(1000) -- Solo necesitamos aplicarlo cada segundo real
        local sTime = GlobalState.AuraTime
        if sTime then
            NetworkOverrideClockTime(sTime.h, sTime.m, 0)
        end
    end
end)
