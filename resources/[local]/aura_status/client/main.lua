local PlayerData = {
    hunger = 100.0,
    thirst = 100.0,
    isLoggedIn = false
}

-- Función auxiliar para limitar valores
local function Clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

-- Función auxiliar para obtener el estado completo del jugador
local function GetPlayerStatus()
    local ped = PlayerPedId()
    return {
        hunger = PlayerData.hunger,
        thirst = PlayerData.thirst,
        health = GetEntityHealth(ped),
        armor = GetPedArmour(ped)
    }
end

-- Inicialización / Carga de estados desde el servidor
RegisterNetEvent('aura_status:client:LoadStatus')
AddEventHandler('aura_status:client:LoadStatus', function(statusData)
    if not statusData then statusData = {} end
    
    PlayerData.hunger = tonumber(statusData.hunger) or 100.0
    PlayerData.thirst = tonumber(statusData.thirst) or 100.0
    
    local ped = PlayerPedId()
    if statusData.health and tonumber(statusData.health) then
        SetEntityHealth(ped, tonumber(statusData.health))
    end
    if statusData.armor and tonumber(statusData.armor) then
        SetPedArmour(ped, tonumber(statusData.armor))
    end
    
    PlayerData.isLoggedIn = true
end)

-- Función de inicialización del jugador
local function InitPlayer()
    TriggerServerEvent('aura_status:server:PlayerReady')
end

-- Inicialización al hacer spawn o cargar personaje en el mundo
AddEventHandler('playerSpawned', InitPlayer)
RegisterNetEvent('aura_core:client:playerSpawned', InitPlayer)
RegisterNetEvent('aura_core:playerSpawnedAndReady', InitPlayer)
RegisterNetEvent('aura_multichar:client:characterLoaded', InitPlayer)

-- Soporte en caso de reinicio en caliente del recurso
AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Wait(500)
    InitPlayer()
end)

-- Evento genérico para añadir estado (comidas, bebidas, etc.)
RegisterNetEvent('aura_status:client:AddStatus')
AddEventHandler('aura_status:client:AddStatus', function(type, amount)
    if type == 'hunger' then
        PlayerData.hunger = Clamp(PlayerData.hunger + amount, 0.0, 100.0)
    elseif type == 'thirst' then
        PlayerData.thirst = Clamp(PlayerData.thirst + amount, 0.0, 100.0)
    end
end)

-- Loop de Metabolismo
CreateThread(function()
    local updateDelayMs = (Config.MetabolismUpdateSeconds or 10) * 1000
    local totalTicksHunger = ((Config.MinutesToStarve or 120) * 60) / (Config.MetabolismUpdateSeconds or 10)
    local hungerDrainPerTick = 100.0 / totalTicksHunger
    
    local totalTicksThirst = ((Config.MinutesToDehydrate or 90) * 60) / (Config.MetabolismUpdateSeconds or 10)
    local thirstDrainPerTick = 100.0 / totalTicksThirst

    while true do
        Wait(updateDelayMs)
        if PlayerData.isLoggedIn then
            local ped = PlayerPedId()
            
            -- Reducir estados basados en el cálculo matemático dinámico
            PlayerData.hunger = Clamp(PlayerData.hunger - hungerDrainPerTick, 0.0, 100.0)
            PlayerData.thirst = Clamp(PlayerData.thirst - thirstDrainPerTick, 0.0, 100.0)
            
            -- Aplicar daño por inanición / deshidratación si llega a 0
            if PlayerData.hunger <= 0.0 then
                local currentHealth = GetEntityHealth(ped)
                if currentHealth > 100 then
                    SetEntityHealth(ped, currentHealth - (Config.StarvationDamage or 2))
                end
            end
            
            if PlayerData.thirst <= 0.0 then
                local currentHealth = GetEntityHealth(ped)
                if currentHealth > 100 then
                    SetEntityHealth(ped, currentHealth - (Config.DehydrationDamage or 3))
                end
            end
        end
    end
end)

-- Loop de Sincronización HUD
CreateThread(function()
    while true do
        Wait(Config.HudSyncTickRate or 500)
        if PlayerData.isLoggedIn then
            local ped = PlayerPedId()
            
            -- Obtener salud (en FiveM, la vida máxima de un ped multijugador es 200, empezando desde 100 que es muerte)
            local maxHealth = GetEntityMaxHealth(ped)
            local currentHealth = GetEntityHealth(ped)
            local healthPercent = 0
            
            if maxHealth > 100 then
                if currentHealth > 100 then
                    healthPercent = ((currentHealth - 100) / (maxHealth - 100)) * 100.0
                else
                    healthPercent = 0.0
                end
            else
                if maxHealth > 0 and currentHealth > 0 then
                    healthPercent = (currentHealth / maxHealth) * 100.0
                else
                    healthPercent = 0.0
                end
            end
            
            -- Obtener armadura
            local armor = GetPedArmour(ped)
            local maxArmor = Config.MaxArmor or 100
            local armorPercent = 0
            if maxArmor > 0 then
                armorPercent = (armor / maxArmor) * 100.0
            end
            
            -- Asegurar límites visuales
            healthPercent = Clamp(math.floor(healthPercent), 0, 100)
            armorPercent = Clamp(math.floor(armorPercent), 0, 100)
            local hungerPercent = Clamp(math.floor(PlayerData.hunger), 0, 100)
            local thirstPercent = Clamp(math.floor(PlayerData.thirst), 0, 100)
            
            -- Obtener Stamina (Energía)
            -- GetPlayerSprintStaminaRemaining devuelve 0.0 en reposo y sube hasta 100.0 cuando se agota al esprintar.
            -- Lo convertimos en energía restante: 100 (descansado) a 0 (agotado).
            local staminaUsed = GetPlayerSprintStaminaRemaining(PlayerId())
            local staminaPercent = 100.0 - staminaUsed
            if staminaUsed <= 0.5 then
                staminaPercent = 100.0
            end
            staminaPercent = Clamp(math.floor(staminaPercent), 0, 100)
            
            -- Enviar datos al recurso aura_hud de forma local
            TriggerEvent('aura_hud:updateStatus', healthPercent, armorPercent, hungerPercent, thirstPercent, staminaPercent)
        end
    end
end)

-- Export para obtener estado actual (útil para guardar o consultar desde otros recursos)
exports('GetStatus', GetPlayerStatus)

-- Guardado periódico si el cliente sufre crash
CreateThread(function()
    while true do
        Wait(60000) -- Cada minuto
        if PlayerData.isLoggedIn then
            TriggerServerEvent('aura_status:server:UpdateStatus', GetPlayerStatus())
        end
    end
end)
