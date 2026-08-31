// =========================================
// AURA SETTINGS - JAVASCRIPT CONTROLLER
// =========================================

const AuraSettingsApp = {
    settings: null,
    tempWallpaper: null,
    tempFrameColor: null,

    getHTML: function() {
        return `
        <div id="app-settings-window" class="app-window" style="background: var(--bg-dark); position: absolute; width:100%; height:100%; top:0; left:0; overflow:hidden;">
            
            <div class="settings-container">
                
                <!-- Cabecera iOS -->
                <div class="settings-header">
                    <h2>Ajustes</h2>
                </div>

                <div class="settings-scroll-area">
                    
                    <!-- Ficha de Perfil / Apple ID de Aura (Click para cambiar nombre) -->
                    <div class="settings-profile-card" onclick="AuraSettingsApp.openNameModal()" title="Editar nombre del dispositivo">
                        <div class="profile-avatar" id="settings-profile-avatar">A</div>
                        <div class="profile-info">
                            <h3 id="settings-profile-name">iPhone de Aura</h3>
                            <p id="settings-profile-sub">Aura ID, iCloud y Seguridad</p>
                        </div>
                        <i class="fas fa-chevron-right profile-arrow"></i>
                    </div>

                    <!-- GRUPO: Personalización (Wallpaper & Frame) -->
                    <div class="settings-group-title">PANTALLA Y ASPECTO</div>
                    <div class="settings-group">
                        
                        <!-- Fondo de Pantalla (URL) -->
                        <div class="settings-row-stacked">
                            <div class="settings-row-label">
                                <div class="settings-icon-box bg-purple"><i class="fas fa-image"></i></div>
                                <span>Fondo de Pantalla (URL)</span>
                            </div>
                            <div class="settings-url-input-box">
                                <input type="text" id="setting-wallpaper-url" placeholder="https://ejemplo.com/fondo.jpg" oninput="AuraSettingsApp.onWallpaperInput(this.value)">
                                <button class="btn-url-apply" onclick="AuraSettingsApp.applyWallpaperInput()" title="Previsualizar"><i class="fas fa-eye"></i></button>
                            </div>
                        </div>

                        <!-- Presets de Fondos con Marco Rosa de Selección -->
                        <div class="settings-row-stacked">
                            <span class="settings-sub-label">Fondos Recomendados Aura</span>
                            <div class="wallpaper-presets-grid" id="wallpaper-presets-container">
                                <div class="wp-preset" data-wp="https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=2564&auto=format&fit=crop" style="background: url('https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=600&auto=format&fit=crop') center/cover;" onclick="AuraSettingsApp.selectWallpaperPreset('https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=2564&auto=format&fit=crop')" title="Cyberpunk"></div>
                                <div class="wp-preset" data-wp="https://images.unsplash.com/photo-1550684848-fac1c5b4e853?q=80&w=2564&auto=format&fit=crop" style="background: url('https://images.unsplash.com/photo-1550684848-fac1c5b4e853?q=80&w=600&auto=format&fit=crop') center/cover;" onclick="AuraSettingsApp.selectWallpaperPreset('https://images.unsplash.com/photo-1550684848-fac1c5b4e853?q=80&w=2564&auto=format&fit=crop')" title="Neon Grid"></div>
                                <div class="wp-preset" data-wp="https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=2564&auto=format&fit=crop" style="background: url('https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=600&auto=format&fit=crop') center/cover;" onclick="AuraSettingsApp.selectWallpaperPreset('https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=2564&auto=format&fit=crop')" title="Sunset Beach"></div>
                                <div class="wp-preset" data-wp="https://images.unsplash.com/photo-1579546929518-9e396f3cc809?q=80&w=2564&auto=format&fit=crop" style="background: url('https://images.unsplash.com/photo-1579546929518-9e396f3cc809?q=80&w=600&auto=format&fit=crop') center/cover;" onclick="AuraSettingsApp.selectWallpaperPreset('https://images.unsplash.com/photo-1579546929518-9e396f3cc809?q=80&w=2564&auto=format&fit=crop')" title="Gradient Wave"></div>
                                <div class="wp-preset" data-wp="dark_amoled" style="background: linear-gradient(135deg, #050508, #151525);" onclick="AuraSettingsApp.selectWallpaperPreset('dark_amoled')" title="Deep Amoled"></div>
                            </div>
                        </div>

                        <!-- Color del Marco / Glow -->
                        <div class="settings-row-stacked">
                            <div class="settings-row-label">
                                <div class="settings-icon-box bg-cyan"><i class="fas fa-palette"></i></div>
                                <span>Bisel y Resplandor del Chasis</span>
                            </div>
                            <div class="frame-colors-grid" id="frame-colors-container">
                                <div class="frame-color-dot" data-color="#00F0FF" style="background: #00F0FF;" onclick="AuraSettingsApp.selectFrameColor('#00F0FF')" title="Cyan Neón"></div>
                                <div class="frame-color-dot" data-color="#FF0055" style="background: #FF0055;" onclick="AuraSettingsApp.selectFrameColor('#FF0055')" title="Rosa Neón"></div>
                                <div class="frame-color-dot" data-color="#FFD700" style="background: #FFD700;" onclick="AuraSettingsApp.selectFrameColor('#FFD700')" title="Oro Titanio"></div>
                                <div class="frame-color-dot" data-color="#9D00FF" style="background: #9D00FF;" onclick="AuraSettingsApp.selectFrameColor('#9D00FF')" title="Morado Eléctrico"></div>
                                <div class="frame-color-dot" data-color="#38ef7d" style="background: #38ef7d;" onclick="AuraSettingsApp.selectFrameColor('#38ef7d')" title="Verde Esmeralda"></div>
                                <div class="frame-color-dot" data-color="#555566" style="background: #555566;" onclick="AuraSettingsApp.selectFrameColor('#555566')" title="Gris Espacial"></div>
                            </div>
                        </div>

                        <!-- Botón Obligatorio para Guardar Pantalla y Aspecto -->
                        <div class="settings-row-stacked" style="padding-top: 6px; padding-bottom: 14px;">
                            <button id="btn-save-appearance" class="btn-appearance-save" onclick="AuraSettingsApp.saveAppearance()">
                                <i class="fas fa-save" style="margin-right: 8px;"></i> Guardar Pantalla y Aspecto
                            </button>
                        </div>

                    </div>

                    <!-- GRUPO 2: Sonidos y Haptics -->
                    <div class="settings-group-title">SONIDOS Y NOTIFICACIONES</div>
                    <div class="settings-group">
                        
                        <!-- Tono de Llamada -->
                        <div class="settings-row">
                            <div class="settings-row-left">
                                <div class="settings-icon-box bg-orange"><i class="fas fa-bell"></i></div>
                                <span>Tono de Llamada</span>
                            </div>
                            <div class="settings-row-right">
                                <select id="setting-ringtone" class="settings-select" onchange="AuraSettingsApp.updateRingtone(this.value)">
                                    <option value="ringtone.mp3">Aura Classic</option>
                                    <option value="cyber_ring.mp3">Cyber Pulse</option>
                                    <option value="marimba.mp3">Marimba iOS</option>
                                </select>
                            </div>
                        </div>

                        <!-- Volumen Llamada Slider -->
                        <div class="settings-row-slider">
                            <div class="slider-header">
                                <span class="slider-title"><i class="fas fa-volume-down" style="margin-right:6px;"></i> Volumen Llamadas</span>
                                <span class="slider-value" id="ring-volume-label">80%</span>
                            </div>
                            <input type="range" id="setting-volume-ring" min="0" max="100" value="80" class="ios-slider" oninput="AuraSettingsApp.updateVolumeRing(this.value)">
                        </div>

                        <!-- Volumen Mensajes Slider -->
                        <div class="settings-row-slider">
                            <div class="slider-header">
                                <span class="slider-title"><i class="fas fa-volume-down" style="margin-right:6px;"></i> Volumen Mensajes</span>
                                <span class="slider-value" id="msg-volume-label">80%</span>
                            </div>
                            <input type="range" id="setting-volume-msg" min="0" max="100" value="80" class="ios-slider" oninput="AuraSettingsApp.updateVolumeMsg(this.value)">
                        </div>

                    </div>

                    <!-- GRUPO 3: Face ID y Código de Seguridad -->
                    <div class="settings-group-title">SEGURIDAD Y ACCESO</div>
                    <div class="settings-group">
                        
                        <!-- Toggle Face ID -->
                        <div class="settings-row">
                            <div class="settings-row-left">
                                <div class="settings-icon-box bg-green"><i class="fas fa-smile"></i></div>
                                <span>Face ID</span>
                            </div>
                            <label class="ios-switch">
                                <input type="checkbox" id="setting-face-id" onchange="AuraSettingsApp.toggleFaceID(this.checked)">
                                <span class="switch-slider"></span>
                            </label>
                        </div>

                        <!-- Código PIN -->
                        <div class="settings-row" style="cursor: pointer;" onclick="AuraSettingsApp.openPinModal()">
                            <div class="settings-row-left">
                                <div class="settings-icon-box bg-red"><i class="fas fa-lock"></i></div>
                                <span>Código PIN</span>
                            </div>
                            <div class="settings-row-right">
                                <span id="setting-pin-status" class="settings-status-text">Desactivado</span>
                                <i class="fas fa-chevron-right row-arrow"></i>
                            </div>
                        </div>

                    </div>

                    <!-- GRUPO 4: Notificaciones de Aplicaciones -->
                    <div class="settings-group-title">PERMISOS DE APLICACIONES</div>
                    <div class="settings-group">
                        
                        <!-- Notificaciones Llamadas -->
                        <div class="settings-row">
                            <div class="settings-row-left">
                                <div class="settings-icon-box bg-green"><i class="fas fa-phone"></i></div>
                                <span>Llamadas Entrantes</span>
                            </div>
                            <label class="ios-switch">
                                <input type="checkbox" id="notif-calls" checked onchange="AuraSettingsApp.toggleNotif('calls', this.checked)">
                                <span class="switch-slider"></span>
                            </label>
                        </div>

                        <!-- Notificaciones Mensajes -->
                        <div class="settings-row">
                            <div class="settings-row-left">
                                <div class="settings-icon-box bg-blue"><i class="fas fa-comment"></i></div>
                                <span>Mensajes y Chats</span>
                            </div>
                            <label class="ios-switch">
                                <input type="checkbox" id="notif-messages" checked onchange="AuraSettingsApp.toggleNotif('messages', this.checked)">
                                <span class="switch-slider"></span>
                            </label>
                        </div>

                        <!-- Notificaciones Banco -->
                        <div class="settings-row">
                            <div class="settings-row-left">
                                <div class="settings-icon-box bg-cyan"><i class="fas fa-university"></i></div>
                                <span>Alertas de Banco</span>
                            </div>
                            <label class="ios-switch">
                                <input type="checkbox" id="notif-bank" checked onchange="AuraSettingsApp.toggleNotif('bank', this.checked)">
                                <span class="switch-slider"></span>
                            </label>
                        </div>

                    </div>

                    <div class="settings-footer-info">
                        Aura OS v2.4.0 • Build CFX-2026<br>Diseñado para Los Santos
                    </div>

                </div>
            </div>

            <!-- MODAL CENTRADO: Cambiar Nombre del Dispositivo -->
            <div id="settings-name-modal" class="msg-modal-overlay hidden">
                <div class="incoming-share-card">
                    <div class="incoming-share-icon" style="background: linear-gradient(135deg, #007AFF, #00F0FF);"><i class="fas fa-user-edit"></i></div>
                    <h3>Nombre del Dispositivo</h3>
                    <p style="color:rgba(255,255,255,0.6); font-size:12px; margin-bottom:15px;">
                        Introduce el nombre que verán los demás en AirDrop y Ajustes:
                    </p>

                    <input type="text" id="modal-device-name-input" class="msg-modal-input" placeholder="Nombre (ej: Otto, iPhone de Marcos)" style="text-align: center; font-size: 15px; font-weight: 600;">

                    <div class="incoming-buttons" style="margin-top: 15px;">
                        <button class="btn-accept-share" onclick="AuraSettingsApp.saveNameModal()">
                            <i class="fas fa-check" style="margin-right:6px;"></i> Guardar
                        </button>
                        <button class="btn-reject-share" onclick="AuraSettingsApp.closeNameModal()">
                            Cancelar
                        </button>
                    </div>
                </div>
            </div>

            <!-- MODAL CENTRADO: Cambiar o Establecer Código PIN -->
            <div id="settings-pin-modal" class="msg-modal-overlay hidden">
                <div class="incoming-share-card">
                    <div class="incoming-share-icon" style="background: linear-gradient(135deg, #FF0055, #9D00FF);"><i class="fas fa-shield-alt"></i></div>
                    <h3>Código de Bloqueo</h3>
                    <p style="color:rgba(255,255,255,0.6); font-size:12px; margin-bottom:15px;">
                        Introduce un nuevo PIN de 4 dígitos o desactiva el bloqueo de seguridad:
                    </p>

                    <input type="password" id="modal-pin-input" maxlength="4" class="msg-modal-input" placeholder="PIN (4 dígitos)" style="text-align: center; font-size: 22px; letter-spacing: 8px;">

                    <div class="incoming-buttons" style="margin-top: 15px; display: flex; flex-direction: column; gap: 8px; width: 100%;">
                        <button class="btn-accept-share" onclick="AuraSettingsApp.savePinModal()" style="width: 100%;">
                            <i class="fas fa-check" style="margin-right:6px;"></i> Guardar PIN
                        </button>
                        <button id="btn-disable-pin" class="btn-reject-share hidden" onclick="AuraSettingsApp.disablePin()" style="width: 100%; background: rgba(255, 0, 85, 0.2); border-color: rgba(255, 0, 85, 0.4); color: var(--primary-pink);">
                            <i class="fas fa-trash-alt" style="margin-right:6px;"></i> Desactivar Código PIN
                        </button>
                        <button class="btn-reject-share" onclick="AuraSettingsApp.closePinModal()" style="width: 100%;">
                            Cancelar
                        </button>
                    </div>
                </div>
            </div>

        </div>
        `;
    },

    onOpen: function() {
        this.fetchAndPopulate();
    },

    closeApp: function() {
        this.closeNameModal();
        this.closePinModal();
    },

    fetchAndPopulate: function() {
        fetch(`https://${GetParentResourceName()}/getSettings`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).then(resp => resp.json()).then(settings => {
            if (settings) {
                this.settings = settings;
                this.tempWallpaper = settings.wallpaper_url;
                this.tempFrameColor = settings.frame_color;
                AuraCore.settings = settings;
                AuraCore.applySettings(settings);
                this.populateUI();
            }
        }).catch(err => {
            if (AuraCore.settings) {
                this.settings = AuraCore.settings;
                this.tempWallpaper = this.settings.wallpaper_url;
                this.tempFrameColor = this.settings.frame_color;
                this.populateUI();
            }
        });
    },

    populateUI: function() {
        if (!this.settings) return;

        // Perfil & Nombre
        const profileName = document.getElementById('settings-profile-name');
        const profileAvatar = document.getElementById('settings-profile-avatar');
        const deviceName = this.settings.device_name || "iPhone de Aura";
        if (profileName) profileName.innerText = deviceName;
        if (profileAvatar) profileAvatar.innerText = deviceName.charAt(0).toUpperCase();

        // Sincronizar temporales
        this.tempWallpaper = this.settings.wallpaper_url;
        this.tempFrameColor = this.settings.frame_color || "#00F0FF";

        // Wallpaper URL input
        const wpInput = document.getElementById('setting-wallpaper-url');
        if (wpInput) wpInput.value = this.tempWallpaper || "";

        // Resaltar preset activo con marco rosa y glow
        this.highlightActivePreset(this.tempWallpaper);

        // Resaltar color de marco activo con marco rosa y glow
        this.highlightActiveFrame(this.tempFrameColor);

        // Ringtone
        const ringtoneSelect = document.getElementById('setting-ringtone');
        if (ringtoneSelect && this.settings.ringtone) ringtoneSelect.value = this.settings.ringtone;

        // Volumes
        const volRing = document.getElementById('setting-volume-ring');
        const volRingLabel = document.getElementById('ring-volume-label');
        if (volRing) {
            volRing.value = this.settings.volume_ring !== undefined ? this.settings.volume_ring : 80;
            if (volRingLabel) volRingLabel.innerText = volRing.value + "%";
        }

        const volMsg = document.getElementById('setting-volume-msg');
        const volMsgLabel = document.getElementById('msg-volume-label');
        if (volMsg) {
            volMsg.value = this.settings.volume_msg !== undefined ? this.settings.volume_msg : 80;
            if (volMsgLabel) volMsgLabel.innerText = volMsg.value + "%";
        }

        // Face ID & PIN
        const faceIdCheck = document.getElementById('setting-face-id');
        if (faceIdCheck) faceIdCheck.checked = (this.settings.security && this.settings.security.face_id === true);

        const pinStatus = document.getElementById('setting-pin-status');
        if (pinStatus) {
            const hasPin = this.settings.security && this.settings.security.pin_code && this.settings.security.pin_code.length > 0;
            pinStatus.innerText = hasPin ? "Activado ••••" : "Desactivado";
            pinStatus.style.color = hasPin ? "var(--primary-cyan)" : "rgba(255,255,255,0.4)";
        }

        // Notificaciones
        if (this.settings.notifications) {
            const notifCalls = document.getElementById('notif-calls');
            const notifMsg = document.getElementById('notif-messages');
            const notifBank = document.getElementById('notif-bank');

            if (notifCalls) notifCalls.checked = (this.settings.notifications.calls !== false);
            if (notifMsg) notifMsg.checked = (this.settings.notifications.messages !== false);
            if (notifBank) notifBank.checked = (this.settings.notifications.bank !== false);
        }
    },

    // Resaltar visualmente el fondo activo
    highlightActivePreset: function(activeUrl) {
        const presets = document.querySelectorAll('.wp-preset');
        presets.forEach(preset => {
            const wpUrl = preset.getAttribute('data-wp');
            if (wpUrl === activeUrl) {
                preset.classList.add('active-wallpaper');
            } else {
                preset.classList.remove('active-wallpaper');
            }
        });
    },

    // Resaltar visualmente el color de marco activo
    highlightActiveFrame: function(activeColor) {
        const dots = document.querySelectorAll('.frame-color-dot');
        dots.forEach(dot => {
            const dotColor = dot.getAttribute('data-color');
            if (dotColor && dotColor.toLowerCase() === (activeColor || "").toLowerCase()) {
                dot.classList.add('active-frame');
            } else {
                dot.classList.remove('active-frame');
            }
        });
    },

    // Selección de preset (Live Preview)
    selectWallpaperPreset: function(url) {
        this.tempWallpaper = url;
        const input = document.getElementById('setting-wallpaper-url');
        if (input) input.value = url;
        this.highlightActivePreset(url);
        
        // Vista previa inmediata
        AuraCore.applySettings({
            ...this.settings,
            wallpaper_url: this.tempWallpaper,
            frame_color: this.tempFrameColor
        });
    },

    onWallpaperInput: function(url) {
        this.tempWallpaper = url.trim();
        this.highlightActivePreset(this.tempWallpaper);
        if (this.tempWallpaper.length > 5) {
            AuraCore.applySettings({
                ...this.settings,
                wallpaper_url: this.tempWallpaper,
                frame_color: this.tempFrameColor
            });
        }
    },

    applyWallpaperInput: function() {
        const input = document.getElementById('setting-wallpaper-url');
        if (input) {
            this.selectWallpaperPreset(input.value.trim());
        }
    },

    // Selección de color del marco (Live Preview)
    selectFrameColor: function(colorHex) {
        this.tempFrameColor = colorHex;
        this.highlightActiveFrame(colorHex);
        
        // Vista previa inmediata
        AuraCore.applySettings({
            ...this.settings,
            wallpaper_url: this.tempWallpaper,
            frame_color: this.tempFrameColor
        });
    },

    // Guardar definitivamente Pantalla y Aspecto en la BD
    saveAppearance: function() {
        if (!this.settings) this.settings = {};
        this.settings.wallpaper_url = this.tempWallpaper || this.settings.wallpaper_url;
        this.settings.frame_color = this.tempFrameColor || this.settings.frame_color;

        AuraCore.applySettings(this.settings);
        this.saveToServer();

        // Feedback visual en el botón
        const btn = document.getElementById('btn-save-appearance');
        if (btn) {
            btn.classList.add('saved');
            btn.innerHTML = '<i class="fas fa-check-circle" style="margin-right: 8px;"></i> ¡Guardado con Éxito!';
            setTimeout(() => {
                btn.classList.remove('saved');
                btn.innerHTML = '<i class="fas fa-save" style="margin-right: 8px;"></i> Guardar Pantalla y Aspecto';
            }, 2000);
        }
    },

    // Sonidos y Volúmenes
    updateRingtone: function(tone) {
        if (!this.settings) this.settings = {};
        this.settings.ringtone = tone;
        this.saveToServer();
    },

    updateVolumeRing: function(val) {
        if (!this.settings) this.settings = {};
        this.settings.volume_ring = parseInt(val);
        const label = document.getElementById('ring-volume-label');
        if (label) label.innerText = val + "%";
        AuraCore.applySettings(this.settings);
        this.saveToServer();
    },

    updateVolumeMsg: function(val) {
        if (!this.settings) this.settings = {};
        this.settings.volume_msg = parseInt(val);
        const label = document.getElementById('msg-volume-label');
        if (label) label.innerText = val + "%";
        AuraCore.applySettings(this.settings);
        this.saveToServer();
    },

    toggleFaceID: function(enabled) {
        if (!this.settings) this.settings = {};
        if (!this.settings.security) this.settings.security = {};
        this.settings.security.face_id = enabled;
        AuraCore.applySettings(this.settings);
        this.saveToServer();
    },

    toggleNotif: function(appKey, enabled) {
        if (!this.settings) this.settings = {};
        if (!this.settings.notifications) this.settings.notifications = {};
        this.settings.notifications[appKey] = enabled;
        AuraCore.applySettings(this.settings);
        this.saveToServer();
    },

    // Modal Nombre del Dispositivo
    openNameModal: function() {
        const modal = document.getElementById('settings-name-modal');
        const input = document.getElementById('modal-device-name-input');
        if (input) input.value = (this.settings && this.settings.device_name) ? this.settings.device_name : "iPhone de Aura";
        if (modal) modal.classList.remove('hidden');
    },

    closeNameModal: function() {
        const modal = document.getElementById('settings-name-modal');
        if (modal) modal.classList.add('hidden');
    },

    saveNameModal: function() {
        const input = document.getElementById('modal-device-name-input');
        const name = input ? input.value.trim() : "";
        if (!name || name === "") return;

        if (!this.settings) this.settings = {};
        this.settings.device_name = name;

        AuraCore.applySettings(this.settings);
        this.saveToServer();
        this.closeNameModal();
        this.populateUI();
    },

    // Modal PIN
    openPinModal: function() {
        const modal = document.getElementById('settings-pin-modal');
        const input = document.getElementById('modal-pin-input');
        const btnDisable = document.getElementById('btn-disable-pin');
        
        const hasPin = this.settings && this.settings.security && this.settings.security.pin_code && this.settings.security.pin_code.length > 0;
        
        if (input) input.value = hasPin ? this.settings.security.pin_code : "";
        if (btnDisable) {
            if (hasPin) {
                btnDisable.classList.remove('hidden');
            } else {
                btnDisable.classList.add('hidden');
            }
        }
        if (modal) modal.classList.remove('hidden');
    },

    closePinModal: function() {
        const modal = document.getElementById('settings-pin-modal');
        if (modal) modal.classList.add('hidden');
    },

    disablePin: function() {
        if (!this.settings) this.settings = {};
        if (!this.settings.security) this.settings.security = {};
        this.settings.security.pin_code = "";
        
        AuraCore.isLocked = false;
        AuraCore.applySettings(this.settings);
        this.saveToServer();
        this.closePinModal();
        this.populateUI();
    },

    savePinModal: function() {
        const input = document.getElementById('modal-pin-input');
        const pin = input ? input.value.trim() : "";
        
        if (!this.settings) this.settings = {};
        if (!this.settings.security) this.settings.security = {};
        this.settings.security.pin_code = pin;
        
        if (!pin || pin === "") {
            AuraCore.isLocked = false;
        }

        AuraCore.applySettings(this.settings);
        this.saveToServer();
        this.closePinModal();
        this.populateUI();
    },

    saveToServer: function() {
        if (!this.settings) return;
        AuraCore.settings = this.settings;
        fetch(`https://${GetParentResourceName()}/saveSettings`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(this.settings)
        });
    }
};

window.AuraSettingsApp = AuraSettingsApp;


