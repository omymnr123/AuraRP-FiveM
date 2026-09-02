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
  `job` varchar(50) NOT NULL DEFAULT '',
  `coords_x` double NOT NULL DEFAULT 0,
  `coords_y` double NOT NULL DEFAULT 0,
  `coords_z` double NOT NULL DEFAULT 0,
  `is_locked` tinyint(1) NOT NULL DEFAULT 1,
  `distance` float NOT NULL DEFAULT 2.5,
  PRIMARY KEY (`door_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla aurarp.aura_doors: ~4 rows (aproximadamente)
INSERT INTO `aura_doors` (`door_id`, `job`, `coords_x`, `coords_y`, `coords_z`, `is_locked`, `distance`) VALUES
	('vazou_main', 'vazou', -1564.44, -974.61, 13.02, 1, 2.0),
	('vazou_secundaria', 'vazou', -1558.66, -972.22, 13.02, 1, 2.0),
	('salieri_main', 'salieri', 322.11, -1095.43, 29.39, 1, 2.0),
	('henhouse_main', 'henhouse', -297.59, 6271.26, 31.51, 1, 2.0)
ON DUPLICATE KEY UPDATE `job` = VALUES(`job`), `coords_x` = VALUES(`coords_x`), `coords_y` = VALUES(`coords_y`), `coords_z` = VALUES(`coords_z`), `distance` = VALUES(`distance`);

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
) ENGINE=InnoDB AUTO_INCREMENT=86 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla aurarp.aura_transactions: ~85 rows (aproximadamente)
INSERT INTO `aura_transactions` (`id`, `transaction_id`, `character_id`, `target_character_id`, `account`, `type`, `amount`, `balance_before`, `balance_after`, `fee`, `reason`, `metadata`, `created_at`) VALUES
	(1, 'TX-1788119036-11-f3ed8221', 11, NULL, 'bank', 'WITHDRAW', 500, 5000, 4500, 0, 'Emisión de Tarjeta de Crédito', NULL, '2026-08-30 19:43:56'),
	(2, 'TX-1788119131-11-62a01561', 11, NULL, 'bank', 'WITHDRAW', 500, 4500, 4000, 0, 'Retirada ATM', '{"executor":11}', '2026-08-30 19:45:31'),
	(3, 'TX-1788119131-11-999a8840', 11, NULL, 'cash', 'DEPOSIT', 500, 0, 500, 0, 'Retirada ATM', NULL, '2026-08-30 19:45:31'),
	(4, 'TX-1788119280-11-373265a0', 11, NULL, 'cash', 'WITHDRAW', 500, 500, 0, 0, 'Depósito bancario ATM', NULL, '2026-08-30 19:48:00'),
	(5, 'TX-1788119280-11-f1c96ad9', 11, NULL, 'bank', 'DEPOSIT', 500, 4000, 4500, 0, 'Depósito recibido', '{"executor":11}', '2026-08-30 19:48:00'),
	(6, 'TX-1788119601-11-3b184e27', 11, NULL, 'bank', 'WITHDRAW', 500, 4500, 4000, 0, 'Retirada ATM', '{"executor":11}', '2026-08-30 19:53:21'),
	(7, 'TX-1788119601-11-ba60c124', 11, NULL, 'cash', 'DEPOSIT', 500, 0, 500, 0, 'Físico: Creación directa en inventario (createItem)', '{"action":"CREATE_ITEM","count":500,"item":"money"}', '2026-08-30 19:53:21'),
	(8, 'TX-1788119601-11-698f1238', 11, NULL, 'cash', 'DEPOSIT', 500, 500, 1000, 0, 'Retirada ATM', NULL, '2026-08-30 19:53:21'),
	(9, 'TX-1788119612-11-6b8b8ba0', 11, NULL, 'bank', 'DEPOSIT', 500, 4000, 4500, 0, 'Depósito bancario ATM', '{"executor":11}', '2026-08-30 19:53:32'),
	(10, 'TX-1788119612-11-54435918', 11, NULL, 'cash', 'WITHDRAW', 500, 1000, 500, 0, 'Depósito bancario ATM', NULL, '2026-08-30 19:53:32'),
	(11, 'TX-1788120626-11-218addc6', 11, NULL, 'bank', 'WITHDRAW', 100, 4500, 4400, 0, 'Retirada ATM', '{"executor":11}', '2026-08-30 20:10:26'),
	(12, 'TX-1788120626-11-156091a3', 11, NULL, 'cash', 'DEPOSIT', 100, 500, 600, 0, 'Físico: Creación directa en inventario (createItem)', '{"action":"CREATE_ITEM","count":100,"item":"money"}', '2026-08-30 20:10:26'),
	(13, 'TX-1788120626-11-54806c5f', 11, NULL, 'cash', 'DEPOSIT', 100, 600, 700, 0, 'Retirada ATM', NULL, '2026-08-30 20:10:26'),
	(14, 'TX-1788121701-11-8a0db6ea', 11, NULL, 'cash', 'DEPOSIT', 600, 700, 1300, 0, 'Físico: Creación directa en inventario (createItem)', '{"item":"money","action":"CREATE_ITEM","count":600}', '2026-08-30 20:28:21'),
	(15, 'TX-1788123845-11-4d90538e', 11, NULL, 'cash', 'DEPOSIT', 600, 1300, 1900, 0, 'Físico: Creación directa en inventario (createItem)', '{"action":"CREATE_ITEM","item":"money","count":600}', '2026-08-30 21:04:05'),
	(16, 'TX-1788124690-11-ed906a9a', 11, NULL, 'cash', 'DEPOSIT', 600, 1900, 2500, 0, 'Físico: Creación directa en inventario (createItem)', '{"item":"money","count":600,"action":"CREATE_ITEM"}', '2026-08-30 21:18:10'),
	(17, 'TX-1788125224-11-81b45c2a', 11, NULL, 'cash', 'DEPOSIT', 600, 2500, 3100, 0, 'Físico: Creación directa en inventario (createItem)', '{"count":600,"action":"CREATE_ITEM","item":"money"}', '2026-08-30 21:27:04'),
	(18, 'TX-1788125407-11-b11c4261', 11, NULL, 'cash', 'DEPOSIT', 600, 3100, 3700, 0, 'Físico: Creación directa en inventario (createItem)', '{"item":"money","action":"CREATE_ITEM","count":600}', '2026-08-30 21:30:07'),
	(19, 'TX-1788125686-11-99edc916', 11, NULL, 'cash', 'DEPOSIT', 600, 3700, 4300, 0, 'Físico: Creación directa en inventario (createItem)', '{"count":600,"item":"money","action":"CREATE_ITEM"}', '2026-08-30 21:34:46'),
	(20, 'TX-1788126127-11-2655acd3', 11, NULL, 'cash', 'DEPOSIT', 600, 4300, 4900, 0, 'Físico: Creación directa en inventario (createItem)', '{"action":"CREATE_ITEM","item":"money","count":600}', '2026-08-30 21:42:07'),
	(21, 'TX-1788126389-11-6cf864f5', 11, NULL, 'cash', 'DEPOSIT', 600, 4900, 5500, 0, 'Físico: Creación directa en inventario (createItem)', '{"count":600,"action":"CREATE_ITEM","item":"money"}', '2026-08-30 21:46:29'),
	(22, 'TX-1788127009-11-353afcc5', 11, NULL, 'cash', 'DEPOSIT', 600, 5500, 6100, 0, 'Físico: Creación directa en inventario (createItem)', '{"item":"money","action":"CREATE_ITEM","count":600}', '2026-08-30 21:56:49'),
	(23, 'TX-1788127271-11-dd567267', 11, NULL, 'cash', 'DEPOSIT', 600, 6100, 6700, 0, 'Físico: Creación directa en inventario (createItem)', '{"item":"money","count":600,"action":"CREATE_ITEM"}', '2026-08-30 22:01:11'),
	(24, 'TX-1788127479-11-84f22469', 11, NULL, 'cash', 'DEPOSIT', 600, 6700, 7300, 0, 'Físico: Creación directa en inventario (createItem)', '{"item":"money","count":600,"action":"CREATE_ITEM"}', '2026-08-30 22:04:39'),
	(25, 'TX-1788127629-11-940ed2ec', 11, NULL, 'cash', 'DEPOSIT', 600, 7300, 7900, 0, 'Físico: Creación directa en inventario (createItem)', '{"count":600,"action":"CREATE_ITEM","item":"money"}', '2026-08-30 22:07:09'),
	(26, 'TX-1788127908-11-3f8a187a', 11, NULL, 'cash', 'DEPOSIT', 600, 7900, 8500, 0, 'Físico: Creación directa en inventario (createItem)', '{"count":600,"action":"CREATE_ITEM","item":"money"}', '2026-08-30 22:11:48'),
	(27, 'TX-1788160985-11-61ea34c1', 11, NULL, 'cash', 'DEPOSIT', 600, 8500, 9100, 0, 'Físico: Creación directa en inventario (createItem)', '{"count":600,"action":"CREATE_ITEM","item":"money"}', '2026-08-31 07:23:05'),
	(28, 'TX-1788162066-11-82766cf9', 11, NULL, 'cash', 'DEPOSIT', 600, 9100, 9700, 0, 'Físico: Creación directa en inventario (createItem)', '{"item":"money","action":"CREATE_ITEM","count":600}', '2026-08-31 07:41:06'),
	(29, 'TX-1788162144-11-e3f8863d', 11, NULL, 'cash', 'DEPOSIT', 600, 9700, 10300, 0, 'Físico: Creación directa en inventario (createItem)', '{"item":"money","action":"CREATE_ITEM","count":600}', '2026-08-31 07:42:24'),
	(30, 'TX-1788162582-11-55e6d398', 11, NULL, 'cash', 'DEPOSIT', 600, 10300, 10900, 0, 'Físico: Creación directa en inventario (createItem)', '{"count":600,"action":"CREATE_ITEM","item":"money"}', '2026-08-31 07:49:42'),
	(31, 'TX-1788162958-11-81e3d341', 11, NULL, 'cash', 'DEPOSIT', 600, 10900, 11500, 0, 'Físico: Creación directa en inventario (createItem)', '{"action":"CREATE_ITEM","item":"money","count":600}', '2026-08-31 07:55:58'),
	(32, 'TX-1788163406-11-c04aa6a2', 11, NULL, 'cash', 'DEPOSIT', 600, 11500, 12100, 0, 'Físico: Creación directa en inventario (createItem)', '{"action":"CREATE_ITEM","count":600,"item":"money"}', '2026-08-31 08:03:26'),
	(33, 'TX-1788163570-11-44e75896', 11, NULL, 'cash', 'DEPOSIT', 600, 12100, 12700, 0, 'Físico: Creación directa en inventario (createItem)', '{"item":"money","action":"CREATE_ITEM","count":600}', '2026-08-31 08:06:10'),
	(34, 'TX-1788163714-11-1eb465e1', 11, NULL, 'cash', 'DEPOSIT', 600, 12700, 13300, 0, 'Físico: Creación directa en inventario (createItem)', '{"action":"CREATE_ITEM","count":600,"item":"money"}', '2026-08-31 08:08:34'),
	(35, 'TX-1788165157-11-29bf9497', 11, NULL, 'cash', 'DEPOSIT', 600, 13300, 13900, 0, 'Físico: Creación directa en inventario (createItem)', '{"item":"money","count":600,"action":"CREATE_ITEM"}', '2026-08-31 08:32:37'),
	(36, 'TX-1788165378-11-21ea97a9', 11, NULL, 'cash', 'DEPOSIT', 600, 13900, 14500, 0, 'Físico: Creación directa en inventario (createItem)', '{"action":"CREATE_ITEM","count":600,"item":"money"}', '2026-08-31 08:36:18'),
	(37, 'TX-1788165964-11-d201e094', 11, NULL, 'cash', 'DEPOSIT', 600, 14500, 15100, 0, 'Físico: Creación directa en inventario (createItem)', '{"count":600,"item":"money","action":"CREATE_ITEM"}', '2026-08-31 08:46:04'),
	(38, 'TX-1788166868-11-bc0c06cd', 11, NULL, 'cash', 'DEPOSIT', 600, 15100, 15700, 0, 'Físico: Creación directa en inventario (createItem)', '{"item":"money","action":"CREATE_ITEM","count":600}', '2026-08-31 09:01:08'),
	(39, 'TX-1788168337-11-786f34fe', 11, NULL, 'cash', 'DEPOSIT', 600, 15700, 16300, 0, 'Físico: Creación directa en inventario (createItem)', '{"action":"CREATE_ITEM","item":"money","count":600}', '2026-08-31 09:25:37'),
	(40, 'TX-1788168600-11-99df6852', 11, NULL, 'cash', 'DEPOSIT', 600, 16300, 16900, 0, 'Físico: Creación directa en inventario (createItem)', '{"item":"money","action":"CREATE_ITEM","count":600}', '2026-08-31 09:30:00'),
	(41, 'TX-1788168875-11-412759fb', 11, NULL, 'cash', 'DEPOSIT', 600, 16900, 17500, 0, 'Físico: Creación directa en inventario (createItem)', '{"action":"CREATE_ITEM","item":"money","count":600}', '2026-08-31 09:34:35'),
	(42, 'TX-1788169317-11-23d52a05', 11, NULL, 'cash', 'DEPOSIT', 600, 17500, 18100, 0, 'Físico: Creación directa en inventario (createItem)', '{"action":"CREATE_ITEM","count":600,"item":"money"}', '2026-08-31 09:41:57'),
	(43, 'TX-1788169645-11-d8b87c70', 11, NULL, 'cash', 'DEPOSIT', 600, 18100, 18700, 0, 'Físico: Creación directa en inventario (createItem)', '{"action":"CREATE_ITEM","item":"money","count":600}', '2026-08-31 09:47:25'),
	(44, 'TX-1788170432-11-9a67a047', 11, NULL, 'cash', 'DEPOSIT', 600, 18700, 19300, 0, 'Físico: Creación directa en inventario (createItem)', '{"action":"CREATE_ITEM","count":600,"item":"money"}', '2026-08-31 10:00:32'),
	(45, 'TX-1788170587-11-28afb150', 11, NULL, 'cash', 'DEPOSIT', 600, 19300, 19900, 0, 'Físico: Creación directa en inventario (createItem)', '{"action":"CREATE_ITEM","count":600,"item":"money"}', '2026-08-31 10:03:07'),
	(46, 'TX-1788171272-11-85ff6b24', 11, NULL, 'cash', 'DEPOSIT', 600, 19900, 20500, 0, 'Físico: Creación directa en inventario (createItem)', '{"item":"money","action":"CREATE_ITEM","count":600}', '2026-08-31 10:14:32'),
	(47, 'TX-1788171551-11-390e906c', 11, NULL, 'cash', 'DEPOSIT', 600, 20500, 21100, 0, 'Físico: Creación directa en inventario (createItem)', '{"item":"money","count":600,"action":"CREATE_ITEM"}', '2026-08-31 10:19:11'),
	(48, 'TX-1788172138-11-78f1456c', 11, NULL, 'cash', 'DEPOSIT', 600, 21100, 21700, 0, 'Físico: Creación directa en inventario (createItem)', '{"count":600,"item":"money","action":"CREATE_ITEM"}', '2026-08-31 10:28:58'),
	(49, 'TX-1788173007-11-5107a765', 11, NULL, 'cash', 'DEPOSIT', 600, 21700, 22300, 0, 'Físico: Creación directa en inventario (createItem)', '{"count":600,"action":"CREATE_ITEM","item":"money"}', '2026-08-31 10:43:27'),
	(50, 'TX-1788173719-11-fc0bcd48', 11, NULL, 'cash', 'DEPOSIT', 600, 22300, 22900, 0, 'Físico: Creación directa en inventario (createItem)', '{"item":"money","action":"CREATE_ITEM","count":600}', '2026-08-31 10:55:19'),
	(51, 'TX-1788177271-11-2c1a317b', 11, NULL, 'cash', 'DEPOSIT', 600, 22900, 23500, 0, 'Físico: Creación directa en inventario (createItem)', '{"count":600,"item":"money","action":"CREATE_ITEM"}', '2026-08-31 11:54:31'),
	(52, 'TX-1788177991-11-79bbdafa', 11, NULL, 'cash', 'DEPOSIT', 600, 23500, 24100, 0, 'Físico: Creación directa en inventario (createItem)', '{"action":"CREATE_ITEM","count":600,"item":"money"}', '2026-08-31 12:06:31'),
	(53, 'TX-1788178282-11-24608212', 11, NULL, 'cash', 'DEPOSIT', 600, 24100, 24700, 0, 'Físico: Creación directa en inventario (createItem)', '{"item":"money","count":600,"action":"CREATE_ITEM"}', '2026-08-31 12:11:22'),
	(54, 'TX-1788184244-11-6636204c', 11, NULL, 'cash', 'DEPOSIT', 600, 24700, 25300, 0, 'Físico: Creación directa en inventario (createItem)', '{"item":"money","action":"CREATE_ITEM","count":600}', '2026-08-31 13:50:44'),
	(55, 'TX-1788184640-11-d749672c', 11, NULL, 'cash', 'DEPOSIT', 600, 25300, 25900, 0, 'Físico: Creación directa en inventario (createItem)', '{"count":600,"item":"money","action":"CREATE_ITEM"}', '2026-08-31 13:57:20'),
	(56, 'TX-1788185218-11-a812145f', 11, NULL, 'cash', 'DEPOSIT', 600, 25900, 26500, 0, 'Físico: Creación directa en inventario (createItem)', '{"action":"CREATE_ITEM","item":"money","count":600}', '2026-08-31 14:06:58'),
	(57, 'TX-1788189867-11-93c27119', 11, NULL, 'cash', 'DEPOSIT', 600, 26500, 27100, 0, 'Físico: Creación directa en inventario (createItem)', '{"count":600,"action":"CREATE_ITEM","item":"money"}', '2026-08-31 15:24:27'),
	(58, 'TX-1788191222-11-beae52da', 11, NULL, 'cash', 'DEPOSIT', 600, 27100, 27700, 0, 'Físico: Creación directa en inventario (createItem)', '{"item":"money","action":"CREATE_ITEM","count":600}', '2026-08-31 15:47:02'),
	(59, 'TX-1788191693-11-075b0173', 11, NULL, 'cash', 'DEPOSIT', 600, 27700, 28300, 0, 'Físico: Creación directa en inventario (createItem)', '{"action":"CREATE_ITEM","item":"money","count":600}', '2026-08-31 15:54:53'),
	(60, 'TX-1788192048-11-22429c86', 11, NULL, 'cash', 'DEPOSIT', 600, 28300, 28900, 0, 'Físico: Creación directa en inventario (createItem)', '{"count":600,"action":"CREATE_ITEM","item":"money"}', '2026-08-31 16:00:48'),
	(61, 'TX-1788192521-11-014054ff', 11, NULL, 'cash', 'DEPOSIT', 600, 28900, 29500, 0, 'Físico: Creación directa en inventario (createItem)', '{"action":"CREATE_ITEM","item":"money","count":600}', '2026-08-31 16:08:41'),
	(62, 'TX-1788254935-11-9943120d', 11, NULL, 'cash', 'DEPOSIT', 600, 29500, 30100, 0, 'Físico: Creación directa en inventario (createItem)', '{"action":"CREATE_ITEM","count":600,"item":"money"}', '2026-09-01 09:28:55'),
	(63, 'TX-1788257018-11-8c60a7b4', 11, NULL, 'cash', 'DEPOSIT', 600, 30100, 30700, 0, 'Físico: Creación directa en inventario (createItem)', '{"action":"CREATE_ITEM","count":600,"item":"money"}', '2026-09-01 10:03:38'),
	(64, 'TX-1788257284-11-e79e17f7', 11, NULL, 'cash', 'DEPOSIT', 600, 30700, 31300, 0, 'Físico: Creación directa en inventario (createItem)', '{"item":"money","action":"CREATE_ITEM","count":600}', '2026-09-01 10:08:04'),
	(65, 'TX-1788257914-11-6d4610e3', 11, NULL, 'cash', 'DEPOSIT', 600, 31300, 31900, 0, 'Físico: Creación directa en inventario (createItem)', '{"count":600,"item":"money","action":"CREATE_ITEM"}', '2026-09-01 10:18:34'),
	(66, 'TX-1788259040-11-c9438829', 11, NULL, 'cash', 'DEPOSIT', 600, 31900, 32500, 0, 'Físico: Creación directa en inventario (createItem)', '{"action":"CREATE_ITEM","item":"money","count":600}', '2026-09-01 10:37:20'),
	(67, 'TX-1788259714-11-19dac306', 11, NULL, 'cash', 'DEPOSIT', 600, 32500, 33100, 0, 'Físico: Creación directa en inventario (createItem)', '{"action":"CREATE_ITEM","count":600,"item":"money"}', '2026-09-01 10:48:34'),
	(68, 'TX-1788260512-11-32ce6e3e', 11, NULL, 'cash', 'DEPOSIT', 30600, 33100, 63700, 0, 'Físico: Creación directa en inventario (createItem)', '{"item":"money","count":30600,"action":"CREATE_ITEM"}', '2026-09-01 11:01:52'),
	(69, 'TX-1788261794-11-f5fe3318', 11, NULL, 'cash', 'DEPOSIT', 30638, 63700, 94338, 0, 'Físico: Creación directa en inventario (createItem)', '{"count":30638,"item":"money","action":"CREATE_ITEM"}', '2026-09-01 11:23:14'),
	(70, 'TX-1788262371-11-563b66a8', 11, NULL, 'cash', 'DEPOSIT', 30638, 94338, 124976, 0, 'Físico: Creación directa en inventario (createItem)', '{"item":"money","count":30638,"action":"CREATE_ITEM"}', '2026-09-01 11:32:51'),
	(71, 'TX-1788263007-11-3cb9d6da', 11, NULL, 'cash', 'DEPOSIT', 30638, 124976, 155614, 0, 'Físico: Creación directa en inventario (createItem)', '{"item":"money","action":"CREATE_ITEM","count":30638}', '2026-09-01 11:43:27'),
	(72, 'TX-1788263990-11-c162d133', 11, NULL, 'cash', 'DEPOSIT', 30638, 155614, 186252, 0, 'Físico: Creación directa en inventario (createItem)', '{"item":"money","action":"CREATE_ITEM","count":30638}', '2026-09-01 11:59:50'),
	(73, 'TX-1788265729-11-e89ac7df', 11, NULL, 'cash', 'DEPOSIT', 30638, 186252, 216890, 0, 'Físico: Creación directa en inventario (createItem)', '{"count":30638,"item":"money","action":"CREATE_ITEM"}', '2026-09-01 12:28:49'),
	(74, 'TX-1788266333-11-9937d657', 11, NULL, 'cash', 'DEPOSIT', 30638, 216890, 247528, 0, 'Físico: Creación directa en inventario (createItem)', '{"item":"money","action":"CREATE_ITEM","count":30638}', '2026-09-01 12:38:53'),
	(75, 'TX-1788266863-11-cb5274fe', 11, NULL, 'cash', 'DEPOSIT', 30638, 247528, 278166, 0, 'Físico: Creación directa en inventario (createItem)', '{"count":30638,"action":"CREATE_ITEM","item":"money"}', '2026-09-01 12:47:43'),
	(76, 'TX-1788268007-11-30e999ba', 11, NULL, 'cash', 'DEPOSIT', 30638, 278166, 308804, 0, 'Físico: Creación directa en inventario (createItem)', '{"action":"CREATE_ITEM","count":30638,"item":"money"}', '2026-09-01 13:06:47'),
	(77, 'TX-1788270308-11-70fd13c5', 11, NULL, 'cash', 'DEPOSIT', 30638, 308804, 339442, 0, 'Físico: Creación directa en inventario (createItem)', '{"item":"money","count":30638,"action":"CREATE_ITEM"}', '2026-09-01 13:45:08'),
	(78, 'TX-1788270687-11-29c6c202', 11, NULL, 'cash', 'DEPOSIT', 30638, 339442, 370080, 0, 'Físico: Creación directa en inventario (createItem)', '{"count":30638,"item":"money","action":"CREATE_ITEM"}', '2026-09-01 13:51:27'),
	(79, 'TX-1788271280-11-3d1379c6', 11, NULL, 'cash', 'DEPOSIT', 30638, 370080, 400718, 0, 'Físico: Creación directa en inventario (createItem)', '{"action":"CREATE_ITEM","item":"money","count":30638}', '2026-09-01 14:01:20'),
	(80, 'TX-1788275547-11-8ba4ff17', 11, NULL, 'cash', 'DEPOSIT', 30638, 400718, 431356, 0, 'Físico: Creación directa en inventario (createItem)', '{"action":"CREATE_ITEM","count":30638,"item":"money"}', '2026-09-01 15:12:27'),
	(81, 'TX-1788275760-11-9ca4374a', 11, NULL, 'cash', 'DEPOSIT', 30638, 431356, 461994, 0, 'Físico: Creación directa en inventario (createItem)', '{"count":30638,"action":"CREATE_ITEM","item":"money"}', '2026-09-01 15:16:00'),
	(82, 'TX-1788294318-11-395e3c58', 11, NULL, 'cash', 'DEPOSIT', 30638, 461994, 492632, 0, 'Físico: Creación directa en inventario (createItem)', '{"count":30638,"item":"money","action":"CREATE_ITEM"}', '2026-09-01 20:25:18'),
	(83, 'TX-1788294432-11-b82a91d7', 11, NULL, 'cash', 'DEPOSIT', 30638, 492632, 523270, 0, 'Físico: Creación directa en inventario (createItem)', '{"item":"money","action":"CREATE_ITEM","count":30638}', '2026-09-01 20:27:12'),
	(84, 'TX-1788294953-11-55a3a0f4', 11, NULL, 'cash', 'DEPOSIT', 30638, 523270, 553908, 0, 'Físico: Creación directa en inventario (createItem)', '{"count":30638,"item":"money","action":"CREATE_ITEM"}', '2026-09-01 20:35:53'),
	(85, 'TX-1788298337-11-7230df38', 11, NULL, 'cash', 'DEPOSIT', 30638, 553908, 584546, 0, 'Físico: Creación directa en inventario (createItem)', '{"item":"money","count":30638,"action":"CREATE_ITEM"}', '2026-09-01 21:32:17');

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
INSERT INTO `characters` (`id`, `citizenid`, `slot`, `firstname`, `lastname`, `nationality`, `dob`, `gender`, `metadata`, `created_at`, `last_played`, `accounts`, `inventory`, `job`, `job_grade`, `job_duty`, `iban`, `pin`, `phone_number`, `phone_settings`) VALUES
	(11, 'HLWWIZKU', 1, 'test', 'uno', 'Angola', '1990-12-11', 0, '{"cash":1000,"health":200,"armor":0,"last_location":{"x":317.67034912109377,"heading":93.54330444335938,"z":29.3978271484375,"y":-1092.7384033203126},"appearance":{"props":[{"texture":-1,"drawable":-1,"prop_id":0},{"texture":-1,"drawable":-1,"prop_id":1},{"texture":-1,"drawable":-1,"prop_id":2},{"texture":-1,"drawable":-1,"prop_id":6},{"texture":-1,"drawable":-1,"prop_id":7}],"eyeColor":0,"headOverlays":{"beard":{"secondColor":0,"color":0,"style":0,"opacity":0},"complexion":{"secondColor":0,"color":0,"style":0,"opacity":0},"blush":{"secondColor":0,"color":0,"style":0,"opacity":0},"ageing":{"secondColor":0,"color":0,"style":0,"opacity":0},"eyebrows":{"secondColor":0,"color":0,"style":0,"opacity":0},"bodyBlemishes":{"secondColor":0,"color":0,"style":0,"opacity":0},"lipstick":{"secondColor":0,"color":0,"style":0,"opacity":0},"blemishes":{"secondColor":0,"color":0,"style":0,"opacity":0},"sunDamage":{"secondColor":0,"color":0,"style":0,"opacity":0},"chestHair":{"secondColor":0,"color":0,"style":0,"opacity":0},"makeUp":{"secondColor":0,"color":0,"style":0,"opacity":0},"moleAndFreckles":{"secondColor":0,"color":0,"style":0,"opacity":0}},"components":[{"texture":0,"component_id":0,"drawable":0},{"texture":0,"component_id":1,"drawable":0},{"texture":0,"component_id":2,"drawable":0},{"texture":0,"component_id":3,"drawable":0},{"texture":0,"component_id":4,"drawable":0},{"texture":0,"component_id":5,"drawable":0},{"texture":0,"component_id":6,"drawable":0},{"texture":0,"component_id":7,"drawable":0},{"texture":0,"component_id":8,"drawable":0},{"texture":0,"component_id":9,"drawable":0},{"texture":0,"component_id":10,"drawable":0},{"texture":0,"component_id":11,"drawable":0}],"hair":{"color":0,"highlight":0,"style":0,"texture":0},"headBlend":{"skinFirst":0,"shapeMix":0,"skinMix":0,"skinSecond":0,"shapeSecond":0,"skinThird":0,"shapeThird":0,"thirdMix":0,"shapeFirst":0},"faceFeatures":{"chinBoneSize":0,"nosePeakLowering":0,"noseBoneHigh":0,"jawBoneWidth":0,"eyeBrownForward":0,"noseBoneTwist":0,"chinBoneLowering":0,"cheeksWidth":0,"nosePeakSize":0,"cheeksBoneHigh":0,"eyesOpening":0,"lipsThickness":0,"noseWidth":0,"jawBoneBackSize":0,"chinHole":0,"cheeksBoneWidth":0,"nosePeakHigh":0,"neckThickness":0,"chinBoneLenght":0,"eyeBrownHigh":0},"model":"mp_m_freemode_01","tattoos":[]},"bank":5000}', '2026-08-29 13:56:37', '2026-09-01 22:03:16', '{"cash":584546,"black_money":0,"bank":4400}', '[{"name":"credit_card","slot":1,"count":1,"metadata":{"owner":11,"iban":"AURA56149361","description":"IBAN: AURA56149361\\nTitular ID: 11"}},{"name":"money","slot":2,"count":553908},{"name":"phone","slot":3,"count":1}]', 'vazou', 4, 0, 'AURA56149361', '6444', '555-8966', '{"ringtone":"ringtone.mp3","security":{"pin_code":"","face_id":true},"message_tone":"sms.mp3","volume_msg":80,"notifications":{"messages":true,"bank":true,"calls":true},"volume_ring":80,"frame_color":"#555566","device_name":"Otto","wallpaper_url":"https://images.unsplash.com/photo-1550684848-fac1c5b4e853?q=80&w=2564&auto=format&fit=crop"}');

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
	(1, 'license:fb83002da5edb49dd7bdb39c170a8c8af7cf5298', 'HLWWIZKU', '{"permissions":"user","status":{"hunger":100,"thirst":100},"position":{"x":0.0,"z":0.0,"y":0.0},"money":{"cash":500,"bank":1500}}', '2026-08-28 18:31:20', '2026-09-01 21:31:59', '2026-09-01 21:31:59');

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
