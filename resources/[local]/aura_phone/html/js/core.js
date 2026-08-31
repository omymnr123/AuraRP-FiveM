// Motor Principal de Aura OS V2
const AuraCore = {
    isOpen: false,
    activeAppId: null,
    settings: null,
    isLocked: false,
    enteredPin: "",

    init: function() {
        this.fetchSettings();
        this.renderHome();
        this.renderAppWindows();
        this.setupListeners();
        this.startClock();
    },

    setupListeners: function() {
        // NUI Messages
        window.addEventListener('message', (event) => {
            const data = event.data;
            if (data.action === "openPhone") {
                this.openPhone();
            } else if (data.action === "closePhone") {
                this.closePhone();
            }
        });

        // Home Indicator (Cerrar App o Teléfono)
        document.getElementById('home-indicator').addEventListener('click', () => {
            if (this.activeAppId) {
                this.closeApp();
            } else {
                this.closePhoneNUI();
            }
        });

        // Escape para cerrar
        document.onkeyup = (data) => {
            if (data.key === "Escape") {
                this.closePhoneNUI();
            }
        };
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

        // 3. Seguridad PIN
        const hasPin = settings.security && settings.security.pin_code && settings.security.pin_code.length > 0;
        if (!hasPin) {
            this.isLocked = false;
            const lockScreen = document.getElementById('lock-screen');
            if (lockScreen) {
                lockScreen.classList.remove('active');
                lockScreen.classList.add('hidden');
            }
            const homeScreen = document.getElementById('home-screen');
            if (homeScreen) {
                homeScreen.classList.remove('hidden');
                homeScreen.classList.add('active');
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

    // Generar dinámicamente los iconos del grid y dock
    renderHome: function() {
        const grid = document.getElementById('app-grid');
        const dock = document.getElementById('app-dock');
        if (!grid || !dock) return;
        grid.innerHTML = '';
        dock.innerHTML = '';

        AuraAppsRegistry.forEach(app => {
            const iconHtml = `
                <div class="app-icon-container" onclick="AuraCore.openApp('${app.id}')">
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
    },

    // Generar dinámicamente los contenedores (ventanas) de las apps
    renderAppWindows: function() {
        const container = document.getElementById('apps-container');
        if (!container) return;
        container.innerHTML = ''; // Limpiar

        AuraAppsRegistry.forEach(app => {
            // El banco tiene su propio render en bank.js
            if (app.id === 'app-bank') {
                if(window.AuraBankApp) {
                    container.innerHTML += window.AuraBankApp.getHTML();
                }
                return;
            }
            
            // El teléfono tiene su propio render en phone.js
            if (app.id === 'app-phone') {
                if(window.AuraPhoneApp) {
                    container.innerHTML += window.AuraPhoneApp.getHTML();
                }
                return;
            }

            // Mensajes tiene su propio render en messages.js
            if (app.id === 'app-messages') {
                if(window.AuraMessagesApp) {
                    container.innerHTML += window.AuraMessagesApp.getHTML();
                }
                return;
            }

            // Contactos tiene su propio render en contacts.js
            if (app.id === 'app-contacts') {
                if(window.AuraContactsApp) {
                    container.innerHTML += window.AuraContactsApp.getHTML();
                }
                return;
            }

            // Ajustes tiene su propio render en settings.js
            if (app.id === 'app-settings') {
                if(window.AuraSettingsApp) {
                    container.innerHTML += window.AuraSettingsApp.getHTML();
                }
                return;
            }

            // Apps genéricas placeholder
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

            // Inicializar script de la app si existe
            const appDef = AuraAppsRegistry.find(a => a.id === appId);
            if (appDef && appDef.script && window[appDef.script]) {
                window[appDef.script].onOpen();
            }
        }
    },

    closeApp: function() {
        if (this.activeAppId) {
            const appWindow = document.getElementById(`${this.activeAppId}-window`);
            if (appWindow) appWindow.classList.remove('open');
            this.activeAppId = null;
        }
    },

    openPhone: function() {
        this.isOpen = true;
        this.fetchSettings();

        const phoneContainer = document.getElementById('phone-container');
        phoneContainer.classList.remove('hidden');
        setTimeout(() => {
            phoneContainer.classList.add('show');
        }, 50);

        // Comprobar bloqueo por PIN
        const hasPin = this.settings && this.settings.security && this.settings.security.pin_code && this.settings.security.pin_code.length > 0;
        
        if (hasPin) {
            this.showLockScreen();
        } else {
            this.unlockPhone();
        }
    },

    closePhone: function() {
        this.isOpen = false;
        this.closeApp(); // Cerrar app activa si la hay
        const phoneContainer = document.getElementById('phone-container');
        phoneContainer.classList.remove('show');
        setTimeout(() => {
            phoneContainer.classList.add('hidden');
            // Relock for next session if PIN exists
            const hasPin = this.settings && this.settings.security && this.settings.security.pin_code && this.settings.security.pin_code.length > 0;
            this.isLocked = (hasPin === true);
        }, 800);
    },

    closePhoneNUI: function() {
        fetch(`https://${GetParentResourceName()}/close`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).catch(err => console.log('NUI Fetch Error', err));
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

        if (lockScreen) {
            lockScreen.classList.remove('hidden');
            lockScreen.classList.add('active');
        }
        if (homeScreen) {
            homeScreen.classList.remove('active');
        }
        if (padlockIcon) {
            padlockIcon.innerHTML = '<i class="fas fa-lock"></i>';
            padlockIcon.classList.remove('unlocked');
        }

        // Si tiene Face ID activado, ejecutar escaneo biométrico automático
        if (this.settings && this.settings.security && this.settings.security.face_id === true) {
            this.triggerFaceIDScan();
        }
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
            // PIN Incorrecto -> Shake anim
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
            lockScreen.classList.remove('active');
            setTimeout(() => {
                lockScreen.classList.add('hidden');
            }, 300);
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

