const CIRCUMFERENCE = 113.097;

// DOM Elements
const container = document.getElementById('hud-container');
const rings = {
    health: { 
        circle: document.getElementById('circle-health'),
        item: document.getElementById('item-health')
    },
    armor: { 
        circle: document.getElementById('circle-armor'),
        item: document.getElementById('item-armor')
    },
    stamina: { 
        circle: document.getElementById('circle-stamina'),
        item: document.getElementById('item-stamina')
    },
    hunger: { 
        circle: document.getElementById('circle-hunger'),
        item: document.getElementById('item-hunger')
    },
    thirst: { 
        circle: document.getElementById('circle-thirst'),
        item: document.getElementById('item-thirst')
    },
    voice: {
        circle: document.getElementById('circle-voice'),
        item: document.getElementById('item-voice')
    }
};

// Inicialización: ocultar todos los indicadores dinámicos por defecto
function initializeHUD() {
    for (const key in rings) {
        if (rings[key] && rings[key].item) {
            setVisibility(rings[key].item, false);
        }
    }
}

if (document.readyState === 'loading') {
    window.addEventListener('DOMContentLoaded', initializeHUD);
} else {
    initializeHUD();
}

// Función para ocultar/mostrar elementos fluidamente
function setVisibility(item, isVisible) {
    if (!item) return;
    if (isVisible) {
        item.style.width = '44px';
        item.style.margin = ''; 
        item.style.opacity = '1';
        item.style.transform = 'scale(1)';
    } else {
        item.style.width = '0';
        item.style.margin = '0';
        item.style.opacity = '0';
        item.style.transform = 'scale(0)';
    }
}

// Variables de estado para el sistema de Armadura Dinámica
let lastArmor = null;
let armorHideTimeout = null;

// Manejo inteligente del indicador de armadura
function updateArmor(percent) {
    if (!rings.armor || !rings.armor.circle || !rings.armor.item) return;
    
    percent = Number(percent);
    if (isNaN(percent)) percent = 0;
    percent = Math.max(0, Math.min(100, Math.round(percent)));
    
    // Calcular offset del anillo (100% = 0, 0% = 113.097)
    const offset = CIRCUMFERENCE - (percent / 100) * CIRCUMFERENCE;
    rings.armor.circle.style.strokeDashoffset = offset;
    
    // Estado de peligro (rojo pulsante) si está en estado crítico (1% - 20%)
    if (percent > 0 && percent <= 20) {
        rings.armor.item.classList.add('danger-state');
    } else {
        rings.armor.item.classList.remove('danger-state');
    }
    
    // 1. Armadura en 0% (Sin chaleco o chaleco roto)
    if (percent === 0) {
        if (armorHideTimeout) {
            clearTimeout(armorHideTimeout);
            armorHideTimeout = null;
        }
        if (lastArmor !== null && lastArmor > 0) {
            // Permitir ver cómo se vacía el círculo antes de desvanecerse
            setTimeout(() => {
                if (lastArmor === 0) {
                    setVisibility(rings.armor.item, false);
                }
            }, 350);
        } else {
            setVisibility(rings.armor.item, false);
        }
        lastArmor = 0;
        return;
    }
    
    // 2. Armadura al 100% (Chaleco nuevo puesto o lleno)
    if (percent >= 100) {
        if (lastArmor === null || lastArmor < 100) {
            // Mostrar cómo se llena el círculo al 100%
            setVisibility(rings.armor.item, true);
            
            if (armorHideTimeout) clearTimeout(armorHideTimeout);
            // Mantener visible durante 3 segundos para confirmación visual y luego ocultar suavemente
            armorHideTimeout = setTimeout(() => {
                if (lastArmor >= 100) {
                    setVisibility(rings.armor.item, false);
                }
            }, 3000);
        }
        lastArmor = 100;
        return;
    }
    
    // 3. Armadura desgastada entre 1% y 99% (Permanecer visible mostrando escudo restante)
    if (armorHideTimeout) {
        clearTimeout(armorHideTimeout);
        armorHideTimeout = null;
    }
    setVisibility(rings.armor.item, true);
    lastArmor = percent;
}

// Función ultra rápida para actualizar un anillo
function updateRing(type, percent) {
    if (!rings[type]) return;
    
    if (type === 'armor') {
        updateArmor(percent);
        return;
    }
    
    // Asegurar número y límites válidos
    percent = Number(percent);
    if (isNaN(percent)) percent = 100;
    percent = Math.max(0, Math.min(100, percent));
    
    // Lógica dinámica de HUD Inteligente para resto de atributos
    if (type === 'hunger' || type === 'thirst') {
        setVisibility(rings[type].item, percent <= 70);
    } else if (type === 'health') {
        setVisibility(rings[type].item, percent <= 95);
    } else if (type === 'stamina') {
        setVisibility(rings[type].item, percent < 99);
    }

    // Calcular offset
    // 100% = 0 offset, 0% = 113.097 offset
    const offset = CIRCUMFERENCE - (percent / 100) * CIRCUMFERENCE;
    rings[type].circle.style.strokeDashoffset = offset;

    // Añadir clase de peligro si el nivel es bajo (<= 20%)
    if (percent <= 20) {
        rings[type].item.classList.add('danger-state');
    } else {
        rings[type].item.classList.remove('danger-state');
    }
}

// Listener de eventos NUI enviados desde el cliente LUA
window.addEventListener('message', (event) => {
    const data = event.data;

    switch (data.action) {
        case 'showHUD':
            container.classList.remove('hidden');
            break;
            
        case 'hideHUD':
            container.classList.add('hidden');
            break;
            
        case 'updateStatus':
            updateRing('health', data.health);
            updateRing('armor', data.armor);
            updateRing('stamina', data.stamina);
            updateRing('hunger', data.hunger);
            updateRing('thirst', data.thirst);
            break;

        case 'updateVoice':
            if (data.isTalking) {
                rings.voice.item.classList.add('talking');
                setVisibility(rings.voice.item, true);
            } else {
                rings.voice.item.classList.remove('talking');
                setVisibility(rings.voice.item, false);
            }
            break;
            
        case 'showVoiceTemporary':
            // Mostrar temporalmente al cambiar el rango de voz
            setVisibility(rings.voice.item, true);
            // Actualizar porcentaje simulando el rango (opcional)
            if (data.rangePercent !== undefined) {
                const offset = CIRCUMFERENCE - (data.rangePercent / 100) * CIRCUMFERENCE;
                rings.voice.circle.style.strokeDashoffset = offset;
            }
            
            // Ocultar después de 2 segundos si no está hablando
            setTimeout(() => {
                if (!rings.voice.item.classList.contains('talking')) {
                    setVisibility(rings.voice.item, false);
                }
            }, 2000);
            break;
            
        case 'editMode':
            document.getElementById('edit-overlay').classList.remove('hidden');
            container.classList.add('editing');
            const hotbarEl = document.getElementById('hotbar-preview');
            if (hotbarEl) {
                hotbarEl.classList.remove('hidden');
                hotbarEl.classList.add('editing');
            }
            break;

        case 'setPosition':
            if (data.hud && data.hud.x !== undefined) {
                container.style.left = data.hud.x + '%';
                container.style.bottom = data.hud.y + '%';
            } else if (data.x !== undefined) {
                container.style.left = data.x + '%';
                container.style.bottom = data.y + '%';
            }
            
            const hotbarPreviewEl = document.getElementById('hotbar-preview');
            if (hotbarPreviewEl && data.hotbar && data.hotbar.x !== undefined) {
                hotbarPreviewEl.style.left = data.hotbar.x + '%';
                hotbarPreviewEl.style.bottom = data.hotbar.y + '%';
                hotbarPreviewEl.style.transform = 'none';
            }
            break;
            
        case 'updateMinimapBorder':
            const mapBorder = document.getElementById('minimap-border');
            if (mapBorder && data.rect) {
                mapBorder.classList.remove('hidden');
                mapBorder.style.left = (data.rect.x * window.innerWidth) + 'px';
                mapBorder.style.top = (data.rect.y * window.innerHeight) + 'px';
                mapBorder.style.width = (data.rect.width * window.innerWidth) + 'px';
                mapBorder.style.height = (data.rect.height * window.innerHeight) + 'px';
            }
            break;
    }
});

// Drag & Drop Logic (HUD Anillos y Cinturón de Items)
const hotbarPreview = document.getElementById('hotbar-preview');

let activeDragElement = null;
let startDragX, startDragY, initialElemLeft, initialElemBottom;

function setupDraggable(elem) {
    if (!elem) return;
    elem.addEventListener('mousedown', (e) => {
        if (!elem.classList.contains('editing')) return;
        activeDragElement = elem;
        startDragX = e.clientX;
        startDragY = e.clientY;
        
        const rect = elem.getBoundingClientRect();
        initialElemLeft = rect.left;
        initialElemBottom = window.innerHeight - rect.bottom;
        elem.style.transform = 'none'; // Quitar transform centrado durante el arrastre
    });
}

setupDraggable(container);
setupDraggable(hotbarPreview);

window.addEventListener('mousemove', (e) => {
    if (!activeDragElement) return;
    
    const dx = e.clientX - startDragX;
    const dy = e.clientY - startDragY;
    
    let newLeft = initialElemLeft + dx;
    let newBottom = initialElemBottom - dy;
    
    const percentX = (newLeft / window.innerWidth) * 100;
    const percentY = (newBottom / window.innerHeight) * 100;
    
    // Limitar dentro de la pantalla (1% a 95%)
    const clampedX = Math.max(0.5, Math.min(95, percentX));
    const clampedY = Math.max(0.5, Math.min(95, percentY));
    
    activeDragElement.style.left = `${clampedX}%`;
    activeDragElement.style.bottom = `${clampedY}%`;
});

window.addEventListener('mouseup', () => {
    activeDragElement = null;
});

// Función para cerrar el modo edición
function closeEditMode() {
    document.getElementById('edit-overlay').classList.add('hidden');
    container.classList.remove('editing');
    if (hotbarPreview) {
        hotbarPreview.classList.add('hidden');
        hotbarPreview.classList.remove('editing');
    }
}

// 1. Guardar Posición Definitiva
document.getElementById('save-btn').addEventListener('click', () => {
    closeEditMode();
    
    // Extraer porcentajes actuales
    const hudLeft = parseFloat(container.style.left) || 17.5;
    const hudBottom = parseFloat(container.style.bottom) || 3.5;
    
    const hotbarLeft = hotbarPreview ? (parseFloat(hotbarPreview.style.left) || 50) : 50;
    const hotbarBottom = hotbarPreview ? (parseFloat(hotbarPreview.style.bottom) || 3.5) : 3.5;
    
    // Enviar a LUA para guardar en DB
    fetch(`https://${GetParentResourceName()}/savePos`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            hud: {
                x: Number(hudLeft.toFixed(2)),
                y: Number(hudBottom.toFixed(2))
            },
            hotbar: {
                x: Number(hotbarLeft.toFixed(2)),
                y: Number(hotbarBottom.toFixed(2))
            }
        })
    });
});

// 2. Restablecer Posiciones por Defecto
document.getElementById('reset-btn').addEventListener('click', () => {
    container.style.left = '17.5%';
    container.style.bottom = '3.5%';
    
    if (hotbarPreview) {
        hotbarPreview.style.left = '50%';
        hotbarPreview.style.bottom = '3.5%';
        hotbarPreview.style.transform = 'translateX(-50%)';
    }
});

// 3. Cancelar Edición
document.getElementById('cancel-btn').addEventListener('click', () => {
    closeEditMode();
    fetch(`https://${GetParentResourceName()}/closeEdit`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({})
    });
});

// 4. Cancelar con tecla Escape
window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && !document.getElementById('edit-overlay').classList.contains('hidden')) {
        closeEditMode();
        fetch(`https://${GetParentResourceName()}/closeEdit`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({})
        });
    }
});
