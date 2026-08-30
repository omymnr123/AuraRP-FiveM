CREATE TABLE IF NOT EXISTS `players` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `license` VARCHAR(50) NOT NULL UNIQUE,
    `citizenid` VARCHAR(10) NOT NULL UNIQUE,
    `metadata` LONGTEXT NOT NULL DEFAULT '{}' CHECK (json_valid(`metadata`)),
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `last_login` TIMESTAMP NULL DEFAULT NULL,
    INDEX `idx_license` (`license`),
    INDEX `idx_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
