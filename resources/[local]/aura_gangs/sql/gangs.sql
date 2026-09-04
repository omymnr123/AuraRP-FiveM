-- ============================================================================
-- AURA RP - FASE 5: SISTEMA DE BANDAS Y CÁRTELES (aura_gangs)
-- Base de datos: aurarp
-- ============================================================================
USE `aurarp`;

-- 1. Tabla de Lavadoras Clandestinas (Money Laundering)
CREATE TABLE IF NOT EXISTS `aura_gang_laundry` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `gang` VARCHAR(50) NOT NULL,
  `machine_id` VARCHAR(50) NOT NULL,
  `black_money_input` BIGINT(20) NOT NULL,
  `clean_money_output` BIGINT(20) NOT NULL,
  `tax_fee` BIGINT(20) NOT NULL DEFAULT 0,
  `ready_at` TIMESTAMP NOT NULL,
  `is_collected` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  PRIMARY KEY (`id`),
  KEY `idx_laundry_machine` (`machine_id`),
  KEY `idx_laundry_citizen` (`citizenid`),
  KEY `idx_laundry_ready` (`ready_at`, `is_collected`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Tabla de Territorios y Graffitis (Turf Wars)
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

-- 3. Cuentas Offshore de Organizaciones en aura_societies
INSERT INTO `aura_societies` (`name`, `label`, `balance`) 
VALUES 
  ('cartel', 'Cártel de Sinaloa / Medellín', 50000),
  ('salieri', 'Familia Salieri & Cártel Clandestino', 50000),
  ('vazou', 'Cártel Marc Vazou', 50000),
  ('ballas', 'East Los Santos Ballas', 25000),
  ('families', 'Chamberlain Gangster Families', 25000),
  ('vagos', 'Los Santos Vagos', 25000)
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`);
