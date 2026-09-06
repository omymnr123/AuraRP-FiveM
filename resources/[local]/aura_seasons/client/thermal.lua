local CurrentInsulation = 25.0
local lastCheckedDrawables = {}
local lastCheckedProps = {}

-- ============================================================================
-- HEURÍSTICAS DE AISLAMIENTO TÉRMICO (GTA V FREEMODE + EUP + EMERGENCY EUP)
-- ============================================================================

-- 1. Componente 11: Tops / Chaquetas / Uniformes / Parkas / Bomberos
local function EvaluateTopInsulation(ped, isMale)
    local drawable = GetPedDrawableVariation(ped, 11)
    if drawable <= 0 or drawable == 15 or drawable == -1 then 
        return 0.0 -- Desnudo superior
    end

    if isMale then
        -- Torso Desnudo / Tirantes ligeros / Sin camiseta / Tatuajes al aire
        if drawable == 15 or drawable == 16 or drawable == 18 or drawable == 21 or drawable == 22 or drawable == 34 or drawable == 35 or drawable == 57 or drawable == 91 or drawable == 252 then
            return 0.0
        -- Camisetas cortas / Polos finos / Camisas de manga corta LSPD/BCSO (EUP)
        elseif (drawable >= 1 and drawable <= 14) or (drawable >= 23 and drawable <= 33) or (drawable >= 40 and drawable <= 55) or drawable == 73 or drawable == 74 or drawable == 150 or drawable == 151 or drawable == 250 then
            return 18.0
        -- Uniformes de manga larga LSPD/BCSO / Sudaderas / Blazers / Chaquetas ligeras / Cazadoras
        elseif (drawable >= 56 and drawable <= 85) or (drawable >= 100 and drawable <= 130) or (drawable >= 140 and drawable <= 170) or drawable == 144 then
            return 32.0
        -- Parkas polares / Abrigos pesados / Chaquetones de plumas / Cazadoras de nieve / Cuero de motorista SAHP / Trajes de Bombero (Turnout/Bunker Gear) / Chaquetón de nieve BCSO
        else
            return 45.0
        end
    else
        -- Femenino: Bikinis / Tops cortos / Espalda descubierta / Desnuda
        if drawable == 14 or drawable == 15 or drawable == 17 or drawable == 18 or drawable == 24 or drawable == 26 or drawable == 86 or drawable == 101 then
            return 0.0
        -- Camisetas / Blusas / Camisas de manga corta EUP
        elseif (drawable >= 1 and drawable <= 13) or (drawable >= 27 and drawable <= 45) or (drawable >= 70 and drawable <= 85) or drawable == 147 then
            return 18.0
        -- Chaquetas / Cárdigans / Sudaderas / Uniformes de manga larga
        elseif (drawable >= 46 and drawable <= 69) or (drawable >= 90 and drawable <= 125) or (drawable >= 140 and drawable <= 170) then
            return 32.0
        -- Abrigos largos / Parkas de invierno / Plumíferos / Trajes de Bombero / Chaquetones EUP
        else
            return 45.0
        end
    end
end

-- 2. Componente 9: Chalecos Antibalas / Porta-Placas Tácticos / Chalecos Reflectantes EUP
local function EvaluateBodyArmorInsulation(ped)
    local drawable = GetPedDrawableVariation(ped, 9)
    if drawable <= 0 or drawable == 15 or drawable == -1 then
        return 0.0 -- Sin chaleco / Sin protección
    -- Arnés ligero / Funda de pistola / Cartuchera / Placa en pecho
    elseif drawable == 1 or drawable == 2 or drawable == 16 then
        return 4.0
    -- Chaleco antibalas reglamentario LSPD/BCSO / Chaleco de tráfico reflectante
    elseif (drawable >= 3 and drawable <= 14) or (drawable >= 17 and drawable <= 23) then
        return 12.0
    -- Chaleco Táctico SWAT pesado / Porta-placas militar / Arnés de bombero / Equipo EOD pesado
    else
        return 18.0
    end
end

-- 3. Componente 3: Brazos / Torso 1 / Mangas / Guantes Térmicos
local function EvaluateArmsInsulation(ped, isMale)
    local drawable = GetPedDrawableVariation(ped, 3)
    if drawable <= 15 or drawable == -1 then return 0.0 end

    if (drawable >= 16 and drawable <= 40) or drawable == 8 then
        return 12.0 -- Manga larga estándar / Camisa policial
    elseif drawable > 40 then
        return 20.0 -- Guantes tácticos / Mangas acolchadas / Guantes térmicos de bombero
    end

    return 0.0
end

-- 4. Componente 4: Pantalones / Piernas / Pantalones de Nieve y Bomberos
local function EvaluatePantsInsulation(ped, isMale)
    local drawable = GetPedDrawableVariation(ped, 4)
    if drawable == -1 or drawable == 15 then return 0.0 end

    if isMale then
        -- Bañadores / Calzoncillos / Ropa interior / Boxers / Piernas desnudas (0% de aislamiento de piernas)
        if drawable == 14 or drawable == 15 or drawable == 16 or drawable == 17 or drawable == 18 or drawable == 20 or drawable == 21 or drawable == 26 or drawable == 56 or drawable == 61 or drawable == 65 or (drawable >= 87 and drawable <= 146) then
            return 0.0
        -- Vaqueros estándar / Pantalones de traje / Pantalones de servicio LSPD/BCSO (EUP)
        elseif (drawable >= 0 and drawable <= 13) or (drawable >= 22 and drawable <= 38) or (drawable >= 40 and drawable <= 55) then
            return 15.0
        -- Pantalones de nieve acolchados / Monos de esquí / Pantalones de Bombero (Bunker Pants) / BDU Táctico SWAT
        else
            return 20.0
        end
    else
        -- Faldas cortas / Shorts / Ropa interior / Bikinis / Piernas desnudas (0% de aislamiento)
        if drawable == 14 or drawable == 15 or drawable == 16 or drawable == 17 or drawable == 19 or drawable == 20 or drawable == 21 or drawable == 26 or drawable == 57 or drawable == 67 or (drawable >= 87 and drawable <= 146) then
            return 0.0
        -- Pantalones largos / Jeans / Leggins / Pantalones de servicio EUP
        elseif (drawable >= 0 and drawable <= 13) or (drawable >= 22 and drawable <= 38) then
            return 15.0
        -- Pantalones térmicos de invierno / Monos de nieve / Pantalones de Bombera
        else
            return 20.0
        end
    end
end

-- 5. Componente 8: Camisetas Interiores / Undershirts / Polos de Servicio
local function EvaluateUndershirtInsulation(ped, isMale)
    local drawable = GetPedDrawableVariation(ped, 8)
    if drawable <= 0 or drawable == 15 or drawable == 14 or drawable == -1 or drawable == 57 or drawable == 58 then
        return 0.0 -- Sin camiseta interior / Piel al descubierto
    elseif (drawable >= 1 and drawable <= 13) or (drawable >= 16 and drawable <= 25) then
        return 5.0 -- Camiseta interior de tirantes o manga corta
    elseif (drawable >= 50 and drawable <= 85) then
        return 8.0 -- Camisa de servicio interior EUP / Corbata policial
    else
        return 10.0 -- Cuello alto / Ropa térmica interior / Chaleco cerrado
    end
end

-- 6. Componente 6: Calzado / Botas Tácticas / Botas de Nieve y Bomberos
local function EvaluateFootwearInsulation(ped, isMale)
    local drawable = GetPedDrawableVariation(ped, 6)
    if drawable == -1 or drawable == 34 or drawable == 35 or drawable == 5 or drawable == 0 then
        return 0.0 -- Descalzo o Chanclas
    elseif (drawable >= 1 and drawable <= 15) or (drawable >= 25 and drawable <= 40) then
        return 3.0 -- Zapatillas deportivas / Zapatos de vestir
    else
        return 5.0 -- Botas de nieve / Botas tácticas policiales / Botas de bombero
    end
end

-- 7. Componente 7: Accesorios de Cuello / Bufandas / Shemagh
local function EvaluateNeckInsulation(ped)
    local drawable = GetPedDrawableVariation(ped, 7)
    if drawable <= 0 or drawable == -1 or drawable == 15 then return 0.0 end
    -- Bufandas / Pañuelos de cuello / Shemagh táctico
    if drawable == 2 or drawable == 3 or drawable == 4 or drawable == 8 or drawable == 14 or (drawable >= 20 and drawable <= 30) then
        return 5.0
    end
    return 1.0 -- Corbatas / Placas de detective
end

-- 8. Componente 1 (Máscaras/Pasamontañas) y Prop 0 (Cascos/Gorros/Beanies)
local function EvaluateHeadgearInsulation(ped)
    local bonus = 0.0

    -- Componente 1: Máscara / Pasamontañas / Balaclava / Máscara de Bombero
    local maskDrawable = GetPedDrawableVariation(ped, 1)
    if maskDrawable > 0 and maskDrawable ~= 15 and maskDrawable ~= -1 then
        if maskDrawable == 51 or maskDrawable == 52 or (maskDrawable >= 110 and maskDrawable <= 130) then
            bonus = bonus + 8.0 -- Pasamontañas térmico completo
        else
            bonus = bonus + 4.0 -- Máscara estándar
        end
    end

    -- Prop 0: Gorros / Beanies / Cascos de Bombero / Cascos de Policía / Cascos SWAT
    local hatProp = GetPedPropIndex(ped, 0)
    if hatProp ~= -1 and hatProp ~= 255 then
        if hatProp == 2 or hatProp == 4 or hatProp == 5 or hatProp == 18 or (hatProp >= 45 and hatProp <= 60) then
            bonus = bonus + 8.0 -- Gorro de lana / Beanie / Casco con acolchado térmico
        else
            bonus = bonus + 4.0 -- Gorra o casco ligero
        end
    end

    return bonus
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
    local headScore = EvaluateHeadgearInsulation(ped)            -- Max 12

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
        head = { maskId = GetPedDrawableVariation(ped, 1), prop0 = GetPedPropIndex(ped, 0), score = EvaluateHeadgearInsulation(ped) }
    }
end)
