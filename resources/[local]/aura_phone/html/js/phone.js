const AuraPhoneApp = {
    currentCallNumber: null,
    callTimerInterval: null,
    callSeconds: 0,
    activeAudio: null,
    isMuted: false,
    isSpeakerOn: false,
    inCallDTMFDigits: "",

    stopActiveAudio: function() {
        if (this.activeAudio) {
            try {
                this.activeAudio.pause();
                this.activeAudio.currentTime = 0;
                this.activeAudio.src = "";
            } catch (e) {}
            this.activeAudio = null;
        }
    },

    playDTMFTone: function(digit) {
        const dtmfFreqs = {
            '1': [697, 1209], '2': [697, 1336], '3': [697, 1477],
            '4': [770, 1209], '5': [770, 1336], '6': [770, 1477],
            '7': [852, 1209], '8': [852, 1336], '9': [852, 1477],
            '*': [941, 1209], '0': [941, 1336], '#': [941, 1477]
        };
        const freqs = dtmfFreqs[digit];
        if (!freqs) return;

        try {
            const ctx = new (window.AudioContext || window.webkitAudioContext)();
            const osc1 = ctx.createOscillator();
            const osc2 = ctx.createOscillator();
            const gain = ctx.createGain();

            osc1.type = 'sine';
            osc2.type = 'sine';
            osc1.frequency.value = freqs[0];
            osc2.frequency.value = freqs[1];

            const vol = (window.AuraCore && AuraCore.settings && AuraCore.settings.volume_msg) ? (AuraCore.settings.volume_msg / 100) * 0.12 : 0.12;
            gain.gain.setValueAtTime(vol, ctx.currentTime);
            gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.12);

            osc1.connect(gain);
            osc2.connect(gain);
            gain.connect(ctx.destination);

            osc1.start();
            osc2.start();
            osc1.stop(ctx.currentTime + 0.12);
            osc2.stop(ctx.currentTime + 0.12);
            setTimeout(() => { ctx.close(); }, 200);
        } catch (e) {}
    },
    
    getHTML: function() {
        return `
            <div id="app-phone-window" class="app-window" style="background: var(--bg-dark);">
                <!-- Pantalla principal de la App (Tabs) -->
                <div id="phone-main-view" class="h-100">
                    <div class="app-header">
                        <span>Teléfono</span>
                    </div>
                    
                    <div class="phone-content">
                        <!-- Pestaña: Favoritos -->
                        <div id="phone-tab-favorites" class="phone-tab">
                            <div class="phone-list-container">
                                <div class="add-contact-header">
                                    <h2>Favoritos</h2>
                                </div>
                                <div id="favorites-list">
                                    <!-- Poblado por JS -->
                                </div>
                            </div>
                        </div>

                        <!-- Pestaña: Recientes -->
                        <div id="phone-tab-recents" class="phone-tab">
                            <div class="phone-list-container" id="recents-list">
                                <!-- Poblado por JS -->
                            </div>
                        </div>

                        <!-- Pestaña: Contactos -->
                        <div id="phone-tab-contacts" class="phone-tab">
                            <div class="phone-list-container">
                                <div class="add-contact-header">
                                    <h2>Contactos</h2>
                                    <button class="add-contact-btn" onclick="AuraPhoneApp.toggleAddContact()"><i class="fas fa-plus-circle"></i></button>
                                </div>
                                <div id="add-contact-form" class="add-contact-form hidden">
                                    <input type="text" id="new-contact-name" placeholder="Nombre completo">
                                    <input type="number" id="new-contact-number" placeholder="Número">
                                    <button onclick="AuraPhoneApp.addContact()">Guardar</button>
                                </div>
                                <div id="contacts-list">
                                    <!-- Poblado por JS -->
                                </div>
                            </div>
                        </div>

                        <!-- Pestaña: Teclado (Dialpad) -->
                        <div id="phone-tab-keypad" class="phone-tab active">
                            <div class="dial-display">
                                <h1 id="dial-number-text"></h1>
                                <p id="dial-status" class="dial-status-text"></p>
                            </div>
                            
                            <div class="dial-pad">
                                <div class="dial-row">
                                    <div class="dial-btn" onclick="AuraPhoneApp.addNumber('1')">1</div>
                                    <div class="dial-btn" onclick="AuraPhoneApp.addNumber('2')">2<span>ABC</span></div>
                                    <div class="dial-btn" onclick="AuraPhoneApp.addNumber('3')">3<span>DEF</span></div>
                                </div>
                                <div class="dial-row">
                                    <div class="dial-btn" onclick="AuraPhoneApp.addNumber('4')">4<span>GHI</span></div>
                                    <div class="dial-btn" onclick="AuraPhoneApp.addNumber('5')">5<span>JKL</span></div>
                                    <div class="dial-btn" onclick="AuraPhoneApp.addNumber('6')">6<span>MNO</span></div>
                                </div>
                                <div class="dial-row">
                                    <div class="dial-btn" onclick="AuraPhoneApp.addNumber('7')">7<span>PQRS</span></div>
                                    <div class="dial-btn" onclick="AuraPhoneApp.addNumber('8')">8<span>TUV</span></div>
                                    <div class="dial-btn" onclick="AuraPhoneApp.addNumber('9')">9<span>WXYZ</span></div>
                                </div>
                                <div class="dial-row">
                                    <div class="dial-btn" onclick="AuraPhoneApp.addNumber('*')">*</div>
                                    <div class="dial-btn" onclick="AuraPhoneApp.addNumber('0')">0<span>+</span></div>
                                    <div class="dial-btn" onclick="AuraPhoneApp.addNumber('#')">#</div>
                                </div>
                                <div class="dial-row dial-actions">
                                    <div class="dial-btn hidden-btn"></div>
                                    <div class="dial-btn call-btn" onclick="AuraPhoneApp.startCall()"><i class="fas fa-phone"></i></div>
                                    <div class="dial-btn backspace-btn" onclick="AuraPhoneApp.removeNumber()"><i class="fas fa-backspace"></i></div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Bottom Navigation -->
                    <div class="phone-bottom-nav">
                        <div class="nav-item" onclick="AuraPhoneApp.switchTab('favorites', this)"><i class="fas fa-star"></i><span>Favoritos</span></div>
                        <div class="nav-item" onclick="AuraPhoneApp.switchTab('recents', this)"><i class="fas fa-clock"></i><span>Recientes</span></div>
                        <div class="nav-item" onclick="AuraPhoneApp.switchTab('contacts', this)"><i class="fas fa-user-circle"></i><span>Contactos</span></div>
                        <div class="nav-item active" onclick="AuraPhoneApp.switchTab('keypad', this)"><i class="fas fa-th"></i><span>Teclado</span></div>
                    </div>
                </div>

                <!-- OVERLAY: Pantalla de Llamada Activa (Glassmorphism Fullscreen) -->
                <div id="active-call-overlay" class="call-overlay hidden">
                    <div class="call-overlay-bg"></div>
                    <div class="call-info">
                        <h2 id="call-contact-name">Desconocido</h2>
                        <p id="call-status">Llamando...</p>
                    </div>
                    
                    <!-- Vista 1: Grid de Acciones de Llamada -->
                    <div id="in-call-actions-view" class="call-actions-grid">
                        <div class="call-action-btn" id="call-btn-mute" onclick="AuraPhoneApp.toggleMute()"><i class="fas fa-microphone-slash"></i><span>Silenciar</span></div>
                        <div class="call-action-btn" id="call-btn-keypad" onclick="AuraPhoneApp.toggleInCallKeypad(true)"><i class="fas fa-th"></i><span>Teclado</span></div>
                        <div class="call-action-btn" id="call-btn-speaker" onclick="AuraPhoneApp.toggleSpeaker()"><i class="fas fa-volume-up"></i><span>Altavoz</span></div>
                    </div>

                    <!-- Vista 2: Teclado numérico durante la llamada (DTMF) -->
                    <div id="in-call-keypad-view" class="in-call-keypad-container hidden">
                        <div class="in-call-dtmf-display">
                            <span id="in-call-dtmf-digits"></span>
                        </div>
                        <div class="dial-pad in-call-dial-pad">
                            <div class="dial-row">
                                <div class="dial-btn" onclick="AuraPhoneApp.pressInCallDTMF('1')">1</div>
                                <div class="dial-btn" onclick="AuraPhoneApp.pressInCallDTMF('2')">2<span>ABC</span></div>
                                <div class="dial-btn" onclick="AuraPhoneApp.pressInCallDTMF('3')">3<span>DEF</span></div>
                            </div>
                            <div class="dial-row">
                                <div class="dial-btn" onclick="AuraPhoneApp.pressInCallDTMF('4')">4<span>GHI</span></div>
                                <div class="dial-btn" onclick="AuraPhoneApp.pressInCallDTMF('5')">5<span>JKL</span></div>
                                <div class="dial-btn" onclick="AuraPhoneApp.pressInCallDTMF('6')">6<span>MNO</span></div>
                            </div>
                            <div class="dial-row">
                                <div class="dial-btn" onclick="AuraPhoneApp.pressInCallDTMF('7')">7<span>PQRS</span></div>
                                <div class="dial-btn" onclick="AuraPhoneApp.pressInCallDTMF('8')">8<span>TUV</span></div>
                                <div class="dial-btn" onclick="AuraPhoneApp.pressInCallDTMF('9')">9<span>WXYZ</span></div>
                            </div>
                            <div class="dial-row">
                                <div class="dial-btn" onclick="AuraPhoneApp.pressInCallDTMF('*')">*</div>
                                <div class="dial-btn" onclick="AuraPhoneApp.pressInCallDTMF('0')">0<span>+</span></div>
                                <div class="dial-btn" onclick="AuraPhoneApp.pressInCallDTMF('#')">#</div>
                            </div>
                        </div>
                        <div class="in-call-hide-keypad-btn" onclick="AuraPhoneApp.toggleInCallKeypad(false)">
                            <span>Ocultar</span>
                        </div>
                    </div>

                    <div class="call-end-container">
                        <!-- Botón de aceptar (solo visible al recibir) -->
                        <div id="btn-accept-call" class="dial-btn accept-btn hidden" onclick="AuraPhoneApp.acceptCall()"><i class="fas fa-phone"></i></div>
                        <!-- Botón de colgar -->
                        <div id="btn-end-call" class="dial-btn end-btn" onclick="AuraPhoneApp.endCall()"><i class="fas fa-phone-slash"></i></div>
                    </div>
                </div>
            </div>
        `;
    },

    onOpen: function() {
        document.getElementById('dial-number-text').innerText = '';
        document.getElementById('dial-status').innerText = '';
    },

    addNumber: function(num) {
        this.playDTMFTone(num);
        const display = document.getElementById('dial-number-text');
        if (display.innerText.length < 15) {
            display.innerText += num;
        }
    },

    removeNumber: function() {
        const display = document.getElementById('dial-number-text');
        display.innerText = display.innerText.slice(0, -1);
    },

    // =========================================
    // ACCIONES EN LLAMADA: MUTE, ALTAVOZ, TECLADO
    // =========================================

    toggleMute: function() {
        this.isMuted = !this.isMuted;
        const btn = document.getElementById('call-btn-mute');
        if (btn) {
            if (this.isMuted) {
                btn.classList.add('active');
                btn.querySelector('span').innerText = 'Silenciado';
            } else {
                btn.classList.remove('active');
                btn.querySelector('span').innerText = 'Silenciar';
            }
        }
        fetch(`https://${GetParentResourceName()}/toggleMute`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ muted: this.isMuted })
        });
    },

    toggleSpeaker: function() {
        this.isSpeakerOn = !this.isSpeakerOn;
        const btn = document.getElementById('call-btn-speaker');
        if (btn) {
            if (this.isSpeakerOn) {
                btn.classList.add('active');
                btn.querySelector('span').innerText = 'Altavoz On';
            } else {
                btn.classList.remove('active');
                btn.querySelector('span').innerText = 'Altavoz';
            }
        }
        fetch(`https://${GetParentResourceName()}/toggleSpeaker`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ enabled: this.isSpeakerOn })
        });
    },

    toggleInCallKeypad: function(show) {
        const keypadView = document.getElementById('in-call-keypad-view');
        const actionsView = document.getElementById('in-call-actions-view');
        if (!keypadView || !actionsView) return;
        
        if (show === undefined) {
            show = keypadView.classList.contains('hidden');
        }

        if (show) {
            actionsView.classList.add('hidden');
            keypadView.classList.remove('hidden');
        } else {
            keypadView.classList.add('hidden');
            actionsView.classList.remove('hidden');
        }
    },

    pressInCallDTMF: function(digit) {
        this.playDTMFTone(digit);
        this.inCallDTMFDigits += digit;
        const display = document.getElementById('in-call-dtmf-digits');
        if (display) display.innerText = this.inCallDTMFDigits;
    },

    // Iniciar llamada (saliente)
    startCall: function() {
        const number = document.getElementById('dial-number-text').innerText;
        if (number.length < 3) return;

        // Limpiar estado
        document.getElementById('dial-status').innerText = "";
        
        // Abrir siempre la pantalla de llamada para dar realismo
        this.showActiveCallScreen(number, "Llamando...", true);
        
        fetch(`https://${GetParentResourceName()}/dialNumber`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ number: number })
        }).then(resp => resp.json()).then(data => {
            if (!data.success) {
                // Si el número no existe o está apagado, simulamos el fallo realista
                document.getElementById('call-status').innerText = data.message || "Número no disponible";
                
                // Reproducir el audio de la operadora si existe, SOLO si no hemos colgado
                if (data.audio && this.currentCallNumber === number) {
                    this.stopActiveAudio();
                    const audio = new Audio(`../audio/${data.audio}`);
                    const volume = (window.AuraCore && AuraCore.settings && AuraCore.settings.volume_ring) ? (AuraCore.settings.volume_ring / 100) : 0.5;
                    audio.volume = Math.max(0.1, Math.min(1.0, volume));
                    this.activeAudio = audio;
                    audio.play().catch(e => console.log("Error al reproducir audio:", e));
                    
                    // Cerrar la pantalla dinámicamente cuando el audio termine de hablar
                    audio.onended = () => {
                        this.stopActiveAudio();
                        if (this.currentCallNumber === number) {
                            this.hideActiveCallScreen();
                        }
                    };
                } else {
                    // Si por algún motivo falla el audio, fallback a temporizador
                    setTimeout(() => {
                        if (this.currentCallNumber === number) {
                            this.hideActiveCallScreen();
                        }
                    }, 4000);
                }
            }
        });
    },

    // Mostrar pantalla de llamada (overlay)
    showActiveCallScreen: function(numberOrName, statusText, isOutgoing) {
        this.currentCallNumber = numberOrName;
        document.getElementById('call-contact-name').innerText = numberOrName;
        document.getElementById('call-status').innerText = statusText;
        
        const overlay = document.getElementById('active-call-overlay');
        overlay.classList.remove('hidden');

        const btnAccept = document.getElementById('btn-accept-call');
        if (isOutgoing) {
            btnAccept.classList.add('hidden'); // No puedes aceptarte a ti mismo
        } else {
            btnAccept.classList.remove('hidden'); // Entrante: Muestra botón verde
        }
    },

    // Aceptar llamada entrante
    acceptCall: function() {
        this.stopActiveAudio();
        this.startTimer();
        const btnAccept = document.getElementById('btn-accept-call');
        if (btnAccept) btnAccept.classList.add('hidden');

        fetch(`https://${GetParentResourceName()}/acceptCall`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    },

    // Finalizar/Rechazar llamada
    endCall: function() {
        this.stopActiveAudio();
        this.hideActiveCallScreen();
        fetch(`https://${GetParentResourceName()}/endCall`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    },

    hideActiveCallScreen: function() {
        this.stopActiveAudio();
        
        // Resetear estados y vistas de llamada
        this.isMuted = false;
        this.isSpeakerOn = false;
        this.inCallDTMFDigits = "";
        
        const btnMute = document.getElementById('call-btn-mute');
        if (btnMute) {
            btnMute.classList.remove('active');
            const span = btnMute.querySelector('span');
            if (span) span.innerText = 'Silenciar';
        }
        
        const btnSpeaker = document.getElementById('call-btn-speaker');
        if (btnSpeaker) {
            btnSpeaker.classList.remove('active');
            const span = btnSpeaker.querySelector('span');
            if (span) span.innerText = 'Altavoz';
        }

        this.toggleInCallKeypad(false);

        const dtmfDisplay = document.getElementById('in-call-dtmf-digits');
        if (dtmfDisplay) dtmfDisplay.innerText = '';

        document.getElementById('active-call-overlay').classList.add('hidden');
        this.stopTimer();
        this.currentCallNumber = null;
        document.getElementById('dial-status').innerText = '';
    },

    startTimer: function() {
        this.callSeconds = 0;
        document.getElementById('call-status').innerText = "00:00";
        this.callTimerInterval = setInterval(() => {
            this.callSeconds++;
            const m = Math.floor(this.callSeconds / 60).toString().padStart(2, '0');
            const s = (this.callSeconds % 60).toString().padStart(2, '0');
            document.getElementById('call-status').innerText = `${m}:${s}`;
        }, 1000);
    },

    stopTimer: function() {
        if (this.callTimerInterval) {
            clearInterval(this.callTimerInterval);
            this.callTimerInterval = null;
        }
    },

    // Lógica de Tabs
    switchTab: function(tabName, el) {
        document.querySelectorAll('.phone-tab').forEach(t => t.classList.remove('active'));
        document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
        
        const targetTab = document.getElementById(`phone-tab-${tabName}`);
        if (targetTab) targetTab.classList.add('active');
        if (el) el.classList.add('active');

        if (tabName === 'favorites') this.fetchFavorites();
        if (tabName === 'recents') this.fetchRecents();
        if (tabName === 'contacts') this.fetchContacts();
    },

    // Iniciar llamada desde listas
    callDirect: function(number) {
        document.getElementById('dial-number-text').innerText = number;
        this.switchTab('keypad', document.querySelectorAll('.nav-item')[3]);
        this.startCall();
    },

    // Favoritos
    fetchFavorites: function() {
        fetch(`https://${GetParentResourceName()}/getFavorites`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).then(resp => resp.json()).then(data => {
            const list = document.getElementById('favorites-list');
            if (!list) return;
            list.innerHTML = '';
            
            if (!data || data.length === 0) {
                list.innerHTML = `
                    <div style="text-align:center; margin-top:40px; color:rgba(255,255,255,0.4); font-size:13px;">
                        <i class="fas fa-star" style="font-size:32px; display:block; margin-bottom:10px; color:#FFD700; opacity:0.3;"></i>
                        No tienes contactos favoritos.<br>Añade favoritos con la estrella en Contactos.
                    </div>
                `;
                return;
            }

            data.forEach(contact => {
                const initial = contact.contact_name.charAt(0).toUpperCase();
                list.innerHTML += `
                    <div class="list-item" onclick="AuraPhoneApp.callDirect('${contact.contact_number}')">
                        <div class="list-avatar" style="background: linear-gradient(135deg, #FFD700, #FFA500); color: black; font-weight: 800;">${initial}</div>
                        <div class="list-info">
                            <div class="list-name">${contact.contact_name}</div>
                            <div class="list-sub"><i class="fas fa-star" style="color:#FFD700; margin-right:4px;"></i> Móvil: ${contact.contact_number}</div>
                        </div>
                        <div class="list-right">
                            <i class="fas fa-phone" style="color:var(--primary-cyan); font-size:16px;"></i>
                        </div>
                    </div>
                `;
            });
        }).catch(err => {
            console.error("Error fetching favorites:", err);
        });
    },

    // Historial (Recientes)
    fetchRecents: function() {
        fetch(`https://${GetParentResourceName()}/getRecents`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).then(resp => resp.json()).then(data => {
            const list = document.getElementById('recents-list');
            list.innerHTML = '';
            data.forEach(call => {
                const isMissed = call.status === 'missed';
                const statusClass = isMissed ? 'status-missed' : 'status-answered';
                const icon = isMissed ? '<i class="fas fa-phone-slash"></i>' : (call.isOutgoing ? '<i class="fas fa-phone-alt"></i>' : '<i class="fas fa-phone"></i>');
                const displayName = call.contact_name || call.number;

                list.innerHTML += `
                    <div class="list-item" onclick="AuraPhoneApp.callDirect('${call.number}')">
                        <div class="list-avatar"><i class="fas fa-user"></i></div>
                        <div class="list-info">
                            <div class="list-name ${statusClass}">${displayName}</div>
                            <div class="list-sub">${icon} ${call.status === 'answered' ? call.duration + 's' : 'Perdida'}</div>
                        </div>
                        <div class="list-right">
                            ${new Date(call.created_at).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}
                        </div>
                    </div>
                `;
            });
        });
    },

    // Contactos
    fetchContacts: function() {
        fetch(`https://${GetParentResourceName()}/getContacts`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).then(resp => resp.json()).then(data => {
            const list = document.getElementById('contacts-list');
            if (!list) return;
            list.innerHTML = '';
            if (!data || data.length === 0) {
                list.innerHTML = '<div style="text-align:center; margin-top:30px; color:rgba(255,255,255,0.4);">No tienes contactos guardados</div>';
                return;
            }
            data.forEach(contact => {
                const initial = contact.contact_name.charAt(0).toUpperCase();
                const star = contact.is_favorite == 1 ? '<i class="fas fa-star" style="color:#FFD700; margin-left:auto; font-size:12px;"></i>' : '';
                list.innerHTML += `
                    <div class="list-item" onclick="AuraPhoneApp.callDirect('${contact.contact_number}')">
                        <div class="list-avatar">${initial}</div>
                        <div class="list-info">
                            <div class="list-name">${contact.contact_name}</div>
                            <div class="list-sub">${contact.contact_number}</div>
                        </div>
                        ${star}
                    </div>
                `;
            });
        });
    },

    toggleAddContact: function() {
        const form = document.getElementById('add-contact-form');
        form.classList.toggle('hidden');
    },

    addContact: function() {
        const name = document.getElementById('new-contact-name').value;
        const number = document.getElementById('new-contact-number').value;

        if (!name || !number) return;

        fetch(`https://${GetParentResourceName()}/addContact`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name: name, number: number })
        }).then(resp => resp.json()).then(data => {
            if (data.success) {
                document.getElementById('new-contact-name').value = '';
                document.getElementById('new-contact-number').value = '';
                this.toggleAddContact();
                this.fetchContacts();
            }
        });
    },

    // Recepción de eventos desde el cliente (Lua)
    handleIncomingEvent: function(action, data) {
        if (action === "incomingCall") {
            this.showActiveCallScreen(data.number, data.callerName || data.number || "Llamada Entrante", false);
        } else if (action === "callConnected") {
            this.startTimer();
            const btnAccept = document.getElementById('btn-accept-call');
            if (btnAccept) btnAccept.classList.add('hidden');
        } else if (action === "callEnded") {
            const statusEl = document.getElementById('call-status');
            if (statusEl) statusEl.innerText = data.reason || "Llamada finalizada";
            setTimeout(() => {
                this.hideActiveCallScreen();
            }, 1000);
        }
    }
};

// Escuchar NUI messages para enrutarlos a esta app
window.addEventListener('message', (event) => {
    const data = event.data;
    if (["incomingCall", "callConnected", "callEnded"].includes(data.action)) {
        AuraPhoneApp.handleIncomingEvent(data.action, data);
    }
});

window.AuraPhoneApp = AuraPhoneApp;
