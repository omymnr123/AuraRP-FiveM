// ============================================================================
// AURA MINIGAMES: 2. ECU WAVEFORM SYNCHRONIZER (OSCILLOSCOPE)
// Electronic bypass tool matching CAN-Bus sinusoidal frequencies
// ============================================================================

class ECUBypassGame {
    constructor(container, options = {}) {
        this.container = container;
        this.timeLimit = options.timeLimit || 35;
        this.syncHoldTime = options.syncHoldTime || 1.6; // 1.6s de sostenimiento armónico continuo
        this.tolerance = options.tolerance || 0.22;       // Tolerancia precisa y calibrada
        this.onFinish = options.onFinish || (() => {});

        this.remainingTime = this.timeLimit;
        this.syncProgress = 0.0; // 0.0 a 1.0
        this.isCompleted = false;
        this.isFailed = false;

        // Parámetros objetivo generados (valores ricos y desafiantes)
        this.targetFreq = Math.round((2.2 + (Math.random() * 2.6)) * 20) / 20;   // 2.20 a 4.80 Hz
        this.targetAmp = Math.round(35 + (Math.random() * 38));                   // 35 a 73 V
        this.targetPhase = Math.round((Math.random() * Math.PI * 1.8) * 20) / 20; // 0 a 5.65 rad

        // Parámetros iniciales del jugador (ganzúa electrónica)
        this.playerFreq = 1.20;
        this.playerAmp = 20;
        this.playerPhase = 0;

        this.timeOffset = 0;
        this.keysPressed = {};
        this.animationFrame = null;
        this.timerInterval = null;
        this.antiTamperOffset = 0;

        this.init();
    }

    init() {
        this.container.innerHTML = `
            <div class="minigame-card ecu-card">
                <div class="minigame-header">
                    <div class="header-tag">
                        <span class="pulse-dot"></span>
                        <span class="tag-text">BYPASS ELECTRÓNICO // ANALIZADOR DE ONDA ECU CAN-BUS</span>
                    </div>
                    <div class="ecu-timer-box">
                        <span class="timer-label">LÍMITE DE SEGURIDAD:</span>
                        <span id="ecu-timer" class="timer-num">${this.remainingTime.toFixed(1)}s</span>
                    </div>
                </div>

                <div class="oscilloscope-container">
                    <canvas id="ecu-canvas" class="oscilloscope-canvas" width="620" height="280"></canvas>
                    
                    <div class="oscilloscope-overlay">
                        <div class="legend">
                            <span class="legend-item target-legend"><span class="dot pink-dot"></span> SEÑAL ECU (OBJETIVO)</span>
                            <span class="legend-item player-legend"><span class="dot cyan-dot"></span> GANZÚA ELECTRÓNICA (SINTONIZADA)</span>
                        </div>
                        <div class="resonance-hud">
                            <span class="hud-title">ACOPLAMIENTO ARMÓNICO:</span>
                            <div class="resonance-bar-wrap">
                                <div id="resonance-fill" class="resonance-bar" style="width: 0%;"></div>
                            </div>
                            <span id="resonance-val" class="resonance-val">0%</span>
                        </div>
                    </div>
                </div>

                <div class="ecu-controls-panel">
                    <div class="dial-group" id="dial-group-freq">
                        <div class="dial-header">
                            <span class="dial-title">FRECUENCIA (Hz)</span>
                            <span class="dial-val" id="val-freq">1.20 Hz</span>
                        </div>
                        <input type="range" id="slider-freq" class="cyber-slider" min="1.0" max="6.0" step="0.05" value="1.20">
                        <div class="dial-hint" id="status-freq">[A] / [D] Sintonizar</div>
                    </div>

                    <div class="dial-group" id="dial-group-amp">
                        <div class="dial-header">
                            <span class="dial-title">AMPLITUD (V)</span>
                            <span class="dial-val" id="val-amp">20 V</span>
                        </div>
                        <input type="range" id="slider-amp" class="cyber-slider" min="15" max="85" step="1" value="20">
                        <div class="dial-hint" id="status-amp">[W] / [S] Sintonizar</div>
                    </div>

                    <div class="dial-group" id="dial-group-phase">
                        <div class="dial-header">
                            <span class="dial-title">FASE (θ)</span>
                            <span class="dial-val" id="val-phase">0.00 rad</span>
                        </div>
                        <input type="range" id="slider-phase" class="cyber-slider" min="0" max="6.28" step="0.05" value="0">
                        <div class="dial-hint" id="status-phase">[Q] / [E] Sintonizar</div>
                    </div>
                </div>

                <div class="minigame-footer">
                    <div class="controls-hint">
                        <span class="badge">[Q/E] [A/D] [W/S]</span> Ajustar Diales
                        <span class="badge" style="margin-left: 10px;">[RATÓN]</span> Arrastrar Controles
                        <span class="badge" style="margin-left: 10px;">[ESC]</span> Cancelar
                    </div>
                    <div class="status-indicator" id="ecu-status">
                        Sintoniza los diales siguiendo las flechas de guía de cada canal...
                    </div>
                </div>
            </div>
        `;

        this.canvas = this.container.querySelector('#ecu-canvas');
        this.ctx = this.canvas.getContext('2d');
        this.sliderFreq = this.container.querySelector('#slider-freq');
        this.sliderAmp = this.container.querySelector('#slider-amp');
        this.sliderPhase = this.container.querySelector('#slider-phase');

        this.valFreq = this.container.querySelector('#val-freq');
        this.valAmp = this.container.querySelector('#val-amp');
        this.valPhase = this.container.querySelector('#val-phase');

        this.dialGroupFreq = this.container.querySelector('#dial-group-freq');
        this.dialGroupAmp = this.container.querySelector('#dial-group-amp');
        this.dialGroupPhase = this.container.querySelector('#dial-group-phase');

        this.statusFreq = this.container.querySelector('#status-freq');
        this.statusAmp = this.container.querySelector('#status-amp');
        this.statusPhase = this.container.querySelector('#status-phase');

        this.resonanceFill = this.container.querySelector('#resonance-fill');
        this.resonanceVal = this.container.querySelector('#resonance-val');
        this.timerEl = this.container.querySelector('#ecu-timer');
        this.statusText = this.container.querySelector('#ecu-status');

        this.bindEvents();
        SoundFX.startWaveLoop();
        this.startTimer();
        this.startLoop();
    }

    bindEvents() {
        this.keyDownHandler = (e) => {
            this.keysPressed[e.key.toLowerCase()] = true;
            if (e.key === 'Escape') {
                this.finish(false);
            }
        };

        this.keyUpHandler = (e) => {
            this.keysPressed[e.key.toLowerCase()] = false;
        };

        window.addEventListener('keydown', this.keyDownHandler);
        window.addEventListener('keyup', this.keyUpHandler);

        // Sliders interactivos con ratón
        this.sliderFreq.addEventListener('input', (e) => {
            this.playerFreq = parseFloat(e.target.value);
            this.updateLabels();
        });
        this.sliderAmp.addEventListener('input', (e) => {
            this.playerAmp = parseFloat(e.target.value);
            this.updateLabels();
        });
        this.sliderPhase.addEventListener('input', (e) => {
            this.playerPhase = parseFloat(e.target.value);
            this.updateLabels();
        });
    }

    startTimer() {
        const intervalMs = 100;
        this.timerInterval = setInterval(() => {
            if (this.isCompleted || this.isFailed) return;
            this.remainingTime -= (intervalMs / 1000);
            if (this.remainingTime <= 0) {
                this.remainingTime = 0;
                this.failTimeout();
            }
            this.timerEl.textContent = `${this.remainingTime.toFixed(1)}s`;
            if (this.remainingTime < 8) {
                this.timerEl.classList.add('timer-danger');
            }
        }, intervalMs);
    }

    startLoop() {
        let lastTimestamp = performance.now();
        const loop = (currentTimestamp) => {
            if (this.isCompleted || this.isFailed) return;
            const dt = (currentTimestamp - lastTimestamp) / 1000;
            lastTimestamp = currentTimestamp;

            this.update(dt);
            this.draw();

            this.animationFrame = requestAnimationFrame(loop);
        };
        this.animationFrame = requestAnimationFrame(loop);
    }

    update(dt) {
        this.timeOffset += dt * 3.5;

        // Sensibilidad dinámica: amortiguación de precisión cerca del objetivo
        const baseSpeed = 2.4 * dt;
        const currentEffectiveTarget = this.targetFreq + (this.antiTamperOffset || 0);

        const freqDist = Math.abs(currentEffectiveTarget - this.playerFreq);
        const ampDist = Math.abs(this.targetAmp - this.playerAmp);
        let phaseDist = Math.abs(this.targetPhase - this.playerPhase);
        if (phaseDist > Math.PI) phaseDist = (Math.PI * 2) - phaseDist;

        // Damping fino cuando está cerca del objetivo para permitir ajuste milimétrico
        const freqDamp = (freqDist < 0.45) ? 0.55 : 1.0;
        const ampDamp = (ampDist < 9.0) ? 0.55 : 1.0;
        const phaseDamp = (phaseDist < 0.65) ? 0.55 : 1.0;

        // Control por teclado en tiempo real
        if (this.keysPressed['a']) {
            this.playerFreq = Math.max(1.0, this.playerFreq - (baseSpeed * 0.9 * freqDamp));
            this.sliderFreq.value = this.playerFreq;
        }
        if (this.keysPressed['d']) {
            this.playerFreq = Math.min(6.0, this.playerFreq + (baseSpeed * 0.9 * freqDamp));
            this.sliderFreq.value = this.playerFreq;
        }

        if (this.keysPressed['s']) {
            this.playerAmp = Math.max(15, this.playerAmp - (baseSpeed * 28 * ampDamp));
            this.sliderAmp.value = this.playerAmp;
        }
        if (this.keysPressed['w']) {
            this.playerAmp = Math.min(85, this.playerAmp + (baseSpeed * 28 * ampDamp));
            this.sliderAmp.value = this.playerAmp;
        }

        if (this.keysPressed['q']) {
            this.playerPhase = (this.playerPhase - (baseSpeed * 2.2 * phaseDamp) + (Math.PI * 2)) % (Math.PI * 2);
            this.sliderPhase.value = this.playerPhase;
        }
        if (this.keysPressed['e']) {
            this.playerPhase = (this.playerPhase + (baseSpeed * 2.2 * phaseDamp)) % (Math.PI * 2);
            this.sliderPhase.value = this.playerPhase;
        }

        // Micro-asistencia magnética suave (solo al estar muy alineado y sin pulsar teclas)
        const noKeys = !this.keysPressed['a'] && !this.keysPressed['d'] &&
                       !this.keysPressed['w'] && !this.keysPressed['s'] &&
                       !this.keysPressed['q'] && !this.keysPressed['e'];

        if (noKeys && freqDist < 0.05 && ampDist < 1.5 && phaseDist < 0.08) {
            this.playerFreq += (currentEffectiveTarget - this.playerFreq) * 5.0 * dt;
            this.playerAmp += (this.targetAmp - this.playerAmp) * 5.0 * dt;
            this.playerPhase += (this.targetPhase - this.playerPhase) * 5.0 * dt;
            this.sliderFreq.value = this.playerFreq;
            this.sliderAmp.value = this.playerAmp;
            this.sliderPhase.value = this.playerPhase;
        }

        // Contramedida anti-inmovilizador: al superar el 45% de resonancia, el CAN-Bus genera
        // una sutil fluctuación armónica que el jugador debe mantener compensada
        if (this.syncProgress >= 0.45) {
            const tamperFactor = Math.min(1.0, (this.syncProgress - 0.45) / 0.45);
            this.antiTamperOffset = Math.sin(this.timeOffset * 2.2) * (0.04 * tamperFactor);
        } else {
            this.antiTamperOffset = 0;
        }

        // Cálculo de disparidad final (post-ajuste)
        const effectiveFreqTarget = this.targetFreq + (this.antiTamperOffset || 0);
        const freqDiff = Math.abs(effectiveFreqTarget - this.playerFreq);
        const ampDiff = Math.abs(this.targetAmp - this.playerAmp);
        let phaseDiff = Math.abs(this.targetPhase - this.playerPhase);
        if (phaseDiff > Math.PI) phaseDiff = (Math.PI * 2) - phaseDiff;

        // Umbrales de tolerancia precisa calibrados
        const freqTol = 0.16;   // ±0.16 Hz
        const ampTol = 3.5;     // ±3.5 V
        const phaseTol = 0.22;  // ±0.22 rad

        const freqOk = freqDiff <= freqTol;
        const ampOk = ampDiff <= ampTol;
        const phaseOk = phaseDiff <= phaseTol;
        const allChannelsOk = freqOk && ampOk && phaseOk;

        // Normalización de error global
        const normFreqDiff = Math.min(1.0, freqDiff / 3.0);
        const normAmpDiff = Math.min(1.0, ampDiff / 40.0);
        const normPhaseDiff = Math.min(1.0, phaseDiff / Math.PI);

        const totalError = (normFreqDiff * 0.42) + (normAmpDiff * 0.33) + (normPhaseDiff * 0.25);
        const matchRatio = Math.max(0.0, 1.0 - (totalError / this.tolerance));

        // Actualizar interfaz y flechas directivas de 3 niveles
        this.updateLabels(freqDiff, ampDiff, phaseDiff);

        // Actualizar sintetizador de audio continuo
        SoundFX.updateWaveLoop(effectiveFreqTarget, this.playerFreq, matchRatio);

        // Progresión de resonancia armónica
        if (allChannelsOk && matchRatio >= 0.82) {
            this.syncProgress = Math.min(1.0, this.syncProgress + (dt / this.syncHoldTime));
            if (this.syncProgress >= 0.50) {
                this.statusText.innerHTML = `<span style="color: #40E0D0; font-weight: bold;">⚡ PROTOCOLO INMOVILIZADOR CAN-BUS: Estabilizando puente...</span>`;
            } else {
                this.statusText.innerHTML = `<span style="color: #40E0D0; font-weight: bold;">⚡ RESONANCIA DETECTADA: Sostén los diales acoplados...</span>`;
            }
        } else if (allChannelsOk && matchRatio >= 0.55) {
            // Cerca pero afinando
            this.statusText.innerHTML = `<span style="color: #FFD700; font-weight: bold;">⚠ SEÑAL PARCIAL: Afina los diales amarillos...</span>`;
        } else {
            // Fuera de rango: la barra decae
            this.syncProgress = Math.max(0.0, this.syncProgress - (dt * 0.70));
            this.statusText.innerHTML = `Sintoniza los diales siguiendo las flechas de guía de cada canal.`;
        }

        const pct = Math.round(this.syncProgress * 100);
        this.resonanceFill.style.width = `${pct}%`;
        this.resonanceVal.textContent = `${pct}%`;

        if (this.syncProgress >= 1.0) {
            this.completeBypass();
        }
    }

    updateLabels(freqDiff, ampDiff, phaseDiff) {
        this.valFreq.textContent = `${this.playerFreq.toFixed(2)} Hz`;
        this.valAmp.textContent = `${Math.round(this.playerAmp)} V`;
        this.valPhase.textContent = `${this.playerPhase.toFixed(2)} rad`;

        const effectiveTarget = this.targetFreq + (this.antiTamperOffset || 0);

        if (freqDiff === undefined) {
            freqDiff = Math.abs(effectiveTarget - this.playerFreq);
            ampDiff = Math.abs(this.targetAmp - this.playerAmp);
            phaseDiff = Math.abs(this.targetPhase - this.playerPhase);
            if (phaseDiff > Math.PI) phaseDiff = (Math.PI * 2) - phaseDiff;
        }

        const freqTol = 0.16;
        const ampTol = 3.5;
        const phaseTol = 0.22;

        // 1. Dial de Frecuencia (3 niveles: Desviado -> Calibrar fino -> Sintonizada)
        if (freqDiff <= freqTol) {
            this.dialGroupFreq.className = 'dial-group dial-locked';
            this.statusFreq.innerHTML = '✔ SINTONIZADA';
        } else if (freqDiff <= freqTol * 2.2) {
            this.dialGroupFreq.className = 'dial-group dial-tuning';
            this.statusFreq.innerHTML = this.playerFreq < effectiveTarget ? '▲ Calibrar fino [D]' : '▼ Calibrar fino [A]';
        } else {
            this.dialGroupFreq.className = 'dial-group';
            this.statusFreq.innerHTML = this.playerFreq < effectiveTarget ? '▲ Aumentar [D]' : '▼ Reducir [A]';
        }

        // 2. Dial de Amplitud
        if (ampDiff <= ampTol) {
            this.dialGroupAmp.className = 'dial-group dial-locked';
            this.statusAmp.innerHTML = '✔ SINTONIZADA';
        } else if (ampDiff <= ampTol * 2.2) {
            this.dialGroupAmp.className = 'dial-group dial-tuning';
            this.statusAmp.innerHTML = this.playerAmp < this.targetAmp ? '▲ Calibrar fino [W]' : '▼ Calibrar fino [S]';
        } else {
            this.dialGroupAmp.className = 'dial-group';
            this.statusAmp.innerHTML = this.playerAmp < this.targetAmp ? '▲ Subir [W]' : '▼ Bajar [S]';
        }

        // 3. Dial de Fase
        if (phaseDiff <= phaseTol) {
            this.dialGroupPhase.className = 'dial-group dial-locked';
            this.statusPhase.innerHTML = '✔ SINTONIZADA';
        } else if (phaseDiff <= phaseTol * 2.2) {
            this.dialGroupPhase.className = 'dial-group dial-tuning';
            this.statusPhase.innerHTML = this.playerPhase < this.targetPhase ? '► Calibrar fino [E]' : '◄ Calibrar fino [Q]';
        } else {
            this.dialGroupPhase.className = 'dial-group';
            this.statusPhase.innerHTML = this.playerPhase < this.targetPhase ? '► Avanzar [E]' : '◄ Retrasar [Q]';
        }
    }

    draw() {
        const w = this.canvas.width;
        const h = this.canvas.height;
        const midY = h / 2;

        this.ctx.clearRect(0, 0, w, h);

        // 1. Rejilla CRT de osciloscopio
        this.ctx.strokeStyle = 'rgba(64, 224, 208, 0.08)';
        this.ctx.lineWidth = 1;
        const gridSize = 28;
        for (let x = 0; x < w; x += gridSize) {
            this.ctx.beginPath();
            this.ctx.moveTo(x, 0);
            this.ctx.lineTo(x, h);
            this.ctx.stroke();
        }
        for (let y = 0; y < h; y += gridSize) {
            this.ctx.beginPath();
            this.ctx.moveTo(0, y);
            this.ctx.lineTo(w, y);
            this.ctx.stroke();
        }

        // Eje central
        this.ctx.strokeStyle = 'rgba(255, 255, 255, 0.15)';
        this.ctx.beginPath();
        this.ctx.moveTo(0, midY);
        this.ctx.lineTo(w, midY);
        this.ctx.stroke();

        const effectiveTarget = this.targetFreq + (this.antiTamperOffset || 0);

        // 2. Onda Objetivo ECU (Rosa Neón #FF007F)
        this.ctx.strokeStyle = '#FF007F';
        this.ctx.lineWidth = 2.5;
        this.ctx.shadowColor = '#FF007F';
        this.ctx.shadowBlur = 10;
        this.ctx.beginPath();

        for (let x = 0; x < w; x++) {
            const t = (x / w) * (Math.PI * 4);
            const y = midY + Math.sin((t * effectiveTarget) + this.targetPhase + this.timeOffset) * this.targetAmp;
            if (x === 0) this.ctx.moveTo(x, y);
            else this.ctx.lineTo(x, y);
        }
        this.ctx.stroke();

        // 3. Onda Jugador (Ganzúa Electrónica #40E0D0 / Fusión luminosa al sincronizar)
        if (this.syncProgress > 0.05) {
            this.ctx.strokeStyle = '#00ffff';
            this.ctx.shadowColor = '#00ffff';
            this.ctx.shadowBlur = 16;
            this.ctx.lineWidth = 3.2;
        } else {
            this.ctx.strokeStyle = '#40E0D0';
            this.ctx.shadowColor = '#40E0D0';
            this.ctx.shadowBlur = 10;
            this.ctx.lineWidth = 2.5;
        }
        this.ctx.beginPath();

        for (let x = 0; x < w; x++) {
            const t = (x / w) * (Math.PI * 4);
            const y = midY + Math.sin((t * this.playerFreq) + this.playerPhase + this.timeOffset) * this.playerAmp;
            if (x === 0) this.ctx.moveTo(x, y);
            else this.ctx.lineTo(x, y);
        }
        this.ctx.stroke();

        // 4. Descargas de arco eléctrico entre ambas señales durante el acoplamiento armónico
        if (this.syncProgress > 0.12) {
            this.ctx.strokeStyle = 'rgba(64, 224, 208, 0.6)';
            this.ctx.lineWidth = 1.2;
            const sparkCount = 3 + Math.floor(this.syncProgress * 5);
            for (let i = 0; i < sparkCount; i++) {
                const sx = Math.floor(Math.random() * w);
                const st = (sx / w) * (Math.PI * 4);
                const sy1 = midY + Math.sin((st * effectiveTarget) + this.targetPhase + this.timeOffset) * this.targetAmp;
                const sy2 = midY + Math.sin((st * this.playerFreq) + this.playerPhase + this.timeOffset) * this.playerAmp;
                if (Math.abs(sy1 - sy2) < 30) {
                    this.ctx.beginPath();
                    this.ctx.moveTo(sx, sy1);
                    this.ctx.lineTo(sx + (Math.random() * 6 - 3), (sy1 + sy2) / 2);
                    this.ctx.lineTo(sx, sy2);
                    this.ctx.stroke();
                }
            }
        }

        this.ctx.shadowBlur = 0;
    }

    completeBypass() {
        this.isCompleted = true;
        SoundFX.playECUSuccess();

        // Destello de acoplamiento completado
        this.statusText.innerHTML = `<span style="color: #40E0D0; font-weight: bold; font-size: 1.15rem;">⚡ ¡ECU DESVIADA // MOTOR CONECTADO Y EN LÍNEA!</span>`;
        this.container.querySelector('.oscilloscope-container').classList.add('pulse-success');

        setTimeout(() => {
            SoundFX.playSuccess();
            this.finish(true);
        }, 1100);
    }

    failTimeout() {
        this.isFailed = true;
        SoundFX.stopWaveLoop();
        SoundFX.playFailure();

        this.statusText.innerHTML = `<span style="color: #FF007F; font-weight: bold;">⛔ TIEMPO AGOTADO: CAN-Bus bloqueado por protocolo inmovilizador.</span>`;
        this.container.querySelector('.minigame-card').classList.add('glitch-shake');

        setTimeout(() => {
            this.finish(false);
        }, 1300);
    }

    finish(success) {
        SoundFX.stopWaveLoop();
        if (this.animationFrame) cancelAnimationFrame(this.animationFrame);
        if (this.timerInterval) clearInterval(this.timerInterval);

        window.removeEventListener('keydown', this.keyDownHandler);
        window.removeEventListener('keyup', this.keyUpHandler);

        if (this.onFinish) {
            this.onFinish(success);
        }
    }

    destroy() {
        SoundFX.stopWaveLoop();
        if (this.animationFrame) cancelAnimationFrame(this.animationFrame);
        if (this.timerInterval) clearInterval(this.timerInterval);

        window.removeEventListener('keydown', this.keyDownHandler);
        window.removeEventListener('keyup', this.keyUpHandler);
        this.container.innerHTML = '';
    }
}
