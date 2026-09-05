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

-- Volcando datos para la tabla aurarp.aura_doors: ~14 rows (aproximadamente)
INSERT INTO `aura_doors` (`door_id`, `is_locked`, `job`, `coords_x`, `coords_y`, `coords_z`, `distance`) VALUES
	('henhouse_main', 1, 'henhouse', -297.5899963378906, 6271.259765625, 31.510000228881836, 2),
	('police_armory1', 0, 'police', 444.3560485839844, -984.0791015625, 34.3011474609375, 2.5),
	('police_automatica1', 1, 'police', 445.71429443359375, -974.10986328125, 30.7120361328125, 2.5),
	('police_automatica2', 0, 'police', 445.6351623535156, -986.2813110351562, 30.7120361328125, 2.5),
	('police_automatica3', 0, 'police', 445.6087951660156, -994.2329711914062, 30.7120361328125, 2.5),
	('police_celda1', 1, 'police', 436.4307556152344, -995.116455078125, 27.4769287109375, 2.5),
	('police_main', 0, 'police', 434.75604248046875, -981.9296875, 30.6951904296875, 2.5),
	('police_main2', 0, 'police', 438.3164978027344, -981.982421875, 30.7120361328125, 2.5),
	('police_main3', 0, 'police', 441.5208740234375, -998.8483276367188, 30.7120361328125, 2.5),
	('police_main4', 0, 'police', 457.0681457519531, -972.4747314453125, 30.7120361328125, 2.5),
	('salieri_1', 1, 'salieri', 316.5758361816406, -1092.6065673828125, 29.4146728515625, 2.5),
	('salieri_main', 1, 'salieri', 316.82000732421875, -1092.6199951171875, 29.420000076293945, 2),
	('vazou_main', 1, 'vazou', -1564.43994140625, -974.6099853515625, 13.020000457763672, 2),
	('vazou_secundaria', 1, 'vazou', -1558.6600341796875, -972.219970703125, 13.020000457763672, 2);

-- Volcando estructura para tabla aurarp.aura_gang_laundry
CREATE TABLE IF NOT EXISTS `aura_gang_laundry` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `gang` varchar(50) NOT NULL,
  `machine_id` varchar(50) NOT NULL,
  `black_money_input` bigint(20) NOT NULL,
  `clean_money_output` bigint(20) NOT NULL,
  `tax_fee` bigint(20) NOT NULL DEFAULT 0,
  `ready_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `is_collected` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_laundry_machine` (`machine_id`),
  KEY `idx_laundry_citizen` (`citizenid`),
  KEY `idx_laundry_ready` (`ready_at`,`is_collected`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla aurarp.aura_gang_laundry: ~0 rows (aproximadamente)

-- Volcando estructura para tabla aurarp.aura_gang_turfs
CREATE TABLE IF NOT EXISTS `aura_gang_turfs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `gang` varchar(50) NOT NULL,
  `graffiti_type` varchar(50) NOT NULL DEFAULT 'spray_gang_default',
  `coords_x` double NOT NULL,
  `coords_y` double NOT NULL,
  `coords_z` double NOT NULL,
  `normal_x` float NOT NULL DEFAULT 0,
  `normal_y` float NOT NULL DEFAULT 0,
  `normal_z` float NOT NULL DEFAULT 1,
  `sprayed_by` varchar(100) NOT NULL,
  `sprayed_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_turf_gang` (`gang`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla aurarp.aura_gang_turfs: ~0 rows (aproximadamente)

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

-- Volcando datos para la tabla aurarp.aura_market_items: ~7 rows (aproximadamente)
INSERT INTO `aura_market_items` (`name`, `base_price`, `min_price`, `max_price`, `current_stock`, `target_stock`, `elasticity`, `last_updated`) VALUES
	('copper_ore', 35, 10, 90, 3000, 3000, 0.05, '2026-08-30 17:39:34'),
	('gold_ore', 150, 50, 350, 500, 500, 0.08, '2026-08-30 17:39:34'),
	('iron_ore', 50, 15, 120, 2000, 2000, 0.05, '2026-08-30 17:39:34'),
	('packaged_fish', 45, 12, 110, 1500, 1500, 0.06, '2026-08-30 17:39:34'),
	('raw_meat', 70, 20, 160, 800, 800, 0.07, '2026-08-30 17:39:34'),
	('scrap_metal', 80, 30, 180, 1000, 1000, 0.05, '2026-09-04 11:18:20'),
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

-- Volcando datos para la tabla aurarp.aura_societies: ~25 rows (aproximadamente)
INSERT INTO `aura_societies` (`name`, `label`, `balance`, `last_updated`) VALUES
	('aceliquor', 'Ace Liquor (Sandy Shores)', 15000, '2026-09-01 21:15:39'),
	('ambulance', 'Emergency Medical Services', 50000, '2026-09-01 09:25:49'),
	('bahama', 'Bahama Mamas West', 15000, '2026-09-01 09:25:49'),
	('ballas', 'East Los Santos Ballas', 25000, '2026-09-04 08:17:10'),
	('banhamliquor', 'Rob\'s Liquor (Banham Canyon)', 15000, '2026-09-01 21:15:39'),
	('burgershot', 'Burgershot Vespucci', 15000, '2026-09-01 09:25:49'),
	('cardealer', 'Premium Deluxe Motorsport', 100000, '2026-09-01 09:25:49'),
	('cartel', 'Cártel de Sinaloa / Medellín', 50000, '2026-09-04 08:17:10'),
	('elrancholiquor', 'Rob\'s Liquor (El Rancho Blvd)', 15000, '2026-09-01 21:15:39'),
	('families', 'Chamberlain Gangster Families', 25000, '2026-09-04 08:17:10'),
	('harmonyliquor', 'Rob\'s Liquor (Harmony Route 68)', 15000, '2026-09-01 21:15:39'),
	('henhouse', 'The Hen House Bar', 15000, '2026-09-01 22:18:44'),
	('mafia', 'Familia Salieri & Cártel Clandestino', 50000, '2026-09-04 08:17:10'),
	('mechanic', 'Los Santos Customs', 25000, '2026-09-01 09:25:49'),
	('morningwoodliquor', 'Rob\'s Liquor (Morningwood)', 15000, '2026-09-01 21:15:39'),
	('paletoliquor', 'Paleto Bay Liquor Store', 15000, '2026-09-01 22:18:44'),
	('pearls', 'Pearls Seafood Restaurant', 12000, '2026-09-01 09:25:49'),
	('police', 'Los Santos Police Department', 50000, '2026-09-01 09:25:49'),
	('salieri', 'Familia Salieri & Cártel Clandestino', 15000, '2026-09-04 10:36:58'),
	('taxi', 'Downtown Cab Co.', 10000, '2026-09-01 09:25:49'),
	('tequilala', 'Tequi-la-la Bar & Club', 30038, '2026-09-01 11:07:09'),
	('vagos', 'Los Santos Vagos', 25000, '2026-09-04 08:17:10'),
	('vanilla', 'Vanilla Unicorn Club', 15000, '2026-09-01 09:25:49'),
	('vazou', 'Cártel Marc Vazou', 15000, '2026-09-04 10:36:58'),
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
) ENGINE=InnoDB AUTO_INCREMENT=97 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla aurarp.aura_transactions: ~18 rows (aproximadamente)
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
	(13, 'TX-1788120626-11-54806c5f', 11, NULL, 'cash', 'DEPOSIT', 100, 600, 700, 0, 'Retirada ATM', NULL, '2026-08-30 20:10:26'),
	(90, 'TX-1788358046-11-8f13519d', 11, NULL, 'bank', 'DEPOSIT', 3040, 4400, 7440, 0, 'Nómina: LSPD (Jefe de Policía)', '{"tax_sunk":160,"gross":3200,"tax_rate":0.05,"grade":6,"job":"police"}', '2026-09-02 14:07:26'),
	(91, 'TX-1788362843-11-7253d6e7', 11, NULL, 'bank', 'DEPOSIT', 3040, 7440, 10480, 0, 'Nómina: LSPD (Jefe de Policía)', '{"tax_rate":0.05,"grade":6,"tax_sunk":160,"job":"police","gross":3200}', '2026-09-02 15:27:23'),
	(92, 'TX-1788464929-11-9f70ea48', 11, NULL, 'bank', 'DEPOSIT', 3040, 10480, 13520, 0, 'Nómina: LSPD (Jefe de Policía)', '{"tax_rate":0.05,"tax_sunk":160,"grade":6,"job":"police","gross":3200}', '2026-09-03 19:48:49'),
	(93, 'TX-1788468699-11-df6382c3', 11, NULL, 'bank', 'DEPOSIT', 3040, 13520, 16560, 0, 'Nómina: LSPD (Comisario)', '{"grade":5,"tax_sunk":160,"job":"police","tax_rate":0.05,"gross":3200}', '2026-09-03 20:51:39'),
	(94, 'TX-1788510543-12-b3f1205c', 12, NULL, 'bank', 'INITIAL', 5000, 0, 5000, 0, 'INITIAL_CHARACTER_CREATION', NULL, '2026-09-04 08:29:03'),
	(95, 'TX-1788516911-13-b0496fb2', 13, NULL, 'bank', 'INITIAL', 5000, 0, 5000, 0, 'INITIAL_CHARACTER_CREATION', NULL, '2026-09-04 10:15:11'),
	(96, 'TX-1788520627-11-84518e41', 11, NULL, 'bank', 'DEPOSIT', 3040, 16560, 19600, 0, 'Nómina: LSPD (Comisario)', '{"tax_rate":0.05,"gross":3200,"grade":5,"tax_sunk":160,"job":"police"}', '2026-09-04 11:17:07');

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
  `metadata` longtext NOT NULL COMMENT 'JSON: health, appearance, bank, last_location, hud_positions',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `last_played` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `accounts` longtext NOT NULL DEFAULT '{"cash":0,"bank":5000,"black_money":0}' COMMENT 'JSON: cash, bank, black_money' CHECK (json_valid(`accounts`)),
  `inventory` longtext DEFAULT NULL,
  `job` varchar(50) NOT NULL DEFAULT 'unemployed',
  `job_grade` int(11) NOT NULL DEFAULT 0,
  `job_duty` tinyint(1) NOT NULL DEFAULT 0,
  `badge` varchar(20) DEFAULT NULL,
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
  KEY `idx_character_badge` (`badge`),
  CONSTRAINT `fk_characters_players` FOREIGN KEY (`citizenid`) REFERENCES `players` (`citizenid`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla aurarp.characters: ~3 rows (aproximadamente)
INSERT INTO `characters` (`id`, `citizenid`, `slot`, `firstname`, `lastname`, `nationality`, `dob`, `gender`, `metadata`, `created_at`, `last_played`, `accounts`, `inventory`, `job`, `job_grade`, `job_duty`, `badge`, `jail_time`, `iban`, `pin`, `phone_number`, `phone_settings`) VALUES
	(11, 'HLWWIZKU', 1, 'test', 'uno', 'Angola', '1990-12-11', 0, '{"health":200,"last_location":{"y":2169.415283203125,"z":53.088623046875,"heading":2.83464550971984,"x":793.8197631835938},"cash":1000,"armor":0,"bank":5000,"appearance":{"eyeColor":0,"tattoos":[],"headBlend":{"shapeMix":0,"skinMix":0,"thirdMix":0,"shapeFirst":0,"shapeThird":0,"skinThird":0,"skinSecond":0,"shapeSecond":0,"skinFirst":0},"props":[{"drawable":10,"texture":6,"prop_id":0},{"drawable":15,"texture":7,"prop_id":1},{"drawable":-1,"texture":-1,"prop_id":2},{"drawable":-1,"texture":-1,"prop_id":6},{"drawable":-1,"texture":-1,"prop_id":7}],"headOverlays":{"beard":{"style":0,"color":0,"secondColor":0,"opacity":0},"sunDamage":{"style":0,"color":0,"secondColor":0,"opacity":0},"complexion":{"style":0,"color":0,"secondColor":0,"opacity":0},"ageing":{"style":0,"color":0,"secondColor":0,"opacity":0},"chestHair":{"style":0,"color":0,"secondColor":0,"opacity":0},"blush":{"style":0,"color":0,"secondColor":0,"opacity":0},"moleAndFreckles":{"style":0,"color":0,"secondColor":0,"opacity":0},"lipstick":{"style":0,"color":0,"secondColor":0,"opacity":0},"eyebrows":{"style":0,"color":0,"secondColor":0,"opacity":0},"blemishes":{"style":0,"color":0,"secondColor":0,"opacity":0},"makeUp":{"style":0,"color":0,"secondColor":0,"opacity":0},"bodyBlemishes":{"style":0,"color":0,"secondColor":0,"opacity":0}},"components":[{"component_id":0,"drawable":0,"texture":0},{"component_id":1,"drawable":0,"texture":0},{"component_id":2,"drawable":0,"texture":0},{"component_id":3,"drawable":200,"texture":0},{"component_id":4,"drawable":52,"texture":1},{"component_id":5,"drawable":0,"texture":0},{"component_id":6,"drawable":24,"texture":0},{"component_id":7,"drawable":1,"texture":0},{"component_id":8,"drawable":253,"texture":0},{"component_id":9,"drawable":101,"texture":0},{"component_id":10,"drawable":0,"texture":0},{"component_id":11,"drawable":629,"texture":0}],"hair":{"style":0,"color":0,"texture":0,"highlight":0},"model":"mp_m_freemode_01","faceFeatures":{"jawBoneBackSize":0,"cheeksBoneWidth":0,"cheeksWidth":0,"chinHole":0,"eyeBrownHigh":0,"lipsThickness":0,"jawBoneWidth":0,"chinBoneLowering":0,"chinBoneLenght":0,"neckThickness":0,"cheeksBoneHigh":0,"nosePeakHigh":0,"noseBoneTwist":0,"nosePeakSize":0,"eyesOpening":0,"noseWidth":0,"chinBoneSize":0,"nosePeakLowering":0,"noseBoneHigh":0,"eyeBrownForward":0}}}', '2026-08-29 13:56:37', '2026-09-04 16:42:43', '{"black_money":0,"bank":19600,"cash":500}', '[{"name":"WEAPON_CARBINERIFLE","metadata":{"registered":"LazyNewt4084","serial":"549447EOQ481566","components":[],"ammo":13,"durability":97.38999999999996},"slot":1,"count":1},{"name":"credit_card","metadata":{"description":"IBAN: AURA56149361\\nTitular ID: 11","iban":"AURA56149361","owner":11},"slot":32,"count":1},{"name":"lockpick","slot":33,"count":4},{"name":"adv_lockpick","slot":34,"count":2},{"name":"WEAPON_STUNGUN","metadata":{"components":[],"registered":"LazyNewt4084","durability":100,"serial":"963013KIX301190"},"slot":35,"count":1},{"name":"car_wheel","slot":36,"count":2},{"name":"car_door","slot":37,"count":3},{"name":"black_money","slot":38,"count":2758},{"name":"ammo-shotgun","slot":40,"count":100},{"name":"WEAPON_COMBATPISTOL","metadata":{"registered":"LazyNewt4084","serial":"790917WWI734442","components":[],"ammo":0,"durability":79.99999999999996},"slot":41,"count":1},{"name":"money","slot":42,"count":500},{"name":"phone","slot":43,"count":1},{"name":"WEAPON_NIGHTSTICK","metadata":{"components":[],"durability":100},"slot":44,"count":1},{"name":"WEAPON_FLASHLIGHT","metadata":{"components":[],"durability":100},"slot":45,"count":1},{"name":"radio","slot":46,"count":1},{"name":"armour","slot":47,"count":1},{"name":"armour","slot":48,"count":1},{"name":"bodycam","slot":49,"count":1},{"name":"police_badge","metadata":{"description":"Placa Nº: 101\\nOficial: test uno\\nRango: Comisario\\nDepartamento: LSPD","officer_name":"test uno","badge":"101","citizenid":"HLWWIZKU","grade_label":"Comisario"},"slot":50,"count":1},{"name":"coca_leaf","slot":2,"count":30},{"name":"cocaine","slot":15,"count":25},{"name":"meth","slot":10,"count":27},{"name":"empty_baggies","slot":4,"count":35},{"name":"sulfuric_acid","slot":6,"count":2},{"name":"baking_soda","slot":7,"count":4}]', 'vazou', 4, 0, '101', 0, 'AURA56149361', '6444', '555-8966', '{"ringtone":"ringtone.mp3","security":{"pin_code":"","face_id":true},"message_tone":"sms.mp3","volume_msg":80,"notifications":{"messages":true,"bank":true,"calls":true},"volume_ring":80,"frame_color":"#555566","device_name":"Otto","wallpaper_url":"https://images.unsplash.com/photo-1550684848-fac1c5b4e853?q=80&w=2564&auto=format&fit=crop"}'),
	(12, 'HLWWIZKU', 2, 'Gang', 'Test', 'Afganistán', '1990-02-05', 0, '{"appearance":{"hair":{"color":0,"style":14,"texture":0,"highlight":0},"components":[{"texture":0,"drawable":0,"component_id":0},{"texture":0,"drawable":0,"component_id":1},{"texture":0,"drawable":0,"component_id":2},{"texture":0,"drawable":0,"component_id":3},{"texture":0,"drawable":0,"component_id":4},{"texture":0,"drawable":0,"component_id":5},{"texture":0,"drawable":8,"component_id":6},{"texture":0,"drawable":0,"component_id":7},{"texture":0,"drawable":0,"component_id":8},{"texture":0,"drawable":0,"component_id":9},{"texture":0,"drawable":0,"component_id":10},{"texture":0,"drawable":57,"component_id":11}],"props":[{"drawable":-1,"texture":-1,"prop_id":0},{"drawable":-1,"texture":-1,"prop_id":1},{"drawable":-1,"texture":-1,"prop_id":2},{"drawable":-1,"texture":-1,"prop_id":6},{"drawable":-1,"texture":-1,"prop_id":7}],"headOverlays":{"bodyBlemishes":{"color":0,"style":0,"secondColor":0,"opacity":0},"makeUp":{"color":0,"style":0,"secondColor":0,"opacity":0},"complexion":{"color":0,"style":0,"secondColor":0,"opacity":0},"ageing":{"color":0,"style":0,"secondColor":0,"opacity":0},"moleAndFreckles":{"color":0,"style":0,"secondColor":0,"opacity":0},"sunDamage":{"color":0,"style":0,"secondColor":0,"opacity":0},"beard":{"color":0,"style":16,"secondColor":0,"opacity":1},"blemishes":{"color":0,"style":0,"secondColor":0,"opacity":0},"blush":{"color":0,"style":0,"secondColor":0,"opacity":0},"eyebrows":{"color":0,"style":0,"secondColor":0,"opacity":0},"lipstick":{"color":0,"style":0,"secondColor":0,"opacity":0},"chestHair":{"color":0,"style":0,"secondColor":0,"opacity":0}},"tattoos":[],"headBlend":{"shapeMix":0,"skinMix":0,"shapeThird":0,"shapeFirst":0,"skinThird":0,"thirdMix":0,"skinFirst":0,"shapeSecond":0,"skinSecond":0},"model":"mp_m_freemode_01","faceFeatures":{"noseWidth":0,"jawBoneWidth":0,"cheeksBoneHigh":0,"nosePeakSize":0,"chinHole":0,"chinBoneSize":0,"jawBoneBackSize":0,"lipsThickness":0,"nosePeakLowering":0,"neckThickness":0,"chinBoneLowering":0,"cheeksBoneWidth":0,"nosePeakHigh":0,"eyeBrownForward":0,"chinBoneLenght":0,"eyeBrownHigh":0,"noseBoneHigh":0,"eyesOpening":0,"cheeksWidth":0,"noseBoneTwist":0},"eyeColor":0},"cash":0,"health":200,"armor":0,"last_location":{"y":-1701.6527099609376,"x":-430.9186706542969,"heading":215.43309020996095,"z":19.018310546875},"black_money":0,"bank":5000}', '2026-09-04 08:29:03', '2026-09-04 11:50:00', '{"black_money":0,"cash":0,"bank":5000}', '[{"name":"adv_lockpick","count":10,"slot":1},{"name":"lockpick","count":2,"slot":2},{"name":"car_parts","count":5,"slot":3},{"name":"car_wheel","count":4,"slot":4},{"name":"black_money","count":18285,"slot":5},{"name":"car_door","count":4,"slot":6},{"name":"car_hood","count":1,"slot":7},{"name":"car_engine","count":1,"slot":8},{"name":"scrap_metal","count":7,"slot":9},{"name":"car_exhaust","count":1,"slot":10}]', 'cartel', 4, 0, NULL, 0, NULL, NULL, '555-8236', NULL),
	(13, 'FULGFGXT', 1, 'Carlos', 'Romero', 'China', '2000-02-01', 0, '{"health":200,"black_money":0,"appearance":{"faceFeatures":{"nosePeakSize":0,"noseBoneHigh":0,"neckThickness":0,"jawBoneWidth":0,"nosePeakLowering":0,"nosePeakHigh":0,"chinBoneLowering":0,"cheeksWidth":0,"chinBoneLenght":0,"jawBoneBackSize":0,"chinHole":0,"cheeksBoneHigh":0,"eyeBrownHigh":0,"noseBoneTwist":0,"chinBoneSize":0,"noseWidth":0,"lipsThickness":0,"eyesOpening":0,"eyeBrownForward":0,"cheeksBoneWidth":0},"props":[{"prop_id":0,"drawable":-1,"texture":-1},{"prop_id":1,"drawable":-1,"texture":-1},{"prop_id":2,"drawable":-1,"texture":-1},{"prop_id":6,"drawable":-1,"texture":-1},{"prop_id":7,"drawable":-1,"texture":-1}],"headBlend":{"skinSecond":0,"skinThird":0,"skinFirst":0,"thirdMix":0,"shapeFirst":0,"shapeSecond":0,"skinMix":0,"shapeMix":0,"shapeThird":0},"hair":{"highlight":0,"style":57,"texture":0,"color":0},"model":"mp_m_freemode_01","headOverlays":{"moleAndFreckles":{"secondColor":0,"style":0,"opacity":0,"color":0},"complexion":{"secondColor":0,"style":0,"opacity":0,"color":0},"eyebrows":{"secondColor":0,"style":0,"opacity":0,"color":0},"ageing":{"secondColor":0,"style":0,"opacity":0,"color":0},"makeUp":{"secondColor":0,"style":0,"opacity":0,"color":0},"beard":{"secondColor":0,"style":0,"opacity":0,"color":0},"chestHair":{"secondColor":0,"style":0,"opacity":0,"color":0},"lipstick":{"secondColor":0,"style":0,"opacity":0,"color":0},"blemishes":{"secondColor":0,"style":0,"opacity":0,"color":0},"bodyBlemishes":{"secondColor":0,"style":0,"opacity":0,"color":0},"blush":{"secondColor":0,"style":0,"opacity":0,"color":0},"sunDamage":{"secondColor":0,"style":0,"opacity":0,"color":0}},"components":[{"drawable":0,"component_id":0,"texture":0},{"drawable":0,"component_id":1,"texture":0},{"drawable":0,"component_id":2,"texture":0},{"drawable":0,"component_id":3,"texture":0},{"drawable":0,"component_id":4,"texture":0},{"drawable":0,"component_id":5,"texture":0},{"drawable":0,"component_id":6,"texture":0},{"drawable":0,"component_id":7,"texture":0},{"drawable":0,"component_id":8,"texture":0},{"drawable":0,"component_id":9,"texture":0},{"drawable":0,"component_id":10,"texture":0},{"drawable":0,"component_id":11,"texture":0}],"eyeColor":0,"tattoos":[]},"last_location":{"x":-863.6439819335938,"heading":141.73228454589845,"z":13.5084228515625,"y":-2616.514404296875},"bank":5000,"armor":0,"cash":0}', '2026-09-04 10:15:11', '2026-09-04 10:19:46', '{"bank":5000,"black_money":0,"cash":0}', NULL, 'unemployed', 0, 0, NULL, 0, NULL, NULL, '555-2548', NULL);

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

-- Volcando datos para la tabla aurarp.ox_inventory: ~4 rows (aproximadamente)
INSERT INTO `ox_inventory` (`owner`, `name`, `data`, `lastupdated`) VALUES
	('', 'vendor_stock_tequilala', '[{"count":100,"slot":1,"name":"water"},{"count":100,"slot":2,"name":"chips"},{"count":100,"slot":3,"name":"cocktail"},{"count":100,"slot":4,"name":"tequila_shot"},{"count":100,"slot":5,"name":"whiskey"},{"count":100,"slot":6,"name":"beer"}]', '2026-09-01 12:37:29'),
	('', 'police_disposal_mission_row', NULL, '2026-09-02 14:05:01'),
	('', 'police_disposal_mrpd', NULL, '2026-09-02 14:05:01'),
	('', 'dummy_suspect_inv_1', '[{"metadata":{"ammo":0,"durability":100,"components":[],"serial":"775288CBF236658"},"name":"WEAPON_PISTOL","slot":1,"count":1},{"name":"ammo-9","slot":2,"count":50},{"name":"lockpick","slot":3,"count":3},{"name":"money","slot":4,"count":1500}]', '2026-09-03 21:15:00');

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
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla aurarp.players: ~2 rows (aproximadamente)
INSERT INTO `players` (`id`, `license`, `citizenid`, `metadata`, `created_at`, `last_updated`, `last_login`) VALUES
	(1, 'license:fb83002da5edb49dd7bdb39c170a8c8af7cf5298', 'HLWWIZKU', '{"permissions":"user","status":{"hunger":100,"thirst":100},"position":{"x":0.0,"z":0.0,"y":0.0},"money":{"cash":500,"bank":1500}}', '2026-08-28 18:31:20', '2026-09-04 16:34:28', '2026-09-04 16:34:28'),
	(2, 'license:158f6c2adc48a219db13bcf84229d592bd19da6a', 'FULGFGXT', '{"status":{"thirst":100,"hunger":100},"permissions":"user","last_location":{"heading":330.0,"x":-1037.8,"y":-2737.9,"z":20.17},"money":{"cash":500,"bank":1500}}', '2026-09-04 10:12:54', '2026-09-04 10:12:54', '2026-09-04 10:12:54');

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
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Volcando datos para la tabla aurarp.playerskins: ~3 rows (aproximadamente)
INSERT INTO `playerskins` (`id`, `citizenid`, `model`, `skin`, `active`) VALUES
	(9, '11', 'mp_m_freemode_01', '{"eyeColor":0,"model":"mp_m_freemode_01","props":[{"drawable":10,"texture":6,"prop_id":0},{"drawable":15,"texture":7,"prop_id":1},{"drawable":-1,"texture":-1,"prop_id":2},{"drawable":-1,"texture":-1,"prop_id":6},{"drawable":-1,"texture":-1,"prop_id":7}],"tattoos":[],"headBlend":{"skinSecond":0,"skinFirst":0,"skinMix":0,"thirdMix":0,"shapeSecond":0,"skinThird":0,"shapeThird":0,"shapeMix":0,"shapeFirst":0},"components":[{"drawable":0,"component_id":0,"texture":0},{"drawable":0,"component_id":1,"texture":0},{"drawable":0,"component_id":2,"texture":0},{"drawable":200,"component_id":3,"texture":0},{"drawable":52,"component_id":4,"texture":1},{"drawable":0,"component_id":5,"texture":0},{"drawable":24,"component_id":6,"texture":0},{"drawable":1,"component_id":7,"texture":0},{"drawable":253,"component_id":8,"texture":0},{"drawable":101,"component_id":9,"texture":0},{"drawable":0,"component_id":10,"texture":0},{"drawable":629,"component_id":11,"texture":0}],"faceFeatures":{"nosePeakSize":0,"cheeksBoneHigh":0,"nosePeakHigh":0,"cheeksWidth":0,"noseBoneTwist":0,"nosePeakLowering":0,"eyeBrownHigh":0,"neckThickness":0,"jawBoneBackSize":0,"lipsThickness":0,"chinBoneLenght":0,"eyesOpening":0,"chinBoneLowering":0,"noseBoneHigh":0,"noseWidth":0,"chinBoneSize":0,"jawBoneWidth":0,"eyeBrownForward":0,"chinHole":0,"cheeksBoneWidth":0},"headOverlays":{"ageing":{"color":0,"style":0,"secondColor":0,"opacity":0},"moleAndFreckles":{"color":0,"style":0,"secondColor":0,"opacity":0},"bodyBlemishes":{"color":0,"style":0,"secondColor":0,"opacity":0},"lipstick":{"color":0,"style":0,"secondColor":0,"opacity":0},"complexion":{"color":0,"style":0,"secondColor":0,"opacity":0},"sunDamage":{"color":0,"style":0,"secondColor":0,"opacity":0},"blush":{"color":0,"style":0,"secondColor":0,"opacity":0},"beard":{"color":0,"style":0,"secondColor":0,"opacity":0},"chestHair":{"color":0,"style":0,"secondColor":0,"opacity":0},"blemishes":{"color":0,"style":0,"secondColor":0,"opacity":0},"eyebrows":{"color":0,"style":0,"secondColor":0,"opacity":0},"makeUp":{"color":0,"style":0,"secondColor":0,"opacity":0}},"hair":{"color":0,"style":0,"texture":0,"highlight":0}}', 1),
	(11, '12', 'mp_m_freemode_01', '{"eyeColor":0,"faceFeatures":{"chinBoneSize":0,"noseBoneHigh":0,"cheeksWidth":0,"eyeBrownForward":0,"chinHole":0,"chinBoneLenght":0,"cheeksBoneWidth":0,"lipsThickness":0,"jawBoneBackSize":0,"noseBoneTwist":0,"nosePeakSize":0,"cheeksBoneHigh":0,"eyeBrownHigh":0,"noseWidth":0,"chinBoneLowering":0,"neckThickness":0,"nosePeakLowering":0,"eyesOpening":0,"nosePeakHigh":0,"jawBoneWidth":0},"headBlend":{"skinSecond":0,"shapeThird":0,"thirdMix":0,"skinMix":0,"skinFirst":0,"shapeFirst":0,"shapeSecond":0,"skinThird":0,"shapeMix":0},"props":[{"drawable":-1,"texture":-1,"prop_id":0},{"drawable":-1,"texture":-1,"prop_id":1},{"drawable":-1,"texture":-1,"prop_id":2},{"drawable":-1,"texture":-1,"prop_id":6},{"drawable":-1,"texture":-1,"prop_id":7}],"tattoos":[],"components":[{"drawable":0,"component_id":0,"texture":0},{"drawable":0,"component_id":1,"texture":0},{"drawable":0,"component_id":2,"texture":0},{"drawable":0,"component_id":3,"texture":0},{"drawable":0,"component_id":4,"texture":0},{"drawable":0,"component_id":5,"texture":0},{"drawable":8,"component_id":6,"texture":0},{"drawable":0,"component_id":7,"texture":0},{"drawable":0,"component_id":8,"texture":0},{"drawable":0,"component_id":9,"texture":0},{"drawable":0,"component_id":10,"texture":0},{"drawable":57,"component_id":11,"texture":0}],"model":"mp_m_freemode_01","headOverlays":{"beard":{"style":16,"color":0,"opacity":1,"secondColor":0},"complexion":{"style":0,"color":0,"opacity":0,"secondColor":0},"ageing":{"style":0,"color":0,"opacity":0,"secondColor":0},"eyebrows":{"style":0,"color":0,"opacity":0,"secondColor":0},"blush":{"style":0,"color":0,"opacity":0,"secondColor":0},"moleAndFreckles":{"style":0,"color":0,"opacity":0,"secondColor":0},"lipstick":{"style":0,"color":0,"opacity":0,"secondColor":0},"chestHair":{"style":0,"color":0,"opacity":0,"secondColor":0},"blemishes":{"style":0,"color":0,"opacity":0,"secondColor":0},"bodyBlemishes":{"style":0,"color":0,"opacity":0,"secondColor":0},"sunDamage":{"style":0,"color":0,"opacity":0,"secondColor":0},"makeUp":{"style":0,"color":0,"opacity":0,"secondColor":0}},"hair":{"texture":0,"highlight":0,"style":14,"color":0}}', 1),
	(14, '13', 'mp_m_freemode_01', '{"faceFeatures":{"nosePeakSize":0,"noseBoneHigh":0,"neckThickness":0,"jawBoneWidth":0,"nosePeakLowering":0,"nosePeakHigh":0,"chinBoneLowering":0,"cheeksWidth":0,"chinBoneLenght":0,"jawBoneBackSize":0,"chinHole":0,"cheeksBoneHigh":0,"eyeBrownHigh":0,"noseBoneTwist":0,"chinBoneSize":0,"eyeBrownForward":0,"cheeksBoneWidth":0,"eyesOpening":0,"lipsThickness":0,"noseWidth":0},"props":[{"prop_id":0,"drawable":-1,"texture":-1},{"prop_id":1,"drawable":-1,"texture":-1},{"prop_id":2,"drawable":-1,"texture":-1},{"prop_id":6,"drawable":-1,"texture":-1},{"prop_id":7,"drawable":-1,"texture":-1}],"headBlend":{"skinSecond":0,"skinThird":0,"skinFirst":0,"thirdMix":0,"shapeFirst":0,"shapeSecond":0,"skinMix":0,"shapeMix":0,"shapeThird":0},"hair":{"texture":0,"style":57,"highlight":0,"color":0},"model":"mp_m_freemode_01","headOverlays":{"moleAndFreckles":{"color":0,"style":0,"opacity":0,"secondColor":0},"complexion":{"color":0,"style":0,"opacity":0,"secondColor":0},"eyebrows":{"color":0,"style":0,"opacity":0,"secondColor":0},"chestHair":{"color":0,"style":0,"opacity":0,"secondColor":0},"bodyBlemishes":{"color":0,"style":0,"opacity":0,"secondColor":0},"beard":{"color":0,"style":0,"opacity":0,"secondColor":0},"sunDamage":{"color":0,"style":0,"opacity":0,"secondColor":0},"makeUp":{"color":0,"style":0,"opacity":0,"secondColor":0},"blemishes":{"color":0,"style":0,"opacity":0,"secondColor":0},"lipstick":{"color":0,"style":0,"opacity":0,"secondColor":0},"blush":{"color":0,"style":0,"opacity":0,"secondColor":0},"ageing":{"color":0,"style":0,"opacity":0,"secondColor":0}},"components":[{"drawable":0,"component_id":0,"texture":0},{"drawable":0,"component_id":1,"texture":0},{"drawable":0,"component_id":2,"texture":0},{"drawable":0,"component_id":3,"texture":0},{"drawable":0,"component_id":4,"texture":0},{"drawable":0,"component_id":5,"texture":0},{"drawable":0,"component_id":6,"texture":0},{"drawable":0,"component_id":7,"texture":0},{"drawable":0,"component_id":8,"texture":0},{"drawable":0,"component_id":9,"texture":0},{"drawable":0,"component_id":10,"texture":0},{"drawable":0,"component_id":11,"texture":0}],"eyeColor":0,"tattoos":[]}', 1);

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

-- Volcando estructura para tabla aurarp.aura_police_radio_channels
CREATE TABLE IF NOT EXISTS `aura_police_radio_channels` (
  `channel_id` varchar(32) NOT NULL,
  `label` varchar(64) NOT NULL,
  `color` varchar(16) NOT NULL DEFAULT '#00f2fe',
  `blip_color` int(11) NOT NULL DEFAULT 38,
  `frequency` int(11) NOT NULL,
  `is_mando` tinyint(1) NOT NULL DEFAULT 0,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`channel_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla aurarp.aura_police_radio_channels
INSERT INTO `aura_police_radio_channels` (`channel_id`, `label`, `color`, `blip_color`, `frequency`, `is_mando`) VALUES
	('mando', 'Canal de Mando', '#ffb700', 46, 100, 1),
	('patrol_1', 'Patrulla #01', '#00f2fe', 38, 101, 0),
	('patrol_2', 'Patrulla #02', '#3b82f6', 3, 102, 0),
	('patrol_3', 'Patrulla #03', '#00ff9d', 2, 103, 0),
	('patrol_4', 'Patrulla #04', '#ff007f', 48, 104, 0),
	('patrol_5', 'Patrulla #05', '#ff6b35', 47, 105, 0),
	('patrol_6', 'Patrulla #06', '#9d4edd', 27, 106, 0),
	('patrol_7', 'Patrulla #07', '#ff2a55', 1, 107, 0),
	('patrol_8', 'Patrulla #08', '#ffffff', 0, 108, 0),
	('patrol_9', 'Patrulla #09', '#ffff00', 5, 109, 0),
	('patrol_10', 'Patrulla #10', '#06d6a0', 25, 110, 0),
	('patrol_11', 'Patrulla #11', '#8338ec', 7, 111, 0),
	('patrol_12', 'Patrulla #12', '#ff477e', 8, 112, 0),
	('patrol_13', 'Patrulla #13', '#3a86ff', 18, 113, 0),
	('patrol_14', 'Patrulla #14', '#fb5607', 17, 114, 0),
	('patrol_15', 'Patrulla #15', '#70e000', 43, 115, 0),
	('patrol_16', 'Patrulla #16', '#0077b6', 29, 116, 0),
	('patrol_17', 'Patrulla #17', '#e0aaff', 19, 117, 0),
	('patrol_18', 'Patrulla #18', '#b5179e', 21, 118, 0),
	('patrol_19', 'Patrulla #19', '#a0aec0', 40, 119, 0),
	('patrol_20', 'Patrulla #20', '#4cc9f0', 68, 120, 0)
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`), `color` = VALUES(`color`), `blip_color` = VALUES(`blip_color`);

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
