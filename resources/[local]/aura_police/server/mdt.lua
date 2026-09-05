-- ============================================================================
-- AURA POLICE: SERVER MDT ENGINE & DATABASE AUTO-MIGRATOR
-- Direct Database Bridges, Warrants, Inmates, Vehicle BOLOs & Fines
-- ============================================================================

-- ============================================================================
-- 1. AUTO-MIGRACIÓN DE BASE DE DATOS (TABLAS POLICIALES REQUERIDAS)
-- ============================================================================

CreateThread(function()
    Wait(1000)

    -- 1. Tabla de Multas Policiales
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `aura_police_fines` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `citizenid` varchar(50) NOT NULL,
            `receiver_name` varchar(100) NOT NULL,
            `officer_citizenid` varchar(50) NOT NULL,
            `officer_name` varchar(100) NOT NULL,
            `amount` int(11) NOT NULL,
            `reason` varchar(255) NOT NULL,
            `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
            PRIMARY KEY (`id`),
            KEY `idx_fine_citizenid` (`citizenid`),
            KEY `idx_fine_officer` (`officer_citizenid`),
            KEY `idx_fine_date` (`created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    -- 2. Tabla de Condenas y Cárcel
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `aura_police_jail` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `citizenid` varchar(50) NOT NULL,
            `character_id` int(11) NOT NULL,
            `jail_time` int(11) NOT NULL COMMENT 'Minutos restantes de condena',
            `reason` varchar(255) NOT NULL,
            `officer_name` varchar(100) NOT NULL,
            `status` enum('active','completed') NOT NULL DEFAULT 'active',
            `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
            `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
            PRIMARY KEY (`id`),
            KEY `idx_jail_citizenid` (`citizenid`),
            KEY `idx_jail_status` (`status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    -- 3. Tabla de Órdenes de Búsqueda y Captura (Warrants)
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `aura_police_warrants` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `citizenid` varchar(50) DEFAULT NULL,
            `suspect_name` varchar(100) NOT NULL,
            `reason` varchar(255) NOT NULL,
            `officer_name` varchar(100) NOT NULL,
            `severity` enum('low','medium','high','urgent') NOT NULL DEFAULT 'medium',
            `status` enum('active','resolved','cancelled') NOT NULL DEFAULT 'active',
            `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
            PRIMARY KEY (`id`),
            KEY `idx_warrant_citizenid` (`citizenid`),
            KEY `idx_warrant_status` (`status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    -- 4. Tabla de BOLO de Vehículos
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `aura_police_vehicle_bolo` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `plate` varchar(12) NOT NULL,
            `model` varchar(50) NOT NULL DEFAULT 'Desconocido',
            `owner_name` varchar(100) NOT NULL DEFAULT 'Desconocido',
            `reason` varchar(255) NOT NULL,
            `officer_name` varchar(100) NOT NULL,
            `status` enum('active','resolved') NOT NULL DEFAULT 'active',
            `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
            PRIMARY KEY (`id`),
            KEY `idx_plate_active` (`plate`,`status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    -- 5. Tabla de Canales de Radio-Patrullas Policiales
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `aura_police_radio_channels` (
            `channel_id` varchar(32) NOT NULL,
            `label` varchar(64) NOT NULL,
            `color` varchar(16) NOT NULL DEFAULT '#00f2fe',
            `blip_color` int(11) NOT NULL DEFAULT 38,
            `frequency` int(11) NOT NULL,
            `is_mando` tinyint(1) NOT NULL DEFAULT 0,
            `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
            PRIMARY KEY (`channel_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    -- Poblar canales por defecto si la tabla está vacía
    local countChannels = MySQL.scalar.await('SELECT COUNT(*) FROM `aura_police_radio_channels`')
    if not countChannels or countChannels == 0 then
        MySQL.query([[
            INSERT INTO `aura_police_radio_channels` (`channel_id`, `label`, `color`, `blip_color`, `frequency`, `is_mando`) VALUES
            ('mando', 'Canal de Mando', '#ffb700', 46, 100, 1),
            ('patrol_1', 'Patrulla #01', '#00f2fe', 38, 101, 0),
            ('patrol_2', 'Patrulla #02', '#3b82f6', 3, 102, 0),
            ('patrol_3', 'Patrulla #03', '#00ff9d', 2, 103, 0),
            ('patrol_4', 'Patrulla #04', '#ff007f', 48, 104, 0),
            ('patrol_5', 'Patrulla #05', '#ff6b35', 47, 105, 0),
            ('patrol_6', 'Patrulla #06', '#9d4edd', 27, 106, 0),
            ('patrol_7', 'Patrulla #07', '#ff2a55', 1, 107, 0),
            ('patrol_8', 'Patrulla #08', '#ffffff', 0, 108, 0),
            ('patrol_9', 'Patrulla #09', '#ffff00', 5, 109, 0),
            ('patrol_10', 'Patrulla #10', '#06d6a0', 25, 110, 0),
            ('patrol_11', 'Patrulla #11', '#8338ec', 7, 111, 0),
            ('patrol_12', 'Patrulla #12', '#ff477e', 8, 112, 0),
            ('patrol_13', 'Patrulla #13', '#3a86ff', 18, 113, 0),
            ('patrol_14', 'Patrulla #14', '#fb5607', 17, 114, 0),
            ('patrol_15', 'Patrulla #15', '#70e000', 43, 115, 0),
            ('patrol_16', 'Patrulla #16', '#0077b6', 29, 116, 0),
            ('patrol_17', 'Patrulla #17', '#e0aaff', 19, 117, 0),
            ('patrol_18', 'Patrulla #18', '#b5179e', 21, 118, 0),
            ('patrol_19', 'Patrulla #19', '#a0aec0', 40, 119, 0),
            ('patrol_20', 'Patrulla #20', '#4cc9f0', 68, 120, 0);
        ]])
    end

    -- 6. Verificación de columna jail_time en characters
    local checkCol = MySQL.scalar.await([[
        SELECT COUNT(*) FROM information_schema.COLUMNS 
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'characters' AND COLUMN_NAME = 'jail_time'
    ]])
    if checkCol == 0 then
        MySQL.query([[
            ALTER TABLE `characters` ADD COLUMN `jail_time` int(11) NOT NULL DEFAULT 0 AFTER `badge`;
        ]])
        print("^2[AURA POLICE] Columna 'jail_time' agregada exitosamente a la tabla characters.^7")
    end

    print("^2[AURA POLICE] Auto-migración verificada: Todas las tablas del MDT Policial y Radio operativas en MariaDB.^7")
end)

-- ============================================================================
-- 2. EXPORTS PARA GESTIÓN POLICIAL MODULAR Y SIN COMANDOS
-- ============================================================================

--- Emite una sanción / multa policial automatizada
--- Descuenta del banco del ciudadano infractor e ingresa al 100% en la cuenta del LSPD
--- @param data table { targetSrc, citizenid, amount, reason }
--- @param officerSrc number ID de servidor del agente actuante
--- @return boolean success, string message
local function IssueFine(data, officerSrc)
    if not data or not data.amount or data.amount <= 0 then
        return false, "Importe de multa inválido."
    end

    local amount = math.floor(tonumber(data.amount))
    local reason = tostring(data.reason or "Infracción Policial LSPD")
    local suspect = nil
    local suspectSrc = nil

    if data.targetSrc and GetPlayerName(tostring(data.targetSrc)) then
        suspectSrc = tonumber(data.targetSrc)
        local char = exports.aura_multichar:GetActiveCharacter(suspectSrc)
        if char then suspect = char end
    elseif data.citizenid then
        suspect = MySQL.single.await('SELECT id, citizenid, firstname, lastname FROM characters WHERE citizenid = ?', { data.citizenid })
        for _, pid in ipairs(GetPlayers()) do
            local pSrc = tonumber(pid)
            if pSrc then
                local c = exports.aura_multichar:GetActiveCharacter(pSrc)
                if c and c.citizenid == data.citizenid then
                    suspectSrc = pSrc
                    break
                end
            end
        end
    end

    if not suspect then
        return false, "Ciudadano infractor no localizado en el registro censal."
    end

    local offChar = officerSrc and exports.aura_multichar:GetActiveCharacter(officerSrc)
    local officerName = offChar and string.format("%s %s", offChar.firstname or "", offChar.lastname or "") or "LSPD"
    local officerCid = offChar and offChar.citizenid or "OFFICER"

    -- 1. Cobro en cuenta bancaria del sospechoso mediante aura_economy
    local debited, _, txId = exports.aura_economy:RemoveMoney(
        suspect.id,
        'bank',
        amount,
        string.format("Multa Policial: %s", reason),
        { officer = officerName, officerCid = officerCid }
    )

    -- 2. Acreditación íntegra a la sociedad policial mediante aura_jobs
    exports.aura_jobs:AddSocietyMoney('police', amount, string.format("Cobro de Multa LSPD a %s %s (%s)", suspect.firstname, suspect.lastname, reason), {
        txId = txId,
        suspectCitizenId = suspect.citizenid,
        officer = officerName
    })

    -- 3. Registro en base de datos
    MySQL.insert([[
        INSERT INTO aura_police_fines (citizenid, receiver_name, officer_citizenid, officer_name, amount, reason)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        suspect.citizenid,
        string.format("%s %s", suspect.firstname, suspect.lastname),
        officerCid,
        officerName,
        amount,
        reason
    })

    -- 4. Notificar al infractor si está conectado
    if suspectSrc then
        TriggerClientEvent('ox_lib:notify', suspectSrc, {
            title = 'Sanción Notificada',
            description = string.format("Has sido sancionado con $%s.\nMotivo: %s\nOficial: %s", lib.math.groupdigits(amount), reason, officerName),
            type = 'error',
            duration = 9000
        })
    end

    return true, string.format("Sanción de $%s tramitada y cobrada con éxito.", lib.math.groupdigits(amount))
end
exports('IssueFine', IssueFine)

--- Obtener el historial judicial y policial completo de un ciudadano
--- @param citizenid string
--- @return table
local function GetCitizenRecords(citizenid)
    if not citizenid then return {} end
    local fines = MySQL.query.await('SELECT amount, reason, officer_name, created_at FROM aura_police_fines WHERE citizenid = ? ORDER BY id DESC LIMIT 10', { citizenid }) or {}
    local jail = MySQL.query.await('SELECT jail_time, reason, officer_name, status, created_at FROM aura_police_jail WHERE citizenid = ? ORDER BY id DESC LIMIT 10', { citizenid }) or {}
    local warrants = MySQL.query.await('SELECT id, reason, severity, status, created_at FROM aura_police_warrants WHERE citizenid = ? AND status = ?', { citizenid, 'active' }) or {}

    return {
        fines = fines,
        jail = jail,
        warrants = warrants,
        hasActiveWarrant = #warrants > 0
    }
end
exports('GetCitizenRecords', GetCitizenRecords)
