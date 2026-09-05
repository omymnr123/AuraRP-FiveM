-- ============================================================================
-- AURA GANGS: CLIENT POLICE RAID CONTROLLER (PROJECT GREENHOUSE)
-- Tactical Breaching, Ariete Minigame & Contraband Destruction
-- ============================================================================

local RaidExteriorZones = {}

--- Limpiar zonas de allanamiento policial
local function CleanupRaidZones()
    for _, zId in ipairs(RaidExteriorZones) do
        exports.ox_target:removeZone(zId)
    end
    RaidExteriorZones = {}
end

--- Registrar interacciones de asalto policial en puertas exteriores
local function SetupPoliceRaidZones(greenhouses)
    CleanupRaidZones()

    for gangId, ghData in pairs(greenhouses or {}) do
        local coords = vec3(ghData.coords.x, ghData.coords.y, ghData.coords.z)
        local gangConfig = Config.Gangs[gangId] or { label = gangId }

        local zId = exports.ox_target:addSphereZone({
            coords = coords,
            radius = 2.0,
            debug = Config.Debug or false,
            options = {
                {
                    name = 'police_raid_' .. gangId,
                    icon = 'fas fa-shield-halved',
                    label = string.format('Allanar Invernadero: %s (Ariete)', gangConfig.label),
                    distance = 2.0,
                    canInteract = function()
                        local pState = LocalPlayer.state
                        local isCop = (pState.job == Config.Greenhouse.PoliceRaid.policeJob) and (pState.job_duty == true)
                        return isCop
                    end,
                    onSelect = function()
                        StartPoliceBreach(gangId)
                    end
                }
            }
        })
        table.insert(RaidExteriorZones, zId)
    end
end

--- Secuencia de derribo de puerta con Ariete Táctico
function StartPoliceBreach(gangId)
    local hasRam = exports.ox_inventory:GetItemCount(Config.Greenhouse.PoliceRaid.requiredItem) >= 1
    if not hasRam then
        lib.notify({
            title = 'EQUIPAMIENTO INSUFICIENTE',
            description = 'Necesitas portar un Ariete Táctico LSPD (ariete_policial) en tu inventario.',
            type = 'error'
        })
        return
    end

    -- Minijuego de habilidad táctica
    local passed = lib.skillCheck(Config.Greenhouse.PoliceRaid.minigame or { 'medium', 'hard', 'medium' }, { 'w', 'a', 's', 'd' })
    if not passed then
        lib.notify({
            title = 'FALLO EN ALLANAMIENTO',
            description = 'El impacto no ha logrado quebrar el cerrojo blindado.',
            type = 'error'
        })
        return
    end

    local ped = PlayerPedId()

    -- Progreso de irrupción física
    if lib.progressBar({
        duration = Config.Greenhouse.PoliceRaid.breachDuration or 7500,
        label = 'Derribando acceso fortificado con ariete...',
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = {
            dict = 'missheistdockssetup1clipboard@idle_a',
            clip = 'idle_a',
            flag = 49
        }
    }) then
        local success, targetCoords = lib.callback.await('aura_gangs:server:executePoliceRaid', false, gangId)
        if not success then
            lib.notify({
                title = 'ERROR DE ALLANAMIENTO',
                description = targetCoords or 'Fallo al irrumpir en las instalaciones.',
                type = 'error'
            })
            return
        end

        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do Wait(50) end

        SetEntityCoords(ped, targetCoords.x, targetCoords.y, targetCoords.z, false, false, false, false)
        SetEntityHeading(ped, targetCoords.w or 270.0)
        Wait(200)

        DoScreenFadeIn(500)
        lib.notify({
            title = 'ALLANAMIENTO TÁCTICO EJECUTADO',
            description = string.format('Has asegurado el perímetro del invernadero clandestino (%s).', gangId),
            type = 'warning'
        })
    else
        lib.notify({ title = 'INTERRUPCIÓN', description = 'Operación de allanamiento cancelada.', type = 'inform' })
    end
end

-- ============================================================================
-- 2. DESTRUCCIÓN E INCAUTACIÓN DE CULTIVOS POR PARTE DE POLICÍAS
-- ============================================================================

--- Registrar target global en props de marihuana para destrucción policial
CreateThread(function()
    local weedModels = {
        `bkr_prop_weed_bucket_open_01a`,
        `bkr_prop_weed_01_small_01a`,
        `bkr_prop_weed_med_01a`,
        `bkr_prop_weed_lrg_01a`
    }

    exports.ox_target:addModel(weedModels, {
        {
            name = 'police_destroy_plant',
            icon = 'fas fa-fire-flame-curved',
            label = 'Destruir Plantación (Incautación LSPD)',
            distance = 1.8,
            canInteract = function(entity)
                local pState = LocalPlayer.state
                local isCop = (pState.job == Config.Greenhouse.PoliceRaid.policeJob) and (pState.job_duty == true)
                local inGreenhouse = pState.greenhouse_bucket and pState.greenhouse_bucket > 0
                return isCop and inGreenhouse
            end,
            onSelect = function(data)
                local entity = data.entity
                local coords = GetEntityCoords(entity)

                -- Buscar ID de planta local
                local targetPlantId = nil
                for pId, pData in pairs(SpawnedPlants or {}) do
                    if pData.entity == entity or #(pData.data.coords - coords) < 0.5 then
                        targetPlantId = pId
                        break
                    end
                end

                if not targetPlantId then
                    lib.notify({ title = 'ERROR', description = 'No se ha podido indexar la planta objetivo.', type = 'error' })
                    return
                end

                if lib.progressBar({
                    duration = Config.Greenhouse.PoliceRaid.destroyDuration or 8000,
                    label = 'Incinerando e incautando cultivo clandestino...',
                    useWhileDead = false,
                    canCancel = true,
                    disable = { car = true, move = true, combat = true },
                    anim = {
                        dict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@',
                        clip = 'weed_crouch_checkingleaves_idle_01_inspector',
                        flag = 49
                    }
                }) then
                    local success, msg = lib.callback.await('aura_gangs:server:destroyPlant', false, targetPlantId)
                    lib.notify({
                        title = success and 'EVIDENCIA DESTRUIDA' or 'ERROR',
                        description = msg,
                        type = success and 'success' or 'error'
                    })
                end
            end
        }
    })
end)

RegisterNetEvent('aura_gangs:client:syncGreenhouses', function(greenhouses)
    SetupPoliceRaidZones(greenhouses)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    CleanupRaidZones()
end)
