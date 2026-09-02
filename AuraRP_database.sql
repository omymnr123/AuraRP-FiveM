-- --------------------------------------------------------
-- Host:                         127.0.0.1
-- Versión del servidor:         10.4.32-MariaDB - mariadb.org binary distribution
-- SO del servidor:              Win64
-- HeidiSQL Versión:             12.21.0.7344
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


-- Volcando estructura de base de datos para aurarp
CREATE DATABASE IF NOT EXISTS `aurarp` /*!40100 DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci */;
USE `aurarp`;

-- Volcando estructura para tabla aurarp.aura_doors
CREATE TABLE IF NOT EXISTS `aura_doors` (
  `door_id` varchar(50) NOT NULL,
  `is_locked` tinyint(1) NOT NULL DEFAULT 1,
  `job` varchar(50) NOT NULL DEFAULT '',
  `coords_x` double NOT NULL DEFAULT 0,
  `coords_y` double NOT NULL DEFAULT 0,
  `coords_z` double NOT NULL DEFAULT 0,
  `distance` float NOT NULL DEFAULT 2.5,
  PRIMARY KEY (`door_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- Volcando datos para la tabla aurarp.aura_doors: ~7 rows (aproximadamente)
INSERT INTO `aura_doors` (`door_id`, `is_locked`, `job`, `coords_x`, `coords_y`, `coords_z`, `distance`) VALUES
	('henhouse_main', 1, 'henhouse', -297.5899963378906, 6271.259765625, 31.510000228881836, 2),
	('police_capitan', 1, 'police', 447.19122314453125, -980.4000244140625, 30.6783447265625, 2.5),
	('police_main', 1, 'police', 434.75604248046875, -981.9296875, 30.6951904296875, 2.5),
	('salieri_1', 1, 'salieri', 316.5758361816406, -1092.6065673828125, 29.4146728515625, 2.5),
	('salieri_main', 1, 'salieri', 316.82000732421875, -1092.6199951171875, 29.420000076293945, 2),
	('vazou_main', 1, 'vazou', -1564.43994140625, -974.6099853515625, 13.020000457763672, 2),
	('vazou_secundaria', 1, 'vazou', -1558.6600341796875, -972.219970703125, 13.020000457763672, 2);

-- Volcando estructura para tabla aurarp.aura_market_items
CREATE TABLE IF NOT EXISTS `aura_market_items` (
  `name` varchar(50) NOT NULL,
  `base_price` int(11) NOT NULL,
  `min_price` int(11) NOT NULL,
  `max_price` int(11) NOT NULL,
  `current_stock` int(11) NOT NULL DEFAULT 0,
  `target_stock` int(11) NOT NULL DEFAULT 1000,
  `elasticity` float NOT NULL DEFAULT 0.05,
  `last_updated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla aurarp.aura_market_items: ~6 rows (aproximadamente)
INSERT INTO `aura_market_items` (`name`, `base_price`, `min_price`, `max_price`, `current_stock`, `target_stock`, `elasticity`, `last_updated`) VALUES
	('copper_ore', 35, 10, 90, 3000, 3000, 0.05, '2026-08-30 17:39:34'),
	('gold_ore', 150, 50, 350, 500, 500, 0.08, '2026-08-30 17:39:34'),
	('iron_ore', 50, 15, 120, 2000, 2000, 0.05, '2026-08-30 17:39:34'),
	('packaged_fish', 45, 12, 110, 1500, 1500, 0.06, '2026-08-30 17:39:34'),
	('raw_meat', 70, 20, 160, 800, 800, 0.07, '2026-08-30 17:39:34'),
	('wood_log', 25, 8, 70, 4000, 4000, 0.04, '2026-08-30 17:39:34');

-- Volcando estructura para tabla aurarp.aura_phone_calls
CREATE TABLE IF NOT EXISTS `aura_phone_calls` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `caller_number` varchar(20) NOT NULL,
  `receiver_number` varchar(20) NOT NULL,
  `status` enum('missed','answered','declined') NOT NULL DEFAULT 'missed',
  `duration` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `caller_number` (`caller_number`),
  CONSTRAINT `aura_phone_calls_ibfk_1` FOREIGN KEY (`caller_number`) REFERENCES `characters` (`phone_number`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla aurarp.aura_phone_calls: ~8 rows (aproximadamente)
INSERT INTO `aura_phone_calls` (`id`, `caller_number`, `receiver_number`, `status`, `duration`, `created_at`) VALUES
	(1, '555-8966', '652125', 'declined', 0, '2026-08-31 09:25:54'),
	(2, '555-8966', '5232123', 'declined', 0, '2026-08-31 09:26:52'),
	(3, '555-8966', '652125', 'declined', 0, '2026-08-31 09:30:11'),
	(4, '555-8966', '652125', 'declined', 0, '2026-08-31 09:34:41'),
	(5, '555-8966', '5232123', 'declined', 0, '2026-08-31 09:42:15'),
	(6, '555-8966', '5232123', 'declined', 0, '2026-08-31 14:16:15'),
	(7, '555-8966', '5232123', 'declined', 0, '2026-08-31 14:18:17'),
	(8, '555-8966', '5232123', 'declined', 0, '2026-08-31 14:19:03');

-- Volcando estructura para tabla aurarp.aura_phone_chats
CREATE TABLE IF NOT EXISTS `aura_phone_chats` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `number_1` varchar(20) NOT NULL,
  `number_2` varchar(20) NOT NULL,
  `last_message` varchar(255) DEFAULT '',
  `last_update` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_number_1` (`number_1`),
  KEY `idx_number_2` (`number_2`),
  KEY `idx_chat_pair` (`number_1`,`number_2`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla aurarp.aura_phone_chats: ~1 rows (aproximadamente)
INSERT INTO `aura_phone_chats` (`id`, `number_1`, `number_2`, `last_message`, `last_update`) VALUES
	(1, '555-8966', '5232123', '[location]', '2026-08-31 10:19:28');

-- Volcando estructura para tabla aurarp.aura_phone_contacts
CREATE TABLE IF NOT EXISTS `aura_phone_contacts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `owner_number` varchar(20) NOT NULL,
  `contact_number` varchar(20) NOT NULL,
  `contact_name` varchar(50) NOT NULL,
  `is_favorite` tinyint(1) DEFAULT 0,
  `note` varchar(255) DEFAULT '',
  `avatar_url` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `owner_number` (`owner_number`),
  CONSTRAINT `aura_phone_contacts_ibfk_1` FOREIGN KEY (`owner_number`) REFERENCES `characters` (`phone_number`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla aurarp.aura_phone_contacts: ~0 rows (aproximadamente)
INSERT INTO `aura_phone_contacts` (`id`, `owner_number`, `contact_number`, `contact_name`, `is_favorite`, `note`, `avatar_url`) VALUES
	(1, '555-8966', '5232123', 'new', 0, '', NULL);

-- Volcando estructura para tabla aurarp.aura_phone_gallery
CREATE TABLE IF NOT EXISTS `aura_phone_gallery` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `owner_number` varchar(50) NOT NULL,
  `media_url` longtext NOT NULL,
  `media_type` varchar(20) DEFAULT 'image',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_owner_gallery` (`owner_number`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla aurarp.aura_phone_gallery: ~0 rows (aproximadamente)
INSERT INTO `aura_phone_gallery` (`id`, `owner_number`, `media_url`, `media_type`, `created_at`) VALUES
	(1, '555-8966', 'https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=800&q=80', 'image', '2026-08-31 15:04:03');

-- Volcando estructura para tabla aurarp.aura_phone_messages
CREATE TABLE IF NOT EXISTS `aura_phone_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `chat_id` int(11) NOT NULL,
  `sender_number` varchar(20) NOT NULL,
  `message_type` enum('text','image','audio','location') NOT NULL DEFAULT 'text',
  `content` text NOT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_sender` (`sender_number`),
  KEY `idx_chat` (`chat_id`),
  CONSTRAINT `fk_msg_chat` FOREIGN KEY (`chat_id`) REFERENCES `aura_phone_chats` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla aurarp.aura_phone_messages: ~2 rows (aproximadamente)
INSERT INTO `aura_phone_messages` (`id`, `chat_id`, `sender_number`, `message_type`, `content`, `is_read`, `created_at`) VALUES
	(1, 1, '555-8966', 'text', 'Muy buenas', 0, '2026-08-31 10:19:24'),
	(2, 1, '555-8966', 'location', '69.40, -1549.21', 0, '2026-08-31 10:19:28');

-- Volcando estructura para tabla aurarp.aura_police_fines
CREATE TABLE IF NOT EXISTS `aura_police_fines` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `receiver_name` varchar(100) NOT NULL,
  `officer_citizenid` varchar(50) NOT NULL,
  `officer_name` varchar(100) NOT NULL,
  `amount` int(11) NOT NULL,
  `reason` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_fine_citizenid` (`citizenid`),
  KEY `idx_fine_officer` (`officer_citizenid`),
  KEY `idx_fine_date` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla aurarp.aura_police_fines: ~0 rows (aproximadamente)

-- Volcando estructura para tabla aurarp.aura_police_jail
CREATE TABLE IF NOT EXISTS `aura_police_jail` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `character_id` int(11) NOT NULL,
  `jail_time` int(11) NOT NULL COMMENT 'Minutos restantes de condena',
  `reason` varchar(255) NOT NULL,
  `officer_name` varchar(100) NOT NULL,
  `status` enum('active','completed') NOT NULL DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_jail_citizenid` (`citizenid`),
  KEY `idx_jail_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla aurarp.aura_police_jail: ~0 rows (aproximadamente)

-- Volcando estructura para tabla aurarp.aura_police_reports
CREATE TABLE IF NOT EXISTS `aura_police_reports` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(150) NOT NULL,
  `author_name` varchar(100) NOT NULL,
  `involved_citizenid` varchar(50) DEFAULT NULL,
  `involved_name` varchar(100) DEFAULT NULL,
  `details` longtext NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_report_involved` (`involved_citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla aurarp.aura_police_reports: ~0 rows (aproximadamente)

-- Volcando estructura para tabla aurarp.aura_police_vehicle_bolo
CREATE TABLE IF NOT EXISTS `aura_police_vehicle_bolo` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `plate` varchar(12) NOT NULL,
  `model` varchar(50) NOT NULL DEFAULT 'Desconocido',
  `owner_name` varchar(100) NOT NULL DEFAULT 'Desconocido',
  `reason` varchar(255) NOT NULL,
  `officer_name` varchar(100) NOT NULL,
  `status` enum('active','resolved') NOT NULL DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_plate_active` (`plate`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla aurarp.aura_police_vehicle_bolo: ~0 rows (aproximadamente)

-- Volcando estructura para tabla aurarp.aura_police_warrants
CREATE TABLE IF NOT EXISTS `aura_police_warrants` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `suspect_name` varchar(100) NOT NULL,
  `reason` varchar(255) NOT NULL,
  `officer_name` varchar(100) NOT NULL,
  `severity` enum('low','medium','high','urgent') NOT NULL DEFAULT 'medium',
  `status` enum('active','resolved','cancelled') NOT NULL DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_warrant_citizenid` (`citizenid`),
  KEY `idx_warrant_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla aurarp.aura_police_warrants: ~0 rows (aproximadamente)

-- Volcando estructura para tabla aurarp.aura_societies
CREATE TABLE IF NOT EXISTS `aura_societies` (
  `name` varchar(50) NOT NULL,
  `label` varchar(100) NOT NULL,
  `balance` bigint(20) NOT NULL DEFAULT 0,
  `last_updated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla aurarp.aura_societies: ~20 rows (aproximadamente)
INSERT INTO `aura_societies` (`name`, `label`, `balance`, `last_updated`) VALUES
	('aceliquor', 'Ace Liquor (Sandy Shores)', 15000, '2026-09-01 21:15:39'),
	('ambulance', 'Emergency Medical Services', 50000, '2026-09-01 09:25:49'),
	('bahama', 'Bahama Mamas West', 15000, '2026-09-01 09:25:49'),
	('banhamliquor', 'Rob\'s Liquor (Banham Canyon)', 15000, '2026-09-01 21:15:39'),
	('burgershot', 'Burgershot Vespucci', 15000, '2026-09-01 09:25:49'),
	('cardealer', 'Premium Deluxe Motorsport', 100000, '2026-09-01 09:25:49'),
	('elrancholiquor', 'Rob\'s Liquor (El Rancho Blvd)', 15000, '2026-09-01 21:15:39'),
	('harmonyliquor', 'Rob\'s Liquor (Harmony Route 68)', 15000, '2026-09-01 21:15:39'),
	('henhouse', 'The Hen House Bar', 15000, '2026-09-01 22:18:44'),
	('mechanic', 'Los Santos Customs', 25000, '2026-09-01 09:25:49'),
	('morningwoodliquor', 'Rob\'s Liquor (Morningwood)', 15000, '2026-09-01 21:15:39'),
	('paletoliquor', 'Paleto Bay Liquor Store', 15000, '2026-09-01 22:18:44'),
	('pearls', 'Pearls Seafood Restaurant', 12000, '2026-09-01 09:25:49'),
	('police', 'Los Santos Police Department', 50000, '2026-09-01 09:25:49'),
	('salieri', 'Salieri Club', 15000, '2026-09-01 22:18:44'),
	('taxi', 'Downtown Cab Co.', 10000, '2026-09-01 09:25:49'),
	('tequilala', 'Tequi-la-la Bar & Club', 30038, '2026-09-01 11:07:09'),
	('vanilla', 'Vanilla Unicorn Club', 15000, '2026-09-01 09:25:49'),
	('vazou', 'Discoteca Marc Vazou', 15000, '2026-09-01 22:18:44'),
	('yellowjack', 'Yellow Jack Inn', 10000, '2026-09-01 09:25:49');

-- Volcando estructura para tabla aurarp.aura_transactions
CREATE TABLE IF NOT EXISTS `aura_transactions` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `transaction_id` varchar(64) NOT NULL,
  `character_id` int(11) NOT NULL,
  `target_character_id` int(11) DEFAULT NULL,
  `account` enum('cash','bank','savings','black_money') NOT NULL,
  `type` enum('INITIAL','DEPOSIT','WITHDRAW','TRANSFER_SEND','TRANSFER_RECEIVE','PURCHASE','SALE','TAX','FINE','SALARY','SINK','ADMIN') NOT NULL,
  `amount` bigint(20) NOT NULL,
  `balance_before` bigint(20) NOT NULL,
  `balance_after` bigint(20) NOT NULL,
  `fee` bigint(20) NOT NULL DEFAULT 0,
  `reason` varchar(255) NOT NULL,
  `metadata` longtext DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `transaction_id` (`transaction_id`),
  KEY `idx_char_date` (`character_id`,`created_at`),
  KEY `idx_target_char` (`target_character_id`),
  KEY `idx_type` (`type`),
  KEY `idx_tx_uuid` (`transaction_id`)
) ENGINE=InnoDB AUTO_INCREMENT=90 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla aurarp.aura_transactions: ~11 rows (aproximadamente)
INSERT INTO `aura_transactions` (`id`, `transaction_id`, `character_id`, `target_character_id`, `account`, `type`, `amount`, `balance_before`, `balance_after`, `fee`, `reason`, `metadata`, `created_at`) VALUES
	(1, 'TX-1788119036-11-f3ed8221', 11, NULL, 'bank', 'WITHDRAW', 500, 5000, 4500, 0, 'Emisión de Tarjeta de Crédito', NULL, '2026-08-30 19:43:56'),
	(2, 'TX-1788119131-11-62a01561', 11, NULL, 'bank', 'WITHDRAW', 500, 4500, 4000, 0, 'Retirada ATM', '{"executor":11}', '2026-08-30 19:45:31'),
	(3, 'TX-1788119131-11-999a8840', 11, NULL, 'cash', 'DEPOSIT', 500, 0, 500, 0, 'Retirada ATM', NULL, '2026-08-30 19:45:31'),
	(4, 'TX-1788119280-11-373265a0', 11, NULL, 'cash', 'WITHDRAW', 500, 500, 0, 0, 'Depósito bancario ATM', NULL, '2026-08-30 19:48:00'),
	(5, 'TX-1788119280-11-f1c96ad9', 11, NULL, 'bank', 'DEPOSIT', 500, 4000, 4500, 0, 'Depósito recibido', '{"executor":11}', '2026-08-30 19:48:00'),
	(6, 'TX-1788119601-11-3b184e27', 11, NULL, 'bank', 'WITHDRAW', 500, 4500, 4000, 0, 'Retirada ATM', '{"executor":11}', '2026-08-30 19:53:21'),
	(8, 'TX-1788119601-11-698f1238', 11, NULL, 'cash', 'DEPOSIT', 500, 500, 1000, 0, 'Retirada ATM', NULL, '2026-08-30 19:53:21'),
	(9, 'TX-1788119612-11-6b8b8ba0', 11, NULL, 'bank', 'DEPOSIT', 500, 4000, 4500, 0, 'Depósito bancario ATM', '{"executor":11}', '2026-08-30 19:53:32'),
	(10, 'TX-1788119612-11-54435918', 11, NULL, 'cash', 'WITHDRAW', 500, 1000, 500, 0, 'Depósito bancario ATM', NULL, '2026-08-30 19:53:32'),
	(11, 'TX-1788120626-11-218addc6', 11, NULL, 'bank', 'WITHDRAW', 100, 4500, 4400, 0, 'Retirada ATM', '{"executor":11}', '2026-08-30 20:10:26'),
	(13, 'TX-1788120626-11-54806c5f', 11, NULL, 'cash', 'DEPOSIT', 100, 600, 700, 0, 'Retirada ATM', NULL, '2026-08-30 20:10:26');

-- Volcando estructura para tabla aurarp.aura_vendor_transactions
CREATE TABLE IF NOT EXISTS `aura_vendor_transactions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `buyer_name` varchar(100) NOT NULL DEFAULT 'Ciudadano',
  `business` varchar(50) NOT NULL,
  `business_label` varchar(100) NOT NULL,
  `items` longtext NOT NULL,
  `total_price` int(11) NOT NULL,
  `payment_method` enum('cash','bank') NOT NULL DEFAULT 'cash',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_vendor_business` (`business`),
  KEY `idx_vendor_citizenid` (`citizenid`),
  KEY `idx_vendor_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla aurarp.aura_vendor_transactions: ~0 rows (aproximadamente)

-- Volcando estructura para tabla aurarp.characters
CREATE TABLE IF NOT EXISTS `characters` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `slot` int(11) NOT NULL,
  `firstname` varchar(50) NOT NULL,
  `lastname` varchar(50) NOT NULL,
  `nationality` varchar(50) NOT NULL,
  `dob` date NOT NULL,
  `gender` tinyint(1) NOT NULL DEFAULT 0 COMMENT '0: Male, 1: Female',
  `metadata` longtext NOT NULL COMMENT 'JSON: health, appearance, bank, last_location',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `last_played` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `accounts` longtext NOT NULL DEFAULT '{"cash":0,"bank":5000,"black_money":0}' COMMENT 'JSON: cash, bank, black_money' CHECK (json_valid(`accounts`)),
  `inventory` longtext DEFAULT NULL,
  `job` varchar(50) NOT NULL DEFAULT 'unemployed',
  `job_grade` int(11) NOT NULL DEFAULT 0,
  `job_duty` tinyint(1) NOT NULL DEFAULT 0,
  `jail_time` int(11) NOT NULL DEFAULT 0,
  `iban` varchar(20) DEFAULT NULL,
  `pin` varchar(4) DEFAULT NULL,
  `phone_number` varchar(20) DEFAULT NULL,
  `phone_settings` longtext DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_citizenid_slot` (`citizenid`,`slot`),
  UNIQUE KEY `idx_phone_number` (`phone_number`),
  KEY `idx_character_job` (`job`),
  KEY `idx_character_job_duty` (`job_duty`),
  CONSTRAINT `fk_characters_players` FOREIGN KEY (`citizenid`) REFERENCES `players` (`citizenid`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla aurarp.characters: ~1 rows (aproximadamente)
INSERT INTO `characters` (`id`, `citizenid`, `slot`, `firstname`, `lastname`, `nationality`, `dob`, `gender`, `metadata`, `created_at`, `last_played`, `accounts`, `inventory`, `job`, `job_grade`, `job_duty`, `jail_time`, `iban`, `pin`, `phone_number`, `phone_settings`) VALUES
	(11, 'HLWWIZKU', 1, 'test', 'uno', 'Angola', '1990-12-11', 0, '{"bank":5000,"appearance":{"model":"mp_m_freemode_01","headBlend":{"skinFirst":0,"shapeThird":0,"shapeMix":0,"shapeSecond":0,"thirdMix":0,"shapeFirst":0,"skinThird":0,"skinMix":0,"skinSecond":0},"tattoos":[],"components":[{"component_id":0,"drawable":0,"texture":0},{"component_id":1,"drawable":0,"texture":0},{"component_id":2,"drawable":0,"texture":0},{"component_id":3,"drawable":0,"texture":0},{"component_id":4,"drawable":0,"texture":0},{"component_id":5,"drawable":0,"texture":0},{"component_id":6,"drawable":0,"texture":0},{"component_id":7,"drawable":0,"texture":0},{"component_id":8,"drawable":0,"texture":0},{"component_id":9,"drawable":0,"texture":0},{"component_id":10,"drawable":0,"texture":0},{"component_id":11,"drawable":0,"texture":0}],"faceFeatures":{"nosePeakLowering":0,"eyeBrownForward":0,"chinBoneLowering":0,"neckThickness":0,"noseWidth":0,"noseBoneHigh":0,"cheeksWidth":0,"chinBoneLenght":0,"chinHole":0,"eyesOpening":0,"lipsThickness":0,"nosePeakHigh":0,"cheeksBoneHigh":0,"eyeBrownHigh":0,"jawBoneBackSize":0,"nosePeakSize":0,"noseBoneTwist":0,"chinBoneSize":0,"jawBoneWidth":0,"cheeksBoneWidth":0},"hair":{"highlight":0,"style":0,"texture":0,"color":0},"props":[{"prop_id":0,"texture":-1,"drawable":-1},{"prop_id":1,"texture":-1,"drawable":-1},{"prop_id":2,"texture":-1,"drawable":-1},{"prop_id":6,"texture":-1,"drawable":-1},{"prop_id":7,"texture":-1,"drawable":-1}],"headOverlays":{"makeUp":{"opacity":0,"style":0,"secondColor":0,"color":0},"blush":{"opacity":0,"style":0,"secondColor":0,"color":0},"blemishes":{"opacity":0,"style":0,"secondColor":0,"color":0},"complexion":{"opacity":0,"style":0,"secondColor":0,"color":0},"lipstick":{"opacity":0,"style":0,"secondColor":0,"color":0},"bodyBlemishes":{"opacity":0,"style":0,"secondColor":0,"color":0},"ageing":{"opacity":0,"style":0,"secondColor":0,"color":0},"beard":{"opacity":0,"style":0,"secondColor":0,"color":0},"eyebrows":{"opacity":0,"style":0,"secondColor":0,"color":0},"moleAndFreckles":{"opacity":0,"style":0,"secondColor":0,"color":0},"sunDamage":{"opacity":0,"style":0,"secondColor":0,"color":0},"chestHair":{"opacity":0,"style":0,"secondColor":0,"color":0}},"eyeColor":0},"last_location":{"z":43.6864013671875,"heading":280.6299133300781,"x":433.6615295410156,"y":-985.8329467773438},"cash":1000,"armor":0,"health":200}', '2026-08-29 13:56:37', '2026-09-02 13:08:08', '{"cash":500,"bank":4400,"black_money":0}', '[{"count":1,"metadata":{"owner":11,"description":"IBAN: AURA56149361\\nTitular ID: 11","iban":"AURA56149361"},"slot":1,"name":"credit_card"},{"count":500,"slot":2,"name":"money"},{"count":1,"slot":3,"name":"phone"}]', 'police', 6, 1, 0, 'AURA56149361', '6444', '555-8966', '{"ringtone":"ringtone.mp3","security":{"pin_code":"","face_id":true},"message_tone":"sms.mp3","volume_msg":80,"notifications":{"messages":true,"bank":true,"calls":true},"volume_ring":80,"frame_color":"#555566","device_name":"Otto","wallpaper_url":"https://images.unsplash.com/photo-1550684848-fac1c5b4e853?q=80&w=2564&auto=format&fit=crop"}');

-- Volcando estructura para tabla aurarp.management_outfits
CREATE TABLE IF NOT EXISTS `management_outfits` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(50) NOT NULL,
  `type` varchar(50) NOT NULL,
  `minrank` int(11) NOT NULL DEFAULT 0,
  `name` varchar(50) NOT NULL DEFAULT 'Cool Outfit',
  `gender` varchar(50) NOT NULL DEFAULT 'male',
  `model` varchar(50) DEFAULT NULL,
  `props` varchar(1000) DEFAULT NULL,
  `components` varchar(1500) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Volcando datos para la tabla aurarp.management_outfits: ~0 rows (aproximadamente)

-- Volcando estructura para tabla aurarp.ox_inventory
CREATE TABLE IF NOT EXISTS `ox_inventory` (
  `owner` varchar(60) DEFAULT NULL,
  `name` varchar(100) NOT NULL,
  `data` longtext DEFAULT NULL,
  `lastupdated` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  UNIQUE KEY `owner` (`owner`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- Volcando datos para la tabla aurarp.ox_inventory: ~1 rows (aproximadamente)
INSERT INTO `ox_inventory` (`owner`, `name`, `data`, `lastupdated`) VALUES
	('', 'vendor_stock_tequilala', '[{"count":100,"slot":1,"name":"water"},{"count":100,"slot":2,"name":"chips"},{"count":100,"slot":3,"name":"cocktail"},{"count":100,"slot":4,"name":"tequila_shot"},{"count":100,"slot":5,"name":"whiskey"},{"count":100,"slot":6,"name":"beer"}]', '2026-09-01 12:37:29');

-- Volcando estructura para tabla aurarp.player_outfit_codes
CREATE TABLE IF NOT EXISTS `player_outfit_codes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `outfitid` int(11) NOT NULL,
  `code` varchar(50) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Volcando datos para la tabla aurarp.player_outfit_codes: ~0 rows (aproximadamente)

-- Volcando estructura para tabla aurarp.player_outfits
CREATE TABLE IF NOT EXISTS `player_outfits` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) DEFAULT NULL,
  `outfitname` varchar(50) NOT NULL DEFAULT '0',
  `model` varchar(50) DEFAULT NULL,
  `props` varchar(1000) DEFAULT NULL,
  `components` varchar(1500) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Volcando datos para la tabla aurarp.player_outfits: ~0 rows (aproximadamente)

-- Volcando estructura para tabla aurarp.players
CREATE TABLE IF NOT EXISTS `players` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `license` varchar(50) NOT NULL,
  `citizenid` varchar(10) NOT NULL,
  `metadata` longtext NOT NULL DEFAULT '{}' CHECK (json_valid(`metadata`)),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `last_updated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `last_login` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `license` (`license`),
  UNIQUE KEY `citizenid` (`citizenid`),
  KEY `idx_license` (`license`),
  KEY `idx_citizenid` (`citizenid`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla aurarp.players: ~1 rows (aproximadamente)
INSERT INTO `players` (`id`, `license`, `citizenid`, `metadata`, `created_at`, `last_updated`, `last_login`) VALUES
	(1, 'license:fb83002da5edb49dd7bdb39c170a8c8af7cf5298', 'HLWWIZKU', '{"permissions":"user","status":{"hunger":100,"thirst":100},"position":{"x":0.0,"z":0.0,"y":0.0},"money":{"cash":500,"bank":1500}}', '2026-08-28 18:31:20', '2026-09-02 13:00:10', '2026-09-02 13:00:10');

-- Volcando estructura para tabla aurarp.playerskins
CREATE TABLE IF NOT EXISTS `playerskins` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(255) NOT NULL,
  `model` varchar(255) NOT NULL,
  `skin` text NOT NULL,
  `active` tinyint(4) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`),
  KEY `active` (`active`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Volcando datos para la tabla aurarp.playerskins: ~1 rows (aproximadamente)
INSERT INTO `playerskins` (`id`, `citizenid`, `model`, `skin`, `active`) VALUES
	(1, '11', 'mp_m_freemode_01', '{"model":"mp_m_freemode_01","components":[{"component_id":0,"drawable":0,"texture":0},{"component_id":1,"drawable":0,"texture":0},{"component_id":2,"drawable":0,"texture":0},{"component_id":3,"drawable":0,"texture":0},{"component_id":4,"drawable":0,"texture":0},{"component_id":5,"drawable":0,"texture":0},{"component_id":6,"drawable":0,"texture":0},{"component_id":7,"drawable":0,"texture":0},{"component_id":8,"drawable":0,"texture":0},{"component_id":9,"drawable":0,"texture":0},{"component_id":10,"drawable":0,"texture":0},{"component_id":11,"drawable":0,"texture":0}],"props":[{"drawable":-1,"prop_id":0,"texture":-1},{"drawable":-1,"prop_id":1,"texture":-1},{"drawable":-1,"prop_id":2,"texture":-1},{"drawable":-1,"prop_id":6,"texture":-1},{"drawable":-1,"prop_id":7,"texture":-1}],"headOverlays":{"blemishes":{"color":0,"opacity":0,"secondColor":0,"style":0},"lipstick":{"color":0,"opacity":0,"secondColor":0,"style":0},"bodyBlemishes":{"color":0,"opacity":0,"secondColor":0,"style":0},"eyebrows":{"color":0,"opacity":0,"secondColor":0,"style":0},"blush":{"color":0,"opacity":0,"secondColor":0,"style":0},"beard":{"color":0,"opacity":0,"secondColor":0,"style":0},"makeUp":{"color":0,"opacity":0,"secondColor":0,"style":0},"moleAndFreckles":{"color":0,"opacity":0,"secondColor":0,"style":0},"complexion":{"color":0,"opacity":0,"secondColor":0,"style":0},"chestHair":{"color":0,"opacity":0,"secondColor":0,"style":0},"sunDamage":{"color":0,"opacity":0,"secondColor":0,"style":0},"ageing":{"color":0,"opacity":0,"secondColor":0,"style":0}},"tattoos":[],"headBlend":{"skinFirst":0,"shapeSecond":0,"shapeThird":0,"skinMix":0,"shapeFirst":0,"skinThird":0,"shapeMix":0,"thirdMix":0,"skinSecond":0},"eyeColor":0,"faceFeatures":{"chinBoneSize":0,"chinHole":0,"chinBoneLowering":0,"noseBoneTwist":0,"eyeBrownHigh":0,"eyeBrownForward":0,"eyesOpening":0,"jawBoneBackSize":0,"jawBoneWidth":0,"lipsThickness":0,"nosePeakLowering":0,"nosePeakHigh":0,"noseWidth":0,"cheeksBoneWidth":0,"neckThickness":0,"cheeksWidth":0,"noseBoneHigh":0,"cheeksBoneHigh":0,"chinBoneLenght":0,"nosePeakSize":0},"hair":{"color":0,"style":0,"highlight":0,"texture":0}}', 1);

-- Volcando estructura para tabla aurarp.vehicles
CREATE TABLE IF NOT EXISTS `vehicles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `plate` varchar(12) NOT NULL,
  `owner` varchar(50) DEFAULT NULL,
  `glovebox` longtext DEFAULT NULL,
  `trunk` longtext DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `plate` (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla aurarp.vehicles: ~0 rows (aproximadamente)

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
