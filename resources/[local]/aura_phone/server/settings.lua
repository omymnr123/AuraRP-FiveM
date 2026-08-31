-- =========================================
-- AURA SETTINGS - SERVER
-- =========================================

local DEFAULT_SETTINGS = {
    device_name = "iPhone de Aura",
    wallpaper_url = "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=2564&auto=format&fit=crop",
    frame_color = "#00F0FF",
    ringtone = "ringtone.mp3",
    message_tone = "sms.mp3",
    volume_ring = 80,
    volume_msg = 80,
    security = {
        pin_code = "",
        face_id = false
    },
    notifications = {
        calls = true,
        messages = true,
        bank = true
    }
}

-- Función auxiliar para mezclar tablas (merge default settings con datos de DB)
local function mergeSettings(saved)
    local result = {}
    for k, v in pairs(DEFAULT_SETTINGS) do
        if type(v) == 'table' then
            result[k] = {}
            for subK, subV in pairs(v) do
                if saved and saved[k] and saved[k][subK] ~= nil then
                    result[k][subK] = saved[k][subK]
                else
                    result[k][subK] = subV
                end
            end
        else
            if saved and saved[k] ~= nil then
                result[k] = saved[k]
            else
                result[k] = v
            end
        end
    end
    return result
end

-- Obtener la configuración del teléfono del usuario
lib.callback.register('aura_phone:server:getSettings', function(source)
    local src = source
    local number = AuraPhone.GetPlayerPhoneNumber(src)
    if not number then return DEFAULT_SETTINGS end

    local charData = MySQL.single.await('SELECT firstname, lastname, phone_settings FROM characters WHERE phone_number = ?', {number})
    if not charData then return DEFAULT_SETTINGS end

    local parsed = nil
    if charData.phone_settings and charData.phone_settings ~= "" then
        pcall(function()
            parsed = json.decode(charData.phone_settings)
        end)
    end

    local finalSettings = mergeSettings(parsed)

    -- Si el device_name es el por defecto, asignar el nombre del personaje
    if not parsed or not parsed.device_name or parsed.device_name == "iPhone de Aura" then
        if charData.firstname then
            finalSettings.device_name = "iPhone de " .. charData.firstname
        end
    end

    return finalSettings
end)

-- Guardar configuración completa en la base de datos
lib.callback.register('aura_phone:server:saveSettings', function(source, settings)
    local src = source
    local number = AuraPhone.GetPlayerPhoneNumber(src)
    if not number or not settings then return { success = false, message = "Error de autenticación" } end

    local encoded = json.encode(settings)

    MySQL.update.await('UPDATE characters SET phone_settings = ? WHERE phone_number = ?', {
        encoded, number
    })

    return { success = true }
end)

-- Actualizar una clave específica en caliente
lib.callback.register('aura_phone:server:updateSettingKey', function(source, data)
    local src = source
    local number = AuraPhone.GetPlayerPhoneNumber(src)
    if not number or not data.key then return { success = false } end

    local charData = MySQL.single.await('SELECT phone_settings FROM characters WHERE phone_number = ?', {number})
    local currentSettings = {}
    if charData and charData.phone_settings and charData.phone_settings ~= "" then
        pcall(function()
            currentSettings = json.decode(charData.phone_settings)
        end)
    end

    currentSettings = mergeSettings(currentSettings)
    currentSettings[data.key] = data.value

    local encoded = json.encode(currentSettings)
    MySQL.update.await('UPDATE characters SET phone_settings = ? WHERE phone_number = ?', {
        encoded, number
    })

    return { success = true, settings = currentSettings }
end)
