-- ============================================================================
-- AURA MEDICAL: BASE DE DATOS Y REGISTROS CLÍNICOS P2P
-- Phase 11: Sistema Interactivo de Diagnóstico y Telemetría Quirúrgica
-- ============================================================================

CREATE TABLE IF NOT EXISTS `aura_medical_records` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL COMMENT 'Identificador único del paciente',
  `patient_name` varchar(100) NOT NULL COMMENT 'Nombre completo del paciente',
  `doctor_citizenid` varchar(50) DEFAULT NULL COMMENT 'Identificador del sanitario actuante',
  `doctor_name` varchar(100) DEFAULT 'Cuerpo Médico AuraRP',
  `diagnosis` text NOT NULL COMMENT 'Resumen clínico o motivo del ingreso',
  `injuries_json` longtext NOT NULL COMMENT 'JSON detallado de zonas afectadas y tipos de lesión reportados',
  `treatments_json` longtext DEFAULT NULL COMMENT 'JSON de tratamientos aplicados y medicamentos administrados',
  `vital_signs` longtext NOT NULL COMMENT 'Frecuencia cardíaca (BPM), estado hemodinámico y resultado',
  `outcome` varchar(50) NOT NULL DEFAULT 'Estabilizado / Reanimado' COMMENT 'Resultado clínico final',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_medical_citizenid` (`citizenid`),
  KEY `idx_medical_doctor` (`doctor_citizenid`),
  KEY `idx_medical_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `aura_medical_diagnoses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `session_id` varchar(64) NOT NULL,
  `patient_src` int(11) NOT NULL,
  `medic_src` int(11) NOT NULL,
  `bpm_initial` int(11) NOT NULL DEFAULT 75,
  `bpm_final` int(11) NOT NULL DEFAULT 75,
  `total_injuries` int(11) NOT NULL DEFAULT 0,
  `cured_injuries` int(11) NOT NULL DEFAULT 0,
  `is_revived` tinyint(1) NOT NULL DEFAULT 0,
  `payload_json` longtext NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_diag_session` (`session_id`),
  KEY `idx_diag_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
