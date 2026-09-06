local CurrentInsulation = 25.0
local lastCheckedDrawables = {}
local lastCheckedProps = {}

-- ============================================================================
-- HEURÍSTICAS DE AISLAMIENTO TÉRMICO (GTA V FREEMODE + EUP + EMERGENCY EUP)
-- ============================================================================

-- 1. Componente 11: Tops / Chaquetas / Uniformes / Parkas / Bomberos
local function EvaluateTopInsulation(ped, isMale)
    local drawable = GetPedDrawableVariation(ped, 11)
    if ClothingCatalog and ClothingCatalog.GetTopScore then
        return ClothingCatalog.GetTopScore(drawable, isMale)
    end
    if drawable < 0 or drawable == 15 then return 0.0 end
    return 30.0
end

-- 2. Componente 9: Chalecos Antibalas / Porta-Placas Tácticos / Chalecos Reflectantes EUP
local function EvaluateBodyArmorInsulation(ped)
    local drawable = GetPedDrawableVariation(ped, 9)
    if ClothingCatalog and ClothingCatalog.GetBodyArmorScore then
        return ClothingCatalog.GetBodyArmorScore(drawable)
    end
    if drawable <= 0 or drawable == 15 or drawable == -1 then return 0.0 end
    return 12.0
end

-- 3. Componente 3: Brazos / Torso 1 / Mangas / Guantes Térmicos
local function EvaluateArmsInsulation(ped, isMale)
    local drawable = GetPedDrawableVariation(ped, 3)
    if ClothingCatalog and ClothingCatalog.GetArmsScore then
        return ClothingCatalog.GetArmsScore(drawable, isMale)
    end
    if drawable < 0 or drawable == 15 or drawable == 0 then return 0.0 end
    return 12.0
end

-- 4. Componente 4: Pantalones / Piernas / Pantalones de Nieve y Bomberos
local function EvaluatePantsInsulation(ped, isMale)
    local drawable = GetPedDrawableVariation(ped, 4)
    if ClothingCatalog and ClothingCatalog.GetPantsScore then
        return ClothingCatalog.GetPantsScore(drawable, isMale)
    end
    if drawable < 0 or drawable == 15 then return 0.0 end
    return 15.0
end

-- 5. Componente 8: Camisetas Interiores / Undershirts / Polos de Servicio
local function EvaluateUndershirtInsulation(ped, isMale)
    local drawable = GetPedDrawableVariation(ped, 8)
    if ClothingCatalog and ClothingCatalog.GetUndershirtScore then
        return ClothingCatalog.GetUndershirtScore(drawable, isMale)
    end
    if drawable < 0 or drawable == 15 then return 0.0 end
    return 5.0
end

-- 6. Componente 6: Calzado / Botas Tácticas / Botas de Nieve y Bomberos
local function EvaluateFootwearInsulation(ped, isMale)
    local drawable = GetPedDrawableVariation(ped, 6)
    if ClothingCatalog and ClothingCatalog.GetShoesScore then
        return ClothingCatalog.GetShoesScore(drawable, isMale)
    end
    if drawable < 0 or drawable == 34 or drawable == 35 or drawable == 5 then return 0.0 end
    return 3.0
end

-- 7. Componente 7: Accesorios de Cuello / Bufandas / Shemagh
local function EvaluateNeckInsulation(ped)
    local drawable = GetPedDrawableVariation(ped, 7)
    if ClothingCatalog and ClothingCatalog.GetNeckScore then
        return ClothingCatalog.GetNeckScore(drawable)
    end
    if drawable <= 0 or drawable == -1 or drawable == 15 then return 0.0 end
    return 1.0
end

-- 8. Componente 1 (Máscaras/Pasamontañas) y Prop 0 (Cascos/Gorros/Beanies)
local function EvaluateHeadgearInsulation(ped, isMale)
    local maskDrawable = GetPedDrawableVariation(ped, 1)
    local hatProp = GetPedPropIndex(ped, 0)
    if ClothingCatalog and ClothingCatalog.GetHeadScore then
        return ClothingCatalog.GetHeadScore(maskDrawable, hatProp, isMale)
    end
    return 0.0
end

-- ============================================================================
-- CÁLCULO INTEGRAL DE AISLAMIENTO (0 a 100)
-- ============================================================================

local function RecalculateInsulation()
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return 0.0 end

    local model = GetEntityModel(ped)
    local isMale = (model == `mp_m_freemode_01`)
    local isFemale = (model == `mp_f_freemode_01`)

    if not isMale and not isFemale then
        CurrentInsulation = 25.0
        return CurrentInsulation
    end

    local topScore = EvaluateTopInsulation(ped, isMale)          -- Max 45
    local armorScore = EvaluateBodyArmorInsulation(ped)          -- Max 18 (EUP / Chalecos)
    local armsScore = EvaluateArmsInsulation(ped, isMale)        -- Max 20
    local pantsScore = EvaluatePantsInsulation(ped, isMale)      -- Max 20
    local underScore = EvaluateUndershirtInsulation(ped, isMale) -- Max 10
    local shoeScore = EvaluateFootwearInsulation(ped, isMale)    -- Max 5
    local neckScore = EvaluateNeckInsulation(ped)                -- Max 5
    local headScore = EvaluateHeadgearInsulation(ped, isMale)    -- Max 12

    -- Si no lleva parte superior (torso desnudo), los brazos no pueden dar aislamiento de manga larga
    if topScore == 0.0 then
        armsScore = 0.0
        if underScore <= 5.0 then
            underScore = 0.0
        end
    end

    -- Si el personaje está completamente desvestido (sin torso ni pantalones ni chaleco)
    if topScore == 0.0 and pantsScore == 0.0 and armorScore == 0.0 then
        if shoeScore <= 3.0 and neckScore <= 1.0 and headScore == 0.0 then
            armsScore = 0.0
            underScore = 0.0
            shoeScore = 0.0
            neckScore = 0.0
        end
    end

    local total = topScore + armorScore + armsScore + pantsScore + underScore + shoeScore + neckScore + headScore
    CurrentInsulation = math.max(0.0, math.min(100.0, total))

    return CurrentInsulation
end

-- Comprobar si ha cambiado alguna prenda en el ped (Multi-Component Watcher)
local function HasOutfitChanged(ped)
    local components = { 1, 3, 4, 5, 6, 7, 8, 9, 10, 11 }
    local hasChanged = false

    for _, compId in ipairs(components) do
        local draw = GetPedDrawableVariation(ped, compId)
        if lastCheckedDrawables[compId] ~= draw then
            lastCheckedDrawables[compId] = draw
            hasChanged = true
        end
    end

    local props = { 0, 1, 2, 6, 7 }
    for _, propId in ipairs(props) do
        local propIdx = GetPedPropIndex(ped, propId)
        if lastCheckedProps[propId] ~= propIdx then
            lastCheckedProps[propId] = propIdx
            hasChanged = true
        end
    end

    return hasChanged
end

-- ============================================================================
-- EVENT LISTENERS & PUENTE CON ILLENIUM-APPEARANCE, EUP & EMERGENCYEUP
-- ============================================================================

local function OnOutfitUpdated()
    Wait(200)
    RecalculateInsulation()
end

-- Eventos de illenium-appearance
RegisterNetEvent('illenium-appearance:client:changeOutfit', OnOutfitUpdated)
RegisterNetEvent('illenium-appearance:client:loadJobOutfit', OnOutfitUpdated)
RegisterNetEvent('illenium-appearance:client:reloadSkin', OnOutfitUpdated)
RegisterNetEvent('illenium-appearance:client:outfitApplied', OnOutfitUpdated)
RegisterNetEvent('illenium-appearance:client:loadPlayerSkin', OnOutfitUpdated)
RegisterNetEvent('illenium-appearance:client:migration:load-qb-clothing-clothes', OnOutfitUpdated)

-- Eventos de EUP y EmergencyEUP
RegisterNetEvent('eup:client:setOutfit', OnOutfitUpdated)
RegisterNetEvent('eup-ui:setOutfit', OnOutfitUpdated)
RegisterNetEvent('eup:setOutfit', OnOutfitUpdated)
RegisterNetEvent('eup_ui:client:setOutfit', OnOutfitUpdated)
RegisterNetEvent('EmergencyEUP:client:setOutfit', OnOutfitUpdated)

-- Eventos de facciones y servicios de emergencia
RegisterNetEvent('aura_police:client:outfitChanged', OnOutfitUpdated)
RegisterNetEvent('aura_jobs:client:uniformApplied', OnOutfitUpdated)

-- Eventos de spawn e inicialización
AddEventHandler('playerSpawned', OnOutfitUpdated)
RegisterNetEvent('aura_core:client:playerSpawned', OnOutfitUpdated)
RegisterNetEvent('aura_multichar:client:characterLoaded', OnOutfitUpdated)

-- Bucle periódico ultra-rápido (cada 500ms) que garantiza detección del 100% de EUP
CreateThread(function()
    while true do
        Wait(500)
        local ped = PlayerPedId()
        if DoesEntityExist(ped) and HasOutfitChanged(ped) then
            RecalculateInsulation()
        end
    end
end)

-- ============================================================================
-- EXPORTS
-- ============================================================================

exports('GetInsulation', function()
    return CurrentInsulation
end)

exports('RecalculateInsulation', function()
    return RecalculateInsulation()
end)

exports('GetInsulationBreakdown', function()
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return {} end
    local model = GetEntityModel(ped)
    local isMale = (model == `mp_m_freemode_01`)
    local isFemale = (model == `mp_f_freemode_01`)
    return {
        total = CurrentInsulation,
        top = { id = GetPedDrawableVariation(ped, 11), score = EvaluateTopInsulation(ped, isMale) },
        armor = { id = GetPedDrawableVariation(ped, 9), score = EvaluateBodyArmorInsulation(ped) },
        arms = { id = GetPedDrawableVariation(ped, 3), score = EvaluateArmsInsulation(ped, isMale) },
        pants = { id = GetPedDrawableVariation(ped, 4), score = EvaluatePantsInsulation(ped, isMale) },
        undershirt = { id = GetPedDrawableVariation(ped, 8), score = EvaluateUndershirtInsulation(ped, isMale) },
        shoes = { id = GetPedDrawableVariation(ped, 6), score = EvaluateFootwearInsulation(ped, isMale) },
        neck = { id = GetPedDrawableVariation(ped, 7), score = EvaluateNeckInsulation(ped) },
        head = { maskId = GetPedDrawableVariation(ped, 1), prop0 = GetPedPropIndex(ped, 0), score = EvaluateHeadgearInsulation(ped, isMale) }
    }
end)
