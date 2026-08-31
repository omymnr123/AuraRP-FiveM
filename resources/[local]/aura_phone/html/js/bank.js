// Módulo aislado para la aplicación del Banco
const AuraBankApp = {
    
    // El Core llamará a esto para inyectar el HTML de la app
    getHTML: function() {
        return `
            <div id="app-bank-window" class="app-window" style="background: var(--bg-dark);">
                <div class="app-header">
                    <i class="fas fa-university app-icon-small"></i>
                    <span>Aura Bank</span>
                </div>
                
                <div id="app-view-bank" class="bank-content">
                    <div class="balance-card">
                        <h3>Balance Disponible</h3>
                        <h1 id="bank-balance">Cargando...</h1>
                    </div>
                    
                    <div class="transfer-box">
                        <h3>Transferencia Inmediata</h3>
                        <input type="number" id="transfer-id" placeholder="ID del Personaje Destino">
                        <input type="number" id="transfer-amount" placeholder="Cantidad ($)">
                        <input type="text" id="transfer-reason" placeholder="Concepto (Opcional)">
                        <button class="btn-glow" onclick="AuraBankApp.sendTransfer()">Enviar Fondos</button>
                        <p id="transfer-status"></p>
                    </div>
                </div>
            </div>
        `;
    },

    // El Core llamará a esto cada vez que se abra la app
    onOpen: function() {
        document.getElementById('transfer-status').innerText = '';
        this.fetchBalance();
    },

    fetchBalance: function() {
        fetch(`https://${GetParentResourceName()}/getBankBalance`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        })
        .then(resp => resp.json())
        .then(data => {
            const formatted = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(data.balance);
            document.getElementById('bank-balance').innerText = formatted;
        })
        .catch(err => {
            console.error("AuraBank Error:", err);
            document.getElementById('bank-balance').innerText = "Error";
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

        statusEl.innerText = "Procesando de forma segura...";
        statusEl.style.color = "#00F0FF";

        fetch(`https://${GetParentResourceName()}/bankTransfer`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                targetId: parseInt(targetId),
                amount: parseInt(amount),
                reason: reason
            })
        })
        .then(resp => resp.json())
        .then(data => {
            if (data.success) {
                statusEl.innerText = "Transferencia Completada";
                statusEl.style.color = "#00FFaa";
                document.getElementById('transfer-id').value = '';
                document.getElementById('transfer-amount').value = '';
                document.getElementById('transfer-reason').value = '';
                this.fetchBalance(); // Recargar balance
            } else {
                statusEl.innerText = data.message;
                statusEl.style.color = "#FF0055";
            }
        })
        .catch(err => {
            statusEl.innerText = "Error de conexión";
            statusEl.style.color = "#FF0055";
        });
    }
};

window.AuraBankApp = AuraBankApp;
