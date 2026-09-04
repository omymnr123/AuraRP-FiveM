-- illenium-appearance/server/framework/aura/main.lua
-- Bridge servidor para el framework Aura (Standalone)
-- Se activa SOLO si QBCore, ESX y OxCore NO están presentes

if not Framework.Aura() then return end

-- Auto-crear tablas requeridas si no existen en la base de datos
CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `playerskins` (
          `id` int(11) NOT NULL AUTO_INCREMENT,
          `citizenid` varchar(255) NOT NULL,
          `model` varchar(255) NOT NULL,
          `skin` text NOT NULL,
          `active` tinyint(4) NOT NULL DEFAULT 1,
          PRIMARY KEY (`id`),
          KEY `citizenid` (`citizenid`),
          KEY `active` (`active`)
        ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `player_outfits` (
          `id` int(11) NOT NULL AUTO_INCREMENT,
          `citizenid` varchar(50) DEFAULT NULL,
          `outfitname` varchar(50) NOT NULL DEFAULT '0',
          `model` varchar(50) DEFAULT NULL,
          `props` varchar(1000) DEFAULT NULL,
          `components` varchar(1500) DEFAULT NULL,
          PRIMARY KEY (`id`),
          KEY `citizenid` (`citizenid`)
        ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `player_outfit_codes` (
          `id` int(11) NOT NULL AUTO_INCREMENT,
          `outfitid` int(11) NOT NULL,
          `code` varchar(50) NOT NULL DEFAULT '',
          PRIMARY KEY (`id`)
        ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `management_outfits` (
          `id` int(11) NOT NULL AUTO_INCREMENT,
          `job_name` varchar(50) NOT NULL,
          `type` varchar(50) NOT NULL,
          `minrank` int(11) NOT NULL DEFAULT 0,
          `name` varchar(50) NOT NULL DEFAULT 'Cool Outfit',
          `gender` varchar(50) NOT NULL DEFAULT 'male',
          `model` varchar(50) DEFAULT NULL,
          `props` varchar(1000) DEFAULT NULL,
          `components` varchar(1500) DEFAULT NULL,
          PRIMARY KEY (`id`)
        ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;
    ]], function()
        print("^2[ILLENIUM-APPEARANCE] Auto-migration complete: all appearance database tables verified.^7")
    end)
end)

-- Obtener el character ID del jugador activo desde aura_multichar
function Framework.GetPlayerID(src)
    local char = exports.aura_multichar:GetActiveCharacter(src)
    if char then
        return tostring(char.id)
    end
    return nil
end

function Framework.HasMoney(src, type, money)
    return true -- En standalone, siempre permitir (no hay sistema de dinero aún)
end

function Framework.RemoveMoney(src, type, money)
    return true -- En standalone, siempre permitir
end

function Framework.GetJob(src)
    return { name = "unemployed", grade = { level = 0 } }
end

function Framework.GetGang(src)
    return { name = "none", grade = { level = 0 } }
end

function Framework.SaveAppearance(appearance, citizenID)
    if not citizenID or not appearance then return end

    local charId = tonumber(citizenID)

    -- Guardar en la tabla playerskins de illenium
    pcall(function()
        Database.PlayerSkins.UpdateActiveField(citizenID, 0)
        Database.PlayerSkins.DeleteByModel(citizenID, appearance.model)
        Database.PlayerSkins.Add(citizenID, appearance.model, json.encode(appearance), 1)
    end)
    
    -- Sincronizar en memoria activa y en la tabla characters de Aura
    if exports.aura_multichar and exports.aura_multichar.SetCharacterAppearance then
        exports.aura_multichar:SetCharacterAppearance(charId or citizenID, appearance)
    else
        if charId then
            local charRow = MySQL.single.await('SELECT metadata FROM characters WHERE id = ?', { charId })
            if charRow then
                local metadata = json.decode(charRow.metadata) or {}
                metadata.appearance = appearance
                MySQL.update.await('UPDATE characters SET metadata = ? WHERE id = ?', {
                    json.encode(metadata),
                    charId
                })
            end
        end
    end
end

function Framework.GetAppearance(citizenID, model)
    if not citizenID then return nil end
    local result = nil
    pcall(function()
        result = Database.PlayerSkins.GetByCitizenID(citizenID, model)
    end)
    if result then
        return json.decode(result)
    end
    return nil
end
