// ============================================================================
// AURARP - CRITICAL STATE & COMA SYSTEM (PHASE 8.2 JS CONTROLLER)
// Dynamic 2-Phase Trauma Engine: Injured (Crawling/Immobile) & Unconscious
// ============================================================================

const DISPATCH_COOLDOWN_SECONDS = 120; // 2 Minutos de enfriamiento

// Elementos del DOM
const appContainer = document.getElementById('death-app');
const countdownEl = document.getElementById('countdown-timer');
const dispatchBtn = document.getElementById('dispatch-btn');
const respawnBtn = document.getElementById('respawn-btn');
const btnText = document.getElementById('btn-text');
const respawnIcon = document.getElementById('respawn-icon');
const respawnText = document.getElementById('respawn-text');
const badgeText = document.getElementById('badge-text');
const pulseDot = document.getElementById('pulse-dot');
const hintText = document.getElementById('hint-text');
const cooldownOverlay = document.getElementById('cooldown-overlay');
const cooldownBar = document.getElementById('cooldown-bar');
const teleHeart = document.getElementById('tele-heart');
const teleSpo2 = document.getElementById('tele-spo2');
const timerTag = document.getElementById('timer-tag');

// Variables de estado
let countdownTimer = null;
let cooldownTimer = null;
let telemetryTimer = null;

let totalSeconds = 300; // 5 Minutos de desangrado (300 segundos)
let secondsRemaining = 300;
let cooldownRemaining = 0;
let currentDeathState = 'injured'; // 'injured' o 'unconscious'
let canCrawl = true;
let crawlRemaining = 60;
let unconsciousDelay = 300; // 5 minutos = 300s

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
 * Configura la UI para la fase de HERIDO (Desangrado de 5 minutos)
 */
function setInjuredState(isCrawling, crawlSec) {
    currentDeathState = 'injured';
    canCrawl = isCrawling;
    crawlRemaining = crawlSec !== undefined ? crawlSec : (canCrawl ? 60 : 0);

    if (timerTag) {
        timerTag.textContent = 'DESANGRADO';
    }

    if (badgeText) {
        badgeText.textContent = canCrawl ? 'HERIDO (ARRÁSTRATE)' : 'HERIDO';
        badgeText.className = 'badge-text injured';
    }
    if (pulseDot) {
        pulseDot.className = 'pulse-dot injured';
    }

    // Botón de Hospital bloqueado en fase de Herido
    if (respawnBtn) {
        respawnBtn.disabled = true;
        respawnBtn.classList.add('disabled', 'locked');
    }
    if (respawnIcon) {
        respawnIcon.className = 'fa-solid fa-lock btn-icon';
    }
    if (respawnText) {
        respawnText.textContent = 'HOSPITAL';
    }

    if (btnText && cooldownRemaining <= 0) {
        btnText.innerHTML = 'AUXILIO <span style="font-size:11px; opacity:0.8; margin-left:4px;">[G]</span>';
    }

    if (hintText) {
        hintText.innerHTML = canCrawl
            ? '<strong>[W/A/S/D]</strong> Arrastrarse • <strong>[T]</strong> Chat'
            : '<strong>[T]</strong> Chat • <strong class="highlight-action">[Click Derecho]</strong> Cámara';
    }
}

/**
 * Configura la UI para la fase de INCONSCIENTE (Desbloquea el botón de Hospital)
 */
function setUnconsciousState() {
    currentDeathState = 'unconscious';
    canCrawl = false;
    crawlRemaining = 0;

    if (timerTag) {
        timerTag.textContent = 'INCONSCIENTE';
    }

    if (badgeText) {
        badgeText.textContent = 'INCONSCIENTE';
        badgeText.className = 'badge-text unconscious';
    }
    if (pulseDot) {
        pulseDot.className = 'pulse-dot unconscious';
    }

    // Botón de Hospital DESBLOQUEADO
    if (respawnBtn) {
        respawnBtn.disabled = false;
        respawnBtn.classList.remove('disabled', 'locked');
    }
    if (respawnIcon) {
        respawnIcon.className = 'fa-solid fa-bed-pulse btn-icon';
    }
    if (respawnText) {
        respawnText.textContent = 'HOSPITAL';
    }

    if (btnText && cooldownRemaining <= 0) {
        btnText.innerHTML = 'AUXILIO <span style="font-size:11px; opacity:0.8; margin-left:4px;">[G]</span>';
    }

    if (hintText) {
        hintText.innerHTML = '<strong>[T]</strong> Chat • <strong class="highlight-action">[Click Derecho]</strong> Cámara';
    }
}

/**
 * Inicia la cuenta regresiva del desangrado (05:00)
 * @param {number} initialSeconds 
 */
function startCountdown(initialSeconds) {
    if (countdownTimer) clearInterval(countdownTimer);
    
    totalSeconds = 300;
    secondsRemaining = Math.max(0, initialSeconds !== undefined ? initialSeconds : 300);
    countdownEl.textContent = formatTime(secondsRemaining);

    countdownTimer = setInterval(() => {
        secondsRemaining--;

        // Reducir tiempo de arrastre en UI
        if (canCrawl && crawlRemaining > 0) {
            crawlRemaining--;
            if (crawlRemaining <= 0) {
                canCrawl = false;
                if (badgeText && currentDeathState === 'injured') {
                    badgeText.textContent = 'HERIDO';
                }
                if (hintText) {
                    hintText.innerHTML = '<strong>[T]</strong> Chat • <strong class="highlight-action">[Click Derecho]</strong> Cámara';
                }
            }
        }

        // Comprobación de paso a INCONSCIENTE al terminar el tiempo de desangrado (00:00)
        if (secondsRemaining <= 0) {
            clearInterval(countdownTimer);
            countdownTimer = null;
            secondsRemaining = 0;
            countdownEl.textContent = "00:00";

            setUnconsciousState();
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
 * Inicia el enfriamiento de 2 minutos para el botón de auxilio
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
            btnText.innerHTML = 'AUXILIO <span style="font-size:11px; opacity:0.8; margin-left:4px;">[G]</span>';
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
            const randomHeart = (currentDeathState === 'injured') 
                ? Math.floor(Math.random() * (48 - 34 + 1)) + 34
                : Math.floor(Math.random() * (28 - 18 + 1)) + 18;
            teleHeart.textContent = `${randomHeart} BPM`;
        }
        if (teleSpo2) {
            const randomSpo2 = (currentDeathState === 'injured')
                ? Math.floor(Math.random() * (68 - 55 + 1)) + 55
                : Math.floor(Math.random() * (45 - 30 + 1)) + 30;
            teleSpo2.textContent = `${randomSpo2}%`;
        }
    }, 3000);
}

// Click Handler: Botón de Auxilio
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

// Click Handler: Botón de Reaparecer en Hospital (Solo disponible en Inconsciencia)
if (respawnBtn) {
    respawnBtn.addEventListener('click', (e) => {
        e.preventDefault();
        if (respawnBtn.disabled || currentDeathState !== 'unconscious') return;

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

            unconsciousDelay = data.unconsciousDelay || 300;
            const initialState = data.deathState || 'injured';
            const initialCanCrawl = data.canCrawl !== undefined ? data.canCrawl : true;
            const initialCrawlRem = data.crawlRemaining !== undefined ? data.crawlRemaining : 60;

            if (initialState === 'unconscious') {
                setUnconsciousState();
            } else {
                setInjuredState(initialCanCrawl, initialCrawlRem);
            }

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
            if (btnText) btnText.innerHTML = 'AUXILIO <span style="font-size:11px; opacity:0.8; margin-left:4px;">[G]</span>';

            startCountdown(data.timeRemaining !== undefined ? data.timeRemaining : 300);
            startTelemetrySimulation();
            break;

        case 'setUnconscious':
            setUnconsciousState();
            break;

        case 'crawlExpired':
            canCrawl = false;
            crawlRemaining = 0;
            if (badgeText && currentDeathState === 'injured') {
                badgeText.textContent = 'HERIDO';
            }
            if (hintText) {
                hintText.innerHTML = '<strong>[T]</strong> Chat • <strong class="highlight-action">[Click Derecho]</strong> Cámara';
            }
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
                if (btnText) btnText.innerHTML = 'AUXILIO <span style="font-size:11px; opacity:0.8; margin-left:4px;">[G]</span>';
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

