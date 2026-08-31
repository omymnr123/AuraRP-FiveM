const AuraMessagesApp = {
    currentChatId: null,
    targetNumber: null,
    targetName: null,

    getHTML: function() {
        return `
        <div id="app-messages-window" class="app-window">
            <!-- VISTA 1: Lista de Chats -->
            <div id="msg-chat-list" class="msg-view">
                <div class="msg-header">
                    <h2>Mensajes</h2>
                    <i class="fas fa-edit msg-new-chat-btn" onclick="AuraMessagesApp.openNewChatModal()"></i>
                </div>
                <div id="msg-chat-list-container">
                    <!-- Poblado por JS -->
                </div>
            </div>

            <!-- VISTA 2: Chat Activo -->
            <div id="msg-active-chat" class="msg-view" style="display:none;">
                <div class="msg-active-header">
                    <i class="fas fa-chevron-left" onclick="AuraMessagesApp.closeActiveChat()"></i>
                    <div class="msg-active-info">
                        <span id="msg-active-chat-name">Nombre</span>
                    </div>
                    <i class="fas fa-video"></i>
                </div>
                
                <div id="msg-bubbles-container" class="msg-bubbles-container">
                    <!-- Burbujas pobladas por JS -->
                </div>

                <div class="msg-input-zone">
                    <i class="fas fa-plus msg-attach-btn" onclick="AuraMessagesApp.toggleAttachments()"></i>
                    <input type="text" id="msg-input" placeholder="Mensaje..." onkeypress="if(event.key === 'Enter') AuraMessagesApp.sendMessage('text')">
                    <button class="msg-send-btn" onclick="AuraMessagesApp.sendMessage('text')"><i class="fas fa-paper-plane"></i></button>
                    
                    <!-- Menú de adjuntos oculto -->
                    <div id="msg-attachments-menu" class="msg-attachments-menu hidden">
                        <div class="msg-attach-item" title="Enviar Foto" onclick="AuraMessagesApp.openImageModal()"><i class="fas fa-camera"></i></div>
                        <div class="msg-attach-item" title="Compartir Ubicación" onclick="AuraMessagesApp.sendLocation()"><i class="fas fa-map-marker-alt"></i></div>
                        <div class="msg-attach-item" title="Nota de Voz"><i class="fas fa-microphone"></i></div>
                    </div>
                </div>
            </div>

            <!-- MODAL: Nuevo Chat -->
            <div id="msg-new-chat-modal" class="msg-modal-overlay hidden">
                <div class="msg-modal-header">
                    <h3>Nuevo Mensaje</h3>
                    <i class="fas fa-times msg-modal-close" onclick="AuraMessagesApp.closeNewChatModal()"></i>
                </div>
                <input type="text" id="msg-new-chat-number" class="msg-modal-input" placeholder="Número (ej: 555-1234)" onkeypress="if(event.key === 'Enter') AuraMessagesApp.confirmNewChat()">
                <button class="msg-modal-btn" onclick="AuraMessagesApp.confirmNewChat()">Iniciar Conversación</button>
                
                <div class="msg-modal-contacts-title">O elige un contacto:</div>
                <div id="msg-modal-contacts-list" class="msg-modal-contacts-list">
                    <!-- Contactos cargados dinámicamente -->
                </div>
            </div>

            <!-- MODAL: Enviar Imagen -->
            <div id="msg-image-modal" class="msg-modal-overlay hidden">
                <div class="msg-modal-header">
                    <h3>Enviar Imagen</h3>
                    <i class="fas fa-times msg-modal-close" onclick="AuraMessagesApp.closeImageModal()"></i>
                </div>
                <input type="text" id="msg-image-url-input" class="msg-modal-input" placeholder="https://i.imgur.com/ejemplo.png" onkeypress="if(event.key === 'Enter') AuraMessagesApp.confirmSendImage()">
                <button class="msg-modal-btn" onclick="AuraMessagesApp.confirmSendImage()">Enviar Foto</button>
            </div>
        </div>
        `;
    },

    onOpen: function() {
        this.fetchChatList();
    },

    closeApp: function() {
        this.closeNewChatModal();
        this.closeImageModal();
        this.closeActiveChat();
    },

    fetchChatList: function() {
        fetch(`https://${GetParentResourceName()}/getChats`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).then(resp => resp.json()).then(data => {
            const list = document.getElementById('msg-chat-list-container');
            if (!list) return;
            list.innerHTML = '';
            
            if (!data || data.length === 0) {
                list.innerHTML = '<div style="text-align:center; margin-top:40px; color:rgba(255,255,255,0.4); font-size:13px;"><i class="fas fa-comments" style="font-size:32px; display:block; margin-bottom:10px; opacity:0.3;"></i>No tienes mensajes todavía.<br>Pulsa el lápiz arriba para iniciar un chat.</div>';
                return;
            }

            data.forEach(chat => {
                const displayName = chat.contact_name || chat.other_number;
                const initial = displayName.charAt(0).toUpperCase();
                const unread = chat.unread > 0 ? `<div class="msg-unread-badge">${chat.unread}</div>` : '';
                
                list.innerHTML += `
                    <div class="msg-list-item" onclick="AuraMessagesApp.openActiveChat(${chat.id}, '${chat.other_number}', '${displayName}')">
                        <div class="msg-avatar">${initial}</div>
                        <div class="msg-info">
                            <div class="msg-name-row">
                                <span class="msg-name">${displayName}</span>
                                <span class="msg-time">${this.formatTime(chat.last_update)}</span>
                            </div>
                            <div class="msg-preview-row">
                                <span class="msg-preview">${this.getPreviewText(chat)}</span>
                                ${unread}
                            </div>
                        </div>
                    </div>
                `;
            });
        }).catch(err => {
            console.error("Error fetching chats:", err);
        });
    },

    getPreviewText: function(chat) {
        if (chat.last_message_type === 'image') return '<i class="fas fa-camera"></i> Imagen';
        if (chat.last_message_type === 'audio') return '<i class="fas fa-microphone"></i> Audio';
        if (chat.last_message_type === 'location') return '<i class="fas fa-map-marker-alt"></i> Ubicación';
        return chat.last_message || '';
    },

    formatTime: function(timestamp) {
        if (!timestamp) return '';
        const date = new Date(timestamp);
        return date.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
    },

    // Modal de Nuevo Chat
    openNewChatModal: function() {
        const modal = document.getElementById('msg-new-chat-modal');
        if (!modal) return;
        modal.classList.remove('hidden');
        const input = document.getElementById('msg-new-chat-number');
        if (input) {
            input.value = '';
            input.focus();
        }
        this.loadModalContacts();
    },

    closeNewChatModal: function() {
        const modal = document.getElementById('msg-new-chat-modal');
        if (modal) modal.classList.add('hidden');
    },

    loadModalContacts: function() {
        const container = document.getElementById('msg-modal-contacts-list');
        if (!container) return;
        container.innerHTML = '<div style="color:rgba(255,255,255,0.4); text-align:center; padding:10px;">Cargando contactos...</div>';

        fetch(`https://${GetParentResourceName()}/getContacts`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).then(resp => resp.json()).then(contacts => {
            container.innerHTML = '';
            if (!contacts || contacts.length === 0) {
                container.innerHTML = '<div style="color:rgba(255,255,255,0.3); text-align:center; padding:15px; font-size:12px;">No tienes contactos guardados.</div>';
                return;
            }

            contacts.forEach(c => {
                const initial = c.contact_name.charAt(0).toUpperCase();
                container.innerHTML += `
                    <div class="msg-modal-contact-item" onclick="AuraMessagesApp.selectContactForChat('${c.contact_number}', '${c.contact_name}')">
                        <div class="msg-modal-contact-avatar">${initial}</div>
                        <div class="msg-modal-contact-info">
                            <span class="msg-modal-contact-name">${c.contact_name}</span>
                            <span class="msg-modal-contact-num">${c.contact_number}</span>
                        </div>
                    </div>
                `;
            });
        }).catch(err => {
            container.innerHTML = '<div style="color:rgba(255,255,255,0.3); text-align:center;">Error al cargar contactos</div>';
        });
    },

    selectContactForChat: function(number, name) {
        this.closeNewChatModal();
        this.openActiveChat(null, number, name);
    },

    confirmNewChat: function() {
        const input = document.getElementById('msg-new-chat-number');
        if (!input) return;
        const targetNumber = input.value.trim();
        if (targetNumber !== '') {
            this.closeNewChatModal();
            this.openActiveChat(null, targetNumber, targetNumber);
        }
    },

    // Modal de Imagen
    openImageModal: function() {
        this.toggleAttachments();
        const modal = document.getElementById('msg-image-modal');
        if (modal) {
            modal.classList.remove('hidden');
            const input = document.getElementById('msg-image-url-input');
            if (input) {
                input.value = '';
                input.focus();
            }
        }
    },

    closeImageModal: function() {
        const modal = document.getElementById('msg-image-modal');
        if (modal) modal.classList.add('hidden');
    },

    confirmSendImage: function() {
        const input = document.getElementById('msg-image-url-input');
        if (!input) return;
        const url = input.value.trim();
        if (url !== '') {
            this.closeImageModal();
            this.sendMessage('image', url);
        }
    },

    openActiveChat: function(chatId, number, name) {
        this.currentChatId = chatId;
        this.targetNumber = number;
        this.targetName = name;
        
        const nameEl = document.getElementById('msg-active-chat-name');
        if (nameEl) nameEl.innerText = name;
        
        const chatList = document.getElementById('msg-chat-list');
        const activeChat = document.getElementById('msg-active-chat');
        
        if (chatList) {
            chatList.classList.add('hidden');
            chatList.style.display = 'none';
        }
        if (activeChat) {
            activeChat.classList.remove('hidden');
            activeChat.style.display = 'flex';
        }
        
        this.fetchMessages();
    },

    closeActiveChat: function() {
        this.currentChatId = null;
        this.targetNumber = null;
        
        const activeChat = document.getElementById('msg-active-chat');
        const chatList = document.getElementById('msg-chat-list');
        
        if (activeChat) {
            activeChat.classList.add('hidden');
            activeChat.style.display = 'none';
        }
        if (chatList) {
            chatList.classList.remove('hidden');
            chatList.style.display = 'flex';
        }
        this.fetchChatList();
    },

    fetchMessages: function() {
        if (!this.currentChatId && !this.targetNumber) return;
        
        fetch(`https://${GetParentResourceName()}/getMessages`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ chat_id: this.currentChatId, target_number: this.targetNumber })
        }).then(resp => resp.json()).then(data => {
            const container = document.getElementById('msg-bubbles-container');
            if (!container) return;
            container.innerHTML = '';
            
            if (data.chat_id) {
                this.currentChatId = data.chat_id;
            }

            if (data.messages && data.messages.length > 0) {
                data.messages.forEach(msg => {
                    this.appendMessageBubble(msg);
                });
            } else {
                container.innerHTML = `<div style="text-align:center; margin:auto; color:rgba(255,255,255,0.3); font-size:12px;">Inicio de la conversación con<br><strong style="color:var(--primary-cyan);">${this.targetName || this.targetNumber}</strong></div>`;
            }
            this.scrollToBottom();
        }).catch(err => {
            console.error("Error fetching messages:", err);
        });
    },

    appendMessageBubble: function(msg) {
        const container = document.getElementById('msg-bubbles-container');
        if (!container) return;

        // Eliminar mensaje placeholder de bienvenida si existe
        if (container.children.length === 1 && container.children[0].innerText.includes('Inicio de la conversación')) {
            container.innerHTML = '';
        }

        const isMe = msg.is_me;
        const alignClass = isMe ? 'bubble-me' : 'bubble-other';
        let contentHtml = '';

        if (msg.message_type === 'text') {
            contentHtml = msg.content;
        } else if (msg.message_type === 'image') {
            contentHtml = `<img src="${msg.content}" class="msg-image" onclick="window.invokeNative && window.invokeNative('openUrl', '${msg.content}')">`;
        } else if (msg.message_type === 'location') {
            contentHtml = `<div class="msg-location" onclick="AuraMessagesApp.setGPS('${msg.content}')">
                            <i class="fas fa-map-marked-alt"></i> Ver en GPS
                           </div>`;
        } else if (msg.message_type === 'audio') {
            contentHtml = `<audio controls src="${msg.content}"></audio>`;
        }

        container.innerHTML += `
            <div class="msg-bubble-wrapper ${alignClass}">
                <div class="msg-bubble">
                    ${contentHtml}
                    <div class="msg-time-small">${this.formatTime(msg.created_at)}</div>
                </div>
            </div>
        `;
    },

    scrollToBottom: function() {
        const container = document.getElementById('msg-bubbles-container');
        if (container) {
            container.scrollTop = container.scrollHeight;
        }
    },

    sendMessage: function(type = 'text', content = null) {
        let msgContent = content;
        
        if (type === 'text') {
            const input = document.getElementById('msg-input');
            if (!input) return;
            msgContent = input.value.trim();
            if (!msgContent) return;
            input.value = '';
        }

        if (!msgContent) return;

        // Optimistic UI Append
        this.appendMessageBubble({
            is_me: true,
            message_type: type,
            content: msgContent,
            created_at: new Date().toISOString()
        });
        this.scrollToBottom();

        fetch(`https://${GetParentResourceName()}/sendMessage`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ 
                chat_id: this.currentChatId,
                target_number: this.targetNumber,
                message_type: type,
                content: msgContent 
            })
        }).then(resp => resp.json()).then(data => {
            if (data.chat_id && !this.currentChatId) {
                this.currentChatId = data.chat_id;
            }
        }).catch(err => {
            console.error("Error sending message:", err);
        });
    },

    toggleAttachments: function() {
        const menu = document.getElementById('msg-attachments-menu');
        if (menu) menu.classList.toggle('hidden');
    },

    sendLocation: function() {
        this.toggleAttachments();
        fetch(`https://${GetParentResourceName()}/sendLocation`, {
            method: 'POST'
        });
    },

    setGPS: function(coordsStr) {
        fetch(`https://${GetParentResourceName()}/setWaypoint`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ coords: coordsStr })
        });
    },

    handleIncomingEvent: function(action, data) {
        if (action === "newMessage") {
            if (this.currentChatId === data.chat_id || this.targetNumber === data.sender_number) {
                this.appendMessageBubble({
                    is_me: false,
                    message_type: data.message_type,
                    content: data.content,
                    created_at: new Date().toISOString()
                });
                this.scrollToBottom();
                
                // Marcar leido
                fetch(`https://${GetParentResourceName()}/markRead`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ chat_id: data.chat_id })
                });
            } else {
                // Si estamos en la lista de chats, actualizarla
                const chatList = document.getElementById('msg-chat-list');
                if (chatList && chatList.style.display !== 'none') {
                    this.fetchChatList();
                }
            }
        } else if (action === "locationReady") {
            this.sendMessage('location', data.coords);
        }
    }
};

// Escucha del NUI general para pasar eventos a MessagesApp si es necesario
window.addEventListener('message', function(event) {
    if (event.data.app === 'messages') {
        AuraMessagesApp.handleIncomingEvent(event.data.action, event.data);
    }
});

// Registrar app globalmente para que el Core pueda llamar a getHTML y onOpen
window.AuraMessagesApp = AuraMessagesApp;

