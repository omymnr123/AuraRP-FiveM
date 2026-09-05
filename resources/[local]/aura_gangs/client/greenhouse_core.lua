-- ============================================================================
-- AURA GANGS: CLIENT GREENHOUSE CORE CONTROLLER (PROJECT GREENHOUSE)
-- Door Target Interaction, Instanced MLO Teleportation & Zone Manager
-- ============================================================================

local ActiveGreenhouses = {}
local ExteriorZones = {}
local InteriorExitZone = nil

--- Limpiar todas las zonas activas de ox_target
local function CleanupExteriorZones()
    for _, zoneId in ipairs(ExteriorZones) do
        exports.ox_target:removeZone(zoneId)
    end
    ExteriorZones = {}
end

--- Registrar las zonas ox_target en las entradas exteriores de los invernaderos
local function SetupExteriorZones()
    CleanupExteriorZones()

    for gangId, ghData in pairs(ActiveGreenhouses) do
        local coords = vec3(ghData.coords.x, ghData.coords.y, ghData.coords.z)
        local gangConfig = Config.Gangs[gangId] or { label = gangId }

        local zoneId = exports.ox_target:addSphereZone({
            coords = coords,
            radius = 1.8,
            debug = Config.Debug or false,
            options = {
                {
                    name = 'greenhouse_enter_' .. gangId,
                    icon = 'fas fa-door-open',
                    label = string.format('Entrar: Invernadero (%s)', gangConfig.label),
                    distance = 2.0,
                    canInteract = function(entity, distance, coords, name)
                        local pState = LocalPlayer.state
                        local job = pState.job or "unemployed"
                        -- Permitir a miembros de la banda o admin
                        return (job == gangId) or (pState.isAdmin == true)
                    end,
                    onSelect = function()
                        EnterGreenhouse(gangId)
                    end
                }
            }
        })
        table.insert(ExteriorZones, zoneId)
    end
end

--- Registrar la zona de salida del interior del MLO
local function SetupInteriorExitZone()
    if InteriorExitZone then
        exports.ox_target:removeZone(InteriorExitZone)
        InteriorExitZone = nil
    end

    local interior = Config.Greenhouse.Interior
    InteriorExitZone = exports.ox_target:addSphereZone({
        coords = interior.exitDoor,
        radius = interior.exitRadius or 2.0,
        debug = Config.Debug or false,
        options = {
            {
                name = 'greenhouse_interior_exit',
                icon = 'fas fa-door-closed',
                label = 'Salir al Exterior',
                distance = 2.0,
                canInteract = function()
                    local pState = LocalPlayer.state
                    return pState.greenhouse_bucket and pState.greenhouse_bucket > 0
                end,
                onSelect = function()
                    ExitGreenhouse()
                end
            }
        }
    })
end

--- Secuencia de teletransporte de entrada al invernadero instanciado
function EnterGreenhouse(gangId)
    local success, targetCoords = lib.callback.await('aura_gangs:server:enterGreenhouse', false, gangId)
    if not success then
        lib.notify({
            title = 'ACCESO DENEGADO',
            description = targetCoords or 'No se ha podido acceder al invernadero.',
            type = 'error'
        })
        return
    end

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(50) end

    local ped = PlayerPedId()
    SetEntityCoords(ped, targetCoords.x, targetCoords.y, targetCoords.z, false, false, false, false)
    SetEntityHeading(ped, targetCoords.w or 270.0)
    Wait(200)

    DoScreenFadeIn(500)
    lib.notify({
        title = 'INVERNADERO CLANDESTINO',
        description = 'Has ingresado a las instalaciones privadas de cultivo.',
        type = 'inform'
    })
end

--- Secuencia de teletransporte de salida al exterior
function ExitGreenhouse()
    local success, exitCoords = lib.callback.await('aura_gangs:server:exitGreenhouse', false)
    if not success then
        lib.notify({
            title = 'ERROR',
            description = 'Error al salir del recinto.',
            type = 'error'
        })
        return
    end

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(50) end

    local ped = PlayerPedId()
    SetEntityCoords(ped, exitCoords.x, exitCoords.y, exitCoords.z, false, false, false, false)
    SetEntityHeading(ped, exitCoords.w or 0.0)
    Wait(200)

    DoScreenFadeIn(500)
    lib.notify({
        title = 'EXTERIOR',
        description = 'Has salido a la vía pública.',
        type = 'inform'
    })
end

-- ============================================================================
-- EVENTOS DE SINCRONIZACIÓN Y CICLO DE VIDA
-- ============================================================================

RegisterNetEvent('aura_gangs:client:syncGreenhouses', function(greenhouses)
    ActiveGreenhouses = greenhouses or {}
    SetupExteriorZones()
end)

CreateThread(function()
    SetupInteriorExitZone()
    TriggerServerEvent('aura_gangs:server:requestGreenhouses')
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    CleanupExteriorZones()
    if InteriorExitZone then
        exports.ox_target:removeZone(InteriorExitZone)
    end
end)
