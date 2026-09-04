-- illenium-appearance/client/framework/aura/main.lua
-- Bridge para el framework Aura (Standalone)
-- Se activa SOLO si QBCore, ESX y OxCore NO están presentes

if not Framework.Aura() then return end

local client = client

-- Variables locales del jugador
local playerGender = "Male"

-- Función llamada por illenium internamente
function Framework.GetPlayerGender()
    return playerGender
end

function Framework.UpdatePlayerData()
    -- Inicializar datos mínimos del cliente que illenium requiere
    client.job = client.job or { name = "unemployed", grade = { level = 0 }, onduty = false }
    client.gang = client.gang or { name = "none", grade = { level = 0 } }
    client.citizenid = client.citizenid or "aura_standalone"
end

function Framework.HasTracker()
    return false
end

function Framework.CheckPlayerMeta()
    return false
end

function Framework.IsPlayerAllowed(citizenid)
    return true
end

function Framework.GetRankInputValues(type)
    return {}
end

function Framework.GetJobGrade()
    return 0
end

function Framework.GetGangGrade()
    return 0
end

function Framework.CachePed()
    return nil
end

function Framework.RestorePlayerArmour()
    return nil
end

-- Asegurar datos mínimos al iniciar
Framework.UpdatePlayerData()

-- Sincronizar datos del personaje cuando carga en aura_multichar
RegisterNetEvent('aura_multichar:client:characterLoaded', function(charData)
    if not charData then return end
    client.citizenid = tostring(charData.id)
    if charData.gender and tonumber(charData.gender) == 1 then
        playerGender = "Female"
    else
        playerGender = "Male"
    end
    client.job = {
        name = charData.job or "unemployed",
        grade = { level = tonumber(charData.job_grade) or 0 },
        onduty = (tonumber(charData.job_duty) == 1)
    }
    client.gang = {
        name = "none",
        grade = { level = 0 }
    }
end)

-- Función pública para que aura_appearance pueda setear el género antes de abrir el menú
exports('setGender', function(gender)
    if gender == 1 then
        playerGender = "Female"
    else
        playerGender = "Male"
    end
end)
