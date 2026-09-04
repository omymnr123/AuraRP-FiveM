-- ============================================================================
-- AURA GANGS: SERVER GRAFFITI & TURF WARS ENGINE
-- Database Migration, Territorial Overwriting & Global Decal Broadcaster
-- ============================================================================

local CachedTurfs = {}

-- Comprobación automática de base de datos para graffitis
CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `aura_gang_turfs` (
          `id` INT(11) NOT NULL AUTO_INCREMENT,
          `gang` VARCHAR(50) NOT NULL,
          `graffiti_type` VARCHAR(50) NOT NULL DEFAULT 'spray_gang_default',
          `coords_x` DOUBLE NOT NULL,
          `coords_y` DOUBLE NOT NULL,
          `coords_z` DOUBLE NOT NULL,
          `normal_x` FLOAT NOT NULL DEFAULT 0,
          `normal_y` FLOAT NOT NULL DEFAULT 0,
          `normal_z` FLOAT NOT NULL DEFAULT 1,
          `sprayed_by` VARCHAR(100) NOT NULL,
          `sprayed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP() ON UPDATE CURRENT_TIMESTAMP(),
          PRIMARY KEY (`id`),
          KEY `idx_turf_gang` (`gang`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    Wait(500)
    local rows = MySQL.query.await('SELECT * FROM aura_gang_turfs ORDER BY id ASC')
    CachedTurfs = rows or {}
end)

--- Obtener todos los graffitis del servidor
lib.callback.register('aura_gangs:server:getGraffitis', function(source)
    return CachedTurfs
end)

--- Guardar o sobreescribir un graffiti en pared
lib.callback.register('aura_gangs:server:saveGraffiti', function(source, coords, normal, gangName)
    local src = source
    if not src or not coords or not gangName then return false, "Petición no válida." end

    local char = exports.aura_multichar:GetActiveCharacter(src)
    if not char then return false, "Personaje no encontrado." end

    local gangInfo = Config.Gangs[gangName]
    if not gangInfo then return false, "Banda no reconocida." end

    local playerName = string.format("%s %s", char.firstname or "Miembro", char.lastname or "")

    -- Comprobar si existe un graffiti rival en un radio de 4.0 metros para tacharlo
    local overwrittenGang = nil
    local existingId = nil

    for _, t in ipairs(CachedTurfs) do
        local dist = #(vec3(t.coords_x, t.coords_y, t.coords_z) - vec3(coords.x, coords.y, coords.z))
        if dist <= 4.0 then
            existingId = t.id
            overwrittenGang = t.gang
            break
        end
    end

    if existingId then
        -- Sobreescribir graffiti rival
        MySQL.update.await([[
            UPDATE aura_gang_turfs 
            SET gang = ?, coords_x = ?, coords_y = ?, coords_z = ?, 
                normal_x = ?, normal_y = ?, normal_z = ?, sprayed_by = ?, sprayed_at = NOW() 
            WHERE id = ?
        ]], { gangName, coords.x, coords.y, coords.z, normal.x or 0.0, normal.y or 0.0, normal.z or 1.0, playerName, existingId })

        for i, t in ipairs(CachedTurfs) do
            if t.id == existingId then
                t.gang = gangName
                t.coords_x = coords.x
                t.coords_y = coords.y
                t.coords_z = coords.z
                t.normal_x = normal.x
                t.normal_y = normal.y
                t.normal_z = normal.z
                t.sprayed_by = playerName
                break
            end
        end

        TriggerClientEvent('aura_gangs:client:syncGraffitis', -1, CachedTurfs)

        if overwrittenGang and overwrittenGang ~= gangName then
            local rivalInfo = Config.Gangs[overwrittenGang]
            local rivalLabel = rivalInfo and rivalInfo.label or overwrittenGang
            return true, string.format("¡Has tachado el graffiti de %s!\nTerritorio conquistado para %s.", rivalLabel, gangInfo.label)
        end
    else
        -- Insertar nuevo graffiti
        local insertId = MySQL.insert.await([[
            INSERT INTO aura_gang_turfs 
            (gang, coords_x, coords_y, coords_z, normal_x, normal_y, normal_z, sprayed_by) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ]], { gangName, coords.x, coords.y, coords.z, normal.x or 0.0, normal.y or 0.0, normal.z or 1.0, playerName })

        table.insert(CachedTurfs, {
            id = insertId,
            gang = gangName,
            coords_x = coords.x,
            coords_y = coords.y,
            coords_z = coords.z,
            normal_x = normal.x,
            normal_y = normal.y,
            normal_z = normal.z,
            sprayed_by = playerName
        })

        TriggerClientEvent('aura_gangs:client:syncGraffitis', -1, CachedTurfs)
    end

    return true, string.format("Territorio marcado con éxito para %s.", gangInfo.label)
end)
