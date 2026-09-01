// ===================================================
// AURA CAMERA APP (Live Hybrid Viewfinder)
// ===================================================

const AuraCameraApp = {
    isFront: false,
    zoom: 1.0,
    isFlash: false,
    isGrid: true,
    lastPhotoUrl: "https://images.unsplash.com/photo-1542751371-adc38448a05e?w=200",
    savedWallpaper: null,

    getHTML: function() {
        return `
            <div id="app-camera-window" class="app-window camera-in-phone-window">
                <!-- Flash Overlay Animation -->
                <div id="camera-flash-screen" class="camera-flash-screen hidden"></div>

                <!-- Top Camera Bar -->
                <div class="cam-in-phone-topbar">
                    <div class="cam-icon-btn" id="cam-btn-flash" onclick="AuraCameraApp.toggleFlash()" title="Flash [E]">
                        <i class="fas fa-bolt"></i>
                    </div>
                    <div class="cam-hdr-pill">
                        <span>AURA PRO</span>
                    </div>
                    <div class="cam-icon-btn active" id="cam-btn-grid" onclick="AuraCameraApp.toggleGrid()" title="Cuadrícula">
                        <i class="fas fa-border-all"></i>
                    </div>
                </div>

                <!-- Viewfinder Transparente Central (Streaming directo del juego) -->
                <div class="cam-in-phone-viewfinder" id="cam-in-phone-viewfinder">
                    <!-- Cuadrícula 3x3 -->
                    <div class="cam-viewfinder-grid" id="cam-viewfinder-grid">
                        <div class="v-line v-1"></div>
                        <div class="v-line v-2"></div>
                        <div class="h-line h-1"></div>
                        <div class="h-line h-2"></div>
                    </div>

                    <!-- Enfoque Reticular Central -->
                    <div class="cam-focus-reticle"></div>

                    <!-- Modo Actual Badge -->
                    <div class="cam-mode-indicator" id="cam-mode-indicator">
                        <span id="cam-mode-text">CÁMARA TRASERA</span>
                    </div>
                </div>

                <!-- Selector de Zoom (0.5x, 1.0x, 2.0x, 3.0x) -->
                <div class="cam-zoom-selector">
                    <div class="zoom-pill" id="zoom-pill-05" onclick="AuraCameraApp.setZoom(0.5)">0.5x</div>
                    <div class="zoom-pill active" id="zoom-pill-1" onclick="AuraCameraApp.setZoom(1.0)">1.0x</div>
                    <div class="zoom-pill" id="zoom-pill-2" onclick="AuraCameraApp.setZoom(2.0)">2.0x</div>
                    <div class="zoom-pill" id="zoom-pill-3" onclick="AuraCameraApp.setZoom(3.0)">3.0x</div>
                </div>

                <!-- Bottom Controls: Galería, Disparador y Giro Selfie -->
                <div class="cam-in-phone-bottombar">
                    <!-- Acceso Directo a Galería -->
                    <div class="cam-gallery-preview-btn" onclick="AuraCameraApp.openGallery()" title="Ver Galería">
                        <img id="cam-last-preview-img" src="${this.lastPhotoUrl}" alt="Galería">
                    </div>

                    <!-- Botón Obturador Principal -->
                    <div class="cam-shutter-button-outer" onclick="AuraCameraApp.onShutterButtonClick()" title="Tomar Foto [ENTER / CLICK IZQ]">
                        <div class="cam-shutter-button-inner"></div>
                    </div>

                    <!-- Botón Girar Cámara -->
                    <div class="cam-flip-camera-btn" id="cam-flip-camera-btn" onclick="AuraCameraApp.toggleFlip()" title="Girar Cámara [FLECHA ARRIBA]">
                        <i class="fas fa-camera-rotate"></i>
                    </div>
                </div>
            </div>
        `;
    },

    onOpen: function() {
        // 1. Activar de inmediato el modo transparente en el HTML
        this.enterCameraMode({});
        this.updateGalleryThumbnail();

        // 2. Notificar al backend de FiveM para activar CellCamActivate
        fetch(`https://${GetParentResourceName()}/openCamera`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    },

    enterCameraMode: function(data) {
        const phone = document.getElementById('phone-container');
        if (phone) {
            phone.classList.add('camera-mode-active');
        }

        // Limpiar fondo inline del wallpaper para garantizar transparencia 100%
        const screen = document.querySelector('.phone-screen');
        if (screen) {
            this.savedWallpaper = screen.style.background;
            screen.style.background = 'transparent';
            screen.style.backgroundImage = 'none';
        }

        this.updateFlip(data.isFront || false);
        this.updateZoomUI(data.zoom || 1.0);
    },

    exitCameraMode: function(openGallery) {
        const phone = document.getElementById('phone-container');
        if (phone) {
            phone.classList.remove('camera-mode-active');
        }

        // Restaurar fondo de pantalla
        if (window.AuraCore && window.AuraCore.settings) {
            window.AuraCore.applySettings(window.AuraCore.settings);
        } else {
            const screen = document.querySelector('.phone-screen');
            if (screen && this.savedWallpaper) {
                screen.style.background = this.savedWallpaper;
            }
        }

        if (openGallery && window.AuraCore) {
            setTimeout(() => {
                AuraCore.openApp('app-gallery');
            }, 100);
        }
    },

    onShutterButtonClick: function() {
        this.triggerShutter();
        fetch(`https://${GetParentResourceName()}/takePhoto`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    },

    triggerShutter: function() {
        const inner = document.querySelector('.cam-shutter-button-inner');
        if (inner) {
            inner.classList.add('shutter-clicked');
            setTimeout(() => inner.classList.remove('shutter-clicked'), 180);
        }
        this.triggerFlash();
    },

    triggerFlash: function() {
        const flash = document.getElementById('camera-flash-screen');
        if (flash) {
            flash.classList.remove('hidden');
            flash.classList.add('flash-screen-active');
            setTimeout(() => {
                flash.classList.remove('flash-screen-active');
                flash.classList.add('hidden');
            }, 250);
        }
    },

    toggleFlip: function() {
        const btn = document.getElementById('cam-flip-camera-btn');
        if (btn) {
            btn.classList.add('rotating');
            setTimeout(() => btn.classList.remove('rotating'), 350);
        }

        fetch(`https://${GetParentResourceName()}/toggleCameraFlip`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    },

    updateFlip: function(isFront) {
        this.isFront = isFront;
        const text = document.getElementById('cam-mode-text');
        if (text) {
            text.innerText = isFront ? "MODO SELFIE" : "CÁMARA TRASERA";
            text.style.color = isFront ? "#FF0055" : "#00F0FF";
        }
    },

    setZoom: function(zoomLevel) {
        this.zoom = zoomLevel;
        this.updateZoomUI(zoomLevel);
        fetch(`https://${GetParentResourceName()}/setCameraZoom`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ zoom: zoomLevel })
        });
    },

    updateZoomUI: function(zoomLevel) {
        const pills = document.querySelectorAll('.cam-zoom-selector .zoom-pill');
        const levelNum = parseFloat(zoomLevel);
        pills.forEach(p => {
            const pillText = p.innerText.replace('x', '').trim();
            if (Math.abs(parseFloat(pillText) - levelNum) < 0.1) {
                p.classList.add('active');
            } else {
                p.classList.remove('active');
            }
        });
    },

    toggleFlash: function() {
        this.isFlash = !this.isFlash;
        const btn = document.getElementById('cam-btn-flash');
        if (btn) {
            if (this.isFlash) btn.classList.add('active');
            else btn.classList.remove('active');
        }
    },

    toggleFlashUI: function(active) {
        this.isFlash = active;
        const btn = document.getElementById('cam-btn-flash');
        if (btn) {
            if (this.isFlash) btn.classList.add('active');
            else btn.classList.remove('active');
        }
    },

    toggleGrid: function() {
        this.isGrid = !this.isGrid;
        const grid = document.getElementById('cam-viewfinder-grid');
        const btn = document.getElementById('cam-btn-grid');
        if (grid) {
            if (this.isGrid) {
                grid.classList.remove('hidden');
                if (btn) btn.classList.add('active');
            } else {
                grid.classList.add('hidden');
                if (btn) btn.classList.remove('active');
            }
        }
    },

    openGallery: function() {
        fetch(`https://${GetParentResourceName()}/closeCamera`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });

        if (window.AuraCore) {
            AuraCore.openApp('app-gallery');
        }
    },

    updateGalleryThumbnail: function(url) {
        if (url) {
            this.lastPhotoUrl = url;
            const thumbImg = document.getElementById('cam-last-preview-img');
            if (thumbImg) {
                thumbImg.src = url;
                thumbImg.style.transform = 'scale(1.15)';
                setTimeout(() => thumbImg.style.transform = 'scale(1)', 300);
            }
            return;
        }

        fetch(`https://${GetParentResourceName()}/getGallery`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).then(resp => resp.json()).then(items => {
            if (items && items.length > 0) {
                this.lastPhotoUrl = items[0].media_url;
                const thumbImg = document.getElementById('cam-last-preview-img');
                if (thumbImg) thumbImg.src = this.lastPhotoUrl;
            }
        }).catch(() => {});
    }
};

// Escuchar eventos NUI enviados desde el cliente Lua
window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data) return;

    if (data.action === "enterCameraMode") {
        AuraCameraApp.enterCameraMode(data);
    } else if (data.action === "exitCameraMode") {
        AuraCameraApp.exitCameraMode(data.openGallery);
    } else if (data.action === "shutterAnimation") {
        AuraCameraApp.triggerShutter();
    } else if (data.action === "toggleFlashUI") {
        AuraCameraApp.toggleFlashUI(data.active);
    } else if (data.action === "updateCameraZoom") {
        AuraCameraApp.updateZoomUI(data.zoom);
    } else if (data.action === "updateCameraFlipState") {
        AuraCameraApp.updateFlip(data.isFront);
    } else if (data.action === "photoSaved") {
        AuraCameraApp.updateGalleryThumbnail(data.url);
    } else if (data.action === "toggleCursorState") {
        // Optional UI updates for cursor toggle could go here
    }
});

window.addEventListener('contextmenu', (e) => {
    const phone = document.getElementById('phone-container');
    if (phone && phone.classList.contains('camera-mode-active')) {
        e.preventDefault(); // Prevent default browser context menu
        fetch(`https://${GetParentResourceName()}/toggleCameraCursor`, {
            method: 'POST',
            body: JSON.stringify({})
        }).catch(() => {});
    }
});

window.AuraCameraApp = AuraCameraApp;
