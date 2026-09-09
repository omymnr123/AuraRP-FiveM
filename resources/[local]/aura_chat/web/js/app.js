/* ==========================================================================
   AuraRP Chat - Application Logic (Phase 10)
   Gestión de eventos NUI, historial de comandos, autocompletado y auto-hide.
   ========================================================================== */

(() => {
    'use strict';

    // Elementos del DOM
    const chatWindow = document.getElementById('chat-window');
    const messagesContainer = document.getElementById('messages-container');
    const messagesList = document.getElementById('messages-list');
    const inputWrapper = document.getElementById('input-wrapper');
    const chatInput = document.getElementById('chat-input');
    const suggestionsBox = document.getElementById('suggestions-box');
    const suggestionsList = document.getElementById('suggestions-list');

    // Estado local
    let isInputOpen = false;
    let hideTimeout = 7000;
    let hideTimer = null;
    let maxMessages = 80;
    let chatVisibilityMode = 'activity'; // 'activity' | 'always' | 'hidden'

    const commandHistory = [];
    let historyIndex = -1;
    let currentInputDraft = '';

    const registeredSuggestions = new Map();

    // ==========================================================================
    // SANITIZACIÓN Y HELPERS
    // ==========================================================================
    function escapeHtml(text) {
        if (!text) return '';
        const map = {
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            '"': '&quot;',
            "'": '&#039;'
        };
        return text.toString().replace(/[&<>"']/g, (m) => map[m]);
    }

    // ==========================================================================
    // MODOS DE VISIBILIDAD (SIEMPRE / ACTIVIDAD / OCULTO)
    // ==========================================================================
    function applyVisibilityMode() {
        if (chatVisibilityMode === 'always') {
            if (hideTimer) {
                clearTimeout(hideTimer);
                hideTimer = null;
            }
            chatWindow.classList.remove('chat-hidden');
        } else if (chatVisibilityMode === 'hidden') {
            if (hideTimer) {
                clearTimeout(hideTimer);
                hideTimer = null;
            }
            if (!isInputOpen) {
                chatWindow.classList.add('chat-hidden');
            }
        } else {
            resetHideTimer();
        }
    }

    // ==========================================================================
    // TEMPORIZADOR DE AUTO-OCULTACIÓN (AUTO-HIDE)
    // ==========================================================================
    function resetHideTimer() {
        if (hideTimer) {
            clearTimeout(hideTimer);
            hideTimer = null;
        }

        if (chatVisibilityMode === 'always') {
            chatWindow.classList.remove('chat-hidden');
            return;
        }

        if (chatVisibilityMode === 'hidden') {
            if (!isInputOpen) {
                chatWindow.classList.add('chat-hidden');
            } else {
                chatWindow.classList.remove('chat-hidden');
            }
            return;
        }

        // Modo 'activity' estándar
        chatWindow.classList.remove('chat-hidden');

        if (!isInputOpen) {
            hideTimer = setTimeout(() => {
                chatWindow.classList.add('chat-hidden');
            }, hideTimeout);
        }
    }

    // ==========================================================================
    // RENDERIZADO DE MENSAJES
    // ==========================================================================
    function appendMessage(data) {
        if (!data) return;

        const item = document.createElement('div');
        const typeClass = data.type ? `type-${data.type}` : 'type-ooc';
        item.className = `message-item ${typeClass}`;

        if (data.customClass) {
            item.classList.add(data.customClass);
        }

        let innerHTML = '';

        // 1. Badge / Insignia Principal (ME, DO, OOC, etc.)
        if (data.badge) {
            const badgeBg = data.badgeColor ? `style="border-color: ${data.badgeColor}; color: ${data.badgeColor};"` : '';
            innerHTML += `<span class="msg-badge" ${badgeBg}>${escapeHtml(data.badge)}</span>`;
        }

        // 2. Etiqueta de ID (Al lado de la etiqueta principal)
        if (data.playerId !== undefined && data.playerId !== null && data.playerId !== '') {
            innerHTML += `<span class="msg-badge msg-badge-id">ID: ${escapeHtml(data.playerId)}</span>`;
        }

        // Hora del mensaje
        if (data.time) {
            innerHTML += `<span class="msg-time">${escapeHtml(data.time)}</span>`;
        }

        // Autor (si aplica)
        if (data.author && data.type !== 'me' && data.type !== 'do') {
            const authorColor = data.authorColor ? `style="color: ${data.authorColor};"` : '';
            innerHTML += `<span class="msg-author" ${authorColor}>${escapeHtml(data.author)}:</span>`;
        }

        // Contenido del mensaje
        const contentColor = data.contentColor ? `style="color: ${data.contentColor};"` : '';
        innerHTML += `<span class="msg-content" ${contentColor}>${escapeHtml(data.content)}</span>`;

        item.innerHTML = innerHTML;
        messagesList.appendChild(item);

        // Limitar la cantidad máxima de mensajes en el DOM
        while (messagesList.children.length > maxMessages) {
            messagesList.removeChild(messagesList.firstChild);
        }

        // Scroll automático suave hacia el último mensaje
        messagesContainer.scrollTop = messagesContainer.scrollHeight;

        // Despertar la ventana de chat y renovar el temporizador de visibilidad
        resetHideTimer();
    }

    // ==========================================================================
    // SISTEMA DE SUGERENCIAS / AUTOCOMPLETADO
    // ==========================================================================
    function updateSuggestionsUI(inputText) {
        if (!inputText.startsWith('/')) {
            suggestionsBox.style.display = 'none';
            return;
        }

        const query = inputText.toLowerCase();
        const matches = [];

        registeredSuggestions.forEach((sugg) => {
            if (sugg.name.toLowerCase().startsWith(query) || query === '/') {
                matches.push(sugg);
            }
        });

        if (matches.length === 0) {
            suggestionsBox.style.display = 'none';
            return;
        }

        suggestionsList.innerHTML = '';
        matches.slice(0, 5).forEach((sugg) => {
            const item = document.createElement('div');
            item.className = 'suggestion-item';

            let paramsHtml = '';
            if (sugg.params && Array.isArray(sugg.params)) {
                sugg.params.forEach((p) => {
                    paramsHtml += `<span class="sugg-param">&lt;${escapeHtml(p.name)}&gt;</span>`;
                });
            }

            item.innerHTML = `
                <span class="sugg-name">${escapeHtml(sugg.name)}</span>
                <span class="sugg-help">${escapeHtml(sugg.help || '')}</span>
                ${paramsHtml}
            `;

            item.addEventListener('click', () => {
                chatInput.value = sugg.name + ' ';
                chatInput.focus();
                updateSuggestionsUI(chatInput.value);
            });

            suggestionsList.appendChild(item);
        });

        suggestionsBox.style.display = 'block';
    }

    // ==========================================================================
    // CONTROLADORES DE ENTRADA (INPUT)
    // ==========================================================================
    function openChatUI(prefix = '') {
        isInputOpen = true;
        chatWindow.classList.remove('chat-hidden');
        inputWrapper.style.display = 'flex';
        
        chatInput.value = prefix;
        
        setTimeout(() => {
            chatInput.focus();
            if (prefix) {
                chatInput.setSelectionRange(prefix.length, prefix.length);
            }
        }, 25);

        historyIndex = -1;
        currentInputDraft = '';

        if (hideTimer) {
            clearTimeout(hideTimer);
            hideTimer = null;
        }

        updateSuggestionsUI(chatInput.value);
    }

    function closeChatUI(sendCallback = true) {
        isInputOpen = false;
        inputWrapper.style.display = 'none';
        suggestionsBox.style.display = 'none';
        chatInput.value = '';

        if (sendCallback) {
            fetch(`https://${GetParentResourceName()}/closeChat`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify({})
            }).catch(() => {});
        }

        resetHideTimer();
    }

    function submitMessage() {
        const message = chatInput.value.trim();

        if (message.length > 0) {
            // Guardar en el historial de comandos
            commandHistory.unshift(message);
            if (commandHistory.length > 40) {
                commandHistory.pop();
            }

            fetch(`https://${GetParentResourceName()}/sendMessage`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify({ message: message })
            }).catch(() => {});
        } else {
            fetch(`https://${GetParentResourceName()}/closeChat`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify({})
            }).catch(() => {});
        }

        closeChatUI(false);
    }

    // Eventos de teclado en el input
    chatInput.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') {
            e.preventDefault();
            submitMessage();
        } else if (e.key === 'Escape') {
            e.preventDefault();
            closeChatUI(true);
        } else if (e.key === 'ArrowUp') {
            e.preventDefault();
            if (commandHistory.length === 0) return;

            if (historyIndex === -1) {
                currentInputDraft = chatInput.value;
            }

            if (historyIndex < commandHistory.length - 1) {
                historyIndex++;
                chatInput.value = commandHistory[historyIndex];
                updateSuggestionsUI(chatInput.value);
            }
        } else if (e.key === 'ArrowDown') {
            e.preventDefault();
            if (historyIndex > 0) {
                historyIndex--;
                chatInput.value = commandHistory[historyIndex];
                updateSuggestionsUI(chatInput.value);
            } else if (historyIndex === 0) {
                historyIndex = -1;
                chatInput.value = currentInputDraft;
                updateSuggestionsUI(chatInput.value);
            }
        } else if (e.key === 'Tab') {
            e.preventDefault();
            // Autocompletar con la primera sugerencia visible
            const firstSuggestion = suggestionsList.querySelector('.sugg-name');
            if (firstSuggestion) {
                chatInput.value = firstSuggestion.textContent.trim() + ' ';
                updateSuggestionsUI(chatInput.value);
            }
        }
    });

    chatInput.addEventListener('input', () => {
        updateSuggestionsUI(chatInput.value);
    });

    // ==========================================================================
    // ESCUCHA DE MENSAJES NUI DESDE EL CLIENTE LUA
    // ==========================================================================
    window.addEventListener('message', (event) => {
        const item = event.data;
        if (!item || !item.action) return;

        switch (item.action) {
            case 'openChat':
                openChatUI(item.prefix || '');
                break;

            case 'addMessage':
                appendMessage(item.message);
                break;

            case 'addSuggestion':
                if (item.suggestion && item.suggestion.name) {
                    registeredSuggestions.set(item.suggestion.name, item.suggestion);
                }
                break;

            case 'addSuggestions':
                if (item.suggestions && Array.isArray(item.suggestions)) {
                    item.suggestions.forEach((sugg) => {
                        if (sugg && sugg.name) {
                            registeredSuggestions.set(sugg.name, sugg);
                        }
                    });
                }
                break;

            case 'removeSuggestion':
                if (item.name) {
                    registeredSuggestions.delete(item.name);
                }
                break;

            case 'clearChat':
                messagesList.innerHTML = '';
                break;

            case 'setChatMode':
                chatVisibilityMode = item.mode || 'activity';
                applyVisibilityMode();
                break;

            default:
                break;
        }
    });

    // Iniciar temporizador inicial de reposo
    resetHideTimer();
})();
