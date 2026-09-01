-- ============================================================================
-- AURA JOBS: AUTOMATED PAYCHECK LOOP & FISCAL SINK ENGINE
-- ============================================================================

local function ProcessPaycheckCycle()
    local players = GetPlayers()
    if not players or #players == 0 then return end

    local totalProcessed = 0
    local totalGrossPaid = 0
    local totalTaxesSunk = 0

    for _, playerId in ipairs(players) do
        local src = tonumber(playerId)
        if src and GetPlayerName(tostring(src)) then
            local pState = Player(src).state
            local jobName = pState.job or 'unemployed'
            local jobGrade = pState.job_grade or 0
            local isDuty = pState.job_duty == true

            -- Solo procesar a jugadores en servicio (o desempleados recibiendo ayuda mínima si se configura)
            local jobConfig = Config.Jobs[jobName]
            if jobConfig and (isDuty or (jobName == 'unemployed' and not jobConfig.canDuty)) then
                local gradeConfig = jobConfig.grades[jobGrade] or jobConfig.grades[0]
                local grossSalary = gradeConfig and tonumber(gradeConfig.salary) or 0

                if grossSalary > 0 then
                    -- 1. Cálculo de deducción fiscal del Estado (Sumidero Deflacionario)
                    local taxRate = Config.PaycheckTaxRate or 0.05
                    local taxAmount = math.floor(grossSalary * taxRate)
                    local netSalary = grossSalary - taxAmount

                    -- 2. Depósito bancario atómico a través de aura_economy
                    local success, newBalance, txId = exports.aura_economy:AddMoney(
                        src,
                        'bank',
                        netSalary,
                        string.format("Nómina: %s (%s)", jobConfig.label, gradeConfig.name),
                        {
                            job = jobName,
                            grade = jobGrade,
                            gross = grossSalary,
                            tax_sunk = taxAmount,
                            tax_rate = taxRate
                        }
                    )

                    if success then
                        totalProcessed = totalProcessed + 1
                        totalGrossPaid = totalGrossPaid + grossSalary
                        totalTaxesSunk = totalTaxesSunk + taxAmount

                        -- 3. Notificación HUD al empleado
                        TriggerClientEvent('ox_lib:notify', src, {
                            title = 'Nómina Cobrada',
                            description = string.format("Has recibido $%s en tu cuenta bancaria.\n(Salario Base: $%s | Retención Estatal 5%%: -$%s)", 
                                lib.math.groupdigits(netSalary), 
                                lib.math.groupdigits(grossSalary), 
                                lib.math.groupdigits(taxAmount)
                            ),
                            type = 'success',
                            duration = 7500
                        })
                    end
                end
            end
        end
    end

    if Config.Debug or totalProcessed > 0 then
        print(string.format("[Aura Jobs Paycheck] Ciclo completado: %d nóminas liquidadas | Salarios Brutos: $%s | Retención Fiscal Destruida (Sink): $%s", 
            totalProcessed, 
            lib.math.groupdigits(totalGrossPaid), 
            lib.math.groupdigits(totalTaxesSunk)
        ))
    end
end

-- Hilo recurrente del servidor cada 30 minutos
CreateThread(function()
    while true do
        Wait(Config.PaycheckInterval or (30 * 60 * 1000))
        ProcessPaycheckCycle()
    end
end)

-- Comando Administrativo para forzar un ciclo de nómina (Testing / Mantenimiento)
RegisterCommand('forcepaycheck', function(source)
    if source ~= 0 and not IsPlayerAceAllowed(tostring(source), 'group.admin') then
        return
    end
    print("[Aura Jobs] Forzando ciclo de nóminas por orden administrativa...")
    ProcessPaycheckCycle()
end, true)
