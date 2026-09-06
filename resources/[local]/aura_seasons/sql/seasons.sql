-- ============================================================================
-- AURARP SEASONS & TIME CONTROLLER DATABASE SCHEMA
-- ============================================================================

CREATE TABLE IF NOT EXISTS `aura_seasons` (
    `id` INT(11) NOT NULL PRIMARY KEY DEFAULT 1,
    `current_season` VARCHAR(32) NOT NULL DEFAULT 'spring',
    `current_day` INT(11) NOT NULL DEFAULT 1,
    `day_in_season` INT(11) NOT NULL DEFAULT 1,
    `last_rotation` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `weather_override` VARCHAR(32) DEFAULT NULL,
    `current_weather` VARCHAR(32) NOT NULL DEFAULT 'CLEAR',
    `base_temperature` DECIMAL(4,1) NOT NULL DEFAULT 18.0,
    `has_snow` TINYINT(1) NOT NULL DEFAULT 0,
    `current_hour` INT(11) NOT NULL DEFAULT 12,
    `current_minute` INT(11) NOT NULL DEFAULT 0,
    `time_frozen` TINYINT(1) NOT NULL DEFAULT 0,
    `day_duration` INT(11) NOT NULL DEFAULT 2000,
    `night_duration` INT(11) NOT NULL DEFAULT 2000,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Migración segura de columnas si la tabla ya existía
ALTER TABLE `aura_seasons`
    ADD COLUMN IF NOT EXISTS `current_weather` VARCHAR(32) NOT NULL DEFAULT 'CLEAR',
    ADD COLUMN IF NOT EXISTS `base_temperature` DECIMAL(4,1) NOT NULL DEFAULT 18.0,
    ADD COLUMN IF NOT EXISTS `has_snow` TINYINT(1) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS `current_hour` INT(11) NOT NULL DEFAULT 12,
    ADD COLUMN IF NOT EXISTS `current_minute` INT(11) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS `time_frozen` TINYINT(1) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS `day_duration` INT(11) NOT NULL DEFAULT 2000,
    ADD COLUMN IF NOT EXISTS `night_duration` INT(11) NOT NULL DEFAULT 2000,
    ADD COLUMN IF NOT EXISTS `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

-- Inserción inicial persistente (idempotente)
INSERT INTO `aura_seasons` (`id`, `current_season`, `current_day`, `day_in_season`, `last_rotation`, `weather_override`, `current_weather`, `base_temperature`, `has_snow`, `current_hour`, `current_minute`, `time_frozen`, `day_duration`, `night_duration`)
VALUES (1, 'spring', 1, 1, NOW(), NULL, 'CLEAR', 18.0, 0, 12, 0, 0, 2000, 2000)
ON DUPLICATE KEY UPDATE `id` = 1;
