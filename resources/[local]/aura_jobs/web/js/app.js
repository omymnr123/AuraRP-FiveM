// ============================================================================
// AURA RP - POS BILLING & 24/7 STORE NUI CONTROLLER
// Framework: Vanilla JavaScript | Zero Bloat | High Performance
// ============================================================================

// ============================================================================
// 1. EFECTOS DE SONIDO SINTETIZADOS (WEB AUDIO API - ZERO ASSETS)
// ============================================================================

const audioCtx = new (window.AudioContext || window.webkitAudioContext)();

function playFeedbackSound(type) {
    try {
        if (audioCtx.state === 'suspended') {
            audioCtx.resume();
        }

        const osc = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        osc.connect(gain);
        gain.connect(audioCtx.destination);

        const now = audioCtx.currentTime;

        if (type === 'open') {
            osc.type = 'sine';
            osc.frequency.setValueAtTime(800, now);
            osc.frequency.exponentialRampToValueAtTime(1200, now + 0.08);
            gain.gain.setValueAtTime(0.06, now);
            gain.gain.exponentialRampToValueAtTime(0.001, now + 0.1);
            osc.start(now);
            osc.stop(now + 0.1);
        } else if (type === 'success') {
            osc.type = 'triangle';
            osc.frequency.setValueAtTime(523.25, now); // C5
            osc.frequency.setValueAtTime(659.25, now + 0.06); // E5
            osc.frequency.setValueAtTime(783.99, now + 0.12); // G5
            gain.gain.setValueAtTime(0.08, now);
            gain.gain.exponentialRampToValueAtTime(0.001, now + 0.3);
            osc.start(now);
            osc.stop(now + 0.3);
        } else if (type === 'error') {
            osc.type = 'sawtooth';
            osc.frequency.setValueAtTime(220, now);
            osc.frequency.setValueAtTime(140, now + 0.08);
            gain.gain.setValueAtTime(0.1, now);
            gain.gain.exponentialRampToValueAtTime(0.001, now + 0.22);
            osc.start(now);
            osc.stop(now + 0.22);
        } else if (type === 'click') {
            osc.type = 'sine';
            osc.frequency.setValueAtTime(1200, now);
            gain.gain.setValueAtTime(0.03, now);
            gain.gain.exponentialRampToValueAtTime(0.001, now + 0.05);
            osc.start(now);
            osc.stop(now + 0.05);
        }
    } catch (e) {
        // Fallback silencioso si el navegador bloquea audio
    }
}

function showToast(message, type = 'info') {
    const container = document.getElementById('toastContainer');
    if (!container) return;

    const toast = document.createElement('div');
    toast.className = `toast-item ${type}`;
    
    let icon = 'fa-solid fa-circle-info';
    if (type === 'success') icon = 'fa-solid fa-circle-check';
    if (type === 'error') icon = 'fa-solid fa-triangle-exclamation';

    toast.innerHTML = `<i class="${icon}"></i> <span>${message}</span>`;
    container.appendChild(toast);

    setTimeout(() => {
        toast.style.opacity = '0';
        toast.style.transform = 'translateX(50px)';
        toast.style.transition = 'all 0.3s';
        setTimeout(() => toast.remove(), 300);
    }, 4000);
}

function formatMoney(amount) {
    return new Intl.NumberFormat('en-US').format(amount);
}

// ============================================================================
// 2. POS BILLING CONTROLLER
// ============================================================================

let currentRegisterId = null;
let isPosProcessing = false;

const posContainer = document.getElementById('posContainer');
const businessNameEl = document.getElementById('businessName');
const employeeNameEl = document.getElementById('employeeName');
const billConceptEl = document.getElementById('billConcept');
const billAmountEl = document.getElementById('billAmount');
const registerCodeEl = document.getElementById('registerCode');

const statusBarEl = document.getElementById('statusBar');
const statusMessageEl = document.getElementById('statusMessage');
const statusIconEl = document.getElementById('statusIcon');

const btnPayCard = document.getElementById('btnPayCard');
const btnPayCash = document.getElementById('btnPayCash');
const btnCancel = document.getElementById('btnCancel');
const btnCloseIcon = document.getElementById('btnCloseIcon');

function showPosStatus(message, type = 'loading') {
    statusBarEl.classList.remove('hidden', 'error', 'success');
    statusMessageEl.textContent = message;

    if (type === 'loading') {
        statusIconEl.className = 'fa-solid fa-circle-notch fa-spin';
    } else if (type === 'error') {
        statusBarEl.classList.add('error');
        statusIconEl.className = 'fa-solid fa-triangle-exclamation';
        playFeedbackSound('error');
    } else if (type === 'success') {
        statusBarEl.classList.add('success');
        statusIconEl.className = 'fa-solid fa-circle-check';
        playFeedbackSound('success');
    }
}

function openPosBilling(data) {
    currentRegisterId = data.registerId;
    isPosProcessing = false;

    businessNameEl.textContent = data.business || "Comercio Registrado";
    employeeNameEl.textContent = data.employee || "Personal en Turno";
    billConceptEl.textContent = data.concept || "Consumo General";
    billAmountEl.textContent = formatMoney(data.amount || 0);
    registerCodeEl.textContent = data.registerId ? `#REG-${data.registerId}` : "#FACT-01";

    statusBarEl.classList.add('hidden');
    btnPayCard.disabled = false;
    btnPayCash.disabled = false;
    btnCancel.disabled = false;

    posContainer.classList.remove('hidden');
    playFeedbackSound('open');
}

function closePosBilling() {
    posContainer.classList.add('hidden');
    currentRegisterId = null;
    isPosProcessing = false;
}

function processPayment(paymentMethod) {
    if (isPosProcessing || !currentRegisterId) return;

    isPosProcessing = true;
    btnPayCard.disabled = true;
    btnPayCash.disabled = true;
    btnCancel.disabled = true;

    showPosStatus(`Conectando con pasarela ${paymentMethod === 'card' ? 'bancaria' : 'de efectivo'}...`, 'loading');

    fetch(`https://${GetParentResourceName()}/payBill`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({
            registerId: currentRegisterId,
            paymentMethod: paymentMethod
        })
    })
    .then(resp => resp.json())
    .then(response => {
        if (response && response.success) {
            showPosStatus(response.message || "Pago procesado y verificado con éxito.", 'success');
            setTimeout(() => {
                closePosBilling();
            }, 1200);
        } else {
            showPosStatus(response ? response.message : "Error al procesar la transacción.", 'error');
            setTimeout(() => {
                isPosProcessing = false;
                btnPayCard.disabled = false;
                btnPayCash.disabled = false;
                btnCancel.disabled = false;
            }, 2000);
        }
    })
    .catch(() => {
        showPosStatus("Fallo de comunicación con la terminal POS.", 'error');
        setTimeout(() => {
            isPosProcessing = false;
            btnPayCard.disabled = false;
            btnPayCash.disabled = false;
            btnCancel.disabled = false;
        }, 2000);
    });
}

function cancelBilling() {
    if (isPosProcessing) return;

    fetch(`https://${GetParentResourceName()}/cancelBill`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({ registerId: currentRegisterId })
    });

    playFeedbackSound('error');
    closePosBilling();
}

btnPayCard.addEventListener('click', () => processPayment('card'));
btnPayCash.addEventListener('click', () => processPayment('cash'));
btnCancel.addEventListener('click', cancelBilling);
btnCloseIcon.addEventListener('click', cancelBilling);

// ============================================================================
// 3. TIENDA AUTÓNOMA 24/7 CONTROLLER
// ============================================================================

let storeVendorKey = null;
let storeItems = [];
let storeCart = {}; // [itemName] = { name, label, price, count, maxStock, icon }
let currentCategory = 'all';
let isStoreCheckingOut = false;

const store247Container = document.getElementById('store247Container');
const storeBusinessName = document.getElementById('storeBusinessName');
const storeDescBizName = document.getElementById('storeDescBizName');
const btnStoreClose = document.getElementById('btnStoreClose');
const storeCategoriesBar = document.getElementById('storeCategoriesBar');
const storeProductsGrid = document.getElementById('storeProductsGrid');
const cartItemsList = document.getElementById('cartItemsList');
const cartTotalPrice = document.getElementById('cartTotalPrice');
const btnCheckoutCard = document.getElementById('btnCheckoutCard');
const btnCheckoutCash = document.getElementById('btnCheckoutCash');

function openStore247(data) {
    if (!data) return;

    storeVendorKey = data.vendorKey;
    storeItems = data.items || [];
    storeCart = {};
    currentCategory = 'all';
    isStoreCheckingOut = false;

    storeBusinessName.textContent = data.label || "Tienda 24/7";
    storeDescBizName.textContent = data.label || "este establecimiento";

    // Resetear categorías
    document.querySelectorAll('.btn-category').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.category === 'all');
    });

    renderProducts();
    renderCart();

    store247Container.classList.remove('hidden');
    playFeedbackSound('open');
}

function closeStore247() {
    store247Container.classList.add('hidden');
    storeVendorKey = null;
    storeCart = {};
    isStoreCheckingOut = false;

    fetch(`https://${GetParentResourceName()}/close247Store`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({})
    });
}

function filterCategory(category) {
    currentCategory = category;
    document.querySelectorAll('.btn-category').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.category === category);
    });
    playFeedbackSound('click');
    renderProducts();
}

function renderProducts() {
    storeProductsGrid.innerHTML = '';

    const filteredItems = storeItems.filter(item => {
        if (currentCategory === 'all') return true;
        return item.category === currentCategory;
    });

    if (filteredItems.length === 0) {
        storeProductsGrid.innerHTML = `
            <div style="grid-column: 1 / -1; text-align: center; color: #64748b; padding: 40px;">
                <i class="fa-solid fa-box-open" style="font-size: 32px; margin-bottom: 10px;"></i>
                <p>No hay productos disponibles en esta categoría.</p>
            </div>
        `;
        return;
    }

    filteredItems.forEach(item => {
        const inCartCount = storeCart[item.name]?.count || 0;
        const availableStock = Math.max(0, item.stock - inCartCount);
        const isOutOfStock = availableStock <= 0;

        const card = document.createElement('div');
        card.className = 'product-card';

        // Imagen con fallback directo
        const imageHtml = `
            <div class="product-image-box">
                <img src="images/${item.name}.png" 
                     onerror="this.onerror=null; this.src='https://cfx-nui-ox_inventory/web/images/${item.name}.png';">
            </div>
        `;

        card.innerHTML = `
            ${imageHtml}
            <div class="product-title">${item.label}</div>
            <div class="product-price-row">
                <span class="product-price">$${formatMoney(item.price)}</span>
            </div>
            <span class="product-stock-tag ${item.stock > 0 ? 'in-stock' : 'out-stock'}">
                ${item.stock > 0 ? `Stock: ${item.stock}` : 'Agotado'}
            </span>
            <button class="btn-add-cart ${isOutOfStock ? 'out' : ''}" 
                    ${isOutOfStock ? 'disabled' : ''} 
                    onclick="addToCart('${item.name}')">
                <i class="fa-solid ${isOutOfStock ? 'fa-ban' : 'fa-cart-plus'}"></i>
                <span>${isOutOfStock ? 'Fuera de stock' : 'Agregar al carrito'}</span>
            </button>
        `;

        storeProductsGrid.appendChild(card);
    });
}

window.addToCart = function(itemName) {
    const item = storeItems.find(it => it.name === itemName);
    if (!item || item.stock <= 0) return;

    if (!storeCart[itemName]) {
        storeCart[itemName] = {
            name: item.name,
            label: item.label,
            price: item.price,
            count: 1,
            maxStock: item.stock,
            icon: item.icon
        };
    } else {
        if (storeCart[itemName].count < item.stock) {
            storeCart[itemName].count++;
        } else {
            showToast(`Has alcanzado el límite de stock de ${item.label}.`, 'error');
            return;
        }
    }

    playFeedbackSound('click');
    renderProducts();
    renderCart();
};

window.updateCartQty = function(itemName, delta) {
    if (!storeCart[itemName]) return;

    storeCart[itemName].count += delta;

    if (storeCart[itemName].count <= 0) {
        delete storeCart[itemName];
    } else if (storeCart[itemName].count > storeCart[itemName].maxStock) {
        storeCart[itemName].count = storeCart[itemName].maxStock;
        showToast("Stock máximo alcanzado.", 'error');
    }

    playFeedbackSound('click');
    renderProducts();
    renderCart();
};

function renderCart() {
    cartItemsList.innerHTML = '';
    const cartKeys = Object.keys(storeCart);

    if (cartKeys.length === 0) {
        cartItemsList.innerHTML = `
            <div class="cart-empty-box">
                <i class="fa-solid fa-cart-shopping"></i>
                <p>Tu carrito está vacío</p>
            </div>
        `;
        cartTotalPrice.textContent = '0';
        btnCheckoutCard.disabled = true;
        btnCheckoutCash.disabled = true;
        return;
    }

    let total = 0;

    cartKeys.forEach(key => {
        const item = storeCart[key];
        const subtotal = item.price * item.count;
        total += subtotal;

        const row = document.createElement('div');
        row.className = 'cart-item-row';
        row.innerHTML = `
            <div style="display: flex; align-items: center; gap: 8px;">
                <img src="images/${item.name}.png" 
                     onerror="this.onerror=null; this.src='https://cfx-nui-ox_inventory/web/images/${item.name}.png';"
                     style="width: 28px; height: 28px; object-fit: contain;">
                <div class="cart-item-info">
                    <span class="cart-item-title">${item.label}</span>
                    <span class="cart-item-unit-price">$${formatMoney(item.price)} x ${item.count} = $${formatMoney(subtotal)}</span>
                </div>
            </div>
            <div class="cart-qty-ctrl">
                <button class="btn-qty" onclick="updateCartQty('${item.name}', -1)">-</button>
                <span class="cart-item-qty">${item.count}</span>
                <button class="btn-qty" onclick="updateCartQty('${item.name}', 1)">+</button>
            </div>
        `;
        cartItemsList.appendChild(row);
    });

    cartTotalPrice.textContent = formatMoney(total);
    btnCheckoutCard.disabled = false;
    btnCheckoutCash.disabled = false;
}

function checkoutStore(paymentMethod) {
    if (isStoreCheckingOut) return;

    const cartArray = Object.values(storeCart).map(it => ({
        name: it.name,
        count: it.count
    }));

    if (cartArray.length === 0) {
        showToast("Añade productos a tu carrito antes de pagar.", 'error');
        return;
    }

    isStoreCheckingOut = true;
    btnCheckoutCard.disabled = true;
    btnCheckoutCash.disabled = true;

    fetch(`https://${GetParentResourceName()}/checkout247Store`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({
            vendorKey: storeVendorKey,
            paymentMethod: paymentMethod,
            cart: cartArray
        })
    })
    .then(resp => resp.json())
    .then(data => {
        if (data && data.success) {
            playFeedbackSound('success');
            showToast(data.result.message || "Compra realizada con éxito.", 'success');
            
            // Actualizar stock local con los datos devueltos por el servidor
            if (data.result && data.result.items) {
                storeItems = data.result.items;
            }
            storeCart = {};
            renderProducts();
            renderCart();

            setTimeout(() => {
                closeStore247();
            }, 1500);
        } else {
            playFeedbackSound('error');
            showToast(data.result || "Error al procesar la compra.", 'error');
            isStoreCheckingOut = false;
            btnCheckoutCard.disabled = false;
            btnCheckoutCash.disabled = false;
        }
    })
    .catch(() => {
        playFeedbackSound('error');
        showToast("Error de conexión al procesar el pago.", 'error');
        isStoreCheckingOut = false;
        btnCheckoutCard.disabled = false;
        btnCheckoutCash.disabled = false;
    });
}

btnStoreClose.addEventListener('click', closeStore247);
btnCheckoutCard.addEventListener('click', () => checkoutStore('bank'));
btnCheckoutCash.addEventListener('click', () => checkoutStore('cash'));

// Categorías delegadas
storeCategoriesBar.addEventListener('click', (e) => {
    const btn = e.target.closest('.btn-category');
    if (btn) {
        filterCategory(btn.dataset.category);
    }
});

// ============================================================================
// 4. RECEPCIÓN DE MENSAJES NUI & LISTENER ESC
// ============================================================================

window.addEventListener('message', function(event) {
    const item = event.data;
    if (!item) return;

    if (item.action === 'openBilling') {
        openPosBilling(item.data);
    } else if (item.action === 'closeBilling') {
        closePosBilling();
    } else if (item.action === 'open247Store') {
        openStore247(item.data);
    } else if (item.action === 'close247Store') {
        store247Container.classList.add('hidden');
    }
});

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        if (!posContainer.classList.contains('hidden')) {
            cancelBilling();
        }
        if (!store247Container.classList.contains('hidden')) {
            closeStore247();
        }
    }
});
