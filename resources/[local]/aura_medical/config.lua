Config = {}

-- Modo depuración en consola
Config.Debug = false

-- Ajustes de la Cámara Diagnóstica 3D
Config.Camera = {
    Fov = 48.0,
    Offset = vector3(0.0, 1.85, 0.15), -- Posición relativa al frente del ped
    PointOffset = vector3(0.0, 0.0, 0.05), -- Altura de enfoque (tórax)
    Timecycle = "hud_def_blur",
    TimecycleStrength = 0.85,
    TransitionDuration = 700 -- milisegundos de interpolación suave
}

-- Mapeo Anatómico de Huesos para FiveM
Config.Bones = {
    head = {
        label = "Cabeza y Cuello",
        icon = "head",
        boneIds = { 31086, 39317, 25260, 12844 },
        primaryBone = 31086,
        maxHealth = 100
    },
    torso = {
        label = "Tórax y Espina Dorsal",
        icon = "torso",
        boneIds = { 24818, 24817, 24816, 11816, 57597, 0 },
        primaryBone = 24818,
        maxHealth = 100
    },
    left_arm = {
        label = "Brazo Izquierdo",
        icon = "left_arm",
        boneIds = { 45509, 61163, 18905, 60309, 26610, 26611, 26612, 26613, 26614 },
        primaryBone = 18905,
        maxHealth = 100
    },
    right_arm = {
        label = "Brazo Derecho",
        icon = "right_arm",
        boneIds = { 40269, 28252, 61007, 57005, 58866, 58867, 58868, 58869, 58870 },
        primaryBone = 61007,
        maxHealth = 100
    },
    left_leg = {
        label = "Pierna Izquierda",
        icon = "left_leg",
        boneIds = { 58271, 63931, 20781, 14201, 23639 },
        primaryBone = 63931,
        maxHealth = 100
    },
    right_leg = {
        label = "Pierna Derecha",
        icon = "right_leg",
        boneIds = { 51826, 36864, 52301, 35502, 6442 },
        primaryBone = 36864,
        maxHealth = 100
    }
}

-- Tipos de Daño y Clasificación Clínica
Config.DamageTypes = {
    Bullet = {
        label = "Impacto Balístico",
        description = "Perforación por proyectil de arma de fuego con cavitación tisular.",
        badgeColor = "#ff0055",
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
        badgeColor = "#ff3366",
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
        badgeColor = "#ff7700",
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
        badgeColor = "#9900ff",
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
