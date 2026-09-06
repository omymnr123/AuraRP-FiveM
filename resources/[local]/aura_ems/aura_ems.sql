-- ============================================================================
-- AURA EMS: DATABASE SCHEMA AND DEFAULT SEEDS (20 ENCRYPTED CHANNELS)
-- ============================================================================

USE `aurarp`;

-- 1. Tabla de Historial Médico y Fichas Clínicas
CREATE TABLE IF NOT EXISTS `aura_medical_records` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `patient_name` varchar(100) NOT NULL,
  `doctor_citizenid` varchar(50) DEFAULT NULL,
  `doctor_name` varchar(100) DEFAULT 'Sistema Médico Automatizado',
  `diagnosis` text NOT NULL,
  `injuries_json` longtext NOT NULL COMMENT 'Detalle de huesos dañados y tipo de trauma',
  `vital_signs` longtext NOT NULL COMMENT 'Salud, temperatura, hambre, sed al momento del scan',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_medical_citizenid` (`citizenid`),
  KEY `idx_medical_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Canales de Radio Encriptada Exclusiva EMS (Canales #1 al #20)
DROP TABLE IF EXISTS `aura_ems_radio_channels`;

CREATE TABLE `aura_ems_radio_channels` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `channel_index` int(11) NOT NULL,
  `label` varchar(64) NOT NULL,
  `frequency` decimal(4,1) NOT NULL,
  `color` varchar(16) NOT NULL DEFAULT '#40E0D0',
  `blip_color` int(11) NOT NULL DEFAULT 1,
  `is_encrypted` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_ems_channel` (`channel_index`),
  KEY `idx_ems_freq` (`frequency`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Inserción de los 20 Canales Frecuenciales Médicos Oficiales (Canal #1 al Canal #20)
INSERT INTO `aura_ems_radio_channels` (`channel_index`, `label`, `frequency`, `color`, `blip_color`, `is_encrypted`) VALUES
(1, 'Canal #1', 10.1, '#40E0D0', 1, 1),
(2, 'Canal #2', 10.2, '#40E0D0', 1, 1),
(3, 'Canal #3', 10.3, '#40E0D0', 1, 1),
(4, 'Canal #4', 10.4, '#40E0D0', 1, 1),
(5, 'Canal #5', 10.5, '#FF007F', 48, 1),
(6, 'Canal #6', 10.6, '#FF007F', 48, 1),
(7, 'Canal #7', 10.7, '#FF007F', 48, 1),
(8, 'Canal #8', 10.8, '#40E0D0', 38, 1),
(9, 'Canal #9', 10.9, '#40E0D0', 38, 1),
(10, 'Canal #10', 11.0, '#38bdf8', 3, 1),
(11, 'Canal #11', 11.1, '#f59e0b', 46, 1),
(12, 'Canal #12', 11.2, '#3b82f6', 38, 1),
(13, 'Canal #13', 11.3, '#ef4444', 1, 1),
(14, 'Canal #14', 11.4, '#40E0D0', 1, 1),
(15, 'Canal #15', 11.5, '#a855f7', 27, 1),
(16, 'Canal #16', 11.6, '#10b981', 2, 1),
(17, 'Canal #17', 11.7, '#64748b', 39, 1),
(18, 'Canal #18', 11.8, '#40E0D0', 1, 1),
(19, 'Canal #19', 11.9, '#FF007F', 48, 1),
(20, 'Canal #20', 12.0, '#d946ef', 83, 1)
ON DUPLICATE KEY UPDATE 
  `label` = VALUES(`label`), 
  `frequency` = VALUES(`frequency`), 
  `color` = VALUES(`color`),
  `blip_color` = VALUES(`blip_color`),
  `is_encrypted` = VALUES(`is_encrypted`);
