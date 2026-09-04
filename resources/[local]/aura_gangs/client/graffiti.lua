-- ============================================================================
-- AURA GANGS: CLIENT GRAFFITI & TURF WARS
-- Wall Raycast Detection, Spray Animation, Physical Decals & Territorial Sync
-- ============================================================================

local ActiveTurfs = {}
local isSpraying = false

--- Raycast hacia la pared frente a la cámara del jugador
--- @param maxDist number
--- @return boolean, vector3, vector3
local function RaycastWallInFront(maxDist)
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local forward = vec3(
        -math.sin(math.rad(camRot.z)) * math.abs(math.cos(math.rad(camRot.x))),
        math.cos(math.rad(camRot.z)) * math.abs(math.cos(math.rad(camRot.x))),
        math.sin(math.rad(camRot.x))
    )
    local targetCoords = camCoords + (forward * (maxDist or 3.0))

    local ray = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, targetCoords.x, targetCoords.y, targetCoords.z, 1, cache.ped, 7)
    local _, hit, endCoords, surfaceNormal, entity = GetShapeTestResult(ray)

    if hit == 1 and entity == 0 then
        -- Ha impactado contra una pared del mapa (edificio o estructura estática)
        return true, endCoords, surfaceNormal
    end

    -- Fallback si el jugador está mirando de frente al ped
    local pCoords = GetEntityCoords(cache.ped)
    local pForward = GetEntityForwardVector(cache.ped)
    local pTarget = pCoords + (pForward * (maxDist or 2.5))
    local pRay = StartShapeTestRay(pCoords.x, pCoords.y, pCoords.z, pTarget.x, pTarget.y, pTarget.z, 1, cache.ped, 7)
    local _, pHit, pEnd, pNormal = GetShapeTestResult(pRay)

    return pHit == 1, pEnd, pNormal
end

--- Renderiza un decal de graffiti en las coordenadas y normal especificadas
--- @param coords vector3
--- @param normal vector3
--- @param gangName string
local function RenderGraffitiDecal(coords, normal, gangName)
    local gangData = Config.Graffiti.GangTags[gangName] or { color = { r = 255, g = 255, b = 255 } }
    -- Decal de graffiti nativo de GTA V (decal 1030 a 1050 son tags callejeros)
    local decalType = 1030
    local c = gangData.color

    AddDecal(
        decalType,
        coords.x, coords.y, coords.z,
        normal.x, normal.y, normal.z,
        0.0, 1.0, 0.0,
        1.5, 1.5,
        c.r / 255.0, c.g / 255.0, c.b / 255.0,
        1.0,
        0.0,
        false, false, false
    )
end

-- ============================================================================
-- 1. EXPORT DE USO DEL BOTE DE SPRAY
-- ============================================================================

local function UseSprayCan()
    if isSpraying then return end
    local ped = cache.ped

    if IsPedInAnyVehicle(ped, false) then
        lib.notify({ title = 'Graffiti', description = 'No puedes pintar desde el interior de un vehículo.', type = 'error' })
        return
    end

    local pJob = LocalPlayer.state.job
    if not pJob or not Config.Gangs[pJob] then
        lib.notify({
            title = 'Territorio',
            description = 'Solo miembros de bandas u organizaciones criminales pueden marcar territorios.',
            type = 'error'
        })
        return
    end

    local hit, wallCoords, wallNormal = RaycastWallInFront(2.8)
    if not hit or not wallCoords then
        lib.notify({
            title = 'Graffiti',
            description = 'Debes acercarte y apuntar directamente hacia una pared sólida.',
            type = 'error'
        })
        return
    end

    isSpraying = true

    -- Crear prop de bote de spray en la mano derecha
    local sprayProp = CreateObject(`prop_cs_spray_can`, 0.0, 0.0, 0.0, true, true, false)
    AttachEntityToEntity(sprayProp, ped, GetPedBoneIndex(ped, 57005), 0.12, 0.0, -0.03, -80.0, 0.0, 0.0, true, true, false, true, 1, true)

    -- Cargar diccionario y animación de pintado
    lib.requestAnimDict('switch@franklin@cleaning_car')
    TaskPlayAnim(ped, 'switch@franklin@cleaning_car', '001946_01_gc_fras_v2_ig_5_base', 3.0, 3.0, -1, 49, 0, false, false, false)

    PlaySoundFrontend(-1, "Spray_Loop", "GTAO_FM_Events_Soundset", true)

    local success = lib.progressBar({
        duration = Config.Graffiti.sprayDuration or 6000,
        label = string.format("Pintando marca de la banda [%s] en la pared...", Config.Gangs[pJob].label),
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true }
    })

    StopSound(-1)
    ClearPedTasks(ped)
    if DoesEntityExist(sprayProp) then DeleteEntity(sprayProp) end
    isSpraying = false

    if success then
        lib.callback('aura_gangs:server:saveGraffiti', false, function(ok, msg)
            if ok then
                RenderGraffitiDecal(wallCoords, wallNormal, pJob)
                PlaySoundFrontend(-1, "MEDAL_UP", "HUD_MINI_GAME_SOUNDSET", true)
                lib.notify({
                    title = 'Territorio Marcado',
                    description = msg,
                    type = 'success',
                    duration = 6000
                })
            else
                lib.notify({ title = 'Territorio', description = msg, type = 'error' })
            end
        end, wallCoords, wallNormal, pJob)
    else
        lib.notify({ title = 'Graffiti', description = 'Pintado cancelado.', type = 'inform' })
    end
end
exports('useSprayCan', UseSprayCan)

-- ============================================================================
-- 2. SINCRONIZACIÓN DE TERRITORIOS Y DIBUJO DE GRAFFITIS
-- ============================================================================

RegisterNetEvent('aura_gangs:client:syncGraffitis', function(turfs)
    ActiveTurfs = turfs or {}
    for _, turf in ipairs(ActiveTurfs) do
        local coords = vec3(turf.coords_x, turf.coords_y, turf.coords_z)
        local normal = vec3(turf.normal_x or 0.0, turf.normal_y or 0.0, turf.normal_z or 1.0)
        RenderGraffitiDecal(coords, normal, turf.gang)
    end
end)

CreateThread(function()
    Wait(2000)
    lib.callback('aura_gangs:server:getGraffitis', false, function(turfs)
        if turfs then
            ActiveTurfs = turfs
            for _, turf in ipairs(ActiveTurfs) do
                local coords = vec3(turf.coords_x, turf.coords_y, turf.coords_z)
                local normal = vec3(turf.normal_x or 0.0, turf.normal_y or 0.0, turf.normal_z or 1.0)
                RenderGraffitiDecal(coords, normal, turf.gang)
            end
        end
    end)
end)
