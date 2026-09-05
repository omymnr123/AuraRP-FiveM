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
  ('henhouse', 'The Hen House Bar', 15000),
  ('antiquebar', 'Antique Bar & Pub', 15000),
  ('barthedrink', 'Bar The Drink & Moscou Club', 15000),
  ('sandyhookah', 'Sandy Hookah Lounge', 15000),
  ('himenbar', 'Himen Bar & Club', 15000),
  ('route68bar', 'Route 68 Clubhouse & Bar', 15000),
  ('cartel', 'Cártel de Sinaloa / Medellín', 50000),
  ('salieri', 'Familia Salieri & Cártel Clandestino', 50000),
  ('ballas', 'East Los Santos Ballas', 25000),
  ('families', 'Chamberlain Gangster Families', 25000),
  ('vagos', 'Los Santos Vagos', 25000),
  ('lostmc', 'The Lost MC Club', 50000),
  ('bratva', 'Bratva (Mafia Rusa)', 50000),
  ('triada', 'Tríada Asiática', 50000),
  ('yakuza', 'Sindicato Yakuza', 50000),
  ('marabunta', 'Marabunta Grande', 50000)
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

-- 6. Tabla de Cerraduras de Puertas por Negocio
CREATE TABLE IF NOT EXISTS `aura_doors` (
  `door_id` VARCHAR(50) NOT NULL,
  `job` VARCHAR(50) NOT NULL DEFAULT '',
  `coords_x` DOUBLE NOT NULL DEFAULT 0,
  `coords_y` DOUBLE NOT NULL DEFAULT 0,
  `coords_z` DOUBLE NOT NULL DEFAULT 0,
  `is_locked` TINYINT(1) NOT NULL DEFAULT 1,
  `distance` FLOAT NOT NULL DEFAULT 2.5,
  PRIMARY KEY (`door_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. Semilla de Puertas Predeterminadas
INSERT INTO `aura_doors` (`door_id`, `is_locked`, `job`, `coords_x`, `coords_y`, `coords_z`, `distance`) VALUES
  ('henhouse_main', 1, 'henhouse', -297.59, 6271.26, 31.51, 2.0),
  ('vazou_main', 1, 'vazou', -1564.44, -974.61, 13.02, 2.0),
  ('vazou_secundaria', 1, 'vazou', -1558.66, -972.22, 13.02, 2.0),
  ('salieri_main', 1, 'salieri', 316.82, -1092.62, 29.42, 2.0),
  ('antiquebar_main', 1, 'antiquebar', 742.84, -2304.53, 20.84, 2.5),
  ('barthedrink_main', 1, 'barthedrink', 1985.39, 3054.49, 47.21, 2.5),
  ('yellowjack_main', 1, 'yellowjack', 1986.04, 3048.36, 47.22, 2.5),
  ('sandyhookah_main', 1, 'sandyhookah', 1888.62, 3747.54, 32.88, 2.5),
  ('himenbar_main', 1, 'himenbar', 980.50, -1805.20, 31.00, 2.5),
  ('route68bar_main', 1, 'route68bar', 982.00, 2664.00, 40.00, 2.5)
ON DUPLICATE KEY UPDATE `job` = VALUES(`job`), `coords_x` = VALUES(`coords_x`), `coords_y` = VALUES(`coords_y`), `coords_z` = VALUES(`coords_z`);



