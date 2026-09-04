// ============================================================================
// AURA MINIGAMES: 1. MECHANICAL TUMBLER PIN LOCKPICK
// Realistic physical cross-section cylinder with tactile shear line physics
// ============================================================================

class LockpickGame {
    constructor(container, options = {}) {
        this.container = container;
        this.pinCount = options.pins || 4;
        this.durability = options.durability || 100;
        this.maxDurability = this.durability;
        this.tolerance = options.tolerance || 0.09; // Margen equilibrado y accesible (~9%)
        this.onFinish = options.onFinish || (() => {});

        this.currentPinIndex = 0; // Pin actual sobre el que está la ganzúa
        this.pickX = 0;           // Posición horizontal de la ganzúa
        this.pickY = 0;           // Elevación de la ganzúa (0.0 a 1.0)
        this.isCompleted = false;
        this.isBroken = false;
        this.lastOversetSound = 0;

        this.pins = [];
        this.keysPressed = {};
        this.animationFrame = null;

        this.init();
    }

    init() {
        this.container.innerHTML = `
            <div class="minigame-card lockpick-card">
                <div class="minigame-header">
                    <div class="header-tag">
                        <span class="pulse-dot"></span>
                        <span class="tag-text">CERRAJERÍA TÁCTIL // BOMBÍN DE ALTA SEGURIDAD</span>
                    </div>
                    <div class="durability-box">
                        <span class="durability-label">INTEGRIDAD GANZÚA:</span>
                        <div class="durability-bar-container">
                            <div id="lockpick-durability-bar" class="durability-bar" style="width: 100%;"></div>
                        </div>
                        <span id="lockpick-durability-text" class="durability-num">100%</span>
                    </div>
                </div>

                <div class="lock-viewport">
                    <!-- Línea de corte / Shear line -->
                    <div class="shear-line-guide">
                        <div class="shear-line-label">LÍNEA DE CORTE (SHEAR LINE)</div>
                    </div>

                    <!-- Contenedor de cámaras de pernos -->
                    <div class="chambers-track" id="chambers-track"></div>

                    <!-- Representación visual de la ganzúa -->
                    <div class="pick-tool" id="pick-tool">
                        <div class="pick-tip"></div>
                        <div class="pick-shaft"></div>
                    </div>

                    <!-- Rotor del cilindro -->
                    <div class="cylinder-core-backdrop" id="cylinder-core"></div>
                </div>

                <div class="minigame-footer">
                    <div class="controls-hint">
                        <span class="badge">[A / D]</span> Seleccionar Perno
                        <span class="badge" style="margin-left: 10px;">[W]</span> Elevar Perno
                        <span class="badge" style="margin-left: 10px; border-color: #FF007F; color: #fff; background: rgba(255, 0, 127, 0.25);">[ESPACIO] Asentar Perno</span>
                        <span class="badge" style="margin-left: 10px;">[ESC]</span> Cancelar
                    </div>
                    <div class="status-indicator" id="lockpick-status">
                        Usa [W] para elevar el perno 1 y busca su punto de fricción...
                    </div>
                </div>
            </div>
        `;

        this.chambersTrack = this.container.querySelector('#chambers-track');
        this.pickToolEl = this.container.querySelector('#pick-tool');
        this.cylinderCore = this.container.querySelector('#cylinder-core');
        this.durabilityBar = this.container.querySelector('#lockpick-durability-bar');
        this.durabilityText = this.container.querySelector('#lockpick-durability-text');
        this.statusText = this.container.querySelector('#lockpick-status');

        this.generatePins();
        this.bindEvents();
        this.renderPick();
        this.startLoop();
    }

    generatePins() {
        this.pins = [];
        this.chambersTrack.innerHTML = '';

        for (let i = 0; i < this.pinCount; i++) {
            // Cada perno tiene una altura de corte aleatoria entre 0.30 y 0.78
            const sweetSpot = 0.30 + (Math.random() * 0.48);

            const chamberEl = document.createElement('div');
            chamberEl.className = 'pin-chamber';
            chamberEl.id = `chamber-${i}`;

            chamberEl.innerHTML = `
                <div class="pin-spring"></div>
                <div class="driver-pin" id="driver-${i}"></div>
                <div class="shear-gap"></div>
                <div class="key-pin" id="key-${i}"></div>
                <div class="pin-number">${i + 1}</div>
            `;

            this.chambersTrack.appendChild(chamberEl);

            this.pins.push({
                index: i,
                sweetSpot: sweetSpot,
                isSet: false,
                currentHeight: 0.0,
                overSet: false,
                driverEl: chamberEl.querySelector(`#driver-${i}`),
                keyEl: chamberEl.querySelector(`#key-${i}`),
                chamberEl: chamberEl
            });
        }
    }

    bindEvents() {
        this.keyDownHandler = (e) => {
            const key = e.key.toLowerCase();
            this.keysPressed[key] = true;

            if (e.key === 'Escape') {
                this.finish(false);
            }

            // [ESPACIO]: Acción de Tensión y Fijación manual del perno
            if (e.key === ' ' || key === 'spacebar') {
                e.preventDefault();
                this.attemptSetPin();
            }
        };

        this.keyUpHandler = (e) => {
            this.keysPressed[e.key.toLowerCase()] = false;
        };

        window.addEventListener('keydown', this.keyDownHandler);
        window.addEventListener('keyup', this.keyUpHandler);

        // Clic de ratón en el viewport también asienta el perno
        const viewport = this.container.querySelector('.lock-viewport');
        this.clickHandler = (e) => {
            if (e.button === 0) {
                this.attemptSetPin();
            }
        };
        viewport.addEventListener('mousedown', this.clickHandler);
    }

    startLoop() {
        const loop = () => {
            if (this.isCompleted || this.isBroken) return;
            this.update();
            this.animationFrame = requestAnimationFrame(loop);
        };
        this.animationFrame = requestAnimationFrame(loop);
    }

    update() {
        // Movimiento horizontal entre pines
        if (this.keysPressed['a'] || this.keysPressed['arrowleft']) {
            if (!this.keysPressed._leftLocked && this.currentPinIndex > 0) {
                this.currentPinIndex--;
                this.keysPressed._leftLocked = true;
                this.pickY = 0.0;
                SoundFX.playBeep(400, 0.04);
            }
        } else {
            this.keysPressed._leftLocked = false;
        }

        if (this.keysPressed['d'] || this.keysPressed['arrowright']) {
            if (!this.keysPressed._rightLocked && this.currentPinIndex < this.pinCount - 1) {
                this.currentPinIndex++;
                this.keysPressed._rightLocked = true;
                this.pickY = 0.0;
                SoundFX.playBeep(450, 0.04);
            }
        } else {
            this.keysPressed._rightLocked = false;
        }

        // Elevación vertical con [W] o Flecha Arriba (ESPACIO asienta el perno)
        const wantsLift = this.keysPressed['w'] || this.keysPressed['arrowup'];
        const activePin = this.pins[this.currentPinIndex];

        if (!activePin.isSet) {
            const diff = Math.abs(this.pickY - activePin.sweetSpot);

            if (wantsLift) {
                // Elevación controlada: fricción táctil al entrar en la línea de corte para facilitar el enganche
                let liftSpeed = 0.015;
                if (diff <= this.tolerance) {
                    liftSpeed = 0.007; // Desaceleración en zona de corte ("tacto mecánico")
                }
                this.pickY = Math.min(1.0, this.pickY + liftSpeed);
            } else {
                // Descenso suave con retención ligera si roza la línea de corte
                let fallSpeed = 0.024;
                if (diff <= this.tolerance) {
                    fallSpeed = 0.012;
                }
                this.pickY = Math.max(0.0, this.pickY - fallSpeed);
            }

            activePin.currentHeight = this.pickY;

            // Análisis de posición respecto a la línea de corte (Shear Line)
            const currentDiff = Math.abs(activePin.currentHeight - activePin.sweetSpot);

            if (currentDiff <= this.tolerance) {
                // DENTRO DE LA VENTANA DE CORTE (Sweet Spot)
                if (!activePin.nearSoundPlayed) {
                    SoundFX.playBeep(520, 0.04);
                    activePin.nearSoundPlayed = true;
                }
                activePin.overSet = false;
                activePin.chamberEl.classList.remove('pin-over');
                activePin.chamberEl.classList.add('pin-near');
                this.statusText.innerHTML = `<span style="color: #40E0D0; font-weight: bold;">🎯 ¡Punto de corte localizado! Pulsa [ESPACIO] para asentar el perno.</span>`;
            } else if (activePin.currentHeight > activePin.sweetSpot + this.tolerance) {
                // SOBRE-EMPUJE (OVER-SET) -> Se pasa de largo
                activePin.nearSoundPlayed = false;
                activePin.overSet = true;
                activePin.chamberEl.classList.remove('pin-near');
                activePin.chamberEl.classList.add('pin-over');

                // Daño moderado y tolerable (permite reaccionar y soltar W sin romper instantáneamente)
                this.damagePick(0.07);

                const now = Date.now();
                if (now - this.lastOversetSound > 450) {
                    SoundFX.playSpringTension();
                    this.lastOversetSound = now;
                }

                this.statusText.innerHTML = `<span style="color: #FF007F; font-weight: bold;">⚠️ SOBRE-EMPUJE: Suelta [W] para volver al punto de corte.</span>`;
            } else {
                // Por debajo del punto de corte
                activePin.nearSoundPlayed = false;
                activePin.overSet = false;
                activePin.chamberEl.classList.remove('pin-over', 'pin-near');
                this.statusText.innerHTML = `Elevando perno ${activePin.index + 1}... Siente la resistencia en la línea de corte.`;
            }
        } else {
            // Perno ya fijado
            this.statusText.innerHTML = `<span style="color: #40E0D0;">Perno ${activePin.index + 1} fijado. Pulsa [D] para pasar al siguiente.</span>`;
        }

        this.renderPick();
        this.renderChambers();
    }

    attemptSetPin() {
        if (this.isCompleted || this.isBroken) return;
        const activePin = this.pins[this.currentPinIndex];
        if (activePin.isSet) return;

        const diff = Math.abs(activePin.currentHeight - activePin.sweetSpot);

        if (diff <= this.tolerance) {
            // ¡ASENTAMIENTO EXITOSO!
            activePin.isSet = true;
            activePin.currentHeight = activePin.sweetSpot;
            activePin.chamberEl.classList.remove('pin-near', 'pin-over');
            activePin.chamberEl.classList.add('pin-set');
            SoundFX.playPinClick();

            this.statusText.innerHTML = `<span style="color: #40E0D0; font-weight: bold;">¡CLIC! Perno ${activePin.index + 1} encajado en la línea de corte.</span>`;
            
            // Avanzar automáticamente al siguiente perno que no esté fijado
            setTimeout(() => {
                const nextUnset = this.pins.findIndex((p, idx) => idx > this.currentPinIndex && !p.isSet);
                if (nextUnset !== -1) {
                    this.currentPinIndex = nextUnset;
                    this.pickY = 0.0;
                }
            }, 300);

            this.checkVictory();
        } else {
            // ¡FALLO DE TENSIÓN! Tensión en falso sin reiniciar pernos ya completados
            SoundFX.playSpringTension();

            if (activePin.currentHeight > activePin.sweetSpot + this.tolerance) {
                // Sobre-empuje
                this.damagePick(6);
                this.statusText.innerHTML = `<span style="color: #FF007F; font-weight: bold;">¡TENSIÓN EN SOBRE-EMPUJE! Ajusta la altura a la línea de corte.</span>`;
            } else {
                // Demasiado bajo
                this.damagePick(4);
                this.statusText.innerHTML = `<span style="color: #f59e0b; font-weight: bold;">Tensión en falso: el perno está por debajo del punto de corte.</span>`;
            }
        }
    }

    damagePick(amount) {
        this.durability = Math.max(0, this.durability - amount);
        const pct = Math.round((this.durability / this.maxDurability) * 100);
        this.durabilityBar.style.width = `${pct}%`;
        this.durabilityText.textContent = `${pct}%`;

        if (pct < 30) {
            this.durabilityBar.style.background = 'linear-gradient(90deg, #FF007F, #ff4444)';
        }

        if (this.durability <= 0) {
            this.breakPick();
        }
    }

    breakPick() {
        this.isBroken = true;
        SoundFX.playLockpickBreak();
        this.statusText.innerHTML = `<span style="color: #FF007F; font-weight: bold; font-size: 1.1rem;">¡GANZÚA FRACTURADA! Cerrajería fallida.</span>`;
        this.container.querySelector('.minigame-card').classList.add('glitch-shake');

        setTimeout(() => {
            this.finish(false);
        }, 1200);
    }

    checkVictory() {
        const allSet = this.pins.every(p => p.isSet);
        if (allSet) {
            this.isCompleted = true;
            SoundFX.playLockCylinderTurn();
            this.cylinderCore.classList.add('cylinder-unlocked');
            this.statusText.innerHTML = `<span style="color: #40E0D0; font-weight: bold; font-size: 1.15rem;">¡CILINDRO DESBLOQUEADO // ACCESO AUTORIZADO!</span>`;

            setTimeout(() => {
                SoundFX.playSuccess();
                this.finish(true);
            }, 1000);
        }
    }

    renderPick() {
        if (!this.pickToolEl) return;
        const chamberWidth = 100 / this.pinCount;
        const targetXPercent = (this.currentPinIndex * chamberWidth) + (chamberWidth / 2);

        this.pickToolEl.style.left = `${targetXPercent}%`;
        const liftPx = this.pickY * 95; // 95px de recorrido
        this.pickToolEl.style.transform = `translate(-50%, -${liftPx}px)`;
    }

    renderChambers() {
        this.pins.forEach((p) => {
            const liftPx = p.currentHeight * 80;
            // El perno de la llave sube
            p.keyEl.style.transform = `translateY(-${liftPx}px)`;
            // El contraperno superior se retrae hacia arriba
            p.driverEl.style.transform = `translateY(-${liftPx}px)`;
        });
    }

    finish(success) {
        if (this.animationFrame) {
            cancelAnimationFrame(this.animationFrame);
        }
        window.removeEventListener('keydown', this.keyDownHandler);
        window.removeEventListener('keyup', this.keyUpHandler);

        if (this.onFinish) {
            this.onFinish(success);
        }
    }

    destroy() {
        if (this.animationFrame) {
            cancelAnimationFrame(this.animationFrame);
        }
        window.removeEventListener('keydown', this.keyDownHandler);
        window.removeEventListener('keyup', this.keyUpHandler);
        this.container.innerHTML = '';
    }
}
