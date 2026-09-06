// ============================================================================
// AURA MINIGAMES: DEFIBRILLATOR (DEA) CARDIAC RESUSCITATION GAME
// Real-time Canvas ECG Waveform, Capacitor Charging & R-Wave Shock Timing
// ============================================================================

class DefibrillatorGame {
    constructor(container, config) {
        this.container = container;
        this.config = Object.assign({
            timeLimit: 25,
            chargeDuration: 2.5,
            requiredShocks: 2,
            shockTolerance: 0.22,
            difficulty: 'medium',
            onFinish: () => {}
        }, config);

        this.shocksCompleted = 0;
        this.state = 'charging'; // 'charging', 'ready', 'shocking', 'success', 'failed'
        this.timer = this.config.timeLimit;
        this.chargeProgress = 0;
        this.ecgOffset = 0;
        this.isDestroyed = false;
        this.animFrameId = null;
        this.intervalId = null;

        this.targetPhase = 0.5; // Sweet spot in wave cycle
        this.currentPhase = 0;

        this.initDOM();
        this.initCanvas();
        this.bindEvents();
        this.startCharging();
        this.startLoop();
    }

    initDOM() {
        this.container.innerHTML = `
            <div class="defib-wrapper">
                <div class="defib-top-glow"></div>
                <div class="defib-header">
                    <div class="defib-brand">
                        <i class="fa-solid fa-heart-pulse defib-icon-pulse"></i>
                        <div>
                            <h2>LIFEPACK-15 DEFIBRILLATOR</h2>
                            <span class="defib-sub">SISTEMA AUTOMATIZADO DE REANIMACIÓN CARDIACA BIFÁSICA</span>
                        </div>
                    </div>
                    <div class="defib-status-badge" id="defibStatusBadge">
                        <span class="defib-dot"></span>
                        <span id="defibStatusText">CARGANDO DEA...</span>
                    </div>
                </div>

                <div class="defib-main-panel">
                    <!-- Monitor ECG Canvas -->
                    <div class="ecg-monitor-frame">
                        <div class="ecg-grid-overlay"></div>
                        <canvas id="ecgCanvas" width="580" height="180"></canvas>
                        <div class="ecg-readouts">
                            <div class="readout-item">
                                <span class="label">RITMO</span>
                                <span class="val text-pink" id="rhythmText">FIB. VENTRICULAR</span>
                            </div>
                            <div class="readout-item">
                                <span class="label">ENERGÍA</span>
                                <span class="val text-cyan" id="energyText">200 JOULES</span>
                            </div>
                            <div class="readout-item">
                                <span class="label">DESCARGAS</span>
                                <span class="val" id="shocksCounter">${this.shocksCompleted} / ${this.config.requiredShocks}</span>
                            </div>
                        </div>
                    </div>

                    <!-- Indicador de Carga / Sweet Spot Bar -->
                    <div class="defib-timing-container">
                        <div class="defib-timing-label">
                            <span id="timingLabel">SINCRONIZACIÓN DE ONDA R - PULSA [ESPACIO] EN LA ZONA VERDE</span>
                            <span class="defib-timer" id="defibTimer">${this.timer}s</span>
                        </div>
                        <div class="defib-bar-track">
                            <div class="defib-sweet-spot" id="defibSweetSpot"></div>
                            <div class="defib-needle" id="defibNeedle"></div>
                        </div>
                    </div>
                </div>

                <!-- Footer y Controles -->
                <div class="defib-footer">
                    <div class="defib-instructions">
                        <i class="fa-solid fa-circle-info"></i>
                        <span>Espera a que el condensador cargue al 100% y pulsa la tecla <kbd>ESPACIO</kbd> o <kbd>CLIC</kbd> cuando la aguja cruce el marcador verde.</span>
                    </div>
                    <button class="btn-shock disabled" id="btnShock" disabled>
                        <i class="fa-solid fa-bolt"></i>
                        <span id="btnShockText">CARGANDO CONDENSADOR (0%)</span>
                    </button>
                </div>
            </div>
        `;

        this.canvas = document.getElementById('ecgCanvas');
        this.ctx = this.canvas.getContext('2d');
        this.statusText = document.getElementById('defibStatusText');
        this.statusBadge = document.getElementById('defibStatusBadge');
        this.needle = document.getElementById('defibNeedle');
        this.sweetSpot = document.getElementById('defibSweetSpot');
        this.btnShock = document.getElementById('btnShock');
        this.btnShockText = document.getElementById('btnShockText');
        this.shocksCounter = document.getElementById('shocksCounter');
        this.rhythmText = document.getElementById('rhythmText');
        this.timerEl = document.getElementById('defibTimer');

        // Configurar posición del Sweet Spot (entre 40% y 60%)
        this.targetPhase = 0.50;
        this.sweetSpot.style.left = `${(this.targetPhase - (this.config.shockTolerance / 2)) * 100}%`;
        this.sweetSpot.style.width = `${this.config.shockTolerance * 100}%`;
    }

    initCanvas() {
        this.ecgPoints = [];
        for (let i = 0; i < 580; i++) {
            this.ecgPoints.push(90);
        }
    }

    bindEvents() {
        this.onKeyDown = (e) => {
            if (e.code === 'Space' || e.key === ' ') {
                e.preventDefault();
                this.triggerShock();
            }
        };

        this.onClick = (e) => {
            if (this.state === 'ready') {
                this.triggerShock();
            }
        };

        window.addEventListener('keydown', this.onKeyDown);
        if (this.btnShock) this.btnShock.addEventListener('click', this.onClick);
    }

    startCharging() {
        this.state = 'charging';
        this.chargeProgress = 0;
        if (this.btnShock) {
            this.btnShock.classList.add('disabled');
            this.btnShock.disabled = true;
        }

        const chargeSteps = 50;
        const stepTime = (this.config.chargeDuration * 1000) / chargeSteps;
        let step = 0;

        const chargeInterval = setInterval(() => {
            if (this.isDestroyed || this.state === 'failed' || this.state === 'success') {
                clearInterval(chargeInterval);
                return;
            }

            step++;
            this.chargeProgress = Math.min(100, Math.floor((step / chargeSteps) * 100));

            if (this.btnShockText) {
                this.btnShockText.textContent = `CARGANDO (${this.chargeProgress}%)`;
            }

            if (step >= chargeSteps) {
                clearInterval(chargeInterval);
                this.setReadyState();
            }
        }, stepTime);
    }

    setReadyState() {
        if (this.isDestroyed) return;
        this.state = 'ready';

        if (this.statusText) {
            this.statusText.textContent = "¡DESCARGA LISTA - DESPEJEN!";
            this.statusBadge.classList.add('ready-pulse');
        }

        if (this.btnShock) {
            this.btnShock.classList.remove('disabled');
            this.btnShock.classList.add('active-shock');
            this.btnShock.disabled = false;
            this.btnShockText.innerHTML = `<i class="fa-solid fa-bolt"></i> ¡DESCARGAR AHORA!`;
        }
    }

    startLoop() {
        // Temporizador de cuenta atrás
        this.intervalId = setInterval(() => {
            if (this.isDestroyed) return;
            this.timer--;
            if (this.timerEl) this.timerEl.textContent = `${this.timer}s`;

            if (this.timer <= 0) {
                this.fail('Tiempo límite expirado. Parada cardiaca irreversible.');
            }
        }, 1000);

        let lastTime = performance.now();
        const loop = (now) => {
            if (this.isDestroyed) return;
            const delta = (now - lastTime) / 1000;
            lastTime = now;

            this.update(delta);
            this.render();

            this.animFrameId = requestAnimationFrame(loop);
        };

        this.animFrameId = requestAnimationFrame(loop);
    }

    update(delta) {
        // Actualizar fase del cursor (oscila de 0 a 1 y de vuelta)
        const speed = 1.35;
        this.currentPhase = (this.currentPhase + (delta * speed)) % 1.0;

        const leftPercent = Math.abs(Math.sin(this.currentPhase * Math.PI)) * 100;
        if (this.needle) {
            this.needle.style.left = `${leftPercent}%`;
        }

        // Desplazar puntos ECG
        this.ecgOffset += delta * 60;
    }

    render() {
        if (!this.ctx) return;
        const width = this.canvas.width;
        const height = this.canvas.height;
        const midY = height / 2;

        this.ctx.clearRect(0, 0, width, height);

        // Dibujar onda ECG
        this.ctx.beginPath();
        this.ctx.strokeStyle = this.state === 'success' ? '#00ff9d' : '#ff007f';
        this.ctx.lineWidth = 2.5;
        this.ctx.shadowBlur = 12;
        this.ctx.shadowColor = this.state === 'success' ? '#00ff9d' : '#ff007f';

        const t = performance.now() * 0.005;

        for (let x = 0; x < width; x++) {
            let y = midY;
            if (this.state === 'success') {
                // Ritmo sinusal normal
                const cycle = (x + t * 40) % 140;
                if (cycle > 60 && cycle < 66) y = midY - 18; // Onda P
                else if (cycle >= 66 && cycle < 72) y = midY + 12; // Q
                else if (cycle >= 72 && cycle < 82) y = midY - 70; // Pico R
                else if (cycle >= 82 && cycle < 90) y = midY + 30; // S
                else if (cycle >= 100 && cycle < 120) y = midY - 24; // T
            } else {
                // Fibrilación ventricular caótica
                y = midY + Math.sin((x * 0.08) + t * 4) * 28 + Math.cos((x * 0.16) - t * 6) * 16 + (Math.random() * 8 - 4);
            }

            if (x === 0) this.ctx.moveTo(x, y);
            else this.ctx.lineTo(x, y);
        }

        this.ctx.stroke();
    }

    triggerShock() {
        if (this.state !== 'ready' || this.isDestroyed) return;

        const currentPos = Math.abs(Math.sin(this.currentPhase * Math.PI));
        const diff = Math.abs(currentPos - this.targetPhase);

        if (diff <= (this.config.shockTolerance / 2) + 0.04) {
            // ¡Descarga exitosa sincronizada!
            this.shocksCompleted++;
            if (this.shocksCounter) this.shocksCounter.textContent = `${this.shocksCompleted} / ${this.config.requiredShocks}`;

            if (this.shocksCompleted >= this.config.requiredShocks) {
                this.success();
            } else {
                // Requiere otra descarga para estabilización completa
                this.state = 'charging';
                if (this.statusText) this.statusText.textContent = "¡RITMO MEJORANDO! PREPARANDO 2ª DESCARGA...";
                this.startCharging();
            }
        } else {
            // Fallo de sincronización
            this.fail('Descarga asincrónica fallida. El ritmo cardiaco no respondió.');
        }
    }

    success() {
        this.state = 'success';
        if (this.statusText) this.statusText.textContent = "¡RITMO SINUSAL RESTABLECIDO!";
        if (this.rhythmText) {
            this.rhythmText.textContent = "SINUSAL NORMAL 75 BPM";
            this.rhythmText.className = "val text-cyan";
        }
        if (this.btnShock) {
            this.btnShock.className = "btn-shock success";
            this.btnShock.innerHTML = `<i class="fa-solid fa-check"></i> ¡PACIENTE ESTABILIZADO!`;
        }

        setTimeout(() => {
            this.finish(true);
        }, 1500);
    }

    fail(reason) {
        this.state = 'failed';
        if (this.statusText) this.statusText.textContent = reason || "DESCARGA FALLIDA";
        if (this.btnShock) {
            this.btnShock.className = "btn-shock failed";
            this.btnShock.innerHTML = `<i class="fa-solid fa-xmark"></i> FALLO CARDIACO`;
        }

        setTimeout(() => {
            this.finish(false);
        }, 1500);
    }

    finish(success) {
        this.destroy();
        if (typeof this.config.onFinish === 'function') {
            this.config.onFinish(success);
        }
    }

    destroy() {
        this.isDestroyed = true;
        if (this.animFrameId) cancelAnimationFrame(this.animFrameId);
        if (this.intervalId) clearInterval(this.intervalId);
        window.removeEventListener('keydown', this.onKeyDown);
    }
}

window.DefibrillatorGame = DefibrillatorGame;
