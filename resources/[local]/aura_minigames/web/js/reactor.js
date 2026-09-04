// ============================================================================
// AURA MINIGAMES: 3. CHEMICAL REACTION STABILIZER (THERMODYNAMICS)
// Clandestine meth lab reactor with pressure, heat, and lethal explosion risk
// ============================================================================

class ChemicalReactorGame {
    constructor(container, options = {}) {
        this.container = container;
        this.totalDuration = options.duration || 18; // 18 segundos de ciclo de síntesis
        this.criticalTimeLimit = options.criticalTimeLimit || 3.0; // 3 seg en zona roja antes de reventar
        this.onFinish = options.onFinish || (() => {});

        // Estado termodinámico
        this.pressure = 65.0; // PSI (Zona segura: 45 - 90, Crítica: > 115)
        this.temperature = 155.0; // °C (Zona segura: 130 - 190, Crítica: > 240)
        this.progress = 0.0; // 0.0 a 1.0 (Progreso de la síntesis)
        this.criticalTime = 0.0; // Tiempo acumulado en zona crítica

        this.catalystBoost = 1.0;
        this.isCompleted = false;
        this.isExploded = false;

        this.keysPressed = {};
        this.animationFrame = null;
        this.alarmInterval = null;

        this.init();
    }

    init() {
        this.container.innerHTML = `
            <div class="minigame-card reactor-card">
                <div class="minigame-header">
                    <div class="header-tag">
                        <span class="pulse-dot"></span>
                        <span class="tag-text">LABORATORIO CLANDESTINO // CONTROL TERMODINÁMICO DEL REACTOR</span>
                    </div>
                    <div class="reactor-status-badge" id="reactor-hazard-badge">
                        ESTADO: ESTABLE
                    </div>
                </div>

                <!-- Progreso general de la reacción / Pureza -->
                <div class="reactor-synthesis-box">
                    <div class="synthesis-header">
                        <span class="synthesis-title">PUREZA DE LA SÍNTESIS QUÍMICA:</span>
                        <span class="synthesis-pct" id="synthesis-pct">0.0%</span>
                    </div>
                    <div class="synthesis-track">
                        <div id="synthesis-fill" class="synthesis-bar" style="width: 0%;"></div>
                    </div>
                </div>

                <div class="reactor-gauges-grid">
                    <!-- Manómetro de Presión -->
                    <div class="gauge-card" id="card-pressure">
                        <div class="gauge-header">
                            <span class="gauge-name">PRESIÓN INTERNA</span>
                            <span class="gauge-reading" id="txt-pressure">65.0 PSI</span>
                        </div>
                        <div class="gauge-bar-vertical-wrap">
                            <div class="safe-zone-marker marker-pressure">
                                <span class="marker-text">ZONA SEGURA (45-90 PSI)</span>
                            </div>
                            <div class="danger-zone-marker">PELIGRO (>115 PSI)</div>
                            <div id="gauge-pressure-fill" class="gauge-fill-vertical" style="height: 45%;"></div>
                        </div>
                        <div class="gauge-sub">Límite de ruptura: 130 PSI</div>
                    </div>

                    <!-- Núcleo de Destilación Animado -->
                    <div class="reactor-vessel-container">
                        <div class="vessel-flask">
                            <div class="flask-liquid" id="flask-liquid"></div>
                            <div class="flask-bubbles" id="flask-bubbles"></div>
                        </div>
                        <div class="overload-warning-text" id="overload-warning">
                            ⚠️ ADVERTENCIA: PARÁMETROS CRÍTICOS ⚠️
                        </div>
                    </div>

                    <!-- Termómetro del Núcleo -->
                    <div class="gauge-card" id="card-temp">
                        <div class="gauge-header">
                            <span class="gauge-name">TEMPERATURA NÚCLEO</span>
                            <span class="gauge-reading" id="txt-temp">155.0 °C</span>
                        </div>
                        <div class="gauge-bar-vertical-wrap">
                            <div class="safe-zone-marker marker-temp">
                                <span class="marker-text">ZONA SEGURA (130-190 °C)</span>
                            </div>
                            <div class="danger-zone-marker">FUSIÓN (>240 °C)</div>
                            <div id="gauge-temp-fill" class="gauge-fill-vertical" style="height: 50%;"></div>
                        </div>
                        <div class="gauge-sub">Punto de ignición: 270 °C</div>
                    </div>
                </div>

                <!-- Válvulas de control interactivas -->
                <div class="reactor-valves-panel">
                    <button class="valve-btn" id="btn-purge">
                        <div class="valve-key">[Q]</div>
                        <div class="valve-info">
                            <span class="valve-name">PURGA DE GAS</span>
                            <span class="valve-desc">-18 PSI | -4 °C</span>
                        </div>
                    </button>

                    <button class="valve-btn" id="btn-cryo">
                        <div class="valve-key">[W]</div>
                        <div class="valve-info">
                            <span class="valve-name">INYECCIÓN CRIOGÉNICA</span>
                            <span class="valve-desc">-22 °C | -6 PSI</span>
                        </div>
                    </button>

                    <button class="valve-btn" id="btn-catalyst">
                        <div class="valve-key">[E]</div>
                        <div class="valve-info">
                            <span class="valve-name">CATALIZADOR ACELERADOR</span>
                            <span class="valve-desc">+Velocidad | +Calor</span>
                        </div>
                    </button>
                </div>

                <div class="minigame-footer">
                    <div class="controls-hint">
                        <span class="badge">[Q] Purga</span>
                        <span class="badge" style="margin-left: 8px;">[W] Criogénico</span>
                        <span class="badge" style="margin-left: 8px;">[E] Catalizador</span>
                        <span class="badge" style="margin-left: 8px;">[ESC] Salir</span>
                    </div>
                    <div class="status-indicator" id="reactor-status">
                        Mantén ambos indicadores dentro de las zonas seguras hasta completar la cristalización...
                    </div>
                </div>
            </div>
        `;

        this.synthesisFill = this.container.querySelector('#synthesis-fill');
        this.synthesisPct = this.container.querySelector('#synthesis-pct');
        this.txtPressure = this.container.querySelector('#txt-pressure');
        this.txtTemp = this.container.querySelector('#txt-temp');
        this.fillPressure = this.container.querySelector('#gauge-pressure-fill');
        this.fillTemp = this.container.querySelector('#gauge-temp-fill');
        this.statusText = this.container.querySelector('#reactor-status');
        this.hazardBadge = this.container.querySelector('#reactor-hazard-badge');
        this.overloadWarning = this.container.querySelector('#overload-warning');
        this.flaskLiquid = this.container.querySelector('#flask-liquid');

        this.bindEvents();
        this.createBubbles();
        this.startLoop();
    }

    createBubbles() {
        const bubblesContainer = this.container.querySelector('#flask-bubbles');
        for (let i = 0; i < 15; i++) {
            const b = document.createElement('div');
            b.className = 'bubble';
            b.style.left = `${Math.random() * 85}%`;
            b.style.animationDuration = `${0.8 + Math.random() * 1.5}s`;
            b.style.animationDelay = `${Math.random() * 2}s`;
            bubblesContainer.appendChild(b);
        }
    }

    bindEvents() {
        this.keyDownHandler = (e) => {
            const key = e.key.toLowerCase();
            if (key === 'q') this.triggerPurge();
            if (key === 'w') this.triggerCryo();
            if (key === 'e') this.triggerCatalyst();
            if (e.key === 'Escape') this.finish(false);
        };

        window.addEventListener('keydown', this.keyDownHandler);

        // Clicks sobre botones
        this.container.querySelector('#btn-purge').addEventListener('click', () => this.triggerPurge());
        this.container.querySelector('#btn-cryo').addEventListener('click', () => this.triggerCryo());
        this.container.querySelector('#btn-catalyst').addEventListener('click', () => this.triggerCatalyst());
    }

    triggerPurge() {
        if (this.isCompleted || this.isExploded) return;
        this.pressure = Math.max(10, this.pressure - 18.0);
        this.temperature = Math.max(80, this.temperature - 4.0);
        SoundFX.playGasPurge();
        this.flashButton('#btn-purge');
    }

    triggerCryo() {
        if (this.isCompleted || this.isExploded) return;
        this.temperature = Math.max(80, this.temperature - 22.0);
        this.pressure = Math.max(10, this.pressure - 6.0);
        SoundFX.playCryoInjection();
        this.flashButton('#btn-cryo');
    }

    triggerCatalyst() {
        if (this.isCompleted || this.isExploded) return;
        this.catalystBoost = 2.2;
        this.temperature += 16.0;
        this.pressure += 14.0;
        SoundFX.playBeep(850, 0.08, 'sawtooth');
        this.flashButton('#btn-catalyst');

        setTimeout(() => {
            this.catalystBoost = 1.0;
        }, 1800);
    }

    flashButton(selector) {
        const btn = this.container.querySelector(selector);
        if (btn) {
            btn.classList.add('btn-active-flash');
            setTimeout(() => btn.classList.remove('btn-active-flash'), 180);
        }
    }

    startLoop() {
        let lastTime = performance.now();

        const loop = (now) => {
            if (this.isCompleted || this.isExploded) return;
            const dt = (now - lastTime) / 1000;
            lastTime = now;

            this.update(dt);
            this.animationFrame = requestAnimationFrame(loop);
        };
        this.animationFrame = requestAnimationFrame(loop);
    }

    update(dt) {
        // Exotermia espontánea: El reactor gana calor y presión de forma natural
        const heatRate = (7.5 + (Math.random() * 9.0)) * this.catalystBoost;
        this.temperature += heatRate * dt;

        // La presión responde al calentamiento del gas
        const pressureSpike = (this.temperature / 170.0) * (6.0 + Math.random() * 8.0);
        this.pressure += pressureSpike * dt;

        // Progreso de síntesis
        const progressSpeed = (1.0 / this.totalDuration) * this.catalystBoost;
        this.progress = Math.min(1.0, this.progress + (progressSpeed * dt));

        // Ratios para las barras visuales
        const pressurePct = Math.min(100, Math.max(0, (this.pressure / 140.0) * 100));
        const tempPct = Math.min(100, Math.max(0, ((this.temperature - 50) / 230.0) * 100));

        this.fillPressure.style.height = `${pressurePct}%`;
        this.fillTemp.style.height = `${tempPct}%`;

        this.txtPressure.textContent = `${this.pressure.toFixed(1)} PSI`;
        this.txtTemp.textContent = `${this.temperature.toFixed(1)} °C`;

        const synPct = (this.progress * 100).toFixed(1);
        this.synthesisFill.style.width = `${synPct}%`;
        this.synthesisPct.textContent = `${synPct}%`;

        // Evaluación de zonas de peligro
        const isPressureCritical = this.pressure > 115.0;
        const isTempCritical = this.temperature > 240.0;
        const isCritical = isPressureCritical || isTempCritical;

        if (isCritical) {
            this.criticalTime += dt;
            this.hazardBadge.textContent = 'PELIGRO DE FUSIÓN CRÍTICA';
            this.hazardBadge.className = 'reactor-status-badge badge-danger';
            this.overloadWarning.style.display = 'block';

            if (!this.alarmInterval) {
                this.alarmInterval = setInterval(() => {
                    if (this.isCompleted || this.isExploded) return;
                    SoundFX.playCriticalAlarm();
                }, 400);
            }

            const timeLeft = Math.max(0, this.criticalTimeLimit - this.criticalTime);
            this.statusText.innerHTML = `<span style="color: #FF007F; font-weight: bold;">🚨 SOBRECARGA CRÍTICA: ¡Purga presión o inyecta criogénico! Detonación en ${timeLeft.toFixed(1)}s</span>`;

            if (this.criticalTime >= this.criticalTimeLimit) {
                this.explodeReactor();
                return;
            }
        } else {
            this.criticalTime = Math.max(0, this.criticalTime - (dt * 1.5));
            this.hazardBadge.textContent = 'REACCIÓN EN EQUILIBRIO';
            this.hazardBadge.className = 'reactor-status-badge badge-safe';
            this.overloadWarning.style.display = 'none';

            if (this.alarmInterval) {
                clearInterval(this.alarmInterval);
                this.alarmInterval = null;
            }

            this.statusText.innerHTML = `Fase de cristalización en curso. Controla las válvulas de gas.`;
        }

        // Condición de éxito
        if (this.progress >= 1.0) {
            this.completeSynthesis();
        }
    }

    explodeReactor() {
        this.isExploded = true;
        if (this.alarmInterval) clearInterval(this.alarmInterval);

        SoundFX.playReactorExplosion();
        this.statusText.innerHTML = `<span style="color: #FF007F; font-weight: bold; font-size: 1.2rem;">💥 ¡RUPTURA DEL REACTOR! DETONACIÓN TÉRMICA INMINENTE</span>`;
        this.container.querySelector('.reactor-card').classList.add('glitch-shake', 'card-exploded');

        setTimeout(() => {
            this.finish(false);
        }, 1500);
    }

    completeSynthesis() {
        this.isCompleted = true;
        if (this.alarmInterval) clearInterval(this.alarmInterval);

        SoundFX.playSuccess();
        this.statusText.innerHTML = `<span style="color: #40E0D0; font-weight: bold; font-size: 1.15rem;">💎 ¡SÍNTESIS EXITOSA! METANFETAMINA PURIFICADA AL 99.4%</span>`;
        this.container.querySelector('.reactor-card').classList.add('pulse-success');

        setTimeout(() => {
            this.finish(true);
        }, 1200);
    }

    finish(success) {
        if (this.animationFrame) cancelAnimationFrame(this.animationFrame);
        if (this.alarmInterval) clearInterval(this.alarmInterval);

        window.removeEventListener('keydown', this.keyDownHandler);

        if (this.onFinish) {
            this.onFinish(success);
        }
    }

    destroy() {
        if (this.animationFrame) cancelAnimationFrame(this.animationFrame);
        if (this.alarmInterval) clearInterval(this.alarmInterval);

        window.removeEventListener('keydown', this.keyDownHandler);
        this.container.innerHTML = '';
    }
}
