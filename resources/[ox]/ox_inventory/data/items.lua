return {
	['testburger'] = {
		label = 'Hamburguesa Gourmet',
		weight = 220,
		degrade = 60,
		description = 'Hamburguesa especial elaborada con carne de primera y vegetales frescos.',
		client = {
			image = 'burger_chicken.png',
			status = { hunger = 200000 },
			anim = 'eating',
			prop = 'burger',
			usetime = 2500,
			export = 'ox_inventory_examples.testburger'
		},
		server = {
			export = 'ox_inventory_examples.testburger',
			test = 'what an amazingly delicious burger, amirite?'
		},
		buttons = {
			{
				label = 'Morder',
				action = function(slot)
					print('Has mordido la hamburguesa')
				end
			}
		},
		consume = 0.3
	},

	['bandage'] = {
		label = 'Vendaje Médico',
		weight = 115,
		description = 'Venda elástica esterilizada para curar heridas leves y contener hemorragias.',
		client = {
			anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 },
			prop = { model = `prop_rolled_sock_02`, pos = vec3(-0.14, -0.14, -0.08), rot = vec3(-50.0, -50.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 2500,
			notification = 'Te has aplicado un vendaje de primeros auxilios'
		}
	},

	['black_money'] = {
		label = 'Dinero Negro',
		weight = 0,
		stack = true,
		close = true,
		description = 'Fajos de billetes no declarados procedentes de actividades ilegales.',
	},

	['burger'] = {
		label = 'Hamburguesa Clásica',
		weight = 220,
		description = 'Deliciosa hamburguesa con queso y salsa. Sacia el apetito y recupera energía.',
		client = {
			anim = 'eating',
			prop = 'burger',
			usetime = 2500,
			notification = 'Has comido una deliciosa hamburguesa'
		},
		server = {
			export = 'aura_status.consumeItem'
		}
	},

	['sprunk'] = {
		label = 'Sprunk',
		weight = 350,
		description = 'Lata de refresco carbonatado de lima-limón con electrolitos. Calma la sed.',
		client = {
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_ld_can_01`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
			usetime = 2500,
			notification = 'Has bebido una refrescante lata de Sprunk'
		},
		server = {
			export = 'aura_status.consumeItem'
		}
	},

	['cola'] = {
		label = 'eCola',
		weight = 350,
		description = 'Famoso refresco de cola con cafeína. Ideal para recargar energía e hidratarse.',
		client = {
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_ecola_can`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
			usetime = 2500,
			notification = 'Has bebido una refrescante lata de eCola'
		},
		server = {
			export = 'aura_status.consumeItem'
		}
	},

	['water'] = {
		label = 'Botella de Agua',
		weight = 500,
		description = 'Botella de agua mineral pura de manantial. Hidrata por completo.',
		client = {
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_ld_flow_bottle`, pos = vec3(0.03, 0.03, 0.02), rot = vec3(0.0, 0.0, -1.5) },
			usetime = 2500,
			cancel = true,
			notification = 'Has bebido agua mineral'
		},
		server = {
			export = 'aura_status.consumeItem'
		}
	},

	['parachute'] = {
		label = 'Paracaídas',
		weight = 8000,
		stack = false,
		description = 'Equipo de paracaidismo deportivo de alta resistencia para saltos desde aeronaves o alturas.',
		client = {
			anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
			usetime = 1500
		}
	},

	['garbage'] = {
		label = 'Bolsa de Basura',
		weight = 100,
		description = 'Desechos y residuos orgánicos e inorgánicos sin valor comercial.',
	},

	['paperbag'] = {
		label = 'Bolsa de Papel',
		weight = 1,
		stack = false,
		close = false,
		consume = 0,
		description = 'Bolsa de papel kraft biodegradable para envolver compras de tienda.',
	},

	['identification'] = {
		label = 'DNI (Documento de Identidad)',
		weight = 10,
		description = 'Documento oficial con tus datos biométricos y personales acreditados por el Estado.',
		client = {
			image = 'card_id.png'
		}
	},

	['panties'] = {
		label = 'Prenda Íntima',
		weight = 10,
		consume = 0,
		description = 'Ropa interior femenina de seda con acabados de diseño.',
		client = {
			status = { thirst = -100000, stress = -25000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_cs_panties_02`, pos = vec3(0.03, 0.0, 0.02), rot = vec3(0.0, -13.5, -1.5) },
			usetime = 2500,
		}
	},

	['lockpick'] = {
		label = 'Ganzúa de Cerrajero',
		weight = 160,
		description = 'Instrumento metálico fino para manipular bombines de cerraduras y puertas mecánicas.',
	},

	['phone'] = {
		label = 'Teléfono Móvil',
		weight = 190,
		stack = false,
		consume = 0,
		description = 'Smartphone de última generación con mensajería, llamadas, banca online y GPS.',
		client = {
			add = function(total)
				if total > 0 then
					pcall(function() return exports.npwd:setPhoneDisabled(false) end)
				end
			end,

			remove = function(total)
				if total < 1 then
					pcall(function() return exports.npwd:setPhoneDisabled(true) end)
				end
			end
		}
	},

	['money'] = {
		label = 'Efectivo',
		weight = 0,
		stack = true,
		close = true,
		description = 'Dólares estadounidenses en billetes de curso legal en circulación.',
	},

	['cash'] = {
		label = 'Efectivo',
		weight = 0,
		stack = true,
		close = true,
		description = 'Dólares estadounidenses en billetes de curso legal en circulación.',
	},

	['mustard'] = {
		label = 'Bote de Mostaza',
		weight = 500,
		description = 'Envase de mostaza picante tradicional de Los Santos.',
		client = {
			status = { hunger = 25000, thirst = 25000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_food_mustard`, pos = vec3(0.01, 0.0, -0.07), rot = vec3(1.0, 1.0, -1.5) },
			usetime = 2500,
			notification = 'Has probado un poco de mostaza'
		}
	},

	['radio'] = {
		label = 'Radio Walkie-Talkie',
		weight = 1000,
		stack = false,
		allowArmed = true,
		description = 'Transmisor portátil de radiofrecuencia para comunicarse por frecuencias abiertas y encriptadas.',
	},

	['armour'] = {
		label = 'Chaleco de Kevlar',
		weight = 3000,
		stack = false,
		description = 'Blindaje balístico ligero de fibra de aramida que absorbe impactos de bala.',
		client = {
			anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
			usetime = 3500
		}
	},

	['armor'] = {
		label = 'Chaleco Balístico',
		weight = 3000,
		stack = false,
		description = 'Blindaje balístico ligero de fibra de aramida que absorbe impactos de bala.',
		client = {
			anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
			usetime = 3500
		}
	},

	['police_badge'] = {
		label = 'Placa Policial LSPD',
		weight = 100,
		stack = false,
		description = 'Insignia y placa reglamentaria de identificación oficial de la Policía de Los Santos (LSPD). Contiene el número de placa y titular.',
		client = {
			anim = { dict = 'missfam4', clip = 'base' },
			usetime = 1500
		}
	},

	['handcuffs'] = {
		label = 'Esposas Reglamentarias',
		weight = 250,
		stack = true,
		description = 'Grilletes dobles de acero inoxidable con llave de seguridad para inmovilización de sospechosos.',
	},

	['bodycam'] = {
		label = 'Cámara Corporal Axon',
		weight = 150,
		stack = false,
		description = 'Dispositivo de grabación audiovisual táctico de alta definición con transmisión en tiempo real.',
	},

	['spikestrip'] = {
		label = 'Banda de Clavos Portátil',
		weight = 4000,
		stack = true,
		description = 'Dispositivo táctico desplegable con púas huecas de desinflado rápido para detención de vehículos en persecución.',
	},

	['radio'] = {
		label = 'Radio Walkie-Talkie',
		weight = 400,
		stack = false,
		description = 'Transmisor portátil de radiofrecuencia para comunicarse por frecuencias abiertas y encriptadas.',
	},

	['medikit'] = {
		label = 'Botiquín Táctico IFAK',
		weight = 800,
		stack = false,
		description = 'Kit médico individual de primeros auxilios y trauma para emergencias tácticas.',
		client = {
			anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 },
			usetime = 3500
		}
	},

	['clothing'] = {
		label = 'Prendas de Ropa',
		weight = 500,
		consume = 0,
		description = 'Conjunto textil de vestimenta casual o de trabajo.',
	},

	['mastercard'] = {
		label = 'Tarjeta Fleeca Bank',
		stack = false,
		weight = 10,
		description = 'Tarjeta bancaria con chip EMV asociada a tu cuenta bancaria personal.',
		client = {
			image = 'card_bank.png'
		}
	},

	['credit_card'] = {
		label = 'Tarjeta de Crédito',
		stack = false,
		weight = 5,
		description = 'Tarjeta de crédito física de alta seguridad del Banco Central de Aura. Úsala en cualquier cajero ATM.',
		client = {
			image = 'card_bank.png'
		}
	},

	['scrapmetal'] = {
		label = 'Chatarra de Metal',
		weight = 80,
		description = 'Fragmentos de hierro y acero reciclable para uso en herrería, mecánica o artesanía.',
	},

	['beer'] = {
		label = 'Cerveza Pißwasser',
		weight = 330,
		description = 'Botellín de cerveza rubia bien fría. Calma la sed y aporta un toque de euforia.',
		client = {
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_amb_beer_bottle`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
			usetime = 2500,
			notification = 'Has bebido una cerveza Pißwasser bien fría'
		},
		server = {
			export = 'aura_status.consumeItem'
		}
	},

	['whiskey'] = {
		label = 'Whisky Richards',
		weight = 250,
		description = 'Vaso de whisky de malta con hielo servido en copa corta.',
		client = {
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_drink_whisky`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
			usetime = 2500,
			notification = 'Has bebido un trago de whisky añejo'
		},
		server = {
			export = 'aura_status.consumeItem'
		}
	},

	['tequila_shot'] = {
		label = 'Chupito de Tequila',
		weight = 100,
		description = 'Chupito de tequila dorado mexicano de alta graduación con limón y sal.',
		client = {
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_tequila_shot`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
			usetime = 2000,
			notification = 'Has tomado un chupito de Tequila de golpe'
		},
		server = {
			export = 'aura_status.consumeItem'
		}
	},

	['cocktail'] = {
		label = 'Cóctel Tropical',
		weight = 300,
		description = 'Cóctel refrescante de frutas con licor elaborado por el barman.',
		client = {
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_cocktail_glass`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
			usetime = 2500,
			notification = 'Has disfrutado de un cóctel dulce y refrescante'
		},
		server = {
			export = 'aura_status.consumeItem'
		}
	},

	['chips'] = {
		label = 'Patatas Fritas',
		weight = 150,
		description = 'Bolsa de patatas fritas crujientes con sal marina.',
		client = {
			anim = 'eating',
			prop = 'burger',
			usetime = 2000,
			notification = 'Has comido unas patatas fritas crujientes'
		},
		server = {
			export = 'aura_status.consumeItem'
		}
	},

	['sandwich'] = {
		label = 'Sándwich Tostado',
		weight = 200,
		description = 'Sándwich mixto recién tostado de jamón y queso fundido.',
		client = {
			anim = 'eating',
			prop = 'burger',
			usetime = 2500,
			notification = 'Has comido un delicioso sándwich tostado'
		},
		server = {
			export = 'aura_status.consumeItem'
		}
	},

	['coffee'] = {
		label = 'Café Expreso',
		weight = 150,
		description = 'Taza de café solo caliente recién molido. Activa los sentidos y despeja la mente.',
		client = {
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_fib_coffee`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
			usetime = 2500,
			notification = 'Has bebido un café aromático y caliente'
		},
		server = {
			export = 'aura_status.consumeItem'
		}
	},

	-- ============================================================================
	-- EQUIPAMIENTO POLICIAL Y EMERGENCIAS (LSPD / BCSO)
	-- ============================================================================
	['handcuffs'] = {
		label = 'Esposas Reglamentarias',
		weight = 250,
		stack = true,
		close = true,
		description = 'Grilletes metálicos de alta resistencia con doble trinquete para la custodia de sospechosos.',
		client = {
			image = 'WEAPON_HANDCUFFS.png'
		}
	},

	['armor'] = {
		label = 'Chaleco Balístico',
		weight = 3000,
		stack = false,
		description = 'Blindaje balístico ligero de fibra de aramida que absorbe impactos de bala.',
		client = {
			image = 'armour.png',
			anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
			usetime = 3500,
			notification = 'Te has colocado el chaleco balístico reglamentario'
		}
	},

	['police_badge'] = {
		label = 'Placa Policial LSPD',
		weight = 50,
		stack = false,
		description = 'Insignia y credencial oficial metálica del Departamento de Policía.',
		client = {
			image = 'card_id.png'
		}
	},

	['bodycam'] = {
		label = 'Cámara Corporal Axon',
		weight = 180,
		stack = false,
		description = 'Cámara corporal táctica de alta definición para el registro de intervenciones policiales.',
		client = {
			image = 'usb_black.png'
		}
	},

	['medikit'] = {
		label = 'Botiquín Táctico IFAK',
		weight = 1000,
		description = 'Kit individual de primeros auxilios táctico con gasas hemostáticas y vendajes compresivos.',
		client = {
			image = 'medikit.png',
			anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 },
			usetime = 4000,
			notification = 'Has utilizado un botiquín táctico de primeros auxilios'
		}
	},

	['spikestrip'] = {
		label = 'Banda de Clavos Portátil',
		weight = 3500,
		stack = true,
		description = 'Dispositivo policial de púas de acero para desinflar neumáticos durante persecuciones.',
		client = {
			image = 'scrapmetal.png'
		}
	},

	['evidence_bag'] = {
		label = 'Bolsa de Evidencias Forense',
		weight = 20,
		stack = true,
		description = 'Bolsa estéril de polietileno precintable para custodia y análisis de pruebas forenses.',
		client = {
			image = 'paperbag.png'
		}
	},

	['breathalyzer'] = {
		label = 'Alcoholímetro Digital',
		weight = 200,
		stack = false,
		description = 'Dispositivo de precisión para medir el nivel de alcohol en aire espirado.',
		client = {
			image = 'phone.png'
		}
	}
}
