// =========================================
// AURA CONTACTS - JAVASCRIPT CONTROLLER
// =========================================

const AuraContactsApp = {
    allContacts: [],
    currentContact: null,
    ownInfo: { number: 'Cargando...', name: 'Mi Tarjeta' },
    incomingShareData: null,

    getHTML: function() {
        return `
        <div id="app-contacts-window" class="app-window" style="background: var(--bg-dark); position: absolute; width:100%; height:100%; top:0; left:0; overflow:hidden;">
            
            <!-- VISTA 1: Lista Principal de Contactos -->
            <div id="contacts-main-view" class="contacts-view">
                <div class="contacts-header">
                    <h2>Contactos</h2>
                    <i class="fas fa-plus contacts-add-btn" onclick="AuraContactsApp.openAddModal()" title="Nuevo Contacto"></i>
                </div>

                <div class="contacts-search-box">
                    <i class="fas fa-search"></i>
                    <input type="text" id="contacts-search-input" placeholder="Buscar contacto o número..." oninput="AuraContactsApp.filterContacts(this.value)">
                </div>

                <div class="contacts-scroll-area">
                    <!-- Mi Tarjeta con botón AirDrop -->
                    <div class="contacts-my-card" id="contacts-my-card">
                        <div class="contacts-my-avatar" id="contacts-my-avatar">M</div>
                        <div class="contacts-my-info">
                            <span class="contacts-my-name" id="contacts-my-name">Mi Tarjeta</span>
                            <span class="contacts-my-number" id="contacts-my-number">555-0000</span>
                        </div>
                        <div class="contacts-my-airdrop-btn" onclick="AuraContactsApp.openNearbyShareModal()" title="Compartir por Proximidad (AirDrop)">
                            <i class="fas fa-broadcast-tower"></i>
                            <span>Compartir</span>
                        </div>
                    </div>

                    <!-- Sección Favoritos (Se oculta si no hay) -->
                    <div id="contacts-fav-section" class="contacts-section hidden">
                        <div class="contacts-section-title"><i class="fas fa-star" style="color:#FFD700; margin-right:5px;"></i> Favoritos</div>
                        <div id="contacts-fav-list" class="contacts-fav-grid">
                            <!-- Poblado por JS -->
                        </div>
                    </div>

                    <!-- Lista Alfabética Completa -->
                    <div id="contacts-alphabet-container">
                        <!-- Poblado por JS -->
                    </div>
                </div>
            </div>

            <!-- VISTA 2: Ficha Detallada del Contacto -->
            <div id="contacts-detail-view" class="contacts-view" style="display: none;">
                <div class="contacts-detail-header">
                    <i class="fas fa-chevron-left" onclick="AuraContactsApp.closeDetailView()"></i>
                    <span class="contacts-edit-action" onclick="AuraContactsApp.openEditModal()">Editar</span>
                </div>

                <div class="contacts-detail-content">
                    <div class="contacts-detail-avatar" id="detail-avatar">A</div>
                    <h2 class="contacts-detail-name" id="detail-name">Nombre Contacto</h2>
                    <p class="contacts-detail-number" id="detail-number">555-0000</p>

                    <!-- Barra de 4 Botones de Acción Rápida -->
                    <div class="contacts-actions-bar">
                        <div class="contacts-action-item" onclick="AuraContactsApp.actionCall()">
                            <div class="action-btn-circle call-glow"><i class="fas fa-phone"></i></div>
                            <span>Llamar</span>
                        </div>
                        <div class="contacts-action-item" onclick="AuraContactsApp.actionMessage()">
                            <div class="action-btn-circle msg-glow"><i class="fas fa-comment"></i></div>
                            <span>Mensaje</span>
                        </div>
                        <div class="contacts-action-item" onclick="AuraContactsApp.actionLocation()">
                            <div class="action-btn-circle loc-glow"><i class="fas fa-map-marker-alt"></i></div>
                            <span>Ubicación</span>
                        </div>
                        <div class="contacts-action-item" onclick="AuraContactsApp.actionToggleFavorite()">
                            <div class="action-btn-circle fav-glow" id="detail-fav-btn"><i class="fas fa-star"></i></div>
                            <span id="detail-fav-label">Favorito</span>
                        </div>
                    </div>

                    <!-- Ficha de Datos -->
                    <div class="contacts-card-info">
                        <div class="card-info-row">
                            <span class="card-info-label">Teléfono Móvil</span>
                            <span class="card-info-value" id="detail-card-number">555-0000</span>
                        </div>
                        <div class="card-info-row">
                            <span class="card-info-label">Notas</span>
                            <span class="card-info-value" id="detail-card-notes">Sin notas adicionales</span>
                        </div>
                    </div>

                    <!-- Botón Eliminar Contacto -->
                    <button class="contacts-delete-btn" onclick="AuraContactsApp.deleteCurrentContact()">
                        <i class="fas fa-trash-alt" style="margin-right:8px;"></i> Eliminar Contacto
                    </button>
                </div>
            </div>

            <!-- MODAL: Crear / Editar Contacto -->
            <div id="contacts-form-modal" class="msg-modal-overlay hidden">
                <div class="msg-modal-header">
                    <h3 id="contacts-form-title">Nuevo Contacto</h3>
                    <i class="fas fa-times msg-modal-close" onclick="AuraContactsApp.closeFormModal()"></i>
                </div>
                
                <input type="hidden" id="form-contact-id">
                <input type="text" id="form-contact-name" class="msg-modal-input" placeholder="Nombre completo">
                <input type="text" id="form-contact-number" class="msg-modal-input" placeholder="Número de teléfono (ej: 555-1234)">
                <input type="text" id="form-contact-notes" class="msg-modal-input" placeholder="Notas (opcional, ej: Mecánico Los Santos)">
                
                <button class="msg-modal-btn" onclick="AuraContactsApp.submitContactForm()">Guardar Contacto</button>
            </div>

            <!-- MODAL: Escáner AirDrop / Proximidad -->
            <div id="contacts-airdrop-modal" class="msg-modal-overlay hidden">
                <div class="msg-modal-header">
                    <h3><i class="fas fa-broadcast-tower" style="color:var(--primary-cyan); margin-right:8px;"></i> Compartir Cercano</h3>
                    <i class="fas fa-times msg-modal-close" onclick="AuraContactsApp.closeNearbyShareModal()"></i>
                </div>
                
                <p style="color:rgba(255,255,255,0.6); font-size:12px; margin-bottom:15px;">
                    Personas en tus proximidades (menos de 3.5m):
                </p>

                <div id="contacts-nearby-list" class="contacts-nearby-list">
                    <!-- Lista poblada por JS -->
                </div>
            </div>

            <!-- MODAL: Solicitud Entrante de Contacto -->
            <div id="contacts-incoming-modal" class="msg-modal-overlay hidden">
                <div class="incoming-share-card">
                    <div class="incoming-share-icon"><i class="fas fa-user-plus"></i></div>
                    <h3>Contacto Recibido</h3>
                    <p id="incoming-share-text" style="color:rgba(255,255,255,0.7); font-size:13px; margin-bottom:15px;">
                        Quieren compartir su número contigo:
                    </p>
                    
                    <div class="incoming-contact-preview">
                        <div class="incoming-avatar" id="incoming-avatar">C</div>
                        <div class="incoming-info">
                            <span class="incoming-name" id="incoming-name">Nombre</span>
                            <span class="incoming-number" id="incoming-number">555-XXXX</span>
                        </div>
                    </div>

                    <div class="incoming-buttons">
                        <button class="btn-accept-share" onclick="AuraContactsApp.acceptIncomingContact()">
                            <i class="fas fa-check" style="margin-right:6px;"></i> Aceptar
                        </button>
                        <button class="btn-reject-share" onclick="AuraContactsApp.rejectIncomingContact()">
                            <i class="fas fa-times" style="margin-right:6px;"></i> Rechazar
                        </button>
                    </div>
                </div>
            </div>

        </div>
        `;
    },

    onOpen: function() {
        this.fetchOwnInfo();
        this.fetchContacts();
    },

    closeApp: function() {
        this.closeFormModal();
        this.closeNearbyShareModal();
        this.closeDetailView();
    },

    fetchOwnInfo: function() {
        fetch(`https://${GetParentResourceName()}/getOwnInfo`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).then(resp => resp.json()).then(data => {
            if (data) {
                this.ownInfo = data;
                const nameEl = document.getElementById('contacts-my-name');
                const numEl = document.getElementById('contacts-my-number');
                const avatarEl = document.getElementById('contacts-my-avatar');
                if (nameEl) nameEl.innerText = data.name || "Mi Tarjeta";
                if (numEl) numEl.innerText = data.number || "555-0000";
                if (avatarEl && data.name) avatarEl.innerText = data.name.charAt(0).toUpperCase();
            }
        }).catch(err => console.error("Error fetching own info:", err));
    },

    fetchContacts: function() {
        fetch(`https://${GetParentResourceName()}/getAllContacts`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).then(resp => resp.json()).then(data => {
            this.allContacts = data || [];
            this.renderContacts(this.allContacts);
        }).catch(err => console.error("Error fetching contacts:", err));
    },

    renderContacts: function(contacts) {
        const alphabetContainer = document.getElementById('contacts-alphabet-container');
        const favSection = document.getElementById('contacts-fav-section');
        const favList = document.getElementById('contacts-fav-list');
        
        if (!alphabetContainer) return;
        alphabetContainer.innerHTML = '';
        if (favList) favList.innerHTML = '';

        if (!contacts || contacts.length === 0) {
            alphabetContainer.innerHTML = `
                <div style="text-align:center; margin-top:40px; color:rgba(255,255,255,0.4); font-size:13px;">
                    <i class="fas fa-address-book" style="font-size:32px; display:block; margin-bottom:10px; opacity:0.3;"></i>
                    No tienes contactos guardados.<br>Pulsa el botón + arriba para añadir uno.
                </div>
            `;
            if (favSection) favSection.classList.add('hidden');
            return;
        }

        // Render Favoritos
        const favorites = contacts.filter(c => c.is_favorite == 1);
        if (favorites.length > 0 && favSection && favList) {
            favSection.classList.remove('hidden');
            favorites.forEach(fav => {
                const initial = fav.contact_name.charAt(0).toUpperCase();
                const avatarHtml = fav.avatar_url 
                    ? `<img src="${fav.avatar_url}" style="width:100%; height:100%; border-radius:50%; object-fit:cover;">` 
                    : initial;
                favList.innerHTML += `
                    <div class="contacts-fav-card" onclick="AuraContactsApp.openDetailView(${fav.id})">
                        <div class="fav-card-avatar">${avatarHtml}</div>
                        <span class="fav-card-name">${fav.contact_name}</span>
                    </div>
                `;
            });
        } else if (favSection) {
            favSection.classList.add('hidden');
        }

        // Agrupación Alfabética (A-Z)
        const grouped = {};
        contacts.forEach(c => {
            const firstLetter = (c.contact_name.charAt(0) || '#').toUpperCase();
            const key = (firstLetter >= 'A' && firstLetter <= 'Z') ? firstLetter : '#';
            if (!grouped[key]) grouped[key] = [];
            grouped[key].push(c);
        });

        const sortedKeys = Object.keys(grouped).sort();
        let alphabetHtml = '';
        sortedKeys.forEach(letter => {
            let letterGroupHtml = `
                <div class="contacts-letter-group">
                    <div class="contacts-letter-header">${letter}</div>
                    <div class="contacts-letter-list">
            `;

            grouped[letter].forEach(contact => {
                const initial = contact.contact_name.charAt(0).toUpperCase();
                const avatarHtml = contact.avatar_url 
                    ? `<img src="${contact.avatar_url}" style="width:100%; height:100%; border-radius:50%; object-fit:cover;">` 
                    : initial;
                const star = contact.is_favorite == 1 ? '<i class="fas fa-star" style="color:#FFD700; margin-left:auto; font-size:12px;"></i>' : '';
                
                letterGroupHtml += `
                    <div class="contacts-row-item" onclick="AuraContactsApp.openDetailView(${contact.id})">
                        <div class="contacts-row-avatar">${avatarHtml}</div>
                        <div class="contacts-row-info">
                            <span class="contacts-row-name">${contact.contact_name}</span>
                            <span class="contacts-row-num">${contact.contact_number}</span>
                        </div>
                        ${star}
                    </div>
                `;
            });

            letterGroupHtml += `</div></div>`;
            alphabetHtml += letterGroupHtml;
        });
        alphabetContainer.innerHTML = alphabetHtml;
    },

    filterContacts: function(query) {
        if (!query || query.trim() === '') {
            this.renderContacts(this.allContacts);
            return;
        }

        const q = query.toLowerCase().trim();
        const filtered = this.allContacts.filter(c => 
            c.contact_name.toLowerCase().includes(q) || 
            c.contact_number.toLowerCase().includes(q)
        );
        this.renderContacts(filtered);
    },

    // Ficha de Detalle
    openDetailView: function(contactId) {
        const contact = this.allContacts.find(c => c.id === contactId);
        if (!contact) return;
        this.currentContact = contact;

        const avatarElem = document.getElementById('detail-avatar');
        if (avatarElem) {
            if (contact.avatar_url) {
                avatarElem.innerHTML = `<img src="${contact.avatar_url}" style="width:100%; height:100%; border-radius:50%; object-fit:cover;">`;
            } else {
                avatarElem.innerText = contact.contact_name.charAt(0).toUpperCase();
            }
        }
        document.getElementById('detail-name').innerText = contact.contact_name;
        document.getElementById('detail-number').innerText = contact.contact_number;
        document.getElementById('detail-card-number').innerText = contact.contact_number;
        document.getElementById('detail-card-notes').innerText = contact.note && contact.note !== '' ? contact.note : 'Sin notas adicionales';

        const favBtn = document.getElementById('detail-fav-btn');
        const favLabel = document.getElementById('detail-fav-label');
        if (contact.is_favorite == 1) {
            if (favBtn) favBtn.classList.add('active');
            if (favLabel) favLabel.innerText = 'Favorito ★';
        } else {
            if (favBtn) favBtn.classList.remove('active');
            if (favLabel) favLabel.innerText = 'Favorito';
        }

        const mainView = document.getElementById('contacts-main-view');
        const detailView = document.getElementById('contacts-detail-view');
        if (mainView) mainView.style.display = 'none';
        if (detailView) {
            detailView.classList.remove('hidden');
            detailView.style.display = 'flex';
        }
    },

    closeDetailView: function() {
        this.currentContact = null;
        const mainView = document.getElementById('contacts-main-view');
        const detailView = document.getElementById('contacts-detail-view');
        if (detailView) {
            detailView.classList.add('hidden');
            detailView.style.display = 'none';
        }
        if (mainView) {
            mainView.classList.remove('hidden');
            mainView.style.display = 'flex';
        }
    },

    // Acciones directas
    actionCall: function() {
        if (!this.currentContact) return;
        const num = this.currentContact.contact_number;
        
        AuraCore.openApp('app-phone');
        if (window.AuraPhoneApp) {
            AuraPhoneApp.dialString = num;
            AuraPhoneApp.updateDialDisplay();
            AuraPhoneApp.startCall();
        }
    },

    actionMessage: function() {
        if (!this.currentContact) return;
        const num = this.currentContact.contact_number;
        const name = this.currentContact.contact_name;

        AuraCore.openApp('app-messages');
        if (window.AuraMessagesApp) {
            AuraMessagesApp.openActiveChat(null, num, name);
        }
    },

    actionLocation: function() {
        if (!this.currentContact) return;
        const num = this.currentContact.contact_number;
        const name = this.currentContact.contact_name;

        fetch(`https://${GetParentResourceName()}/shareLocationWithContact`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ number: num, name: name })
        });
    },

    actionToggleFavorite: function() {
        if (!this.currentContact) return;
        const newStatus = this.currentContact.is_favorite == 1 ? 0 : 1;
        
        fetch(`https://${GetParentResourceName()}/toggleFavoriteContact`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ id: this.currentContact.id, is_favorite: newStatus == 1 })
        }).then(resp => resp.json()).then(res => {
            if (res.success) {
                this.currentContact.is_favorite = newStatus;
                this.openDetailView(this.currentContact.id);
                this.fetchContacts();
            }
        });
    },

    // Modal Crear / Editar
    openAddModal: function() {
        document.getElementById('contacts-form-title').innerText = "Nuevo Contacto";
        document.getElementById('form-contact-id').value = "";
        document.getElementById('form-contact-name').value = "";
        document.getElementById('form-contact-number').value = "";
        document.getElementById('form-contact-notes').value = "";
        
        const modal = document.getElementById('contacts-form-modal');
        if (modal) modal.classList.remove('hidden');
    },

    openEditModal: function() {
        if (!this.currentContact) return;
        document.getElementById('contacts-form-title').innerText = "Editar Contacto";
        document.getElementById('form-contact-id').value = this.currentContact.id;
        document.getElementById('form-contact-name').value = this.currentContact.contact_name;
        document.getElementById('form-contact-number').value = this.currentContact.contact_number;
        document.getElementById('form-contact-notes').value = this.currentContact.note || "";
        
        const modal = document.getElementById('contacts-form-modal');
        if (modal) modal.classList.remove('hidden');
    },

    closeFormModal: function() {
        const modal = document.getElementById('contacts-form-modal');
        if (modal) modal.classList.add('hidden');
    },

    submitContactForm: function() {
        const id = document.getElementById('form-contact-id').value;
        const name = document.getElementById('form-contact-name').value.trim();
        const number = document.getElementById('form-contact-number').value.trim();
        const notes = document.getElementById('form-contact-notes').value.trim();

        if (!name || !number) {
            return;
        }

        fetch(`https://${GetParentResourceName()}/saveContact`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                id: id !== "" ? parseInt(id) : null,
                name: name,
                number: number,
                note: notes
            })
        }).then(resp => resp.json()).then(res => {
            if (res.success) {
                this.closeFormModal();
                this.fetchContacts();
                if (id !== "" && this.currentContact) {
                    this.currentContact.contact_name = name;
                    this.currentContact.contact_number = number;
                    this.currentContact.note = notes;
                    this.openDetailView(parseInt(id));
                }
            }
        });
    },

    deleteCurrentContact: function() {
        if (!this.currentContact) return;
        
        fetch(`https://${GetParentResourceName()}/deleteContact`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ id: this.currentContact.id })
        }).then(resp => resp.json()).then(res => {
            if (res.success) {
                this.closeDetailView();
                this.fetchContacts();
            }
        });
    },

    // =========================================
    // AIRDROP / PROXIMITY SHARING
    // =========================================

    openNearbyShareModal: function() {
        const modal = document.getElementById('contacts-airdrop-modal');
        const listContainer = document.getElementById('contacts-nearby-list');
        if (!modal || !listContainer) return;

        modal.classList.remove('hidden');
        listContainer.innerHTML = '<div style="color:rgba(255,255,255,0.4); text-align:center; padding:20px;"><i class="fas fa-spinner fa-spin" style="font-size:24px; display:block; margin-bottom:10px; color:var(--primary-cyan);"></i>Escaneando personas cercanas...</div>';

        fetch(`https://${GetParentResourceName()}/getNearbyPlayers`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).then(resp => resp.json()).then(players => {
            listContainer.innerHTML = '';
            if (!players || players.length === 0) {
                listContainer.innerHTML = '<div style="color:rgba(255,255,255,0.4); text-align:center; padding:25px; font-size:13px;"><i class="fas fa-user-slash" style="font-size:28px; display:block; margin-bottom:10px; opacity:0.3;"></i>No hay nadie en tus proximidades.<br>Acércate a otra persona para compartir tu contacto.</div>';
                return;
            }

            players.forEach(p => {
                const initial = p.name.charAt(0).toUpperCase();
                listContainer.innerHTML += `
                    <div class="nearby-player-row" onclick="AuraContactsApp.sendMyContactTo(${p.serverId}, '${p.name}')">
                        <div class="nearby-player-avatar">${initial}</div>
                        <div class="nearby-player-info">
                            <span class="nearby-player-name">${p.name}</span>
                            <span class="nearby-player-id">ID: ${p.serverId} • ${p.number}</span>
                        </div>
                        <i class="fas fa-paper-plane nearby-send-icon"></i>
                    </div>
                `;
            });
        }).catch(err => {
            listContainer.innerHTML = '<div style="color:rgba(255,255,255,0.3); text-align:center;">Error al escanear</div>';
        });
    },

    closeNearbyShareModal: function() {
        const modal = document.getElementById('contacts-airdrop-modal');
        if (modal) modal.classList.add('hidden');
    },

    sendMyContactTo: function(serverId, name) {
        fetch(`https://${GetParentResourceName()}/sendContactShare`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ targetServerId: serverId })
        }).then(resp => resp.json()).then(res => {
            this.closeNearbyShareModal();
        });
    },

    // Manejar evento de solicitud entrante
    handleIncomingEvent: function(action, payload) {
        if (action === "incomingContactShare") {
            const data = payload.data;
            this.incomingShareData = data;

            const modal = document.getElementById('contacts-incoming-modal');
            const nameEl = document.getElementById('incoming-name');
            const numEl = document.getElementById('incoming-number');
            const avatarEl = document.getElementById('incoming-avatar');

            if (nameEl) nameEl.innerText = data.name || "Ciudadano";
            if (numEl) numEl.innerText = data.number || "555-0000";
            if (avatarEl && data.name) avatarEl.innerText = data.name.charAt(0).toUpperCase();

            // Abrir modal
            if (modal) modal.classList.remove('hidden');
        }
    },

    acceptIncomingContact: function() {
        if (!this.incomingShareData) return;

        fetch(`https://${GetParentResourceName()}/acceptContactShare`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(this.incomingShareData)
        }).then(resp => resp.json()).then(res => {
            this.rejectIncomingContact(); // Ocultar modal
            this.fetchContacts(); // Recargar contactos
        });
    },

    rejectIncomingContact: function() {
        this.incomingShareData = null;
        const modal = document.getElementById('contacts-incoming-modal');
        if (modal) modal.classList.add('hidden');
    }
};

// Escucha del NUI general para pasar eventos a ContactsApp si es necesario
window.addEventListener('message', function(event) {
    if (event.data.app === 'contacts') {
        AuraContactsApp.handleIncomingEvent(event.data.action, event.data);
    }
});

// Registrar app globalmente para que el Core de Aura OS pueda invocar getHTML() y onOpen()
window.AuraContactsApp = AuraContactsApp;

