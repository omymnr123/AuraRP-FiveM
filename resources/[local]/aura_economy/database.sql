-- ============================================================================
-- AURA ECONOMY: SCHEMA MIGRATION & AUDIT INFRASTRUCTURE (FASE 4)
-- ============================================================================

-- 1. Actualización de la estructura de personajes con columna de cuentas estrictamente validada
ALTER TABLE `characters` 
ADD COLUMN IF NOT EXISTS `accounts` LONGTEXT NOT NULL 
DEFAULT '{"cash":0,"bank":5000,"savings":0,"black_money":0}' 
COMMENT 'JSON: cash, bank, savings, black_money' 
CHECK (JSON_VALID(`accounts`));

-- 2. Tabla Inmutable de Registro y Auditoría de Transacciones (Doble Partida)
CREATE TABLE IF NOT EXISTS `aura_transactions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `transaction_id` VARCHAR(64) NOT NULL UNIQUE,
  `character_id` INT(11) NOT NULL,
  `target_character_id` INT(11) NULL DEFAULT NULL,
  `account` ENUM('cash', 'bank', 'savings', 'black_money') NOT NULL,
  `type` ENUM(
    'INITIAL',
    'DEPOSIT',
    'WITHDRAW',
    'TRANSFER_SEND',
    'TRANSFER_RECEIVE',
    'PURCHASE',
    'SALE',
    'TAX',
    'FINE',
    'SALARY',
    'SINK',
    'ADMIN'
  ) NOT NULL,
  `amount` BIGINT NOT NULL,
  `balance_before` BIGINT NOT NULL,
  `balance_after` BIGINT NOT NULL,
  `fee` BIGINT NOT NULL DEFAULT 0,
  `reason` VARCHAR(255) NOT NULL,
  `metadata` LONGTEXT NULL DEFAULT NULL CHECK (`metadata` IS NULL OR JSON_VALID(`metadata`)),
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_char_date` (`character_id`, `created_at`),
  KEY `idx_target_char` (`target_character_id`),
  KEY `idx_type` (`type`),
  KEY `idx_tx_uuid` (`transaction_id`),
  CONSTRAINT `fk_tx_character` FOREIGN KEY (`character_id`) REFERENCES `characters` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Tabla de Persistencia de Estado para el Mercado Dinámico
CREATE TABLE IF NOT EXISTS `aura_market_items` (
  `name` VARCHAR(50) NOT NULL PRIMARY KEY,
  `base_price` INT NOT NULL,
  `min_price` INT NOT NULL,
  `max_price` INT NOT NULL,
  `current_stock` INT NOT NULL DEFAULT 0,
  `target_stock` INT NOT NULL DEFAULT 1000,
  `elasticity` FLOAT NOT NULL DEFAULT 0.05,
  `last_updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
