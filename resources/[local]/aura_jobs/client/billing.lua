-- ============================================================================
-- AURA JOBS: REFACTORED UNIVERSAL BILLING & STASH CLIENT CONTROLLER
-- Player-to-Player Billing ("Facturar") + Centralized Business Stashes
-- ============================================================================

local isNuiOpen = false

-- ============================================================================
-- 1. FACTURACIÓN DIRECTA JUGADOR A JUGADOR (OX_TARGET GLOBAL PLAYER)
-- ============================================================================

CreateThread(function()
    -- Opción de Facturar sobre jugadores
    exports.ox_target:addGlobalPlayer({
        {
            name = 'aura_jobs_bill_player',
            icon = 'fa-solid fa-file-invoice-dollar',
            label = 'Facturar',
            distance = 2.5,
            canInteract = function(entity, distance, coords, name)
                -- Validar que el emisor esté de servicio en un trabajo comercial
                local pState = LocalPlayer.state
                local job = pState.job or 'unemployed'
                local isDuty = pState.job_duty == true
                local jobConfig = Config.Jobs[job]

                if not isDuty or not jobConfig or not jobConfig.isBusiness then
                    return false
                end

                -- No facturarse a uno mismo
                local targetPlayer = NetworkGetPlayerIndexFromPed(entity)
                return targetPlayer ~= PlayerId()
            end,
            onSelect = function(data)
                local targetPed = data.entity
                if not DoesEntityExist(targetPed) then return end

                local targetIndex = NetworkGetPlayerIndexFromPed(targetPed)
                local targetSrc = GetPlayerServerId(targetIndex)
                if not targetSrc or targetSrc <= 0 then return end

                local jobLabel = LocalPlayer.state.job_label or "Negocio"

                -- Modal de entrada de datos con ox_lib
                local input = lib.inputDialog(string.format('Emitir Factura - %s', jobLabel), {
                    {
                        type = 'input',
                        label = 'Concepto del Servicio / Producto',
                        placeholder = 'Ej: Reparación de Motor + Pintura',
                        required = true,
                        min = 3,
                        max = 60
                    },
                    {
                        type = 'number',
                        label = 'Importe a Cobrar ($)',
                        placeholder = 'Introduce la cantidad en dólares',
                        icon = 'dollar-sign',
                        required = true,
                        min = 1,
                        max = 1000000
                    }
                })

                if not input then return end

                local concept = input[1]
                local amount = tonumber(input[2])

                if not concept or not amount or amount <= 0 then
                    lib.notify({
                        title = 'Error',
                        description = 'Debes especificar un concepto válido y un importe mayor a $0.',
                        type = 'error'
                    })
                    return
                end

                -- Enviar la solicitud de factura al servidor
                lib.callback('aura_jobs:server:sendPlayerBill', false, function(success, err)
                    if not success then
                        lib.notify({
                            title = 'Error al Facturar',
                            description = string.format("No se pudo enviar la factura: %s", tostring(err)),
                            type = 'error'
                        })
                    end
                end, {
                    targetSrc = targetSrc,
                    concept = concept,
                    amount = amount
                })
            end
        }
    })

    local function PromptBillCustomer(targetSrc)
        local jobLabel = LocalPlayer.state.job_label or "Negocio"

        local input = lib.inputDialog(string.format('Cobro en Caja TPV - %s', jobLabel), {
            {
                type = 'input',
                label = 'Concepto del Servicio / Producto',
                placeholder = 'Ej: 2x Cerveza + 1x Patatas',
                required = true,
                min = 3,
                max = 60
            },
            {
                type = 'number',
                label = 'Importe a Cobrar ($)',
                placeholder = 'Introduce la cantidad en dólares',
                icon = 'dollar-sign',
                required = true,
                min = 1,
                max = 1000000
            }
        })

        if not input then return end

        local concept = input[1]
        local amount = tonumber(input[2])

        if not concept or not amount or amount <= 0 then
            lib.notify({
                title = 'Error',
                description = 'Debes especificar un concepto válido y un importe mayor a $0.',
                type = 'error'
            })
            return
        end

        lib.callback('aura_jobs:server:sendPlayerBill', false, function(success, err)
            if not success then
                lib.notify({
                    title = 'Error al Facturar',
                    description = string.format("No se pudo enviar la factura: %s", tostring(err)),
                    type = 'error'
                })
            else
                lib.notify({
                    title = 'Cobro Enviado',
                    description = string.format("Factura de $%s enviada al cliente en mostrador.", lib.math.groupdigits(amount)),
                    type = 'success'
                })
            end
        end, {
            targetSrc = targetSrc,
            concept = concept,
            amount = amount
        })
    end

    -- ============================================================================
    -- 2. CAJAS REGISTRADORAS FÍSICAS (TPV COBRO RÁPIDO, STASH Y BALANCE DE EMPRESA)
    -- ============================================================================
    exports.ox_target:addModel(Config.RegisterProps, {
        -- Opción 1: Cobro TPV al cliente frente al mostrador
        {
            name = 'aura_register_bill_customer',
            icon = 'fa-solid fa-cash-register',
            label = 'Cobrar en Caja (TPV)',
            distance = 2.0,
            canInteract = function(entity, distance, coords, name)
                local pState = LocalPlayer.state
                local job = pState.job or 'unemployed'
                local isDuty = pState.job_duty == true
                local jobConfig = Config.Jobs[job]
                return isDuty and jobConfig and jobConfig.isBusiness == true
            end,
            onSelect = function(data)
                -- Buscar clientes cercanos alrededor del mostrador (hasta 4.0 metros)
                local myPed = PlayerPedId()
                local myCoords = GetEntityCoords(myPed)
                local nearbyPlayers = {}

                for _, player in ipairs(GetActivePlayers()) do
                    local ped = GetPlayerPed(player)
                    if ped ~= myPed and DoesEntityExist(ped) then
                        local coords = GetEntityCoords(ped)
                        local dist = #(myCoords - coords)
                        if dist <= 4.0 then
                            local sId = GetPlayerServerId(player)
                            table.insert(nearbyPlayers, {
                                serverId = sId,
                                distance = dist,
                                label = string.format("Cliente en Mostrador (ID: %d)", sId)
                            })
                        end
                    end
                end

                if #nearbyPlayers == 0 then
                    lib.notify({
                        title = 'Caja Registradora',
                        description = 'No hay ningún cliente cerca del mostrador para cobrarle.',
                        type = 'inform'
                    })
                    return
                elseif #nearbyPlayers == 1 then
                    PromptBillCustomer(nearbyPlayers[1].serverId)
                else
                    local menuOptions = {}
                    for _, p in ipairs(nearbyPlayers) do
                        table.insert(menuOptions, {
                            title = p.label,
                            description = string.format("Distancia: %.1f metros", p.distance),
                            icon = 'fa-solid fa-user',
                            onSelect = function()
                                PromptBillCustomer(p.serverId)
                            end
                        })
                    end

                    lib.registerContext({
                        id = 'aura_register_select_customer',
                        title = 'Seleccionar Cliente a Cobrar',
                        options = menuOptions
                    })
                    lib.showContext('aura_register_select_customer')
                end
            end
        },

        -- Opción 2: Abrir Stash de Efectivo y Documentos del Negocio
        {
            name = 'aura_register_open_stash',
            icon = 'fa-solid fa-box-open',
            label = 'Abrir Caja (Efectivo & Stash)',
            distance = 2.0,
            canInteract = function(entity, distance, coords, name)
                local pState = LocalPlayer.state
                local job = pState.job or 'unemployed'
                local isDuty = pState.job_duty == true
                local jobConfig = Config.Jobs[job]
                return isDuty and jobConfig and jobConfig.isBusiness == true
            end,
            onSelect = function(data)
                local entity = data.entity
                if not DoesEntityExist(entity) then return end

                -- Solicitar apertura de la caja central del negocio actual
                lib.callback('aura_jobs:server:openBusinessStash', false, function(allowed, stashId)
                    if allowed and stashId then
                        exports.ox_inventory:openInventory('stash', stashId)
                    else
                        lib.notify({
                            title = 'Acceso Denegado',
                            description = 'No estás de servicio o no perteneces a este negocio.',
                            type = 'error'
                        })
                    end
                end)
            end
        },

        -- Opción 3: Consultar Balance de Empresa
        {
            name = 'aura_register_society_balance',
            icon = 'fa-solid fa-chart-line',
            label = 'Consultar Balance de Empresa',
            distance = 2.0,
            canInteract = function(entity, distance, coords, name)
                local pState = LocalPlayer.state
                local job = pState.job or 'unemployed'
                local isDuty = pState.job_duty == true
                local jobConfig = Config.Jobs[job]
                return isDuty and jobConfig and jobConfig.isBusiness == true
            end,
            onSelect = function(data)
                lib.callback('aura_jobs:server:getSocietyBalance', false, function(success, balance, bizLabel)
                    if success then
                        lib.notify({
                            title = bizLabel,
                            description = string.format("Saldo en tesorería societaria: $%s", lib.math.groupdigits(balance)),
                            type = 'inform'
                        })
                    else
                        lib.notify({
                            title = 'Error',
                            description = tostring(balance),
                            type = 'error'
                        })
                    end
                end)
            end
        }
    })
end)

-- ============================================================================
-- 3. RECEPCIÓN DE FACTURA POR PARTE DEL CLIENTE (APERTURA NUI)
-- ============================================================================

RegisterNetEvent('aura_jobs:client:receiveBill', function(billData)
    if not billData then return end

    isNuiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openBilling',
        data = {
            registerId = billData.billCode or "POS-DIRECT",
            concept = billData.concept,
            amount = billData.amount,
            business = billData.business,
            employee = billData.employee
        }
    })
end)

RegisterNetEvent('aura_jobs:client:closeBilling', function()
    if isNuiOpen then
        isNuiOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
    end
end)

-- ============================================================================
-- 4. NUI CALLBACKS (PAGO DESDE LA INTERFAZ)
-- ============================================================================

-- PAGO CON TARJETA BANCARIA
RegisterNUICallback('payCard', function(data, cb)
    lib.callback('aura_jobs:server:payPlayerBillCard', false, function(success, message)
        if success then
            isNuiOpen = false
            SetNuiFocus(false, false)
            SendNUIMessage({ action = 'close' })
            cb({ success = true })
        else
            local errorMsg = "Error en el débito bancario"
            if message == "SALDO_BANCARIO_INSUFICIENTE" then
                errorMsg = "Saldo bancario insuficiente"
            elseif message == "NO_HAY_FACTURA_PENDIENTE" then
                errorMsg = "La factura ha expirado o ya no está disponible"
            end
            cb({ success = false, message = errorMsg })
        end
    end)
end)

-- PAGO EN EFECTIVO FÍSICO
RegisterNUICallback('payCash', function(data, cb)
    lib.callback('aura_jobs:server:payPlayerBillCash', false, function(success, message)
        if success then
            isNuiOpen = false
            SetNuiFocus(false, false)
            SendNUIMessage({ action = 'close' })
            cb({ success = true })
        else
            local errorMsg = "Error al abonar en efectivo"
            if message == "EFECTIVO_INSUFICIENTE" then
                errorMsg = "No tienes suficiente dinero en efectivo encima"
            elseif message == "NO_HAY_FACTURA_PENDIENTE" then
                errorMsg = "La factura ha expirado o ya no está disponible"
            end
            cb({ success = false, message = errorMsg })
        end
    end)
end)

-- CERRAR / CANCELAR FACTURA
RegisterNUICallback('close', function(_, cb)
    isNuiOpen = false
    SetNuiFocus(false, false)
    lib.callback('aura_jobs:server:cancelPlayerBill', false, function() end)
    cb('ok')
end)
