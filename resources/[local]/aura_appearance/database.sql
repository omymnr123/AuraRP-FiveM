-- Tabla requerida por illenium-appearance para almacenar las apariencias
-- Ejecutar en tu base de datos MariaDB antes de iniciar el servidor

CREATE TABLE IF NOT EXISTS `playerskins` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(255) NOT NULL,
  `model` varchar(255) NOT NULL,
  `skin` text NOT NULL,
  `active` tinyint(4) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`),
  KEY `active` (`active`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;

-- Tablas opcionales para outfits (player_outfits, player_outfit_codes, management_outfits)
-- Puedes ejecutar los archivos SQL de illenium-appearance/sql/ si necesitas la funcionalidad de outfits guardados.
