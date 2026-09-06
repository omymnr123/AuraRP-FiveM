-- ============================================================================
-- AURARP SEASONS & SURVIVAL CONTROL HUB CONTROLLER (CLIENT)
-- ============================================================================

local isPanelOpen = false
local isDebugOverlayActive = false

local function GetFullTelemetryPayload()
    local season = exports['aura_seasons']:GetCurrentSeason() or 'spring'
    local weather = exports['aura_seasons']:GetCurrentWeather() or 'CLEAR'
    local ambientTemp = exports['aura_seasons']:GetAmbientTemperature() or 21.0
    local coreTemp = exports['aura_seasons']:GetCoreTemperature() or 37.0
    local insulation = exports['aura_seasons']:GetInsulation() or 0.0
    local isSheltered = exports['aura_seasons']:IsInsideShelter() or false
    local breakdown = exports['aura_seasons']:GetInsulationBreakdown() or {}
    local buffs = exports['aura_seasons']:GetThermalBuffs() or {}
    local seasonInfo = exports['aura_seasons']:GetSeasonInfo() or {}
    local timeInfo = exports['aura_seasons']:GetTime() or { hour = 12, minute = 0, isFrozen = false, isDay = true, dayDuration = 2000, nightDuration = 2000 }

    local hour = timeInfo.hour or 12
    local minute = timeInfo.minute or 0

    return {
        season = season,
        seasonLabel = Config.Seasons[season] and Config.Seasons[season].label or season,
        weather = weather,
        ambientTemp = ambientTemp,
        coreTemp = coreTemp,
        insulation = insulation,
        isSheltered = isSheltered,
        breakdown = breakdown,
        buffs = buffs,
        dayInSeason = seasonInfo.dayInSeason or 1,
        totalDay = seasonInfo.totalDay or 1,
        time = {
            hour = hour,
            minute = minute,
            formatted = string.format('%02d:%02d', hour, minute),
            isFrozen = timeInfo.isFrozen or false,
            isDay = timeInfo.isDay ~= nil and timeInfo.isDay or (hour >= 6 and hour < 20),
            dayDuration = timeInfo.dayDuration or 2000,
            nightDuration = timeInfo.nightDuration or 2000
        }
    }
end

-- ============================================================================
-- ABRIR / CERRAR PANEL CUSTOM NUI
-- ============================================================================

local function OpenSeasonsControlHub()
    if isPanelOpen then return end
    isPanelOpen = true

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openMenu',
        payload = GetFullTelemetryPayload()
    })
end

local function CloseSeasonsControlHub()
    if not isPanelOpen then return end
    isPanelOpen = false

    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeMenu'
    })
end

-- Bucle de actualización en tiempo real mientras el panel está abierto
CreateThread(function()
    while true do
        if isPanelOpen then
            Wait(400)
            SendNUIMessage({
                action = 'updateTelemetry',
                payload = GetFullTelemetryPayload()
            })
        else
            Wait(1500)
        end
    end
end)

-- ============================================================================
-- NUI CALLBACKS (RESPUESTAS INSTANTÁNEAS AL HACER CLIC)
-- ============================================================================

RegisterNUICallback('close', function(data, cb)
    CloseSeasonsControlHub()
    cb('ok')
end)

RegisterNUICallback('setSeason', function(data, cb)
    if data and data.season then
        TriggerServerEvent('aura_seasons:server:adminSetSeason', data.season)
    end
    cb('ok')
end)

RegisterNUICallback('setWeather', function(data, cb)
    if data and data.weather then
        TriggerServerEvent('aura_seasons:server:adminSetWeather', data.weather)
    end
    cb('ok')
end)

RegisterNUICallback('setTime', function(data, cb)
    if data and data.hour ~= nil then
        TriggerServerEvent('aura_seasons:server:adminSetTime', data.hour, data.minute or 0)
    end
    cb('ok')
end)

RegisterNUICallback('toggleFreezeTime', function(data, cb)
    if data then
        TriggerServerEvent('aura_seasons:server:adminToggleFreezeTime', data.frozen)
    end
    cb('ok')
end)

RegisterNUICallback('setTimeSpeed', function(data, cb)
    if data then
        TriggerServerEvent('aura_seasons:server:adminSetTimeSpeed', data.dayDuration, data.nightDuration)
    end
    cb('ok')
end)

RegisterNUICallback('setTemp', function(data, cb)
    if data and data.temp then
        local temp = tonumber(data.temp)
        if temp then
            exports['aura_seasons']:SetCoreTemperature(temp)
            lib.notify({
                title = 'Simulación Térmica',
                description = ('Temperatura corporal fijada en %.1fºC'):format(temp),
                type = 'inform'
            })
        end
    end
    cb('ok')
end)

RegisterNUICallback('applyBuff', function(data, cb)
    if data and data.type then
        TriggerEvent('aura_seasons:client:applyBuff', data)
    end
    cb('ok')
end)

RegisterNUICallback('giveTestItems', function(data, cb)
    TriggerServerEvent('aura_seasons:server:adminGiveTestItems')
    cb('ok')
end)

RegisterNUICallback('advanceDay', function(data, cb)
    local amount = data and tonumber(data.amount) or 1
    TriggerServerEvent('aura_seasons:server:adminAdvanceDay', amount)
    cb('ok')
end)

RegisterNUICallback('rotateNextSeason', function(data, cb)
    local season = exports['aura_seasons']:GetCurrentSeason() or 'spring'
    local nextSeason = Config.Seasons[season] and Config.Seasons[season].nextSeason or 'summer'
    TriggerServerEvent('aura_seasons:server:adminSetSeason', nextSeason)
    cb('ok')
end)

-- ============================================================================
-- OVERLAY DE DIAGNÓSTICO EN PANTALLA (/thermaldebug)
-- ============================================================================

local function StartDebugOverlayLoop()
    CreateThread(function()
        while isDebugOverlayActive do
            local p = GetFullTelemetryPayload()
            local now = GetGameTimer()
            local warmthSec = p.buffs.warmth and p.buffs.warmth.active and math.max(0, math.floor((p.buffs.warmth.expiresAt - now) / 1000)) or 0
            local coolingSec = p.buffs.cooling and p.buffs.cooling.active and math.max(0, math.floor((p.buffs.cooling.expiresAt - now) / 1000)) or 0

            local text = string.format([[
**[AuraRP Seasons Telemetry]**
• **Estación:** %s | **Clima:** %s
• **Temp. Ambiente:** %.1fºC %s
• **Temp. Corporal:** %.1fºC
• **Aislamiento Total:** %.1f / 100
  - *Top (11):* ID %s (%.0f pts)
  - *Chaleco EUP (9):* ID %s (%.0f pts)
  - *Brazos (3):* ID %s (%.0f pts)
  - *Pantalón (4):* ID %s (%.0f pts)
  - *Interior (8):* ID %s (%.0f pts)
  - *Zapatos (6):* ID %s (%.0f pts)
  - *Cabeza:* Mask %s | Prop0 %s (%.0f pts)
• **Refugio / Climatizado:** %s
• **Buff Calor:** %s (%ds)
• **Buff Frío:** %s (%ds)
            ]],
                string.upper(p.season),
                p.weather,
                p.ambientTemp,
                p.isSheltered and '(Climatizado 21ºC)' or '',
                p.coreTemp,
                p.breakdown.total or 0,
                p.breakdown.top and p.breakdown.top.id or 'N/A', p.breakdown.top and p.breakdown.top.score or 0,
                p.breakdown.armor and p.breakdown.armor.id or 'N/A', p.breakdown.armor and p.breakdown.armor.score or 0,
                p.breakdown.arms and p.breakdown.arms.id or 'N/A', p.breakdown.arms and p.breakdown.arms.score or 0,
                p.breakdown.pants and p.breakdown.pants.id or 'N/A', p.breakdown.pants and p.breakdown.pants.score or 0,
                p.breakdown.undershirt and p.breakdown.undershirt.id or 'N/A', p.breakdown.undershirt and p.breakdown.undershirt.score or 0,
                p.breakdown.shoes and p.breakdown.shoes.id or 'N/A', p.breakdown.shoes and p.breakdown.shoes.score or 0,
                p.breakdown.head and p.breakdown.head.maskId or 'N/A', p.breakdown.head and p.breakdown.head.prop0 or 'N/A', p.breakdown.head and p.breakdown.head.score or 0,
                p.isSheltered and '🟢 SÍ' or '🔴 NO',
                warmthSec > 0 and '🟢 ACTIVO' or '⚪ Inactivo', warmthSec,
                coolingSec > 0 and '🟢 ACTIVO' or '⚪ Inactivo', coolingSec
            )

            lib.showTextUI(text, {
                position = 'top-right',
                icon = 'temperature-half',
                style = {
                    borderRadius = 10,
                    backgroundColor = '#0a0e19fa',
                    color = '#f8fafc',
                    border = '1.5px solid #00f0ff'
                }
            })

            Wait(500)
        end
        lib.hideTextUI()
    end)
end

local function ToggleDebugOverlay()
    isDebugOverlayActive = not isDebugOverlayActive
    if isDebugOverlayActive then
        StartDebugOverlayLoop()
        lib.notify({
            title = 'Thermal Debug',
            description = 'Overlay de telemetría activado en pantalla.',
            type = 'inform'
        })
    else
        lib.hideTextUI()
        lib.notify({
            title = 'Thermal Debug',
            description = 'Overlay de telemetría desactivado.',
            type = 'inform'
        })
    end
end

-- ============================================================================
-- COMANDOS Y REGISTRO DE EVENTOS
-- ============================================================================

RegisterNetEvent('aura_seasons:client:openAdminMenu', function()
    OpenSeasonsControlHub()
end)

RegisterCommand('seasonmenu', function()
    OpenSeasonsControlHub()
end, false)

RegisterCommand('seasonsadmin', function()
    OpenSeasonsControlHub()
end, false)

RegisterCommand('thermaldebug', function()
    ToggleDebugOverlay()
end, false)

RegisterCommand('settemp', function(source, args)
    if not args[1] then
        lib.notify({ title = 'Uso', description = 'Usa: /settemp [grados_celsius] (ej: /settemp 32.5 o /settemp 40.5)', type = 'inform' })
        return
    end
    local temp = tonumber(args[1])
    if temp then
        exports['aura_seasons']:SetCoreTemperature(temp)
        lib.notify({ title = 'Temperatura Corporal', description = ('Temperatura forzada a %.1fºC'):format(temp), type = 'success' })
    end
end, false)

RegisterCommand('recalcinsulation', function()
    local val = exports['aura_seasons']:RecalculateInsulation()
    lib.notify({
        title = 'Aislamiento Recalculado',
        description = ('Tu nivel de aislamiento actual es: %.1f / 100'):format(val or 0),
        type = 'inform'
    })
end, false)
