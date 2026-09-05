// ============================================================================
// AURA MINIGAMES: 5. WEED PACKAGING & HERMETIC SEALER
// Precision digital scale dosage + vacuum thermal sealing minigame
// Theme: AuraRP Cyber Glassmorphism (Turquoise #40E0D0 to Neon Pink #FF007F)
// ============================================================================

class WeedPackagingGame {
    constructor(container, options = {}) {
        this.container = container;
        this.targetWeight = options.targetWeight || 28.00; // Gramos objetivo por bolsa
        this.weightTolerance = options.weightTolerance || 0.70; // Margen admisible ±0.70g
        this.requiredSeals = options.requiredSeals || 3; // Sellados térmicos requeridos
        this.timeLimit = options.timeLimit || 35; // Tiempo límite en segundos
        this.onFinish = options.onFinish || (() => {});

        // Estado de juego
        this.currentPhase = 1; // 1: Dosificación / Báscula, 2: Sellado Térmico
        this.currentWeight = 0.00;
        this.isAddingBuds = false;
        this.isRemovingBuds = false;
        this.isCalibrated = false;
        this.calibrationHoldTime = 0; // Tiempo sostenido en rango óptimo

        // Estado Fase 2 (Sellado térmico)
        this.completedSeals = 0;
        this.sealBarPos = 0; // 0 a 100 (%)
        this.sealBarDirection = 1;
        this.sealBarSpeed = options.sealSpeed || 1.1; // Velocidad de oscilación
        this.sealNodes = [25, 50, 75]; // Posiciones de los nodos de sellado en %
        this.nodeHit = [false, false, false];

        this.timeLeft = this.timeLimit;
        this.isFinished = false;

        this.animationFrame = null;
        this.timerInterval = null;
        this.boundKeyDown = this.handleKeyDown.bind(this);
        this.boundKeyUp = this.handleKeyUp.bind(this);

        this.init();
    }

    init() {
        this.container.innerHTML = `
            <div class="minigame-card weed-pkg-card">
                <!-- Encabezado AuraRP -->
                <div class="minigame-header">
                    <div class="header-tag">
                        <span class="pulse-dot"></span>
                        <span class="tag-text">DISPENSARIO CLANDESTINO // MESA DE PESAJE Y SELLADO HERMÉTICO</span>
                    </div>
                    <div class="weed-timer-badge" id="pkg-timer-badge">
                        TIEMPO: <span id="pkg-timer-text">${this.timeLeft}s</span>
                    </div>
                </div>

                <!-- Barra de Fases -->
                <div class="pkg-stepper">
                    <div class="pkg-step active" id="step-phase-1">
                        <span class="step-num">1</span>
                        <span class="step-label">PESAJE DE COGOLLOS (5x)</span>
                    </div>
                    <div class="step-divider"></div>
                    <div class="pkg-step" id="step-phase-2">
                        <span class="step-num">2</span>
                        <span class="step-label">SELLADO TÉRMICO AL VACÍO</span>
                    </div>
                </div>

                <!-- CONTENEDOR FASE 1: BÁSCULA DIGITAL DE PRECISIÓN -->
                <div id="phase-1-container" class="pkg-phase-body">
                    <div class="scale-section">
                        <div class="scale-display-card">
                            <div class="scale-header-row">
                                <span class="scale-brand">AURA PRECISION LAB-9000</span>
                                <span class="scale-target-tag">OBJETIVO: ${this.targetWeight.toFixed(2)}g (±${this.weightTolerance.toFixed(2)}g)</span>
                            </div>

                            <div class="scale-digital-screen">
                                <div class="digital-unit">NET WEIGHT</div>
                                <div class="digital-number" id="digital-weight-txt">0.00</div>
                                <div class="digital-grams">GRAMS (g)</div>
                            </div>

                            <!-- Barra visual de rango de tolerancia -->
                            <div class="scale-bar-track">
                                <div class="scale-safe-zone" style="left: 65%; width: 22%;">
                                    <span class="safe-zone-tag">ZONA ÓPTIMA</span>
                                </div>
                                <div class="scale-pointer" id="scale-pointer" style="left: 0%;"></div>
                            </div>

                            <div class="scale-status-feedback" id="scale-status-txt">
                                MANTÉN [ESPACIO] PARA DESMENUZAR Y AÑADIR COGOLLOS A LA BÁSCULA
                            </div>
                        </div>

                        <!-- Panel de Control e Interacción -->
                        <div class="scale-controls-grid">
                            <button type="button" class="btn-scale-action btn-add-buds" id="btn-add-buds">
                                <span class="btn-icon">🌿</span>
                                <span class="btn-text-main">AÑADIR COGOLLOS</span>
                                <span class="btn-key-hint">MANTENER [ESPACIO] / CLICK</span>
                            </button>

                            <button type="button" class="btn-scale-action btn-rem-buds" id="btn-rem-buds">
                                <span class="btn-icon">✂️</span>
                                <span class="btn-text-main">RETIRAR EXCESO</span>
                                <span class="btn-key-hint">MANTENER [A]</span>
                            </button>

                            <button type="button" class="btn-scale-action btn-lock-dose disabled" id="btn-lock-dose">
                                <span class="btn-icon">⚡</span>
                                <span class="btn-text-main">CONFIRMAR DOSIS</span>
                                <span class="btn-key-hint">[E] / CLICK</span>
                            </button>
                        </div>
                    </div>
                </div>

                <!-- CONTENEDOR FASE 2: SELLADORA TÉRMICA INDUSTRIAL -->
                <div id="phase-2-container" class="pkg-phase-body hidden">
                    <div class="sealer-section">
                        <div class="sealer-instructions">
                            <span class="pulse-dot-pink"></span>
                            <span>PULSA <strong class="key-accent">[ESPACIO]</strong> JUSTO CUANDO EL LÁSER TÉRMICO CRUCE CADA NODO DE SELLADO</span>
                        </div>

                        <div class="sealer-bag-mockup">
                            <div class="bag-top-zipper">
                                <!-- Track donde oscila el cabezal térmico -->
                                <div class="thermal-track" id="thermal-track">
                                    <div class="seal-target-node node-1" id="seal-node-0" style="left: 25%;">
                                        <span class="node-marker">1</span>
                                    </div>
                                    <div class="seal-target-node node-2" id="seal-node-1" style="left: 50%;">
                                        <span class="node-marker">2</span>
                                    </div>
                                    <div class="seal-target-node node-3" id="seal-node-2" style="left: 75%;">
                                        <span class="node-marker">3</span>
                                    </div>

                                    <!-- Cabezal láser oscilante -->
                                    <div class="thermal-laser-head" id="thermal-laser" style="left: 0%;">
                                        <div class="laser-beam"></div>
                                    </div>
                                </div>
                            </div>

                            <div class="bag-body-preview">
                                <div class="bag-label-aura">
                                    <div class="bag-logo">🌿 AURA CANNABIS 🌿</div>
                                    <div class="bag-sub">PURE ORGANIC WEED // 100% QUALITY</div>
                                    <div class="bag-seals-status" id="bag-seals-counter">SELLADOS AL VACÍO: 0 / 3</div>
                                </div>
                            </div>
                        </div>

                        <div class="sealer-footer-controls">
                            <button type="button" class="btn-seal-trigger" id="btn-seal-trigger">
                                <span>🔥 APLICAR SELLADO TÉRMICO ([ESPACIO] / CLICK)</span>
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Pie Informativo -->
                <div class="pkg-footer">
                    <span class="footer-tip">Receta: 5x Cogollos de Marihuana + 1x Bolsita Hermética ➔ 1x Marihuana Envasada</span>
                    <span class="footer-esc">[ESC] Cancelar</span>
                </div>
            </div>
        `;

        this.bindEvents();
        this.startTimer();
        this.startLoop();
    }

    bindEvents() {
        window.addEventListener('keydown', this.boundKeyDown);
        window.addEventListener('keyup', this.boundKeyUp);

        // Botones interactivos Fase 1
        const btnAdd = document.getElementById('btn-add-buds');
        const btnRem = document.getElementById('btn-rem-buds');
        const btnLock = document.getElementById('btn-lock-dose');

        if (btnAdd) {
            btnAdd.addEventListener('mousedown', () => { this.isAddingBuds = true; });
            btnAdd.addEventListener('mouseup', () => { this.isAddingBuds = false; });
            btnAdd.addEventListener('mouseleave', () => { this.isAddingBuds = false; });
            btnAdd.addEventListener('touchstart', (e) => { e.preventDefault(); this.isAddingBuds = true; });
            btnAdd.addEventListener('touchend', (e) => { e.preventDefault(); this.isAddingBuds = false; });
        }

        if (btnRem) {
            btnRem.addEventListener('mousedown', () => { this.isRemovingBuds = true; });
            btnRem.addEventListener('mouseup', () => { this.isRemovingBuds = false; });
            btnRem.addEventListener('mouseleave', () => { this.isRemovingBuds = false; });
        }

        if (btnLock) {
            btnLock.addEventListener('click', () => {
                if (this.isCalibrated) {
                    this.advanceToPhase2();
                }
            });
        }

        // Botón interactivo Fase 2
        const btnSeal = document.getElementById('btn-seal-trigger');
        if (btnSeal) {
            btnSeal.addEventListener('click', () => {
                this.attemptThermalSeal();
            });
        }
    }

    handleKeyDown(e) {
        if (this.isFinished) return;

        if (e.code === 'Space') {
            e.preventDefault();
            if (this.currentPhase === 1) {
                this.isAddingBuds = true;
            } else if (this.currentPhase === 2) {
                this.attemptThermalSeal();
            }
        } else if (e.code === 'KeyA') {
            e.preventDefault();
            if (this.currentPhase === 1) {
                this.isRemovingBuds = true;
            }
        } else if (e.code === 'KeyE') {
            e.preventDefault();
            if (this.currentPhase === 1 && this.isCalibrated) {
                this.advanceToPhase2();
            }
        }
    }

    handleKeyUp(e) {
        if (e.code === 'Space') {
            if (this.currentPhase === 1) {
                this.isAddingBuds = false;
            }
        } else if (e.code === 'KeyA') {
            if (this.currentPhase === 1) {
                this.isRemovingBuds = false;
            }
        }
    }

    startTimer() {
        this.timerInterval = setInterval(() => {
            if (this.isFinished) return;
            this.timeLeft--;

            const timerText = document.getElementById('pkg-timer-text');
            if (timerText) {
                timerText.textContent = `${this.timeLeft}s`;
            }

            if (this.timeLeft <= 0) {
                this.finish(false, '¡Tiempo agotado! Proceso de empaquetado cancelado.');
            }
        }, 1000);
    }

    startLoop() {
        const loop = () => {
            if (this.isFinished) return;

            if (this.currentPhase === 1) {
                this.updatePhase1();
            } else if (this.currentPhase === 2) {
                this.updatePhase2();
            }

            this.animationFrame = requestAnimationFrame(loop);
        };
        this.animationFrame = requestAnimationFrame(loop);
    }

    updatePhase1() {
        if (this.isAddingBuds) {
            // Curva suave de llenado
            this.currentWeight += 0.28 + (Math.random() * 0.12);
            if (this.currentWeight > 38.0) this.currentWeight = 38.0;
            if (Math.random() < 0.3) SoundFX.playBeep(450, 0.04, 'sine');
        }

        if (this.isRemovingBuds) {
            this.currentWeight -= 0.32;
            if (this.currentWeight < 0.0) this.currentWeight = 0.0;
            if (Math.random() < 0.2) SoundFX.playBeep(320, 0.04, 'sine');
        }

        const digitalWeight = document.getElementById('digital-weight-txt');
        const scalePointer = document.getElementById('scale-pointer');
        const statusTxt = document.getElementById('scale-status-txt');
        const btnLock = document.getElementById('btn-lock-dose');

        if (digitalWeight) {
            digitalWeight.textContent = this.currentWeight.toFixed(2);
        }

        // Mapeo a porcentaje visual (0g a 35g)
        const pct = Math.min(Math.max((this.currentWeight / 35.0) * 100, 0), 100);
        if (scalePointer) {
            scalePointer.style.left = `${pct}%`;
        }

        // Comprobación de peso óptimo
        const minValid = this.targetWeight - this.weightTolerance;
        const maxValid = this.targetWeight + this.weightTolerance;

        if (this.currentWeight >= minValid && this.currentWeight <= maxValid) {
            this.isCalibrated = true;
            this.calibrationHoldTime += 0.016;

            if (statusTxt) {
                statusTxt.innerHTML = `<span class="txt-optimal">✨ ¡PESO EXACTO (${this.currentWeight.toFixed(2)}g)! PULSA [E] O CONFIRMAR PARA SELLAR ✨</span>`;
            }
            if (btnLock) {
                btnLock.classList.remove('disabled');
                btnLock.classList.add('ready-pulse');
            }
            if (scalePointer) {
                scalePointer.classList.add('pointer-optimal');
            }
        } else {
            this.isCalibrated = false;
            this.calibrationHoldTime = 0;

            if (btnLock) {
                btnLock.classList.add('disabled');
                btnLock.classList.remove('ready-pulse');
            }
            if (scalePointer) {
                scalePointer.classList.remove('pointer-optimal');
            }

            if (statusTxt) {
                if (this.currentWeight < minValid) {
                    statusTxt.textContent = `FALTAN COGOLLOS (ACTUAL: ${this.currentWeight.toFixed(2)}g / META: ${this.targetWeight.toFixed(2)}g) — MANTÉN [ESPACIO]`;
                } else {
                    statusTxt.textContent = `⚠️ EXCESO DE PESO (${this.currentWeight.toFixed(2)}g) — MANTÉN [A] PARA RETIRAR`;
                }
            }
        }
    }

    advanceToPhase2() {
        this.currentPhase = 2;
        this.isAddingBuds = false;
        this.isRemovingBuds = false;

        SoundFX.playSuccess();

        const p1 = document.getElementById('phase-1-container');
        const p2 = document.getElementById('phase-2-container');
        const step1 = document.getElementById('step-phase-1');
        const step2 = document.getElementById('step-phase-2');

        if (p1) p1.classList.add('hidden');
        if (p2) p2.classList.remove('hidden');

        if (step1) {
            step1.classList.remove('active');
            step1.classList.add('completed');
        }
        if (step2) {
            step2.classList.add('active');
        }
    }

    updatePhase2() {
        // Movimiento oscilatorio del láser térmico
        this.sealBarPos += this.sealBarDirection * this.sealBarSpeed;

        if (this.sealBarPos >= 95) {
            this.sealBarPos = 95;
            this.sealBarDirection = -1;
        } else if (this.sealBarPos <= 5) {
            this.sealBarPos = 5;
            this.sealBarDirection = 1;
        }

        const laserHead = document.getElementById('thermal-laser');
        if (laserHead) {
            laserHead.style.left = `${this.sealBarPos}%`;
        }
    }

    attemptThermalSeal() {
        if (this.isFinished || this.currentPhase !== 2) return;

        // Tolerancia de acierto en el nodo (±6% del track)
        const hitTolerance = 6.5;
        let hitIndex = -1;

        for (let i = 0; i < this.sealNodes.length; i++) {
            if (!this.nodeHit[i]) {
                const dist = Math.abs(this.sealBarPos - this.sealNodes[i]);
                if (dist <= hitTolerance) {
                    hitIndex = i;
                    break;
                }
            }
        }

        if (hitIndex !== -1) {
            // Acierto en nodo
            this.nodeHit[hitIndex] = true;
            this.completedSeals++;

            SoundFX.playBeep(880 + (this.completedSeals * 220), 0.1, 'triangle');

            const nodeEl = document.getElementById(`seal-node-${hitIndex}`);
            if (nodeEl) {
                nodeEl.classList.add('sealed-success');
                nodeEl.innerHTML = '✔';
            }

            const counterEl = document.getElementById('bag-seals-counter');
            if (counterEl) {
                counterEl.innerHTML = `SELLADOS AL VACÍO: <span class="seal-accent">${this.completedSeals} / ${this.requiredSeals}</span>`;
            }

            // Destello térmico
            const track = document.getElementById('thermal-track');
            if (track) {
                track.classList.add('seal-flash');
                setTimeout(() => track.classList.remove('seal-flash'), 250);
            }

            if (this.completedSeals >= this.requiredSeals) {
                // Éxito total
                setTimeout(() => {
                    this.finish(true);
                }, 400);
            }
        } else {
            // Fallo de sellado térmico
            SoundFX.playFailure();
            const track = document.getElementById('thermal-track');
            if (track) {
                track.classList.add('seal-fail-flash');
                setTimeout(() => track.classList.remove('seal-fail-flash'), 300);
            }
        }
    }

    finish(success, message) {
        if (this.isFinished) return;
        this.isFinished = true;

        if (this.timerInterval) clearInterval(this.timerInterval);
        if (this.animationFrame) cancelAnimationFrame(this.animationFrame);

        if (success) {
            SoundFX.playSuccess();
        }

        setTimeout(() => {
            this.destroy();
            this.onFinish(success);
        }, success ? 700 : 300);
    }

    destroy() {
        this.isFinished = true;
        if (this.timerInterval) clearInterval(this.timerInterval);
        if (this.animationFrame) cancelAnimationFrame(this.animationFrame);
        window.removeEventListener('keydown', this.boundKeyDown);
        window.removeEventListener('keyup', this.boundKeyUp);
    }
}
