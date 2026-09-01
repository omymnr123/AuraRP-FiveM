// ===================================================
// AURA GALLERY APP (iOS-Tier Multimedia Ecosystem)
// ===================================================

const AuraGalleryApp = {
    mediaItems: [],
    selectedMedia: null,
    contactsList: [],

    getHTML: function() {
        return `
            <div id="app-gallery-window" class="app-window gallery-window">
                <!-- Header Galería -->
                <div class="gallery-header">
                    <div class="gallery-header-left">
                        <i class="fas fa-images gallery-header-icon"></i>
                        <span>Fotos</span>
                    </div>
                    <div class="gallery-header-stats" id="gallery-header-stats">
                        0 Fotos
                    </div>
                </div>

                <!-- Grid de Fotos -->
                <div class="gallery-content">
                    <div class="gallery-grid" id="gallery-grid">
                        <!-- Inyectado dinámicamente -->
                    </div>

                    <!-- Empty State -->
                    <div id="gallery-empty-state" class="gallery-empty-state hidden">
                        <div class="empty-icon-circle">
                            <i class="fas fa-camera-retro"></i>
                        </div>
                        <h3>Sin fotos aún</h3>
                        <p>Abre la aplicación de Cámara para capturar momentos en Los Santos.</p>
                        <button class="btn-open-camera" onclick="AuraCore.openApp('app-camera')">
                            <i class="fas fa-camera"></i> Abrir Cámara
                        </button>
                    </div>
                </div>

                <!-- OVERLAY: Vista Pantalla Completa de Foto con Action Sheet -->
                <div id="gallery-fullscreen-view" class="gallery-fullscreen-view hidden">
                    <div class="gallery-fs-topbar">
                        <button class="fs-nav-btn" onclick="AuraGalleryApp.closeFullscreen()">
                            <i class="fas fa-chevron-left"></i> Fotos
                        </button>
                        <span class="fs-photo-date" id="fs-photo-date">Hoy</span>
                        <button class="fs-nav-btn fs-nav-close" onclick="AuraGalleryApp.closeFullscreen()">
                            <i class="fas fa-times"></i>
                        </button>
                    </div>

                    <div class="gallery-fs-img-container">
                        <img id="gallery-fs-img" src="" alt="Aura Media">
                    </div>

                    <!-- Bottom iOS-Tier Action Sheet -->
                    <div class="gallery-action-sheet" id="gallery-action-sheet">
                        <div class="sheet-handle"></div>
                        <div class="sheet-actions-grid">
                            <!-- Acción 1: Fondo de Pantalla -->
                            <div class="sheet-action-item" onclick="AuraGalleryApp.setAsWallpaper()">
                                <div class="sheet-action-icon wallpaper-icon">
                                    <i class="fas fa-image"></i>
                                </div>
                                <span>Fondo de Pantalla</span>
                            </div>

                            <!-- Acción 2: Asignar a Contacto -->
                            <div class="sheet-action-item" onclick="AuraGalleryApp.openContactPicker()">
                                <div class="sheet-action-icon contact-icon">
                                    <i class="fas fa-user-circle"></i>
                                </div>
                                <span>Asignar a Contacto</span>
                            </div>

                            <!-- Acción 3: Compartir por Mensaje -->
                            <div class="sheet-action-item" onclick="AuraGalleryApp.shareInChat()">
                                <div class="sheet-action-icon share-icon">
                                    <i class="fas fa-paper-plane"></i>
                                </div>
                                <span>Enviar Mensaje</span>
                            </div>

                            <!-- Acción 4: Eliminar -->
                            <div class="sheet-action-item delete-action" onclick="AuraGalleryApp.deleteSelectedPhoto()">
                                <div class="sheet-action-icon delete-icon">
                                    <i class="fas fa-trash-alt"></i>
                                </div>
                                <span>Eliminar</span>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- MODAL: Contact Picker para Asignar Avatar -->
                <div id="gallery-contact-picker-modal" class="gallery-picker-modal hidden">
                    <div class="picker-modal-backdrop" onclick="AuraGalleryApp.closeContactPicker()"></div>
                    <div class="picker-modal-content">
                        <div class="picker-modal-header">
                            <h3>Asignar Foto a Contacto</h3>
                            <button onclick="AuraGalleryApp.closeContactPicker()"><i class="fas fa-times"></i></button>
                        </div>
                        <div class="picker-search-box">
                            <i class="fas fa-search"></i>
                            <input type="text" id="picker-search-input" placeholder="Buscar contacto..." oninput="AuraGalleryApp.filterPickerContacts()">
                        </div>
                        <div class="picker-contacts-list" id="picker-contacts-list">
                            <!-- Inyectado dinámicamente -->
                        </div>
                    </div>
                </div>
            </div>
        `;
    },

    onOpen: function() {
        this.fetchGallery();
    },

    fetchGallery: function() {
        fetch(`https://${GetParentResourceName()}/getGallery`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).then(resp => resp.json()).then(data => {
            this.mediaItems = data || [];
            this.renderGrid();
        }).catch(err => {
            console.error("Error fetching gallery:", err);
            this.mediaItems = [];
            this.renderGrid();
        });
    },

    renderGrid: function() {
        const grid = document.getElementById('gallery-grid');
        const emptyState = document.getElementById('gallery-empty-state');
        const stats = document.getElementById('gallery-header-stats');
        if (!grid) return;

        grid.innerHTML = '';
        if (stats) stats.innerText = `${this.mediaItems.length} Fotos`;

        if (this.mediaItems.length === 0) {
            if (emptyState) emptyState.classList.remove('hidden');
            return;
        }

        if (emptyState) emptyState.classList.add('hidden');

        this.mediaItems.forEach(item => {
            const card = document.createElement('div');
            card.className = 'gallery-item-card';
            card.innerHTML = `
                <img src="${item.media_url}" alt="Foto" loading="lazy" onerror="this.src='https://images.unsplash.com/photo-1542751371-adc38448a05e?w=500'">
                <div class="item-card-glow"></div>
            `;
            card.onclick = () => this.openFullscreen(item);
            grid.appendChild(card);
        });
    },

    openFullscreen: function(item) {
        this.selectedMedia = item;
        const fsView = document.getElementById('gallery-fullscreen-view');
        const fsImg = document.getElementById('gallery-fs-img');
        const fsDate = document.getElementById('fs-photo-date');

        if (fsView && fsImg) {
            fsImg.src = item.media_url;
            if (fsDate && item.created_at) {
                const dateObj = new Date(item.created_at);
                fsDate.innerText = !isNaN(dateObj.getTime()) ? dateObj.toLocaleDateString('es-ES', { day: 'numeric', month: 'short' }) : 'Reciente';
            }
            fsView.classList.remove('hidden');
        }
    },

    closeFullscreen: function() {
        const fsView = document.getElementById('gallery-fullscreen-view');
        if (fsView) fsView.classList.add('hidden');
        this.selectedMedia = null;
    },

    // 1. Establecer como Fondo de Pantalla
    setAsWallpaper: function() {
        if (!this.selectedMedia) return;
        const newUrl = this.selectedMedia.media_url;

        // Actualizar estado en Ajustes
        if (window.AuraSettingsApp) {
            window.AuraSettingsApp.settings.wallpaper_url = newUrl;
            window.AuraSettingsApp.saveSettingsDirectly({ wallpaper_url: newUrl });
        }

        // Actualizar visualmente fondos
        if (window.AuraCore) {
            if (AuraCore.settings) AuraCore.settings.wallpaper_url = newUrl;
            AuraCore.applyWallpaper(newUrl);
        }

        this.showToast("Fondo de pantalla actualizado con éxito", "success");
    },

    // 2. Asignar como Avatar a Contacto
    openContactPicker: function() {
        if (!this.selectedMedia) return;
        const modal = document.getElementById('gallery-contact-picker-modal');
        if (!modal) return;

        modal.classList.remove('hidden');

        fetch(`https://${GetParentResourceName()}/getAllContacts`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).then(resp => resp.json()).then(contacts => {
            this.contactsList = contacts || [];
            this.renderPickerContacts(this.contactsList);
        });
    },

    closeContactPicker: function() {
        const modal = document.getElementById('gallery-contact-picker-modal');
        if (modal) modal.classList.add('hidden');
    },

    renderPickerContacts: function(list) {
        const container = document.getElementById('picker-contacts-list');
        if (!container) return;
        container.innerHTML = '';

        if (list.length === 0) {
            container.innerHTML = '<div class="picker-no-contacts">No tienes contactos guardados</div>';
            return;
        }

        list.forEach(c => {
            const item = document.createElement('div');
            item.className = 'picker-contact-row';
            item.innerHTML = `
                <div class="picker-contact-avatar">
                    ${c.avatar_url ? `<img src="${c.avatar_url}" alt="${c.contact_name}">` : c.contact_name.charAt(0).toUpperCase()}
                </div>
                <div class="picker-contact-info">
                    <span class="picker-name">${c.contact_name}</span>
                    <span class="picker-num">${c.contact_number}</span>
                </div>
                <i class="fas fa-check picker-select-icon"></i>
            `;
            item.onclick = () => this.assignAvatarToContact(c.id, c.contact_name);
            container.appendChild(item);
        });
    },

    filterPickerContacts: function() {
        const query = (document.getElementById('picker-search-input').value || '').toLowerCase();
        const filtered = this.contactsList.filter(c => 
            c.contact_name.toLowerCase().includes(query) || c.contact_number.includes(query)
        );
        this.renderPickerContacts(filtered);
    },

    assignAvatarToContact: function(contactId, contactName) {
        if (!this.selectedMedia) return;
        const avatarUrl = this.selectedMedia.media_url;

        fetch(`https://${GetParentResourceName()}/setContactAvatar`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ contactId: contactId, avatarUrl: avatarUrl })
        }).then(resp => resp.json()).then(data => {
            if (data.success) {
                this.showToast(`Avatar asignado a ${contactName}`, "success");
                this.closeContactPicker();
                if (window.AuraContactsApp) {
                    window.AuraContactsApp.loadContacts();
                }
            } else {
                this.showToast("Error al asignar avatar", "error");
            }
        });
    },

    // 3. Compartir en Mensajes
    shareInChat: function() {
        if (!this.selectedMedia) return;
        const url = this.selectedMedia.media_url;
        this.closeFullscreen();
        if (window.AuraCore && window.AuraMessagesApp) {
            AuraCore.openApp('app-messages');
            this.showToast("Copia la URL o adjúntala en el chat", "info");
        }
    },

    // 4. Eliminar Foto
    deleteSelectedPhoto: function() {
        if (!this.selectedMedia) return;
        const photoId = this.selectedMedia.id;

        if (confirm("¿Estás seguro de que deseas eliminar esta foto de tu galería?")) {
            fetch(`https://${GetParentResourceName()}/deleteGalleryMedia`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ id: photoId })
            }).then(resp => resp.json()).then(data => {
                if (data.success) {
                    this.showToast("Foto eliminada correctamente", "success");
                    this.mediaItems = this.mediaItems.filter(m => m.id !== photoId);
                    this.closeFullscreen();
                    this.renderGrid();
                }
            });
        }
    },

    showToast: function(message, type) {
        if (window.AuraCore) {
            AuraCore.addNotification({
                app: 'gallery',
                title: 'Aura Galería',
                message: message,
                icon: type === 'success' ? 'fas fa-check-circle' : 'fas fa-info-circle',
                color: type === 'success' ? '#00F0FF' : '#FF0055'
            });
        }
    }
};

window.AuraGalleryApp = AuraGalleryApp;
