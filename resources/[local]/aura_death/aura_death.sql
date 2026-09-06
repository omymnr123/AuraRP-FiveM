-- ============================================================================
-- AURA DEATH: SCHEMA DE BASE DE DATOS (ESTADO CRÍTICO Y PERSISTENCIA)
-- ============================================================================

CREATE TABLE IF NOT EXISTS `aura_death` (
  `character_id` int(11) NOT NULL,
  `citizenid` varchar(50) NOT NULL,
  `is_dead` tinyint(1) NOT NULL DEFAULT 0,
  `death_time` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `bleedout_remaining` int(11) NOT NULL DEFAULT 600 COMMENT 'Segundos restantes de estado crítico (10 min = 600 seg)',
  `death_reason` varchar(255) DEFAULT 'Heridas Críticas',
  `killer_source` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`character_id`),
  KEY `idx_death_citizenid` (`citizenid`),
  KEY `idx_death_status` (`is_dead`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
