-- Espacio de memoria principal del core
AuraCore = {}
AuraCore.Players = {}

-- Función interna: Generación criptográfica básica para CitizenID
local function GenerateCitizenId()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local id = ''
    for i = 1, 8 do
        local rand = math.random(1, #chars)
        id = id .. string.sub(chars, rand, rand)
    end
    return id
end

-- Función interna: Extracción del identificador primario (License)
local function GetPlayerLicense(source)
    local identifiers = GetPlayerIdentifiers(source)
    for i = 1, #identifiers do
        if string.sub(identifiers[i], 1, 8) == "license:" then
            return identifiers[i]
        end
    end
    return nil
end

-- Intercepción de conexión
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    deferrals.defer()

    -- Ceder el hilo temporalmente al sistema de deferrals (obligatorio)
    Wait(0)

    deferrals.update(string.format("Aura Core: Verificando identificadores para %s...", name))

    local license = GetPlayerLicense(src)
    if not license then
        deferrals.done("Acceso denegado: No se pudo verificar la licencia de Rockstar. Asegúrese de tener el cliente iniciado correctamente.")
        return
    end

    deferrals.update("Aura Core: Consultando base de datos central...")

    -- Operación asíncrona (no bloqueante) para obtener el perfil
    local playerRecord = MySQL.single.await('SELECT license, citizenid, metadata FROM players WHERE license = ? LIMIT 1', { license })

    if playerRecord then
        -- [Jugador Recurrente]
        deferrals.update("Aura Core: Perfil localizado. Cargando estado en memoria...")
        
        -- Registro de último inicio de sesión asíncrono
        MySQL.update('UPDATE players SET last_login = CURRENT_TIMESTAMP WHERE license = ?', { license })

        -- Inicialización en RAM
        AuraCore.Players[src] = {
            license = playerRecord.license,
            citizenid = playerRecord.citizenid,
            metadata = json.decode(playerRecord.metadata),
            name = name,
            source = src
        }

        print(string.format("[Aura Core] Conexión autorizada: %s | CitizenID: %s", name, playerRecord.citizenid))
        deferrals.done()
    else
        -- [Nuevo Jugador]
        deferrals.update("Aura Core: Registrando nueva identidad...")

        local newCitizenId = GenerateCitizenId()
        
        -- Prevención de colisiones de CitizenID en DB
        while MySQL.scalar.await('SELECT 1 FROM players WHERE citizenid = ?', { newCitizenId }) do
            newCitizenId = GenerateCitizenId()
        end

        local defaultMetadata = {
            money = { cash = 500, bank = 1500 },
            last_location = { x = -1037.8, y = -2737.9, z = 20.17, heading = 330.0 },
            status = { hunger = 100, thirst = 100 },
            permissions = "user"
        }

        local insertId = MySQL.insert.await('INSERT INTO players (license, citizenid, metadata, last_login) VALUES (?, ?, ?, CURRENT_TIMESTAMP)', {
            license,
            newCitizenId,
            json.encode(defaultMetadata)
        })

        if insertId then
            AuraCore.Players[src] = {
                license = license,
                citizenid = newCitizenId,
                metadata = defaultMetadata,
                name = name,
                source = src
            }
            print(string.format("[Aura Core] Registro completado: %s | CitizenID: %s", name, newCitizenId))
            deferrals.done()
        else
            deferrals.done("Error interno del servidor (Aura Core): Fallo en la inserción SQL. Contacte a infraestructura.")
        end
    end
end)

-- Limpieza de caché (Garbage Collection & Save)
AddEventHandler('playerDropped', function(reason)
    local src = source
    local player = AuraCore.Players[src]
    
    if player then
        local ped = GetPlayerPed(src)
        if ped and ped ~= 0 then
            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            
            -- Actualizamos 'last_location' que es lo que lee aura_multichar
            player.metadata.last_location = {
                x = coords.x,
                y = coords.y,
                z = coords.z,
                heading = heading
            }
        end

        -- Sincronizar estado actual a disco (DB) antes de destruir el objeto en memoria
        MySQL.update('UPDATE players SET metadata = ? WHERE license = ?', {
            json.encode(player.metadata),
            player.license
        })

        print(string.format("[Aura Core] Desconexión de %s procesada. Motivo: %s", player.name, reason))
        
        -- Liberar puntero de memoria
        AuraCore.Players[src] = nil
    end
end)

-- Exports para otros recursos (Aura Status, Aura Economy, etc.)
exports('GetPlayer', function(source)
    return AuraCore.Players[source]
end)

exports('UpdatePlayerMetadata', function(source, key, value)
    if AuraCore.Players[source] and AuraCore.Players[source].metadata then
        AuraCore.Players[source].metadata[key] = value
        return true
    end
    return false
end)
