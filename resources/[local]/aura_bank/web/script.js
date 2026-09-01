let app = document.getElementById('app');
let closeBtn = document.getElementById('close-btn');

const formatMoney = (amount) => {
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(amount);
};

const showNotification = (msg, isError = false) => {
    let div = document.createElement('div');
    div.className = 'notify';
    div.style.borderLeft = `4px solid ${isError ? 'var(--danger)' : 'var(--green-accent)'}`;
    div.innerText = msg;
    document.getElementById('notify-container').appendChild(div);
    
    setTimeout(() => {
        div.style.opacity = '0';
        div.style.transform = 'translateX(50px)';
        div.style.transition = 'all 0.3s ease';
        setTimeout(() => div.remove(), 300);
    }, 3000);
};

const postMessage = async (name, data = {}) => {
    try {
        const resp = await fetch(`https://aura_bank/${name}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });
        return await resp.json();
    } catch (e) {
        return null;
    }
};

const closeUI = () => {
    app.style.display = 'none';
    postMessage('close');
};

// TAB LOGIC
document.querySelectorAll('.nav-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
        
        btn.classList.add('active');
        document.getElementById(`tab-${btn.dataset.tab}`).classList.add('active');
    });
});

let balanceChart = null;
const initChart = async () => {
    const chartData = await postMessage('fetchChartData');
    if (!chartData || !chartData.labels) return;

    const ctx = document.getElementById('balanceChart').getContext('2d');
    
    if (balanceChart) balanceChart.destroy();

    balanceChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: chartData.labels,
            datasets: [{
                label: 'Saldo',
                data: chartData.data,
                borderColor: '#00f0ff',
                backgroundColor: 'rgba(0, 240, 255, 0.1)',
                borderWidth: 2,
                pointBackgroundColor: '#00f0ff',
                pointRadius: 4,
                pointHoverRadius: 6,
                fill: true,
                tension: 0.4
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false },
                tooltip: {
                    callbacks: {
                        label: function(context) {
                            return formatMoney(context.parsed.y);
                        }
                    }
                }
            },
            scales: {
                x: {
                    grid: { display: false, drawBorder: false },
                    ticks: { color: '#666' }
                },
                y: {
                    grid: { color: 'rgba(255,255,255,0.05)', drawBorder: false },
                    ticks: { display: false }
                }
            }
        }
    });
};

const updateUI = (data) => {
    document.getElementById('checking-balance').innerText = formatMoney(data.bank);
    document.getElementById('checking-iban').innerText = data.iban.match(/.{1,4}/g).join(' ');
    document.getElementById('checking-name').innerText = data.name.toUpperCase();
    
    document.getElementById('savings-balance').innerText = formatMoney(data.savings || 0);
    document.getElementById('savings-iban').innerText = "**** **** **** 8090"; // Decorative for savings
    document.getElementById('savings-name').innerText = data.name.toUpperCase();
    
    document.getElementById('user-name').innerText = data.name;
};

const renderTransactions = (txs) => {
    const recentList = document.getElementById('recent-tx-list');
    const fullList = document.getElementById('full-history-list');
    
    recentList.innerHTML = '';
    fullList.innerHTML = '';
    
    if (!txs || txs.length === 0) {
        recentList.innerHTML = '<div style="padding: 20px; text-align: center; color: #666;">Sin movimientos recientes</div>';
        return;
    }

    txs.forEach((tx, idx) => {
        let isPositive = tx.type === 'DEPOSIT' || tx.type === 'TRANSFER_RECEIVE' || tx.type === 'INITIAL' || tx.type === 'SALARY';
        
        let typeStr = tx.type.replace('_', ' ');
        if(tx.type === 'DEPOSIT') typeStr = 'Depósito';
        if(tx.type === 'WITHDRAW') typeStr = 'Retirada';
        if(tx.type === 'TRANSFER_SEND') typeStr = 'Envío Transf.';
        if(tx.type === 'TRANSFER_RECEIVE') typeStr = 'Recepción Transf.';
        
        let sign = isPositive ? '+' : '-';
        let amountClass = isPositive ? 'positive' : 'negative';
        let date = new Date(tx.timestamp).toLocaleString('es-ES');
        
        let iconClass = 'fas fa-exchange-alt';
        let iconBg = 'transfer';
        if (tx.type === 'DEPOSIT') { iconClass = 'fas fa-arrow-down'; iconBg = 'deposit'; }
        if (tx.type === 'WITHDRAW') { iconClass = 'fas fa-arrow-up'; iconBg = 'withdraw'; }

        // Render Recent (limit to 5)
        if (idx < 5) {
            recentList.innerHTML += `
                <div class="tx-item">
                    <div class="tx-icon ${iconBg}">
                        <i class="${iconClass}"></i>
                    </div>
                    <div class="tx-details">
                        <h4>${typeStr}</h4>
                        <p>${tx.reason}</p>
                    </div>
                    <div class="tx-amount ${amountClass}">
                        ${sign}${formatMoney(tx.amount)}
                    </div>
                </div>
            `;
        }

        // Render Full History
        fullList.innerHTML += `
            <tr>
                <td>${date}</td>
                <td>${typeStr}</td>
                <td>${tx.reason}</td>
                <td class="${amountClass}" style="font-weight: 600;">${sign}${formatMoney(tx.amount)}</td>
            </tr>
        `;
    });
};

const loadTransactions = async () => {
    const txs = await postMessage('fetchTransactions');
    renderTransactions(txs || []);
};

// Update time
setInterval(() => {
    const now = new Date();
    document.getElementById('current-time').innerText = now.toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' });
}, 1000);

// PIN MODAL LOGIC
const pinModal = document.getElementById('pin-modal');
const pinInput = document.getElementById('atm-pin-input');
let currentPin = '';

const handlePinInput = (val) => {
    if (currentPin.length < 4) {
        currentPin += val;
        pinInput.value = currentPin;
    }
};

document.querySelectorAll('.pin-btn:not(.action-btn)').forEach(btn => {
    btn.addEventListener('click', () => handlePinInput(btn.innerText));
});

document.getElementById('pin-cancel').addEventListener('click', () => {
    pinModal.style.display = 'none';
    currentPin = '';
    pinInput.value = '';
    postMessage('submitPin', { pin: null });
});

document.getElementById('pin-confirm').addEventListener('click', () => {
    if (currentPin.length === 4) {
        pinModal.style.display = 'none';
        postMessage('submitPin', { pin: currentPin });
        currentPin = '';
        pinInput.value = '';
    } else {
        pinInput.style.borderColor = 'var(--danger)';
        setTimeout(() => pinInput.style.borderColor = 'var(--aura-turquoise)', 500);
    }
});

// Keyboard support for PIN modal
window.addEventListener('keydown', (e) => {
    if (pinModal.style.display === 'flex') {
        if (e.key >= '0' && e.key <= '9') {
            handlePinInput(e.key);
        } else if (e.key === 'Backspace') {
            currentPin = currentPin.slice(0, -1);
            pinInput.value = currentPin;
        } else if (e.key === 'Enter') {
            document.getElementById('pin-confirm').click();
        } else if (e.key === 'Escape') {
            document.getElementById('pin-cancel').click();
        }
    }
});

// window.addEventListener messages handler
window.addEventListener('message', (e) => {
    const msg = e.data;
    
    if (msg.action === 'requestPin') {
        app.style.display = 'flex';
        document.querySelector('.bank-container').style.display = 'none';
        pinModal.style.display = 'flex';
        currentPin = '';
        pinInput.value = '';
    }
    
    if (msg.action === 'openUI') {
        app.style.display = 'flex';
        document.querySelector('.bank-container').style.display = 'flex';
        pinModal.style.display = 'none';
        updateUI(msg.data);
        loadTransactions();
        initChart();
        
        // Manejo de pestaña corporativa exclusiva para jefes/directores
        const corpNavBtn = document.getElementById('nav-btn-corporate');
        if (msg.data.isBoss && msg.data.society) {
            corpNavBtn.style.display = 'flex';
            document.getElementById('corp-company-name').innerText = `CUENTA: ${msg.data.society.label.toUpperCase()}`;
            document.getElementById('corp-society-holder').innerText = msg.data.society.label.toUpperCase();
            document.getElementById('corp-society-name').innerText = `SOCIETY_${msg.data.society.name.toUpperCase()}`;
            document.getElementById('corp-balance').innerText = formatMoney(msg.data.society.balance || 0);
        } else {
            corpNavBtn.style.display = 'none';
        }

        // Reset tabs
        document.querySelectorAll('.nav-btn')[0].click();
    }

    if (msg.action === 'updateBalance') {
        document.getElementById('checking-balance').innerText = formatMoney(msg.bank);
        document.getElementById('savings-balance').innerText = formatMoney(msg.savings || 0);
        loadTransactions();
        initChart(); // Update chart as well
    }
});

closeBtn.addEventListener('click', closeUI);
window.addEventListener('keyup', (e) => {
    if (e.key === 'Escape') closeUI();
});

// Actions
const handleAction = async (type, amountId, ibanId = null) => {
    let amountInput = document.getElementById(amountId);
    let amount = parseFloat(amountInput.value);
    
    let ibanInput = ibanId ? document.getElementById(ibanId) : null;
    let targetIban = ibanInput ? ibanInput.value.trim() : null;

    if (isNaN(amount) || amount <= 0) {
        showNotification('Cantidad inválida.', true);
        return;
    }
    
    if (ibanId && (!targetIban || targetIban.length < 5)) {
        showNotification('IBAN inválido.', true);
        return;
    }

    const res = await postMessage('doTransaction', {
        type: type,
        amount: amount,
        targetIban: targetIban
    });

    if (res) {
        if (res.success) {
            showNotification(res.message);
            amountInput.value = '';
            if (ibanInput) ibanInput.value = '';
        } else {
            showNotification(res.message, true);
        }
    }
};

document.getElementById('btn-deposit').addEventListener('click', () => handleAction('deposit', 'deposit-amount'));
document.getElementById('btn-withdraw').addEventListener('click', () => handleAction('withdraw', 'withdraw-amount'));
document.getElementById('btn-transfer').addEventListener('click', () => handleAction('transfer', 'transfer-amount', 'transfer-iban'));

// Savings Actions
document.getElementById('btn-to-savings').addEventListener('click', () => handleAction('transfer_to_savings', 'to-savings-amount'));
document.getElementById('btn-from-savings').addEventListener('click', () => handleAction('transfer_from_savings', 'from-savings-amount'));

// Card Services
document.getElementById('btn-request-card').addEventListener('click', async () => {
    const res = await postMessage('requestCard');
    if (res && res.success) {
        showNotification(res.message);
    } else {
        showNotification(res ? res.message : "Error al solicitar tarjeta", true);
    }
});

// PIN Change
document.getElementById('btn-change-pin').addEventListener('click', async () => {
    const pinInputBox = document.getElementById('new-pin-input');
    const newPin = pinInputBox.value.trim();

    if (newPin.length !== 4 || isNaN(newPin)) {
        showNotification('El PIN debe tener exactamente 4 números.', true);
        return;
    }

    const res = await postMessage('changePin', { pin: newPin });
    if (res && res.success) {
        showNotification(res.message);
        pinInputBox.value = '';
    } else {
        showNotification(res ? res.message : "Error al cambiar PIN", true);
    }
});

// ACCIONES DE BANCA CORPORATIVA (EXCLUSIVO DIRECTORES)
document.getElementById('btn-corp-deposit').addEventListener('click', async () => {
    const amountInput = document.getElementById('corp-deposit-amount');
    const amount = parseFloat(amountInput.value);

    if (isNaN(amount) || amount <= 0) {
        showNotification('Introduce una cantidad válida.', true);
        return;
    }

    const res = await postMessage('corporateDeposit', { amount: amount });
    if (res && res.success) {
        showNotification(res.message);
        amountInput.value = '';
        if (res.newBalance !== undefined) {
            document.getElementById('corp-balance').innerText = formatMoney(res.newBalance);
        }
    } else {
        showNotification(res ? res.message : "Error al depositar fondos corporativos", true);
    }
});

document.getElementById('btn-corp-withdraw').addEventListener('click', async () => {
    const amountInput = document.getElementById('corp-withdraw-amount');
    const amount = parseFloat(amountInput.value);

    if (isNaN(amount) || amount <= 0) {
        showNotification('Introduce una cantidad válida.', true);
        return;
    }

    const res = await postMessage('corporateWithdraw', { amount: amount });
    if (res && res.success) {
        showNotification(res.message);
        amountInput.value = '';
        if (res.newBalance !== undefined) {
            document.getElementById('corp-balance').innerText = formatMoney(res.newBalance);
        }
    } else {
        showNotification(res ? res.message : "Error al retirar fondos corporativos", true);
    }
});

