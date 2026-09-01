-- ============================================================================
-- AURA JOBS: REFACTORED UNIVERSAL BILLING & STASH SERVER CONTROLLER
-- Player-to-Player Direct Billing + Centralized Society Stashes
-- ============================================================================

local ActiveCustomerBills = {}   -- [customerSrc] = { billCode, concept, amount, emitterSrc, emitterCharId, emitterName, job, jobLabel, createdAt }
local RegisteredBusinessStashes = {}

-- ============================================================================
-- REGISTRO DE STASHES CENTRALIZADOS DE NEGOCIOS EN OX_INVENTORY
-- ============================================================================

local function RegisterBusinessStash(jobName)
    local stashId = "register_" .. tostring(jobName)
    if not RegisteredBusinessStashes[stashId] then
        local jobConfig = Config.Jobs[jobName]
        local label = (jobConfig and jobConfig.label or string.upper(jobName)) .. " - Caja Registradora"

        exports.ox_inventory:RegisterStash(
            stashId,
            label,
            Config.RegisterStash.slots or 20,
            Config.RegisterStash.maxWeight or 50000,
            nil, -- Sin owner individual (abierto para empleados autorizados de servicio)
            nil,
            nil
        )
        RegisteredBusinessStashes[stashId] = true

        if Config.Debug then
            print(string.format("[Aura Jobs Billing] Stash centralizado registrado en ox_inventory: %s (%s)", stashId, label))
        end
    end
    return stashId
end

-- Inicializar stashes para todos los negocios al arrancar el recurso
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for jobName, jobData in pairs(Config.Jobs) do
        if jobData.isBusiness then
            RegisterBusinessStash(jobName)
        end
    end
end)

-- ============================================================================
-- EMISIÓN DE FACTURA (JUGADOR A JUGADOR)
-- ============================================================================

lib.callback.register('aura_jobs:server:sendPlayerBill', function(source, data)
    local emitterSrc = source
    if not data or not data.targetSrc or not data.concept or not data.amount then
        return false, "PARAMETROS_INVALIDOS"
    end

    local targetSrc = tonumber(data.targetSrc)
    local amount = tonumber(data.amount)

    if not targetSrc or not GetPlayerName(tostring(targetSrc)) then
        return false, "CLIENTE_NO_DISPONIBLE"
    end

    if targetSrc == emitterSrc then
        return false, "NO_PUEDES_FACTURARTE_A_TI_MISMO"
    end

    if not amount or amount <= 0 then
        return false, "IMPORTE_INVALIDO"
    end

    -- 1. Validar permisos del empleado
    local pState = Player(emitterSrc).state
    local jobName = pState.job or 'unemployed'
    local isDuty = pState.job_duty == true
    local jobConfig = Config.Jobs[jobName]

    if not jobConfig or not jobConfig.isBusiness or not isDuty then
        return false, "NO_ESTAS_DE_SERVICIO_O_EMPRESA_INVALIDA"
    end

    -- 2. Validación de proximidad física
    local emitterPed = GetPlayerPed(emitterSrc)
    local targetPed = GetPlayerPed(targetSrc)
    local emitterCoords = GetEntityCoords(emitterPed)
    local targetCoords = GetEntityCoords(targetPed)

    if #(emitterCoords - targetCoords) > 10.0 then
        return false, "CLIENTE_DEMASIADO_LEJOS"
    end

    -- 3. Asegurar que el negocio tiene su stash registrado
    RegisterBusinessStash(jobName)

    -- 4. Obtener identidad del empleado
    local activeChar = exports.aura_multichar:GetActiveCharacter(emitterSrc)
    local emitterName = activeChar and string.format("%s %s", activeChar.firstname or "", activeChar.lastname or "") or "Empleado"
    local billCode = string.format("FAC-%d-%s", os.time() % 10000, string.upper(string.sub(jobName, 1, 3)))

    -- 5. Cachear la factura pendiente en el cliente receptor
    ActiveCustomerBills[targetSrc] = {
        billCode = billCode,
        concept = tostring(data.concept),
        amount = math.floor(amount),
        emitterSrc = emitterSrc,
        emitterCharId = activeChar and activeChar.id or nil,
        emitterName = emitterName,
        job = jobName,
        jobLabel = jobConfig.label,
        createdAt = os.time()
    }

    -- 6. Disparar NUI directamente al cliente
    TriggerClientEvent('aura_jobs:client:receiveBill', targetSrc, {
        billCode = billCode,
        concept = data.concept,
        amount = math.floor(amount),
        business = jobConfig.label,
        employee = emitterName
    })

    -- 7. Notificar al empleado emisor
    TriggerClientEvent('ox_lib:notify', emitterSrc, {
        title = 'Factura Emitida',
        description = string.format("Has enviado una factura de $%s a %s. Esperando pago...", lib.math.groupdigits(amount), GetPlayerName(tostring(targetSrc))),
        type = 'inform'
    })

    return true, "BILL_SENT"
end)

-- ============================================================================
-- APERTURA DE CAJA REGISTRADORA FÍSICA (STASH CENTRAL DE LA EMPRESA)
-- ============================================================================

lib.callback.register('aura_jobs:server:openBusinessStash', function(source)
    local src = source
    local pState = Player(src).state
    local jobName = pState.job or 'unemployed'
    local isDuty = pState.job_duty == true
    local jobConfig = Config.Jobs[jobName]

    if not jobConfig or not jobConfig.isBusiness or not isDuty then
        return false, "UNAUTHORIZED"
    end

    local stashId = RegisterBusinessStash(jobName)
    return true, stashId
end)

-- ============================================================================
-- RESOLUCIÓN DE PAGOS (CLIENTE -> BANCO O DEPÓSITO DIRECTO EN CAJA)
-- ============================================================================

-- PAGO CON TARJETA BANCARIA
lib.callback.register('aura_jobs:server:payPlayerBillCard', function(source)
    local customerSrc = source
    local bill = ActiveCustomerBills[customerSrc]

    if not bill then
        return false, "NO_HAY_FACTURA_PENDIENTE"
    end

    local amount = bill.amount

    -- 1. Verificar balance bancario del cliente en aura_economy
    local clientBank = exports.aura_economy:GetMoney(customerSrc, 'bank') or 0
    if clientBank < amount then
        return false, "SALDO_BANCARIO_INSUFICIENTE"
    end

    -- 2. Débito atómico bancario del cliente
    local debited, _, txId = exports.aura_economy:RemoveMoney(
        customerSrc,
        'bank',
        amount,
        string.format("Pago TPV: %s (%s)", bill.concept, bill.jobLabel),
        {
            billCode = bill.billCode,
            business = bill.job,
            emitterCharId = bill.emitterCharId
        }
    )

    if not debited then
        return false, "ERROR_DEBITO_BANCARIO"
    end

    -- 3. Acreditar el 100% de los fondos a la cuenta societaria del negocio
    exports.aura_jobs:AddSocietyMoney(
        bill.job,
        amount,
        string.format("Cobro Factura #%s: %s (Cliente ID #%d)", bill.billCode, bill.concept, customerSrc),
        {
            txId = txId,
            customerSrc = customerSrc,
            emitterSrc = bill.emitterSrc
        }
    )

    -- 4. Limpiar factura activa
    ActiveCustomerBills[customerSrc] = nil

    -- 5. Notificaciones de éxito
    TriggerClientEvent('ox_lib:notify', customerSrc, {
        title = 'Pago Completado',
        description = string.format("Has pagado $%s con tarjeta bancaria por '%s'.", lib.math.groupdigits(amount), bill.concept),
        type = 'success'
    })

    if bill.emitterSrc and GetPlayerName(tostring(bill.emitterSrc)) then
        TriggerClientEvent('ox_lib:notify', bill.emitterSrc, {
            title = 'Factura Cobrada (Tarjeta)',
            description = string.format("El cliente ha abonado $%s por '%s'. Fondos transferidos a la sociedad.", lib.math.groupdigits(amount), bill.concept),
            type = 'success'
        })
    end

    return true, "PAYMENT_SUCCESS"
end)

-- PAGO EN EFECTIVO FÍSICO (BYPASS DIRECTO AL STASH CENTRAL DE LA EMPRESA)
lib.callback.register('aura_jobs:server:payPlayerBillCash', function(source)
    local customerSrc = source
    local bill = ActiveCustomerBills[customerSrc]

    if not bill then
        return false, "NO_HAY_FACTURA_PENDIENTE"
    end

    local amount = bill.amount
    local cashItem = Config.CashItem or 'money'

    -- 1. Verificar efectivo en inventario del cliente
    local clientCash = exports.ox_inventory:Search(customerSrc, 'count', cashItem) or 0
    if clientCash < amount then
        return false, "EFECTIVO_INSUFICIENTE"
    end

    -- 2. Retirar efectivo del cliente
    local removed = exports.ox_inventory:RemoveItem(customerSrc, cashItem, amount)
    if not removed then
        return false, "ERROR_RETIRADA_EFECTIVO"
    end

    -- 3. Depositar DIRECTAMENTE en el stash central del negocio (EL EMPLEADO NUNCA RECIBE EL EFECTIVO EN MANO)
    local stashId = RegisterBusinessStash(bill.job)
    local added = exports.ox_inventory:AddItem(stashId, cashItem, amount)

    if not added then
        -- Rollback de emergencia al cliente si falla el depósito en el stash
        exports.ox_inventory:AddItem(customerSrc, cashItem, amount)
        return false, "ERROR_DEPOSITO_STASH"
    end

    -- 4. Limpiar factura activa
    ActiveCustomerBills[customerSrc] = nil

    -- 5. Notificaciones de éxito
    TriggerClientEvent('ox_lib:notify', customerSrc, {
        title = 'Pago en Efectivo',
        description = string.format("Has pagado $%s en efectivo por '%s'.", lib.math.groupdigits(amount), bill.concept),
        type = 'success'
    })

    if bill.emitterSrc and GetPlayerName(tostring(bill.emitterSrc)) then
        TriggerClientEvent('ox_lib:notify', bill.emitterSrc, {
            title = 'Factura Cobrada (Efectivo)',
            description = string.format("El cliente ha abonado $%s en efectivo. El dinero se encuentra depositado en la caja de la empresa.", lib.math.groupdigits(amount)),
            type = 'success'
        })
    end

    return true, "PAYMENT_SUCCESS"
end)

-- CANCELACIÓN DE FACTURA POR PARTE DEL CLIENTE O TIMEOUT
lib.callback.register('aura_jobs:server:cancelPlayerBill', function(source)
    local customerSrc = source
    local bill = ActiveCustomerBills[customerSrc]

    if bill then
        if bill.emitterSrc and GetPlayerName(tostring(bill.emitterSrc)) then
            TriggerClientEvent('ox_lib:notify', bill.emitterSrc, {
                title = 'Factura Cancelada',
                description = 'El cliente ha cancelado la factura emitida.',
                type = 'inform'
            })
        end
        ActiveCustomerBills[customerSrc] = nil
    end

    return true
end)

-- Limpieza automática en caso de desconexión
AddEventHandler('playerDropped', function()
    local src = source
    if ActiveCustomerBills[src] then
        local bill = ActiveCustomerBills[src]
        if bill.emitterSrc and GetPlayerName(tostring(bill.emitterSrc)) then
            TriggerClientEvent('ox_lib:notify', bill.emitterSrc, {
                title = 'Factura Cancelada',
                description = 'El cliente se ha desconectado del servidor.',
                type = 'error'
            })
        end
        ActiveCustomerBills[src] = nil
    end
end)
