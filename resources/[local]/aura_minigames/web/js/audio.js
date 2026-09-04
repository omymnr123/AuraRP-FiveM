// ============================================================================
// AURA MINIGAMES: REAL-TIME WEB AUDIO SYNTHESIZER
// High-fidelity, zero-latency procedural audio engine for FiveM NUI
// ============================================================================

const SoundFX = (() => {
    let ctx = null;
    let waveOscTarget = null;
    let waveOscPlayer = null;
    let waveGain = null;

    function getContext() {
        if (!ctx) {
            const AudioContext = window.AudioContext || window.webkitAudioContext;
            ctx = new AudioContext();
        }
        if (ctx.state === 'suspended') {
            ctx.resume();
        }
        return ctx;
    }

    return {
        init() {
            getContext();
        },

        // 1. Clic metálico de perno alcanzando la línea de corte (Shear Line)
        playPinClick() {
            const c = getContext();
            const now = c.currentTime;

            // Transitorio agudo (golpe de metal endurecido)
            const osc = c.createOscillator();
            const gain = c.createGain();
            osc.type = 'triangle';
            osc.frequency.setValueAtTime(2400, now);
            osc.frequency.exponentialRampToValueAtTime(800, now + 0.04);

            gain.gain.setValueAtTime(0.35, now);
            gain.gain.exponentialRampToValueAtTime(0.001, now + 0.045);

            osc.connect(gain);
            gain.connect(c.destination);

            osc.start(now);
            osc.stop(now + 0.05);

            // Resonancia metálica secundaria
            const osc2 = c.createOscillator();
            const gain2 = c.createGain();
            osc2.type = 'sine';
            osc2.frequency.setValueAtTime(4200, now);
            osc2.frequency.exponentialRampToValueAtTime(2800, now + 0.08);

            gain2.gain.setValueAtTime(0.2, now);
            gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.08);

            osc2.connect(gain2);
            gain2.connect(c.destination);

            osc2.start(now);
            osc2.stop(now + 0.09);
        },

        // Vibración elástica de perno fallido o sobrepresión
        playSpringTension() {
            const c = getContext();
            const now = c.currentTime;
            const osc = c.createOscillator();
            const gain = c.createGain();

            osc.type = 'sawtooth';
            osc.frequency.setValueAtTime(120, now);
            osc.frequency.linearRampToValueAtTime(80, now + 0.1);

            gain.gain.setValueAtTime(0.15, now);
            gain.gain.exponentialRampToValueAtTime(0.001, now + 0.1);

            osc.connect(gain);
            gain.connect(c.destination);

            osc.start(now);
            osc.stop(now + 0.11);
        },

        // Giro pesado del bombín al desbloquearse
        playLockCylinderTurn() {
            const c = getContext();
            const now = c.currentTime;

            // Clunk metálico grave
            const osc = c.createOscillator();
            const gain = c.createGain();
            osc.type = 'triangle';
            osc.frequency.setValueAtTime(180, now);
            osc.frequency.exponentialRampToValueAtTime(40, now + 0.35);

            gain.gain.setValueAtTime(0.6, now);
            gain.gain.exponentialRampToValueAtTime(0.001, now + 0.35);

            osc.connect(gain);
            gain.connect(c.destination);

            osc.start(now);
            osc.stop(now + 0.36);

            // Cascada de liberación mecánica
            setTimeout(() => this.playPinClick(), 40);
            setTimeout(() => this.playPinClick(), 120);
        },

        // Rotura de ganzúa por fatiga
        playLockpickBreak() {
            const c = getContext();
            const now = c.currentTime;

            const osc = c.createOscillator();
            const gain = c.createGain();
            osc.type = 'square';
            osc.frequency.setValueAtTime(3200, now);
            osc.frequency.exponentialRampToValueAtTime(120, now + 0.15);

            gain.gain.setValueAtTime(0.4, now);
            gain.gain.exponentialRampToValueAtTime(0.001, now + 0.15);

            osc.connect(gain);
            gain.connect(c.destination);

            osc.start(now);
            osc.stop(now + 0.16);
        },

        // 2. OSCILOSCOPIO ECU: Sintetizador de ondas en tiempo real
        startWaveLoop() {
            const c = getContext();
            if (waveOscTarget) return;

            const now = c.currentTime;
            waveGain = c.createGain();
            waveGain.gain.setValueAtTime(0.08, now);
            waveGain.connect(c.destination);

            // Onda objetivo ECU
            waveOscTarget = c.createOscillator();
            waveOscTarget.type = 'sine';
            waveOscTarget.frequency.setValueAtTime(220, now);
            waveOscTarget.connect(waveGain);
            waveOscTarget.start();

            // Onda de la ganzúa electrónica
            waveOscPlayer = c.createOscillator();
            waveOscPlayer.type = 'sine';
            waveOscPlayer.frequency.setValueAtTime(180, now);
            waveOscPlayer.connect(waveGain);
            waveOscPlayer.start();
        },

        updateWaveLoop(targetFreq, playerFreq, resonanceRatio) {
            if (!waveOscTarget || !ctx) return;
            const now = ctx.currentTime;

            // Escala de audio audible (100 Hz a 600 Hz)
            const f1 = 120 + targetFreq * 40;
            const f2 = 120 + playerFreq * 40;

            waveOscTarget.frequency.setTargetAtTime(f1, now, 0.05);
            waveOscPlayer.frequency.setTargetAtTime(f2, now, 0.05);

            // Cuanto más cerca de resonancia (1.0), más armónico y puro el volumen
            const vol = 0.04 + (resonanceRatio * 0.08);
            waveGain.gain.setTargetAtTime(vol, now, 0.05);
        },

        stopWaveLoop() {
            if (waveOscTarget) {
                try {
                    waveOscTarget.stop();
                    waveOscPlayer.stop();
                } catch (e) {}
                waveOscTarget = null;
                waveOscPlayer = null;
                waveGain = null;
            }
        },

        // Descarga de enlace de centralita completado (ignición)
        playECUSuccess() {
            this.stopWaveLoop();
            const c = getContext();
            const now = c.currentTime;

            const osc = c.createOscillator();
            const gain = c.createGain();
            osc.type = 'sawtooth';
            osc.frequency.setValueAtTime(80, now);
            osc.frequency.exponentialRampToValueAtTime(360, now + 0.4);

            gain.gain.setValueAtTime(0.4, now);
            gain.gain.exponentialRampToValueAtTime(0.001, now + 0.45);

            osc.connect(gain);
            gain.connect(c.destination);

            osc.start(now);
            osc.stop(now + 0.46);
        },

        // 3. REACTOR TERMOQUÍMICO: Purga de gas comprimido (White Noise)
        playGasPurge() {
            const c = getContext();
            const bufferSize = c.sampleRate * 0.4;
            const buffer = c.createBuffer(1, bufferSize, c.sampleRate);
            const data = buffer.getChannelData(0);

            for (let i = 0; i < bufferSize; i++) {
                data[i] = Math.random() * 2 - 1;
            }

            const noise = c.createBufferSource();
            noise.buffer = buffer;

            const filter = c.createBiquadFilter();
            filter.type = 'bandpass';
            filter.frequency.setValueAtTime(1400, c.currentTime);
            filter.Q.setValueAtTime(3.0, c.currentTime);

            const gain = c.createGain();
            gain.gain.setValueAtTime(0.25, c.currentTime);
            gain.gain.exponentialRampToValueAtTime(0.001, c.currentTime + 0.38);

            noise.connect(filter);
            filter.connect(gain);
            gain.connect(c.destination);

            noise.start();
        },

        // Inyección criogénica (Modulated High-Pass Noise)
        playCryoInjection() {
            const c = getContext();
            const bufferSize = c.sampleRate * 0.45;
            const buffer = c.createBuffer(1, bufferSize, c.sampleRate);
            const data = buffer.getChannelData(0);

            for (let i = 0; i < bufferSize; i++) {
                data[i] = Math.random() * 2 - 1;
            }

            const noise = c.createBufferSource();
            noise.buffer = buffer;

            const filter = c.createBiquadFilter();
            filter.type = 'highpass';
            filter.frequency.setValueAtTime(2800, c.currentTime);

            const gain = c.createGain();
            gain.gain.setValueAtTime(0.3, c.currentTime);
            gain.gain.exponentialRampToValueAtTime(0.001, c.currentTime + 0.42);

            noise.connect(filter);
            filter.connect(gain);
            gain.connect(c.destination);

            noise.start();
        },

        // Alarma urgente de sobrecalentamiento / sobrepresión del reactor
        playCriticalAlarm() {
            const c = getContext();
            const now = c.currentTime;

            const osc = c.createOscillator();
            const gain = c.createGain();
            osc.type = 'square';
            osc.frequency.setValueAtTime(880, now);
            osc.frequency.setValueAtTime(660, now + 0.1);

            gain.gain.setValueAtTime(0.2, now);
            gain.gain.exponentialRampToValueAtTime(0.001, now + 0.22);

            osc.connect(gain);
            gain.connect(c.destination);

            osc.start(now);
            osc.stop(now + 0.24);
        },

        // Explosión de fallo crítico del reactor
        playReactorExplosion() {
            const c = getContext();
            const now = c.currentTime;

            // Onda de choque grave
            const osc = c.createOscillator();
            const gain = c.createGain();
            osc.type = 'triangle';
            osc.frequency.setValueAtTime(140, now);
            osc.frequency.exponentialRampToValueAtTime(25, now + 0.9);

            gain.gain.setValueAtTime(0.7, now);
            gain.gain.exponentialRampToValueAtTime(0.001, now + 0.9);

            osc.connect(gain);
            gain.connect(c.destination);

            osc.start(now);
            osc.stop(now + 0.95);

            // Ruido de detonación
            const bufferSize = c.sampleRate * 0.8;
            const buffer = c.createBuffer(1, bufferSize, c.sampleRate);
            const data = buffer.getChannelData(0);
            for (let i = 0; i < bufferSize; i++) {
                data[i] = (Math.random() * 2 - 1) * Math.exp(-i / (c.sampleRate * 0.3));
            }

            const noise = c.createBufferSource();
            noise.buffer = buffer;
            const nGain = c.createGain();
            nGain.gain.setValueAtTime(0.5, now);
            nGain.gain.exponentialRampToValueAtTime(0.001, now + 0.8);

            noise.connect(nGain);
            nGain.connect(c.destination);
            noise.start(now);
        },

        // 4. CIPHER MATRIX & UI GENERAL
        playBeep(freq = 600, duration = 0.06, type = 'sine') {
            const c = getContext();
            const now = c.currentTime;
            const osc = c.createOscillator();
            const gain = c.createGain();

            osc.type = type;
            osc.frequency.setValueAtTime(freq, now);

            gain.gain.setValueAtTime(0.18, now);
            gain.gain.exponentialRampToValueAtTime(0.001, now + duration);

            osc.connect(gain);
            gain.connect(c.destination);

            osc.start(now);
            osc.stop(now + duration);
        },

        playSuccess() {
            const notes = [523.25, 659.25, 783.99, 1046.50]; // C5, E5, G5, C6
            notes.forEach((freq, idx) => {
                setTimeout(() => {
                    this.playBeep(freq, 0.12, 'triangle');
                }, idx * 75);
            });
        },

        playFailure() {
            const notes = [400, 320, 240, 160];
            notes.forEach((freq, idx) => {
                setTimeout(() => {
                    this.playBeep(freq, 0.15, 'sawtooth');
                }, idx * 90);
            });
        }
    };
})();
