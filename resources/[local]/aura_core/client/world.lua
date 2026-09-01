--[[
    Aura Core - World Controller
    Control de densidad (-80%), protección de interiores y pacificación de NPCs
]]

local relationshipGroups = {
    `PLAYER`,
    `CIVMALE`,
    `CIVFEMALE`,
    `COP`,
    `SECURITY_GUARD`,
    `PRIVATE_SECURITY`,
    `GANG_1`,
    `GANG_2`,
    `GANG_9`,
    `GANG_10`,
    `AMBIENT_GANG_LOST`,
    `AMBIENT_GANG_BALLAS`,
    `AMBIENT_GANG_FAMILY`,
    `AMBIENT_GANG_MARABUNTE`,
    `AMBIENT_GANG_SALVA`,
    `AMBIENT_GANG_MEXICAN`,
    `FIREMAN`,
    `MEDIC`,
    `ARMY`,
    `DEALER`,
    `HATES_PLAYER`,
    `NO_RELATIONSHIP`,
    `SPECIAL`,
    `MISSION2`,
    `MISSION3`,
    `MISSION4`,
    `MISSION5`,
    `MISSION6`,
    `MISSION7`,
    `MISSION8`
}

-- Función para inicializar relaciones pacíficas entre NPCs y el Jugador
local function SetupPeacefulRelationships()
    local playerGroup = `PLAYER`
    for i = 1, #relationshipGroups do
        local group = relationshipGroups[i]
        -- Establecer relación de respeto (1) y agrado (2) para que nunca ataquen al jugador
        SetRelationshipBetweenGroups(1, playerGroup, group)
        SetRelationshipBetweenGroups(1, group, playerGroup)
        SetRelationshipBetweenGroups(1, group, group)
    end
end

-- ==========================================================
-- 1. HILO DE DENSIDAD DE NPCS Y TRÁFICO (Reducción del 80%)
-- ==========================================================
CreateThread(function()
    while true do
        Wait(0)
        
        local pedDensity = Config.Density.Peds or 0.20
        local scenarioDensity = Config.Density.ScenarioPeds or 0.20
        local vehicleDensity = Config.Density.Vehicles or 0.20
        local parkedDensity = Config.Density.ParkedVehicles or 0.20
        local randomVehDensity = Config.Density.RandomVehicles or 0.20
        local rangeDensity = Config.Density.AmbientRange or 0.20

        -- Multiplicadores de densidad de peatones
        SetPedDensityMultiplierThisFrame(pedDensity)
        SetScenarioPedDensityMultiplierThisFrame(scenarioDensity, scenarioDensity)

        -- Multiplicadores de densidad de tráfico
        SetVehicleDensityMultiplierThisFrame(vehicleDensity)
        SetRandomVehicleDensityMultiplierThisFrame(randomVehDensity)
        SetParkedVehicleDensityMultiplierThisFrame(parkedDensity)
        SetAmbientVehicleRangeMultiplierThisFrame(rangeDensity)

        -- Optimización adicional de luces distantes
        DisableVehicleDistantlights(true)
    end
end)

-- ==========================================================
-- 2. HILO DE CONFIGURACIÓN DEL JUGADOR Y RELACIONES
-- ==========================================================
CreateThread(function()
    SetupPeacefulRelationships()

    while true do
        Wait(5000)
        
        local player = PlayerId()
        local playerPed = PlayerPedId()

        -- Evitar que las bandas de GTA increpen o inicien peleas con el jugador
        if Config.PacifyNPCs.GangsIgnorePlayers then
            SetPlayerCanBeHassledByGangs(player, false)
        end

        SetCanAttackFriendly(playerPed, false, false)
    end
end)

-- ==========================================================
-- 3. HILO DE PROTECCIÓN DE INTERIORES Y PACIFICACIÓN DE NPCS
-- ==========================================================
CreateThread(function()
    while true do
        Wait(Config.Interiors.ScanInterval or 1000)

        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local playerInterior = GetInteriorFromEntity(playerPed)

        -- Si el jugador está dentro de un interior/negocio, limpiar peds ambientales cercanos
        if Config.Interiors.ClearInteriorPeds and playerInterior ~= 0 then
            ClearAreaOfPeds(
                playerCoords.x,
                playerCoords.y,
                playerCoords.z,
                Config.Interiors.ClearRadiusWhenInside or 40.0,
                1 -- El flag 1 asegura que NO se borren peds de misión / dependientes oficiales
            )
        end

        -- Escanear todos los peds del pool del juego
        local peds = GetGamePool('CPed')
        for i = 1, #peds do
            local ped = peds[i]

            -- Solo procesamos peds que no sean jugadores ni dependientes registrados (mission entities)
            if ped ~= playerPed and not IsPedAPlayer(ped) and not IsEntityAMissionEntity(ped) then
                local pedInterior = GetInteriorFromEntity(ped)

                -- Si un NPC ambiental se encuentra dentro de cualquier interior o negocio -> Eliminarlo
                if Config.Interiors.ClearInteriorPeds and pedInterior ~= 0 then
                    SetEntityAsMissionEntity(ped, true, true)
                    DeleteEntity(ped)
                else
                    -- Pacificar al NPC en la calle para que no sea agresivo
                    if Config.PacifyNPCs.DisableAggression then
                        SetPedCombatAttributes(ped, 46, false) -- BF_AlwaysFight = false
                        SetPedCombatAttributes(ped, 5, false)  -- BF_CanFightArmedPedsWhenNotArmed = false
                        SetPedCombatAttributes(ped, 0, false)  -- BF_CanUseCover = false
                        SetPedCombatAbility(ped, 0)            -- Nivel de combate bajo/nulo
                        SetPedCombatMovement(ped, 0)           -- Movimiento defensivo/estacionario
                        SetPedCombatRange(ped, 0)              -- Rango corto
                        SetPedAlertness(ped, 0)                -- Alerta mínima
                        SetPedAsEnemy(ped, false)              -- No tratar al jugador como enemigo
                        SetPedHearingRange(ped, 0.0)
                        SetPedSeeingRange(ped, 0.0)

                        if Config.PacifyNPCs.FleeOnPanic then
                            SetPedFleeAttributes(ped, 0, false)
                            SetBlockingOfNonTemporaryEvents(ped, false) -- Si hay disparos/ruido, huyen en vez de pelear
                        end
                    end
                end
            end
        end
    end
end)
