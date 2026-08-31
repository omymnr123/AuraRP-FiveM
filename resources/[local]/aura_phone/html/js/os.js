const AuraOS = {
    isOpen: false,
    currentApp: 'home-screen',

    init: function() {
        window.addEventListener('message', (event) => {
            const data = event.data;
            if (data.action === "openPhone") {
                this.openPhone();
            } else if (data.action === "closePhone") {
                this.closePhone();
            }
        });

        // Reloj
        setInterval(() => {
            const now = new Date();
            let h = now.getHours();
            let m = now.getMinutes();
            if(h < 10) h = '0'+h;
            if(m < 10) m = '0'+m;
            document.getElementById('clock').innerText = `${h}:${m}`;
        }, 1000);

        // Escape para cerrar
        document.onkeyup = (data) => {
            if (data.key === "Escape") {
                this.closePhoneNUI();
            }
        };
    },

    openPhone: function() {
        this.isOpen = true;
        document.getElementById('phone-container').classList.remove('hidden');
        setTimeout(() => {
            document.getElementById('phone-container').classList.add('show');
        }, 50);
        this.showApp('home-screen');
    },

    closePhone: function() {
        this.isOpen = false;
        document.getElementById('phone-container').classList.remove('show');
        setTimeout(() => {
            document.getElementById('phone-container').classList.add('hidden');
        }, 600);
    },

    closePhoneNUI: function() {
        fetch(`https://${GetParentResourceName()}/close`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    },

    showApp: function(appId) {
        document.querySelectorAll('.app-view').forEach(el => el.classList.remove('active'));
        document.getElementById(appId).classList.add('active');
        this.currentApp = appId;
    },

    openApp: function(appName) {
        if (appName === 'bank') {
            this.loadBankData();
            this.showApp('app-bank');
        }
    },

    closeApp: function() {
        if(this.currentApp !== 'home-screen') {
            this.showApp('home-screen');
        } else {
            this.closePhoneNUI();
        }
    },

    // --- BANKING APP LOGIC --- //
    loadBankData: function() {
        fetch(`https://${GetParentResourceName()}/getBankBalance`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).then(resp => resp.json()).then(data => {
            // Formatear a moneda USD
            const formatted = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(data.balance);
            document.getElementById('bank-balance').innerText = formatted;
        });
    },

    sendTransfer: function() {
        const targetId = document.getElementById('transfer-id').value;
        const amount = document.getElementById('transfer-amount').value;
        const reason = document.getElementById('transfer-reason').value;
        const statusEl = document.getElementById('transfer-status');

        if (!targetId || !amount || amount <= 0) {
            statusEl.innerText = "Datos inválidos";
            statusEl.style.color = "#FF0055";
            return;
        }

        statusEl.innerText = "Procesando...";
        statusEl.style.color = "#00F0FF";

        fetch(`https://${GetParentResourceName()}/bankTransfer`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                targetId: parseInt(targetId),
                amount: parseInt(amount),
                reason: reason
            })
        }).then(resp => resp.json()).then(data => {
            if (data.success) {
                statusEl.innerText = "Transferencia Completada";
                statusEl.style.color = "#00FFaa";
                document.getElementById('transfer-id').value = '';
                document.getElementById('transfer-amount').value = '';
                document.getElementById('transfer-reason').value = '';
                this.loadBankData(); // Recargar balance
            } else {
                statusEl.innerText = data.message;
                statusEl.style.color = "#FF0055";
            }
        });
    }
};

window.onload = () => {
    AuraOS.init();
};
