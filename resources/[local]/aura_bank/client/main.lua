local currentTargetCharId = nil
local currentPendingCard = nil

-- Utilidad: Animación ATM
local function playAtmAnimation()
    lib.requestAnimDict('amb@prop_human_atm@male@enter')
    TaskPlayAnim(cache.ped, 'amb@prop_human_atm@male@enter', 'enter', 8.0, 8.0, -1, 50, 0, false, false, false)
    Wait(3000)
    ClearPedTasks(cache.ped)
end

-- Interacción con Cajero (Teller)
local function openTellerMenu()
    local success, data = lib.callback.await('aura_bank:tellerLogin', false)
    if not success then
        lib.notify({ title = 'Banco', description = data, type = 'error' })
        return
    end

    currentTargetCharId = data.targetCharId
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openUI',
        data = {
            iban = data.iban,
            cash = data.accounts.cash or 0,
            bank = data.accounts.bank or 0,
            savings = data.accounts.savings or 0,
            name = data.name or "Desconocido",
            isBoss = data.isBoss or false,
            society = data.society or nil
        }
    })
end

-- Interacción con ATM
local function interactAtm()
    local hasItem = exports.ox_inventory:Search('count', 'credit_card')
    if hasItem < 1 then
        lib.notify({ title = 'ATM', description = 'No tienes una tarjeta de crédito.', type = 'error' })
        return
    end

    -- Obtener la tarjeta del inventario (asumimos la primera si hay varias, ox_inventory search devuelve count, usamos Items)
    local items = exports.ox_inventory:Search('slots', 'credit_card')
    local card = items and items[1]
    
    if not card or not card.metadata or not card.metadata.iban then
        lib.notify({ title = 'ATM', description = 'Tarjeta defectuosa o sin IBAN.', type = 'error' })
        return
    end

    playAtmAnimation()

    currentPendingCard = card

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'requestPin'
    })
end

-- Setup Targets, Blips y NPCs
local spawnedPeds = {}

CreateThread(function()
    -- ATMs
    exports.ox_target:addModel(Config.ATMModels, {
        {
            name = 'aura_bank:atm',
            icon = 'fas fa-credit-card',
            label = 'Usar Cajero Automático',
            onSelect = interactAtm,
            distance = 2.0
        }
    })

    -- Tellers (NPCs), Blips y Targets
    for i, data in ipairs(Config.BankTellers) do
        -- Crear Blip
        local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
        SetBlipSprite(blip, 108) -- Banco
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 2) -- Verde
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Banco")
        EndTextCommandSetBlipName(blip)

        -- Generar el Ped (NPC)
        lib.requestModel(data.model)
        -- Restamos 1.0 a Z para que toque el suelo si la coordenada fue tomada de un jugador
        local ped = CreatePed(4, data.model, data.coords.x, data.coords.y, data.coords.z - 1.0, data.heading, false, true)
        SetEntityAsMissionEntity(ped, true, true)
        SetEntityHeading(ped, data.heading)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetModelAsNoLongerNeeded(data.model)
        
        table.insert(spawnedPeds, ped)

        -- Asignar el target de ox_target SÓLO a esta entidad recién creada
        exports.ox_target:addLocalEntity(ped, {
            {
                name = 'aura_bank:teller_' .. i,
                icon = 'fas fa-building-columns',
                label = 'Hablar con el Cajero',
                onSelect = openTellerMenu,
                distance = 3.0
            }
        })
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
end)

-- Callbacks NUI
RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    currentTargetCharId = nil
    currentPendingCard = nil
    cb('ok')
end)

RegisterNUICallback('submitPin', function(data, cb)
    if not currentPendingCard then 
        cb('ok')
        return
    end
    
    local pin = data.pin
    if not pin then
        -- User closed or cancelled PIN
        SetNuiFocus(false, false)
        currentPendingCard = nil
        cb('ok')
        return
    end

    local success, response = lib.callback.await('aura_bank:verifyPin', false, pin, currentPendingCard.metadata)
    
    if success then
        currentTargetCharId = response.targetCharId
        SendNUIMessage({
            action = 'openUI',
            data = {
                iban = response.iban,
                cash = response.accounts.cash or 0,
                bank = response.accounts.bank or 0,
                savings = response.accounts.savings or 0,
                name = response.name or "Desconocido",
                isBoss = response.isBoss or false,
                society = response.society or nil
            }
        })
    else
        SetNuiFocus(false, false)
        lib.notify({ title = 'ATM', description = response, type = 'error' })
    end
    
    currentPendingCard = nil
    cb('ok')
end)

RegisterNUICallback('corporateDeposit', function(data, cb)
    local amount = tonumber(data.amount)
    if not amount or amount <= 0 then
        cb({ success = false, message = "Importe inválido" })
        return
    end

    local success, msg, newBalance = lib.callback.await('aura_bank:corporateDeposit', false, amount)
    cb({ success = success, message = msg, newBalance = newBalance })
end)

RegisterNUICallback('corporateWithdraw', function(data, cb)
    local amount = tonumber(data.amount)
    if not amount or amount <= 0 then
        cb({ success = false, message = "Importe inválido" })
        return
    end

    local success, msg, newBalance = lib.callback.await('aura_bank:corporateWithdraw', false, amount)
    cb({ success = success, message = msg, newBalance = newBalance })
end)

RegisterNUICallback('fetchCorporateData', function(data, cb)
    local data = lib.callback.await('aura_bank:getCorporateData', false)
    cb(data)
end)

RegisterNUICallback('doTransaction', function(data, cb)
    if not currentTargetCharId then
        cb({ success = false, message = "Sesión inválida" })
        return
    end

    local type = data.type -- 'withdraw', 'deposit', 'transfer'
    local amount = data.amount
    local targetIban = data.targetIban

    local success, message = lib.callback.await('aura_bank:doTransaction', false, currentTargetCharId, type, amount, targetIban)
    
    -- Si tuvo éxito, actualizar UI
    if success then
        local _, res = lib.callback.await('aura_bank:tellerLogin', false) -- Truco rápido para obtener saldos
        if res then
            SendNUIMessage({
                action = 'updateBalance',
                cash = res.accounts.cash or 0,
                bank = res.accounts.bank or 0,
                savings = res.accounts.savings or 0
            })
        end
    end

    cb({ success = success, message = message })
end)

RegisterNUICallback('fetchTransactions', function(data, cb)
    if not currentTargetCharId then
        cb({})
        return
    end
    local txs = lib.callback.await('aura_bank:getTransactions', false, currentTargetCharId)
    cb(txs)
end)

RegisterNUICallback('fetchChartData', function(data, cb)
    if not currentTargetCharId then
        cb({labels = {}, data = {}})
        return
    end
    local chart = lib.callback.await('aura_bank:getChartData', false, currentTargetCharId)
    cb(chart)
end)

RegisterNUICallback('requestCard', function(data, cb)
    local emitSuccess, msg = lib.callback.await('aura_bank:requestCard', false)
    cb({ success = emitSuccess, message = msg })
end)

RegisterNUICallback('changePin', function(data, cb)
    if not currentTargetCharId then
        cb({ success = false, message = "Sesión inválida" })
        return
    end
    local success, msg = lib.callback.await('aura_bank:changePin', false, currentTargetCharId, data.pin)
    cb({ success = success, message = msg })
end)

-- Utilidad para que el administrador pueda copiar las coordenadas y rotación directamente al portapapeles
RegisterCommand('coords', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    
    local coordString = string.format("coords = vec3(%.2f, %.2f, %.2f), heading = %.2f", coords.x, coords.y, coords.z, heading)
    
    -- Imprimir siempre en la consola F8
    print("====================================")
    print("COORDENADAS (Copia lo de abajo):")
    print(coordString)
    print("====================================")
    
    if lib and lib.setClipboard then
        lib.setClipboard(coordString)
        lib.notify({ title = 'Coordenadas Copiadas y en F8', description = coordString, type = 'success', duration = 5000 })
    end
end, false)
