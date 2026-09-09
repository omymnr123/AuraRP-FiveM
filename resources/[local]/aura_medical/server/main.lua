-- ============================================================================
-- AURA MEDICAL: SERVER MAIN CONTROLLER
-- ============================================================================

CreateThread(function()
    -- Asegurar tablas requeridas en base de datos
    pcall(function()
        MySQL.query([=[
            CREATE TABLE IF NOT EXISTS `aura_medical_records` (
              `id` int(11) NOT NULL AUTO_INCREMENT,
              `citizenid` varchar(50) NOT NULL,
              `patient_name` varchar(100) NOT NULL,
              `doctor_citizenid` varchar(50) DEFAULT NULL,
              `doctor_name` varchar(100) DEFAULT 'Cuerpo Médico AuraRP',
              `diagnosis` text NOT NULL,
              `injuries_json` longtext NOT NULL,
              `treatments_json` longtext DEFAULT NULL,
              `vital_signs` longtext NOT NULL,
              `outcome` varchar(50) NOT NULL DEFAULT 'Estabilizado / Reanimado',
              `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
              PRIMARY KEY (`id`),
              KEY `idx_medical_citizenid` (`citizenid`),
              KEY `idx_medical_doctor` (`doctor_citizenid`),
              KEY `idx_medical_created` (`created_at`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]=])

        -- Migraciones seguras para columnas sin errores en consola
        MySQL.query([[
            SELECT COLUMN_NAME 
            FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_NAME = 'aura_medical_records' 
            AND TABLE_SCHEMA = DATABASE() 
            AND COLUMN_NAME IN ('treatments_json', 'outcome');
        ]], {}, function(result)
            local hasTreatments = false
            local hasOutcome = false
            if result and type(result) == "table" then
                for _, row in ipairs(result) do
                    if row.COLUMN_NAME == 'treatments_json' then hasTreatments = true end
                    if row.COLUMN_NAME == 'outcome' then hasOutcome = true end
                end
            end

            if not hasTreatments then
                MySQL.query("ALTER TABLE `aura_medical_records` ADD COLUMN `treatments_json` longtext DEFAULT NULL AFTER `injuries_json`")
            end
            if not hasOutcome then
                MySQL.query("ALTER TABLE `aura_medical_records` ADD COLUMN `outcome` varchar(50) NOT NULL DEFAULT 'Estabilizado / Reanimado' AFTER `vital_signs`")
            end
        end)

        MySQL.query([=[
            CREATE TABLE IF NOT EXISTS `aura_medical_diagnoses` (
              `id` int(11) NOT NULL AUTO_INCREMENT,
              `session_id` varchar(64) NOT NULL,
              `patient_src` int(11) NOT NULL,
              `medic_src` int(11) NOT NULL,
              `bpm_initial` int(11) NOT NULL DEFAULT 75,
              `bpm_final` int(11) NOT NULL DEFAULT 75,
              `total_injuries` int(11) NOT NULL DEFAULT 0,
              `cured_injuries` int(11) NOT NULL DEFAULT 0,
              `is_revived` tinyint(1) NOT NULL DEFAULT 0,
              `payload_json` longtext NOT NULL,
              `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
              PRIMARY KEY (`id`),
              KEY `idx_diag_session` (`session_id`),
              KEY `idx_diag_created` (`created_at`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]=])
    end)
end)

local function InitPlayerMedicalState(src)
    if not src or src <= 0 then return end

    local medicalData = nil

    -- Intentar obtener desde aura_multichar
    if exports.aura_multichar and exports.aura_multichar.GetActiveCharacter then
        local char = exports.aura_multichar:GetActiveCharacter(src)
        if char and char.metadata and char.metadata.medical and char.metadata.medical.bone_damage then
            medicalData = char.metadata.medical.bone_damage
        end
    end

    -- Fallback aura_core
    if not medicalData and exports.aura_core and exports.aura_core.GetPlayer then
        local player = exports.aura_core:GetPlayer(src)
        if player and player.metadata and player.metadata.medical and player.metadata.medical.bone_damage then
            medicalData = player.metadata.medical.bone_damage
        end
    end

    local defaultDamage = {
        head = { health = 100, injuries = {} },
        torso = { health = 100, injuries = {} },
        right_arm = { health = 100, injuries = {} },
        left_arm = { health = 100, injuries = {} },
        right_hand = { health = 100, injuries = {} },
        left_hand = { health = 100, injuries = {} },
        right_leg = { health = 100, injuries = {} },
        left_leg = { health = 100, injuries = {} },
        right_foot = { health = 100, injuries = {} },
        left_foot = { health = 100, injuries = {} }
    }

    local finalData = medicalData or defaultDamage
    Player(src).state:set('bone_damage', finalData, true)
    TriggerClientEvent('aura_medical:client:loadDamage', src, finalData)
end

RegisterNetEvent('aura_core:playerLoaded', function()
    local src = source
    InitPlayerMedicalState(src)
end)

RegisterNetEvent('aura_multichar:server:characterSelected', function()
    local src = source
    InitPlayerMedicalState(src)
end)
