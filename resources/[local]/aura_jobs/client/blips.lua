-- ============================================================================
-- AURA JOBS: CLIENT BUSINESS & LIQUOR STORE BLIPS CONTROLLER
-- Dynamic Minimap & Map Blips with Real-time Open (Original Color) / Closed (Grey) Sync
-- ============================================================================

local businessBlips = {}
local staticBlips = {}

local function UpdateBusinessBlip(jobKey, forceState)
    local blipData = businessBlips[jobKey]
    if not blipData or not DoesBlipExist(blipData.handle) then return end

    local conf = blipData.config
    local isOpen = forceState
    if isOpen == nil then
        isOpen = GlobalState['business_' .. jobKey .. '_open'] == true
    end

    local color = isOpen and (conf.openColor or 48) or (conf.closedColor or 39)
    local statusSuffix = isOpen and " [ABIERTO]" or " [CERRADO]"
    local displayName = (conf.name or jobKey) .. statusSuffix

    SetBlipColour(blipData.handle, color)
    
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(displayName)
    EndTextCommandSetBlipName(blipData.handle)
end

local function ClearAllBlips()
    for _, blipData in pairs(businessBlips) do
        if DoesBlipExist(blipData.handle) then
            RemoveBlip(blipData.handle)
        end
    end
    businessBlips = {}

    for _, handle in ipairs(staticBlips) do
        if DoesBlipExist(handle) then
            RemoveBlip(handle)
        end
    end
    staticBlips = {}
end

local function InitAllBlips()
    ClearAllBlips()

    -- 1. Blips dinámicos de Negocios de Hostelería (Copa 93 / Dinámicos Abierto/Cerrado)
    if Config.BusinessVendors then
        for vendorKey, vendorConfig in pairs(Config.BusinessVendors) do
            local blipConfig = vendorConfig.blip
            if blipConfig and blipConfig.enabled ~= false then
                local coords = blipConfig.coords or vendorConfig.coords
                local blip = AddBlipForCoord(coords.x, coords.y, coords.z)

                SetBlipSprite(blip, blipConfig.sprite or 93)
                SetBlipDisplay(blip, 4)
                SetBlipScale(blip, blipConfig.scale or 0.8)
                SetBlipAsShortRange(blip, true)

                businessBlips[vendorConfig.job or vendorKey] = {
                    handle = blip,
                    config = blipConfig
                }

                UpdateBusinessBlip(vendorConfig.job or vendorKey)
            end
        end
    end


end

-- ============================================================================
-- EVENTOS Y SINCRONIZACIÓN EN TIEMPO REAL
-- ============================================================================

-- Escuchar cambios en GlobalState para actualizar el color en 0ms cuando un negocio abre o cierra
AddStateBagChangeHandler(nil, 'global', function(bagName, key, value)
    if string.sub(key, 1, 9) == 'business_' and string.sub(key, -5) == '_open' then
        local jobName = string.sub(key, 10, -6)
        UpdateBusinessBlip(jobName, value == true)
    end
end)

-- Inicializar blips al cargar el script o entrar al servidor
CreateThread(function()
    Wait(1000)
    InitAllBlips()
end)

RegisterNetEvent('aura_economy:server:characterLoaded', function()
    Wait(1500)
    InitAllBlips()
end)

-- Limpieza limpia al detener o reiniciar el recurso
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        ClearAllBlips()
    end
end)
