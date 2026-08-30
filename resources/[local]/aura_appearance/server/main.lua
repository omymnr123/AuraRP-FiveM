-- aura_appearance/server/main.lua

-- Evento para guardar la apariencia del personaje (Seguridad inyectable)
RegisterNetEvent('aura_appearance:saveAppearance', function(appearanceData)
    local src = source
    if not appearanceData or type(appearanceData) ~= "table" then return end

    -- Obtener el personaje activo desde aura_multichar
    local char = exports.aura_multichar:GetActiveCharacter(src)
    if not char then
        print(("^1[AURA APPEARANCE] Exploit Alert: Player %s tried to save appearance without an active character.^7"):format(src))
        return
    end

    -- Actualizar el objeto metadata con la nueva apariencia
    char.metadata.appearance = appearanceData

    -- Guardar de forma segura en base de datos usando oxmysql
    MySQL.update('UPDATE characters SET metadata = ? WHERE id = ?', {
        json.encode(char.metadata),
        char.id
    }, function(affectedRows)
        if affectedRows > 0 then
            print(("^2[AURA APPEARANCE] Appearance saved successfully for character ID: %s (Player: %s)^7"):format(char.id, src))
        else
            print(("^1[AURA APPEARANCE] Error saving appearance for character ID: %s (Player: %s)^7"):format(char.id, src))
        end
    end)
end)
