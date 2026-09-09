-- ============================================================================
-- AURA MEDICAL: CONFIGURACIÓN GENERAL (PHASE 11: P2P MEDICAL DIAGNOSTICS & TELEMETRY)
-- ============================================================================

Config = {}

-- Modo depuración en consola del servidor y cliente
Config.Debug = false

-- Nombre del trabajo médico autorizado (EMS)
Config.JobName = 'ambulance'

-- ============================================================================
-- 1. ZONAS ANATÓMICAS CLÍNICAS (10 ZONAS TOTALMENTE DIFERENCIADAS DERECHA/IZQUIERDA)
-- ============================================================================
Config.Zones = {
    head = {
        id = "head",
        label = "Cabeza y Cuello",
        icon = "fa-solid fa-head-side-medical",
        description = "Región craneoencefálica, macizo facial y vértebras cervicales."
    },
    torso = {
        id = "torso",
        label = "Tronco y Tórax",
        icon = "fa-solid fa-lungs",
        description = "Caja torácica, órganos vitales, abdomen y columna dorsal."
    },
    right_arm = {
        id = "right_arm",
        label = "Brazo Derecho",
        icon = "fa-solid fa-hand-fist",
        description = "Húmero derecho, cúbito, radio y articulación del codo derecho."
    },
    left_arm = {
        id = "left_arm",
        label = "Brazo Izquierdo",
        icon = "fa-solid fa-hand-fist",
        description = "Húmero izquierdo, cúbito, radio y articulación del codo izquierdo."
    },
    right_hand = {
        id = "right_hand",
        label = "Mano Derecha",
        icon = "fa-solid fa-hands",
        description = "Carpianos, metacarpianos y falanges de la mano derecha."
    },
    left_hand = {
        id = "left_hand",
        label = "Mano Izquierda",
        icon = "fa-solid fa-hands",
        description = "Carpianos, metacarpianos y falanges de la mano izquierda."
    },
    right_leg = {
        id = "right_leg",
        label = "Pierna Derecha",
        icon = "fa-solid fa-person-running",
        description = "Fémur derecho, rótula, tibia, peroné y cuádriceps derecho."
    },
    left_leg = {
        id = "left_leg",
        label = "Pierna Izquierda",
        icon = "fa-solid fa-person-running",
        description = "Fémur izquierdo, rótula, tibia, peroné y cuádriceps izquierdo."
    },
    right_foot = {
        id = "right_foot",
        label = "Pie Derecho",
        icon = "fa-solid fa-shoe-prints",
        description = "Tarso, metatarso y falanges del pie derecho."
    },
    left_foot = {
        id = "left_foot",
        label = "Pie Izquierdo",
        icon = "fa-solid fa-shoe-prints",
        description = "Tarso, metatarso y falanges del pie izquierdo."
    }
}

-- ============================================================================
-- 2. TIPOS DE LESIÓN CLÍNICA Y TRATAMIENTOS ASOCIADOS (8 TRAUMATISMOS)
-- ============================================================================
Config.InjuryTypes = {
    contusion = {
        id = "contusion",
        label = "Contusión",
        description = "Traumatismo por impacto directo con hematoma subcutáneo.",
        badgeColor = "#ffaa00",
        treatment = "Aplicar Compresa Fría / Antiinflamatorio",
        treatmentIcon = "fa-solid fa-snowflake"
    },
    scratch = {
        id = "scratch",
        label = "Rasguño superficial",
        description = "Erosión epidérmica con sangrado capilar leve y riesgo de infección.",
        badgeColor = "#40E0D0",
        treatment = "Desinfectar y Colocar Vendaje Estéril",
        treatmentIcon = "fa-solid fa-bandage"
    },
    puncture = {
        id = "puncture",
        label = "Herida punzante",
        description = "Perforación profunda tisular por arma blanca o fragmento afilado.",
        badgeColor = "#ff00a0",
        treatment = "Cauterizar, Limpiar y Suturar Herida",
        treatmentIcon = "fa-solid fa-syringe"
    },
    bullet = {
        id = "bullet",
        label = "Herida de bala",
        description = "Impacto por proyectil balístico con penetración profunda y sangrado activo.",
        badgeColor = "#ff007f",
        treatment = "Extraer Proyectil con Pinzas Quirúrgicas",
        treatmentIcon = "fa-solid fa-crosshairs"
    },
    bone_break = {
        id = "bone_break",
        label = "Rotura de hueso",
        description = "Fractura ósea con desplazamiento o fisura estructural severa.",
        badgeColor = "#e11d48",
        treatment = "Alinear y Entablillar Fractura Ósea",
        treatmentIcon = "fa-solid fa-bone"
    },
    sprain = {
        id = "sprain",
        label = "Esguince",
        description = "Distensión ligamentosa articular aguda por hiperextensión o torsión.",
        badgeColor = "#d946ef",
        treatment = "Aplicar Vendaje Compresivo Funcional",
        treatmentIcon = "fa-solid fa-tape"
    },
    burn = {
        id = "burn",
        label = "Quemadura",
        description = "Lesión dérmica térmica con compromiso flictenular o tisular.",
        badgeColor = "#ff5500",
        treatment = "Aplicar Pomada Hidratante y Apósitos",
        treatmentIcon = "fa-solid fa-fire-flame-curved"
    },
    muscle_tear = {
        id = "muscle_tear",
        label = "Desgarro muscular",
        description = "Ruptura de fibras musculares con inflamación e impotencia funcional.",
        badgeColor = "#8b5cf6",
        treatment = "Infiltración Muscular y Reposo Asistido",
        treatmentIcon = "fa-solid fa-heart-pulse"
    }
}

-- ============================================================================
-- 3. FARMACOLOGÍA Y ESTABILIZACIÓN HEMODINÁMICA (BPM CONTROL)
-- ============================================================================
Config.Medications = {
    adrenaline = {
        id = "adrenaline",
        label = "Inyectar Adrenalina (Epinefrina)",
        description = "Aumenta la contractilidad miocárdica y eleva el ritmo cardíaco.",
        icon = "fa-solid fa-syringe",
        bpmDelta = 25,
        color = "#ff007f"
    },
    sedative = {
        id = "sedative",
        label = "Inyectar Sedante / Antiarrítmico",
        description = "Reduce la taquicardia severa y estabiliza el gasto cardíaco.",
        icon = "fa-solid fa-pills",
        bpmDelta = -20,
        color = "#40E0D0"
    },
    atropine = {
        id = "atropine",
        label = "Administrar Atropina",
        description = "Estimulante vagolítico para revertir bradicardias moderadas.",
        icon = "fa-solid fa-flask-vial",
        bpmDelta = 15,
        color = "#00f2fe"
    },
    saline = {
        id = "saline",
        label = "Solución Salina Fisiológica",
        description = "Restaura volemia y normaliza el pulso hacia 75 BPM.",
        icon = "fa-solid fa-droplet",
        bpmDelta = 0,
        color = "#3b82f6"
    }
}

-- ============================================================================
-- 4. PROCEDIMIENTOS FINALES (DESBLOQUEABLES TRAS CURACIÓN Y ESTABILIZACIÓN)
-- ============================================================================
Config.FinalProcedures = {
    tourniquet = {
        label = "CONTROLAR HEMORRAGIA",
        item = "torniquete",
        icon = "fa-solid fa-droplet-slash",
        animDict = "amb@medic@standing@kneel@base",
        animClip = "base"
    },
    defib = {
        label = "DESFIBRILADOR (DEA)",
        item = "desfibrilador",
        icon = "fa-solid fa-bolt-lightning",
        animDict = "mini@cpr@char_a@cpr_str",
        animClip = "cpr_pumpchest"
    }
}

-- Rango de BPM seguro para permitir reanimación / cierre quirúrgico
Config.StableBpmRange = {
    min = 60,
    max = 100
}

-- ============================================================================
-- 5. MAPEO ÓSEO DE HUESOS (10 REGIONES ANATÓMICAS)
-- ============================================================================
Config.Bones = {
    head = {
        label = "Cabeza y Cuello",
        icon = "head",
        boneIds = { 31086, 39317, 25260, 12844 },
        primaryBone = 31086,
        side = "head",
        maxHealth = 100
    },
    torso = {
        label = "Tórax y Espina Dorsal",
        icon = "torso",
        boneIds = { 24818, 24817, 24816, 11816, 57597, 23553, 0 },
        primaryBone = 24818,
        side = "torso",
        maxHealth = 100
    },
    right_arm = {
        label = "Brazo Derecho",
        icon = "right_arm",
        boneIds = { 40269, 28252 },
        primaryBone = 28252,
        side = "left",
        maxHealth = 100
    },
    left_arm = {
        label = "Brazo Izquierdo",
        icon = "left_arm",
        boneIds = { 45509, 61163 },
        primaryBone = 61163,
        side = "right",
        maxHealth = 100
    },
    right_hand = {
        label = "Mano Derecha",
        icon = "right_hand",
        boneIds = { 57005, 58866, 58867, 58868, 58869, 58870 },
        primaryBone = 57005,
        side = "left",
        maxHealth = 100
    },
    left_hand = {
        label = "Mano Izquierda",
        icon = "left_hand",
        boneIds = { 18905, 26610, 26611, 26612, 26613, 26614, 60309 },
        primaryBone = 18905,
        side = "right",
        maxHealth = 100
    },
    right_leg = {
        label = "Pierna Derecha",
        icon = "right_leg",
        boneIds = { 51826, 36864 },
        primaryBone = 36864,
        side = "left",
        maxHealth = 100
    },
    left_leg = {
        label = "Pierna Izquierda",
        icon = "left_leg",
        boneIds = { 58271, 63931 },
        primaryBone = 63931,
        side = "right",
        maxHealth = 100
    },
    right_foot = {
        label = "Pie Derecho",
        icon = "right_foot",
        boneIds = { 52301, 35502, 6442 },
        primaryBone = 52301,
        side = "left",
        maxHealth = 100
    },
    left_foot = {
        label = "Pie Izquierdo",
        icon = "left_foot",
        boneIds = { 14201, 20781, 23639 },
        primaryBone = 14201,
        side = "right",
        maxHealth = 100
    }
}

Config.DamageTypes = {
    Bullet = { label = "Impacto Balístico", badgeColor = "#ff007f", severityLevels = { Minor = "Rozadura Balística", Moderate = "Herida Perforante", Severe = "Hemorragia Interna", Critical = "Trauma Balístico Masivo" } },
    Cut = { label = "Laceración / Corte", badgeColor = "#ff00a0", severityLevels = { Minor = "Corte Superficial", Moderate = "Laceración Profunda", Severe = "Daño Muscular", Critical = "Sección Vascular" } },
    Blunt = { label = "Contusión / Traumatismo", badgeColor = "#ffaa00", severityLevels = { Minor = "Hematoma", Moderate = "Contusión Fuerte", Severe = "Fractura Desplazada", Critical = "Aplastamiento Óseo" } },
    Burn = { label = "Quemadura Térmica", badgeColor = "#ff5500", severityLevels = { Minor = "Quemadura 1er Grado", Moderate = "Quemadura 2º Grado", Severe = "Quemadura 3er Grado", Critical = "Quemadura Crítica" } },
    Fall = { label = "Trauma por Caída", badgeColor = "#d946ef", severityLevels = { Minor = "Esguince", Moderate = "Distensión Severa", Severe = "Fractura por Impacto", Critical = "Politraumatismo" } }
}

-- Configuración de Cámara 3D (para escáner opcional o modo cinemático)
Config.Camera = {
    Fov = 46.0,
    Offset = vector3(0.0, 3.35, -0.02),
    PointOffset = vector3(0.0, 0.0, -0.15),
    Timecycle = "hud_def_blur",
    TimecycleStrength = 0.80,
    TransitionDuration = 700
}
