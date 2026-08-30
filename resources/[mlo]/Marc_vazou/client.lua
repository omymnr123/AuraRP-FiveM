Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local ped = PlayerPedId()
        local myCoords = GetEntityCoords(ped)
        if #(myCoords - vector3(-1552.0, -977.0, 13.0)) < 40.0 then
            ClearAreaOfPeds(-1552.0, -977.0, 13.0, 40.0, 0)
        end
    end
end)
