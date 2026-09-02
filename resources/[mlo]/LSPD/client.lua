CreateThread(function()
    RequestIpl("hei_dt1_19_interior_0_heist_police_dlc_milo_")
    RequestIpl("T1JNES_MRPD_MILO")
    
    local interior = GetInteriorAtCoords(440.84, -983.14, 30.69)
    if IsValidInterior(interior) then
        PinInteriorInMemory(interior)
        LoadInterior(interior)
        RefreshInterior(interior)
    end
end)
