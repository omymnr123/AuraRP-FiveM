-- ============================================================================
-- AURA POLICE & MDT ECOSYSTEM - COMPLETE DATABASE SCHEMA
-- Compatible con MySQL 8.0+ / MariaDB 10.4+
-- Base de Datos: aurarp
-- ============================================================================

USE `aurarp`;

-- 1. Tabla de Historial de Sanciones y Multas Policiales
CREATE TABLE IF NOT EXISTS `aura_police_fines` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `receiver_name` VARCHAR(100) NOT NULL,
  `officer_citizenid` VARCHAR(50) NOT NULL,
  `officer_name` VARCHAR(100) NOT NULL,
  `amount` INT(11) NOT NULL,
  `reason` VARCHAR(255) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_fine_citizenid` (`citizenid`),
  KEY `idx_fine_officer` (`officer_citizenid`),
  KEY `idx_fine_date` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Tabla de Encarcelamientos y Sentencias Penitenciarias
CREATE TABLE IF NOT EXISTS `aura_police_jail` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `character_id` INT(11) NOT NULL,
  `jail_time` INT(11) NOT NULL COMMENT 'Minutos restantes de condena',
  `reason` VARCHAR(255) NOT NULL,
  `officer_name` VARCHAR(100) NOT NULL,
  `status` ENUM('active', 'completed') NOT NULL DEFAULT 'active',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_jail_citizenid` (`citizenid`),
  KEY `idx_jail_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Tabla de Órdenes de Búsqueda y Captura (Warrants / BOLO)
CREATE TABLE IF NOT EXISTS `aura_police_warrants` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `suspect_name` VARCHAR(100) NOT NULL,
  `reason` VARCHAR(255) NOT NULL,
  `officer_name` VARCHAR(100) NOT NULL,
  `severity` ENUM('low', 'medium', 'high', 'urgent') NOT NULL DEFAULT 'medium',
  `status` ENUM('active', 'resolved', 'cancelled') NOT NULL DEFAULT 'active',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_warrant_citizenid` (`citizenid`),
  KEY `idx_warrant_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Tabla de Atestados e Informes Policiales (Incident Reports)
CREATE TABLE IF NOT EXISTS `aura_police_reports` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(150) NOT NULL,
  `author_name` VARCHAR(100) NOT NULL,
  `involved_citizenid` VARCHAR(50) DEFAULT NULL,
  `involved_name` VARCHAR(100) DEFAULT NULL,
  `details` LONGTEXT NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_report_involved` (`involved_citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Tabla de Vehículos en Búsqueda (BOLO Vehicular)
CREATE TABLE IF NOT EXISTS `aura_police_vehicle_bolo` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `plate` VARCHAR(12) NOT NULL,
  `model` VARCHAR(50) NOT NULL DEFAULT 'Desconocido',
  `owner_name` VARCHAR(100) NOT NULL DEFAULT 'Desconocido',
  `reason` VARCHAR(255) NOT NULL,
  `officer_name` VARCHAR(100) NOT NULL,
  `status` ENUM('active', 'resolved') NOT NULL DEFAULT 'active',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_plate_active` (`plate`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Campo de Tiempo de Cárcel en Characters (para comprobación rápida en login)
ALTER TABLE `characters` 
  ADD COLUMN IF NOT EXISTS `jail_time` INT(11) NOT NULL DEFAULT 0 AFTER `job_duty`;

-- 7. Asegurar la Sociedad Policial en aura_societies
INSERT INTO `aura_societies` (`name`, `label`, `balance`) 
VALUES ('police', 'Los Santos Police Department', 50000)
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`);
