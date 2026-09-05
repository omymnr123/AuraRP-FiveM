-- ============================================================================
-- AURA RP - SISTEMA DE INVERNADEROS Y CULTIVO CLANDESTINO (PROJECT GREENHOUSE)
-- Base de Datos: aurarp
-- ============================================================================
USE `aurarp`;

-- 1. Tabla de Invernaderos Físicos y Puntos de Entrada por Organización
CREATE TABLE IF NOT EXISTS `aura_greenhouses` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `gang_id` VARCHAR(50) NOT NULL,
  `exterior_x` DOUBLE NOT NULL,
  `exterior_y` DOUBLE NOT NULL,
  `exterior_z` DOUBLE NOT NULL,
  `exterior_h` FLOAT NOT NULL DEFAULT 0.0,
  `created_by` VARCHAR(100) DEFAULT 'Admin',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP() ON UPDATE CURRENT_TIMESTAMP(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_greenhouse_gang` (`gang_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Tabla de Plantas Persistentes, Estados Biológicos y Ciclo de Vida
CREATE TABLE IF NOT EXISTS `aura_plants` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `gang_id` VARCHAR(50) NOT NULL,
  `stage` INT(11) NOT NULL DEFAULT 1 COMMENT 'Fase visual 1 a 4',
  `growth` FLOAT NOT NULL DEFAULT 0.0 COMMENT 'Porcentaje de crecimiento 0.0 a 100.0',
  `thirst` FLOAT NOT NULL DEFAULT 100.0 COMMENT 'Nivel de hidratación 0.0 a 100.0',
  `nutrition` FLOAT NOT NULL DEFAULT 100.0 COMMENT 'Nivel de abono NPK 0.0 a 100.0',
  `coords_x` DOUBLE NOT NULL,
  `coords_y` DOUBLE NOT NULL,
  `coords_z` DOUBLE NOT NULL,
  `heading` FLOAT NOT NULL DEFAULT 0.0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP() ON UPDATE CURRENT_TIMESTAMP(),
  PRIMARY KEY (`id`),
  KEY `idx_plants_gang` (`gang_id`),
  KEY `idx_plants_stage` (`stage`, `growth`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
