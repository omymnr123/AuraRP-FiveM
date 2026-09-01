AuraPhoneClient = AuraPhoneClient or {}
AuraPhoneClient.isPhoneOpen = false
AuraPhoneClient.phoneProp = 0
AuraPhoneClient.isInCall = false

-- Utils para Animación y Prop
function AuraPhoneClient.LoadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
end

function AuraPhoneClient.LoadModel(model)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
end

function AuraPhoneClient.AttachPhoneProp()
    if DoesEntityExist(AuraPhoneClient.phoneProp) then return end
    local ped = PlayerPedId()
    local model = joaat('prop_npc_phone_02')
    AuraPhoneClient.LoadModel(model)
    
    local coords = GetEntityCoords(ped)
    AuraPhoneClient.phoneProp = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)
    
    local bone = GetPedBoneIndex(ped, 28422) -- Mano derecha
    AttachEntityToEntity(AuraPhoneClient.phoneProp, ped, bone, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(model)
end

function AuraPhoneClient.RemovePhoneProp()
    if DoesEntityExist(AuraPhoneClient.phoneProp) then
        DeleteEntity(AuraPhoneClient.phoneProp)
        AuraPhoneClient.phoneProp = 0
    end
end

function AuraPhoneClient.StartCallAnimation()
    local ped = PlayerPedId()
    AuraPhoneClient.isInCall = true
    AuraPhoneClient.LoadAnimDict("cellphone@")
    AuraPhoneClient.AttachPhoneProp()
    
    -- Sacar el teléfono y ponérselo en la oreja
    TaskPlayAnim(ped, "cellphone@", "cellphone_call_in", 3.0, -1, -1, 50, 0, false, false, false)
    
    CreateThread(function()
        Wait(1000)
        if AuraPhoneClient.isInCall then
            TaskPlayAnim(ped, "cellphone@", "cellphone_call_listen_base", 3.0, -1, -1, 49, 0, false, false, false)
        end
    end)
end

function AuraPhoneClient.StopCallAnimation()
    if not AuraPhoneClient.isInCall then return end
    AuraPhoneClient.isInCall = false
    local ped = PlayerPedId()
    
    AuraPhoneClient.LoadAnimDict("cellphone@")
    TaskPlayAnim(ped, "cellphone@", "cellphone_call_out", 3.0, -1, -1, 50, 0, false, false, false)
    
    SetTimeout(600, function()
        StopAnimTask(ped, "cellphone@", "cellphone_call_out", 1.0)
        StopAnimTask(ped, "cellphone@", "cellphone_call_listen_base", 1.0)
        StopAnimTask(ped, "cellphone@", "cellphone_call_in", 1.0)
        
        if not AuraPhoneClient.isPhoneOpen then
            StopAnimTask(ped, "cellphone@", "cellphone_text_in", 1.0)
            ClearPedSecondaryTask(ped)
            AuraPhoneClient.RemovePhoneProp()
        else
            TaskPlayAnim(ped, "cellphone@", "cellphone_text_in", 4.0, -1, -1, 50, 0, false, false, false)
        end
    end)
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        AuraPhoneClient.RemovePhoneProp()
    end
end)

-- Funciones principales del Teléfono
local function TogglePhone(state)
    local ped = PlayerPedId()
    AuraPhoneClient.isPhoneOpen = state
    
    if AuraPhoneClient.isPhoneOpen then
        if not AuraPhoneClient.isInCall then
            AuraPhoneClient.LoadAnimDict("cellphone@")
            TaskPlayAnim(ped, "cellphone@", "cellphone_text_in", 4.0, -1, -1, 50, 0, false, false, false)
            AuraPhoneClient.AttachPhoneProp()
        end
        
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
        SendNUIMessage({ action = "openPhone" })
    else
        if not AuraPhoneClient.isInCall then
            StopAnimTask(ped, "cellphone@", "cellphone_text_in", 1.0)
            AuraPhoneClient.RemovePhoneProp()
        end
        
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "closePhone" })
    end
end

-- Export para abrir desde ox_inventory (ej. usar el item "phone")
exports('openPhone', function()
    if not AuraPhoneClient.isPhoneOpen then
        TogglePhone(true)
    end
end)

-- Keybind provisional / debug (Opcional, se puede quitar y usar solo ox_inventory)
RegisterCommand('auraphone', function()
    TogglePhone(not isPhoneOpen)
end)
RegisterKeyMapping('auraphone', 'Abrir Teléfono', 'keyboard', 'M')

-- ==========================================
-- NUI CALLBACKS (Frontend -> Client -> Server)
-- ==========================================

RegisterNUICallback('close', function(data, cb)
    TogglePhone(false)
    cb('ok')
end)

RegisterNUICallback('getBankBalance', function(data, cb)
    -- Obtener balance desde StateBag generado por aura_economy
    local moneyState = LocalPlayer.state.money
    local bank = moneyState and moneyState.bank or 0
    cb({ balance = bank })
end)

RegisterNUICallback('bankTransfer', function(data, cb)
    -- Reenviar al servidor para validación segura
    lib.callback('aura_phone:server:bankTransfer', false, function(success, msg)
        cb({ success = success, message = msg })
    end, data.targetId, data.amount, data.reason)
end)
