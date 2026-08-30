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

-- Inicialización / Carga de estados
RegisterNetEvent('aura_status:client:LoadStatus')
AddEventHandler('aura_status:client:LoadStatus', function(statusData)
    PlayerData.hunger = statusData.hunger or 100.0
    PlayerData.thirst = statusData.thirst or 100.0
    
    local ped = PlayerPedId()
    if statusData.health then
        SetEntityHealth(ped, statusData.health)
    end
    if statusData.armor then
        SetPedArmour(ped, statusData.armor)
    end
    
    PlayerData.isLoggedIn = true
end)

-- Inicialización al hacer spawn en el mundo
AddEventHandler('playerSpawned', function()
    TriggerServerEvent('aura_status:server:PlayerReady')
end)

-- Evento genérico para añadir estado
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
    -- Cálculos de matemática intuitiva (basado en Config.lua)
    local updateDelayMs = Config.MetabolismUpdateSeconds * 1000
    local totalTicksHunger = (Config.MinutesToStarve * 60) / Config.MetabolismUpdateSeconds
    local hungerDrainPerTick = 100.0 / totalTicksHunger
    
    local totalTicksThirst = (Config.MinutesToDehydrate * 60) / Config.MetabolismUpdateSeconds
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
                if currentHealth > 0 then
                    SetEntityHealth(ped, currentHealth - Config.StarvationDamage)
                end
            end
            
            if PlayerData.thirst <= 0.0 then
                local currentHealth = GetEntityHealth(ped)
                if currentHealth > 0 then
                    SetEntityHealth(ped, currentHealth - Config.DehydrationDamage)
                end
            end
        end
    end
end)

-- Loop de Sincronización HUD
CreateThread(function()
    while true do
        Wait(Config.HudSyncTickRate)
        if PlayerData.isLoggedIn then
            local ped = PlayerPedId()
            
            -- Obtener salud (en FiveM, la vida máxima de un ped suele ser 200, empezando desde 100 que es muerte)
            -- Restamos 100 y calculamos porcentaje sobre los 100 reales de vida.
            local health = GetEntityHealth(ped)
            local healthPercent = 0
            if health > 100 then
                healthPercent = ((health - 100) / (GetEntityMaxHealth(ped) - 100)) * 100
            end
            
            -- Obtener armadura
            local armor = GetPedArmour(ped)
            local armorPercent = (armor / Config.MaxArmor) * 100
            
            -- Asegurar límites visuales
            healthPercent = Clamp(math.floor(healthPercent), 0, 100)
            armorPercent = Clamp(math.floor(armorPercent), 0, 100)
            local hungerPercent = Clamp(math.floor(PlayerData.hunger), 0, 100)
            local thirstPercent = Clamp(math.floor(PlayerData.thirst), 0, 100)
            
            -- Obtener Stamina (Energía)
            -- GetPlayerSprintStaminaRemaining devuelve 0 cuando está descansado y 100 cuando está agotado.
            -- Lo invertimos para que sea 100 (descansado) a 0 (agotado).
            local staminaPercent = Clamp(math.floor(100.0 - GetPlayerSprintStaminaRemaining(PlayerId())), 0, 100)
            
            -- Enviar datos al recurso aura_hud de forma local
            TriggerEvent('aura_hud:updateStatus', healthPercent, armorPercent, hungerPercent, thirstPercent, staminaPercent)
        end
    end
end)

-- Export para obtener estado actual (útil para guardar)
exports('GetStatus', function()
    local ped = PlayerPedId()
    return {
        hunger = PlayerData.hunger,
        thirst = PlayerData.thirst,
        health = GetEntityHealth(ped),
        armor = GetPedArmour(ped)
    }
end)

-- Guardado periódico si el cliente sufre crash
CreateThread(function()
    while true do
        Wait(60000) -- Cada minuto
        if PlayerData.isLoggedIn then
            TriggerServerEvent('aura_status:server:UpdateStatus', exports.aura_status:GetStatus())
        end
    end
end)
