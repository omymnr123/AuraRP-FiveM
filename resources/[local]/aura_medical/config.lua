Config = {}

-- Modo depuración en consola
Config.Debug = false

-- Ajustes de la Cámara Diagnóstica 3D (Vista Completa de Cuerpo Entero desde Cabeza hasta Pies)
Config.Camera = {
    Fov = 46.0,
    Offset = vector3(0.0, 3.35, -0.02), -- Distancia frontal óptima para encuadre completo de cuerpo entero
    PointOffset = vector3(0.0, 0.0, -0.15), -- Punto de enfoque central (pelvis / torso)
    Timecycle = "hud_def_blur",
    TimecycleStrength = 0.80,
    TransitionDuration = 700 -- milisegundos de interpolación suave
}

-- Mapeo Anatómico Completo de Huesos para FiveM (10 Regiones: Cabeza, Torso, Brazos, Manos, Piernas, Pies)
Config.Bones = {
    head = {
        label = "Cabeza y Cuello",
        icon = "head",
        boneIds = { 31086, 39317, 25260, 12844 },
        primaryBone = 31086, -- SKEL_Head
        side = "head",
        maxHealth = 100
    },
    torso = {
        label = "Tórax y Espina Dorsal",
        icon = "torso",
        boneIds = { 24818, 24817, 24816, 11816, 57597, 23553, 0 },
        primaryBone = 24818, -- SKEL_Spine3 (Centro del pecho / tórax)
        side = "torso",
        maxHealth = 100
    },
    right_arm = {
        label = "Brazo Derecho",
        icon = "right_arm",
        boneIds = { 40269, 28252 },
        primaryBone = 28252, -- SKEL_R_Forearm (Brazo derecho anatómico -> izquierda en pantalla)
        side = "left",
        maxHealth = 100
    },
    left_arm = {
        label = "Brazo Izquierdo",
        icon = "left_arm",
        boneIds = { 45509, 61163 },
        primaryBone = 61163, -- SKEL_L_Forearm (Brazo izquierdo anatómico -> derecha en pantalla)
        side = "right",
        maxHealth = 100
    },
    right_hand = {
        label = "Mano Derecha",
        icon = "right_hand",
        boneIds = { 57005, 58866, 58867, 58868, 58869, 58870 },
        primaryBone = 57005, -- SKEL_R_Hand
        side = "left",
        maxHealth = 100
    },
    left_hand = {
        label = "Mano Izquierda",
        icon = "left_hand",
        boneIds = { 18905, 26610, 26611, 26612, 26613, 26614, 60309 },
        primaryBone = 18905, -- SKEL_L_Hand
        side = "right",
        maxHealth = 100
    },
    right_leg = {
        label = "Pierna Derecha",
        icon = "right_leg",
        boneIds = { 51826, 36864 },
        primaryBone = 36864, -- SKEL_R_Calf (Pierna derecha anatómica -> izquierda en pantalla)
        side = "left",
        maxHealth = 100
    },
    left_leg = {
        label = "Pierna Izquierda",
        icon = "left_leg",
        boneIds = { 58271, 63931 },
        primaryBone = 63931, -- SKEL_L_Calf (Pierna izquierda anatómica -> derecha en pantalla)
        side = "right",
        maxHealth = 100
    },
    right_foot = {
        label = "Pie Derecho",
        icon = "right_foot",
        boneIds = { 52301, 35502, 6442 },
        primaryBone = 52301, -- SKEL_R_Foot
        side = "left",
        maxHealth = 100
    },
    left_foot = {
        label = "Pie Izquierdo",
        icon = "left_foot",
        boneIds = { 14201, 20781, 23639 },
        primaryBone = 14201, -- SKEL_L_Foot / SKEL_L_Toe0
        side = "right",
        maxHealth = 100
    }
}

-- Tipos de Daño y Clasificación Clínica
Config.DamageTypes = {
    Bullet = {
        label = "Impacto Balístico",
        description = "Perforación por proyectil de arma de fuego con cavitación tisular.",
        badgeColor = "#ff007f",
        severityLevels = {
            Minor = "Rozadura Balística Leve",
            Moderate = "Herida Perforante Balística",
            Severe = "Impacto Balístico con Hemorragia Interna",
            Critical = "Trauma Balístico Masivo / Destrozo Óseo"
        }
    },
    Cut = {
        label = "Laceración / Corte",
        description = "Herida incisa punzocortante con compromiso de dermis y vasos sanguíneos.",
        badgeColor = "#ff00a0",
        severityLevels = {
            Minor = "Corte Superficial",
            Moderate = "Laceración Profunda",
            Severe = "Herida Incisa con Daño Muscular",
            Critical = "Sección Vascular / Hemorragia Severa"
        }
    },
    Blunt = {
        label = "Contusión / Traumatismo",
        description = "Traumatismo por objeto contundente o golpe físico de alto impacto.",
        badgeColor = "#ffaa00",
        severityLevels = {
            Minor = "Hematoma Subcutáneo",
            Moderate = "Fisura Ósea / Contusión Fuerte",
            Severe = "Fractura Cerrada Desplazada",
            Critical = "Aplastamiento / Fractura Conminuta"
        }
    },
    Burn = {
        label = "Quemadura Térmica",
        description = "Lesión dérmica ocasionada por alta temperatura, llama abierta o deflagración.",
        badgeColor = "#ff5500",
        severityLevels = {
            Minor = "Quemadura de 1er Grado (Eritema)",
            Moderate = "Quemadura de 2º Grado (Flictenas)",
            Severe = "Quemadura de 3er Grado (Necrosis dérmica)",
            Critical = "Quemadura Crítica Extensa"
        }
    },
    Fall = {
        label = "Trauma por Caída / Colisión",
        description = "Desaceleración violenta por impacto contra superficies o colisión vehicular.",
        badgeColor = "#d946ef",
        severityLevels = {
            Minor = "Esguince / Golpe Articular",
            Moderate = "Distensión Ligamentosa Severa",
            Severe = "Fractura por Compresión / Impacto",
            Critical = "Politraumatismo Grave por Desaceleración"
        }
    }
}

-- Tecla rápida opcional para abrir escáner (o usar botón Salud de ox_inventory)
Config.Keybind = {
    Enabled = true,
    Key = 'F6',
    Description = 'Abrir Escáner Diagnóstico de Salud'
}
