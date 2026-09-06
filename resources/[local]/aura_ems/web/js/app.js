// ============================================================================
// AURA EMS: NUI APPLICATION CONTROLLER
// Dispatch Alerts, Active Calls Board, Tactical Radio (20 Channels) & Clinical MDT Suite
// ============================================================================

// --- UTILIDAD DE TOAST NOTIFICATIONS ---
function showToast(message, isError = false) {
    const container = document.getElementById("toastContainer");
    if (!container) return;

    const toast = document.createElement("div");
    toast.className = `toast ${isError ? 'error' : ''}`;
    toast.innerHTML = `
        <i class="fa-solid ${isError ? 'fa-triangle-exclamation' : 'fa-circle-check'}"></i>
        <span>${message}</span>
    `;

    container.appendChild(toast);

    requestAnimationFrame(() => {
        toast.classList.add("visible");
    });

    setTimeout(() => {
        toast.classList.remove("visible");
        setTimeout(() => toast.remove(), 300);
    }, 3500);
}

// --- UTILIDAD DE POST FETCH ---
async function postFetch(endpoint, data = {}) {
    try {
        const response = await fetch(`https://${GetParentResourceName()}/${endpoint}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data)
        });
        return await response.json();
    } catch (e) {
        return { success: false, error: e };
    }
}

// --- PALETA DE COLORES TÁCTICOS Y BLIPS GPS ---
const RADIO_COLOR_PALETTE = [
    { hex: '#ff007f', blip: 48, name: 'Rosa Neón (Aura)' },
    { hex: '#40E0D0', blip: 38, name: 'Turquesa Médico' },
    { hex: '#00ff9d', blip: 2,  name: 'Verde Emergencia' },
    { hex: '#3b82f6', blip: 3,  name: 'Azul Soporte' },
    { hex: '#ffb700', blip: 46, name: 'Oro Mando EMS' },
    { hex: '#ff2a55', blip: 1,  name: 'Rojo Crítico / UCI' },
    { hex: '#ff6b35', blip: 47, name: 'Naranja Rescate' },
    { hex: '#9d4edd', blip: 27, name: 'Púrpura Cirugía' },
    { hex: '#ffffff', blip: 0,  name: 'Blanco Hospital' },
    { hex: '#ffff00', blip: 5,  name: 'Amarillo Triage' },
    { hex: '#06d6a0', blip: 25, name: 'Verde Menta' },
    { hex: '#8338ec', blip: 7,  name: 'Violeta Intensivo' },
    { hex: '#ff477e', blip: 8,  name: 'Magenta Táctico' },
    { hex: '#3a86ff', blip: 18, name: 'Azul Eléctrico' },
    { hex: '#fb5607', blip: 17, name: 'Coral Trauma' },
    { hex: '#70e000', blip: 43, name: 'Lima Ambulancia' },
    { hex: '#0077b6', blip: 29, name: 'Azul Marino' },
    { hex: '#e0aaff', blip: 19, name: 'Lavanda Helitransporte' },
    { hex: '#b5179e', blip: 21, name: 'Fucsia Forense' },
    { hex: '#a0aec0', blip: 40, name: 'Gris Nocturno' },
    { hex: '#4cc9f0', blip: 68, name: 'Celeste Hielo' }
];

let activePickerChannelIndex = null;

// ============================================================================
// 1. DISPATCH HUD (SMART DISPATCH BANNER - SIMÉTRICO A POLICE)
// ============================================================================

class DispatchHUD {
    constructor() {
        this.container = document.getElementById("dispatchContainer");
        this.init();
    }

    init() {
        window.addEventListener("message", (event) => {
            const data = event.data;
            if (data.action === "dispatchAlert" && data.alert) {
                this.showAlert(data.alert);
            }
        });
    }

    showAlert(alert) {
        if (!this.container) return;

        const card = document.createElement("div");
        card.className = "dispatch-alert-card";

        card.innerHTML = `
            <div class="dispatch-glow-strip"></div>
            <div class="dispatch-card-inner">
                <div class="dispatch-icon-badge">
                    <i class="fa-solid fa-truck-medical"></i>
                </div>
                <div class="dispatch-content">
                    <div class="dispatch-meta-row">
                        <span class="dispatch-code">${alert.code || '10-33'}</span>
                        <span class="dispatch-time"><i class="fa-regular fa-clock"></i> ${alert.time || 'AHORA'}</span>
                    </div>
                    <div class="dispatch-title-row">
                        <span class="dispatch-title">${alert.title || 'Emergencia Médica'}</span>
                    </div>
                    <div class="dispatch-location-row">
                        <i class="fa-solid fa-location-dot"></i>
                        <span>${alert.street || 'Vía Pública'} <strong class="zone-highlight">(${alert.zone || 'Distrito'})</strong></span>
                    </div>
                    <div class="dispatch-footer-tip">
                        <div class="dispatch-pill-btn">
                            <kbd>G</kbd> <span>ACUDIR / GPS (${alert.distance || 0}m)</span>
                        </div>
                        <div class="dispatch-pill-btn alt">
                            <kbd>U</kbd> <span>CENTRAL MÉDICA</span>
                        </div>
                    </div>
                </div>
            </div>
            <div class="dispatch-progress-bar">
                <div class="dispatch-progress-fill"></div>
            </div>
        `;

        this.container.prepend(card);

        requestAnimationFrame(() => {
            card.classList.add("visible");
        });

        setTimeout(() => {
            card.classList.remove("visible");
            card.classList.add("removing");
            setTimeout(() => {
                card.remove();
            }, 400);
        }, 8500);
    }
}

// ============================================================================
// 2. CENTRAL DE AVISOS MÉDICOS EN VIVO (DISPATCH BOARD)
// ============================================================================

class DispatchBoard {
    constructor() {
        this.wrapper = document.getElementById("dispatchBoardApp");
        this.listEl = document.getElementById("dispatchBoardList");
        this.btnClose = document.getElementById("btnCloseBoard");
        this.backdrop = document.getElementById("dispatchBoardBackdrop");

        this.calls = [];
        this.mySrc = 0;
        this.isOpen = false;

        this.init();
    }

    init() {
        window.addEventListener("message", (event) => {
            const data = event.data;
            if (data.action === "openDispatchBoard") {
                this.calls = data.calls || [];
                this.mySrc = data.mySrc || 0;
                this.show();
            } else if (data.action === "closeDispatchBoard") {
                this.hide();
            } else if (data.action === "syncCallUpdate" && data.call) {
                this.updateCall(data.call);
            }
        });

        if (this.btnClose) this.btnClose.addEventListener("click", () => this.close());
        if (this.backdrop) this.backdrop.addEventListener("click", () => this.close());
    }

    show() {
        this.isOpen = true;
        this.wrapper.classList.remove("hidden");
        this.renderCalls();
    }

    hide() {
        this.isOpen = false;
        this.wrapper.classList.add("hidden");
    }

    close() {
        this.hide();
        postFetch('closeDispatchBoard');
    }

    updateCall(updatedCall) {
        const index = this.calls.findIndex(c => c.id === updatedCall.id);
        if (index !== -1) {
            this.calls[index] = updatedCall;
            if (this.isOpen) this.renderCalls();
        }
    }

    renderCalls() {
        if (!this.listEl) return;
        this.listEl.innerHTML = "";

        if (this.calls.length === 0) {
            this.listEl.innerHTML = `
                <div class="empty-board-state">
                    <i class="fa-solid fa-heart-circle-check"></i>
                    <h3>No hay emergencias médicas activas</h3>
                    <p>La red de ambulancias está en espera de nuevas llamadas del 911 o paradas cardíacas.</p>
                </div>
            `;
            return;
        }

        this.calls.forEach(call => {
            const card = document.createElement("div");
            card.className = "board-card";

            const units = call.assignedUnits || [];
            const isAssigned = units.some(u => u.src === this.mySrc);
            const isFull = units.length >= (call.maxUnits || 3);

            let unitsBadges = "";
            if (units.length === 0) {
                unitsBadges = `<span class="unit-pill empty"><i class="fa-regular fa-circle-question"></i> Sin ambulancia asignada</span>`;
            } else {
                unitsBadges = units.map(u => `
                    <span class="unit-pill ${u.src === this.mySrc ? 'my-unit' : ''}">
                        <i class="fa-solid fa-truck-medical"></i> ${u.name}
                    </span>
                `).join("");
            }

            card.innerHTML = `
                <div class="board-card-header">
                    <div class="board-card-header-left">
                        <span class="board-code-pill">${call.code || '10-33'}</span>
                        <h3 class="board-card-title">${call.title || 'Emergencia Médica'}</h3>
                    </div>
                    <span class="board-time"><i class="fa-regular fa-clock"></i> ${call.time || 'AHORA'}</span>
                </div>

                <div class="board-card-body">
                    <div class="board-info-row">
                        <span class="label"><i class="fa-solid fa-user-injured"></i> Paciente:</span>
                        <span class="value patient">${call.patientName || 'Ciudadano Inconsciente'}</span>
                    </div>
                    <div class="board-info-row">
                        <span class="label"><i class="fa-solid fa-heart-pulse"></i> Causa / Estado:</span>
                        <span class="value cause">${call.deathReason || 'Parada Cardiorrespiratoria'}</span>
                    </div>
                    <div class="board-info-row">
                        <span class="label"><i class="fa-solid fa-map-location-dot"></i> Ubicación:</span>
                        <span class="value">${call.street || 'Vía Pública'} <strong class="zone-highlight">(${call.zone || 'Los Santos'})</strong></span>
                    </div>
                </div>

                <div class="board-units-section">
                    <div class="board-units-header">
                        <span><i class="fa-solid fa-user-doctor"></i> Unidades en Ruta (${units.length}/${call.maxUnits || 3}):</span>
                    </div>
                    <div class="board-units-list">
                        ${unitsBadges}
                    </div>
                </div>

                <div class="board-card-actions">
                    ${isAssigned ? `
                        <button class="btn-card-action unassign" onclick="window.dispatchBoard.toggleAssign('${call.id}', false)">
                            <i class="fa-solid fa-circle-xmark"></i> Desasignarse
                        </button>
                    ` : `
                        <button class="btn-card-action assign ${isFull ? 'disabled' : ''}" 
                                ${isFull ? 'disabled' : ''} 
                                onclick="window.dispatchBoard.toggleAssign('${call.id}', true)">
                            <i class="fa-solid fa-hand-holding-medical"></i> ${isFull ? 'Cupo Completo' : 'Asignarme'}
                        </button>
                    `}
                    <button class="btn-card-action gps" onclick="window.dispatchBoard.setGPS(${call.coords.x}, ${call.coords.y})">
                        <i class="fa-solid fa-location-crosshairs"></i> Fijar GPS
                    </button>
                </div>
            `;

            this.listEl.appendChild(card);
        });
    }

    toggleAssign(callId, assign) {
        postFetch('toggleDispatchAssign', { callId, assign }).then(res => {
            if (res && res.success) {
                const call = this.calls.find(c => c.id === callId);
                if (call) {
                    if (assign) {
                        call.assignedUnits.push({ src: this.mySrc, name: "Tú" });
                    } else {
                        call.assignedUnits = call.assignedUnits.filter(u => u.src !== this.mySrc);
                    }
                    this.renderCalls();
                }
            }
        });
    }

    setGPS(x, y) {
        postFetch('setDispatchGps', { x, y });
    }
}

// ============================================================================
// 3. TABLETA CLÍNICA & SUITE MÉDICA MDT (CON RADIO TÁCTICA 20 CANALES)
// ============================================================================

class EmsMDT {
    constructor() {
        this.appEl = document.getElementById("emsMdtApp");
        this.backdrop = document.getElementById("emsMdtBackdrop");
        this.btnClose = document.getElementById("btnCloseMdt");
        this.tabBtns = document.querySelectorAll(".mdt-tab-btn");
        this.tabPanes = document.querySelectorAll(".mdt-tab-pane");

        // Historial
        this.inputSearch = document.getElementById("inputSearchRecord");
        this.btnSearch = document.getElementById("btnSearchRecords");
        this.recordsTableBody = document.getElementById("medicalRecordsTableBody");
        this.btnOpenNewRec = document.getElementById("btnOpenNewRecordModal");

        // Modal Nuevo Informe
        this.modalNewRecord = document.getElementById("modalNewRecord");
        this.btnCloseNewRec = document.getElementById("btnCloseNewRecordModal");
        this.btnCancelNewRec = document.getElementById("btnCancelNewRecord");
        this.btnSaveNewRec = document.getElementById("btnSaveNewRecord");

        // Radio Táctica (#01 - #20)
        this.radioEmisorasContainer = document.getElementById("emsRadioEmisorasContainer");
        this.radioBeaconWrapper = document.getElementById("emsRadioBeaconWrapper");
        this.radioActiveDot = document.getElementById("emsRadioActiveDot");
        this.radioActiveFreqDesc = document.getElementById("emsRadioActiveFreqDesc");
        this.radioActiveChannelTitle = document.getElementById("emsRadioActiveChannelTitle");
        this.btnEmsDisconnectRadio = document.getElementById("btnEmsDisconnectRadio");
        this.radioColorPickerDropdown = document.getElementById("radioColorPickerDropdown");
        this.pickerSwatchesGrid = document.getElementById("pickerSwatchesGrid");
        this.btnClosePicker = document.getElementById("btnCloseRadioColorPicker");

        // Staff
        this.staffTableBody = document.getElementById("staffTableBody");
        this.inputHireSrc = document.getElementById("inputHireTargetSrc");
        this.btnHireStaff = document.getElementById("btnHireStaff");

        this.isOpen = false;
        this.radioOverview = { channels: [], activeChannelIndex: null };

        this.init();
    }

    init() {
        window.addEventListener("message", (event) => {
            const data = event.data;
            if (data.action === "openEmsMdt") {
                this.show(data.overview || {});
            } else if (data.action === "closeEmsMdt") {
                this.hide();
            } else if (data.action === "syncRadioOverview" && data.overview) {
                this.radioOverview = data.overview;
                if (this.isOpen) {
                    this.renderRadio(data.overview);
                }
            } else if (data.action === "syncRadioChannel" && data.channel) {
                if (this.radioOverview && this.radioOverview.channels) {
                    const idx = this.radioOverview.channels.findIndex(c => c.channelIndex === data.channel.channelIndex);
                    if (idx !== -1) {
                        this.radioOverview.channels[idx] = data.channel;
                    }
                    if (this.isOpen) {
                        this.renderRadio(this.radioOverview);
                    }
                }
            }
        });

        if (this.btnClose) this.btnClose.addEventListener("click", () => this.close());
        if (this.backdrop) this.backdrop.addEventListener("click", () => this.close());

        this.tabBtns.forEach(btn => {
            btn.addEventListener("click", () => {
                const targetTab = btn.getAttribute("data-tab");
                this.switchTab(targetTab);
            });
        });

        if (this.btnSearch) {
            this.btnSearch.addEventListener("click", () => this.searchRecords());
        }

        if (this.btnOpenNewRec) {
            this.btnOpenNewRec.addEventListener("click", () => {
                this.modalNewRecord.classList.remove("hidden");
            });
        }
        if (this.btnCloseNewRec) {
            this.btnCloseNewRec.addEventListener("click", () => {
                this.modalNewRecord.classList.add("hidden");
            });
        }
        if (this.btnSaveNewRec) {
            this.btnSaveNewRec.addEventListener("click", () => this.saveNewRecord());
        }

        if (this.btnEmsDisconnectRadio) {
            this.btnEmsDisconnectRadio.addEventListener("click", () => this.disconnectRadio());
        }

        if (this.btnClosePicker) {
            this.btnClosePicker.addEventListener("click", () => this.closeColorPicker());
        }

        document.addEventListener("click", (e) => {
            if (this.radioColorPickerDropdown && !this.radioColorPickerDropdown.classList.contains("hidden")) {
                if (!this.radioColorPickerDropdown.contains(e.target) && !e.target.closest('.btn-patrol-color-mini')) {
                    this.closeColorPicker();
                }
            }
        });

        if (this.btnHireStaff) {
            this.btnHireStaff.addEventListener("click", () => this.hireStaff());
        }

        window.addEventListener("keydown", (e) => {
            if (this.isOpen && e.key === "Escape") {
                if (this.radioColorPickerDropdown && !this.radioColorPickerDropdown.classList.contains("hidden")) {
                    this.closeColorPicker();
                } else if (!this.modalNewRecord.classList.contains("hidden")) {
                    this.modalNewRecord.classList.add("hidden");
                } else {
                    this.close();
                }
            }
        });
    }

    show(overview) {
        this.isOpen = true;
        this.appEl.classList.remove("hidden");

        const statDoctors = document.getElementById("statActiveDoctors");
        const statRecords = document.getElementById("statTotalRecords");
        if (statDoctors) statDoctors.textContent = overview.activeDoctors || 0;
        if (statRecords) statRecords.textContent = overview.totalRecords || 0;

        const staffBtn = document.getElementById("tabStaffBtn");
        if (staffBtn) {
            staffBtn.style.display = overview.isBoss ? "flex" : "none";
        }

        this.loadCalls();
        this.loadRadioOverview();
    }

    hide() {
        this.isOpen = false;
        this.appEl.classList.add("hidden");
        this.modalNewRecord.classList.add("hidden");
        this.closeColorPicker();
    }

    close() {
        this.hide();
        postFetch('closeEmsMdt');
    }

    switchTab(tabId) {
        this.tabBtns.forEach(btn => {
            btn.classList.toggle("active", btn.getAttribute("data-tab") === tabId);
        });
        this.tabPanes.forEach(pane => {
            pane.classList.toggle("active", pane.id === tabId);
        });

        if (tabId === "tab-calls") this.loadCalls();
        else if (tabId === "tab-records") this.searchRecords();
        else if (tabId === "tab-radio") this.loadRadioOverview();
        else if (tabId === "tab-staff") this.loadStaff();
    }

    async loadCalls() {
        const grid = document.getElementById("mdtCallsGrid");
        if (!grid) return;
        const calls = await postFetch('getDispatchBoardCalls') || [];
        grid.innerHTML = "";
        calls.forEach(call => {
            const card = document.createElement("div");
            card.className = "board-card";
            card.innerHTML = `<h4 class="board-card-title">${call.title}</h4><p class="board-card-desc">Paciente: ${call.patientName || 'Desconocido'}</p>`;
            grid.appendChild(card);
        });
    }

    async searchRecords() {
        const query = this.inputSearch ? this.inputSearch.value : "";
        const res = await postFetch('searchMedicalRecords', { query });
        const records = (res && res.results) || [];

        if (!this.recordsTableBody) return;
        this.recordsTableBody.innerHTML = "";

        if (records.length === 0) {
            this.recordsTableBody.innerHTML = `
                <tr>
                    <td colspan="7" style="text-align: center; padding: 30px; color: #64748b;">
                        No se encontraron historiales médicos para los criterios de búsqueda.
                    </td>
                </tr>
            `;
            return;
        }

        records.forEach(rec => {
            const tr = document.createElement("tr");
            tr.innerHTML = `
                <td><strong>#${rec.id}</strong></td>
                <td>${rec.created_at || 'N/A'}</td>
                <td style="color:#ffffff; font-weight:700;">${rec.patient_name}</td>
                <td><span style="font-family:'JetBrains Mono'; color:#40E0D0;">${rec.citizenid}</span></td>
                <td>${rec.doctor_name || 'Sanitario'}</td>
                <td style="max-width: 350px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">${rec.diagnosis}</td>
                <td>
                    <button class="btn-card-action" onclick="window.emsMdt.viewDiagnosis('${encodeURIComponent(rec.patient_name || '')}', '${encodeURIComponent(rec.diagnosis || '')}')">
                        <i class="fa-solid fa-eye"></i> Ver
                    </button>
                </td>
            `;
            this.recordsTableBody.appendChild(tr);
        });
    }

    viewDiagnosis(patient, diagnosis) {
        alert(`PACIENTE: ${decodeURIComponent(patient)}\n\nDIAGNÓSTICO:\n${decodeURIComponent(diagnosis)}`);
    }

    async saveNewRecord() {
        const name = document.getElementById("newRecPatientName")?.value;
        const cid = document.getElementById("newRecCitizenId")?.value;
        const diag = document.getElementById("newRecDiagnosis")?.value;

        if (!name || !cid || !diag) {
            showToast("Completa todos los campos del informe médico.", true);
            return;
        }

        const res = await postFetch('createMedicalRecord', {
            patientName: name,
            citizenid: cid,
            diagnosis: diag
        });

        if (res && res.success) {
            this.modalNewRecord.classList.add("hidden");
            document.getElementById("newRecPatientName").value = "";
            document.getElementById("newRecCitizenId").value = "";
            document.getElementById("newRecDiagnosis").value = "";
            showToast(res.message || "Informe médico registrado.");
            this.searchRecords();
        } else {
            showToast(res.message || "Error al registrar el informe.", true);
        }
    }

    async loadRadioOverview() {
        const overview = await postFetch('getEmsRadioOverview');
        if (overview) {
            this.radioOverview = overview;
            this.renderRadio(overview);
        }
    }

    renderRadio(overview) {
        if (!this.radioEmisorasContainer) return;

        const channels = overview.channels || [];
        const activeChannelIndex = overview.activeChannelIndex;
        const currentChannel = channels.find(c => c.channelIndex === activeChannelIndex);

        if (currentChannel) {
            if (this.radioActiveChannelTitle) this.radioActiveChannelTitle.textContent = `${currentChannel.label.toUpperCase()} (${parseFloat(currentChannel.frequency).toFixed(1)} MHz)`;
            if (this.radioActiveFreqDesc) this.radioActiveFreqDesc.textContent = `Conectado y transmitiendo en vivo. Frecuencia ${parseFloat(currentChannel.frequency).toFixed(1)} MHz`;
            if (this.radioActiveDot) { this.radioActiveDot.style.background = currentChannel.color || '#40E0D0'; this.radioActiveDot.style.boxShadow = `0 0 10px ${currentChannel.color || '#40E0D0'}`; }
            if (this.radioBeaconWrapper) this.radioBeaconWrapper.classList.add('active');
            if (this.btnEmsDisconnectRadio) this.btnEmsDisconnectRadio.style.display = 'inline-flex';
        } else {
            if (this.radioActiveChannelTitle) this.radioActiveChannelTitle.textContent = 'DESCONECTADO DE LA RED';
            if (this.radioActiveFreqDesc) this.radioActiveFreqDesc.textContent = 'FRECUENCIAS MÉDICAS ENCRIPTADAS (10.1 - 12.0 MHz)';
            if (this.radioActiveDot) { this.radioActiveDot.style.background = '#64748b'; this.radioActiveDot.style.boxShadow = 'none'; }
            if (this.radioBeaconWrapper) this.radioBeaconWrapper.classList.remove('active');
            if (this.btnEmsDisconnectRadio) this.btnEmsDisconnectRadio.style.display = 'none';
        }

        this.radioEmisorasContainer.innerHTML = '';
        channels.forEach(p => {
            const isConnected = (p.channelIndex === activeChannelIndex);
            const pMembers = p.members || [];
            const hexColor = p.color || '#40E0D0';

            let membersChips = pMembers.length === 0 ? '<span class="patrol-empty-text"><i class="fa-regular fa-circle-check"></i> Disponible / Libre</span>' : '<div class="patrol-chips-wrap">' + pMembers.map(mem => `<span class="patrol-chip" title="${mem.name}"><i class="fa-solid fa-user-doctor"></i> ${mem.name}</span>`).join('') + '</div>';

            const card = document.createElement('div');
            card.className = `patrol-card ${isConnected ? 'active' : ''}`;
            card.style.setProperty('--patrol-color', hexColor);

            card.innerHTML = `
                <div class="patrol-card-header">
                    <div class="patrol-info"><span class="patrol-dot" style="background:${hexColor}; box-shadow: 0 0 8px ${hexColor};"></span><strong class="patrol-title">${p.label}</strong><span class="patrol-freq-badge">${parseFloat(p.frequency).toFixed(1)} MHz</span></div>
                    <div class="patrol-btn-group">
                        <button class="btn-patrol-color-mini" onclick="window.openEmsRadioColorPicker(${p.channelIndex}, event)"><i class="fa-solid fa-palette"></i></button>
                        ${isConnected ? `<button class="btn-patrol-join disconnect" onclick="window.leaveEmsRadio()"><i class="fa-solid fa-link-slash"></i> Salir</button>` : `<button class="btn-patrol-join" onclick="window.joinEmsRadio(${p.channelIndex})"><i class="fa-solid fa-plug"></i> Entrar</button>`}
                    </div>
                </div>
                <div class="patrol-members-row">${membersChips}</div>
            `;
            this.radioEmisorasContainer.appendChild(card);
        });
    }

    async joinRadio(channelIndex) {
        const res = await postFetch('joinEmsRadio', { channelIndex });
        if (res && res.success) { showToast(res.message || `Conectado al Canal #${channelIndex}`); this.loadRadioOverview(); } else { showToast((res && res.message) || "Error al conectar.", true); }
    }

    async disconnectRadio() {
        const res = await postFetch('leaveEmsRadio');
        if (res && res.success) { showToast(res.message || "Desconectado."); this.loadRadioOverview(); } else { showToast((res && res.message) || "Error al desconectar.", true); }
    }

    openColorPicker(channelIndex, event) {
        if (event) { event.stopPropagation(); event.preventDefault(); }
        activePickerChannelIndex = channelIndex;
        if (!this.radioColorPickerDropdown || !this.pickerSwatchesGrid) return;

        this.pickerSwatchesGrid.innerHTML = '';
        RADIO_COLOR_PALETTE.forEach(c => {
            const btn = document.createElement('button');
            btn.className = 'swatch-btn';
            btn.innerHTML = `<span class="swatch-circle" style="background: ${c.hex};"></span><span>${c.name}</span>`;
            btn.onclick = (e) => { e.stopPropagation(); this.setColor(c.hex, c.blip); };
            this.pickerSwatchesGrid.appendChild(btn);
        });
        this.radioColorPickerDropdown.classList.remove('hidden');
    }

    closeColorPicker() { if (this.radioColorPickerDropdown) this.radioColorPickerDropdown.classList.add('hidden'); activePickerChannelIndex = null; }

    async setColor(hexColor, blipColor) {
        if (!activePickerChannelIndex) return;
        const channelIndex = activePickerChannelIndex;
        this.closeColorPicker();
        const res = await postFetch('setEmsRadioColor', { channelIndex, hexColor, blipColor });
        if (res && res.success) { showToast("Color actualizado."); this.loadRadioOverview(); } else { showToast("Error al actualizar.", true); }
    }

    async loadStaff() {
        const res = await postFetch('getEmsStaff');
        const staff = (res && res.staff) || [];
        if (!this.staffTableBody) return;
        this.staffTableBody.innerHTML = "";

        if (staff.length === 0) {
            this.staffTableBody.innerHTML = `
                <tr>
                    <td colspan="7" style="text-align: center; padding: 25px; color: #64748b;">
                        No hay miembros del cuerpo médico registrados en la base de datos.
                    </td>
                </tr>
            `;
            return;
        }

        staff.forEach(emp => {
            const tr = document.createElement("tr");
            tr.innerHTML = `
                <td style="color:#ffffff; font-weight:700;">${emp.name}</td>
                <td><span style="font-family:'JetBrains Mono'; color:#40E0D0;">${emp.citizenid}</span></td>
                <td><strong style="color:#FF007F;">${emp.gradeLabel}</strong> (Grado ${emp.grade})</td>
                <td>$${emp.salary}/nómina</td>
                <td>${emp.phone || 'N/A'}</td>
                <td>
                    ${emp.isOnline ? `
                        <span style="color:${emp.isDuty ? '#40E0D0' : '#f59e0b'}; font-weight:700;">
                            ${emp.isDuty ? 'EN SERVICIO' : 'ONLINE'}
                        </span>
                    ` : `<span style="color:#64748b;">Desconectado</span>`}
                </td>
                <td>
                    <div style="display:flex; gap:6px;">
                        <button class="btn-card-action" onclick="window.emsMdt.promoteStaff(${emp.charId}, ${emp.grade + 1})" title="Ascender">
                            <i class="fa-solid fa-arrow-up"></i>
                        </button>
                        <button class="btn-card-action" onclick="window.emsMdt.promoteStaff(${emp.charId}, ${emp.grade - 1})" title="Degradar">
                            <i class="fa-solid fa-arrow-down"></i>
                        </button>
                        <button class="btn-card-action" style="color:#f43f5e; border-color:#f43f5e;" onclick="window.emsMdt.fireStaff(${emp.charId})" title="Despedir">
                            <i class="fa-solid fa-user-xmark"></i>
                        </button>
                    </div>
                </td>
            `;
            this.staffTableBody.appendChild(tr);
        });
    }

    async hireStaff() {
        const src = parseInt(this.inputHireSrc.value);
        if (!src) return;
        const res = await postFetch('hireEmsStaff', { targetSrc: src });
        showToast(res.message || "Resultado de contratación", !res.success);
        this.inputHireSrc.value = "";
        this.loadStaff();
    }

    async fireStaff(charId) {
        if (!confirm("¿Confirmas el despido de este empleado?")) return;
        const res = await postFetch('fireEmsStaff', { targetCharId: charId });
        showToast(res.message || "Resultado de despido", !res.success);
        this.loadStaff();
    }

    async promoteStaff(charId, newGrade) {
        if (newGrade < 0 || newGrade > 4) return;
        const res = await postFetch('setEmsStaffGrade', { targetCharId: charId, newGrade });
        showToast(res.message || "Resultado de actualización de rango", !res.success);
        this.loadStaff();
    }
}

// ============================================================================
// FUNCIONES GLOBALES NUI & ACCESOS DIRECTOS
// ============================================================================

window.joinEmsRadio = (channelIndex) => { if (window.emsMdt) window.emsMdt.joinRadio(channelIndex); };
window.leaveEmsRadio = () => { if (window.emsMdt) window.emsMdt.disconnectRadio(); };
window.openEmsRadioColorPicker = (channelIndex, event) => { if (window.emsMdt) window.emsMdt.openColorPicker(channelIndex, event); };

// ============================================================================
// INICIALIZACIÓN GLOBAL
// ============================================================================

window.addEventListener('DOMContentLoaded', () => {
    window.dispatchHUD = new DispatchHUD();
    window.dispatchBoard = new DispatchBoard();
    window.emsMdt = new EmsMDT();
});
