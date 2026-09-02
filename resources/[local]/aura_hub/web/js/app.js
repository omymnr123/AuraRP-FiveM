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

function formatDateOfBirth(rawDob) {
    if (!rawDob) return "N/A";
    
    // Si es un número o string numérico (timestamp en ms o segundos)
    const num = Number(rawDob);
    if (!isNaN(num) && num > 10000000) {
        const ms = num < 10000000000 ? num * 1000 : num;
        const d = new Date(ms);
        if (!isNaN(d.getTime())) {
            const day = String(d.getDate()).padStart(2, '0');
            const month = String(d.getMonth() + 1).padStart(2, '0');
            const year = d.getFullYear();
            return `${day}/${month}/${year}`;
        }
    }

    // Si es string formato YYYY-MM-DD
    if (typeof rawDob === 'string' && rawDob.includes('-')) {
        const parts = rawDob.split('-');
        if (parts.length === 3) {
            return `${parts[2].padStart(2, '0')}/${parts[1].padStart(2, '0')}/${parts[0]}`;
        }
    }

    return String(rawDob);
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

    // Botón MDT Policial (Siempre visible si perteneces a la policía)
    const btnPoliceMdt = document.getElementById('btnActionPoliceMdt');
    if (data.job && (data.job.name === 'police' || data.job.name === 'sheriff')) {
        if (btnPoliceMdt) btnPoliceMdt.style.display = 'flex';
    } else {
        if (btnPoliceMdt) btnPoliceMdt.style.display = 'none';
    }

    // Actualizar Botón de Servicio (Duty)
    updateDutyUI(data.job);

    // Resetear modales ocultos
    document.querySelectorAll('.hub-modal-overlay').forEach(m => m.classList.add('hidden'));
    hubWrapper.classList.remove('hidden');
}

function updateDutyUI(jobData) {
    const btnDutyToggle = document.getElementById('btnActionDutyToggle');
    const dutyPulseDot = document.getElementById('dutyPulseDot');
    const dutyText = document.getElementById('dutyText');
    const dutyBadgeSub = document.getElementById('dutyBadgeSub');
    const mdtDutyStatusText = document.getElementById('mdtDutyStatusText');
    const mdtBadgeSub = document.getElementById('mdtBadgeSub');

    const canDuty = jobData && (jobData.canDuty === true || jobData.canDuty === 1);
    const isDuty = jobData && (jobData.duty === true || jobData.duty === 1);
    const badge = (jobData && (jobData.badge || jobData.callsign)) || (currentHubData && currentHubData.job && (currentHubData.job.badge || currentHubData.job.callsign));

    if (canDuty) {
        if (btnDutyToggle) {
            btnDutyToggle.style.display = 'flex';
            if (isDuty) {
                btnDutyToggle.classList.add('on-duty');
                if (dutyPulseDot) {
                    dutyPulseDot.style.background = '#00ff9d';
                    dutyPulseDot.style.boxShadow = '0 0 10px #00ff9d';
                }
                if (dutyText) {
                    dutyText.textContent = 'EN SERVICIO';
                    dutyText.style.color = '#00ff9d';
                }
            } else {
                btnDutyToggle.classList.remove('on-duty');
                if (dutyPulseDot) {
                    dutyPulseDot.style.background = '#ff4d6d';
                    dutyPulseDot.style.boxShadow = '0 0 10px #ff4d6d';
                }
                if (dutyText) {
                    dutyText.textContent = 'FUERA DE SERVICIO';
                    dutyText.style.color = '#ff4d6d';
                }
            }

            if (dutyBadgeSub) {
                if (badge && jobData && jobData.name === 'police') {
                    dutyBadgeSub.textContent = `Placa: #${badge}`;
                    dutyBadgeSub.style.display = 'block';
                } else {
                    dutyBadgeSub.style.display = 'none';
                }
            }
        }
    } else {
        if (btnDutyToggle) btnDutyToggle.style.display = 'none';
    }

    if (mdtDutyStatusText) {
        if (isDuty) {
            mdtDutyStatusText.style.color = '#00ff9d';
            mdtDutyStatusText.innerHTML = `<span class="pulse-dot" id="mdtDutyDot" style="background:#00ff9d; box-shadow:0 0 8px #00ff9d; width:7px; height:7px;"></span> EN SERVICIO`;
        } else {
            mdtDutyStatusText.style.color = '#ff4d6d';
            mdtDutyStatusText.innerHTML = `<span class="pulse-dot" id="mdtDutyDot" style="background:#ff4d6d; box-shadow:0 0 8px #ff4d6d; width:7px; height:7px;"></span> FUERA DE SERVICIO`;
        }
    }

    if (mdtBadgeSub) {
        if (badge && jobData && jobData.name === 'police') {
            mdtBadgeSub.textContent = `Placa: #${badge}`;
            mdtBadgeSub.style.display = 'block';
        } else {
            mdtBadgeSub.style.display = 'none';
        }
    }
}

window.togglePlayerDuty = async () => {
    playTone('click');
    const res = await postFetch('toggleDuty');
    if (res && res.success) {
        const newDuty = res.newDuty === true;
        if (currentHubData && currentHubData.job) {
            currentHubData.job.duty = newDuty;
            updateDutyUI(currentHubData.job);
        }
    } else {
        showToast("Error al alternar servicio.", true);
    }
};

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
    } else if (payload.action === 'showDutyAnnouncement') {
        triggerDutyAnnouncement(payload.data);
    }
});

// ============================================================================
// BANNER GLOBAL ANIMADO
// ============================================================================
function triggerGlobalAnnouncement(data) {
    if (announcementTimeout) {
        clearTimeout(announcementTimeout);
    }

    const metaTag = document.querySelector('.banner-tag');
    if (metaTag) metaTag.textContent = "AVISO DE LA CIUDAD";

    bannerCard.classList.remove('duty-active');
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

function triggerDutyAnnouncement(data) {
    if (announcementTimeout) {
        clearTimeout(announcementTimeout);
    }

    const isDuty = data.isDuty === true;
    bannerTitle.textContent = data.label || "Servicio Oficial";
    
    const metaTag = document.querySelector('.banner-tag');
    if (metaTag) metaTag.textContent = "REGISTRO DE SERVICIO";

    if (isDuty) {
        bannerCard.classList.remove('closed');
        bannerCard.classList.add('duty-active');
        bannerIcon.className = data.isPolice ? 'fa-solid fa-shield-halved' : 'fa-solid fa-user-check';
        bannerSubtitle.textContent = "Has ENTRADO en servicio activo. Terminal y armamento autorizados.";
        bannerBadgeText.textContent = "EN SERVICIO";
    } else {
        bannerCard.classList.add('closed');
        bannerCard.classList.remove('duty-active');
        bannerIcon.className = data.isPolice ? 'fa-solid fa-shield' : 'fa-solid fa-user-clock';
        bannerSubtitle.textContent = "Has SALIDO de servicio. Estado fuera de servicio registrado.";
        bannerBadgeText.textContent = "FUERA DE SERVICIO";
    }

    playTone('announcement');
    globalBanner.classList.remove('hidden');
    globalBanner.classList.add('show');

    announcementTimeout = setTimeout(() => {
        globalBanner.classList.remove('show');
        setTimeout(() => {
            globalBanner.classList.add('hidden');
            if (metaTag) metaTag.textContent = "AVISO DE LA CIUDAD";
        }, 450);
    }, data.duration || 6500);
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

// ============================================================================
// MDT POLICIAL LSPD (CONTROLADORES, BÚSQUEDAS, MULTAS Y CÁRCEL EN AURA HUB)
// ============================================================================

let mdtOverviewData = null;

// Apertura del MDT desde el Botón de Cabecera o Pill de Policía
document.getElementById('btnActionPoliceMdt')?.addEventListener('click', () => {
    openModal('modalPoliceMdt');
    switchMdtTab('mdttab-citizens');
    loadPoliceMdtOverview();
});

document.querySelector('.counter-pill.police')?.addEventListener('click', () => {
    if (currentHubData && currentHubData.job && (currentHubData.job.name === 'police' || currentHubData.job.name === 'sheriff')) {
        openModal('modalPoliceMdt');
        switchMdtTab('mdttab-citizens');
        loadPoliceMdtOverview();
    }
});

// Cambio de Pestañas en el MDT
window.switchMdtTab = (tabId) => {
    playTone('click');
    document.querySelectorAll('.mdt-tab-btn').forEach(b => b.classList.remove('active'));
    document.querySelectorAll('.mdt-tab-pane').forEach(p => p.classList.remove('active'));

    const tabBtn = document.querySelector(`.mdt-tab-btn[onclick*="${tabId}"]`);
    if (tabBtn) tabBtn.classList.add('active');

    const pane = document.getElementById(tabId);
    if (pane) pane.classList.add('active');

    if (tabId === 'mdttab-jail') {
        loadMdtInmates();
    } else if (tabId === 'mdttab-warrants') {
        loadMdtWarrants();
    } else if (tabId === 'mdttab-roster') {
        loadMdtRoster();
    } else if (tabId === 'mdttab-dispatch') {
        loadMdtDispatchCalls();
    } else if (tabId === 'mdttab-staff') {
        loadMdtStaff();
    }
};

// Carga General de Estadísticas del MDT
async function loadPoliceMdtOverview() {
    const res = await postFetch('getPoliceMdtOverview');
    if (!res || !res.success || !res.data) return;

    mdtOverviewData = res.data;

    // Actualizar Saldo Policial
    const socBalElem = document.getElementById('mdtSocBalance');
    if (socBalElem) socBalElem.textContent = formatMoney(res.data.societyBalance || 0);

    // Contadores de Oficiales
    const offCountElem = document.getElementById('mdtActiveOfficersCount');
    if (offCountElem) offCountElem.textContent = `${res.data.officers ? res.data.officers.length : 0} Oficiales Activos`;

    // Renderizar Códigos Predefinidos de Multas
    renderFinePresets(res.data.presets || []);
}

// Renderizado de Códigos Predefinidos de Multas
function renderFinePresets(presets) {
    const container = document.getElementById('mdtFinePresetsContainer');
    if (!container) return;
    container.innerHTML = '';

    if (!presets || presets.length === 0) {
        // Fallback si la lista viene vacía
        presets = [
            { category: 'Tráfico', code: 'TR-01', label: 'Exceso de velocidad leve', amount: 250 },
            { category: 'Tráfico', code: 'TR-02', label: 'Exceso de velocidad grave', amount: 600 },
            { category: 'Tráfico', code: 'TR-03', label: 'Conducción temeraria', amount: 1200 },
            { category: 'Orden Público', code: 'OP-01', label: 'Desacato a la autoridad', amount: 800 },
            { category: 'Delitos Graves', code: 'DG-01', label: 'Posesión de arma ilegal', amount: 3500 },
            { category: 'Delitos Graves', code: 'DG-02', label: 'Robo a mano armada', amount: 5000 }
        ];
    }

    presets.forEach(p => {
        const div = document.createElement('div');
        div.className = 'fine-preset-item';
        div.innerHTML = `
            <div class="fine-preset-info">
                <span class="fine-preset-code">[${p.code}] ${p.category}</span>
                <span class="fine-preset-label">${p.label}</span>
            </div>
            <span class="fine-preset-amount">${formatMoney(p.amount)}</span>
        `;
        div.addEventListener('click', () => {
            playTone('click');
            document.getElementById('inputMdtFineAmount').value = p.amount;
            document.getElementById('inputMdtFineReason').value = `[${p.code}] ${p.label}`;
            showToast(`Código ${p.code} seleccionado.`);
        });
        container.appendChild(div);
    });
}

// 1. BÚSQUEDA DE CIUDADANOS
document.getElementById('btnMdtSearchCitizen')?.addEventListener('click', searchMdtCitizen);
document.getElementById('inputMdtCitizenSearch')?.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') searchMdtCitizen();
});

async function searchMdtCitizen() {
    const query = document.getElementById('inputMdtCitizenSearch').value.trim();
    if (!query || query.length < 2) {
        showToast("Introduce al menos 2 caracteres para buscar.", true);
        return;
    }

    playTone('click');
    const container = document.getElementById('mdtCitizenResults');
    container.innerHTML = `<div class="mdt-empty-state"><i class="fa-solid fa-spinner fa-spin"></i><p>Consultando base de datos central de Los Santos...</p></div>`;

    const res = await postFetch('policeSearchCitizen', { query });
    if (!res || !res.success || !res.results || res.results.length === 0) {
        container.innerHTML = `<div class="mdt-empty-state"><i class="fa-solid fa-user-slash"></i><p>No se encontraron registros de ciudadanos para "${query}".</p></div>`;
        return;
    }

    container.innerHTML = '';
    res.results.forEach(c => {
        const card = document.createElement('div');
        card.className = `mdt-citizen-card ${c.hasWarrant ? 'has-warrant' : ''}`;

        const weaponLic = c.licenses && c.licenses.weapon ? `<span class="license-pill valid">VIGENTE</span>` : `<span class="license-pill invalid">DENEGADA</span>`;
        const driverLic = c.licenses && c.licenses.driver ? `<span class="license-pill valid">VIGENTE</span>` : `<span class="license-pill invalid">RETIRADA</span>`;
        const platesList = c.plates && c.plates.length > 0 ? c.plates.join(', ') : 'Ninguno';

        let finesHtml = '<p style="color:var(--text-muted); font-size:11px;">Sin sanciones recientes.</p>';
        if (c.fines && c.fines.length > 0) {
            finesHtml = c.fines.map(f => `<div style="font-size:11px; margin-bottom:4px;"><strong style="color:#00ff9d;">$${f.amount}</strong> - ${f.reason} <small style="color:var(--text-dim);">(${f.officer_name})</small></div>`).join('');
        }

        let jailHtml = '<p style="color:var(--text-muted); font-size:11px;">Sin antecedentes de prisión.</p>';
        if (c.jailRecords && c.jailRecords.length > 0) {
            jailHtml = c.jailRecords.map(j => `<div style="font-size:11px; margin-bottom:4px;"><strong style="color:#ff4d6d;">${j.jail_time} min</strong> - ${j.reason} <small style="color:var(--text-dim);">(${j.status})</small></div>`).join('');
        }

        card.innerHTML = `
            <div class="mdt-citizen-top">
                <div class="mdt-citizen-identity">
                    <div class="mdt-citizen-avatar"><i class="fa-solid fa-user-shield"></i></div>
                    <div>
                        <h3>${c.name}</h3>
                        <span class="cid-tag">CITIZENID: ${c.citizenid}</span>
                    </div>
                </div>
                ${c.hasWarrant ? `<div class="warrant-badge-warning"><i class="fa-solid fa-triangle-exclamation"></i> ORDEN DE CAPTURA ACTIVA</div>` : ''}
            </div>
            <div class="mdt-citizen-info-grid">
                <div class="mdt-info-box"><span>FECHA NACIMIENTO</span><strong>${formatDateOfBirth(c.dob)}</strong></div>
                <div class="mdt-info-box"><span>GÉNERO</span><strong>${c.gender}</strong></div>
                <div class="mdt-info-box"><span>TELÉFONO</span><strong>${c.phone}</strong></div>
                <div class="mdt-info-box"><span>CUENTA IBAN</span><strong>${c.iban}</strong></div>
                <div class="mdt-info-box"><span>LICENCIA ARMAS</span>${weaponLic}</div>
                <div class="mdt-info-box"><span>LICENCIA CONDUCIR</span>${driverLic}</div>
                <div class="mdt-info-box" style="grid-column: span 2;"><span>VEHÍCULOS REGISTRADOS</span><strong>${platesList}</strong></div>
            </div>
            <div style="display:grid; grid-template-columns:1fr 1fr; gap:12px; background:rgba(0,0,0,0.25); padding:10px; border-radius:8px;">
                <div><span style="font-size:10px; font-weight:800; color:#00f2fe;">HISTORIAL DE MULTAS</span><div style="margin-top:6px;">${finesHtml}</div></div>
                <div><span style="font-size:10px; font-weight:800; color:#ff4d6d;">HISTORIAL PENITENCIARIO</span><div style="margin-top:6px;">${jailHtml}</div></div>
            </div>
            <div class="mdt-citizen-bottom-actions">
                <button class="btn-mdt-action cyan small" onclick="quickFillFine('${c.citizenid}')"><i class="fa-solid fa-receipt"></i> Sancionar</button>
                <button class="btn-mdt-action red small" onclick="quickFillJail('${c.citizenid}')"><i class="fa-solid fa-lock"></i> Encarcelar</button>
                <button class="btn-mdt-action red small" onclick="quickFillWarrant('${c.citizenid}', '${c.name}')"><i class="fa-solid fa-bullhorn"></i> Orden de Búsqueda</button>
            </div>
        `;
        container.appendChild(card);
    });
}

// 2. BÚSQUEDA DE VEHÍCULOS
document.getElementById('btnMdtSearchVehicle')?.addEventListener('click', searchMdtVehicle);
document.getElementById('inputMdtVehicleSearch')?.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') searchMdtVehicle();
});

async function searchMdtVehicle() {
    const plate = document.getElementById('inputMdtVehicleSearch').value.trim();
    if (!plate || plate.length < 2) {
        showToast("Introduce una matrícula válida.", true);
        return;
    }

    playTone('click');
    const container = document.getElementById('mdtVehicleResults');
    container.innerHTML = `<div class="mdt-empty-state"><i class="fa-solid fa-spinner fa-spin"></i><p>Consultando registro de la DGT...</p></div>`;

    const res = await postFetch('policeSearchVehicle', { plate });
    if (!res || !res.success || !res.result) {
        container.innerHTML = `<div class="mdt-empty-state"><i class="fa-solid fa-car-burst"></i><p>No existe ningún vehículo registrado con la matrícula "${plate}".</p></div>`;
        return;
    }

    const v = res.result;
    container.innerHTML = `
        <div class="mdt-vehicle-card ${v.isBolo ? 'is-bolo' : ''}">
            <div class="mdt-citizen-top">
                <div class="mdt-citizen-identity">
                    <div class="mdt-citizen-avatar"><i class="fa-solid fa-car"></i></div>
                    <div>
                        <h3>MATRÍCULA: ${v.plate}</h3>
                        <span class="cid-tag">PROPIETARIO: ${v.owner} (${v.ownerCitizenId})</span>
                    </div>
                </div>
                ${v.isBolo ? `<div class="warrant-badge-warning"><i class="fa-solid fa-triangle-exclamation"></i> VEHÍCULO EN BÚSQUEDA (BOLO)</div>` : `<span class="license-pill valid">SITUACIÓN REGULAR</span>`}
            </div>
            <div class="mdt-citizen-info-grid">
                <div class="mdt-info-box"><span>TELÉFONO TITULAR</span><strong>${v.phone}</strong></div>
                <div class="mdt-info-box"><span>ESTADO BOLO</span><strong>${v.isBolo ? 'EN BÚSQUEDA Y CAPTURA' : 'SIN INCIDENCIAS'}</strong></div>
                <div class="mdt-info-box" style="grid-column: span 2;"><span>MOTIVO BOLO</span><strong>${v.boloReason || 'N/A'}</strong></div>
            </div>
            <div class="mdt-citizen-bottom-actions">
                <button class="btn-mdt-action ${v.isBolo ? 'cyan' : 'red'} small" onclick="toggleVehicleBolo('${v.plate}')">
                    <i class="fa-solid fa-arrows-rotate"></i> ${v.isBolo ? 'Cancelar / Resolver BOLO' : 'Marcar en Búsqueda (BOLO)'}
                </button>
            </div>
        </div>
    `;
}

window.toggleVehicleBolo = async (plate) => {
    const res = await postFetch('policeToggleVehicleBolo', { plate, reason: "BOLO Emitido por sospecha o robo vehicular" });
    if (res && res.success) {
        showToast(res.message);
        searchMdtVehicle();
    } else {
        showToast(res ? res.message : "Error al actualizar BOLO", true);
    }
};

// 3. EMISIÓN DE SANCIONES
document.getElementById('btnMdtSubmitFine')?.addEventListener('click', async () => {
    const target = document.getElementById('inputMdtFineTarget').value.trim();
    const amount = parseFloat(document.getElementById('inputMdtFineAmount').value);
    const reason = document.getElementById('inputMdtFineReason').value.trim();

    if (!target) {
        showToast("Introduce el ID de servidor o CitizenID del infractor.", true);
        return;
    }
    if (isNaN(amount) || amount <= 0) {
        showToast("Introduce un importe válido.", true);
        return;
    }
    if (!reason) {
        showToast("Introduce el motivo o código de infracción.", true);
        return;
    }

    playTone('click');
    const isNumericId = !isNaN(parseInt(target)) && target.length <= 4;
    const payload = {
        amount: amount,
        reason: reason,
        targetServerId: isNumericId ? parseInt(target) : null,
        citizenid: !isNumericId ? target : null
    };

    const res = await postFetch('policeIssueFine', payload);
    if (res && res.success) {
        showToast(res.message);
        document.getElementById('inputMdtFineTarget').value = '';
        document.getElementById('inputMdtFineAmount').value = '';
        document.getElementById('inputMdtFineReason').value = '';
        loadPoliceMdtOverview();
    } else {
        showToast(res ? res.message : "Error al procesar sanción", true);
    }
});

// 4. ENCARCELAMIENTO Y TRASLADO PENITENCIARIO
document.getElementById('btnMdtSubmitJail')?.addEventListener('click', async () => {
    const target = document.getElementById('inputMdtJailTarget').value.trim();
    const minutes = parseInt(document.getElementById('inputMdtJailMinutes').value);
    const reason = document.getElementById('inputMdtJailReason').value.trim();

    if (!target) {
        showToast("Introduce el ID de servidor del sospechoso.", true);
        return;
    }
    if (isNaN(minutes) || minutes < 1 || minutes > 120) {
        showToast("La condena debe ser entre 1 y 120 minutos.", true);
        return;
    }
    if (!reason) {
        showToast("Introduce los cargos y delitos imputados.", true);
        return;
    }

    playTone('click');
    const isNumericId = !isNaN(parseInt(target)) && target.length <= 4;
    const payload = {
        targetServerId: isNumericId ? parseInt(target) : null,
        citizenid: !isNumericId ? target : null,
        minutes: minutes,
        reason: reason
    };

    const res = await postFetch('policeJailSuspect', payload);
    if (res && res.success) {
        showToast(res.message);
        document.getElementById('inputMdtJailTarget').value = '';
        document.getElementById('inputMdtJailMinutes').value = '';
        document.getElementById('inputMdtJailReason').value = '';
        loadMdtInmates();
    } else {
        showToast(res ? res.message : "Error al procesar ingreso penitenciario", true);
    }
});

async function loadMdtInmates() {
    const res = await postFetch('policeGetActiveInmates');
    const tableBody = document.getElementById('mdtInmatesTableBody');
    if (!tableBody) return;
    tableBody.innerHTML = '';

    if (!res || !res.success || !res.inmates || res.inmates.length === 0) {
        tableBody.innerHTML = `<tr><td colspan="4" style="text-align:center; padding:20px; color:var(--text-dim);">No hay reclusos activos en Bolingbroke.</td></tr>`;
        return;
    }

    res.inmates.forEach(inmate => {
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td><strong>${inmate.citizenid}</strong></td>
            <td><span style="color:#ff4d6d; font-weight:800;"><i class="fa-solid fa-clock"></i> ${inmate.jail_time} min</span></td>
            <td>${inmate.reason}</td>
            <td><small style="color:var(--text-dim);">${inmate.officer_name}</small></td>
        `;
        tableBody.appendChild(tr);
    });
}

// 5. ÓRDENES DE BÚSQUEDA Y CAPTURA (WARRANTS)
document.getElementById('btnMdtCreateWarrant')?.addEventListener('click', async () => {
    const cid = document.getElementById('inputMdtWarrantCid').value.trim();
    const name = document.getElementById('inputMdtWarrantName').value.trim();
    const severity = document.getElementById('selectMdtWarrantSeverity').value;
    const reason = document.getElementById('inputMdtWarrantReason').value.trim();

    if (!cid || !name || !reason) {
        showToast("Completa todos los campos de la orden.", true);
        return;
    }

    playTone('click');
    const res = await postFetch('policeCreateWarrant', { citizenid: cid, suspectName: name, severity, reason });
    if (res && res.success) {
        showToast(res.message);
        document.getElementById('inputMdtWarrantCid').value = '';
        document.getElementById('inputMdtWarrantName').value = '';
        document.getElementById('inputMdtWarrantReason').value = '';
        loadMdtWarrants();
    } else {
        showToast(res ? res.message : "Error al registrar orden", true);
    }
});

async function loadMdtWarrants() {
    const res = await postFetch('policeGetWarrants');
    const container = document.getElementById('mdtWarrantsContainer');
    if (!container) return;
    container.innerHTML = '';

    if (!res || !res.success || !res.warrants || res.warrants.length === 0) {
        container.innerHTML = `<div class="mdt-empty-state"><i class="fa-solid fa-shield-check"></i><p>No hay órdenes de búsqueda activas en la ciudad.</p></div>`;
        return;
    }

    res.warrants.forEach(w => {
        if (w.status !== 'active') return;
        const div = document.createElement('div');
        div.className = 'warrant-item-card';
        div.innerHTML = `
            <div class="warrant-item-info">
                <h5>${w.suspect_name} <small style="color:#00f2fe;">(${w.citizenid})</small> <span class="severity-pill ${w.severity}">${w.severity}</span></h5>
                <p><strong>Motivo:</strong> ${w.reason} <span style="color:var(--text-dim);">| Emisor: ${w.officer_name}</span></p>
            </div>
            <button class="btn-mdt-action cyan small" onclick="deleteWarrant(${w.id})"><i class="fa-solid fa-check"></i> Resolver</button>
        `;
        container.appendChild(div);
    });
}

window.deleteWarrant = async (warrantId) => {
    playTone('click');
    const res = await postFetch('policeDeleteWarrant', { warrantId });
    if (res && res.success) {
        showToast(res.message);
        loadMdtWarrants();
    } else {
        showToast(res ? res.message : "Error al archivar orden", true);
    }
};

// 6. ROSTER DE UNIDADES EN SERVICIO
async function loadMdtRoster() {
    const container = document.getElementById('mdtRosterGrid');
    if (!container) return;

    if (!mdtOverviewData) {
        await loadPoliceMdtOverview();
    }

    container.innerHTML = '';

    // Filtrar explícitamente solo oficiales con duty == true
    const activeOfficers = (mdtOverviewData && mdtOverviewData.officers) 
        ? mdtOverviewData.officers.filter(off => off.duty === true || off.duty === 1)
        : [];

    if (activeOfficers.length === 0) {
        container.innerHTML = `<div class="mdt-empty-state" style="grid-column: span 3;"><i class="fa-solid fa-user-slash"></i><p>No hay unidades en servicio actualmente.</p></div>`;
        return;
    }

    activeOfficers.forEach(off => {
        const div = document.createElement('div');
        div.className = 'officer-roster-card';
        div.innerHTML = `
            <div class="officer-avatar"><i class="fa-solid fa-shield"></i></div>
            <div class="officer-roster-details">
                <h5>${off.name} <small style="color:var(--text-dim);">(ID: ${off.src})</small></h5>
                <div style="display:flex; align-items:center; gap:6px; margin-top:2px;">
                    <span>${off.gradeLabel} (Grado ${off.grade})</span>
                    <span class="badge-pill" style="background:rgba(0,255,255,0.12); color:#00ffff; border:1px solid rgba(0,255,255,0.3); padding:1px 6px; border-radius:4px; font-size:9.5px; font-weight:700;"><i class="fa-solid fa-id-badge"></i> Placa #${off.badge || '---'}</span>
                </div>
                <p style="font-size:10px; color:var(--text-muted); margin-top:2px;"><i class="fa-solid fa-phone"></i> ${off.phoneNumber}</p>
            </div>
            <div class="officer-status-tag active" style="margin-left:auto; display:flex; align-items:center; gap:6px; font-size:10px; font-weight:800; color:#00ff9d; background:rgba(0,255,157,0.12); padding:4px 8px; border-radius:6px; border:1px solid rgba(0,255,157,0.3);">
                <span class="pulse-dot" style="background:#00ff9d; box-shadow:0 0 6px #00ff9d; width:6px; height:6px; border-radius:50%;"></span>
                <span>EN SERVICIO</span>
            </div>
        `;
        container.appendChild(div);
    });
}

// 7. DESPACHO 911 EN VIVO Y WAYPOINT GPS
window.loadMdtDispatchCalls = async () => {
    playTone('click');
    const container = document.getElementById('mdtDispatchFeed');
    if (!container) return;
    container.innerHTML = `<div class="mdt-empty-state"><i class="fa-solid fa-spinner fa-spin"></i><p>Sincronizando feed de emergencias...</p></div>`;

    const res = await postFetch('policeGetDispatchHistory');
    if (!res || !res.calls || res.calls.length === 0) {
        container.innerHTML = `<div class="mdt-empty-state"><i class="fa-solid fa-tower-broadcast"></i><p>No hay avisos de emergencia recientes en la central.</p></div>`;
        return;
    }

    container.innerHTML = '';
    res.calls.forEach(call => {
        const div = document.createElement('div');
        div.className = 'dispatch-call-card';
        div.innerHTML = `
            <div style="display:flex; align-items:center;">
                <span class="dispatch-code-pill">${call.code}</span>
                <div>
                    <h5 style="color:#ffffff; font-size:13px; font-weight:800;">${call.title} <small style="color:var(--text-dim);">${call.time}</small></h5>
                    <p style="color:var(--text-muted); font-size:11px;">${call.description}</p>
                </div>
            </div>
            <button class="btn-mdt-action cyan small" onclick="setCallWaypoint(${call.coords.x}, ${call.coords.y})">
                <i class="fa-solid fa-location-crosshairs"></i> Fijar GPS
            </button>
        `;
        container.appendChild(div);
    });
};

window.setCallWaypoint = (x, y) => {
    playTone('click');
    postFetch('setGpsWaypoint', { x, y });
};

// Acciones Rápidas desde Ficha Ciudadana
window.quickFillFine = (citizenid) => {
    switchMdtTab('mdttab-fines');
    document.getElementById('inputMdtFineTarget').value = citizenid;
};

window.quickFillJail = (citizenid) => {
    switchMdtTab('mdttab-jail');
    document.getElementById('inputMdtJailTarget').value = citizenid;
};

window.quickFillWarrant = (citizenid, name) => {
    switchMdtTab('mdttab-warrants');
    document.getElementById('inputMdtWarrantCid').value = citizenid;
    document.getElementById('inputMdtWarrantName').value = name;
};

// ============================================================================
// 8. RRHH & GESTIÓN DE PLANTILLA POLICIAL (CONTRATAR, ASCENDER, DEGRADAR, EXPULSAR)
// ============================================================================

async function loadMdtStaff() {
    const tableBody = document.getElementById('mdtStaffTableBody');
    if (!tableBody) return;
    tableBody.innerHTML = `<tr><td colspan="5" style="text-align:center; padding:20px; color:var(--text-dim);"><i class="fa-solid fa-spinner fa-spin"></i> Cargando plantilla del LSPD...</td></tr>`;

    const res = await postFetch('policeGetStaff');
    if (!res || !res.success || !res.data) {
        tableBody.innerHTML = `<tr><td colspan="5" style="text-align:center; padding:20px; color:#ff4d6d;">Error al cargar la plantilla policial. Se requiere rango de Alto Mando.</td></tr>`;
        return;
    }

    const { staff, isHighCommand, callerGrade } = res.data;
    tableBody.innerHTML = '';

    if (!staff || staff.length === 0) {
        tableBody.innerHTML = `<tr><td colspan="5" style="text-align:center; padding:20px; color:var(--text-dim);">No hay oficiales registrados en el cuerpo policial.</td></tr>`;
        return;
    }

    staff.forEach(off => {
        const tr = document.createElement('tr');
        const onlineText = off.isOnline 
            ? `<span style="color:#00ff9d; font-weight:700;"><i class="fa-solid fa-circle-dot"></i> Online (ID: ${off.src})</span>` 
            : `<span style="color:#64748b;"><i class="fa-solid fa-circle"></i> Desconectado</span>`;

        let actionsHtml = '';
        if (isHighCommand) {
            const canPromote = (callerGrade >= 6 || off.grade < callerGrade - 1) && off.grade < 6;
            const canDemote = (callerGrade >= 6 || off.grade < callerGrade) && off.grade > 0;
            const canFire = (callerGrade >= 6 || off.grade < callerGrade);

            actionsHtml = `
                <button class="btn-emp-action" title="Ascender (+1 Rango)" onclick="changePoliceGrade(${off.charId}, ${off.grade + 1})" ${!canPromote ? 'disabled style="opacity:0.3; cursor:not-allowed;"' : ''}>
                    <i class="fa-solid fa-arrow-up"></i>
                </button>
                <button class="btn-emp-action" title="Degradar (-1 Rango)" onclick="changePoliceGrade(${off.charId}, ${off.grade - 1})" ${!canDemote ? 'disabled style="opacity:0.3; cursor:not-allowed;"' : ''}>
                    <i class="fa-solid fa-arrow-down"></i>
                </button>
                <button class="btn-emp-action fire" title="Expulsar del Departamento" onclick="firePoliceOfficer(${off.charId})" ${!canFire ? 'disabled style="opacity:0.3; cursor:not-allowed;"' : ''}>
                    <i class="fa-solid fa-user-xmark"></i>
                </button>
            `;
        } else {
            actionsHtml = `<span style="color:var(--text-dim); font-size:11px;">Solo Lectura</span>`;
        }

        tr.innerHTML = `
            <td>${onlineText}</td>
            <td><strong>${off.name}</strong> <small style="color:var(--text-dim);">(${off.citizenid})</small></td>
            <td><span style="color:#00f2fe; font-weight:800;">${off.gradeLabel}</span> <small style="color:var(--text-muted);">(Grado ${off.grade})</small></td>
            <td style="font-family:var(--font-mono); color:#ffffff;">${formatMoney(off.salary)}</td>
            <td style="text-align: right;">${actionsHtml}</td>
        `;
        tableBody.appendChild(tr);
    });
}

// Contratación de Cadetes
document.getElementById('btnMdtHirePolice')?.addEventListener('click', async () => {
    const input = document.getElementById('inputMdtHirePoliceId');
    const targetSrc = parseInt(input.value);

    if (isNaN(targetSrc) || targetSrc <= 0) {
        showToast("Introduce un ID de servidor válido.", true);
        return;
    }

    playTone('click');
    const res = await postFetch('policeHireOfficer', { targetSrc });
    if (res && res.success) {
        showToast(res.message);
        input.value = '';
        loadMdtStaff();
    } else {
        showToast(res ? res.message : "Error al contratar oficial", true);
    }
});

// Modificar Rango de un Oficial (Ascender / Degradar)
window.changePoliceGrade = async (targetCharId, newGrade) => {
    if (newGrade < 0) {
        showToast("El oficial ya tiene el rango mínimo (Cadete).", true);
        return;
    }
    if (newGrade > 6) {
        showToast("El oficial ya tiene el rango máximo (Jefe de Policía).", true);
        return;
    }

    playTone('click');
    const res = await postFetch('policeSetOfficerGrade', { targetCharId, newGrade });
    if (res && res.success) {
        showToast(res.message);
        loadMdtStaff();
    } else {
        showToast(res ? res.message : "Error al modificar rango", true);
    }
};

// Expulsar a un Oficial
window.firePoliceOfficer = async (targetCharId) => {
    playTone('click');
    const res = await postFetch('policeFireOfficer', { targetCharId });
    if (res && res.success) {
        showToast(res.message);
        loadMdtStaff();
    } else {
        showToast(res ? res.message : "Error al expulsar oficial", true);
    }
};
