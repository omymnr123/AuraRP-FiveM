// ============================================================================
// AURA HUB - JAVASCRIPT CONTROLLER (GRID & MODAL ARCHITECTURE)
// ============================================================================

let currentHubData = null;
let announcementTimeout = null;

// Elementos Top Bar
const topPlayerName = document.getElementById('topPlayerName');
const topPlayerJob = document.getElementById('topPlayerJob');
const topPlayerId = document.getElementById('topPlayerId');
const topStatCash = document.getElementById('topStatCash');
const topStatBank = document.getElementById('topStatBank');
const topAvatarImg = document.getElementById('topAvatarImg');
const topAvatarFallback = document.getElementById('topAvatarFallback');

// Contadores Sidebar
const openBusinessesList = document.getElementById('openBusinessesList');
const statPlayersOnline = document.getElementById('statPlayersOnline');
const statPoliceStatus = document.getElementById('statPoliceStatus');

// Contenedores Base
const hubWrapper = document.getElementById('hubWrapper');
const btnCloseHub = document.getElementById('btnCloseHub');

// Banner Global
const globalBanner = document.getElementById('globalBanner');
const bannerCard = document.getElementById('bannerCard');
const bannerTitle = document.getElementById('bannerTitle');
const bannerSubtitle = document.getElementById('bannerSubtitle');
const bannerBadgeText = document.getElementById('bannerBadgeText');
const bannerIcon = document.getElementById('bannerIcon');

// Toast Container
const toastContainer = document.getElementById('toastContainer');

// ============================================================================
// AUDIO SINTETIZADO (WEB AUDIO API)
// ============================================================================
const audioCtx = new (window.AudioContext || window.webkitAudioContext)();

function playTone(type) {
    try {
        if (audioCtx.state === 'suspended') {
            audioCtx.resume();
        }

        const osc = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        osc.connect(gain);
        gain.connect(audioCtx.destination);

        const now = audioCtx.currentTime;

        if (type === 'announcement') {
            osc.type = 'sine';
            osc.frequency.setValueAtTime(587.33, now); // D5
            osc.frequency.setValueAtTime(880, now + 0.1); // A5
            gain.gain.setValueAtTime(0.08, now);
            gain.gain.exponentialRampToValueAtTime(0.001, now + 0.4);
            osc.start(now);
            osc.stop(now + 0.4);
        } else if (type === 'click') {
            osc.type = 'sine';
            osc.frequency.setValueAtTime(1000, now);
            gain.gain.setValueAtTime(0.03, now);
            gain.gain.exponentialRampToValueAtTime(0.001, now + 0.05);
            osc.start(now);
            osc.stop(now + 0.05);
        }
    } catch (e) {}
}

// ============================================================================
// UTILIDADES
// ============================================================================
function formatMoney(amount) {
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(amount);
}

function updateOpenBusinessesList(businesses) {
    if (!openBusinessesList) return;
    openBusinessesList.innerHTML = '';
    if (businesses && Array.isArray(businesses) && businesses.length > 0) {
        businesses.forEach(b => {
            const div = document.createElement('div');
            div.className = 'business-entry';
            div.innerHTML = `<i class="fa-solid fa-store"></i> <span>${b.label}</span>`;
            openBusinessesList.appendChild(div);
        });
    } else {
        openBusinessesList.innerHTML = `<div class="business-empty-msg"><i class="fa-solid fa-store-slash"></i><br>No hay comercios abiertos</div>`;
    }
}

function showToast(message, isError = false) {
    const toast = document.createElement('div');
    toast.className = `toast ${isError ? 'error' : ''}`;
    toast.innerHTML = `<i class="fa-solid ${isError ? 'fa-triangle-exclamation' : 'fa-circle-check'}"></i> ${message}`;
    toastContainer.appendChild(toast);

    setTimeout(() => {
        toast.style.opacity = '0';
        toast.style.transform = 'translateX(40px)';
        toast.style.transition = 'all 0.25s ease';
        setTimeout(() => toast.remove(), 250);
    }, 4000);
}

async function postFetch(endpoint, data = {}) {
    try {
        const res = await fetch(`https://aura_hub/${endpoint}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });
        return await res.json();
    } catch (e) {
        return null;
    }
}

// ============================================================================
// GESTIÓN DE MODALES
// ============================================================================
window.openModal = (modalId) => {
    playTone('click');
    document.querySelectorAll('.hub-modal-overlay').forEach(m => m.classList.add('hidden'));
    const target = document.getElementById(modalId);
    if (target) target.classList.remove('hidden');
};

window.closeModal = (modalId) => {
    playTone('click');
    const target = document.getElementById(modalId);
    if (target) target.classList.add('hidden');
};

// ============================================================================
// RENDERIZADO DEL HUB
// ============================================================================
function renderHub(data) {
    currentHubData = data;

    // Header Info
    topPlayerName.textContent = data.name;
    topPlayerJob.textContent = data.job.label;
    topPlayerId.textContent = `ID: ${data.serverId || 1}`;
    topStatCash.textContent = formatMoney(data.accounts.cash || 0);
    topStatBank.textContent = formatMoney(data.accounts.bank || 0);

    // Avatar Real del Personaje (Ped Headshot)
    if (data.mugshot && data.mugshot !== "none") {
        topAvatarImg.onerror = () => {
            topAvatarImg.style.display = 'none';
            topAvatarFallback.style.display = 'block';
        };
        topAvatarImg.src = `https://nui-img/${data.mugshot}/${data.mugshot}`;
        topAvatarImg.style.display = 'block';
        topAvatarFallback.style.display = 'none';
    } else {
        topAvatarImg.style.display = 'none';
        topAvatarFallback.style.display = 'block';
    }

    // Contadores Sidebar
    statPlayersOnline.textContent = `${data.onlinePlayers || 1} / ${data.maxPlayers || 48}`;
    const policeCount = data.services ? data.services.police : 0;
    statPoliceStatus.textContent = policeCount > 0 ? `DISPONIBLE (${policeCount})` : `NO DISPONIBLE`;

    // Lista de Negocios Abiertos
    updateOpenBusinessesList(data.openBusinesses);

    // Modal Negocio Configuración
    document.getElementById('modalBizName').textContent = data.job.isBusiness ? data.job.label.toUpperCase() : "SIN NEGOCIO ASIGNADO";
    document.getElementById('modalBizGrade').textContent = `Puesto: ${data.job.gradeLabel}`;

    const beacon = document.getElementById('modalBizBeacon');
    const bizStateText = document.getElementById('modalBizStateText');
    if (data.businessOpen) {
        beacon.classList.add('open');
        bizStateText.textContent = "ABIERTO AL PÚBLICO";
        bizStateText.style.color = "#6ee7b7";
    } else {
        beacon.classList.remove('open');
        bizStateText.textContent = "CERRADO";
        bizStateText.style.color = "#fca5a5";
    }

    // Pestañas Boss en Modal Negocio
    const hrBtn = document.getElementById('modalBizHrBtn');
    const financeBtn = document.getElementById('modalBizFinanceBtn');
    if (data.isBoss && data.society) {
        hrBtn.style.display = 'flex';
        financeBtn.style.display = 'flex';
        document.getElementById('modalSocBalance').textContent = formatMoney(data.society.balance || 0);
    } else {
        hrBtn.style.display = 'none';
        financeBtn.style.display = 'none';
    }

    // Modal Servicios
    if (data.services) {
        document.getElementById('srvPoliceText').textContent = `${data.services.police} Oficiales de servicio`;
        document.getElementById('srvEmsText').textContent = `${data.services.ems} Médicos de servicio`;
        document.getElementById('srvMecText').textContent = `${data.services.mechanic} Mecánicos de servicio`;
        document.getElementById('srvTaxiText').textContent = `${data.services.taxi} Conductores de servicio`;
    }

    // Resetear modales ocultos
    document.querySelectorAll('.hub-modal-overlay').forEach(m => m.classList.add('hidden'));
    hubWrapper.classList.remove('hidden');
}

function closeHub() {
    hubWrapper.classList.add('hidden');
    document.querySelectorAll('.hub-modal-overlay').forEach(m => m.classList.add('hidden'));
    postFetch('closeHub');
}

// ============================================================================
// RRHH / EMPLEADOS EN MODAL
// ============================================================================
async function loadEmployees() {
    const res = await postFetch('fetchEmployees');
    if (!res || !res.success || !res.data) {
        showToast("Error al cargar la plantilla de empleados", true);
        return;
    }

    const { employees } = res.data;
    const tableBody = document.getElementById('modalEmployeeTableBody');
    tableBody.innerHTML = '';

    if (employees.length === 0) {
        tableBody.innerHTML = `<tr><td colspan="5" style="text-align:center; padding: 20px; color: var(--text-dim);">No hay empleados contratados.</td></tr>`;
        return;
    }

    employees.forEach(emp => {
        const tr = document.createElement('tr');
        const onlineText = emp.isOnline ? `<span style="color:#6ee7b7;">Online (ID: ${emp.src})</span>` : `<span style="color:#64748b;">Offline</span>`;

        tr.innerHTML = `
            <td>${onlineText}</td>
            <td><strong>${emp.name}</strong> <small style="color:var(--text-dim);">(${emp.citizenid})</small></td>
            <td><span style="color:var(--turquoise-main); font-weight:700;">${emp.gradeLabel} (${emp.grade})</span></td>
            <td style="font-family:var(--font-mono); color:#ffffff;">${formatMoney(emp.salary)}</td>
            <td style="text-align: right;">
                <button class="btn-emp-action" title="Ascender" onclick="changeGrade(${emp.charId}, ${emp.grade + 1})"><i class="fa-solid fa-arrow-up"></i></button>
                <button class="btn-emp-action" title="Degradar" onclick="changeGrade(${emp.charId}, ${emp.grade - 1})"><i class="fa-solid fa-arrow-down"></i></button>
                <button class="btn-emp-action fire" title="Despedir" onclick="fireEmp(${emp.charId})"><i class="fa-solid fa-user-xmark"></i></button>
            </td>
        `;
        tableBody.appendChild(tr);
    });
}

window.changeGrade = async (targetCharId, newGrade) => {
    if (newGrade < 0) {
        showToast("El empleado ya tiene el rango mínimo.", true);
        return;
    }
    const res = await postFetch('setEmployeeGrade', { targetCharId, newGrade });
    if (res && res.success) {
        showToast(res.message);
        loadEmployees();
    } else {
        showToast(res ? res.message : "Error al modificar rango", true);
    }
};

window.fireEmp = async (targetCharId) => {
    const res = await postFetch('fireEmployee', { targetCharId });
    if (res && res.success) {
        showToast(res.message);
        loadEmployees();
    } else {
        showToast(res ? res.message : "Error al despedir", true);
    }
};

// ============================================================================
// ESCUCHA DE EVENTOS NUI
// ============================================================================
window.addEventListener('message', (event) => {
    const payload = event.data;
    if (!payload) return;

    if (payload.action === 'openHub') {
        renderHub(payload.data);
    } else if (payload.action === 'closeHub') {
        hubWrapper.classList.add('hidden');
    } else if (payload.action === 'showAnnouncement') {
        triggerGlobalAnnouncement(payload.data);
    }
});

// ============================================================================
// BANNER GLOBAL ANIMADO
// ============================================================================
function triggerGlobalAnnouncement(data) {
    if (announcementTimeout) {
        clearTimeout(announcementTimeout);
    }

    bannerTitle.textContent = data.business || "Comercio Local";
    const isOpen = data.isOpen == true;

    if (isOpen) {
        bannerCard.classList.remove('closed');
        bannerIcon.className = 'fa-solid fa-door-open';
        bannerSubtitle.textContent = "El establecimiento está ahora ABIERTO al público.";
        bannerBadgeText.textContent = "ABIERTO";
    } else {
        bannerCard.classList.add('closed');
        bannerIcon.className = 'fa-solid fa-door-closed';
        bannerSubtitle.textContent = "El establecimiento ha CERRADO sus puertas.";
        bannerBadgeText.textContent = "CERRADO";
    }

    if (data.openBusinesses) {
        updateOpenBusinessesList(data.openBusinesses);
    }

    playTone('announcement');
    globalBanner.classList.remove('hidden');
    globalBanner.classList.add('show');

    announcementTimeout = setTimeout(() => {
        globalBanner.classList.remove('show');
        setTimeout(() => globalBanner.classList.add('hidden'), 450);
    }, data.duration || 7000);
}

// ============================================================================
// EVENT LISTENERS: TILES & BOTONES
// ============================================================================

// Tile 1: MAPA -> Llama callback NUI para abrir mapa nativo GTA V
document.getElementById('tileMap').addEventListener('click', () => {
    playTone('click');
    postFetch('openMap');
});

// Tile 2: SERVICIOS
document.getElementById('tileServices').addEventListener('click', () => {
    openModal('modalServices');
});

// Tile 3: MI NEGOCIO
document.getElementById('tileBusiness').addEventListener('click', () => {
    openModal('modalBusiness');
    document.querySelectorAll('.modal-tab-btn')[0].click();
});

// Tile 4: MI ORGANIZACIÓN
document.getElementById('tileOrg').addEventListener('click', () => {
    openModal('modalServices');
});

// Botones de Cabecera
document.getElementById('btnActionSettings').addEventListener('click', () => openModal('modalSettings'));
document.getElementById('btnActionInvoices').addEventListener('click', () => openModal('modalInvoices'));

btnCloseHub.addEventListener('click', closeHub);

// Desconexión
document.getElementById('btnModalDisconnect').addEventListener('click', () => {
    postFetch('disconnect');
});

// Tecla ESC
window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' || e.keyCode === 27) {
        if (!hubWrapper.classList.contains('hidden')) {
            const openModals = document.querySelectorAll('.hub-modal-overlay:not(.hidden)');
            if (openModals.length > 0) {
                openModals.forEach(m => m.classList.add('hidden'));
            } else {
                closeHub();
            }
        }
    }
});

// Pestañas del Modal Negocio
document.querySelectorAll('.modal-tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        playTone('click');
        document.querySelectorAll('.modal-tab-btn').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.modal-tab-content').forEach(p => p.classList.remove('active'));

        btn.classList.add('active');
        const target = document.getElementById(`modaltab-${btn.dataset.modaltab}`);
        if (target) target.classList.add('active');

        if (btn.dataset.modaltab === 'biz-hr') {
            loadEmployees();
        }
    });
});

// Alternar Apertura / Cierre en Modal
document.getElementById('btnModalToggleBiz').addEventListener('click', async () => {
    const res = await postFetch('toggleBusinessState');
    if (res && res.success) {
        const beacon = document.getElementById('modalBizBeacon');
        const bizStateText = document.getElementById('modalBizStateText');
        const isOpen = (res.result === true);
        if (isOpen) {
            beacon.classList.add('open');
            bizStateText.textContent = "ABIERTO AL PÚBLICO";
            bizStateText.style.color = "#6ee7b7";
        } else {
            beacon.classList.remove('open');
            bizStateText.textContent = "CERRADO";
            bizStateText.style.color = "#fca5a5";
        }
        if (res.openBusinesses) {
            updateOpenBusinessesList(res.openBusinesses);
        }
        showToast(isOpen ? "Has ABIERTO el negocio al público." : "Has CERRADO el negocio.");
    } else {
        showToast(res ? res.result : "Error al alternar estado", true);
    }
});

// Contratar en Modal
document.getElementById('btnModalHire').addEventListener('click', async () => {
    const targetSrc = parseInt(document.getElementById('modalHireId').value);
    if (isNaN(targetSrc) || targetSrc <= 0) {
        showToast("Introduce un ID de jugador válido.", true);
        return;
    }

    const res = await postFetch('hireEmployee', { targetSrc });
    if (res && res.success) {
        showToast(res.message);
        document.getElementById('modalHireId').value = '';
        loadEmployees();
    } else {
        showToast(res ? res.message : "Error al contratar", true);
    }
});

// Transferencia Digital Corporativa en Modal
document.getElementById('btnModalSendWire').addEventListener('click', async () => {
    const targetIban = document.getElementById('modalWireIban').value.trim();
    const amount = parseFloat(document.getElementById('modalWireAmount').value);
    const reason = document.getElementById('modalWireReason').value.trim();

    if (!targetIban || targetIban.length < 4) {
        showToast("Introduce un IBAN de destino válido.", true);
        return;
    }

    if (isNaN(amount) || amount <= 0) {
        showToast("Introduce un importe válido.", true);
        return;
    }

    const res = await postFetch('corporateWireTransfer', {
        targetIban: targetIban,
        amount: amount,
        reason: reason || "Transferencia Corporativa Digital"
    });

    if (res && res.success) {
        showToast(res.message);
        document.getElementById('modalWireIban').value = '';
        document.getElementById('modalWireAmount').value = '';
        document.getElementById('modalWireReason').value = '';
        if (res.newBalance !== undefined) {
            document.getElementById('modalSocBalance').textContent = formatMoney(res.newBalance);
        }
    } else {
        showToast(res ? res.message : "Error al emitir transferencia corporativa", true);
    }
});
