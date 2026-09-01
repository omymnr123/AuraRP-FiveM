-- ============================================================================
-- AURA JOBS & UNIVERSAL BILLING SYSTEM - DATABASE MIGRATION
-- Base de Datos: aurarp | Compatible con MariaDB / MySQL 8.0+
-- ============================================================================

USE `aurarp`;

-- 1. Añadir columnas de empleo y estado de servicio a la tabla `characters`
ALTER TABLE `characters`
  ADD COLUMN IF NOT EXISTS `job` VARCHAR(50) NOT NULL DEFAULT 'unemployed' AFTER `inventory`,
  ADD COLUMN IF NOT EXISTS `job_grade` INT(11) NOT NULL DEFAULT 0 AFTER `job`,
  ADD COLUMN IF NOT EXISTS `job_duty` TINYINT(1) NOT NULL DEFAULT 0 AFTER `job_grade`;

-- 2. Índices de optimización para consultas masivas de nóminas y servicio
ALTER TABLE `characters`
  ADD INDEX IF NOT EXISTS `idx_character_job` (`job`),
  ADD INDEX IF NOT EXISTS `idx_character_job_duty` (`job_duty`);

-- 3. Tabla para la gestión de fondos societarios (Cuentas de Empresa)
CREATE TABLE IF NOT EXISTS `aura_societies` (
  `name` VARCHAR(50) NOT NULL,
  `label` VARCHAR(100) NOT NULL,
  `balance` BIGINT(20) NOT NULL DEFAULT 0,
  `last_updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Semilla de sociedades predeterminadas del servidor
INSERT INTO `aura_societies` (`name`, `label`, `balance`) VALUES
  ('police', 'Los Santos Police Department', 50000),
  ('ambulance', 'Emergency Medical Services', 50000),
  ('mechanic', 'Los Santos Customs', 25000),
  ('burgershot', 'Burgershot Vespucci', 15000),
  ('bahama', 'Bahama Mamas West', 15000),
  ('vanilla', 'Vanilla Unicorn Club', 15000),
  ('yellowjack', 'Yellow Jack Inn', 10000),
  ('pearls', 'Pearls Seafood Restaurant', 12000),
  ('taxi', 'Downtown Cab Co.', 10000),
  ('cardealer', 'Premium Deluxe Motorsport', 100000),
  ('tequilala', 'Tequi-la-la Bar & Club', 15000),
  ('vazou', 'Discoteca Marc Vazou', 15000),
  ('paletoliquor', 'Paleto Bay Liquor Store', 15000),
  ('henhouse', 'The Hen House Bar', 15000)
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`);

-- 5. Tabla de Registro y Auditoría Fiscal de Ventas 24/7 (Cero Pérdida de Datos)
CREATE TABLE IF NOT EXISTS `aura_vendor_transactions` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `citizenid` VARCHAR(50) NOT NULL,
  `buyer_name` VARCHAR(100) NOT NULL DEFAULT 'Ciudadano',
  `business` VARCHAR(50) NOT NULL,
  `business_label` VARCHAR(100) NOT NULL,
  `items` LONGTEXT NOT NULL,
  `total_price` INT(11) NOT NULL,
  `payment_method` ENUM('cash', 'bank') NOT NULL DEFAULT 'cash',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_vendor_business` (`business`),
  INDEX `idx_vendor_citizenid` (`citizenid`),
  INDEX `idx_vendor_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

