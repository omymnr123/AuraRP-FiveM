CREATE TABLE IF NOT EXISTS `characters` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `slot` INT(11) NOT NULL,
  `firstname` VARCHAR(50) NOT NULL,
  `lastname` VARCHAR(50) NOT NULL,
  `nationality` VARCHAR(50) NOT NULL,
  `dob` DATE NOT NULL,
  `gender` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '0: Male, 1: Female',
  `accounts` LONGTEXT NOT NULL DEFAULT '{"cash":0,"bank":5000,"black_money":0}' COMMENT 'JSON: cash, bank, black_money' CHECK (json_valid(`accounts`)),
  `metadata` LONGTEXT NOT NULL COMMENT 'JSON: health, appearance, last_location',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_played` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_citizenid_slot` (`citizenid`, `slot`),
  CONSTRAINT `fk_characters_players` FOREIGN KEY (`citizenid`) REFERENCES `players` (`citizenid`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
