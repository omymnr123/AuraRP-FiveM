-- ============================================================================
-- AURA MINIGAMES: CLIENT CONTROLLER & EXPORTS
-- Promise-based NUI minigame bridge for AuraRP
-- ============================================================================

local activePromise = nil
local isMinigameActive = false

--- Inicia un minijuego NUI de forma asíncrona mediante promesas
--- @param gameType string 'lockpick' | 'ecubypass' | 'reactor' | 'cipher'
--- @param options table | nil
--- @return boolean
local function StartMinigame(gameType, options)
    if isMinigameActive then
        return false
    end

    options = options or {}
    local defaults = Config.Defaults[gameType] or {}
    for k, v in pairs(defaults) do
        if options[k] == nil then
            options[k] = v
        end
    end

    isMinigameActive = true
    activePromise = promise.new()

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)

    SendNUIMessage({
        action = 'openMinigame',
        game = gameType,
        config = options
    })

    local result = Citizen.Await(activePromise)
    activePromise = nil
    isMinigameActive = false
    SetNuiFocus(false, false)

    return result == true
end

-- ============================================================================
-- EXPORTS PÚBLICOS
-- ============================================================================

--- Minijuego de forzado mecánico de bombines
--- @param options table | nil { pins = 4, durability = 100, tolerance = 0.08 }
--- @return boolean
local function Lockpick(options)
    return StartMinigame('Lockpick', options)
end
exports('Lockpick', Lockpick)

--- Minijuego de bypass por sincronización de onda de centralita ECU
--- @param options table | nil { timeLimit = 25, syncHoldTime = 1.5, tolerance = 0.12 }
--- @return boolean
local function ECUBypass(options)
    return StartMinigame('ECUBypass', options)
end
exports('ECUBypass', ECUBypass)

--- Minijuego de control y estabilización de reactor termoquímico
--- @param options table | nil { duration = 18, criticalTimeLimit = 3.0 }
--- @return boolean
local function ChemicalReactor(options)
    return StartMinigame('ChemicalReactor', options)
end
exports('ChemicalReactor', ChemicalReactor)

--- Minijuego de descifrado matricial hexadecimal estilo Breach
--- @param options table | nil { gridSize = 5, bufferSize = 4, sequenceLength = 3, timeLimit = 30 }
--- @return boolean
local function CipherMatrix(options)
    return StartMinigame('CipherMatrix', options)
end
exports('CipherMatrix', CipherMatrix)

-- ============================================================================
-- NUI CALLBACKS
-- ============================================================================

RegisterNUICallback('minigameResult', function(data, cb)
    local success = data and data.success == true
    if activePromise then
        activePromise:resolve(success)
    end
    SetNuiFocus(false, false)
    isMinigameActive = false
    cb({ ok = true })
end)

RegisterNUICallback('closeMinigame', function(_, cb)
    if activePromise then
        activePromise:resolve(false)
    end
    SetNuiFocus(false, false)
    isMinigameActive = false
    cb({ ok = true })
end)

-- ============================================================================
-- COMANDOS DE PRUEBA Y ADMINISTRACIÓN
-- ============================================================================

RegisterCommand('testminigame', function(source, args)
    local gameName = args and args[1] and args[1]:lower() or 'lockpick'

    if gameName == 'lockpick' or gameName == 'ganzua' then
        lib.notify({ title = 'Minijuego AuraRP', description = 'Iniciando forzado de cerradura mecánica...', type = 'inform' })
        local res = Lockpick({ pins = 4 })
        if res then
            lib.notify({ title = 'Minijuego', description = '¡Cerradura descerrajada con éxito! (TRUE)', type = 'success' })
        else
            lib.notify({ title = 'Minijuego', description = 'Has fallado o cancelado el forzado. (FALSE)', type = 'error' })
        end

    elseif gameName == 'ecu' or gameName == 'bypass' or gameName == 'adv_lockpick' then
        lib.notify({ title = 'Minijuego AuraRP', description = 'Iniciando sincronizador de osciloscopio ECU...', type = 'inform' })
        local res = ECUBypass()
        if res then
            lib.notify({ title = 'Minijuego', description = '¡Centralita pirateada con éxito! (TRUE)', type = 'success' })
        else
            lib.notify({ title = 'Minijuego', description = 'Fallo en la resonancia de la centralita. (FALSE)', type = 'error' })
        end

    elseif gameName == 'reactor' or gameName == 'meth' or gameName == 'lab' then
        lib.notify({ title = 'Minijuego AuraRP', description = 'Iniciando estabilización de reactor termoquímico...', type = 'inform' })
        local res = ChemicalReactor({ duration = 18 })
        if res then
            lib.notify({ title = 'Minijuego', description = '¡Síntesis química pura al 99.4%! (TRUE)', type = 'success' })
        else
            lib.notify({ title = 'Minijuego', description = '¡Fallo crítico! El reactor se ha desestabilizado. (FALSE)', type = 'error' })
        end

    elseif gameName == 'cipher' or gameName == 'matrix' or gameName == 'hack' then
        lib.notify({ title = 'Minijuego AuraRP', description = 'Iniciando descifrador de matriz hexadecimal...', type = 'inform' })
        local res = CipherMatrix({ gridSize = 5, bufferSize = 4, sequenceLength = 3 })
        if res then
            lib.notify({ title = 'Minijuego', description = '¡Búfer descifrado con éxito! (TRUE)', type = 'success' })
        else
            lib.notify({ title = 'Minijuego', description = 'Fallo de descifrado en la memoria. (FALSE)', type = 'error' })
        end

    else
        lib.notify({
            title = 'Test Minijuegos',
            description = 'Uso: /testminigame [lockpick | ecu | reactor | cipher]',
            type = 'error'
        })
    end
end, false)

RegisterCommand('minijuego', function(source, args)
    ExecuteCommand('testminigame ' .. (args[1] or ''))
end, false)
