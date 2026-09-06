RegisterNetEvent('aura_multichar:client:characterUnloaded', client.onLogout)

-- ============================================================================
-- AURA INVENTORY: CLOTHING & APPAREL ENGINE (AuraRP Luxury Style)
-- ============================================================================

local clothingToggles = {
    hat = true,
    mask = true,
    glasses = true,
    ear = true,
    chain = true,
    jacket = true,
    tshirt = true,
    vest = true,
    gloves = true,
    pants = true,
    shoes = true,
    bag = true,
    watch = true,
    bracelet = true
}

local cachedBaseAppearance = nil
local isToggling = false

local function IsPedMale(ped)
    local model = GetEntityModel(ped)
    return model == `mp_m_freemode_01`
end

local function PlayClothingAnimation(dict, anim, duration)
    local ped = cache.ped or PlayerPedId()
    if not DoesEntityExist(ped) or IsPedInAnyVehicle(ped, false) or IsPedFalling(ped) or IsEntityDead(ped) then
        return
    end

    lib.requestAnimDict(dict, 1000)
    TaskPlayAnim(ped, dict, anim, 8.0, 3.0, duration or 600, 51, 0.0, false, false, false)
    Wait(duration or 600)
    RemoveAnimDict(dict)
end

local function EnsureBaseAppearance()
    local ped = cache.ped or PlayerPedId()
    if not cachedBaseAppearance and exports['illenium-appearance'] then
        pcall(function()
            cachedBaseAppearance = exports['illenium-appearance']:getPedAppearance(ped)
        end)
    end
end

local function GetBaseComponent(compIndex)
    EnsureBaseAppearance()
    if cachedBaseAppearance and cachedBaseAppearance.components then
        for _, comp in ipairs(cachedBaseAppearance.components) do
            if comp.component_id == compIndex then
                return comp.drawable, comp.texture
            end
        end
    end
    local ped = cache.ped or PlayerPedId()
    return GetPedDrawableVariation(ped, compIndex), GetPedTextureVariation(ped, compIndex)
end

local function GetBaseProp(propIndex)
    EnsureBaseAppearance()
    if cachedBaseAppearance and cachedBaseAppearance.props then
        for _, prop in ipairs(cachedBaseAppearance.props) do
            if prop.prop_id == propIndex then
                return prop.drawable, prop.texture
            end
        end
    end
    local ped = cache.ped or PlayerPedId()
    return GetPedPropIndex(ped, propIndex), GetPedPropTextureIndex(ped, propIndex)
end

local function SyncClothingToServer()
    local ped = cache.ped or PlayerPedId()
    local currentApp = nil
    if exports['illenium-appearance'] then
        pcall(function()
            currentApp = exports['illenium-appearance']:getPedAppearance(ped)
        end)
    end

    TriggerServerEvent('aura_inventory:server:saveClothingState', currentApp, cachedBaseAppearance, clothingToggles)

    SendNUIMessage({
        action = 'setClothingState',
        state = clothingToggles
    })
end

local function ToggleClothingPiece(pieceType)
    if isToggling then return false end
    isToggling = true

    local ped = cache.ped or PlayerPedId()
    local isMale = IsPedMale(ped)
    EnsureBaseAppearance()

    local currentlyWorn = clothingToggles[pieceType] ~= false
    local newWornState = not currentlyWorn
    clothingToggles[pieceType] = newWornState

    if pieceType == 'hat' then
        CreateThread(function()
            PlayClothingAnimation('mp_masks@standard_car@ds@', 'put_on_mask', 600)
        end)
        Wait(250)
        if newWornState then
            local drawable, texture = GetBaseProp(0)
            if drawable and drawable >= 0 then
                SetPedPropIndex(ped, 0, drawable, texture or 0, false)
            else
                ClearPedProp(ped, 0)
            end
        else
            ClearPedProp(ped, 0)
        end

    elseif pieceType == 'mask' then
        CreateThread(function()
            PlayClothingAnimation('mp_masks@standard_car@ds@', 'put_on_mask', 600)
        end)
        Wait(250)
        if newWornState then
            local drawable, texture = GetBaseComponent(1)
            SetPedComponentVariation(ped, 1, drawable or 0, texture or 0, 0)
        else
            SetPedComponentVariation(ped, 1, 0, 0, 0)
        end

    elseif pieceType == 'glasses' then
        CreateThread(function()
            PlayClothingAnimation('clothingspecs', 'take_off', 550)
        end)
        Wait(250)
        if newWornState then
            local drawable, texture = GetBaseProp(1)
            if drawable and drawable >= 0 then
                SetPedPropIndex(ped, 1, drawable, texture or 0, false)
            else
                ClearPedProp(ped, 1)
            end
        else
            ClearPedProp(ped, 1)
        end

    elseif pieceType == 'ear' then
        CreateThread(function()
            PlayClothingAnimation('mp_cp_stolen_tut', 'b_adjust_earpiece', 500)
        end)
        Wait(200)
        if newWornState then
            local drawable, texture = GetBaseProp(2)
            if drawable and drawable >= 0 then
                SetPedPropIndex(ped, 2, drawable, texture or 0, false)
            else
                ClearPedProp(ped, 2)
            end
        else
            ClearPedProp(ped, 2)
        end

    elseif pieceType == 'chain' then
        CreateThread(function()
            PlayClothingAnimation('clothingtie', 'try_tie_negative_a', 600)
        end)
        Wait(250)
        if newWornState then
            local drawable, texture = GetBaseComponent(7)
            SetPedComponentVariation(ped, 7, drawable or 0, texture or 0, 0)
        else
            SetPedComponentVariation(ped, 7, 0, 0, 0)
        end

    elseif pieceType == 'jacket' then
        CreateThread(function()
            PlayClothingAnimation('clothingtie', 'try_tie_negative_a', 650)
        end)
        Wait(300)
        if newWornState then
            local comp11, tex11 = GetBaseComponent(11)
            local comp3, tex3 = GetBaseComponent(3)
            local comp8, tex8 = GetBaseComponent(8)
            SetPedComponentVariation(ped, 11, comp11 or (isMale and 15 or 15), tex11 or 0, 0)
            SetPedComponentVariation(ped, 3, comp3 or 15, tex3 or 0, 0)
            SetPedComponentVariation(ped, 8, comp8 or (isMale and 15 or 14), tex8 or 0, 0)
        else
            -- Torso desnudo / Sujetador
            SetPedComponentVariation(ped, 11, 15, 0, 0)
            SetPedComponentVariation(ped, 3, 15, 0, 0)
            SetPedComponentVariation(ped, 8, isMale and 15 or 14, 0, 0)
        end

    elseif pieceType == 'tshirt' then
        CreateThread(function()
            PlayClothingAnimation('clothingtie', 'try_tie_negative_a', 600)
        end)
        Wait(250)
        if newWornState then
            local comp8, tex8 = GetBaseComponent(8)
            SetPedComponentVariation(ped, 8, comp8 or (isMale and 15 or 14), tex8 or 0, 0)
        else
            SetPedComponentVariation(ped, 8, isMale and 15 or 14, 0, 0)
        end

    elseif pieceType == 'vest' then
        CreateThread(function()
            PlayClothingAnimation('clothingtie', 'try_tie_negative_a', 600)
        end)
        Wait(250)
        if newWornState then
            local drawable, texture = GetBaseComponent(9)
            SetPedComponentVariation(ped, 9, drawable or 0, texture or 0, 0)
        else
            SetPedComponentVariation(ped, 9, 0, 0, 0)
        end

    elseif pieceType == 'gloves' then
        CreateThread(function()
            PlayClothingAnimation('nmt_3_rcm-10', 'cs_nigel_dual-10', 500)
        end)
        Wait(200)
        if newWornState then
            local comp3, tex3 = GetBaseComponent(3)
            SetPedComponentVariation(ped, 3, comp3 or 15, tex3 or 0, 0)
        else
            SetPedComponentVariation(ped, 3, 15, 0, 0)
        end

    elseif pieceType == 'pants' then
        CreateThread(function()
            PlayClothingAnimation('re@construction', 'out_of_breath', 700)
        end)
        Wait(300)
        if newWornState then
            local comp4, tex4 = GetBaseComponent(4)
            SetPedComponentVariation(ped, 4, comp4 or (isMale and 61 or 15), tex4 or 0, 0)
        else
            -- Boxers / Ropa interior
            SetPedComponentVariation(ped, 4, isMale and 61 or 15, 0, 0)
        end

    elseif pieceType == 'shoes' then
        CreateThread(function()
            PlayClothingAnimation('random@domestic', 'pickup_low', 650)
        end)
        Wait(300)
        if newWornState then
            local comp6, tex6 = GetBaseComponent(6)
            SetPedComponentVariation(ped, 6, comp6 or (isMale and 34 or 35), tex6 or 0, 0)
        else
            -- Descalzo
            SetPedComponentVariation(ped, 6, isMale and 34 or 35, 0, 0)
        end

    elseif pieceType == 'bag' then
        CreateThread(function()
            PlayClothingAnimation('anim@heists@ornate_bank@grab_cash', 'intro', 600)
        end)
        Wait(250)
        if newWornState then
            local drawable, texture = GetBaseComponent(5)
            SetPedComponentVariation(ped, 5, drawable or 0, texture or 0, 0)
        else
            SetPedComponentVariation(ped, 5, 0, 0, 0)
        end

    elseif pieceType == 'watch' then
        CreateThread(function()
            PlayClothingAnimation('nmt_3_rcm-10', 'cs_nigel_dual-10', 500)
        end)
        Wait(200)
        if newWornState then
            local drawable, texture = GetBaseProp(6)
            if drawable and drawable >= 0 then
                SetPedPropIndex(ped, 6, drawable, texture or 0, false)
            else
                ClearPedProp(ped, 6)
            end
        else
            ClearPedProp(ped, 6)
        end

    elseif pieceType == 'bracelet' then
        CreateThread(function()
            PlayClothingAnimation('nmt_3_rcm-10', 'cs_nigel_dual-10', 500)
        end)
        Wait(200)
        if newWornState then
            local drawable, texture = GetBaseProp(7)
            if drawable and drawable >= 0 then
                SetPedPropIndex(ped, 7, drawable, texture or 0, false)
            else
                ClearPedProp(ped, 7)
            end
        else
            ClearPedProp(ped, 7)
        end
    end

    SyncClothingToServer()

    SetTimeout(600, function()
        isToggling = false
    end)

    return true, newWornState
end

-- ============================================================================
-- NUI CALLBACKS (Comunicación instantánea con ox_inventory UI)
-- ============================================================================

RegisterNUICallback('aura_toggleClothing', function(data, cb)
    local pieceType = data and data.type
    if not pieceType then
        return cb({ success = false, state = clothingToggles })
    end

    local success, newState = ToggleClothingPiece(pieceType)
    cb({ success = success, state = clothingToggles })
end)

RegisterNUICallback('aura_getClothingState', function(_, cb)
    EnsureBaseAppearance()
    cb({ success = true, state = clothingToggles })
end)

-- ============================================================================
-- EVENTOS DE CARGA Y SINCRONIZACIÓN DE PERSONAJE
-- ============================================================================

RegisterNetEvent('aura_multichar:client:characterLoaded', function(charData)
    PlayerData.loaded = true
    client.setPlayerData('groups', {})

    if charData and charData.metadata then
        if charData.metadata.base_appearance and next(charData.metadata.base_appearance) ~= nil then
            cachedBaseAppearance = charData.metadata.base_appearance
        elseif charData.metadata.appearance and next(charData.metadata.appearance) ~= nil then
            cachedBaseAppearance = charData.metadata.appearance
        end

        if charData.metadata.clothing_toggles and type(charData.metadata.clothing_toggles) == "table" then
            clothingToggles = charData.metadata.clothing_toggles
        end
    end

    SendNUIMessage({
        action = 'setClothingState',
        state = clothingToggles
    })
end)

RegisterNetEvent('aura_core:playerSpawnedAndReady', function()
    PlayerData.loaded = true
    client.setPlayerData('groups', {})
    EnsureBaseAppearance()
end)

-- Evento cuando el jugador guarda apariencia en tienda / creador
RegisterNetEvent('aura_appearance:client:onAppearanceSaved', function(newAppearance)
    if newAppearance and type(newAppearance) == "table" then
        cachedBaseAppearance = newAppearance
        for k in pairs(clothingToggles) do
            clothingToggles[k] = true
        end
        SendNUIMessage({
            action = 'setClothingState',
            state = clothingToggles
        })
    end
end)

-- ============================================================================
-- EXPORTS PÚBLICOS
-- ============================================================================

exports('ToggleClothing', ToggleClothingPiece)
exports('GetClothingState', function() return clothingToggles end)
exports('SetClothingState', function(toggles) clothingToggles = toggles or clothingToggles end)
exports('SetBaseAppearance', function(appearance) cachedBaseAppearance = appearance end)

-- Comandos directos para abrir el inventario
RegisterCommand('inventory', function()
    if not PlayerData.loaded then
        PlayerData.loaded = true
    end
    client.openInventory()
end, false)

RegisterCommand('inv', function()
    if not PlayerData.loaded then
        PlayerData.loaded = true
    end
    client.openInventory()
end, false)

-- Asignación de tecla por defecto (TAB y F2)
RegisterKeyMapping('inventory', 'Abrir Inventario (Aura)', 'keyboard', 'TAB')

