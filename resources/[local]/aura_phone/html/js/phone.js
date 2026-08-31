// Módulo aislado para la aplicación de Teléfono / Llamadas
const AuraPhoneApp = {
    currentCallNumber: null,
    callTimerInterval: null,
    callSeconds: 0,
    
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
                    
                    <div class="call-actions-grid">
                        <div class="call-action-btn"><i class="fas fa-microphone-slash"></i><span>Silenciar</span></div>
                        <div class="call-action-btn"><i class="fas fa-th"></i><span>Teclado</span></div>
                        <div class="call-action-btn"><i class="fas fa-volume-up"></i><span>Altavoz</span></div>
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
        const display = document.getElementById('dial-number-text');
        if (display.innerText.length < 15) {
            display.innerText += num;
        }
    },

    removeNumber: function() {
        const display = document.getElementById('dial-number-text');
        display.innerText = display.innerText.slice(0, -1);
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
                
                // Reproducir el audio de la operadora si existe
                if (data.audio) {
                    console.log("Intentando reproducir audio:", data.audio);
                    const audio = new Audio(`../audio/${data.audio}`);
                    audio.volume = 0.5;
                    audio.play().catch(e => console.log("Error al reproducir audio:", e));
                    
                    // Cerrar la pantalla dinámicamente cuando el audio termine de hablar
                    audio.onended = () => {
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
        fetch(`https://${GetParentResourceName()}/acceptCall`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
        document.getElementById('btn-accept-call').classList.add('hidden');
    },

    // Finalizar/Rechazar llamada
    endCall: function() {
        fetch(`https://${GetParentResourceName()}/endCall`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
        this.hideActiveCallScreen();
    },

    hideActiveCallScreen: function() {
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
            this.showActiveCallScreen(data.number, "Llamada Entrante", false);
        } else if (action === "callConnected") {
            this.startTimer();
            document.getElementById('btn-accept-call').classList.add('hidden');
        } else if (action === "callEnded") {
            document.getElementById('call-status').innerText = data.reason || "Llamada finalizada";
            setTimeout(() => {
                this.hideActiveCallScreen();
            }, 2000);
        }
    }
};

// Escuchar NUI messages para enrutarlos a esta app
window.addEventListener('message', (event) => {
    const data = event.data;
    if (["incomingCall", "callConnected", "callEnded"].includes(data.action)) {
        AuraPhoneApp.handleIncomingEvent(data.action, data);
        
        // Si hay una llamada entrante y el teléfono está cerrado, forzar apertura
        if (data.action === "incomingCall" && !AuraCore.isOpen) {
            AuraCore.openPhone();
            AuraCore.openApp('app-phone');
        }
    }
});

window.AuraPhoneApp = AuraPhoneApp;
