// Motor Principal de Aura OS V2
const AuraCore = {
    isOpen: false,
    activeAppId: null,

    init: function() {
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

    startClock: function() {
        setInterval(() => {
            const now = new Date();
            let h = now.getHours().toString().padStart(2, '0');
            let m = now.getMinutes().toString().padStart(2, '0');
            
            // Actualizar status bar y widget
            document.getElementById('clock').innerText = `${h}:${m}`;
            const widgetTime = document.getElementById('widget-time');
            if (widgetTime) widgetTime.innerText = `${h}:${m}`;

        }, 1000);
    },

    // Generar dinámicamente los iconos del grid y dock
    renderHome: function() {
        const grid = document.getElementById('app-grid');
        const dock = document.getElementById('app-dock');
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
        const appWindow = document.getElementById(`${appId}-window`);
        if (appWindow) {
            appWindow.classList.add('open');
            this.activeAppId = appId;
            
            // Dynamic island animation (optional)
            const island = document.getElementById('dynamic-island');
            island.style.transform = 'translateX(-50%) scale(0.9)';
            setTimeout(() => { island.style.transform = 'translateX(-50%) scale(1)'; }, 200);

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
        document.getElementById('phone-container').classList.remove('hidden');
        setTimeout(() => {
            document.getElementById('phone-container').classList.add('show');
        }, 50);
    },

    closePhone: function() {
        this.isOpen = false;
        this.closeApp(); // Cerrar app activa si la hay
        document.getElementById('phone-container').classList.remove('show');
        setTimeout(() => {
            document.getElementById('phone-container').classList.add('hidden');
        }, 800);
    },

    closePhoneNUI: function() {
        fetch(`https://${GetParentResourceName()}/close`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).catch(err => console.log('NUI Fetch Error', err));
    }
};

window.onload = () => {
    AuraCore.init();
};
