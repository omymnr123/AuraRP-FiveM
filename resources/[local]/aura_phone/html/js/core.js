// Motor Principal de Aura OS V2
const AuraCore = {
    isOpen: false,
    activeAppId: null,
    settings: null,
    isLocked: false,
    enteredPin: "",
    notifications: [],
    activeTopBannerTimeout: null,
    currentTopNotif: null,
    activeIncomingCall: null,
    activeRingtoneInterval: null,
    peekNotifTimeout: null,
    isPeeking: false,

    init: function() {
        this.fetchSettings();
        this.renderHome();
        this.renderAppWindows();
        this.setupListeners();
        this.startClock();
        this.renderLockNotifications();
    },

    setupListeners: function() {
        // NUI Messages
        window.addEventListener('message', (event) => {
            const data = event.data;
            if (!data) return;

            if (data.action === "openPhone") {
                this.openPhone();
            } else if (data.action === "closePhone") {
                this.closePhone();
            } else if (data.action === "newNotification" || data.action === "testNotification") {
                this.addNotification(data.notification || data);
            } else if (data.action === "clearAllNotifications") {
                this.clearAllNotifications();
            } else if (data.action === "incomingCall" || data.action === "testIncomingCall") {
                this.handleIncomingCall(data);
            } else if (data.action === "callConnected" || data.action === "callAccepted") {
                this.stopRingtone();
            } else if (data.action === "callEnded") {
                this.handleCallEnded(data.reason);
            } else if (data.action === "acceptCallByKeyboard") {
                this.acceptIncomingCall();
            } else if (data.action === "declineCallByKeyboard") {
                this.declineIncomingCall();
            } else if (data.action === "newMessage") {
                this.addNotification({
                    app: 'messages',
                    title: data.sender_name || data.sender_number || "Mensaje Nuevo",
                    message: data.content || "Has recibido un mensaje",
                    icon: 'fas fa-comment',
                    color: '#25D366',
                    data: { number: data.sender_number, chat_id: data.chat_id }
                });
            }
        });

        // Eventos de teclado físicos
        document.addEventListener('keydown', (e) => {
            if (this.activeIncomingCall) {
                if (e.key === "Enter") {
                    e.preventDefault();
                    this.acceptIncomingCall();
                    return;
                } else if (e.key === "Backspace" || e.key === "Delete") {
                    e.preventDefault();
                    this.declineIncomingCall();
                    return;
                }
            }

            // Si hay una llamada activa en curso y se presiona Backspace/Delete (fuera de campos de texto)
            if (e.key === "Backspace" || e.key === "Delete") {
                if (window.AuraPhoneApp && window.AuraPhoneApp.currentCallNumber) {
                    const tag = document.activeElement ? document.activeElement.tagName : '';
                    if (tag !== 'INPUT' && tag !== 'TEXTAREA') {
                        e.preventDefault();
                        window.AuraPhoneApp.endCall();
                        return;
                    }
                }
            }

            if (e.key === "Escape") {
                this.closePhoneNUI();
            }
        });

        // Home Indicator (Cerrar App, Desbloquear Teléfono o Cerrar Teléfono)
        document.getElementById('home-indicator').addEventListener('click', () => {
            this.handleHomeIndicatorClick();
        });
    },

    fetchSettings: function() {
        fetch(`https://${GetParentResourceName()}/getSettings`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).then(resp => resp.json()).then(settings => {
            if (settings) {
                this.settings = settings;
                this.applySettings(settings);
                if (window.AuraSettingsApp) {
                    window.AuraSettingsApp.settings = settings;
                    window.AuraSettingsApp.populateUI();
                }
            }
        }).catch(err => console.error("Error loading settings:", err));
    },

    applySettings: function(settings) {
        if (!settings) return;
        this.settings = settings;

        // 1. Color de Marco / Bisel
        const root = document.documentElement;
        const frameColor = settings.frame_color || "#00F0FF";
        root.style.setProperty('--phone-frame-color', frameColor);

        const hardware = document.querySelector('.phone-hardware');
        if (hardware) {
            hardware.style.boxShadow = `inset 0 0 15px rgba(255, 255, 255, 0.15), 0 0 0 2px ${frameColor}, 0 0 30px ${frameColor}33`;
        }

        // 2. Fondo de Pantalla (Wallpaper)
        const screen = document.querySelector('.phone-screen');
        if (screen) {
            if (settings.wallpaper_url === 'dark_amoled') {
                screen.style.background = 'linear-gradient(135deg, #050508 0%, #101018 100%)';
            } else if (settings.wallpaper_url && settings.wallpaper_url !== "") {
                screen.style.background = `#000 url('${settings.wallpaper_url}') center/cover no-repeat`;
            }
        }
    },

    startClock: function() {
        const updateClock = () => {
            const now = new Date();
            let h = now.getHours().toString().padStart(2, '0');
            let m = now.getMinutes().toString().padStart(2, '0');
            
            // Actualizar status bar y widget
            const clockEl = document.getElementById('clock');
            if (clockEl) clockEl.innerText = `${h}:${m}`;

            const widgetTime = document.getElementById('widget-time');
            if (widgetTime) widgetTime.innerText = `${h}:${m}`;

            const lockTime = document.getElementById('lock-time');
            if (lockTime) lockTime.innerText = `${h}:${m}`;

            const days = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
            const months = [
                'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
                'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
            ];
            
            const dayName = days[now.getDay()];
            const dayNum = now.getDate();
            const monthName = months[now.getMonth()];
            const dateStr = `${dayName}, ${dayNum} de ${monthName}`;
            
            const widgetDate = document.getElementById('widget-date');
            if (widgetDate) widgetDate.innerText = dateStr;

            const lockDate = document.getElementById('lock-date');
            if (lockDate) lockDate.innerText = dateStr;
        };

        updateClock();
        setInterval(updateClock, 1000);
    },

    // Generar dinámicamente los iconos del grid y dock con Badges de Notificaciones
    renderHome: function() {
        const grid = document.getElementById('app-grid');
        const dock = document.getElementById('app-dock');
        if (!grid || !dock) return;
        grid.innerHTML = '';
        dock.innerHTML = '';

        AuraAppsRegistry.forEach(app => {
            const iconHtml = `
                <div class="app-icon-container" id="icon-container-${app.id}" onclick="AuraCore.openApp('${app.id}')">
                    <div class="app-badge hidden" id="badge-${app.id}">0</div>
                    <div class="icon-squircle ${app.colorClass}">
                        <i class="${app.icon}"></i>
                    </div>
                    <span>${app.name}</span>
                </div>
            `;
            
            if (app.inDock) {
                dock.innerHTML += iconHtml;
            } else {
                grid.innerHTML += iconHtml;
            }
        });

        this.updateAppBadges();
    },

    // Generar dinámicamente los contenedores (ventanas) de las apps
    renderAppWindows: function() {
        const container = document.getElementById('apps-container');
        if (!container) return;
        container.innerHTML = '';

        AuraAppsRegistry.forEach(app => {
            if (app.id === 'app-bank') {
                if(window.AuraBankApp) {
                    container.innerHTML += window.AuraBankApp.getHTML();
                }
                return;
            }
            
            if (app.id === 'app-phone') {
                if(window.AuraPhoneApp) {
                    container.innerHTML += window.AuraPhoneApp.getHTML();
                }
                return;
            }

            if (app.id === 'app-messages') {
                if(window.AuraMessagesApp) {
                    container.innerHTML += window.AuraMessagesApp.getHTML();
                }
                return;
            }

            if (app.id === 'app-contacts') {
                if(window.AuraContactsApp) {
                    container.innerHTML += window.AuraContactsApp.getHTML();
                }
                return;
            }

            if (app.id === 'app-settings') {
                if(window.AuraSettingsApp) {
                    container.innerHTML += window.AuraSettingsApp.getHTML();
                }
                return;
            }

            if (app.id === 'app-gallery') {
                if(window.AuraGalleryApp) {
                    container.innerHTML += window.AuraGalleryApp.getHTML();
                }
                return;
            }

            if (app.id === 'app-camera') {
                if(window.AuraCameraApp) {
                    container.innerHTML += window.AuraCameraApp.getHTML();
                }
                return;
            }

            container.innerHTML += `
                <div id="${app.id}-window" class="app-window">
                    <div class="app-header">
                        <i class="${app.icon} app-icon-small"></i>
                        <span>${app.name}</span>
                    </div>
                    <div class="placeholder-content">
                        <i class="${app.icon}"></i>
                        <p>Interfaz en desarrollo</p>
                    </div>
                </div>
            `;
        });
    },

    openApp: function(appId) {
        if (this.isLocked) return;

        const appWindow = document.getElementById(`${appId}-window`);
        if (appWindow) {
            appWindow.classList.add('open');
            this.activeAppId = appId;
            
            // Dynamic island animation
            const island = document.getElementById('dynamic-island');
            if (island) {
                island.style.transform = 'translateX(-50%) scale(0.9)';
                setTimeout(() => { island.style.transform = 'translateX(-50%) scale(1)'; }, 200);
            }

            // Limpiar notificaciones de la app abierta
            this.clearNotificationsForApp(appId);

            const appDef = AuraAppsRegistry.find(a => a.id === appId);
            if (appDef && appDef.script && window[appDef.script]) {
                window[appDef.script].onOpen();
            }
        }
    },

    closeApp: function() {
        if (this.activeAppId) {
            if (this.activeAppId === 'app-camera') {
                if (window.AuraCameraApp) window.AuraCameraApp.exitCameraMode();
                fetch(`https://${GetParentResourceName()}/closeCamera`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({})
                });
            }

            const appWindow = document.getElementById(`${this.activeAppId}-window`);
            if (appWindow) appWindow.classList.remove('open');
            this.activeAppId = null;
        }
    },

    openPhone: function() {
        this.isOpen = true;
        this.isPeeking = false;
        this.fetchSettings();

        const phoneContainer = document.getElementById('phone-container');
        phoneContainer.classList.remove('hidden', 'peek-call', 'peek-notif');
        setTimeout(() => {
            phoneContainer.classList.add('show');
        }, 50);

        this.showLockScreen();
    },

    closePhone: function() {
        this.isOpen = false;
        this.isPeeking = false;
        this.closeApp();
        const phoneContainer = document.getElementById('phone-container');
        phoneContainer.classList.remove('show', 'peek-call', 'peek-notif');
        setTimeout(() => {
            phoneContainer.classList.add('hidden');
            this.isLocked = true;
        }, 800);
    },

    closePhoneNUI: function() {
        fetch(`https://${GetParentResourceName()}/close`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).catch(err => console.log('NUI Fetch Error', err));
    },

    handleHomeIndicatorClick: function() {
        if (this.isLocked) {
            const hasPin = this.settings && this.settings.security && this.settings.security.pin_code && this.settings.security.pin_code.length > 0;
            
            if (hasPin) {
                if (this.enteredPin.length < 4) {
                    const pinContainer = document.getElementById('lock-pin-container');
                    if (pinContainer) {
                        pinContainer.classList.add('shake-anim');
                        setTimeout(() => { pinContainer.classList.remove('shake-anim'); }, 400);
                    }
                    return;
                }
            } else {
                this.unlockPhone();
                return;
            }
        }

        if (this.activeAppId) {
            this.closeApp();
            return;
        }

        this.closePhoneNUI();
    },

    // =========================================
    // CONTINUOUS RINGTONE & CALL MANAGEMENT
    // =========================================

    startRingtone: function() {
        this.stopRingtone();

        let vol = 0.8;
        if (this.settings && this.settings.volume_ring !== undefined) {
            vol = this.settings.volume_ring / 100;
        }
        if (vol <= 0) return;

        const playRingPattern = () => {
            try {
                const AudioContext = window.AudioContext || window.webkitAudioContext;
                if (!AudioContext) return;
                const ctx = new AudioContext();
                const now = ctx.currentTime;

                // Marimba iOS Style Melodic Chimes (4 notes x 2 bursts)
                const notes = [
                    { f: 880.00, t: 0.00, d: 0.12 }, // A5
                    { f: 1046.50, t: 0.14, d: 0.12 }, // C6
                    { f: 1318.51, t: 0.28, d: 0.14 }, // E6
                    { f: 1760.00, t: 0.44, d: 0.24 }, // A6
                    { f: 1318.51, t: 0.72, d: 0.12 }, // E6
                    { f: 1760.00, t: 0.88, d: 0.35 }  // A6
                ];

                notes.forEach(n => {
                    const osc1 = ctx.createOscillator();
                    const osc2 = ctx.createOscillator();
                    const gain = ctx.createGain();

                    osc1.type = "sine";
                    osc1.frequency.setValueAtTime(n.f, now + n.t);

                    osc2.type = "triangle";
                    osc2.frequency.setValueAtTime(n.f * 2, now + n.t);

                    gain.gain.setValueAtTime(vol * 0.35, now + n.t);
                    gain.gain.exponentialRampToValueAtTime(0.0001, now + n.t + n.d);

                    osc1.connect(gain);
                    osc2.connect(gain);
                    gain.connect(ctx.destination);

                    osc1.start(now + n.t);
                    osc2.start(now + n.t);
                    osc1.stop(now + n.t + n.d);
                    osc2.stop(now + n.t + n.d);
                });
            } catch(e) {
                // Ignore audio restriction if before first gesture
            }
        };

        playRingPattern();
        this.activeRingtoneInterval = setInterval(playRingPattern, 2300);
    },

    stopRingtone: function() {
        if (this.activeRingtoneInterval) {
            clearInterval(this.activeRingtoneInterval);
            this.activeRingtoneInterval = null;
        }
    },

    handleIncomingCall: function(data) {
        const callerNumber = data.number || data.callerNumber || "555-0199";
        const callerName = data.callerName || callerNumber;
        this.activeIncomingCall = { number: callerNumber, name: callerName };

        // 1. Iniciar tono de llamada continuo
        this.startRingtone();

        // 2. Si el teléfono está cerrado, desplegar en modo PEEK (asomar sólo la parte superior)
        if (!this.isOpen) {
            this.isPeeking = true;
            const phoneContainer = document.getElementById('phone-container');
            phoneContainer.classList.remove('hidden', 'show', 'peek-notif');
            phoneContainer.classList.add('peek-call');

            const peekCard = document.getElementById('peek-call-card');
            if (peekCard) {
                document.getElementById('peek-caller-name').innerText = callerName;
                document.getElementById('peek-caller-number').innerText = callerNumber;
                peekCard.classList.remove('hidden');
            }
        } else {
            // Teléfono abierto: Mostrar pantalla completa de llamada
            if (window.AuraPhoneApp) {
                this.openApp('app-phone');
                window.AuraPhoneApp.showActiveCallScreen(callerNumber, callerName, false);
            }
        }
    },

    acceptIncomingCall: function() {
        this.stopRingtone();
        const peekCard = document.getElementById('peek-call-card');
        if (peekCard) peekCard.classList.add('hidden');

        const phoneContainer = document.getElementById('phone-container');
        phoneContainer.classList.remove('peek-call', 'peek-notif');

        // Si estaba peeking o cerrado, desplegar teléfono completo para la llamada
        if (this.isPeeking || !this.isOpen) {
            this.isPeeking = false;
            this.openPhone();
            this.openApp('app-phone');
        }

        if (window.AuraPhoneApp) {
            window.AuraPhoneApp.acceptCall();
        }

        this.activeIncomingCall = null;
    },

    declineIncomingCall: function() {
        this.stopRingtone();
        const peekCard = document.getElementById('peek-call-card');
        if (peekCard) peekCard.classList.add('hidden');

        const phoneContainer = document.getElementById('phone-container');
        const wasPeeking = this.isPeeking;
        phoneContainer.classList.remove('peek-call', 'peek-notif');

        if (window.AuraPhoneApp) {
            window.AuraPhoneApp.endCall();
        }

        // Registrar notificación de llamada perdida con estilo AuraRP
        if (this.activeIncomingCall) {
            this.addNotification({
                app: 'calls',
                title: 'Llamada Perdida',
                message: `${this.activeIncomingCall.name} (${this.activeIncomingCall.number})`,
                icon: 'fas fa-phone-slash',
                color: '#FF0055',
                data: { number: this.activeIncomingCall.number }
            });
        }

        if (wasPeeking || !this.isOpen) {
            this.isPeeking = false;
            phoneContainer.classList.add('hidden');
        }

        this.activeIncomingCall = null;
    },

    handleCallEnded: function(reason) {
        this.stopRingtone();
        if (window.AuraPhoneApp) {
            window.AuraPhoneApp.stopActiveAudio();
            window.AuraPhoneApp.hideActiveCallScreen();
        }
        const peekCard = document.getElementById('peek-call-card');
        if (peekCard) peekCard.classList.add('hidden');

        const phoneContainer = document.getElementById('phone-container');
        phoneContainer.classList.remove('peek-call', 'peek-notif');

        if (this.isPeeking) {
            this.isPeeking = false;
            phoneContainer.classList.add('hidden');
        }

        this.activeIncomingCall = null;
    },

    // =========================================
    // GESTOR DE NOTIFICACIONES & PEEK NOTIFS
    // =========================================

    addNotification: function(notif) {
        if (!notif) return;

        // Comprobar si las notificaciones están silenciadas en Ajustes
        if (this.settings && this.settings.notifications) {
            const appKey = (notif.app === 'app-phone' || notif.app === 'calls') ? 'calls' :
                           (notif.app === 'app-messages' || notif.app === 'messages') ? 'messages' :
                           (notif.app === 'app-bank' || notif.app === 'bank') ? 'bank' : null;
            if (appKey && this.settings.notifications[appKey] === false) {
                return;
            }
        }

        notif.id = notif.id || 'notif_' + Date.now() + '_' + Math.random().toString(36).substr(2, 4);
        notif.time = notif.time || "ahora";

        if (notif.app === 'messages' || notif.app === 'app-messages') {
            notif.appName = notif.appName || "Mensajes";
            notif.appId = "app-messages";
            notif.icon = notif.icon || "fas fa-comment";
            notif.color = notif.color || "#25D366";
            notif.soundType = 'message';
        } else if (notif.app === 'calls' || notif.app === 'app-phone') {
            notif.appName = notif.appName || "Teléfono";
            notif.appId = "app-phone";
            notif.icon = notif.icon || "fas fa-phone";
            notif.color = notif.color || "#00F0FF";
            notif.soundType = 'call';
        } else if (notif.app === 'bank' || notif.app === 'app-bank') {
            notif.appName = notif.appName || "AuraBank";
            notif.appId = "app-bank";
            notif.icon = notif.icon || "fas fa-university";
            notif.color = notif.color || "#00F0FF";
            notif.soundType = 'bank';
        } else {
            notif.appName = notif.appName || (notif.app ? notif.app.toUpperCase() : "Aura OS");
            notif.appId = notif.appId || (notif.app ? (notif.app.startsWith('app-') ? notif.app : 'app-' + notif.app) : 'app-messages');
            notif.icon = notif.icon || "fas fa-bell";
            notif.color = notif.color || "var(--primary-cyan)";
            notif.soundType = 'message';
        }

        // Insertar en la lista (más recientes primero)
        this.notifications.unshift(notif);
        if (this.notifications.length > 25) {
            this.notifications.pop();
        }

        this.renderLockNotifications();
        this.updateAppBadges();
        this.playNotificationSound(notif.soundType);

        // Si el teléfono está abierto y desbloqueado, mostrar banner superior
        if (this.isOpen && !this.isLocked) {
            this.showTopBanner(notif);
        } else if (!this.isOpen && !this.isPeeking && !this.activeIncomingCall) {
            // Si el teléfono está cerrado, asomarse brevemente en modo peek
            const phoneContainer = document.getElementById('phone-container');
            phoneContainer.classList.remove('hidden', 'show', 'peek-call');
            phoneContainer.classList.add('peek-notif');
            this.showTopBanner(notif);

            if (this.peekNotifTimeout) clearTimeout(this.peekNotifTimeout);
            this.peekNotifTimeout = setTimeout(() => {
                if (!this.isOpen && !this.activeIncomingCall) {
                    phoneContainer.classList.remove('peek-notif');
                    phoneContainer.classList.add('hidden');
                    this.hideTopBanner();
                }
            }, 4500);
        }
    },

    removeNotification: function(id, event) {
        if (event) event.stopPropagation();
        this.notifications = this.notifications.filter(n => n.id !== id);
        this.renderLockNotifications();
        this.updateAppBadges();
    },

    clearAllNotifications: function(event) {
        if (event) event.stopPropagation();
        this.notifications = [];
        this.renderLockNotifications();
        this.updateAppBadges();
    },

    clearNotificationsForApp: function(appId) {
        this.notifications = this.notifications.filter(n => n.appId !== appId && n.app !== appId);
        this.renderLockNotifications();
        this.updateAppBadges();
    },

    clickNotification: function(id) {
        const notif = this.notifications.find(n => n.id === id);
        if (!notif) return;

        this.unlockPhone();

        if (notif.appId) {
            setTimeout(() => {
                this.openApp(notif.appId);
                
                if ((notif.appId === 'app-messages' || notif.app === 'messages') && notif.data && notif.data.number) {
                    if (window.AuraMessagesApp && window.AuraMessagesApp.openChatDirectly) {
                        setTimeout(() => {
                            window.AuraMessagesApp.openChatDirectly(notif.data.number, notif.title);
                        }, 250);
                    }
                }
            }, 300);
        }

        this.removeNotification(id);
    },

    renderLockNotifications: function() {
        const list = document.getElementById('lock-notifs-list');
        const container = document.getElementById('lock-notifications-container');
        if (!list || !container) return;

        const hasPin = this.settings && this.settings.security && this.settings.security.pin_code && this.settings.security.pin_code.length > 0;
        if (this.isLocked && hasPin && this.enteredPin.length > 0) {
            container.classList.add('hidden');
            return;
        }

        if (this.notifications.length === 0) {
            container.classList.add('hidden');
            list.innerHTML = '';
            return;
        }

        container.classList.remove('hidden');

        list.innerHTML = this.notifications.map(n => `
            <div class="lock-notif-card" onclick="AuraCore.clickNotification('${n.id}')">
                <div class="notif-card-top">
                    <div class="notif-app-badge">
                        <div class="notif-app-icon">
                            <i class="${n.icon}"></i>
                        </div>
                        <span class="notif-app-name">${n.appName}</span>
                    </div>
                    <span class="notif-time">${n.time}</span>
                </div>
                <div class="notif-card-body">
                    <span class="notif-card-title">${n.title}</span>
                    <span class="notif-card-msg">${n.message}</span>
                </div>
                <div class="notif-card-close" onclick="AuraCore.removeNotification('${n.id}', event)" title="Descartar">
                    <i class="fas fa-times"></i>
                </div>
            </div>
        `).join('');
    },

    updateAppBadges: function() {
        const counts = {};
        this.notifications.forEach(n => {
            const key = n.appId || n.app;
            counts[key] = (counts[key] || 0) + 1;
        });

        AuraAppsRegistry.forEach(app => {
            const badgeEl = document.getElementById(`badge-${app.id}`);
            if (badgeEl) {
                const count = counts[app.id] || 0;
                if (count > 0) {
                    badgeEl.innerText = count > 99 ? "99+" : count;
                    badgeEl.classList.remove('hidden');
                } else {
                    badgeEl.classList.add('hidden');
                }
            }
        });
    },

    showTopBanner: function(notif) {
        const banner = document.getElementById('top-notification-banner');
        const iconEl = document.getElementById('top-notif-icon');
        const appEl = document.getElementById('top-notif-app');
        const titleEl = document.getElementById('top-notif-title');
        const bodyEl = document.getElementById('top-notif-body');

        if (!banner) return;
        this.currentTopNotif = notif;

        if (iconEl) {
            iconEl.innerHTML = `<i class="${notif.icon || 'fas fa-bell'}"></i>`;
        }
        if (appEl) appEl.innerText = notif.appName || "Notificación";
        if (titleEl) titleEl.innerText = notif.title || "";
        if (bodyEl) bodyEl.innerText = notif.message || "";

        banner.classList.remove('hidden');

        if (this.activeTopBannerTimeout) {
            clearTimeout(this.activeTopBannerTimeout);
        }

        this.activeTopBannerTimeout = setTimeout(() => {
            this.hideTopBanner();
        }, 4000);
    },

    hideTopBanner: function() {
        const banner = document.getElementById('top-notification-banner');
        if (banner) banner.classList.add('hidden');
        this.currentTopNotif = null;
    },

    clickTopBanner: function() {
        if (this.currentTopNotif) {
            const notif = this.currentTopNotif;
            this.hideTopBanner();
            this.clickNotification(notif.id);
        }
    },

    playNotificationSound: function(type = 'message') {
        try {
            let vol = 0.8;
            if (this.settings) {
                if (type === 'call') {
                    vol = (this.settings.volume_ring !== undefined ? this.settings.volume_ring : 80) / 100;
                } else {
                    vol = (this.settings.volume_msg !== undefined ? this.settings.volume_msg : 80) / 100;
                }
            }
            if (vol <= 0) return;

            const AudioContext = window.AudioContext || window.webkitAudioContext;
            if (!AudioContext) return;
            const ctx = new AudioContext();
            const now = ctx.currentTime;
            
            const osc1 = ctx.createOscillator();
            const osc2 = ctx.createOscillator();
            const gain = ctx.createGain();
            
            osc1.type = "sine";
            osc2.type = "triangle";
            
            if (type === 'bank') {
                osc1.frequency.setValueAtTime(587.33, now);
                osc1.frequency.setValueAtTime(880, now + 0.1);
                gain.gain.setValueAtTime(vol * 0.3, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.4);
            } else {
                // Tri-tone iOS
                osc1.frequency.setValueAtTime(659.25, now);
                osc1.frequency.setValueAtTime(830.61, now + 0.08);
                osc1.frequency.setValueAtTime(1046.50, now + 0.16);
                
                osc2.frequency.setValueAtTime(659.25, now);
                osc2.frequency.setValueAtTime(830.61, now + 0.08);
                osc2.frequency.setValueAtTime(1046.50, now + 0.16);

                gain.gain.setValueAtTime(vol * 0.35, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.45);
            }
            
            osc1.connect(gain);
            osc2.connect(gain);
            gain.connect(ctx.destination);
            
            osc1.start(now);
            osc2.start(now);
            osc1.stop(now + 0.5);
            osc2.stop(now + 0.5);
        } catch(e) {
            // Silently ignore restricted audio context before user gesture
        }
    },

    // =========================================
    // LOCK SCREEN & FACE ID LOGIC
    // =========================================

    showLockScreen: function() {
        this.isLocked = true;
        this.enteredPin = "";
        this.updatePinDots();

        const lockScreen = document.getElementById('lock-screen');
        const homeScreen = document.getElementById('home-screen');
        const padlockIcon = document.getElementById('lock-padlock-icon');
        const pinContainer = document.getElementById('lock-pin-container');
        const swipeHint = document.getElementById('lock-swipe-hint');

        if (lockScreen) {
            lockScreen.classList.remove('hidden', 'sliding-up');
            lockScreen.classList.add('active');
        }
        if (homeScreen) {
            homeScreen.classList.remove('active');
        }

        const hasPin = this.settings && this.settings.security && this.settings.security.pin_code && this.settings.security.pin_code.length > 0;

        if (hasPin) {
            if (padlockIcon) {
                padlockIcon.innerHTML = '<i class="fas fa-lock"></i>';
                padlockIcon.classList.remove('unlocked');
            }
            if (pinContainer) pinContainer.classList.remove('hidden');
            if (swipeHint) swipeHint.classList.add('hidden');

            if (this.settings && this.settings.security && this.settings.security.face_id === true) {
                this.triggerFaceIDScan();
            }
        } else {
            if (padlockIcon) {
                padlockIcon.innerHTML = '<i class="fas fa-unlock"></i>';
                padlockIcon.classList.add('unlocked');
            }
            if (pinContainer) pinContainer.classList.add('hidden');
            if (swipeHint) swipeHint.classList.remove('hidden');
        }

        this.renderLockNotifications();
    },

    triggerFaceIDScan: function() {
        const island = document.getElementById('dynamic-island');
        const banner = document.getElementById('lock-faceid-banner');
        
        if (island) {
            island.classList.add('island-faceid-scan');
        }
        if (banner) {
            banner.classList.remove('hidden');
        }

        setTimeout(() => {
            if (island) island.classList.remove('island-faceid-scan');
            if (banner) banner.classList.add('hidden');

            const padlockIcon = document.getElementById('lock-padlock-icon');
            if (padlockIcon) {
                padlockIcon.innerHTML = '<i class="fas fa-unlock"></i>';
                padlockIcon.classList.add('unlocked');
            }

            setTimeout(() => {
                this.unlockPhone();
            }, 300);
        }, 1100);
    },

    enterPinDigit: function(digit) {
        if (!this.isLocked || this.enteredPin.length >= 4) return;
        this.enteredPin += digit;
        this.updatePinDots();

        if (this.enteredPin.length === 4) {
            setTimeout(() => {
                this.verifyPin();
            }, 150);
        }
    },

    deletePinDigit: function() {
        if (!this.isLocked || this.enteredPin.length === 0) return;
        this.enteredPin = this.enteredPin.slice(0, -1);
        this.updatePinDots();
    },

    updatePinDots: function() {
        for (let i = 1; i <= 4; i++) {
            const dot = document.getElementById(`pdot-${i}`);
            if (dot) {
                if (i <= this.enteredPin.length) {
                    dot.classList.add('filled');
                } else {
                    dot.classList.remove('filled');
                }
            }
        }
    },

    verifyPin: function() {
        const correctPin = (this.settings && this.settings.security && this.settings.security.pin_code) ? this.settings.security.pin_code : "";

        if (this.enteredPin === correctPin) {
            const padlockIcon = document.getElementById('lock-padlock-icon');
            if (padlockIcon) {
                padlockIcon.innerHTML = '<i class="fas fa-unlock"></i>';
                padlockIcon.classList.add('unlocked');
            }
            setTimeout(() => {
                this.unlockPhone();
            }, 300);
        } else {
            const pinContainer = document.getElementById('lock-pin-container');
            if (pinContainer) {
                pinContainer.classList.add('shake-anim');
                setTimeout(() => { pinContainer.classList.remove('shake-anim'); }, 500);
            }
            this.enteredPin = "";
            this.updatePinDots();
        }
    },

    unlockPhone: function() {
        this.isLocked = false;
        this.enteredPin = "";
        this.updatePinDots();

        const lockScreen = document.getElementById('lock-screen');
        const homeScreen = document.getElementById('home-screen');

        if (lockScreen) {
            lockScreen.classList.add('sliding-up');
            setTimeout(() => {
                lockScreen.classList.remove('active', 'sliding-up');
                lockScreen.classList.add('hidden');
            }, 350);
        }
        if (homeScreen) {
            homeScreen.classList.remove('hidden');
            homeScreen.classList.add('active');
        }
    }
};

window.onload = () => {
    AuraCore.init();
};
