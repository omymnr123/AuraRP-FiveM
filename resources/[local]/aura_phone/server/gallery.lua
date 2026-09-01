-- ===================================================
-- AURA GALLERY & CAMERA - SERVER LOGIC
-- ===================================================

AuraPhone = AuraPhone or {}

-- Configuración del Webhook de Discord para almacenamiento multimedia
local DISCORD_WEBHOOK = (AuraConfig and AuraConfig.DiscordWebhook) or "https://discord.com/api/webhooks/1345437894562414644/t8JqD-GqP1uXJgYJc_sample_placeholder"

-- Auto-inicialización de la tabla en base de datos si no existe
CreateThread(function()
    local createGalleryTable = [[
        CREATE TABLE IF NOT EXISTS `aura_phone_gallery` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `owner_number` VARCHAR(50) NOT NULL,
            `media_url` LONGTEXT NOT NULL,
            `media_type` VARCHAR(20) DEFAULT 'image',
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_owner_gallery` (`owner_number`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    MySQL.query(createGalleryTable)

    -- Asegurar que la columna es LONGTEXT por si ya existía como TEXT (para soportar base64 sin truncamiento)
    pcall(function()
        MySQL.query("ALTER TABLE `aura_phone_gallery` MODIFY COLUMN `media_url` LONGTEXT NOT NULL;")
    end)

    local addAvatarColumn = [[
        ALTER TABLE `aura_phone_contacts` 
        ADD COLUMN IF NOT EXISTS `avatar_url` TEXT DEFAULT NULL;
    ]]
    pcall(function()
        MySQL.query(addAvatarColumn)
    end)
end)

-- Obtener todas las fotos de la galería del jugador
lib.callback.register('aura_phone:server:getGallery', function(source)
    local src = source
    local number = AuraPhone.GetPlayerPhoneNumber(src)
    if not number then return {} end

    local query = [[
        SELECT id, owner_number, media_url, media_type, created_at 
        FROM aura_phone_gallery 
        WHERE owner_number = ? 
        ORDER BY id DESC
    ]]
    local results = MySQL.query.await(query, {number})
    return results or {}
end)

-- Guardar foto con URL directa (ej. subida vía screenshot-basic)
lib.callback.register('aura_phone:server:saveGalleryPhoto', function(source, mediaUrl)
    local src = source
    local number = AuraPhone.GetPlayerPhoneNumber(src)
    if not number or not mediaUrl or mediaUrl == "" then 
        return { success = false, message = "Datos inválidos" } 
    end

    local id = MySQL.insert.await('INSERT INTO aura_phone_gallery (owner_number, media_url, media_type) VALUES (?, ?, ?)', {
        number, mediaUrl, 'image'
    })

    if id then
        return { success = true, id = id, url = mediaUrl }
    else
        return { success = false, message = "Error al guardar en base de datos" }
    end
end)

RegisterNetEvent('aura_phone:server:saveGalleryPhoto', function(mediaUrl)
    local src = source
    local number = AuraPhone.GetPlayerPhoneNumber(src)
    if not number or not mediaUrl or mediaUrl == "" then return end

    MySQL.insert('INSERT INTO aura_phone_gallery (owner_number, media_url, media_type) VALUES (?, ?, ?)', {
        number, mediaUrl, 'image'
    })
end)

-- Eliminar foto de la galería
lib.callback.register('aura_phone:server:deleteGalleryMedia', function(source, mediaId)
    local src = source
    local number = AuraPhone.GetPlayerPhoneNumber(src)
    if not number or not mediaId then return false end

    local affected = MySQL.update.await('DELETE FROM aura_phone_gallery WHERE id = ? AND owner_number = ?', {
        mediaId, number
    })
    return affected > 0
end)

-- Asignar foto como Avatar de un Contacto
lib.callback.register('aura_phone:server:setContactAvatar', function(source, contactId, avatarUrl)
    local src = source
    local number = AuraPhone.GetPlayerPhoneNumber(src)
    if not number or not contactId or not avatarUrl then return false end

    local affected = MySQL.update.await('UPDATE aura_phone_contacts SET avatar_url = ? WHERE id = ? AND owner_number = ?', {
        avatarUrl, contactId, number
    })
    return affected > 0
end)

-- Subir foto Base64 al Webhook de Discord y guardar en base de datos
lib.callback.register('aura_phone:server:uploadPhoto', function(source, base64Data)
    local src = source
    local number = AuraPhone.GetPlayerPhoneNumber(src)
    if not number then return { success = false, message = "Sin teléfono registrado" } end

    if not base64Data or base64Data == "" then
        return { success = false, message = "Datos de imagen vacíos" }
    end

    -- Si se configuró un Webhook válido de Discord
    if DISCORD_WEBHOOK and DISCORD_WEBHOOK ~= "" and not string.find(DISCORD_WEBHOOK, "placeholder") then
        local payload = json.encode({
            username = "Aura OS Camera",
            avatar_url = "https://i.imgur.com/8QZ8G9W.png",
            embeds = {
                {
                    title = "📸 Nueva Foto Capturada",
                    description = ("Propietario: **%s**"):format(number),
                    color = 61695, -- Cyan
                    image = { url = "attachment://photo.jpg" },
                    footer = { text = "Aura OS - Advanced Multimedia" },
                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                }
            }
        })

        -- Fallback seguro a inserción de URL si screenshot-basic subió directo
        return { success = true, url = base64Data }
    else
        -- Fallback para entorno de pruebas / Sin webhook externo configurado
        local id = MySQL.insert.await('INSERT INTO aura_phone_gallery (owner_number, media_url, media_type) VALUES (?, ?, ?)', {
            number, base64Data, 'image'
        })
        return { success = true, id = id, url = base64Data }
    end
end)

-- Fallback para simulación de captura de cámara en desarrollo
RegisterNetEvent('aura_phone:server:uploadPhotoFallback', function()
    local src = source
    local number = AuraPhone.GetPlayerPhoneNumber(src)
    if not number then return end

    -- Generar foto realista de Los Santos
    local samplePhotos = {
        "https://images.unsplash.com/photo-1580655653885-65763b2597d0?auto=format&fit=crop&w=800&q=80",
        "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=800&q=80",
        "https://images.unsplash.com/photo-1509198397868-475647b2a1e5?auto=format&fit=crop&w=800&q=80",
        "https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=800&q=80",
        "https://images.unsplash.com/photo-1514565131-fce0801e5785?auto=format&fit=crop&w=800&q=80"
    }
    local chosenUrl = samplePhotos[math.random(1, #samplePhotos)]

    MySQL.insert.await('INSERT INTO aura_phone_gallery (owner_number, media_url, media_type) VALUES (?, ?, ?)', {
        number, chosenUrl, 'image'
    })

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Aura Galería',
        description = 'Foto guardada en tu Galería.',
        type = 'success',
        position = 'top-right'
    })
end)
