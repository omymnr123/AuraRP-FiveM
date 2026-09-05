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

-- Volcando datos para la tabla aurarp.aura_doors: ~20 rows (aproximadamente)
INSERT INTO `aura_doors` (`door_id`, `is_locked`, `job`, `coords_x`, `coords_y`, `coords_z`, `distance`) VALUES
	('antiquebar_main', 1, 'antiquebar', 742.84, -2304.53, 20.84, 2.5),
	('barthedrink_main', 1, 'barthedrink', 1985.39, 3054.49, 47.21, 2.5),
	('henhouse_main', 1, 'henhouse', -297.5899963378906, 6271.259765625, 31.510000228881836, 2),
	('himenbar_main', 1, 'himenbar', 980.5, -1805.2, 31, 2.5),
	('police_armory1', 0, 'police', 444.3560485839844, -984.0791015625, 34.3011474609375, 2.5),
	('police_automatica1', 1, 'police', 445.71429443359375, -974.10986328125, 30.7120361328125, 2.5),
	('police_automatica2', 0, 'police', 445.6351623535156, -986.2813110351562, 30.7120361328125, 2.5),
	('police_automatica3', 0, 'police', 445.6087951660156, -994.2329711914062, 30.7120361328125, 2.5),
	('police_celda1', 1, 'police', 436.4307556152344, -995.116455078125, 27.4769287109375, 2.5),
	('police_main', 0, 'police', 434.75604248046875, -981.9296875, 30.6951904296875, 2.5),
	('police_main2', 0, 'police', 438.3164978027344, -981.982421875, 30.7120361328125, 2.5),
	('police_main3', 0, 'police', 441.5208740234375, -998.8483276367188, 30.7120361328125, 2.5),
	('police_main4', 0, 'police', 457.0681457519531, -972.4747314453125, 30.7120361328125, 2.5),
	('route68bar_main', 1, 'route68bar', 982, 2664, 40, 2.5),
	('salieri_1', 1, 'salieri', 316.5758361816406, -1092.6065673828125, 29.4146728515625, 2.5),
	('salieri_main', 1, 'salieri', 316.82000732421875, -1092.6199951171875, 29.420000076293945, 2),
	('sandyhookah_main', 1, 'sandyhookah', 1888.62, 3747.54, 32.88, 2.5),
	('vazou_main', 1, 'vazou', -1564.43994140625, -974.6099853515625, 13.020000457763672, 2),
	('vazou_secundaria', 1, 'vazou', -1558.6600341796875, -972.219970703125, 13.020000457763672, 2),
	('yellowjack_main', 1, 'yellowjack', 1986.04, 3048.36, 47.22, 2.5);

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

-- Volcando estructura para tabla aurarp.aura_gang_radio_channels
CREATE TABLE IF NOT EXISTS `aura_gang_radio_channels` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `gang` varchar(50) NOT NULL,
  `channel_index` int(11) NOT NULL,
  `label` varchar(64) NOT NULL,
  `color` varchar(16) NOT NULL DEFAULT '#00f2fe',
  `blip_color` int(11) NOT NULL DEFAULT 38,
  `frequency` decimal(6,1) NOT NULL,
  `is_encrypted` tinyint(1) NOT NULL DEFAULT 1,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_gang_channel` (`gang`,`channel_index`),
  KEY `idx_frequency` (`frequency`)
) ENGINE=InnoDB AUTO_INCREMENT=341 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla aurarp.aura_gang_radio_channels: ~220 rows (aproximadamente)
INSERT INTO `aura_gang_radio_channels` (`id`, `gang`, `channel_index`, `label`, `color`, `blip_color`, `frequency`, `is_encrypted`, `updated_at`) VALUES
	(1, 'salieri', 1, 'Emisora #01', '#00f2fe', 38, 201.0, 1, '2026-09-05 08:12:33'),
	(2, 'salieri', 2, 'Emisora #02', '#3b82f6', 3, 202.0, 1, '2026-09-05 08:12:33'),
	(3, 'salieri', 3, 'Emisora #03', '#00ff9d', 2, 203.0, 1, '2026-09-05 08:12:33'),
	(4, 'salieri', 4, 'Emisora #04', '#ff007f', 48, 204.0, 1, '2026-09-05 08:12:33'),
	(5, 'salieri', 5, 'Emisora #05', '#ff6b35', 47, 205.0, 1, '2026-09-05 08:12:33'),
	(6, 'salieri', 6, 'Emisora #06', '#9d4edd', 27, 206.0, 1, '2026-09-05 08:12:33'),
	(7, 'salieri', 7, 'Emisora #07', '#ff2a55', 1, 207.0, 1, '2026-09-05 08:12:33'),
	(8, 'salieri', 8, 'Emisora #08', '#ffffff', 0, 208.0, 1, '2026-09-05 08:12:33'),
	(9, 'salieri', 9, 'Emisora #09', '#ffff00', 5, 209.0, 1, '2026-09-05 08:12:33'),
	(10, 'salieri', 10, 'Emisora #10', '#06d6a0', 25, 210.0, 1, '2026-09-05 08:12:33'),
	(11, 'salieri', 11, 'Emisora #11', '#8338ec', 7, 211.0, 1, '2026-09-05 08:12:33'),
	(12, 'salieri', 12, 'Emisora #12', '#ff477e', 8, 212.0, 1, '2026-09-05 08:12:33'),
	(13, 'salieri', 13, 'Emisora #13', '#3a86ff', 18, 213.0, 1, '2026-09-05 08:12:33'),
	(14, 'salieri', 14, 'Emisora #14', '#fb5607', 17, 214.0, 1, '2026-09-05 08:12:33'),
	(15, 'salieri', 15, 'Emisora #15', '#70e000', 43, 215.0, 1, '2026-09-05 08:12:33'),
	(16, 'salieri', 16, 'Emisora #16', '#0077b6', 29, 216.0, 1, '2026-09-05 08:12:33'),
	(17, 'salieri', 17, 'Emisora #17', '#e0aaff', 19, 217.0, 1, '2026-09-05 08:12:33'),
	(18, 'salieri', 18, 'Emisora #18', '#b5179e', 21, 218.0, 1, '2026-09-05 08:12:33'),
	(19, 'salieri', 19, 'Emisora #19', '#a0aec0', 40, 219.0, 1, '2026-09-05 08:12:33'),
	(20, 'salieri', 20, 'Emisora #20', '#4cc9f0', 68, 220.0, 1, '2026-09-05 08:12:33'),
	(21, 'vazou', 1, 'Emisora #01', '#00f2fe', 38, 221.0, 1, '2026-09-05 08:12:33'),
	(22, 'vazou', 2, 'Emisora #02', '#3b82f6', 3, 222.0, 1, '2026-09-05 08:12:33'),
	(23, 'vazou', 3, 'Emisora #03', '#00ff9d', 2, 223.0, 1, '2026-09-05 08:12:33'),
	(24, 'vazou', 4, 'Emisora #04', '#ff007f', 48, 224.0, 1, '2026-09-05 08:12:33'),
	(25, 'vazou', 5, 'Emisora #05', '#ff6b35', 47, 225.0, 1, '2026-09-05 08:12:33'),
	(26, 'vazou', 6, 'Emisora #06', '#9d4edd', 27, 226.0, 1, '2026-09-05 08:12:33'),
	(27, 'vazou', 7, 'Emisora #07', '#ff2a55', 1, 227.0, 1, '2026-09-05 08:12:33'),
	(28, 'vazou', 8, 'Emisora #08', '#ffffff', 0, 228.0, 1, '2026-09-05 08:12:33'),
	(29, 'vazou', 9, 'Emisora #09', '#ffff00', 5, 229.0, 1, '2026-09-05 08:12:33'),
	(30, 'vazou', 10, 'Emisora #10', '#06d6a0', 25, 230.0, 1, '2026-09-05 08:12:33'),
	(31, 'vazou', 11, 'Emisora #11', '#8338ec', 7, 231.0, 1, '2026-09-05 08:12:33'),
	(32, 'vazou', 12, 'Emisora #12', '#ff477e', 8, 232.0, 1, '2026-09-05 08:12:33'),
	(33, 'vazou', 13, 'Emisora #13', '#3a86ff', 18, 233.0, 1, '2026-09-05 08:12:33'),
	(34, 'vazou', 14, 'Emisora #14', '#fb5607', 17, 234.0, 1, '2026-09-05 08:12:33'),
	(35, 'vazou', 15, 'Emisora #15', '#70e000', 43, 235.0, 1, '2026-09-05 08:12:33'),
	(36, 'vazou', 16, 'Emisora #16', '#0077b6', 29, 236.0, 1, '2026-09-05 08:12:33'),
	(37, 'vazou', 17, 'Emisora #17', '#e0aaff', 19, 237.0, 1, '2026-09-05 08:12:33'),
	(38, 'vazou', 18, 'Emisora #18', '#b5179e', 21, 238.0, 1, '2026-09-05 08:12:33'),
	(39, 'vazou', 19, 'Emisora #19', '#a0aec0', 40, 239.0, 1, '2026-09-05 08:12:33'),
	(40, 'vazou', 20, 'Emisora #20', '#4cc9f0', 68, 240.0, 1, '2026-09-05 08:12:33'),
	(41, 'cartel', 1, 'Emisora #01', '#00f2fe', 38, 241.0, 1, '2026-09-05 08:12:33'),
	(42, 'cartel', 2, 'Emisora #02', '#3b82f6', 3, 242.0, 1, '2026-09-05 08:12:33'),
	(43, 'cartel', 3, 'Emisora #03', '#00ff9d', 2, 243.0, 1, '2026-09-05 08:12:33'),
	(44, 'cartel', 4, 'Emisora #04', '#ff007f', 48, 244.0, 1, '2026-09-05 08:12:33'),
	(45, 'cartel', 5, 'Emisora #05', '#ff6b35', 47, 245.0, 1, '2026-09-05 08:12:33'),
	(46, 'cartel', 6, 'Emisora #06', '#9d4edd', 27, 246.0, 1, '2026-09-05 08:12:33'),
	(47, 'cartel', 7, 'Emisora #07', '#ff2a55', 1, 247.0, 1, '2026-09-05 08:12:33'),
	(48, 'cartel', 8, 'Emisora #08', '#ffffff', 0, 248.0, 1, '2026-09-05 08:12:33'),
	(49, 'cartel', 9, 'Emisora #09', '#ffff00', 5, 249.0, 1, '2026-09-05 08:12:33'),
	(50, 'cartel', 10, 'Emisora #10', '#06d6a0', 25, 250.0, 1, '2026-09-05 08:12:33'),
	(51, 'cartel', 11, 'Emisora #11', '#8338ec', 7, 251.0, 1, '2026-09-05 08:12:33'),
	(52, 'cartel', 12, 'Emisora #12', '#ff477e', 8, 252.0, 1, '2026-09-05 08:12:33'),
	(53, 'cartel', 13, 'Emisora #13', '#3a86ff', 18, 253.0, 1, '2026-09-05 08:12:33'),
	(54, 'cartel', 14, 'Emisora #14', '#fb5607', 17, 254.0, 1, '2026-09-05 08:12:33'),
	(55, 'cartel', 15, 'Emisora #15', '#70e000', 43, 255.0, 1, '2026-09-05 08:12:33'),
	(56, 'cartel', 16, 'Emisora #16', '#0077b6', 29, 256.0, 1, '2026-09-05 08:12:33'),
	(57, 'cartel', 17, 'Emisora #17', '#e0aaff', 19, 257.0, 1, '2026-09-05 08:12:33'),
	(58, 'cartel', 18, 'Emisora #18', '#b5179e', 21, 258.0, 1, '2026-09-05 08:12:33'),
	(59, 'cartel', 19, 'Emisora #19', '#a0aec0', 40, 259.0, 1, '2026-09-05 08:12:33'),
	(60, 'cartel', 20, 'Emisora #20', '#4cc9f0', 68, 260.0, 1, '2026-09-05 08:12:33'),
	(61, 'ballas', 1, 'Emisora #01', '#00f2fe', 38, 261.0, 1, '2026-09-05 08:12:33'),
	(62, 'ballas', 2, 'Emisora #02', '#3b82f6', 3, 262.0, 1, '2026-09-05 08:12:33'),
	(63, 'ballas', 3, 'Emisora #03', '#00ff9d', 2, 263.0, 1, '2026-09-05 08:12:33'),
	(64, 'ballas', 4, 'Emisora #04', '#ff007f', 48, 264.0, 1, '2026-09-05 08:12:33'),
	(65, 'ballas', 5, 'Emisora #05', '#ff6b35', 47, 265.0, 1, '2026-09-05 08:12:33'),
	(66, 'ballas', 6, 'Emisora #06', '#9d4edd', 27, 266.0, 1, '2026-09-05 08:12:33'),
	(67, 'ballas', 7, 'Emisora #07', '#ff2a55', 1, 267.0, 1, '2026-09-05 08:12:33'),
	(68, 'ballas', 8, 'Emisora #08', '#ffffff', 0, 268.0, 1, '2026-09-05 08:12:33'),
	(69, 'ballas', 9, 'Emisora #09', '#ffff00', 5, 269.0, 1, '2026-09-05 08:12:33'),
	(70, 'ballas', 10, 'Emisora #10', '#06d6a0', 25, 270.0, 1, '2026-09-05 08:12:33'),
	(71, 'ballas', 11, 'Emisora #11', '#8338ec', 7, 271.0, 1, '2026-09-05 08:12:33'),
	(72, 'ballas', 12, 'Emisora #12', '#ff477e', 8, 272.0, 1, '2026-09-05 08:12:33'),
	(73, 'ballas', 13, 'Emisora #13', '#3a86ff', 18, 273.0, 1, '2026-09-05 08:12:33'),
	(74, 'ballas', 14, 'Emisora #14', '#fb5607', 17, 274.0, 1, '2026-09-05 08:12:33'),
	(75, 'ballas', 15, 'Emisora #15', '#70e000', 43, 275.0, 1, '2026-09-05 08:12:33'),
	(76, 'ballas', 16, 'Emisora #16', '#0077b6', 29, 276.0, 1, '2026-09-05 08:12:33'),
	(77, 'ballas', 17, 'Emisora #17', '#e0aaff', 19, 277.0, 1, '2026-09-05 08:12:33'),
	(78, 'ballas', 18, 'Emisora #18', '#b5179e', 21, 278.0, 1, '2026-09-05 08:12:33'),
	(79, 'ballas', 19, 'Emisora #19', '#a0aec0', 40, 279.0, 1, '2026-09-05 08:12:33'),
	(80, 'ballas', 20, 'Emisora #20', '#4cc9f0', 68, 280.0, 1, '2026-09-05 08:12:33'),
	(81, 'families', 1, 'Emisora #01', '#00f2fe', 38, 281.0, 1, '2026-09-05 08:12:33'),
	(82, 'families', 2, 'Emisora #02', '#3b82f6', 3, 282.0, 1, '2026-09-05 08:12:33'),
	(83, 'families', 3, 'Emisora #03', '#00ff9d', 2, 283.0, 1, '2026-09-05 08:12:33'),
	(84, 'families', 4, 'Emisora #04', '#ff007f', 48, 284.0, 1, '2026-09-05 08:12:33'),
	(85, 'families', 5, 'Emisora #05', '#ff6b35', 47, 285.0, 1, '2026-09-05 08:12:33'),
	(86, 'families', 6, 'Emisora #06', '#9d4edd', 27, 286.0, 1, '2026-09-05 08:12:33'),
	(87, 'families', 7, 'Emisora #07', '#ff2a55', 1, 287.0, 1, '2026-09-05 08:12:33'),
	(88, 'families', 8, 'Emisora #08', '#ffffff', 0, 288.0, 1, '2026-09-05 08:12:33'),
	(89, 'families', 9, 'Emisora #09', '#ffff00', 5, 289.0, 1, '2026-09-05 08:12:33'),
	(90, 'families', 10, 'Emisora #10', '#06d6a0', 25, 290.0, 1, '2026-09-05 08:12:33'),
	(91, 'families', 11, 'Emisora #11', '#8338ec', 7, 291.0, 1, '2026-09-05 08:12:33'),
	(92, 'families', 12, 'Emisora #12', '#ff477e', 8, 292.0, 1, '2026-09-05 08:12:33'),
	(93, 'families', 13, 'Emisora #13', '#3a86ff', 18, 293.0, 1, '2026-09-05 08:12:33'),
	(94, 'families', 14, 'Emisora #14', '#fb5607', 17, 294.0, 1, '2026-09-05 08:12:33'),
	(95, 'families', 15, 'Emisora #15', '#70e000', 43, 295.0, 1, '2026-09-05 08:12:33'),
	(96, 'families', 16, 'Emisora #16', '#0077b6', 29, 296.0, 1, '2026-09-05 08:12:33'),
	(97, 'families', 17, 'Emisora #17', '#e0aaff', 19, 297.0, 1, '2026-09-05 08:12:33'),
	(98, 'families', 18, 'Emisora #18', '#b5179e', 21, 298.0, 1, '2026-09-05 08:12:33'),
	(99, 'families', 19, 'Emisora #19', '#a0aec0', 40, 299.0, 1, '2026-09-05 08:12:33'),
	(100, 'families', 20, 'Emisora #20', '#4cc9f0', 68, 300.0, 1, '2026-09-05 08:12:33'),
	(101, 'vagos', 1, 'Emisora #01', '#00f2fe', 38, 301.0, 1, '2026-09-05 08:12:33'),
	(102, 'vagos', 2, 'Emisora #02', '#3b82f6', 3, 302.0, 1, '2026-09-05 08:12:33'),
	(103, 'vagos', 3, 'Emisora #03', '#00ff9d', 2, 303.0, 1, '2026-09-05 08:12:33'),
	(104, 'vagos', 4, 'Emisora #04', '#ff007f', 48, 304.0, 1, '2026-09-05 08:12:33'),
	(105, 'vagos', 5, 'Emisora #05', '#ff6b35', 47, 305.0, 1, '2026-09-05 08:12:33'),
	(106, 'vagos', 6, 'Emisora #06', '#9d4edd', 27, 306.0, 1, '2026-09-05 08:12:33'),
	(107, 'vagos', 7, 'Emisora #07', '#ff2a55', 1, 307.0, 1, '2026-09-05 08:12:33'),
	(108, 'vagos', 8, 'Emisora #08', '#ffffff', 0, 308.0, 1, '2026-09-05 08:12:33'),
	(109, 'vagos', 9, 'Emisora #09', '#ffff00', 5, 309.0, 1, '2026-09-05 08:12:33'),
	(110, 'vagos', 10, 'Emisora #10', '#06d6a0', 25, 310.0, 1, '2026-09-05 08:12:33'),
	(111, 'vagos', 11, 'Emisora #11', '#8338ec', 7, 311.0, 1, '2026-09-05 08:12:33'),
	(112, 'vagos', 12, 'Emisora #12', '#ff477e', 8, 312.0, 1, '2026-09-05 08:12:33'),
	(113, 'vagos', 13, 'Emisora #13', '#3a86ff', 18, 313.0, 1, '2026-09-05 08:12:33'),
	(114, 'vagos', 14, 'Emisora #14', '#fb5607', 17, 314.0, 1, '2026-09-05 08:12:33'),
	(115, 'vagos', 15, 'Emisora #15', '#70e000', 43, 315.0, 1, '2026-09-05 08:12:33'),
	(116, 'vagos', 16, 'Emisora #16', '#0077b6', 29, 316.0, 1, '2026-09-05 08:12:33'),
	(117, 'vagos', 17, 'Emisora #17', '#e0aaff', 19, 317.0, 1, '2026-09-05 08:12:33'),
	(118, 'vagos', 18, 'Emisora #18', '#b5179e', 21, 318.0, 1, '2026-09-05 08:12:33'),
	(119, 'vagos', 19, 'Emisora #19', '#a0aec0', 40, 319.0, 1, '2026-09-05 08:12:33'),
	(120, 'vagos', 20, 'Emisora #20', '#4cc9f0', 68, 320.0, 1, '2026-09-05 08:12:33'),
	(241, 'lostmc', 1, 'Emisora #01', '#00f2fe', 38, 321.0, 1, '2026-09-05 16:12:50'),
	(242, 'lostmc', 2, 'Emisora #02', '#3b82f6', 3, 322.0, 1, '2026-09-05 16:12:50'),
	(243, 'lostmc', 3, 'Emisora #03', '#00ff9d', 2, 323.0, 1, '2026-09-05 16:12:50'),
	(244, 'lostmc', 4, 'Emisora #04', '#ff007f', 48, 324.0, 1, '2026-09-05 16:12:50'),
	(245, 'lostmc', 5, 'Emisora #05', '#ff6b35', 47, 325.0, 1, '2026-09-05 16:12:50'),
	(246, 'lostmc', 6, 'Emisora #06', '#9d4edd', 27, 326.0, 1, '2026-09-05 16:12:50'),
	(247, 'lostmc', 7, 'Emisora #07', '#ff2a55', 1, 327.0, 1, '2026-09-05 16:12:50'),
	(248, 'lostmc', 8, 'Emisora #08', '#ffffff', 0, 328.0, 1, '2026-09-05 16:12:50'),
	(249, 'lostmc', 9, 'Emisora #09', '#ffff00', 5, 329.0, 1, '2026-09-05 16:12:50'),
	(250, 'lostmc', 10, 'Emisora #10', '#06d6a0', 25, 330.0, 1, '2026-09-05 16:12:50'),
	(251, 'lostmc', 11, 'Emisora #11', '#8338ec', 7, 331.0, 1, '2026-09-05 16:12:50'),
	(252, 'lostmc', 12, 'Emisora #12', '#ff477e', 8, 332.0, 1, '2026-09-05 16:12:50'),
	(253, 'lostmc', 13, 'Emisora #13', '#3a86ff', 18, 333.0, 1, '2026-09-05 16:12:50'),
	(254, 'lostmc', 14, 'Emisora #14', '#fb5607', 17, 334.0, 1, '2026-09-05 16:12:50'),
	(255, 'lostmc', 15, 'Emisora #15', '#70e000', 43, 335.0, 1, '2026-09-05 16:12:50'),
	(256, 'lostmc', 16, 'Emisora #16', '#0077b6', 29, 336.0, 1, '2026-09-05 16:12:50'),
	(257, 'lostmc', 17, 'Emisora #17', '#e0aaff', 19, 337.0, 1, '2026-09-05 16:12:50'),
	(258, 'lostmc', 18, 'Emisora #18', '#b5179e', 21, 338.0, 1, '2026-09-05 16:12:50'),
	(259, 'lostmc', 19, 'Emisora #19', '#a0aec0', 40, 339.0, 1, '2026-09-05 16:12:50'),
	(260, 'lostmc', 20, 'Emisora #20', '#4cc9f0', 68, 340.0, 1, '2026-09-05 16:12:50'),
	(261, 'bratva', 1, 'Emisora #01', '#00f2fe', 38, 341.0, 1, '2026-09-05 16:12:50'),
	(262, 'bratva', 2, 'Emisora #02', '#3b82f6', 3, 342.0, 1, '2026-09-05 16:12:50'),
	(263, 'bratva', 3, 'Emisora #03', '#00ff9d', 2, 343.0, 1, '2026-09-05 16:12:50'),
	(264, 'bratva', 4, 'Emisora #04', '#ff007f', 48, 344.0, 1, '2026-09-05 16:12:50'),
	(265, 'bratva', 5, 'Emisora #05', '#ff6b35', 47, 345.0, 1, '2026-09-05 16:12:50'),
	(266, 'bratva', 6, 'Emisora #06', '#9d4edd', 27, 346.0, 1, '2026-09-05 16:12:50'),
	(267, 'bratva', 7, 'Emisora #07', '#ff2a55', 1, 347.0, 1, '2026-09-05 16:12:50'),
	(268, 'bratva', 8, 'Emisora #08', '#ffffff', 0, 348.0, 1, '2026-09-05 16:12:50'),
	(269, 'bratva', 9, 'Emisora #09', '#ffff00', 5, 349.0, 1, '2026-09-05 16:12:50'),
	(270, 'bratva', 10, 'Emisora #10', '#06d6a0', 25, 350.0, 1, '2026-09-05 16:12:50'),
	(271, 'bratva', 11, 'Emisora #11', '#8338ec', 7, 351.0, 1, '2026-09-05 16:12:50'),
	(272, 'bratva', 12, 'Emisora #12', '#ff477e', 8, 352.0, 1, '2026-09-05 16:12:50'),
	(273, 'bratva', 13, 'Emisora #13', '#3a86ff', 18, 353.0, 1, '2026-09-05 16:12:50'),
	(274, 'bratva', 14, 'Emisora #14', '#fb5607', 17, 354.0, 1, '2026-09-05 16:12:50'),
	(275, 'bratva', 15, 'Emisora #15', '#70e000', 43, 355.0, 1, '2026-09-05 16:12:50'),
	(276, 'bratva', 16, 'Emisora #16', '#0077b6', 29, 356.0, 1, '2026-09-05 16:12:50'),
	(277, 'bratva', 17, 'Emisora #17', '#e0aaff', 19, 357.0, 1, '2026-09-05 16:12:50'),
	(278, 'bratva', 18, 'Emisora #18', '#b5179e', 21, 358.0, 1, '2026-09-05 16:12:50'),
	(279, 'bratva', 19, 'Emisora #19', '#a0aec0', 40, 359.0, 1, '2026-09-05 16:12:50'),
	(280, 'bratva', 20, 'Emisora #20', '#4cc9f0', 68, 360.0, 1, '2026-09-05 16:12:50'),
	(281, 'triada', 1, 'Emisora #01', '#00f2fe', 38, 361.0, 1, '2026-09-05 16:12:50'),
	(282, 'triada', 2, 'Emisora #02', '#3b82f6', 3, 362.0, 1, '2026-09-05 16:12:50'),
	(283, 'triada', 3, 'Emisora #03', '#00ff9d', 2, 363.0, 1, '2026-09-05 16:12:50'),
	(284, 'triada', 4, 'Emisora #04', '#ff007f', 48, 364.0, 1, '2026-09-05 16:12:50'),
	(285, 'triada', 5, 'Emisora #05', '#ff6b35', 47, 365.0, 1, '2026-09-05 16:12:50'),
	(286, 'triada', 6, 'Emisora #06', '#9d4edd', 27, 366.0, 1, '2026-09-05 16:12:50'),
	(287, 'triada', 7, 'Emisora #07', '#ff2a55', 1, 367.0, 1, '2026-09-05 16:12:50'),
	(288, 'triada', 8, 'Emisora #08', '#ffffff', 0, 368.0, 1, '2026-09-05 16:12:50'),
	(289, 'triada', 9, 'Emisora #09', '#ffff00', 5, 369.0, 1, '2026-09-05 16:12:50'),
	(290, 'triada', 10, 'Emisora #10', '#06d6a0', 25, 370.0, 1, '2026-09-05 16:12:50'),
	(291, 'triada', 11, 'Emisora #11', '#8338ec', 7, 371.0, 1, '2026-09-05 16:12:50'),
	(292, 'triada', 12, 'Emisora #12', '#ff477e', 8, 372.0, 1, '2026-09-05 16:12:50'),
	(293, 'triada', 13, 'Emisora #13', '#3a86ff', 18, 373.0, 1, '2026-09-05 16:12:50'),
	(294, 'triada', 14, 'Emisora #14', '#fb5607', 17, 374.0, 1, '2026-09-05 16:12:50'),
	(295, 'triada', 15, 'Emisora #15', '#70e000', 43, 375.0, 1, '2026-09-05 16:12:50'),
	(296, 'triada', 16, 'Emisora #16', '#0077b6', 29, 376.0, 1, '2026-09-05 16:12:50'),
	(297, 'triada', 17, 'Emisora #17', '#e0aaff', 19, 377.0, 1, '2026-09-05 16:12:50'),
	(298, 'triada', 18, 'Emisora #18', '#b5179e', 21, 378.0, 1, '2026-09-05 16:12:50'),
	(299, 'triada', 19, 'Emisora #19', '#a0aec0', 40, 379.0, 1, '2026-09-05 16:12:50'),
	(300, 'triada', 20, 'Emisora #20', '#4cc9f0', 68, 380.0, 1, '2026-09-05 16:12:50'),
	(301, 'yakuza', 1, 'Emisora #01', '#00f2fe', 38, 381.0, 1, '2026-09-05 16:12:50'),
	(302, 'yakuza', 2, 'Emisora #02', '#3b82f6', 3, 382.0, 1, '2026-09-05 16:12:50'),
	(303, 'yakuza', 3, 'Emisora #03', '#00ff9d', 2, 383.0, 1, '2026-09-05 16:12:50'),
	(304, 'yakuza', 4, 'Emisora #04', '#ff007f', 48, 384.0, 1, '2026-09-05 16:12:50'),
	(305, 'yakuza', 5, 'Emisora #05', '#ff6b35', 47, 385.0, 1, '2026-09-05 16:12:50'),
	(306, 'yakuza', 6, 'Emisora #06', '#9d4edd', 27, 386.0, 1, '2026-09-05 16:12:50'),
	(307, 'yakuza', 7, 'Emisora #07', '#ff2a55', 1, 387.0, 1, '2026-09-05 16:12:50'),
	(308, 'yakuza', 8, 'Emisora #08', '#ffffff', 0, 388.0, 1, '2026-09-05 16:12:50'),
	(309, 'yakuza', 9, 'Emisora #09', '#ffff00', 5, 389.0, 1, '2026-09-05 16:12:50'),
	(310, 'yakuza', 10, 'Emisora #10', '#06d6a0', 25, 390.0, 1, '2026-09-05 16:12:50'),
	(311, 'yakuza', 11, 'Emisora #11', '#8338ec', 7, 391.0, 1, '2026-09-05 16:12:50'),
	(312, 'yakuza', 12, 'Emisora #12', '#ff477e', 8, 392.0, 1, '2026-09-05 16:12:50'),
	(313, 'yakuza', 13, 'Emisora #13', '#3a86ff', 18, 393.0, 1, '2026-09-05 16:12:50'),
	(314, 'yakuza', 14, 'Emisora #14', '#fb5607', 17, 394.0, 1, '2026-09-05 16:12:50'),
	(315, 'yakuza', 15, 'Emisora #15', '#70e000', 43, 395.0, 1, '2026-09-05 16:12:50'),
	(316, 'yakuza', 16, 'Emisora #16', '#0077b6', 29, 396.0, 1, '2026-09-05 16:12:50'),
	(317, 'yakuza', 17, 'Emisora #17', '#e0aaff', 19, 397.0, 1, '2026-09-05 16:12:50'),
	(318, 'yakuza', 18, 'Emisora #18', '#b5179e', 21, 398.0, 1, '2026-09-05 16:12:50'),
	(319, 'yakuza', 19, 'Emisora #19', '#a0aec0', 40, 399.0, 1, '2026-09-05 16:12:50'),
	(320, 'yakuza', 20, 'Emisora #20', '#4cc9f0', 68, 400.0, 1, '2026-09-05 16:12:50'),
	(321, 'marabunta', 1, 'Emisora #01', '#00f2fe', 38, 401.0, 1, '2026-09-05 16:12:50'),
	(322, 'marabunta', 2, 'Emisora #02', '#3b82f6', 3, 402.0, 1, '2026-09-05 16:12:50'),
	(323, 'marabunta', 3, 'Emisora #03', '#00ff9d', 2, 403.0, 1, '2026-09-05 16:12:50'),
	(324, 'marabunta', 4, 'Emisora #04', '#ff007f', 48, 404.0, 1, '2026-09-05 16:12:50'),
	(325, 'marabunta', 5, 'Emisora #05', '#ff6b35', 47, 405.0, 1, '2026-09-05 16:12:50'),
	(326, 'marabunta', 6, 'Emisora #06', '#9d4edd', 27, 406.0, 1, '2026-09-05 16:12:50'),
	(327, 'marabunta', 7, 'Emisora #07', '#ff2a55', 1, 407.0, 1, '2026-09-05 16:12:50'),
	(328, 'marabunta', 8, 'Emisora #08', '#ffffff', 0, 408.0, 1, '2026-09-05 16:12:50'),
	(329, 'marabunta', 9, 'Emisora #09', '#ffff00', 5, 409.0, 1, '2026-09-05 16:12:50'),
	(330, 'marabunta', 10, 'Emisora #10', '#06d6a0', 25, 410.0, 1, '2026-09-05 16:12:50'),
	(331, 'marabunta', 11, 'Emisora #11', '#8338ec', 7, 411.0, 1, '2026-09-05 16:12:50'),
	(332, 'marabunta', 12, 'Emisora #12', '#ff477e', 8, 412.0, 1, '2026-09-05 16:12:50'),
	(333, 'marabunta', 13, 'Emisora #13', '#3a86ff', 18, 413.0, 1, '2026-09-05 16:12:50'),
	(334, 'marabunta', 14, 'Emisora #14', '#fb5607', 17, 414.0, 1, '2026-09-05 16:12:50'),
	(335, 'marabunta', 15, 'Emisora #15', '#70e000', 43, 415.0, 1, '2026-09-05 16:12:50'),
	(336, 'marabunta', 16, 'Emisora #16', '#0077b6', 29, 416.0, 1, '2026-09-05 16:12:50'),
	(337, 'marabunta', 17, 'Emisora #17', '#e0aaff', 19, 417.0, 1, '2026-09-05 16:12:50'),
	(338, 'marabunta', 18, 'Emisora #18', '#b5179e', 21, 418.0, 1, '2026-09-05 16:12:50'),
	(339, 'marabunta', 19, 'Emisora #19', '#a0aec0', 40, 419.0, 1, '2026-09-05 16:12:50'),
	(340, 'marabunta', 20, 'Emisora #20', '#4cc9f0', 68, 420.0, 1, '2026-09-05 16:12:50');

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

-- Volcando estructura para tabla aurarp.aura_greenhouses
CREATE TABLE IF NOT EXISTS `aura_greenhouses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `gang_id` varchar(50) NOT NULL,
  `exterior_x` double NOT NULL,
  `exterior_y` double NOT NULL,
  `exterior_z` double NOT NULL,
  `exterior_h` float NOT NULL DEFAULT 0,
  `created_by` varchar(100) DEFAULT 'Admin',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_greenhouse_gang` (`gang_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla aurarp.aura_greenhouses: ~1 rows (aproximadamente)
INSERT INTO `aura_greenhouses` (`id`, `gang_id`, `exterior_x`, `exterior_y`, `exterior_z`, `exterior_h`, `created_by`, `created_at`, `updated_at`) VALUES
	(1, 'vazou', -1577.82861328125, -976.4307861328125, 13.0029296875, 138.898, 'LazyNewt4084', '2026-09-05 09:24:22', '2026-09-05 09:24:22');

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

-- Volcando estructura para tabla aurarp.aura_plants
CREATE TABLE IF NOT EXISTS `aura_plants` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `gang_id` varchar(50) NOT NULL,
  `stage` int(11) NOT NULL DEFAULT 1 COMMENT 'Fase visual 1 a 4',
  `growth` float NOT NULL DEFAULT 0 COMMENT 'Porcentaje de crecimiento 0.0 a 100.0',
  `thirst` float NOT NULL DEFAULT 100 COMMENT 'Nivel de hidratación 0.0 a 100.0',
  `nutrition` float NOT NULL DEFAULT 100 COMMENT 'Nivel de abono NPK 0.0 a 100.0',
  `neglected_time` int(11) NOT NULL DEFAULT 0,
  `mature_time` int(11) NOT NULL DEFAULT 0,
  `coords_x` double NOT NULL,
  `coords_y` double NOT NULL,
  `coords_z` double NOT NULL,
  `heading` float NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_plants_gang` (`gang_id`),
  KEY `idx_plants_stage` (`stage`,`growth`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla aurarp.aura_plants: ~0 rows (aproximadamente)

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

-- Volcando estructura para tabla aurarp.aura_police_radio_channels
CREATE TABLE IF NOT EXISTS `aura_police_radio_channels` (
  `channel_id` varchar(32) NOT NULL,
  `label` varchar(64) NOT NULL,
  `color` varchar(16) NOT NULL DEFAULT '#00f2fe',
  `blip_color` int(11) NOT NULL DEFAULT 38,
  `frequency` int(11) NOT NULL,
  `is_mando` tinyint(1) NOT NULL DEFAULT 0,
  `is_encrypted` tinyint(1) NOT NULL DEFAULT 1,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`channel_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla aurarp.aura_police_radio_channels: ~21 rows (aproximadamente)
INSERT INTO `aura_police_radio_channels` (`channel_id`, `label`, `color`, `blip_color`, `frequency`, `is_mando`, `is_encrypted`, `updated_at`) VALUES
	('mando', 'Canal de Mando', '#ffb700', 46, 100, 1, 1, '2026-09-04 17:35:17'),
	('patrol_1', 'Patrulla #01', '#00f2fe', 38, 101, 0, 1, '2026-09-05 08:01:40'),
	('patrol_10', 'Patrulla #10', '#06d6a0', 25, 110, 0, 1, '2026-09-05 07:38:02'),
	('patrol_11', 'Patrulla #11', '#8338ec', 7, 111, 0, 1, '2026-09-05 07:38:02'),
	('patrol_12', 'Patrulla #12', '#ff477e', 8, 112, 0, 1, '2026-09-05 07:38:02'),
	('patrol_13', 'Patrulla #13', '#3a86ff', 18, 113, 0, 1, '2026-09-05 07:38:02'),
	('patrol_14', 'Patrulla #14', '#fb5607', 17, 114, 0, 1, '2026-09-05 07:38:02'),
	('patrol_15', 'Patrulla #15', '#70e000', 43, 115, 0, 1, '2026-09-05 07:38:02'),
	('patrol_16', 'Patrulla #16', '#0077b6', 29, 116, 0, 1, '2026-09-05 07:38:02'),
	('patrol_17', 'Patrulla #17', '#e0aaff', 19, 117, 0, 1, '2026-09-05 07:38:02'),
	('patrol_18', 'Patrulla #18', '#b5179e', 21, 118, 0, 1, '2026-09-05 07:38:02'),
	('patrol_19', 'Patrulla #19', '#a0aec0', 40, 119, 0, 1, '2026-09-05 07:38:02'),
	('patrol_2', 'Patrulla #02', '#3b82f6', 3, 102, 0, 1, '2026-09-04 17:35:17'),
	('patrol_20', 'Patrulla #20', '#4cc9f0', 68, 120, 0, 1, '2026-09-05 07:38:02'),
	('patrol_3', 'Patrulla #03', '#00ff9d', 2, 103, 0, 1, '2026-09-04 17:35:17'),
	('patrol_4', 'Patrulla #04', '#ff007f', 48, 104, 0, 1, '2026-09-04 17:35:17'),
	('patrol_5', 'Patrulla #05', '#ff6b35', 47, 105, 0, 1, '2026-09-04 17:35:17'),
	('patrol_6', 'Patrulla #06', '#9d4edd', 27, 106, 0, 1, '2026-09-04 17:35:17'),
	('patrol_7', 'Patrulla #07', '#ff2a55', 1, 107, 0, 1, '2026-09-04 17:35:17'),
	('patrol_8', 'Patrulla #08', '#ffffff', 0, 108, 0, 1, '2026-09-04 17:35:17'),
	('patrol_9', 'Patrulla #09', '#ffff00', 5, 109, 0, 1, '2026-09-05 07:38:02');

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

-- Volcando datos para la tabla aurarp.aura_societies: ~35 rows (aproximadamente)
INSERT INTO `aura_societies` (`name`, `label`, `balance`, `last_updated`) VALUES
	('aceliquor', 'Ace Liquor (Sandy Shores)', 15000, '2026-09-01 21:15:39'),
	('ambulance', 'Emergency Medical Services', 50000, '2026-09-01 09:25:49'),
	('antiquebar', 'Antique Bar & Pub', 15000, '2026-09-05 15:53:51'),
	('bahama', 'Bahama Mamas West', 15000, '2026-09-01 09:25:49'),
	('ballas', 'East Los Santos Ballas', 25000, '2026-09-04 08:17:10'),
	('banhamliquor', 'Rob\'s Liquor (Banham Canyon)', 15000, '2026-09-01 21:15:39'),
	('barthedrink', 'Bar The Drink', 15000, '2026-09-05 15:53:51'),
	('bratva', 'Bratva (Mafia Rusa)', 50000, '2026-09-05 16:12:50'),
	('burgershot', 'Burgershot Vespucci', 15000, '2026-09-01 09:25:49'),
	('cardealer', 'Premium Deluxe Motorsport', 100000, '2026-09-01 09:25:49'),
	('cartel', 'Cártel de Sinaloa / Medellín', 50000, '2026-09-04 08:17:10'),
	('elrancholiquor', 'Rob\'s Liquor (El Rancho Blvd)', 15000, '2026-09-01 21:15:39'),
	('families', 'Chamberlain Gangster Families', 25000, '2026-09-04 08:17:10'),
	('harmonyliquor', 'Rob\'s Liquor (Harmony Route 68)', 15000, '2026-09-01 21:15:39'),
	('henhouse', 'The Hen House Bar', 15000, '2026-09-01 22:18:44'),
	('himenbar', 'Himen Bar & Club', 15000, '2026-09-05 15:53:51'),
	('lostmc', 'The Lost MC Club', 50000, '2026-09-05 16:12:50'),
	('mafia', 'Familia Salieri & Cártel Clandestino', 50000, '2026-09-04 08:17:10'),
	('marabunta', 'Marabunta Grande', 50000, '2026-09-05 16:12:50'),
	('mechanic', 'Los Santos Customs', 25000, '2026-09-01 09:25:49'),
	('morningwoodliquor', 'Rob\'s Liquor (Morningwood)', 15000, '2026-09-01 21:15:39'),
	('paletoliquor', 'Paleto Bay Liquor Store', 15000, '2026-09-01 22:18:44'),
	('pearls', 'Pearls Seafood Restaurant', 12000, '2026-09-01 09:25:49'),
	('police', 'Los Santos Police Department', 50000, '2026-09-01 09:25:49'),
	('route68bar', 'Route 68 Clubhouse & Bar', 15000, '2026-09-05 15:53:51'),
	('salieri', 'Familia Salieri & Cártel Clandestino', 15000, '2026-09-04 10:36:58'),
	('sandyhookah', 'Sandy Hookah Lounge', 15000, '2026-09-05 15:53:51'),
	('taxi', 'Downtown Cab Co.', 10000, '2026-09-01 09:25:49'),
	('tequilala', 'Tequi-la-la Bar & Club', 30038, '2026-09-01 11:07:09'),
	('triada', 'Tríada Asiática', 50000, '2026-09-05 16:12:50'),
	('vagos', 'Los Santos Vagos', 25000, '2026-09-04 08:17:10'),
	('vanilla', 'Vanilla Unicorn Club', 15000, '2026-09-01 09:25:49'),
	('vazou', 'Cártel Marc Vazou', 15000, '2026-09-04 10:36:58'),
	('yakuza', 'Sindicato Yakuza', 50000, '2026-09-05 16:12:50'),
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
) ENGINE=InnoDB AUTO_INCREMENT=99 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla aurarp.aura_transactions: ~20 rows (aproximadamente)
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
	(96, 'TX-1788520627-11-84518e41', 11, NULL, 'bank', 'DEPOSIT', 3040, 16560, 19600, 0, 'Nómina: LSPD (Comisario)', '{"tax_rate":0.05,"gross":3200,"grade":5,"tax_sunk":160,"job":"police"}', '2026-09-04 11:17:07'),
	(97, 'TX-1788542622-11-bbcba315', 11, NULL, 'bank', 'DEPOSIT', 3040, 19600, 22640, 0, 'Nómina: LSPD (Comisario)', '{"grade":5,"tax_rate":0.05,"job":"police","tax_sunk":160,"gross":3200}', '2026-09-04 17:23:42'),
	(98, 'TX-1788594980-11-0d07b989', 11, NULL, 'bank', 'DEPOSIT', 3040, 22640, 25680, 0, 'Nómina: LSPD (Comisario)', '{"grade":5,"job":"police","tax_sunk":160,"gross":3200,"tax_rate":0.05}', '2026-09-05 07:56:20');

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
	(11, 'HLWWIZKU', 1, 'test', 'uno', 'Angola', '1990-12-11', 0, '{"appearance":{"components":[{"drawable":0,"texture":0,"component_id":0},{"drawable":0,"texture":0,"component_id":1},{"drawable":0,"texture":0,"component_id":2},{"drawable":200,"texture":0,"component_id":3},{"drawable":52,"texture":1,"component_id":4},{"drawable":0,"texture":0,"component_id":5},{"drawable":24,"texture":0,"component_id":6},{"drawable":1,"texture":0,"component_id":7},{"drawable":253,"texture":0,"component_id":8},{"drawable":101,"texture":0,"component_id":9},{"drawable":0,"texture":0,"component_id":10},{"drawable":629,"texture":0,"component_id":11}],"props":[{"drawable":10,"texture":6,"prop_id":0},{"drawable":15,"texture":7,"prop_id":1},{"drawable":-1,"texture":-1,"prop_id":2},{"drawable":-1,"texture":-1,"prop_id":6},{"drawable":-1,"texture":-1,"prop_id":7}],"model":"mp_m_freemode_01","faceFeatures":{"nosePeakLowering":0,"chinBoneLowering":0,"eyeBrownHigh":0,"neckThickness":0,"chinBoneLenght":0,"jawBoneWidth":0,"jawBoneBackSize":0,"lipsThickness":0,"noseBoneHigh":0,"eyeBrownForward":0,"noseBoneTwist":0,"chinBoneSize":0,"cheeksWidth":0,"nosePeakHigh":0,"chinHole":0,"noseWidth":0,"nosePeakSize":0,"cheeksBoneWidth":0,"cheeksBoneHigh":0,"eyesOpening":0},"hair":{"color":0,"texture":0,"style":0,"highlight":0},"tattoos":[],"headBlend":{"thirdMix":0,"shapeThird":0,"shapeFirst":0,"shapeMix":0,"skinMix":0,"shapeSecond":0,"skinThird":0,"skinSecond":0,"skinFirst":0},"headOverlays":{"moleAndFreckles":{"secondColor":0,"style":0,"opacity":0,"color":0},"bodyBlemishes":{"secondColor":0,"style":0,"opacity":0,"color":0},"ageing":{"secondColor":0,"style":0,"opacity":0,"color":0},"beard":{"secondColor":0,"style":0,"opacity":0,"color":0},"blush":{"secondColor":0,"style":0,"opacity":0,"color":0},"complexion":{"secondColor":0,"style":0,"opacity":0,"color":0},"eyebrows":{"secondColor":0,"style":0,"opacity":0,"color":0},"blemishes":{"secondColor":0,"style":0,"opacity":0,"color":0},"lipstick":{"secondColor":0,"style":0,"opacity":0,"color":0},"chestHair":{"secondColor":0,"style":0,"opacity":0,"color":0},"makeUp":{"secondColor":0,"style":0,"opacity":0,"color":0},"sunDamage":{"secondColor":0,"style":0,"opacity":0,"color":0}},"eyeColor":0},"cash":1000,"last_location":{"y":-1543.2659912109376,"x":496.73406982421877,"heading":93.54330444335938,"z":29.24609375},"bank":5000,"health":200,"armor":0}', '2026-08-29 13:56:37', '2026-09-05 15:55:44', '{"bank":25680,"black_money":0,"cash":500}', '[{"name":"weed","count":14,"slot":1},{"name":"coca_leaf","count":30,"slot":2},{"name":"maceta_vacia","count":5,"slot":3},{"name":"meth","count":27,"slot":5},{"name":"sulfuric_acid","count":2,"slot":6},{"name":"baking_soda","count":4,"slot":7},{"name":"weed_seed","count":5,"slot":8},{"name":"empty_baggies","count":31,"slot":9},{"name":"fertilizante","count":3,"slot":10},{"name":"saco_tierra","count":5,"slot":11},{"name":"tijeras_podar","count":1,"slot":12},{"name":"cogollo_weed","count":52,"slot":13},{"name":"cocaine","count":25,"slot":15},{"name":"WEAPON_FLASHLIGHT","metadata":{"durability":100,"components":[]},"count":1,"slot":45},{"name":"credit_card","metadata":{"iban":"AURA56149361","description":"IBAN: AURA56149361\\nTitular ID: 11","owner":11},"count":1,"slot":32},{"name":"lockpick","count":4,"slot":33},{"name":"bodycam","count":1,"slot":49},{"name":"police_badge","metadata":{"officer_name":"test uno","grade_label":"Comisario","badge":"101","description":"Placa Nº: 101\\nOficial: test uno\\nRango: Comisario\\nDepartamento: LSPD","citizenid":"HLWWIZKU"},"count":1,"slot":50},{"name":"black_money","count":2758,"slot":38},{"name":"money","count":500,"slot":42},{"name":"phone","count":1,"slot":43},{"name":"WEAPON_NIGHTSTICK","metadata":{"durability":100,"components":[]},"count":1,"slot":44},{"name":"adv_lockpick","count":2,"slot":34}]', 'vazou', 4, 0, '101', 0, 'AURA56149361', '6444', '555-8966', '{"ringtone":"ringtone.mp3","security":{"pin_code":"","face_id":true},"message_tone":"sms.mp3","volume_msg":80,"notifications":{"messages":true,"bank":true,"calls":true},"volume_ring":80,"frame_color":"#555566","device_name":"Otto","wallpaper_url":"https://images.unsplash.com/photo-1550684848-fac1c5b4e853?q=80&w=2564&auto=format&fit=crop"}'),
	(12, 'HLWWIZKU', 2, 'Gang', 'Test', 'Afganistán', '1990-02-05', 0, '{"appearance": {"hair": {"color": 0, "style": 14, "texture": 0, "highlight": 0}, "components": [{"texture": 0, "drawable": 0, "component_id": 0}, {"texture": 0, "drawable": 0, "component_id": 1}, {"texture": 0, "drawable": 0, "component_id": 2}, {"texture": 0, "drawable": 0, "component_id": 3}, {"texture": 0, "drawable": 0, "component_id": 4}, {"texture": 0, "drawable": 0, "component_id": 5}, {"texture": 0, "drawable": 8, "component_id": 6}, {"texture": 0, "drawable": 0, "component_id": 7}, {"texture": 0, "drawable": 0, "component_id": 8}, {"texture": 0, "drawable": 0, "component_id": 9}, {"texture": 0, "drawable": 0, "component_id": 10}, {"texture": 0, "drawable": 57, "component_id": 11}], "props": [{"drawable": -1, "texture": -1, "prop_id": 0}, {"drawable": -1, "texture": -1, "prop_id": 1}, {"drawable": -1, "texture": -1, "prop_id": 2}, {"drawable": -1, "texture": -1, "prop_id": 6}, {"drawable": -1, "texture": -1, "prop_id": 7}], "headOverlays": {"bodyBlemishes": {"color": 0, "style": 0, "secondColor": 0, "opacity": 0}, "makeUp": {"color": 0, "style": 0, "secondColor": 0, "opacity": 0}, "complexion": {"color": 0, "style": 0, "secondColor": 0, "opacity": 0}, "ageing": {"color": 0, "style": 0, "secondColor": 0, "opacity": 0}, "moleAndFreckles": {"color": 0, "style": 0, "secondColor": 0, "opacity": 0}, "sunDamage": {"color": 0, "style": 0, "secondColor": 0, "opacity": 0}, "beard": {"color": 0, "style": 16, "secondColor": 0, "opacity": 1}, "blemishes": {"color": 0, "style": 0, "secondColor": 0, "opacity": 0}, "blush": {"color": 0, "style": 0, "secondColor": 0, "opacity": 0}, "eyebrows": {"color": 0, "style": 0, "secondColor": 0, "opacity": 0}, "lipstick": {"color": 0, "style": 0, "secondColor": 0, "opacity": 0}, "chestHair": {"color": 0, "style": 0, "secondColor": 0, "opacity": 0}}, "tattoos": [], "headBlend": {"shapeMix": 0, "skinMix": 0, "shapeThird": 0, "shapeFirst": 0, "skinThird": 0, "thirdMix": 0, "skinFirst": 0, "shapeSecond": 0, "skinSecond": 0}, "model": "mp_m_freemode_01", "faceFeatures": {"noseWidth": 0, "jawBoneWidth": 0, "cheeksBoneHigh": 0, "nosePeakSize": 0, "chinHole": 0, "chinBoneSize": 0, "jawBoneBackSize": 0, "lipsThickness": 0, "nosePeakLowering": 0, "neckThickness": 0, "chinBoneLowering": 0, "cheeksBoneWidth": 0, "nosePeakHigh": 0, "eyeBrownForward": 0, "chinBoneLenght": 0, "eyeBrownHigh": 0, "noseBoneHigh": 0, "eyesOpening": 0, "cheeksWidth": 0, "noseBoneTwist": 0}, "eyeColor": 0}, "cash": 0, "health": 200, "armor": 0, "last_location": {"y": -1701.6527099609376, "x": -430.9186706542969, "heading": 215.43309020996095, "z": 19.018310546875}, "black_money": 0, "bank": 5000, "hud_positions": {"hud": {"x": 17.5, "y": 3.5}, "hotbar": {"x": 50.0, "y": 3.5}}}', '2026-09-04 08:29:03', '2026-09-04 16:52:15', '{"black_money":0,"cash":0,"bank":5000}', '[{"name":"adv_lockpick","count":10,"slot":1},{"name":"lockpick","count":2,"slot":2},{"name":"car_parts","count":5,"slot":3},{"name":"car_wheel","count":4,"slot":4},{"name":"black_money","count":18285,"slot":5},{"name":"car_door","count":4,"slot":6},{"name":"car_hood","count":1,"slot":7},{"name":"car_engine","count":1,"slot":8},{"name":"scrap_metal","count":7,"slot":9},{"name":"car_exhaust","count":1,"slot":10}]', 'cartel', 4, 0, NULL, 0, NULL, NULL, '555-8236', NULL),
	(13, 'FULGFGXT', 1, 'Carlos', 'Romero', 'China', '2000-02-01', 0, '{"health": 200, "black_money": 0, "appearance": {"faceFeatures": {"nosePeakSize": 0, "noseBoneHigh": 0, "neckThickness": 0, "jawBoneWidth": 0, "nosePeakLowering": 0, "nosePeakHigh": 0, "chinBoneLowering": 0, "cheeksWidth": 0, "chinBoneLenght": 0, "jawBoneBackSize": 0, "chinHole": 0, "cheeksBoneHigh": 0, "eyeBrownHigh": 0, "noseBoneTwist": 0, "chinBoneSize": 0, "noseWidth": 0, "lipsThickness": 0, "eyesOpening": 0, "eyeBrownForward": 0, "cheeksBoneWidth": 0}, "props": [{"prop_id": 0, "drawable": -1, "texture": -1}, {"prop_id": 1, "drawable": -1, "texture": -1}, {"prop_id": 2, "drawable": -1, "texture": -1}, {"prop_id": 6, "drawable": -1, "texture": -1}, {"prop_id": 7, "drawable": -1, "texture": -1}], "headBlend": {"skinSecond": 0, "skinThird": 0, "skinFirst": 0, "thirdMix": 0, "shapeFirst": 0, "shapeSecond": 0, "skinMix": 0, "shapeMix": 0, "shapeThird": 0}, "hair": {"highlight": 0, "style": 57, "texture": 0, "color": 0}, "model": "mp_m_freemode_01", "headOverlays": {"moleAndFreckles": {"secondColor": 0, "style": 0, "opacity": 0, "color": 0}, "complexion": {"secondColor": 0, "style": 0, "opacity": 0, "color": 0}, "eyebrows": {"secondColor": 0, "style": 0, "opacity": 0, "color": 0}, "ageing": {"secondColor": 0, "style": 0, "opacity": 0, "color": 0}, "makeUp": {"secondColor": 0, "style": 0, "opacity": 0, "color": 0}, "beard": {"secondColor": 0, "style": 0, "opacity": 0, "color": 0}, "chestHair": {"secondColor": 0, "style": 0, "opacity": 0, "color": 0}, "lipstick": {"secondColor": 0, "style": 0, "opacity": 0, "color": 0}, "blemishes": {"secondColor": 0, "style": 0, "opacity": 0, "color": 0}, "bodyBlemishes": {"secondColor": 0, "style": 0, "opacity": 0, "color": 0}, "blush": {"secondColor": 0, "style": 0, "opacity": 0, "color": 0}, "sunDamage": {"secondColor": 0, "style": 0, "opacity": 0, "color": 0}}, "components": [{"drawable": 0, "component_id": 0, "texture": 0}, {"drawable": 0, "component_id": 1, "texture": 0}, {"drawable": 0, "component_id": 2, "texture": 0}, {"drawable": 0, "component_id": 3, "texture": 0}, {"drawable": 0, "component_id": 4, "texture": 0}, {"drawable": 0, "component_id": 5, "texture": 0}, {"drawable": 0, "component_id": 6, "texture": 0}, {"drawable": 0, "component_id": 7, "texture": 0}, {"drawable": 0, "component_id": 8, "texture": 0}, {"drawable": 0, "component_id": 9, "texture": 0}, {"drawable": 0, "component_id": 10, "texture": 0}, {"drawable": 0, "component_id": 11, "texture": 0}], "eyeColor": 0, "tattoos": []}, "last_location": {"x": -863.6439819335938, "heading": 141.73228454589845, "z": 13.5084228515625, "y": -2616.514404296875}, "bank": 5000, "armor": 0, "cash": 0, "hud_positions": {"hud": {"x": 17.5, "y": 3.5}, "hotbar": {"x": 50.0, "y": 3.5}}}', '2026-09-04 10:15:11', '2026-09-04 16:52:15', '{"bank":5000,"black_money":0,"cash":0}', NULL, 'unemployed', 0, 0, NULL, 0, NULL, NULL, '555-2548', NULL);

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
	(1, 'license:fb83002da5edb49dd7bdb39c170a8c8af7cf5298', 'HLWWIZKU', '{"permissions":"user","status":{"hunger":100,"thirst":100},"position":{"x":0.0,"z":0.0,"y":0.0},"money":{"cash":500,"bank":1500}}', '2026-08-28 18:31:20', '2026-09-05 15:41:45', '2026-09-05 15:41:45'),
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

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
