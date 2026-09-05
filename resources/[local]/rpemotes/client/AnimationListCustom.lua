-- AURARP - EXTENSIVE ROLEPLAY ANIMATION PACK
-- Auto-loaded seamlessly into rpemotes backend

local CustomDP = {}

CustomDP.Expressions = {}
CustomDP.Walks = {}
CustomDP.Shared = {}
CustomDP.Dances = {}
CustomDP.AnimalEmotes = {}
CustomDP.Exits = {}
CustomDP.Emotes = {}
CustomDP.PropEmotes = {}

CustomDP.Emotes['cop'] = {
    'amb@world_human_cop_idles@male@idle_b',
    'idle_e',
    'Policía - Manos al Cinturón',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['cop2'] = {
    'amb@world_human_cop_idles@female@idle_b',
    'idle_d',
    'Policía 2 - Relajado',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['cop3'] = {
    'amb@world_human_cop_idles@male@idle_a',
    'idle_a',
    'Policía 3 - Firme',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['holster'] = {
    'move_m@intimidation@cop@unarmed',
    'idle',
    'Funda - Mano en Pistola',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['holster2'] = {
    'reaction@intimidation@cop@unarmed',
    'intro',
    'Funda 2 - Alerta',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['investigate'] = {
    'amb@code_human_police_investigate@idle_a',
    'idle_b',
    'Investigar - Inspeccionar Escena',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['investigate2'] = {
    'amb@code_human_police_investigate@idle_b',
    'idle_d',
    'Investigar 2 - Linterna al Suelo',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['traffic'] = {
    'amb@world_human_car_park_attendant@male@idle_a',
    'idle_a',
    'Tráfico - Dirigir Coches',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['traffic2'] = {
    'amb@world_human_car_park_attendant@male@idle_b',
    'idle_d',
    'Tráfico 2 - Alto Vehículo',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['cuff'] = {
    'mp_arresting',
    'a_uncuff',
    'Esposar - Poner Grilletes',
    AnimationOptions = { EmoteLoop = false, EmoteDuration = 3000 }
}

CustomDP.Emotes['cuffed'] = {
    'mp_arresting',
    'idle',
    'Esposado - Manos a la Espalda',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true, EmoteStuck = false }
}

CustomDP.Emotes['cuffed2'] = {
    'anim@move_m@prisoner_cuffed',
    'idle',
    'Esposado 2 - Manos Delante',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['uncuff'] = {
    'mp_arresting',
    'a_uncuff',
    'Desesposar - Quitar Grilletes',
    AnimationOptions = { EmoteLoop = false, EmoteDuration = 3000 }
}

CustomDP.Emotes['search'] = {
    'anim@heists@heist_safehouse_intro_prep_2',
    'base_sit_idle',
    'Cachear - Registro Corporal',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['search2'] = {
    'missexile3',
    'ex03_dingy_search_case_a_michael',
    'Registrar 2 - Buscar Pistas',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['cpr'] = {
    'mini@cpr@char_a@cpr_str',
    'cpr_pumpchest',
    'RCP - Masaje Cardíaco',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['cpr2'] = {
    'mini@cpr@char_a@cpr_def',
    'cpr_intro',
    'RCP 2 - Evaluar Víctima',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['cpr3'] = {
    'mini@cpr@char_b@cpr_str',
    'cpr_pumpchest',
    'RCP 3 - Posición Víctima',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['checkpulse'] = {
    'missheistfbi3b_ig8_2',
    'cpr_loop_paramedic',
    'Pulso - Tomar Constantes',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['bandage'] = {
    'amb@medic@standing@kneel@base',
    'base',
    'Vendar - Cura de Rodillas',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['firstaid'] = {
    'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
    'machinic_loop_mechandplayer',
    'Primeros Auxilios - Curar Herida',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['undercar'] = {
    'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
    'machinic_loop_mechandplayer',
    'Mecánico - Reparar Motor',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['clean'] = {
    'anim@heists@prison_heiststation@cop_reactions',
    'cop_b_idle',
    'Limpiar - Pasar Bayeta',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['pump'] = {
    'timetable@gardener@filling_can',
    'gar_ig_5_filling_can',
    'Gasolinera - Manguera Combustible',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['tire'] = {
    'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
    'machinic_loop_mechandplayer',
    'Neumático - Cambiar Rueda',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['sit'] = {
    'anim@heists@fleeca_bank@ig_7_jetski_owner',
    'owner_idle',
    'Sentarse - Piernas Cruzadas',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['sit2'] = {
    'amb@world_human_picnic@male@idle_a',
    'idle_a',
    'Sentarse 2 - Relajado Suelo',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['sit3'] = {
    'amb@world_human_picnic@female@idle_a',
    'idle_b',
    'Sentarse 3 - Casual Suelo',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['sit4'] = {
    'amb@world_human_stupor@male@idle_a',
    'idle_a',
    'Sentarse 4 - Apoyado Suelo',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['sit5'] = {
    'anim@amb@business@bkr@bkr_warehouse@fra_warehouse_security@',
    'security_idle_a',
    'Sentarse 5 - Descanso Suelo',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['sitchair'] = {
    'anim@amb@nightclub@lazlow@hi_podium@',
    'danceidle_hi_11_buttslap_laz',
    'Silla - Sentarse Cómodo',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['sitchair2'] = {
    'timetable@ron@ig_3_couch',
    'base',
    'Silla 2 - Sofá',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['sitchair3'] = {
    'anim@amb@clubhouse@seating@male@variable@',
    'ped_male_seating_var_a_idle_a',
    'Silla 3 - Taburete',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['lay'] = {
    'amb@world_human_sunbathe@male@back@idle_a',
    'idle_a',
    'Tumbarse - Boca Arriba',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['lay2'] = {
    'amb@world_human_sunbathe@female@front@idle_a',
    'idle_a',
    'Tumbarse 2 - Boca Abajo',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['lay3'] = {
    'amb@world_human_bum_slumped@male@laying_down@idle_a',
    'idle_a',
    'Tumbarse 3 - De Lado',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['lay4'] = {
    'random@gang_intimidaton@',
    '001445_01_gang_intimidation_1_female_idle_b',
    'Tumbarse 4 - Relax Suelo',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['lay5'] = {
    'missfbi3_sniping',
    'prone_sniping',
    'Tumbarse 5 - Francotirador',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['lay6'] = {
    'anim@gangops@morgue@table@',
    'body_search',
    'Tumbarse 6 - Camilla',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['sleep'] = {
    'amb@world_human_bum_slumped@male@laying_down@base',
    'base',
    'Dormir - Siesta Suelo',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['sleep2'] = {
    'timetable@tracy@sleep@',
    'idle_c',
    'Dormir 2 - Sueño Profundo',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['sunbathe'] = {
    'amb@world_human_sunbathe@male@back@base',
    'base',
    'Tomar el Sol - Cara al Cielo',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['sunbathe2'] = {
    'amb@world_human_sunbathe@female@front@base',
    'base',
    'Tomar el Sol 2 - Espalda',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['kneel'] = {
    'amb@medic@standing@kneel@base',
    'base',
    'Arrodillarse - Una Rodilla',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['kneel2'] = {
    'random@arrests',
    'kneeling_arrest_idle',
    'Arrodillarse 2 - Dos Rodillas',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['pray'] = {
    'rcmnigel1a_kneeling_crying',
    'base',
    'Rezar - Devoción de Rodillas',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['pray2'] = {
    'anim@heists@heist_safehouse_intro_prep_2',
    'base_sit_idle',
    'Rezar 2 - Plegaria en Silencio',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['meditate'] = {
    'rcmcollect_paperleadinout@',
    'meditiate_idle',
    'Meditar - Flor de Loto',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['yoga'] = {
    'anim@mp_player_intcelebrationfemale@yoga',
    'yoga',
    'Yoga - Postura del Árbol',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['surrender'] = {
    'random@arrests@busted',
    'idle_a',
    'Rendirse - Manos en Cabeza',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['injured'] = {
    'combat@damage@writheidle_c',
    'writhe_idle_g',
    'Herido - Dolor Intenso',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['injured2'] = {
    'combat@damage@writheidle_a',
    'writhe_idle_c',
    'Herido 2 - Quejándose en Suelo',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['dead'] = {
    'dead',
    'dead_a',
    'Muerto - Cuerpo Inerte',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['faint'] = {
    'anim@heists@heist_safehouse_intro_prep_2',
    'base_sit_idle',
    'Desmayo - Pérdida de Conocimiento',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['gangster'] = {
    'move_m@gangster@var_e',
    'idle',
    'Gánster - Postura de Barrio',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['gangster2'] = {
    'move_m@gangster@var_f',
    'idle',
    'Gánster 2 - Actitud Calle',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['gangsign'] = {
    'mp_player_int_gang_sign_a',
    'mp_player_int_gang_sign_a',
    'Seña de Banda - West Coast',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['gangsign2'] = {
    'mp_player_int_gang_sign_b',
    'mp_player_int_gang_sign_b',
    'Seña de Banda 2 - East Coast',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['gangsign3'] = {
    'anim@mp_player_intuppergang_sign_a',
    'idle_a',
    'Seña de Banda 3 - South Side',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['gangsign4'] = {
    'anim@mp_player_intuppergang_sign_b',
    'idle_a',
    'Seña de Banda 4 - North Side',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['rap'] = {
    'anim@mp_player_intcelebrationfemale@dj',
    'dj',
    'Rap - Rimar con Estilo',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['rap2'] = {
    'anim@mp_player_intcelebrationmale@dj',
    'dj',
    'Rap 2 - Flow Callejero',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['squat'] = {
    'anim@amb@nightclub@mini@dance@dance_solo@male@var_a@',
    'med_center_down',
    'Sentadilla - Posición Baja',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['slavsquat'] = {
    'amb@world_human_bum_slumped@male@laying_down@idle_a',
    'idle_a',
    'Sentadilla Rusa - En Cuclillas',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['warmup'] = {
    'anim@mp_player_intcelebrationfemale@shadow_boxing',
    'shadow_boxing',
    'Calentamiento - Guardia de Boxeo',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['shadowbox'] = {
    'anim@mp_player_intcelebrationmale@shadow_boxing',
    'shadow_boxing',
    'Boxeo - Jab Directo',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['pushups'] = {
    'amb@world_human_push_ups@male@base',
    'base',
    'Flexiones - Pecho en Suelo',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['situps'] = {
    'amb@world_human_sit_ups@male@base',
    'base',
    'Abdominales - Entrenamiento Core',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['stretch'] = {
    'anim@mp_player_intcelebrationfemale@stretch',
    'stretch',
    'Estiramiento - Brazos y Hombros',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['stretch2'] = {
    'anim@mp_player_intcelebrationmale@stretch',
    'stretch',
    'Estiramiento 2 - Piernas',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['pullup'] = {
    'anim@mp_player_intcelebrationfemale@chin_ups',
    'chin_ups',
    'Dominadas - Barra de Fuerza',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = true }
}

CustomDP.Emotes['cheer2'] = {
    'anim@mp_player_intcelebrationfemale@cheer',
    'cheer',
    'Celebrar 2 - Salto de Alegría',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['clap2'] = {
    'anim@mp_player_intcelebrationfemale@slow_clap',
    'slow_clap',
    'Aplaudir 2 - Ovación',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['middlefinger'] = {
    'anim@mp_player_intupperfinger',
    'idle_a_fp',
    'Peineta - Corte de Manga Doble',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['fuckyou'] = {
    'mp_player_intfinger',
    'mp_player_int_finger',
    'Dedo - Peineta Directa',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['peace'] = {
    'anim@mp_player_intcelebrationfemale@peace',
    'peace',
    'Paz - Dos Dedos Arriba',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['salute'] = {
    'anim@mp_player_intincarthumbs_upbodhi@ps@',
    'enter',
    'Saludo Militar - A la Orden',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['salute2'] = {
    'anim@mp_player_intcelebrationfemale@salute',
    'salute',
    'Saludo Militar 2 - Respeto',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['shrug'] = {
    'anim@mp_player_intcelebrationfemale@shrug',
    'shrug',
    'Encogerse de Hombros - Ni Idea',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['facepalm'] = {
    'anim@mp_player_intcelebrationfemale@face_palm',
    'face_palm',
    'Facepalm - Qué Desastre',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['facepalm2'] = {
    'anim@mp_player_intcelebrationmale@face_palm',
    'face_palm',
    'Facepalm 2 - No me lo Creo',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['wave'] = {
    'anim@mp_player_intcelebrationfemale@wave',
    'wave',
    'Saludar - Mano Amigable',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['wave2'] = {
    'anim@mp_player_intcelebrationmale@wave',
    'wave',
    'Saludar 2 - Hey Qué Tal',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['wave3'] = {
    'friends@frj@ig_1',
    'wave_a',
    'Saludar 3 - Saludo Efusivo',
    AnimationOptions = { EmoteMoving = true, EmoteLoop = true }
}

CustomDP.Emotes['hug'] = {
    'mp_ped_interaction',
    'hugs_guy_a',
    'Abrazo - Saludo Cálido',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = false, EmoteDuration = 3500 }
}

CustomDP.Emotes['brohug'] = {
    'mp_ped_interaction',
    'hugs_guy_b',
    'Abrazo Colega - Saludo de Hermanos',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = false, EmoteDuration = 3500 }
}

CustomDP.Emotes['handshake'] = {
    'mp_ped_interaction',
    'handshake_guy_a',
    'Apretón de Manos - Trato Hecho',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = false, EmoteDuration = 3000 }
}

CustomDP.Emotes['fistbump'] = {
    'mp_ped_interaction',
    'kisses_guy_a',
    'Chocar Puño - Respeto',
    AnimationOptions = { EmoteMoving = false, EmoteLoop = false, EmoteDuration = 3000 }
}

CustomDP.PropEmotes['badge'] = {
    'paper_1_rcm_alt1-9',
    'player_one_dual-9',
    'Placa Policía - Enseñar ID',
    AnimationOptions = { Prop = 'prop_fib_badge', PropBone = 28422, PropPlacement = {0.06,0.01,-0.03,130.0,-70.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['copbadge'] = {
    'paper_1_rcm_alt1-9',
    'player_one_dual-9',
    'Placa LSPD - Agente Policial',
    AnimationOptions = { Prop = 'prop_cop_badge', PropBone = 28422, PropPlacement = {0.06,0.01,-0.03,130.0,-70.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['badge2'] = {
    'paper_1_rcm_alt1-9',
    'player_one_dual-9',
    'Placa Detective - Insignia Dorada',
    AnimationOptions = { Prop = 'prop_lspd_badge', PropBone = 28422, PropPlacement = {0.06,0.01,-0.03,130.0,-70.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['radio2'] = {
    'random@arrests',
    'generic_radio_chatter',
    'Radio 2 - Comunicador de Hombro',
    AnimationOptions = { Prop = 'prop_cs_hand_radio', PropBone = 60309, PropPlacement = {0.07,0.03,-0.02,90.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['ticket'] = {
    'amb@medic@standing@timeofdeath@base',
    'base',
    'Multa - Escribir Sanción',
    AnimationOptions = { Prop = 'p_cs_clipboard', PropBone = 60309, PropPlacement = {0.1,0.02,0.05,10.0,-20.0,20.0}, SecondProp = 'prop_pencil_01', SecondPropBone = 57005, SecondPropPlacement = {0.12,0.05,-0.01,0.0,0.0,-90.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['radar'] = {
    'amb@world_human_security_shine_torch@male@base',
    'base',
    'Radar - Pistola de Velocidad',
    AnimationOptions = { Prop = 'prop_speed_gun', PropBone = 57005, PropPlacement = {0.12,0.03,-0.03,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['baton'] = {
    'amb@world_human_security_shine_torch@male@base',
    'base',
    'Porra - Defensa Policial',
    AnimationOptions = { Prop = 'prop_nightstick_01', PropBone = 57005, PropPlacement = {0.1,0.0,-0.02,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['riotshield'] = {
    'amb@world_human_security_shine_torch@male@base',
    'base',
    'Escudo - Antidisturbios',
    AnimationOptions = { Prop = 'prop_riot_shield', PropBone = 60309, PropPlacement = {0.1,0.05,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['megaph'] = {
    'amb@world_human_mobile_film_shocking@male@base',
    'base',
    'Megáfono - Aviso por Megafonía',
    AnimationOptions = { Prop = 'prop_megaphone_01', PropBone = 28422, PropPlacement = {0.0,0.0,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['breathalyzer'] = {
    'amb@world_human_drinking@coffee@male@base',
    'base',
    'Alcoholímetro - Test de Alcoholemia',
    AnimationOptions = { Prop = 'prop_ecg', PropBone = 28422, PropPlacement = {0.0,0.0,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['defib'] = {
    'amb@medic@standing@kneel@base',
    'base',
    'Desfibrilador - Electrodos RCP',
    AnimationOptions = { Prop = 'prop_ld_health_pack', PropBone = 28422, PropPlacement = {0.0,0.0,0.0,0.0,0.0,0.0}, EmoteMoving = false, EmoteLoop = true }
}

CustomDP.PropEmotes['syringe'] = {
    'amb@world_human_smoking@male@male_a@base',
    'base',
    'Jeringuilla - Vacuna / Inyección',
    AnimationOptions = { Prop = 'prop_syringe_01', PropBone = 28422, PropPlacement = {0.0,0.0,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['pill'] = {
    'mp_suicide',
    'pill',
    'Pastilla - Tomar Medicación',
    AnimationOptions = { Prop = 'prop_cs_pills', PropBone = 28422, PropPlacement = {0.0,0.0,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = false, EmoteDuration = 3000 }
}

CustomDP.PropEmotes['medicbag'] = {
    'amb@world_human_stand_guard@male@base',
    'base',
    'Maletín Médico - Kit Sanitario',
    AnimationOptions = { Prop = 'prop_med_bag_01', PropBone = 57005, PropPlacement = {0.4,0.0,0.0,0.0,270.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['wrench'] = {
    'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
    'machinic_loop_mechandplayer',
    'Llave Inglesa - Apretar Tuerca',
    AnimationOptions = { Prop = 'prop_tool_wrench', PropBone = 57005, PropPlacement = {0.12,0.03,-0.02,0.0,0.0,0.0}, EmoteMoving = false, EmoteLoop = true }
}

CustomDP.PropEmotes['wrench2'] = {
    'amb@world_human_hammering@male@base',
    'base',
    'Llave Inglesa 2 - Ajuste de Pie',
    AnimationOptions = { Prop = 'prop_tool_wrench', PropBone = 57005, PropPlacement = {0.12,0.03,-0.02,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['sponge'] = {
    'anim@heists@prison_heiststation@cop_reactions',
    'cop_b_idle',
    'Esponja - Lavado de Coche',
    AnimationOptions = { Prop = 'prop_sponge_01', PropBone = 28422, PropPlacement = {0.0,0.0,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['blowtorch'] = {
    'amb@world_human_welding@male@base',
    'base',
    'Soplete - Soldadura y Corte',
    AnimationOptions = { Prop = 'prop_tool_blowtorch', PropBone = 57005, PropPlacement = {0.1,0.02,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['chainsaw'] = {
    'amb@world_human_security_shine_torch@male@base',
    'base',
    'Motosierra - Cortar Madera',
    AnimationOptions = { Prop = 'prop_tool_consaw', PropBone = 57005, PropPlacement = {0.15,0.05,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['burger'] = {
    'mp_player_inteat@burger',
    'mp_player_int_eat_burger',
    'Hamburguesa - Comer Burger',
    AnimationOptions = { Prop = 'prop_cs_burger_01', PropBone = 18905, PropPlacement = {0.13,0.05,0.02,-50.0,16.0,60.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['burger2'] = {
    'mp_player_inteat@burger',
    'mp_player_int_eat_burger_fp',
    'Hamburguesa 2 - Gran Mordisco',
    AnimationOptions = { Prop = 'prop_cs_burger_01', PropBone = 18905, PropPlacement = {0.13,0.05,0.02,-50.0,16.0,60.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['pizza'] = {
    'mp_player_inteat@burger',
    'mp_player_int_eat_burger',
    'Caja Pizza - Reparto Pizza',
    AnimationOptions = { Prop = 'prop_pizza_box_02', PropBone = 60309, PropPlacement = {0.2,0.1,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['pizza2'] = {
    'mp_player_inteat@burger',
    'mp_player_int_eat_burger',
    'Porción Pizza - Comer Trozo',
    AnimationOptions = { Prop = 'prop_pizza_slice_01', PropBone = 18905, PropPlacement = {0.12,0.05,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['sandwich'] = {
    'mp_player_inteat@burger',
    'mp_player_int_eat_burger',
    'Sándwich - Comer Bocadillo',
    AnimationOptions = { Prop = 'prop_sandwich_01', PropBone = 18905, PropPlacement = {0.13,0.05,0.02,-50.0,16.0,60.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['donut'] = {
    'mp_player_inteat@burger',
    'mp_player_int_eat_burger',
    'Donut - Glaseado Rosa',
    AnimationOptions = { Prop = 'prop_amb_donut', PropBone = 18905, PropPlacement = {0.13,0.05,0.02,-50.0,16.0,60.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['hotdog'] = {
    'mp_player_inteat@burger',
    'mp_player_int_eat_burger',
    'Perrito Caliente - Mostaza',
    AnimationOptions = { Prop = 'prop_cs_hotdog_01', PropBone = 18905, PropPlacement = {0.13,0.05,0.02,-50.0,16.0,60.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['taco'] = {
    'mp_player_inteat@burger',
    'mp_player_int_eat_burger',
    'Taco - Taco Mexicano',
    AnimationOptions = { Prop = 'prop_taco_01', PropBone = 18905, PropPlacement = {0.13,0.05,0.02,-50.0,16.0,60.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['noodles'] = {
    'mp_player_inteat@burger',
    'mp_player_int_eat_burger',
    'Fideos - Bol de Ramen',
    AnimationOptions = { Prop = 'prop_cs_bowl_01', PropBone = 60309, PropPlacement = {0.1,0.05,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['chips'] = {
    'mp_player_inteat@burger',
    'mp_player_int_eat_burger',
    'Patatas - Bolsa de Snacks',
    AnimationOptions = { Prop = 'prop_crisp_packet_01', PropBone = 18905, PropPlacement = {0.13,0.05,0.02,-50.0,16.0,60.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['chocolate'] = {
    'mp_player_inteat@burger',
    'mp_player_int_eat_burger',
    'Chocolate - Barrita Dulce',
    AnimationOptions = { Prop = 'prop_choc_ego', PropBone = 18905, PropPlacement = {0.13,0.05,0.02,-50.0,16.0,60.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['icecream'] = {
    'mp_player_inteat@burger',
    'mp_player_int_eat_burger',
    'Helado - Cucurucho Vainilla',
    AnimationOptions = { Prop = 'prop_ice_tea', PropBone = 18905, PropPlacement = {0.13,0.05,0.02,-50.0,16.0,60.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['coffee'] = {
    'amb@world_human_drinking@coffee@male@idle_a',
    'idle_c',
    'Café - Taza Caliente',
    AnimationOptions = { Prop = 'prop_fib_coffee', PropBone = 28422, PropPlacement = {0.0,0.0,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['coffee2'] = {
    'amb@world_human_drinking@coffee@male@idle_a',
    'idle_a',
    'Café 2 - Vaso Takeaway',
    AnimationOptions = { Prop = 'p_amb_coffeecup_01', PropBone = 28422, PropPlacement = {0.0,0.0,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['soda'] = {
    'amb@world_human_drinking@coffee@male@idle_a',
    'idle_c',
    'Refresco - Lata eCola',
    AnimationOptions = { Prop = 'prop_ecola_can', PropBone = 28422, PropPlacement = {0.0,0.0,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['water'] = {
    'amb@world_human_drinking@coffee@male@idle_a',
    'idle_c',
    'Agua - Botella Mineral',
    AnimationOptions = { Prop = 'prop_ld_flow_bottle', PropBone = 28422, PropPlacement = {0.0,0.0,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['beer'] = {
    'amb@world_human_drinking@beer@male@idle_a',
    'idle_a',
    'Cerveza - Botellín Frío',
    AnimationOptions = { Prop = 'prop_amb_beer_bottle', PropBone = 28422, PropPlacement = {0.0,0.0,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['wine'] = {
    'amb@world_human_drinking@coffee@male@idle_a',
    'idle_c',
    'Vino - Copa de Tinto',
    AnimationOptions = { Prop = 'prop_wine_glass', PropBone = 28422, PropPlacement = {0.0,0.0,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['whiskey'] = {
    'amb@world_human_drinking@coffee@male@idle_a',
    'idle_c',
    'Whisky - Vaso con Hielo',
    AnimationOptions = { Prop = 'prop_drink_whisky', PropBone = 28422, PropPlacement = {0.0,0.0,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['champagne'] = {
    'amb@world_human_drinking@coffee@male@idle_a',
    'idle_c',
    'Champán - Copa de Fiesta',
    AnimationOptions = { Prop = 'prop_champ_flute', PropBone = 28422, PropPlacement = {0.0,0.0,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['energy'] = {
    'amb@world_human_drinking@coffee@male@idle_a',
    'idle_c',
    'Bebida Energética - Lata Junk',
    AnimationOptions = { Prop = 'prop_energy_drink', PropBone = 28422, PropPlacement = {0.0,0.0,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['smoke'] = {
    'amb@world_human_smoking@male@male_a@idle_a',
    'idle_b',
    'Fumar - Cigarrillo',
    AnimationOptions = { Prop = 'prop_cs_ciggy_01', PropBone = 28422, PropPlacement = {0.0,0.0,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['smoke2'] = {
    'amb@world_human_smoking@male@male_b@idle_a',
    'idle_a',
    'Fumar 2 - Cigarrillo Casual',
    AnimationOptions = { Prop = 'prop_cs_ciggy_01', PropBone = 28422, PropPlacement = {0.0,0.0,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['cigar'] = {
    'amb@world_human_smoking@male@male_a@idle_a',
    'idle_b',
    'Puro - Habano',
    AnimationOptions = { Prop = 'prop_cigar_02', PropBone = 28422, PropPlacement = {0.0,0.0,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['cigar2'] = {
    'amb@world_human_smoking@male@male_b@idle_a',
    'idle_a',
    'Puro 2 - Puro Elegante',
    AnimationOptions = { Prop = 'prop_cigar_01', PropBone = 28422, PropPlacement = {0.0,0.0,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['joint'] = {
    'amb@world_human_smoking_pot@male@idle_a',
    'idle_a',
    'Porro - Hierba Liada',
    AnimationOptions = { Prop = 'p_amb_joint_01', PropBone = 28422, PropPlacement = {0.0,0.0,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['bong'] = {
    'anim@safehouse@bong',
    'bong_stage1',
    'Bong - Pipa de Agua',
    AnimationOptions = { Prop = 'prop_bong_01', PropBone = 18905, PropPlacement = {0.1,-0.25,0.0,95.0,190.0,180.0}, EmoteMoving = false, EmoteLoop = true }
}

CustomDP.PropEmotes['lighter'] = {
    'amb@world_human_smoking@male@male_a@enter',
    'enter',
    'Mechero - Encender Llama',
    AnimationOptions = { Prop = 'p_cs_lighter_01', PropBone = 28422, PropPlacement = {0.0,0.0,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = false, EmoteDuration = 2500 }
}

CustomDP.PropEmotes['call'] = {
    'cellphone@',
    'cellphone_call_listen_base',
    'Llamada - Teléfono al Oído',
    AnimationOptions = { Prop = 'prop_player_phone_01', PropBone = 28422, PropPlacement = {0.0,0.0,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['text'] = {
    'cellphone@',
    'cellphone_text_read_base',
    'Mensaje - Escribir en Móvil',
    AnimationOptions = { Prop = 'prop_player_phone_01', PropBone = 28422, PropPlacement = {0.0,0.0,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['selfie'] = {
    'cellphone@self',
    'selfie_horizontal',
    'Selfie - Foto Frontal',
    AnimationOptions = { Prop = 'prop_player_phone_01', PropBone = 28422, PropPlacement = {0.0,0.0,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['tablet'] = {
    'amb@world_human_seat_wall_tablet@female@base',
    'base',
    'Tablet - Navegar en Pantalla',
    AnimationOptions = { Prop = 'prop_cs_tablet', PropBone = 60309, PropPlacement = {0.03,0.002,-0.0,10.0,160.0,60.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['laptop'] = {
    'anim@heists@prison_heiststation@cop_reactions',
    'cop_b_idle',
    'Portátil - Trabajar en Ordenador',
    AnimationOptions = { Prop = 'prop_laptop_01a', PropBone = 60309, PropPlacement = {0.1,0.05,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['camera'] = {
    'amb@world_human_paparazzi@male@idle_a',
    'idle_a',
    'Cámara - Fotógrafo Réflex',
    AnimationOptions = { Prop = 'prop_pap_camera_01', PropBone = 28422, PropPlacement = {0.0,0.0,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['mic'] = {
    'missheistdocksprep1hold_cellphone',
    'static',
    'Micrófono - Entrevista / Canto',
    AnimationOptions = { Prop = 'p_ing_microphonel_01', PropBone = 60309, PropPlacement = {0.05,0.05,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['clipboard'] = {
    'amb@medic@standing@timeofdeath@base',
    'base',
    'Portapapeles - Notas de Oficina',
    AnimationOptions = { Prop = 'p_cs_clipboard', PropBone = 60309, PropPlacement = {0.1,0.02,0.05,10.0,-20.0,20.0}, SecondProp = 'prop_pencil_01', SecondPropBone = 57005, SecondPropPlacement = {0.12,0.05,-0.01,0.0,0.0,-90.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['readbook'] = {
    'amb@world_human_drinking@coffee@male@idle_a',
    'idle_c',
    'Libro - Lectura de Novela',
    AnimationOptions = { Prop = 'prop_novel_01', PropBone = 60309, PropPlacement = {0.1,0.05,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['briefcase'] = {
    'missheistdocksprep1hold_cellphone',
    'static',
    'Maletín - Cuero Ejecutivo',
    AnimationOptions = { Prop = 'prop_ld_case_01', PropBone = 57005, PropPlacement = {0.1,0.0,0.0,0.0,270.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['briefcase2'] = {
    'missheistdocksprep1hold_cellphone',
    'static',
    'Maletín 2 - Metal Seguridad',
    AnimationOptions = { Prop = 'prop_security_case_01', PropBone = 57005, PropPlacement = {0.1,0.0,0.0,0.0,270.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['dufflebag'] = {
    'missheistdocksprep1hold_cellphone',
    'static',
    'Bolsa de Deporte - Bolsa Atraco',
    AnimationOptions = { Prop = 'p_ld_heist_bag_s_pro_o', PropBone = 57005, PropPlacement = {0.35,0.0,0.0,0.0,270.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['money'] = {
    'mp_player_inteat@burger',
    'mp_player_int_eat_burger',
    'Dinero - Fajo de Billetes',
    AnimationOptions = { Prop = 'prop_anim_cash_pile_01', PropBone = 18905, PropPlacement = {0.13,0.05,0.02,-50.0,16.0,60.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['countmoney'] = {
    'anim@heists@fleeca_bank@drilling',
    'drill_straight_idle',
    'Contar Dinero - Revisar Fajo',
    AnimationOptions = { Prop = 'prop_anim_cash_pile_01', PropBone = 60309, PropPlacement = {0.1,0.0,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['moneybag'] = {
    'missheistdocksprep1hold_cellphone',
    'static',
    'Saco Dinero - Bolsa de Botín',
    AnimationOptions = { Prop = 'prop_money_bag_01', PropBone = 57005, PropPlacement = {0.35,0.0,0.0,0.0,270.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['flowers'] = {
    'amb@world_human_drinking@coffee@male@idle_a',
    'idle_c',
    'Flores - Ramo de Rosas',
    AnimationOptions = { Prop = 'prop_snow_flower_02', PropBone = 60309, PropPlacement = {0.1,0.0,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['carrybox'] = {
    'anim@heists@box_carry@',
    'idle',
    'Caja - Cargar Caja Pesada',
    AnimationOptions = { Prop = 'hei_prop_heist_box', PropBone = 60309, PropPlacement = {0.025,0.08,0.255,-145.0,290.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['package'] = {
    'anim@heists@box_carry@',
    'idle',
    'Paquete - Reparto Mensajería',
    AnimationOptions = { Prop = 'prop_cardbordbox_04a', PropBone = 60309, PropPlacement = {0.025,0.08,0.255,-145.0,290.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['trashbag'] = {
    'missfbi4prepp1',
    '_idle_garbage_man',
    'Basura - Bolsa de Basura',
    AnimationOptions = { Prop = 'hei_prop_heist_binbag', PropBone = 57005, PropPlacement = {0.12,0.0,0.0,0.0,270.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

CustomDP.PropEmotes['dumbbell'] = {
    'amb@world_human_muscle_weights@male@barbell@base',
    'base',
    'Mancuerna - Curl de Bíceps',
    AnimationOptions = { Prop = 'prop_curl_bar_01', PropBone = 28422, PropPlacement = {0.0,0.0,0.0,0.0,0.0,0.0}, EmoteMoving = true, EmoteLoop = true }
}

-----------------------------------------------------------------------------------------
--| Inyectar animaciones automáticamente en las tablas principales de rpemotes
-----------------------------------------------------------------------------------------

for arrayName, array in pairs(CustomDP) do
    if RP[arrayName] then
        for emoteName, emoteData in pairs(array) do
            RP[arrayName][emoteName] = emoteData
        end
    end
    CustomDP[arrayName] = nil
end
CustomDP = nil
