/**
 * AURARP - AURA_ANIMATIONS JAVASCRIPT FRONTEND
 * Bridges seamlessly with rpemotes Lua backend via FiveM NUI Callbacks.
 */

// ============================================================================
// ANIMATION DATABASE (MAPPED TO RPEMOTES INTERNAL COMMANDS)
// ============================================================================

const ANIMATION_DATABASE = {
    // 💃 BAILES (Dances)
    dances: [
        { id: 'dance', label: 'Baile DJ Club', cmd: 'dance', type: 'dance', tags: ['fiesta', 'club', 'electrónica'] },
        { id: 'dance2', label: 'Baile Discoteca 2', cmd: 'dance2', type: 'dance', tags: ['club', 'noche', 'ritmo'] },
        { id: 'dance3', label: 'Baile Discoteca 3', cmd: 'dance3', type: 'dance', tags: ['club', 'noche', 'party'] },
        { id: 'dance4', label: 'Baile Energético', cmd: 'dance4', type: 'dance', tags: ['ritmo', 'party', 'movimiento'] },
        { id: 'dance5', label: 'Baile Casino Pop', cmd: 'dance5', type: 'dance', tags: ['casino', 'pop', 'elegante'] },
        { id: 'dance6', label: 'Baile Freestyle', cmd: 'dance6', type: 'dance', tags: ['calle', 'flow', 'urbano'] },
        { id: 'dance7', label: 'Baile Clubbing', cmd: 'dance7', type: 'dance', tags: ['discoteca', 'fiesta'] },
        { id: 'dance8', label: 'Baile Urbano', cmd: 'dance8', type: 'dance', tags: ['hiphop', 'calle'] },
        { id: 'dance9', label: 'Baile Electrónico', cmd: 'dance9', type: 'dance', tags: ['techno', 'rave'] },
        { id: 'danceglow', label: 'Baile con Luces Glow', cmd: 'danceglow', type: 'dance', tags: ['rave', 'luces', 'neon'] },
        { id: 'salsa', label: 'Salsa Latina', cmd: 'salsa', type: 'dance', tags: ['latino', 'ritmo', 'salsa'] },
        { id: 'bachata', label: 'Bachata Sensual', cmd: 'bachata', type: 'dance', tags: ['latino', 'sensual', 'bachata'] },
        { id: 'reggaeton', label: 'Reggaeton Flow', cmd: 'reggaeton', type: 'dance', tags: ['latino', 'perreo', 'flow'] },
        { id: 'breakdance', label: 'Breakdance B-Boy', cmd: 'breakdance', type: 'dance', tags: ['acrobacia', 'suelo', 'bboy'] },
        { id: 'shuffle', label: 'Shuffle Dance', cmd: 'shuffle', type: 'dance', tags: ['pasos', 'rapido', 'rave'] },
        { id: 'hiphop', label: 'Hip Hop Groove', cmd: 'hiphop', type: 'dance', tags: ['urbano', 'ritmo'] },
        { id: 'robot', label: 'Baile Robot', cmd: 'dancef', type: 'dance', tags: ['robotico', 'mecanico'] },
        { id: 'carlton', label: 'Baile Carlton', cmd: 'carlton', type: 'dance', tags: ['clasico', 'gracioso'] },
        { id: 'floss', label: 'Baile Floss', cmd: 'floss', type: 'dance', tags: ['brazos', 'meme'] },
        { id: 'twerk', label: 'Twerk', cmd: 'twerk', type: 'dance', tags: ['sensual', 'ritmo'] },
        { id: 'lapdance', label: 'Baile Sensual VIP', cmd: 'lapdance', type: 'dance', tags: ['vip', 'privado', 'sensual'] },
        { id: 'cheer', label: 'Animadora / Cheer', cmd: 'cheer', type: 'dance', tags: ['aplausos', 'animar'] },
        { id: 'slowdance', label: 'Baile Lento', cmd: 'danceglow2', type: 'dance', tags: ['romantico', 'tranquilo'] },
        { id: 'chicken', label: 'Baile del Pollo', cmd: 'dancem', type: 'dance', tags: ['broma', 'gracioso'] }
    ],

    // 🧍 POSTURAS Y ACCIONES (Poses & General Emotes)
    poses: [
        { id: 'crossarms', label: 'Brazos Cruzados', cmd: 'crossarms', type: 'emote', tags: ['espera', 'serio', 'pose'] },
        { id: 'crossarms2', label: 'Brazos Cruzados Relajado', cmd: 'crossarms2', type: 'emote', tags: ['tranquilo', 'pose'] },
        { id: 'leanwall', label: 'Apoyarse en Pared Espalda', cmd: 'leanwall', type: 'emote', tags: ['apoyo', 'calle', 'espera'] },
        { id: 'leanbar', label: 'Apoyarse en Mostrador / Barra', cmd: 'leanbar', type: 'emote', tags: ['bar', 'tienda', 'charla'] },
        { id: 'leanside', label: 'Apoyarse de Lado', cmd: 'leanside', type: 'emote', tags: ['apoyo', 'pared', 'relajado'] },
        { id: 'sit', label: 'Sentarse en Suelo', cmd: 'sit', type: 'emote', tags: ['suelo', 'descanso', 'chill'] },
        { id: 'sitchair', label: 'Sentarse Cómodo', cmd: 'sitchair', type: 'emote', tags: ['silla', 'espera'] },
        { id: 'kneel', label: 'Arrodillarse', cmd: 'kneel', type: 'emote', tags: ['respeto', 'suelo'] },
        { id: 'surrender', label: 'Rendirse / Manos en Nuca', cmd: 'surrender', type: 'emote', tags: ['policia', 'arresto', 'manos'] },
        { id: 'handsup', label: 'Levantar Manos', cmd: 'handsup', type: 'emote', tags: ['atraco', 'policia'] },
        { id: 'guard', label: 'Guardia de Seguridad', cmd: 'guard', type: 'emote', tags: ['seguridad', 'policia', 'atento'] },
        { id: 'cop', label: 'Postura de Policía', cmd: 'cop2', type: 'emote', tags: ['policia', 'servicio', 'orden'] },
        { id: 'salute', label: 'Saludo Militar', cmd: 'salute', type: 'emote', tags: ['respeto', 'militar', 'saludo'] },
        { id: 'wave', label: 'Saludar con la Mano', cmd: 'wave', type: 'emote', tags: ['hola', 'amigo', 'saludo'] },
        { id: 'think', label: 'Pensativo / Duda', cmd: 'think', type: 'emote', tags: ['pensar', 'idea', 'duda'] },
        { id: 'meditate', label: 'Meditar Zen', cmd: 'meditate', type: 'emote', tags: ['yoga', 'paz', 'zen'] },
        { id: 'pushup', label: 'Hacer Flexiones', cmd: 'pushup', type: 'emote', tags: ['ejercicio', 'gym', 'fuerza'] },
        { id: 'situp', label: 'Hacer Abdominales', cmd: 'situp', type: 'emote', tags: ['ejercicio', 'gym', 'fitness'] },
        { id: 'mechanic', label: 'Inspeccionar Motor / Mecánico', cmd: 'mechanic', type: 'emote', tags: ['taller', 'coche', 'reparar'] },
        { id: 'laydown', label: 'Tumbarse en el Suelo', cmd: 'laydown', type: 'emote', tags: ['descanso', 'herido', 'suelo'] },
        { id: 'pocket', label: 'Manos en Bolsillos', cmd: 'pocket', type: 'emote', tags: ['relajado', 'pose', 'calle'] },
        { id: 'threaten', label: 'Amenazar / Desafiar', cmd: 'threaten', type: 'emote', tags: ['pelea', 'banda', 'enfado'] },
        { id: 'warmhands', label: 'Calentarse las Manos', cmd: 'warmhands', type: 'emote', tags: ['frio', 'invierno'] },
        { id: 'facepalm', label: 'Vergüenza Ajena / Facepalm', cmd: 'facepalm', type: 'emote', tags: ['fallo', 'error', 'decepcion'] }
    ],

    // 📦 OBJETOS Y PROPS (Props & Utility Emotes)
    props: [
        { id: 'coffee', label: 'Tomar Café', cmd: 'coffee', type: 'prop', tags: ['cafe', 'desayuno', 'vaso'] },
        { id: 'phonecall', label: 'Llamar por Teléfono', cmd: 'phonecall', type: 'prop', tags: ['movil', 'llamada', 'celular'] },
        { id: 'phone', label: 'Mirar el Móvil', cmd: 'phone', type: 'prop', tags: ['whatsapp', 'redes', 'movil'] },
        { id: 'smoke', label: 'Fumar Cigarro', cmd: 'smoke', type: 'prop', tags: ['tabaco', 'cigarro', 'fumar'] },
        { id: 'cigar', label: 'Fumar Puro Habano', cmd: 'cigar', type: 'prop', tags: ['puro', 'mafia', 'elegante'] },
        { id: 'vape', label: 'Vapear', cmd: 'vape', type: 'prop', tags: ['vaper', 'humo', 'electronico'] },
        { id: 'camera', label: 'Cámara Fotográfica', cmd: 'camera', type: 'prop', tags: ['foto', 'periodista', 'flash'] },
        { id: 'tablet', label: 'Usar Tablet Digital', cmd: 'tablet2', type: 'prop', tags: ['ipad', 'policia', 'tecnologia'] },
        { id: 'briefcase', label: 'Sostener Maletín', cmd: 'briefcase', type: 'prop', tags: ['negocios', 'abogado', 'dinero'] },
        { id: 'box', label: 'Cargar Caja Pesada', cmd: 'box', type: 'prop', tags: ['reparto', 'trabajo', 'carga'] },
        { id: 'umbrella', label: 'Llevar Paraguas', cmd: 'umbrella', type: 'prop', tags: ['lluvia', 'clima', 'paraguas'] },
        { id: 'notepad', label: 'Anotar en Libreta', cmd: 'notepad', type: 'prop', tags: ['policia', 'apuntes', 'escribir'] },
        { id: 'beer', label: 'Beber Botellín de Cerveza', cmd: 'beer', type: 'prop', tags: ['alcohol', 'fiesta', 'bar'] },
        { id: 'wine', label: 'Copa de Vino Tinto', cmd: 'wine', type: 'prop', tags: ['vino', 'cena', 'lujo'] },
        { id: 'whiskey', label: 'Vaso de Whisky On The Rocks', cmd: 'whiskey', type: 'prop', tags: ['copa', 'bar', 'licor'] },
        { id: 'donut', label: 'Comer Donut Glaseado', cmd: 'donut', type: 'prop', tags: ['comida', 'policia', 'dulce'] },
        { id: 'burger', label: 'Comer Hamburguesa', cmd: 'burger', type: 'prop', tags: ['comida', 'hambre', 'fastfood'] },
        { id: 'flashlight', label: 'Inspeccionar con Linterna', cmd: 'flashlight', type: 'prop', tags: ['luz', 'noche', 'policia'] },
        { id: 'guitar', label: 'Tocar Guitarra Acústica', cmd: 'guitar', type: 'prop', tags: ['musica', 'cancion', 'arte'] },
        { id: 'bong', label: 'Fumar Bong', cmd: 'bong', type: 'prop', tags: ['hierba', 'relax', 'humo'] },
        { id: 'champagne', label: 'Botella de Champán Lujosa', cmd: 'champagne', type: 'prop', tags: ['fiesta', 'vip', 'celebracion'] },
        { id: 'radio', label: 'Llevar Radio Cassette al Hombro', cmd: 'boombox', type: 'prop', tags: ['musica', 'calle', 'retro'] }
    ],

    // 🚶 ESTILOS DE CAMINAR (Walk Styles)
    walks: [
        { id: 'casual', label: 'Casual / Relajado', cmd: 'Casual', type: 'walk', tags: ['normal', 'tranquilo'] },
        { id: 'arrogant', label: 'Arrogante / Soberbio', cmd: 'Arrogant', type: 'walk', tags: ['creido', 'presumido'] },
        { id: 'brave', label: 'Valiente / Seguro', cmd: 'Brave', type: 'walk', tags: ['fuerte', 'firme'] },
        { id: 'confident', label: 'Confiado / Líder', cmd: 'Confident', type: 'walk', tags: ['seguridad', 'lider'] },
        { id: 'cop', label: 'Policía en Patrulla', cmd: 'Cop', type: 'walk', tags: ['oficial', 'seguridad', 'recto'] },
        { id: 'gangster', label: 'Gangster / Calle', cmd: 'Gangster', type: 'walk', tags: ['barrio', 'calle', 'chulo'] },
        { id: 'posh', label: 'Elegante / Posh', cmd: 'Posh', type: 'walk', tags: ['lujo', 'rico', 'fino'] },
        { id: 'femme', label: 'Femenino / Modelo', cmd: 'Femme', type: 'walk', tags: ['modelo', 'desfile', 'femenino'] },
        { id: 'hurry', label: 'Apresurado / Prisa', cmd: 'Hurry', type: 'walk', tags: ['rapido', 'correr', 'urgente'] },
        { id: 'injured', label: 'Herido / Cojeando', cmd: 'Injured', type: 'walk', tags: ['herida', 'dolor', 'hospital'] },
        { id: 'drunk', label: 'Borracho / Ebrio', cmd: 'Drunk', type: 'walk', tags: ['alcohol', 'fiesta', 'mareado'] },
        { id: 'tough', label: 'Tipo Duro / Musculoso', cmd: 'Tough', type: 'walk', tags: ['gym', 'pesado', 'fuerte'] },
        { id: 'alien', label: 'Paso Extraño / Alien', cmd: 'Alien', type: 'walk', tags: ['raro', 'divertido'] },
        { id: 'coward', label: 'Asustado / Miedoso', cmd: 'Coward', type: 'walk', tags: ['miedo', 'temblor'] }
    ],

    // 😊 EXPRESIONES FACIALES (Moods)
    expressions: [
        { id: 'happy', label: 'Feliz / Sonriente', cmd: 'Happy', type: 'expression', tags: ['alegre', 'sonrisa', 'positivo'] },
        { id: 'angry', label: 'Enfadado / Furioso', cmd: 'Angry', type: 'expression', tags: ['rabia', 'molesto', 'serio'] },
        { id: 'aiming', label: 'Mirada Concentrada / Táctica', cmd: 'Aiming', type: 'expression', tags: ['policia', 'seriedad', 'foco'] },
        { id: 'crying', label: 'Llorando / Triste', cmd: 'Crying', type: 'expression', tags: ['llanto', 'tristeza', 'pena'] },
        { id: 'drunk', label: 'Cara de Borracho', cmd: 'Drunk', type: 'expression', tags: ['ebrio', 'perdido'] },
        { id: 'excited', label: 'Emocionado / Eufórico', cmd: 'Excited', type: 'expression', tags: ['fiesta', 'emocion'] },
        { id: 'grumpy', label: 'Gruñón / Mal Humor', cmd: 'Grumpy', type: 'expression', tags: ['serio', 'queja'] },
        { id: 'injured', label: 'Dolor / Expresión de Herido', cmd: 'Injured', type: 'expression', tags: ['dolor', 'herida'] },
        { id: 'shocked', label: 'Sorprendido / En Shock', cmd: 'Shocked', type: 'expression', tags: ['impacto', 'sorpresa'] },
        { id: 'sleeping', label: 'Ojos Cerrados / Dormido', cmd: 'Sleeping', type: 'expression', tags: ['sueño', 'descanso'] },
        { id: 'smug', label: 'Sonrisa Burlona / Chula', cmd: 'Smug', type: 'expression', tags: ['ironico', 'chulo'] },
        { id: 'stressed', label: 'Estresado / Agobiado', cmd: 'Stressed', type: 'expression', tags: ['estres', 'nervioso'] }
    ],

    // 🤝 ANIMACIONES SINCRONIZADAS / COMPARTIDAS (Shared Emotes)
    shared: [
        { id: 'hug', label: 'Abrazo Fraternal', cmd: 'hug', type: 'shared', tags: ['amistad', 'abrazo', 'pareja'] },
        { id: 'hug2', label: 'Abrazo Emotivo', cmd: 'hug2', type: 'shared', tags: ['amigo', 'cercano'] },
        { id: 'handshake', label: 'Apretón de Manos', cmd: 'handshake', type: 'shared', tags: ['saludo', 'negocios', 'pacto'] },
        { id: 'fistbump', label: 'Chocar Puños', cmd: 'fistbump', type: 'shared', tags: ['amigos', 'respeto', 'flow'] },
        { id: 'highfive', label: 'Chocar los Cinco', cmd: 'highfive', type: 'shared', tags: ['victoria', 'chocar'] },
        { id: 'carry', label: 'Cargar al Hombro (Carry)', cmd: 'carry', type: 'shared', tags: ['socorro', 'herido', 'llevar'] },
        { id: 'piggyback', label: 'Cargar a Caballito', cmd: 'piggyback', type: 'shared', tags: ['divertido', 'amigos'] },
        { id: 'hostage', label: 'Tomar de Rehén', cmd: 'hostage', type: 'shared', tags: ['atraco', 'policia', 'rehen'] },
        { id: 'cpr', label: 'Reanimación Cardiopulmonar (RCP)', cmd: 'cpr', type: 'shared', tags: ['ems', 'medico', 'socorro'] },
        { id: 'slap', label: 'Bofetada / Cachetada', cmd: 'slap', type: 'shared', tags: ['pelea', 'golpe'] },
        { id: 'kiss', label: 'Beso Romántico', cmd: 'kiss', type: 'shared', tags: ['amor', 'pareja', 'beso'] },
        { id: 'cuff', label: 'Esposar a Sospechoso', cmd: 'cuff', type: 'shared', tags: ['policia', 'arresto', 'grilletes'] }
    ]
};

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

// ============================================================================
// UI RENDERING ENGINE
// ============================================================================

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
        // Búsqueda global a través de todas las categorías
        const q = searchQuery.toLowerCase().trim();
        const allItems = getAllAnimations();
        
        itemsToRender = allItems.filter(item => {
            const matchLabel = item.label.toLowerCase().includes(q);
            const matchCmd = item.cmd.toLowerCase().includes(q);
            const matchTags = item.tags && item.tags.some(tag => tag.toLowerCase().includes(q));
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
