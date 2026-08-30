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

// Ocultar voz por defecto al iniciar
window.addEventListener('DOMContentLoaded', () => {
    setVisibility(rings.voice.item, false);
});

// Función para ocultar/mostrar elementos fluidamente
function setVisibility(item, isVisible) {
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

// Función ultra rápida para actualizar un anillo
function updateRing(type, percent) {
    if (!rings[type]) return;
    
    // Lógica dinámica de HUD Inteligente
    if (type === 'armor') {
        setVisibility(rings[type].item, percent > 0);
    } else if (type === 'hunger' || type === 'thirst') {
        setVisibility(rings[type].item, percent <= 70);
    } else if (type === 'health') {
        setVisibility(rings[type].item, percent <= 95);
    } else if (type === 'stamina') {
        setVisibility(rings[type].item, percent < 100);
    }

    // Calcular offset
    // 100% = 0 offset, 0% = 113.097 offset
    const offset = CIRCUMFERENCE - (percent / 100) * CIRCUMFERENCE;
    rings[type].circle.style.strokeDashoffset = offset;

    // Añadir clase de peligro si el nivel es bajo (< 20%)
    if (type !== 'armor') {
        if (percent <= 20) {
            rings[type].item.classList.add('danger-state');
        } else {
            rings[type].item.classList.remove('danger-state');
        }
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
            break;

        case 'setPosition':
            if (data.x) {
                container.style.left = data.x + '%';
                container.style.bottom = data.y + '%';
            } else if (data.hud && data.hud.x) {
                container.style.left = data.hud.x + '%';
                container.style.bottom = data.hud.y + '%';
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

// Drag & Drop Logic (HUD Anillos)
let isDraggingHUD = false;
let startHUDX, startHUDY, initialHUDLeft, initialHUDBottom;

container.addEventListener('mousedown', (e) => {
    if (!container.classList.contains('editing')) return;
    isDraggingHUD = true;
    startHUDX = e.clientX;
    startHUDY = e.clientY;
    
    const rect = container.getBoundingClientRect();
    initialHUDLeft = rect.left;
    initialHUDBottom = window.innerHeight - rect.bottom;
});

window.addEventListener('mousemove', (e) => {
    if (!isDraggingHUD) return;
    
    const dx = e.clientX - startHUDX;
    const dy = e.clientY - startHUDY;
    
    let newLeft = initialHUDLeft + dx;
    let newBottom = initialHUDBottom - dy;
    
    const percentX = (newLeft / window.innerWidth) * 100;
    const percentY = (newBottom / window.innerHeight) * 100;
    
    container.style.left = `${percentX}%`;
    container.style.bottom = `${percentY}%`;
});

window.addEventListener('mouseup', () => {
    isDraggingHUD = false;
});

// Guardar Posición Definitiva
document.getElementById('save-btn').addEventListener('click', () => {
    // Quitar UI de edición
    document.getElementById('edit-overlay').classList.add('hidden');
    container.classList.remove('editing');
    
    // Extraer porcentajes actuales
    const hudLeft = parseFloat(container.style.left) || 17.5;
    const hudBottom = parseFloat(container.style.bottom) || 3.5;
    
    // Enviar a LUA para guardar en DB
    fetch(`https://${GetParentResourceName()}/savePos`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            x: hudLeft,
            y: hudBottom
        })
    });
});
