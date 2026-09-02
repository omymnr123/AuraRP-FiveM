-- ============================================================================
-- AURA JOBS: CLIENT VENDORS CONTROLLER (24/7 STORE & PHYSICAL STOCK STASH)
-- Proximity-based Dynamic Ped Spawner (lib.points) + ox_target + NUI 24/7 Store
-- ============================================================================

local vendorPoints = {}
local isStoreOpen = false

local function OpenStoreUI(storeData)
    isStoreOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open247Store',
        data = storeData
    })
end

local function CloseStoreUI()
    if not isStoreOpen then return end
    isStoreOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close247Store' })
end

-- ============================================================================
-- SPAWN DE NPCS BASADO EN PROXIMIDAD (LIB.POINTS - COMPATIBLE CON TODOS LOS MLOS)
-- ============================================================================

local function InitVendorPoints()
    if not Config.BusinessVendors then return end

    for vendorKey, vendorConfig in pairs(Config.BusinessVendors) do
        local coords = vendorConfig.coords
        local heading = coords.w or vendorConfig.heading or 85.0
        local pointCoords = vector3(coords.x, coords.y, coords.z)

        local point = lib.points.new({
            coords = pointCoords,
            distance = 60.0,
            onEnter = function(self)
                if self.ped and DoesEntityExist(self.ped) then return end

                local modelString = vendorConfig.pedModel or 'u_m_y_party_01'
                local modelHash = type(modelString) == 'number' and modelString or joaat(modelString)

                if not IsModelValid(modelHash) then
                    print("^1[Aura_Jobs] ERROR crítico evitado: Invalid NPC model -> " .. tostring(modelString) .. "^7")
                    return -- Saltar el spawn de este NPC específico para no romper el script
                end

                -- Cargar el modelo de forma segura usando ox_lib
                lib.requestModel(modelHash)

                local ped = CreatePed(4, modelHash, coords.x, coords.y, coords.z - 1.0, heading, false, true)
                
                SetEntityAsMissionEntity(ped, true, true)
                SetEntityInvincible(ped, true)
                SetBlockingOfNonTemporaryEvents(ped, true)
                FreezeEntityPosition(ped, true)
                SetPedCanRagdollFromPlayerImpact(ped, false)
                SetEntityHeading(ped, heading)

                if vendorConfig.scenario then
                    TaskStartScenarioInPlace(ped, vendorConfig.scenario, 0, true)
                end

                self.ped = ped

                -- Registro en ox_target
                exports.ox_target:addLocalEntity(ped, {
                    -- Opción 1: Cliente compra en Tienda 24/7 (Solo cuando el local está cerrado)
                    {
                        name = 'aura_jobs_vendor_buy_' .. vendorKey,
                        icon = 'fas fa-basket-shopping',
                        label = 'Comprar en Tienda 24/7',
                        distance = 2.5,
                        canInteract = function()
                            return GlobalState['business_' .. vendorConfig.job .. '_open'] ~= true
                        end,
                        onSelect = function()
                            lib.callback('aura_jobs:server:getVendorStoreData', false, function(success, data)
                                if success and data then
                                    OpenStoreUI(data)
                                else
                                    lib.notify({
                                        title = vendorConfig.label,
                                        description = data or "No se pudo acceder a la tienda en este momento.",
                                        type = 'error'
                                    })
                                end
                            end, vendorKey)
                        end
                    },

                    -- Opción 2: Empleados / Jefes reponen el Stock físico en ox_inventory
                    {
                        name = 'aura_jobs_vendor_stock_' .. vendorKey,
                        icon = 'fas fa-boxes-stacked',
                        label = '📦 Reponer Stock de Tienda 24/7',
                        distance = 2.5,
                        canInteract = function()
                            local playerJob = LocalPlayer.state.job or (Player(PlayerPedId()) and Player(PlayerPedId()).state.job)
                            return playerJob == vendorConfig.job
                        end,
                        onSelect = function()
                            local stashId = 'vendor_stock_' .. vendorConfig.job
                            exports.ox_inventory:openInventory('stash', stashId)
                        end
                    },

                    -- Opción 3: Indicador de local abierto por empleados
                    {
                        name = 'aura_jobs_vendor_open_' .. vendorKey,
                        icon = 'fas fa-door-open',
                        label = 'Local Abierto (Atendido por Empleados)',
                        distance = 2.5,
                        canInteract = function()
                            return GlobalState['business_' .. vendorConfig.job .. '_open'] == true
                        end,
                        onSelect = function()
                            lib.notify({
                                title = vendorConfig.label,
                                description = "El establecimiento está abierto al público. Por favor realiza tu pedido a los empleados en servicio.",
                                type = 'inform'
                            })
                        end
                    }
                })
            end,
            onExit = function(self)
                if self.ped and DoesEntityExist(self.ped) then
                    DeleteEntity(self.ped)
                    self.ped = nil
                end
            end
        })

        table.insert(vendorPoints, point)
    end
end

CreateThread(function()
    Wait(500)
    InitVendorPoints()
end)

-- ============================================================================
-- NUI CALLBACKS
-- ============================================================================

RegisterNUICallback('close247Store', function(_, cb)
    isStoreOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('checkout247Store', function(data, cb)
    lib.callback('aura_jobs:server:buyVendorCart', false, function(success, result)
        cb({ success = success, result = result })
    end, data)
end)

-- Limpieza al detener el recurso
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        if isStoreOpen then
            SetNuiFocus(false, false)
        end
        for _, point in ipairs(vendorPoints) do
            if point.ped and DoesEntityExist(point.ped) then
                DeleteEntity(point.ped)
            end
            if point.remove then
                point:remove()
            end
        end
        vendorPoints = {}
    end
end)
