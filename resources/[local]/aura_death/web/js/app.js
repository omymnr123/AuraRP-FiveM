// ============================================================================
// AURARP - CRITICAL STATE & COMA SYSTEM (PHASE 8 JS CONTROLLER)
// ============================================================================

const DISPATCH_COOLDOWN_SECONDS = 120; // 2 Minutos de enfriamiento

// Elementos del DOM
const appContainer = document.getElementById('death-app');
const countdownEl = document.getElementById('countdown-timer');
const dispatchBtn = document.getElementById('dispatch-btn');
const respawnBtn = document.getElementById('respawn-btn');
const btnText = document.getElementById('btn-text');
const cooldownOverlay = document.getElementById('cooldown-overlay');
const cooldownBar = document.getElementById('cooldown-bar');
const teleHeart = document.getElementById('tele-heart');
const teleSpo2 = document.getElementById('tele-spo2');

// Variables de estado
let countdownTimer = null;
let cooldownTimer = null;
let telemetryTimer = null;

let totalSeconds = 600;
let secondsRemaining = 600;
let cooldownRemaining = 0;

/**
 * Formatea segundos a string MM:SS
 * @param {number} totalSec 
 * @returns {string} Formato 00:00
 */
function formatTime(totalSec) {
    if (isNaN(totalSec) || totalSec < 0) totalSec = 0;
    const minutes = Math.floor(totalSec / 60);
    const seconds = totalSec % 60;
    return `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
}

/**
 * Inicia la cuenta regresiva del estado crítico (10:00)
 * @param {number} initialSeconds 
 */
function startCountdown(initialSeconds) {
    if (countdownTimer) clearInterval(countdownTimer);
    
    totalSeconds = 600;
    secondsRemaining = Math.max(1, initialSeconds || 600);
    countdownEl.textContent = formatTime(secondsRemaining);

    countdownTimer = setInterval(() => {
        secondsRemaining--;

        if (secondsRemaining <= 0) {
            clearInterval(countdownTimer);
            countdownTimer = null;
            countdownEl.textContent = "00:00";

            // Notificar a FiveM Lua que el tiempo expiró para ejecutar PK
            fetch(`https://${GetParentResourceName()}/timerExpired`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json; charset=UTF-8',
                },
                body: JSON.stringify({})
            }).catch(() => {});
            return;
        }

        countdownEl.textContent = formatTime(secondsRemaining);

        // Sincronizar periódicamente cada 10 segundos
        if (secondsRemaining % 10 === 0) {
            fetch(`https://${GetParentResourceName()}/syncTime`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json; charset=UTF-8',
                },
                body: JSON.stringify({
                    timeRemaining: secondsRemaining
                })
            }).catch(() => {});
        }
    }, 1000);
}

/**
 * Inicia el enfriamiento de 2 minutos para el botón de emergencias
 */
function startDispatchCooldown() {
    if (cooldownTimer) clearInterval(cooldownTimer);

    cooldownRemaining = DISPATCH_COOLDOWN_SECONDS;
    dispatchBtn.disabled = true;
    dispatchBtn.classList.add('disabled');
    cooldownOverlay.classList.remove('hidden');

    btnText.textContent = `(${formatTime(cooldownRemaining)})`;
    cooldownBar.style.width = '100%';

    cooldownTimer = setInterval(() => {
        cooldownRemaining--;

        if (cooldownRemaining <= 0) {
            clearInterval(cooldownTimer);
            cooldownTimer = null;
            dispatchBtn.disabled = false;
            dispatchBtn.classList.remove('disabled');
            cooldownOverlay.classList.add('hidden');
            btnText.textContent = 'EMERGENCIAS';
            cooldownBar.style.width = '100%';
            return;
        }

        btnText.textContent = `(${formatTime(cooldownRemaining)})`;
        const percent = (cooldownRemaining / DISPATCH_COOLDOWN_SECONDS) * 100;
        cooldownBar.style.width = `${percent}%`;
    }, 1000);
}

/**
 * Simulación de telemetría de pulso y saturación en estado agónico
 */
function startTelemetrySimulation() {
    if (telemetryTimer) clearInterval(telemetryTimer);

    telemetryTimer = setInterval(() => {
        if (teleHeart) {
            const randomHeart = Math.floor(Math.random() * (38 - 26 + 1)) + 26;
            teleHeart.textContent = `${randomHeart} BPM`;
        }
        if (teleSpo2) {
            const randomSpo2 = Math.floor(Math.random() * (52 - 42 + 1)) + 42;
            teleSpo2.textContent = `${randomSpo2}%`;
        }
    }, 3000);
}

// Click Handler: Botón de Emergencias
if (dispatchBtn) {
    dispatchBtn.addEventListener('click', (e) => {
        e.preventDefault();
        if (dispatchBtn.disabled || cooldownRemaining > 0) return;

        startDispatchCooldown();

        fetch(`https://${GetParentResourceName()}/callDispatch`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({})
        }).catch(() => {});
    });
}

// Click Handler: Botón de Reaparecer en Hospital
if (respawnBtn) {
    respawnBtn.addEventListener('click', (e) => {
        e.preventDefault();
        fetch(`https://${GetParentResourceName()}/respawnHospital`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({})
        }).catch(() => {});
    });
}

// Click Derecho en NUI: Prevenir menú contextual de Chromium y alternar cámara / cursor
window.addEventListener('contextmenu', (e) => {
    e.preventDefault();
    fetch(`https://${GetParentResourceName()}/toggleCursor`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({})
    }).catch(() => {});
});

// FiveM Message Event Listener
window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || !data.action) return;

    switch (data.action) {
        case 'openDeathScreen':
            appContainer.classList.remove('hidden');
            appContainer.style.display = 'flex';

            // Limpieza y reinicio garantizado del botón de emergencias
            cooldownRemaining = 0;
            if (cooldownTimer) {
                clearInterval(cooldownTimer);
                cooldownTimer = null;
            }
            if (dispatchBtn) {
                dispatchBtn.disabled = false;
                dispatchBtn.classList.remove('disabled');
            }
            if (cooldownOverlay) cooldownOverlay.classList.add('hidden');
            if (btnText) btnText.innerHTML = 'EMERGENCIAS <span style="font-size:11px; opacity:0.8; margin-left:4px;">[G]</span>';

            startCountdown(data.timeRemaining || 600);
            startTelemetrySimulation();
            break;

        case 'triggerDispatchKey':
            if (dispatchBtn && !dispatchBtn.disabled && cooldownRemaining <= 0) {
                dispatchBtn.click();
            }
            break;

        case 'closeDeathScreen':
            appContainer.classList.add('hidden');
            appContainer.style.display = 'none';

            if (countdownTimer) {
                clearInterval(countdownTimer);
                countdownTimer = null;
            }
            if (cooldownTimer) {
                clearInterval(cooldownTimer);
                cooldownTimer = null;
            }
            if (telemetryTimer) {
                clearInterval(telemetryTimer);
                telemetryTimer = null;
            }

            if (dispatchBtn) {
                dispatchBtn.disabled = false;
                dispatchBtn.classList.remove('disabled');
                if (cooldownOverlay) cooldownOverlay.classList.add('hidden');
                if (btnText) btnText.innerHTML = 'EMERGENCIAS <span style="font-size:11px; opacity:0.8; margin-left:4px;">[G]</span>';
            }
            break;

        case 'updateTime':
            if (data.timeRemaining !== undefined) {
                secondsRemaining = data.timeRemaining;
                countdownEl.textContent = formatTime(secondsRemaining);
            }
            break;

        case 'pauseBleedout':
            if (countdownTimer) {
                clearInterval(countdownTimer);
                countdownTimer = null;
            }
            if (countdownEl) {
                countdownEl.textContent = `${formatTime(secondsRemaining)} [PAUSA]`;
                countdownEl.style.color = '#40E0D0';
                countdownEl.style.textShadow = '0 0 15px #40E0D0';
            }
            break;
    }
});
