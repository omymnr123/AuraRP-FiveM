/**
 * AURARP - AURA_ANIMATIONS JAVASCRIPT FRONTEND
 * Bridges seamlessly with rpemotes Lua backend via FiveM NUI Callbacks.
 * Uses verified ANIMATION_DATABASE loaded from animations_data.js (1500+ animations).
 */

// ============================================================================
// STATE MANAGEMENT
// ============================================================================

let currentCategory = 'dances';
let searchQuery = '';
let favorites = new Set();
let config = {};

// Cargar favoritos desde localStorage
function loadFavorites() {
    try {
        const saved = localStorage.getItem('aura_anim_favorites');
        if (saved) {
            favorites = new Set(JSON.parse(saved));
        }
    } catch (e) {
        console.error("Error loading favorites from localStorage:", e);
        favorites = new Set();
    }
    updateFavoritesBadge();
}

function saveFavorites() {
    try {
        localStorage.setItem('aura_anim_favorites', JSON.stringify(Array.from(favorites)));
    } catch (e) {
        console.error("Error saving favorites to localStorage:", e);
    }
    updateFavoritesBadge();
}

function updateFavoritesBadge() {
    const badge = document.getElementById('fav-count');
    if (badge) {
        badge.textContent = favorites.size;
    }
}

// Obtener todas las animaciones aplanadas para búsqueda global
function getAllAnimations() {
    const all = [];
    Object.keys(ANIMATION_DATABASE).forEach(catKey => {
        ANIMATION_DATABASE[catKey].forEach(item => {
            all.push({ ...item, sourceCategory: catKey });
        });
    });
    return all;
}

function normalizeText(str) {
    if (!str) return '';
    return str.toString()
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .toLowerCase()
        .trim();
}

function renderGrid() {
    const grid = document.getElementById('animations-grid');
    const emptyState = document.getElementById('empty-state');
    const resultsCount = document.getElementById('results-count');
    const emptyTitle = document.getElementById('empty-title');
    const emptyDesc = document.getElementById('empty-desc');
    const emptyIcon = document.getElementById('empty-icon');

    grid.innerHTML = '';

    let itemsToRender = [];

    if (searchQuery.trim() !== '') {
        // Búsqueda global a través de todas las categorías con normalización de tildes
        const q = normalizeText(searchQuery);
        const allItems = getAllAnimations();
        
        itemsToRender = allItems.filter(item => {
            const matchLabel = normalizeText(item.label).includes(q);
            const matchCmd = normalizeText(item.cmd).includes(q);
            const matchTags = item.tags && item.tags.some(tag => normalizeText(tag).includes(q));
            return matchLabel || matchCmd || matchTags;
        });
    } else if (currentCategory === 'favorites') {
        // Renderizar elementos favoritos
        const allItems = getAllAnimations();
        itemsToRender = allItems.filter(item => favorites.has(item.id));
    } else {
        // Renderizar categoría seleccionada
        itemsToRender = ANIMATION_DATABASE[currentCategory] || [];
    }

    resultsCount.textContent = itemsToRender.length;

    if (itemsToRender.length === 0) {
        grid.style.display = 'none';
        emptyState.style.display = 'flex';

        if (currentCategory === 'favorites' && searchQuery.trim() === '') {
            emptyIcon.textContent = '⭐';
            emptyTitle.textContent = 'Sin Favoritos';
            emptyDesc.textContent = 'Aún no tienes animaciones guardadas. Haz clic en la estrella ⭐ de cualquier animación para tenerla aquí a mano.';
        } else {
            emptyIcon.textContent = '🔍';
            emptyTitle.textContent = 'Sin Resultados';
            emptyDesc.textContent = `No encontramos animaciones que coincidan con "${searchQuery}". Prueba con otra palabra clave.`;
        }
        return;
    }

    grid.style.display = 'grid';
    emptyState.style.display = 'none';

    // Inyectar tarjetas
    itemsToRender.forEach(item => {
        const isFav = favorites.has(item.id);
        const card = document.createElement('div');
        card.className = 'anim-card';
        card.dataset.id = item.id;
        card.dataset.cmd = item.cmd;
        card.dataset.type = item.type;

        // Formato visual del comando en la pastilla
        let cmdPrefix = '/e ';
        if (item.type === 'walk') cmdPrefix = '/walk ';
        else if (item.type === 'expression') cmdPrefix = '/mood ';
        else if (item.type === 'shared') cmdPrefix = '/nearby ';

        card.innerHTML = `
            <div class="card-top">
                <div class="card-title-group">
                    <span class="card-label">${escapeHtml(item.label)}</span>
                    <span class="card-type-tag">${getTypeLabel(item.type)}</span>
                </div>
                <button class="card-fav-btn ${isFav ? 'favorited' : ''}" title="${isFav ? 'Quitar de favoritos' : 'Añadir a favoritos'}">
                    ${isFav ? '★' : '☆'}
                </button>
            </div>
            <div class="card-bottom">
                <span class="card-cmd-badge">${cmdPrefix}${escapeHtml(item.cmd)}</span>
                <div class="card-play-icon">
                    <svg viewBox="0 0 24 24" fill="currentColor">
                        <polygon points="5 3 19 12 5 21 5 3"></polygon>
                    </svg>
                </div>
            </div>
        `;

        // Evento de clic para ejecutar animación
        card.addEventListener('click', (e) => {
            if (e.target.closest('.card-fav-btn')) return; // No ejecutar si se pulsó la estrella
            playAnimation(item);
        });

        // Evento de clic en estrella de favoritos
        const favBtn = card.querySelector('.card-fav-btn');
        favBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            toggleFavorite(item.id);
        });

        grid.appendChild(card);
    });
}

function getTypeLabel(type) {
    switch (type) {
        case 'dance': return 'Baile';
        case 'emote': return 'Postura';
        case 'prop': return 'Objeto';
        case 'walk': return 'Caminar';
        case 'expression': return 'Expresión';
        case 'shared': return 'Sincronizada';
        default: return 'Animación';
    }
}

function escapeHtml(string) {
    return String(string).replace(/[&<>"'`=\/]/g, function (s) {
        return {
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            '"': '&quot;',
            "'": '&#39;',
            '/': '&#x2F;',
            '=': '&#x3D;',
            '`': '&#x60;'
        }[s];
    });
}

// ============================================================================
// NUI BRIDGE API CALLS
// ============================================================================

function postNUI(endpoint, data = {}) {
    const resName = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'aura_animations';
    return fetch(`https://${resName}/${endpoint}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8'
        },
        body: JSON.stringify(data)
    }).catch(err => {
        console.warn(`[AuraAnimations] NUI Callback error on /${endpoint}:`, err);
    });
}

function playAnimation(item) {
    postNUI('playAnim', {
        type: item.type,
        name: item.cmd
    });

    showToast(`Ejecutando: ${item.label}`, 'success', '▶');
}

function cancelCurrentAnimation() {
    postNUI('cancelAnim', {});
    showToast('Animación cancelada', 'danger', '🛑');
}

function resetWalkingStyle() {
    postNUI('resetWalk', {});
    showToast('Estilo de andar restablecido', 'success', '🚶');
}

function resetFacialExpression() {
    postNUI('resetExpression', {});
    showToast('Expresión facial restablecida', 'success', '😐');
}

function closeUI() {
    const app = document.getElementById('app');
    app.style.display = 'none';
    postNUI('close', {});
}

function toggleFavorite(id) {
    if (favorites.has(id)) {
        favorites.delete(id);
        showToast('Eliminado de favoritos', 'danger', '☆');
    } else {
        favorites.add(id);
        showToast('Añadido a tus favoritos', 'success', '⭐');
    }
    saveFavorites();
    renderGrid();
}

// ============================================================================
// TOAST NOTIFICATION SYSTEM
// ============================================================================

let toastTimeout = null;

function showToast(msg, type = 'success', icon = '⚡') {
    const container = document.getElementById('toast-container');
    if (!container) return;

    // Limpiar toast previo
    container.innerHTML = '';
    if (toastTimeout) clearTimeout(toastTimeout);

    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.innerHTML = `
        <span class="toast-icon">${icon}</span>
        <span class="toast-msg">${escapeHtml(msg)}</span>
    `;

    container.appendChild(toast);

    toastTimeout = setTimeout(() => {
        toast.style.animation = 'toastPop 0.25s reverse forwards';
        setTimeout(() => {
            if (toast.parentNode) toast.parentNode.removeChild(toast);
        }, 250);
    }, 2200);
}

// ============================================================================
// EVENT LISTENERS & INITIALIZATION
// ============================================================================

document.addEventListener('DOMContentLoaded', () => {
    loadFavorites();

    // Tabs de categoría y soporte de Scroll / Dragging interactivo
    const categoryTabs = document.getElementById('category-tabs');
    const tabArrowLeft = document.getElementById('tab-arrow-left');
    const tabArrowRight = document.getElementById('tab-arrow-right');
    const tabButtons = document.querySelectorAll('.tab-btn');

    let isDraggingTabs = false;
    let tabStartX = 0;
    let tabScrollLeft = 0;
    let hasDraggedDistance = 0;

    // 1. Scroll con rueda del ratón horizontal
    if (categoryTabs) {
        categoryTabs.addEventListener('wheel', (e) => {
            e.preventDefault();
            categoryTabs.scrollLeft += e.deltaY * 0.9;
        }, { passive: false });

        // 2. Arrastre con clic (Click & Drag / Pan)
        categoryTabs.addEventListener('mousedown', (e) => {
            isDraggingTabs = true;
            hasDraggedDistance = 0;
            categoryTabs.classList.add('dragging');
            tabStartX = e.pageX - categoryTabs.offsetLeft;
            tabScrollLeft = categoryTabs.scrollLeft;
        });

        window.addEventListener('mouseup', () => {
            if (isDraggingTabs) {
                isDraggingTabs = false;
                categoryTabs.classList.remove('dragging');
            }
        });

        categoryTabs.addEventListener('mousemove', (e) => {
            if (!isDraggingTabs) return;
            e.preventDefault();
            const x = e.pageX - categoryTabs.offsetLeft;
            const walk = (x - tabStartX) * 1.4;
            hasDraggedDistance += Math.abs(walk);
            categoryTabs.scrollLeft = tabScrollLeft - walk;
        });
    }

    // 3. Flechas de navegación izquierda y derecha
    if (tabArrowLeft) {
        tabArrowLeft.addEventListener('click', () => {
            if (categoryTabs) {
                categoryTabs.scrollBy({ left: -140, behavior: 'smooth' });
            }
        });
    }

    if (tabArrowRight) {
        tabArrowRight.addEventListener('click', () => {
            if (categoryTabs) {
                categoryTabs.scrollBy({ left: 140, behavior: 'smooth' });
            }
        });
    }

    // 4. Selección de tab (evitar disparo accidental si se estaba arrastrando)
    tabButtons.forEach(btn => {
        btn.addEventListener('click', (e) => {
            if (hasDraggedDistance > 6) {
                e.preventDefault();
                e.stopPropagation();
                hasDraggedDistance = 0;
                return;
            }

            tabButtons.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');

            currentCategory = btn.dataset.category;
            
            // Si había búsqueda, limpiarla al cambiar de tab para UX fluida
            const searchInput = document.getElementById('search-input');
            const searchClear = document.getElementById('search-clear');
            if (searchInput.value !== '') {
                searchInput.value = '';
                searchQuery = '';
                searchClear.style.display = 'none';
            }

            // Auto centrar el botón activo en la vista si es necesario
            btn.scrollIntoView({ behavior: 'smooth', inline: 'nearest', block: 'nearest' });

            renderGrid();
        });
    });

    // Búsqueda en vivo
    const searchInput = document.getElementById('search-input');
    const searchClear = document.getElementById('search-clear');

    searchInput.addEventListener('input', (e) => {
        searchQuery = e.target.value;
        searchClear.style.display = searchQuery.length > 0 ? 'flex' : 'none';
        renderGrid();
    });

    searchClear.addEventListener('click', () => {
        searchInput.value = '';
        searchQuery = '';
        searchClear.style.display = 'none';
        searchInput.focus();
        renderGrid();
    });

    // Botones de acción rápida
    document.getElementById('btn-cancel-anim').addEventListener('click', cancelCurrentAnimation);
    document.getElementById('btn-reset-walk').addEventListener('click', resetWalkingStyle);
    document.getElementById('btn-reset-mood').addEventListener('click', resetFacialExpression);
    document.getElementById('btn-close-ui').addEventListener('click', closeUI);

    // Tecla ESC para cerrar y tecla X para cancelar
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            closeUI();
        }
    });

    // Mensajes NUI desde FiveM
    window.addEventListener('message', (event) => {
        const data = event.data;
        if (!data) return;

        if (data.action === 'open') {
            config = data.config || {};
            const app = document.getElementById('app');
            app.style.display = 'flex';
            
            // Resetear búsqueda
            searchInput.value = '';
            searchQuery = '';
            searchClear.style.display = 'none';
            
            renderGrid();
        } else if (data.action === 'close') {
            const app = document.getElementById('app');
            app.style.display = 'none';
        }
    });
});
