// ============================================================================
// AURA MINIGAMES: 4. HEX MATRIX DECRYPTER (BREACH PROTOCOL)
// Cybernetic memory matrix hack for encrypted terminals and safes
// ============================================================================

class CipherMatrixGame {
    constructor(container, options = {}) {
        this.container = container;
        this.gridSize = options.gridSize || 5; // 5x5
        this.bufferSize = options.bufferSize || 4;
        this.sequenceLength = options.sequenceLength || 3;
        this.timeLimit = options.timeLimit || 30;
        this.onFinish = options.onFinish || (() => {});

        this.remainingTime = this.timeLimit;
        this.buffer = [];
        this.matrix = [];
        this.targetSequence = [];

        // Modo de selección actual: 'row' o 'col'
        this.selectionMode = 'row';
        this.activeRow = 0;
        this.activeCol = 0;

        this.isCompleted = false;
        this.isFailed = false;
        this.timerInterval = null;

        this.hexTokens = ['1C', 'E9', '7A', 'BD', '55', 'FF'];

        this.init();
    }

    init() {
        this.generateData();

        this.container.innerHTML = `
            <div class="minigame-card cipher-card">
                <div class="minigame-header">
                    <div class="header-tag">
                        <span class="pulse-dot"></span>
                        <span class="tag-text">ACCESO CLANDESTINO // MATRIZ DE MEMORIA HEXADECIMAL</span>
                    </div>
                    <div class="cipher-timer-box">
                        <span class="timer-label">TIEMPO BÚFER:</span>
                        <span id="cipher-timer" class="timer-num">${this.remainingTime}s</span>
                    </div>
                </div>

                <div class="cipher-body">
                    <!-- Panel izquierdo: Matriz Hexadecimal -->
                    <div class="matrix-panel">
                        <div class="panel-subtitle">MATRIZ DE CÓDIGO VOLÁTIL</div>
                        <div class="hex-grid" id="hex-grid" style="grid-template-columns: repeat(${this.gridSize}, 1fr);"></div>
                    </div>

                    <!-- Panel derecho: Secuencia Objetivo & Memoria Búfer -->
                    <div class="target-panel">
                        <div class="panel-subtitle">SECUENCIA OBJETIVO</div>
                        <div class="sequence-list" id="target-sequence"></div>

                        <div class="panel-subtitle" style="margin-top: 25px;">MEMORIA BÚFER (<span id="buffer-count">0</span>/${this.bufferSize})</div>
                        <div class="buffer-slots" id="buffer-slots"></div>

                        <div class="cipher-guide-box">
                            <span class="guide-title">PROTOCOLO DE DESVÍO:</span>
                            <p class="guide-text">Selecciona pares hexadecimales alternando entre fila horizontal y columna vertical.</p>
                        </div>
                    </div>
                </div>

                <div class="minigame-footer">
                    <div class="controls-hint">
                        <span class="badge">[CLIC RATÓN]</span> Inyectar Token en Búfer
                        <span class="badge" style="margin-left: 10px;">[ESC]</span> Abortar
                    </div>
                    <div class="status-indicator" id="cipher-status">
                        Selecciona un par de la fila activa resaltada...
                    </div>
                </div>
            </div>
        `;

        this.gridEl = this.container.querySelector('#hex-grid');
        this.targetSeqEl = this.container.querySelector('#target-sequence');
        this.bufferSlotsEl = this.container.querySelector('#buffer-slots');
        this.bufferCountEl = this.container.querySelector('#buffer-count');
        this.timerEl = this.container.querySelector('#cipher-timer');
        this.statusText = this.container.querySelector('#cipher-status');

        this.renderTargetSequence();
        this.renderBuffer();
        this.renderMatrix();
        this.bindEvents();
        this.startTimer();
    }

    generateData() {
        this.matrix = [];
        for (let r = 0; r < this.gridSize; r++) {
            const row = [];
            for (let c = 0; c < this.gridSize; c++) {
                const randomToken = this.hexTokens[Math.floor(Math.random() * this.hexTokens.length)];
                row.push({
                    row: r,
                    col: c,
                    value: randomToken,
                    used: false
                });
            }
            this.matrix.push(row);
        }

        // Generar una secuencia objetivo resoluble garantizada
        this.targetSequence = [];
        let currR = 0;
        let currC = Math.floor(Math.random() * this.gridSize);
        let mode = 'row';

        for (let s = 0; s < this.sequenceLength; s++) {
            if (mode === 'row') {
                currC = Math.floor(Math.random() * this.gridSize);
                this.targetSequence.push(this.matrix[currR][currC].value);
                mode = 'col';
            } else {
                currR = Math.floor(Math.random() * this.gridSize);
                this.targetSequence.push(this.matrix[currR][currC].value);
                mode = 'row';
            }
        }
    }

    renderTargetSequence() {
        this.targetSeqEl.innerHTML = '';
        this.targetSequence.forEach((val) => {
            const item = document.createElement('div');
            item.className = 'target-token';
            item.textContent = val;
            this.targetSeqEl.appendChild(item);
        });
    }

    renderBuffer() {
        this.bufferSlotsEl.innerHTML = '';
        this.bufferCountEl.textContent = this.buffer.length;

        for (let i = 0; i < this.bufferSize; i++) {
            const slot = document.createElement('div');
            slot.className = 'buffer-slot';
            if (this.buffer[i]) {
                slot.textContent = this.buffer[i];
                slot.classList.add('slot-filled');
            } else {
                slot.textContent = '__';
            }
            this.bufferSlotsEl.appendChild(slot);
        }
    }

    renderMatrix() {
        this.gridEl.innerHTML = '';

        for (let r = 0; r < this.gridSize; r++) {
            for (let c = 0; c < this.gridSize; c++) {
                const cell = this.matrix[r][c];
                const btn = document.createElement('button');
                btn.className = 'hex-cell';
                btn.textContent = cell.value;
                btn.id = `cell-${r}-${c}`;

                if (cell.used) {
                    btn.classList.add('cell-used');
                    btn.disabled = true;
                } else {
                    // Verificar si está en la fila o columna activa
                    const isSelectable = (this.selectionMode === 'row' && r === this.activeRow) ||
                                         (this.selectionMode === 'col' && c === this.activeCol);

                    if (isSelectable) {
                        btn.classList.add('cell-selectable');
                        btn.addEventListener('click', () => this.selectCell(cell));
                    } else {
                        btn.classList.add('cell-dim');
                    }
                }

                this.gridEl.appendChild(btn);
            }
        }
    }

    selectCell(cell) {
        if (this.isCompleted || this.isFailed || cell.used) return;

        cell.used = true;
        this.buffer.push(cell.value);
        SoundFX.playBeep(520 + (this.buffer.length * 60), 0.08, 'sine');

        this.renderBuffer();

        // Comprobar si la secuencia objetivo coincide
        if (this.checkSequenceMatch()) {
            this.completeVictory();
            return;
        }

        // Comprobar si el búfer se llenó
        if (this.buffer.length >= this.bufferSize) {
            this.failBufferFull();
            return;
        }

        // Alternar modo de selección
        if (this.selectionMode === 'row') {
            this.selectionMode = 'col';
            this.activeCol = cell.col;
            this.statusText.innerHTML = `Columna <span style="color: #40E0D0;">${cell.col + 1}</span> activada. Elige el siguiente par vertical.`;
        } else {
            this.selectionMode = 'row';
            this.activeRow = cell.row;
            this.statusText.innerHTML = `Fila <span style="color: #FF007F;">${cell.row + 1}</span> activada. Elige el siguiente par horizontal.`;
        }

        this.renderMatrix();
    }

    checkSequenceMatch() {
        const bufferStr = this.buffer.join(' ');
        const targetStr = this.targetSequence.join(' ');
        return bufferStr.includes(targetStr);
    }

    startTimer() {
        this.timerInterval = setInterval(() => {
            if (this.isCompleted || this.isFailed) return;
            this.remainingTime--;
            this.timerEl.textContent = `${this.remainingTime}s`;

            if (this.remainingTime <= 5) {
                this.timerEl.classList.add('timer-danger');
                SoundFX.playBeep(800, 0.05, 'square');
            }

            if (this.remainingTime <= 0) {
                this.failTimeout();
            }
        }, 1000);
    }

    bindEvents() {
        this.keyDownHandler = (e) => {
            if (e.key === 'Escape') this.finish(false);
        };
        window.addEventListener('keydown', this.keyDownHandler);
    }

    completeVictory() {
        this.isCompleted = true;
        if (this.timerInterval) clearInterval(this.timerInterval);

        SoundFX.playSuccess();
        this.statusText.innerHTML = `<span style="color: #40E0D0; font-weight: bold; font-size: 1.15rem;">🔓 ¡SECUENCIA DESCIFRADA // VOLCADO DE MEMORIA EXITOSO!</span>`;
        this.container.querySelector('.cipher-card').classList.add('pulse-success');

        setTimeout(() => {
            this.finish(true);
        }, 1100);
    }

    failBufferFull() {
        this.isFailed = true;
        if (this.timerInterval) clearInterval(this.timerInterval);

        SoundFX.playFailure();
        this.statusText.innerHTML = `<span style="color: #FF007F; font-weight: bold;">⛔ DESBORDAMIENTO DE BÚFER: Secuencia no encontrada.</span>`;
        this.container.querySelector('.cipher-card').classList.add('glitch-shake');

        setTimeout(() => {
            this.finish(false);
        }, 1200);
    }

    failTimeout() {
        this.isFailed = true;
        if (this.timerInterval) clearInterval(this.timerInterval);

        SoundFX.playFailure();
        this.statusText.innerHTML = `<span style="color: #FF007F; font-weight: bold;">⛔ TIEMPO AGOTADO: Enlace cortado por firewall de seguridad.</span>`;
        this.container.querySelector('.cipher-card').classList.add('glitch-shake');

        setTimeout(() => {
            this.finish(false);
        }, 1200);
    }

    finish(success) {
        if (this.timerInterval) clearInterval(this.timerInterval);
        window.removeEventListener('keydown', this.keyDownHandler);

        if (this.onFinish) {
            this.onFinish(success);
        }
    }

    destroy() {
        if (this.timerInterval) clearInterval(this.timerInterval);
        window.removeEventListener('keydown', this.keyDownHandler);
        this.container.innerHTML = '';
    }
}
