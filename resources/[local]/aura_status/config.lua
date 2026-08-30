Config = {}

-- ==========================================
-- CONFIGURACIÓN DE METABOLISMO (SÚPER INTUITIVA)
-- ==========================================
-- Aquí defines exactamente cuántos MINUTOS REALES tarda un jugador 
-- en morir de hambre o sed si no come ni bebe nada (bajando del 100% al 0%).
Config.MinutesToStarve = 120 -- Tarda 120 minutos (2 horas) en llegar a 0 de Hambre
Config.MinutesToDehydrate = 90 -- Tarda 90 minutos (1 hora y media) en llegar a 0 de Sed

-- Ciclo interno (cada cuántos segundos se actualiza internamente). 
-- No afecta la velocidad total, solo qué tan fluido baja. Recomendado: 10 a 20.
Config.MetabolismUpdateSeconds = 10 

-- Intervalo en milisegundos para enviar datos al HUD.
Config.HudSyncTickRate = 500

Config.StarvationDamage = 2 -- Daño aplicado cuando el hambre llega a 0
Config.DehydrationDamage = 3 -- Daño aplicado cuando la sed llega a 0

Config.MaxHealth = 200 -- Vida máxima estándar en GTA V para peds multijugador
Config.MaxArmor = 100 -- Armadura máxima

Config.Consumables = {
    ['burger'] = { type = 'hunger', amount = 30, anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger' }, prop = 'prop_cs_burger_01' },
    ['water'] = { type = 'thirst', amount = 40, anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' }, prop = 'prop_ld_flow_bottle' },
    ['sprunk'] = { type = 'thirst', amount = 35, anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' }, prop = 'prop_ld_can_01' },
    ['cola'] = { type = 'thirst', amount = 35, anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' }, prop = 'prop_ecola_can' },
}
