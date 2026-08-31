local isPhoneOpen = false
local phoneProp = 0

-- Utils para Animación y Prop
local function LoadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
end

local function LoadModel(model)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
end

local function AttachPhoneProp()
    local ped = PlayerPedId()
    local model = joaat('prop_npc_phone_02')
    LoadModel(model)
    
    local coords = GetEntityCoords(ped)
    phoneProp = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)
    
    local bone = GetPedBoneIndex(ped, 28422) -- Mano derecha
    AttachEntityToEntity(phoneProp, ped, bone, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(model)
end

local function RemovePhoneProp()
    if DoesEntityExist(phoneProp) then
        DeleteEntity(phoneProp)
        phoneProp = 0
    end
end

-- Funciones principales del Teléfono
local function TogglePhone(state)
    local ped = PlayerPedId()
    isPhoneOpen = state
    
    if isPhoneOpen then
        LoadAnimDict("cellphone@")
        TaskPlayAnim(ped, "cellphone@", "cellphone_text_in", 4.0, -1, -1, 50, 0, false, false, false)
        AttachPhoneProp()
        
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false) -- Impedir movimiento de cámara
        SendNUIMessage({ action = "openPhone" })
    else
        StopAnimTask(ped, "cellphone@", "cellphone_text_in", 1.0)
        RemovePhoneProp()
        
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "closePhone" })
    end
end

-- Export para abrir desde ox_inventory (ej. usar el item "phone")
exports('openPhone', function()
    if not isPhoneOpen then
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
