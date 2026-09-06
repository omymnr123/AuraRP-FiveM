// ============================================================================
// AURARP SEASONS & SURVIVAL CONTROL HUB NUI JAVASCRIPT CONTROLLER
// ============================================================================

const app = document.getElementById('app');

// Tab Navigation
const tabs = document.querySelectorAll('.nav-tab');
const tabContents = document.querySelectorAll('.tab-content');

tabs.forEach(tab => {
    tab.addEventListener('click', () => {
        const targetTab = tab.getAttribute('data-tab');
        
        tabs.forEach(t => t.classList.remove('active'));
        tabContents.forEach(tc => tc.classList.remove('active'));

        tab.classList.add('active');
        const activeContent = document.getElementById(`tab-${targetTab}`);
        if (activeContent) {
            activeContent.classList.add('active');
        }
    });
});

// Slider display updater
const tempSlider = document.getElementById('temp-slider');
const sliderDisplay = document.getElementById('slider-temp-display');

if (tempSlider && sliderDisplay) {
    tempSlider.addEventListener('input', (e) => {
        sliderDisplay.textContent = `${Number(e.target.value).toFixed(1)}ºC`;
    });
}

// Horizontal wheel scroll on navigation tabs
const panelNav = document.querySelector('.panel-nav');
if (panelNav) {
    panelNav.addEventListener('wheel', (e) => {
        if (e.deltaY !== 0) {
            e.preventDefault();
            panelNav.scrollLeft += e.deltaY;
        }
    });
}

// Time Slider & Controls State
const timeSlider = document.getElementById('time-slider');
const timeSliderVal = document.getElementById('time-slider-val');
let isUserDraggingTimeSlider = false;
let isTimeFrozenCurrent = false;

if (timeSlider && timeSliderVal) {
    timeSlider.addEventListener('mousedown', () => { isUserDraggingTimeSlider = true; });
    timeSlider.addEventListener('mouseup', () => { isUserDraggingTimeSlider = false; });
    timeSlider.addEventListener('touchstart', () => { isUserDraggingTimeSlider = true; });
    timeSlider.addEventListener('touchend', () => { isUserDraggingTimeSlider = false; });

    timeSlider.addEventListener('input', (e) => {
        const totalMinutes = parseInt(e.target.value, 10);
        const h = Math.floor(totalMinutes / 60);
        const m = totalMinutes % 60;
        timeSliderVal.textContent = `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
    });
}

// Function to send NUI callbacks to Lua client
function postCallback(endpoint, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${endpoint}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify(data)
    }).catch(err => console.error(`Error sending NUI callback [${endpoint}]:`, err));
}

// Close Panel Handler
function closePanel() {
    app.classList.add('hidden');
    postCallback('close');
}

document.getElementById('btn-close').addEventListener('click', closePanel);

window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && !app.classList.contains('hidden')) {
        closePanel();
    }
});

// Update UI with incoming data from client Lua
function updateDashboardData(data) {
    if (!data) return;

    // Telemetry bar
    const seasonLabel = data.seasonLabel || data.season || 'PRIMAVERA';
    document.getElementById('telemetry-season').textContent = seasonLabel.toUpperCase();
    document.getElementById('telemetry-weather').textContent = data.weather || 'CLEAR';
    document.getElementById('telemetry-ambient').textContent = `${(data.ambientTemp || 21.0).toFixed(1)}ºC`;
    document.getElementById('telemetry-core').textContent = `${(data.coreTemp || 37.0).toFixed(1)}ºC`;
    document.getElementById('telemetry-insulation').textContent = `${Math.round(data.insulation || 0)}%`;

    const shelterEl = document.getElementById('telemetry-shelter');
    if (data.isSheltered) {
        shelterEl.innerHTML = '<i class="fa-solid fa-circle-check status-yes"></i> SÍ (21ºC)';
    } else {
        shelterEl.innerHTML = '<i class="fa-solid fa-circle-xmark status-no"></i> NO';
    }

    // Telemetry Time & Cycle
    if (data.time) {
        const t = data.time;
        isTimeFrozenCurrent = t.isFrozen;
        const timePill = document.getElementById('telemetry-time');
        if (timePill) {
            const cycleIcon = t.isDay ? 'fa-sun status-yes' : 'fa-moon' ;
            const cycleText = t.isFrozen ? '(Pausa)' : (t.isDay ? 'DÍA' : 'NOCHE');
            timePill.innerHTML = `<i class="fa-solid ${cycleIcon}"></i> ${t.formatted} <small style="font-size: 10px; color: var(--text-secondary);">${cycleText}</small>`;
        }

        // Digital Clock
        const digitalClock = document.getElementById('digital-clock-time');
        if (digitalClock) {
            digitalClock.textContent = t.formatted;
        }

        const clockBadge = document.getElementById('digital-clock-badge');
        if (clockBadge) {
            clockBadge.className = 'digital-clock-badge';
            if (t.isFrozen) {
                clockBadge.classList.add('frozen');
                clockBadge.innerHTML = '<i class="fa-solid fa-snowflake"></i> PAUSADO';
            } else if (t.isDay) {
                clockBadge.innerHTML = '<i class="fa-solid fa-sun"></i> CICLO DÍA';
            } else {
                clockBadge.classList.add('night');
                clockBadge.innerHTML = '<i class="fa-solid fa-moon"></i> CICLO NOCHE';
            }
        }

        // Time slider auto-sync when not dragged
        if (timeSlider && timeSliderVal && !isUserDraggingTimeSlider) {
            const currentTotalMin = (t.hour * 60) + t.minute;
            timeSlider.value = currentTotalMin;
            timeSliderVal.textContent = t.formatted;
        }

        // Freeze button state
        const freezeBtn = document.getElementById('btn-freeze-time');
        const freezeText = document.getElementById('freeze-btn-text');
        if (freezeBtn && freezeText) {
            if (t.isFrozen) {
                freezeBtn.classList.add('active');
                freezeBtn.innerHTML = '<i class="fa-solid fa-play"></i> <span id="freeze-btn-text">Reanudar Tiempo</span>';
            } else {
                freezeBtn.classList.remove('active');
                freezeBtn.innerHTML = '<i class="fa-solid fa-pause"></i> <span id="freeze-btn-text">Pausar Tiempo</span>';
            }
        }

        // Inputs for day/night duration in real minutes (if not active element)
        const dayInput = document.getElementById('input-day-minutes');
        const nightInput = document.getElementById('input-night-minutes');
        const DAY_INGAME_MINUTES = 840;   // 14 horas de día * 60
        const NIGHT_INGAME_MINUTES = 600; // 10 horas de noche * 60

        if (dayInput && document.activeElement !== dayInput && t.dayDuration) {
            const serverDayMins = Math.max(1, Math.round((t.dayDuration * DAY_INGAME_MINUTES) / 60000));
            dayInput.value = serverDayMins;
        }
        if (nightInput && document.activeElement !== nightInput && t.nightDuration) {
            const serverNightMins = Math.max(1, Math.round((t.nightDuration * NIGHT_INGAME_MINUTES) / 60000));
            nightInput.value = serverNightMins;
        }
        updateCycleSummary();
    }

    // Dashboard Gauges
    document.getElementById('dash-ambient-val').textContent = `${(data.ambientTemp || 21.0).toFixed(1)}º`;
    document.getElementById('dash-core-val').textContent = `${(data.coreTemp || 37.0).toFixed(1)}º`;
    document.getElementById('dash-insul-val').textContent = `${Math.round(data.insulation || 0)}%`;

    // Core temp gauge color styling
    const coreBorder = document.getElementById('dash-core-border');
    if (coreBorder) {
        if (data.coreTemp <= 35.5) {
            coreBorder.style.borderColor = '#00f0ff';
            coreBorder.style.boxShadow = '0 0 15px rgba(0, 240, 255, 0.6)';
        } else if (data.coreTemp >= 38.5) {
            coreBorder.style.borderColor = '#ff007f';
            coreBorder.style.boxShadow = '0 0 15px rgba(255, 0, 127, 0.6)';
        } else {
            coreBorder.style.borderColor = '#10b981';
            coreBorder.style.boxShadow = '0 0 15px rgba(16, 185, 129, 0.4)';
        }
    }

    // Clothing Slots Breakdown
    if (data.breakdown) {
        const bd = data.breakdown;
        if (bd.top) {
            document.getElementById('slot-top-id').textContent = `Drawable #${bd.top.id}`;
            document.getElementById('slot-top-score').textContent = `+${Math.round(bd.top.score)} pts`;
        }
        if (bd.armor) {
            document.getElementById('slot-armor-id').textContent = `Drawable #${bd.armor.id}`;
            document.getElementById('slot-armor-score').textContent = `+${Math.round(bd.armor.score)} pts`;
        }
        if (bd.arms) {
            document.getElementById('slot-arms-id').textContent = `Drawable #${bd.arms.id}`;
            document.getElementById('slot-arms-score').textContent = `+${Math.round(bd.arms.score)} pts`;
        }
        if (bd.pants) {
            document.getElementById('slot-pants-id').textContent = `Drawable #${bd.pants.id}`;
            document.getElementById('slot-pants-score').textContent = `+${Math.round(bd.pants.score)} pts`;
        }
        if (bd.undershirt) {
            document.getElementById('slot-under-id').textContent = `Drawable #${bd.undershirt.id}`;
            document.getElementById('slot-under-score').textContent = `+${Math.round(bd.undershirt.score)} pts`;
        }
        if (bd.shoes) {
            document.getElementById('slot-shoes-id').textContent = `Drawable #${bd.shoes.id}`;
            document.getElementById('slot-shoes-score').textContent = `+${Math.round(bd.shoes.score)} pts`;
        }
        if (bd.head) {
            document.getElementById('slot-head-id').textContent = `Mask #${bd.head.maskId} | Prop #${bd.head.prop0}`;
            document.getElementById('slot-head-score').textContent = `+${Math.round(bd.head.score)} pts`;
        }
    }

    // Calendar
    if (document.getElementById('cal-day-in-season')) {
        document.getElementById('cal-day-in-season').textContent = `${data.dayInSeason || 1} / 7`;
    }
    if (document.getElementById('cal-total-day')) {
        document.getElementById('cal-total-day').textContent = data.totalDay || 1;
    }

    // Slider
    if (tempSlider && sliderDisplay) {
        tempSlider.value = data.coreTemp || 37.0;
        sliderDisplay.textContent = `${Number(data.coreTemp || 37.0).toFixed(1)}ºC`;
    }
}

// NUI Message Listener
window.addEventListener('message', (event) => {
    const data = event.data;

    switch (data.action) {
        case 'openMenu':
            updateDashboardData(data.payload);
            app.classList.remove('hidden');
            break;
            
        case 'updateTelemetry':
            updateDashboardData(data.payload);
            break;
            
        case 'closeMenu':
            app.classList.add('hidden');
            break;
    }
});

// ============================================================================
// BOTONES INTERACTIVOS & ACCIONES DIRECTAS
// ============================================================================

// 1. Selector de Estaciones
document.querySelectorAll('.btn-season').forEach(btn => {
    btn.addEventListener('click', () => {
        const season = btn.getAttribute('data-season');
        postCallback('setSeason', { season: season });
    });
});

// 2. Selector de Clima
document.querySelectorAll('.btn-weather').forEach(btn => {
    btn.addEventListener('click', () => {
        const weather = btn.getAttribute('data-weather');
        postCallback('setWeather', { weather: weather });
    });
});

document.getElementById('btn-weather-reset').addEventListener('click', () => {
    postCallback('setWeather', { weather: 'RESET' });
});

// 3. Control de Tiempo (Slider, Presets, Freeze, Speed)
const btnApplyTime = document.getElementById('btn-apply-time');
if (btnApplyTime && timeSlider) {
    btnApplyTime.addEventListener('click', () => {
        const totalMinutes = parseInt(timeSlider.value, 10);
        const h = Math.floor(totalMinutes / 60);
        const m = totalMinutes % 60;
        postCallback('setTime', { hour: h, minute: m });
    });
}

document.querySelectorAll('.btn-time-preset').forEach(btn => {
    btn.addEventListener('click', () => {
        const h = parseInt(btn.getAttribute('data-hour'), 10);
        const m = parseInt(btn.getAttribute('data-minute'), 10);
        postCallback('setTime', { hour: h, minute: m });
    });
});

const btnFreeze = document.getElementById('btn-freeze-time');
if (btnFreeze) {
    btnFreeze.addEventListener('click', () => {
        postCallback('toggleFreezeTime', { frozen: !isTimeFrozenCurrent });
    });
}

// Helper calculation for Day/Night cycle summary
const DAY_INGAME_MINS = 840;   // 14 horas de día * 60 minutos
const NIGHT_INGAME_MINS = 600; // 10 horas de noche * 60 minutos

function updateCycleSummary() {
    const dayInput = document.getElementById('input-day-minutes');
    const nightInput = document.getElementById('input-night-minutes');
    const dayCalc = document.getElementById('day-calc-display');
    const nightCalc = document.getElementById('night-calc-display');
    const totalSummary = document.getElementById('total-cycle-summary');

    const dayMins = Math.max(1, parseInt(dayInput ? dayInput.value : 30, 10) || 30);
    const nightMins = Math.max(1, parseInt(nightInput ? nightInput.value : 15, 10) || 15);
    const totalMins = dayMins + nightMins;

    if (dayCalc) dayCalc.textContent = `${dayMins} min reales`;
    if (nightCalc) nightCalc.textContent = `${nightMins} min reales`;
    if (totalSummary) {
        totalSummary.textContent = `${totalMins} minutos reales (${dayMins}m día + ${nightMins}m noche)`;
    }
}

const inputDayMins = document.getElementById('input-day-minutes');
const inputNightMins = document.getElementById('input-night-minutes');

if (inputDayMins) {
    inputDayMins.addEventListener('input', updateCycleSummary);
}
if (inputNightMins) {
    inputNightMins.addEventListener('input', updateCycleSummary);
}

// Chips de minutos rápidos
document.querySelectorAll('.chip-btn').forEach(chip => {
    chip.addEventListener('click', () => {
        const target = chip.getAttribute('data-target');
        const val = parseInt(chip.getAttribute('data-val'), 10);
        if (target === 'day' && inputDayMins) {
            inputDayMins.value = val;
            document.querySelectorAll('.chip-btn[data-target="day"]').forEach(c => c.classList.remove('active'));
            chip.classList.add('active');
        } else if (target === 'night' && inputNightMins) {
            inputNightMins.value = val;
            document.querySelectorAll('.chip-btn[data-target="night"]').forEach(c => c.classList.remove('active'));
            chip.classList.add('active');
        }
        updateCycleSummary();
    });
});

const btnSaveSpeed = document.getElementById('btn-save-speed');
if (btnSaveSpeed) {
    btnSaveSpeed.addEventListener('click', () => {
        const dayMins = Math.max(1, parseInt(document.getElementById('input-day-minutes').value, 10) || 30);
        const nightMins = Math.max(1, parseInt(document.getElementById('input-night-minutes').value, 10) || 15);
        
        // Conversión matemática exacta: Minutos Reales -> Milisegundos por minuto de juego
        const dayDurationMs = Math.max(100, Math.round((dayMins * 60 * 1000) / DAY_INGAME_MINS));
        const nightDurationMs = Math.max(100, Math.round((nightMins * 60 * 1000) / NIGHT_INGAME_MINS));

        postCallback('setTimeSpeed', { dayDuration: dayDurationMs, nightDuration: nightDurationMs });

        btnSaveSpeed.innerHTML = '<i class="fa-solid fa-check"></i> ¡Duración Guardada!';
        btnSaveSpeed.style.background = '#10b981';
        setTimeout(() => {
            btnSaveSpeed.innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Guardar Duración en Base de Datos';
            btnSaveSpeed.style.background = '';
        }, 2000);
    });
}

// 4. Simulador Fisiológico - Presets
document.querySelectorAll('.preset-card').forEach(card => {
    card.addEventListener('click', () => {
        const temp = parseFloat(card.getAttribute('data-temp'));
        postCallback('setTemp', { temp: temp });
    });
});

// 5. Slider de Temperatura Personalizada
document.getElementById('btn-apply-slider').addEventListener('click', () => {
    const temp = parseFloat(tempSlider.value);
    postCallback('setTemp', { temp: temp });
});

// 6. Buffs & Consumibles
document.querySelector('.btn-apply-warmth').addEventListener('click', () => {
    postCallback('applyBuff', {
        type: 'warmth',
        coreTempBoost: 1.5,
        buffDuration: 600,
        resistance: 0.50,
        label: 'Café Expreso Caliente'
    });
});

document.querySelector('.btn-apply-cooling').addEventListener('click', () => {
    postCallback('applyBuff', {
        type: 'cooling',
        coreTempBoost: -1.2,
        buffDuration: 600,
        resistance: 0.50,
        label: 'Botella de Agua Fresca'
    });
});

document.querySelector('.btn-give-items').addEventListener('click', () => {
    postCallback('giveTestItems');
});

// 7. Calendario & Días
document.getElementById('btn-day-prev').addEventListener('click', () => {
    postCallback('advanceDay', { amount: -1 });
});

document.getElementById('btn-day-next').addEventListener('click', () => {
    postCallback('advanceDay', { amount: 1 });
});

document.getElementById('btn-rotate-next').addEventListener('click', () => {
    postCallback('rotateNextSeason');
});

