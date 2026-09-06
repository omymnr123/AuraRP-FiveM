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
        this.btnRefresh = document.getElementById("btnRefreshBoard");
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

        if (this.btnRefresh) {
            this.btnRefresh.addEventListener("click", () => {
                postFetch('getDispatchBoardCalls').then(calls => {
                    if (Array.isArray(calls)) {
                        this.calls = calls;
                        this.renderCalls();
                    }
                });
            });
        }

        window.addEventListener("keydown", (e) => {
            if (this.isOpen && (e.key === "Escape" || e.key === "u" || e.key === "U")) {
                this.close();
            }
        });
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
        } else {
            this.calls.unshift(updatedCall);
        }
        if (this.isOpen) {
            this.renderCalls();
        }
    }

    renderCalls() {
        if (!this.listEl) return;
        this.listEl.innerHTML = "";

        if (!this.calls || this.calls.length === 0) {
            this.listEl.innerHTML = `
                <div class="board-empty-state">
                    <i class="fa-solid fa-heart-pulse"></i>
                    <h4>Sin Incidentes Sanitarios Activos</h4>
                    <p>La central médica no registra llamadas de emergencias 10-33 pendientes en este momento.</p>
                </div>
            `;
            return;
        }

        this.calls.forEach(call => {
            const isResolved = call.status === 'resolved';
            const units = call.units || [];
            const maxUnits = call.maxUnits || 2;
            const isFull = units.length >= maxUnits;
            const amIAttending = units.some(u => u.src === this.mySrc);

            let statusPillClass = 'status-pending';
            let statusLabel = `PENDIENTE (0/${maxUnits})`;

            if (isResolved) {
                statusPillClass = 'status-resolved';
                statusLabel = 'RESUELTO';
            } else if (isFull) {
                statusPillClass = 'status-full';
                statusLabel = `CUPO COMPLETO (${units.length}/${maxUnits})`;
            } else if (units.length > 0) {
                statusPillClass = 'status-responding';
                statusLabel = `EN CURSO (${units.length}/${maxUnits})`;
            }

            const card = document.createElement("div");
            card.className = `board-call-card ${isResolved ? 'resolved' : ''}`;
            card.id = `boardCall_${call.id}`;

            card.innerHTML = `
                <div class="board-card-header">
                    <div class="board-header-info">
                        <span class="board-code-pill">${call.code || '10-33'}</span>
                        <h4 class="board-call-title">${call.title || 'Emergencia Médica'}</h4>
                        <span class="board-call-time"><i class="fa-regular fa-clock"></i> ${call.time || 'AHORA'}</span>
                    </div>
                    <div class="board-status-pill ${statusPillClass}">
                        <span class="pulse-dot-cyan"></span>
                        <span>${statusLabel}</span>
                    </div>
                </div>

                <div class="board-card-body">
                    <div class="board-patient-row">
                        <i class="fa-solid fa-user-injured"></i>
                        <span>Paciente: <strong>${call.patientName || 'Ciudadano Inconsciente'}</strong></span>
                    </div>
                    <div class="board-cause-row">
                        <i class="fa-solid fa-heart-pulse"></i>
                        <span>Estado / Causa: <strong>${call.deathReason || 'Parada Cardiorrespiratoria'}</strong></span>
                    </div>
                    <div class="board-loc-row">
                        <i class="fa-solid fa-location-dot"></i>
                        <span>${call.street || 'Vía Pública'} <strong>(${call.zone || 'Los Santos'})</strong></span>
                    </div>
                </div>

                <div class="board-units-section">
                    <div class="board-units-label">
                        <i class="fa-solid fa-truck-medical"></i> Ambulancias en camino (${units.length}/${maxUnits}):
                    </div>
                    <div class="board-units-list">
                        ${units.length > 0 ? units.map(u => `
                            <span class="unit-badge ${u.src === this.mySrc ? 'my-unit' : ''}">
                                <i class="fa-solid fa-user-doctor"></i> ${u.name}
                            </span>
                        `).join('') : '<span class="no-units-text">Ninguna ambulancia asignada todavía</span>'}
                    </div>
                </div>

                <div class="board-card-actions">
                    <button class="btn-board-action gps" onclick="window.dispatchBoard.setGps(${call.coords ? call.coords.x : 0}, ${call.coords ? call.coords.y : 0})">
                        <i class="fa-solid fa-location-crosshairs"></i>
                        <span>Fijar GPS</span>
                    </button>

                    ${!isResolved ? `
                        ${amIAttending ? `
                            <button class="btn-board-action cancel" onclick="window.dispatchBoard.cancelCall(${call.id})">
                                <i class="fa-solid fa-user-xmark"></i>
                                <span>Cancelar Respuesta</span>
                            </button>
                        ` : `
                            <button class="btn-board-action respond ${isFull ? 'disabled' : ''}" ${isFull ? 'disabled' : ''} onclick="window.dispatchBoard.respondCall(${call.id})">
                                <i class="fa-solid fa-hand-holding-medical"></i>
                                <span>${isFull ? 'Cupo Completo' : 'Acudir / Responder'}</span>
                            </button>
                        `}

                        <button class="btn-board-action resolve" onclick="window.dispatchBoard.resolveCall(${call.id})">
                            <i class="fa-solid fa-check-double"></i>
                            <span>Marcar Resuelto</span>
                        </button>
                    ` : ''}
                </div>
            `;

            this.listEl.appendChild(card);
        });
    }

    respondCall(callId) {
        postFetch('respondDispatchCall', { callId: callId });
    }

    cancelCall(callId) {
        postFetch('cancelDispatchCall', { callId: callId });
    }

    resolveCall(callId) {
        postFetch('resolveDispatchCall', { callId: callId });
    }

    setGps(x, y) {
        postFetch('setDispatchGps', { x: x, y: y });
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

        // Modal Ver Informe
        this.modalViewRecord = document.getElementById("modalViewRecord");
        this.btnCloseViewRec = document.getElementById("btnCloseViewRecordModal");
        this.btnDoneViewRec = document.getElementById("btnDoneViewRecord");
        this.currentRecords = [];

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
                if (!this.isOpen) {
                    postFetch('closeDiagnosticModal');
                }
            });
        }
        if (this.btnCancelNewRec) {
            this.btnCancelNewRec.addEventListener("click", () => {
                this.modalNewRecord.classList.add("hidden");
                if (!this.isOpen) {
                    postFetch('closeDiagnosticModal');
                }
            });
        }
        if (this.btnSaveNewRec) {
            this.btnSaveNewRec.addEventListener("click", () => this.saveNewRecord());
        }

        if (this.btnCloseViewRec) {
            this.btnCloseViewRec.addEventListener("click", () => this.closeViewRecordModal());
        }
        if (this.btnDoneViewRec) {
            this.btnDoneViewRec.addEventListener("click", () => this.closeViewRecordModal());
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
            if (e.key === "Escape") {
                if (this.modalViewRecord && !this.modalViewRecord.classList.contains("hidden")) {
                    this.closeViewRecordModal();
                } else if (this.modalNewRecord && !this.modalNewRecord.classList.contains("hidden")) {
                    this.modalNewRecord.classList.add("hidden");
                    if (!this.isOpen) {
                        postFetch('closeDiagnosticModal');
                    }
                } else if (this.isOpen) {
                    if (this.radioColorPickerDropdown && !this.radioColorPickerDropdown.classList.contains("hidden")) {
                        this.closeColorPicker();
                    } else {
                        this.close();
                    }
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
        const res = await postFetch('getDispatchBoardCalls');
        const calls = Array.isArray(res) ? res : (res && Array.isArray(res.calls) ? res.calls : []);
        grid.innerHTML = "";

        if (calls.length === 0) {
            grid.innerHTML = `
                <div class="empty-state-card">
                    <i class="fa-solid fa-clipboard-check text-cyan"></i>
                    <p>No hay avisos médicos de emergencia activos en este momento.</p>
                </div>
            `;
            return;
        }

        calls.forEach(call => {
            const card = document.createElement("div");
            card.className = "board-card";
            card.innerHTML = `<h4 class="board-card-title">${call.title || 'Emergencia Médica'}</h4><p class="board-card-desc">Paciente: ${call.patientName || 'Desconocido'}</p>`;
            grid.appendChild(card);
        });
    }

    async searchRecords() {
        const query = this.inputSearch ? this.inputSearch.value : "";
        const res = await postFetch('searchMedicalRecords', { query });
        const records = (res && res.results) || [];
        this.currentRecords = records;

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
                    <button class="btn-card-action" onclick="window.emsMdt.viewDiagnosisRecord(${rec.id})">
                        <i class="fa-solid fa-file-waveform text-cyan"></i> Ver Informe
                    </button>
                </td>
            `;
            this.recordsTableBody.appendChild(tr);
        });
    }

    viewDiagnosisRecord(recId) {
        const rec = (this.currentRecords || []).find(r => r.id === recId);
        if (!rec) return;

        const idEl = document.getElementById("viewRecId");
        const patientEl = document.getElementById("viewRecPatient");
        const cidEl = document.getElementById("viewRecCitizenId");
        const docEl = document.getElementById("viewRecDoctor");
        const dateEl = document.getElementById("viewRecDate");
        const diagEl = document.getElementById("viewRecDiagnosis");

        if (idEl) idEl.textContent = `#${rec.id}`;
        if (patientEl) patientEl.textContent = (rec.patient_name || 'Paciente Desconocido').toUpperCase();
        if (cidEl) cidEl.textContent = rec.citizenid || 'SIN REGISTRO';
        if (docEl) docEl.textContent = rec.doctor_name || 'Sistema Médico Central';
        if (dateEl) dateEl.textContent = rec.created_at || 'N/A';
        if (diagEl) diagEl.textContent = rec.diagnosis || 'Sin anotaciones clínicas.';

        if (this.modalViewRecord) {
            this.modalViewRecord.classList.remove("hidden");
        }
    }

    closeViewRecordModal() {
        if (this.modalViewRecord) {
            this.modalViewRecord.classList.add("hidden");
        }
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
            if (!this.isOpen) {
                postFetch('closeDiagnosticModal');
            }
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
// 4. DIAGNOSTIC MODAL & ANATOMICAL BODY MAP CONTROLLER (AURA EMS)
// ============================================================================

class DiagnosticModal {
    constructor() {
        this.wrapper = document.getElementById("diagnosticModalApp");
        this.backdrop = document.getElementById("diagnosticModalBackdrop");
        this.btnClose = document.getElementById("btnCloseDiag");
        this.btnCloseBottom = document.getElementById("btnDiagCloseBottom");

        // Elementos de cabecera
        this.patientName = document.getElementById("diagPatientName");
        this.citizenId = document.getElementById("diagCitizenId");
        this.genderBadge = document.getElementById("diagGenderBadge");
        this.glasgowScore = document.getElementById("diagGlasgowScore");
        this.statusBadge = document.getElementById("diagStatusBadge");
        this.statusText = document.getElementById("diagStatusText");

        // Hemodinámica
        this.bpmVal = document.getElementById("diagBpmVal");
        this.rhythmLabel = document.getElementById("diagRhythmLabel");
        this.ecgStateText = document.getElementById("diagEcgStateText");
        this.bpVal = document.getElementById("diagBpVal");
        this.bpStatus = document.getElementById("diagBpStatus");
        this.spo2Val = document.getElementById("diagSpo2Val");
        this.spo2Bar = document.getElementById("diagSpo2Bar");
        this.spo2Status = document.getElementById("diagSpo2Status");
        this.bleedingVal = document.getElementById("diagBleedingVal");
        this.tourniquetBadge = document.getElementById("diagTourniquetBadge");

        // Siluetas Anatómicas
        this.maleContainer = document.getElementById("maleSilhouetteContainer");
        this.femaleContainer = document.getElementById("femaleSilhouetteContainer");
        this.tooltip = document.getElementById("anatomyTooltip");
        this.tooltipBoneName = document.getElementById("tooltipBoneName");
        this.tooltipBoneHp = document.getElementById("tooltipBoneHp");
        this.tooltipInjuriesList = document.getElementById("tooltipInjuriesList");

        // Termorregulación y Metabolismo
        this.coreTempVal = document.getElementById("diagCoreTempVal");
        this.ambientTempVal = document.getElementById("diagAmbientTempVal");
        this.insulationVal = document.getElementById("diagInsulationVal");
        this.tempBadge = document.getElementById("diagTempBadge");

        this.healthVal = document.getElementById("diagHealthVal");
        this.healthBar = document.getElementById("diagHealthBar");
        this.armorVal = document.getElementById("diagArmorVal");
        this.armorBar = document.getElementById("diagArmorBar");
        this.hungerVal = document.getElementById("diagHungerVal");
        this.hungerBar = document.getElementById("diagHungerBar");
        this.thirstVal = document.getElementById("diagThirstVal");
        this.thirstBar = document.getElementById("diagThirstBar");
        this.staminaVal = document.getElementById("diagStaminaVal");
        this.staminaBar = document.getElementById("diagStaminaBar");

        // Botones de acción
        this.btnTourniquet = document.getElementById("btnDiagTourniquet");
        this.btnDefib = document.getElementById("btnDiagDefib");
        this.btnSaveRecord = document.getElementById("btnDiagSaveRecord");

        // Canvas ECG
        this.canvas = document.getElementById("ecgWaveCanvas");
        this.ctx = this.canvas ? this.canvas.getContext("2d") : null;
        this.ecgAnimationId = null;
        this.ecgX = 0;
        this.ecgPoints = [];

        this.currentPatient = null;
        this.isOpen = false;

        this.boneLabels = {
            head: "Cabeza y Cuello",
            torso: "Tórax, Espina Dorsal y Pelvis",
            right_arm: "Brazo Derecho",
            left_arm: "Brazo Izquierdo",
            right_hand: "Mano Derecha",
            left_hand: "Mano Izquierda",
            right_leg: "Pierna Derecha",
            left_leg: "Pierna Izquierda",
            right_foot: "Pie Derecho",
            left_foot: "Pie Izquierdo"
        };

        this.init();
    }

    init() {
        // Escuchar mensajes NUI
        window.addEventListener("message", (event) => {
            const data = event.data;
            if (data.action === "openDiagnosticModal" && data.patient) {
                this.open(data.patient);
            } else if (data.action === "closeDiagnosticModal") {
                this.close();
            } else if (data.action === "updateDiagnosticVitals" && (data.patient || data.vitals)) {
                this.updateData(data.patient || data.vitals);
            }
        });

        // Eventos de cierre
        if (this.btnClose) this.btnClose.addEventListener("click", () => this.close());
        if (this.btnCloseBottom) this.btnCloseBottom.addEventListener("click", () => this.close());
        if (this.backdrop) this.backdrop.addEventListener("click", () => this.close());

        window.addEventListener("keydown", (e) => {
            if (e.key === "Escape" && this.isOpen) {
                this.close();
            }
        });

        // Eventos de botones de acción
        if (this.btnTourniquet) {
            this.btnTourniquet.addEventListener("click", () => this.handleTourniquet());
        }

        if (this.btnDefib) {
            this.btnDefib.addEventListener("click", () => this.handleDefib());
        }

        if (this.btnSaveRecord) {
            this.btnSaveRecord.addEventListener("click", () => this.handleSaveRecord());
        }

        this.bindAnatomyInteractions();
    }

    open(patient) {
        this.currentPatient = patient;
        this.isOpen = true;
        this.updateData(patient);

        // Resetear botones de acción médica reactivamente
        if (this.btnTourniquet) {
            this.btnTourniquet.classList.remove("in-progress");
            if (patient.hasTourniquet || patient.isTourniquetApplied) {
                this.btnTourniquet.classList.add("completed");
                this.btnTourniquet.innerHTML = `<i class="fa-solid fa-check"></i><span>Torniquete C-A-T Aplicado</span>`;
            } else {
                this.btnTourniquet.classList.remove("completed");
                this.btnTourniquet.innerHTML = `<i class="fa-solid fa-bandage"></i><span>Aplicar Torniquete C-A-T</span>`;
            }
        }

        if (this.btnDefib) {
            this.btnDefib.classList.remove("in-progress");
            if (!patient.isDead && (patient.bpm && patient.bpm > 0)) {
                this.btnDefib.classList.add("completed");
                this.btnDefib.innerHTML = `<i class="fa-solid fa-heart-circle-check text-cyan"></i><span>Ritmo Sinusal (78 BPM)</span>`;
            } else {
                this.btnDefib.classList.remove("completed");
                this.btnDefib.innerHTML = `<i class="fa-solid fa-heart-pulse"></i><span>Desfibrilador (DEA)</span>`;
            }
        }

        if (this.wrapper) {
            this.wrapper.classList.remove("hidden");
        }

        this.startEcgAnimation();
    }

    close() {
        if (!this.isOpen) return;
        this.isOpen = false;
        if (this.wrapper) {
            this.wrapper.classList.add("hidden");
        }
        this.stopEcgAnimation();
        postFetch('closeDiagnosticModal');
    }

    updateData(patient) {
        if (!patient) return;
        this.currentPatient = Object.assign(this.currentPatient || {}, patient);

        // 1. Identidad y Metadatos
        if (this.patientName) {
            this.patientName.textContent = patient.name ? patient.name.toUpperCase() : "PACIENTE • EVALUACIÓN INICIAL";
        }
        if (this.citizenId) {
            this.citizenId.textContent = patient.citizenid || "SIN REGISTRO";
        }

        // Género y Silueta Anatómica (Adaptación Dinámica Masculino / Femenino)
        const isMale = patient.isMale !== false;
        if (this.genderBadge) {
            if (isMale) {
                this.genderBadge.className = "gender-pill male";
                this.genderBadge.innerHTML = `<i class="fa-solid fa-mars"></i> MASCULINO`;
            } else {
                this.genderBadge.className = "gender-pill female";
                this.genderBadge.innerHTML = `<i class="fa-solid fa-venus"></i> FEMENINO`;
            }
        }

        if (this.maleContainer && this.femaleContainer) {
            if (isMale) {
                this.maleContainer.classList.remove("hidden");
                this.maleContainer.style.display = "flex";
                this.femaleContainer.classList.add("hidden");
                this.femaleContainer.style.display = "none";
            } else {
                this.maleContainer.classList.add("hidden");
                this.maleContainer.style.display = "none";
                this.femaleContainer.classList.remove("hidden");
                this.femaleContainer.style.display = "flex";
            }
        }

        // Escala Glasgow y Estado Clínico
        const isDead = patient.isDead === true || (patient.health !== undefined && patient.health <= 0);
        const glasgow = patient.glasgow || (isDead ? 3 : 15);
        if (this.glasgowScore) {
            this.glasgowScore.textContent = `${glasgow}/15`;
        }

        if (this.statusBadge && this.statusText) {
            if (isDead) {
                this.statusBadge.className = "diag-status-badge critical";
                this.statusText.textContent = "PARADA CARDIORRESPIRATORIA (PCR)";
            } else if (patient.health < 40) {
                this.statusBadge.className = "diag-status-badge critical";
                this.statusText.textContent = "ESTADO CRÍTICO / TRAUMA SEVERO";
            } else {
                this.statusBadge.className = "diag-status-badge stable";
                this.statusText.textContent = "PACIENTE CONSCIENTE / ESTABLE";
            }
        }

        // 2. Hemodinámica
        const bpm = isDead ? 0 : (patient.bpm || 72);
        if (this.bpmVal) this.bpmVal.textContent = bpm;
        if (this.rhythmLabel) {
            this.rhythmLabel.textContent = isDead ? "ASISTOLIA / FV" : (bpm > 100 ? "TAQUICARDIA" : "SINUSAL NORMAL");
            this.rhythmLabel.style.color = isDead ? "#ff2a55" : (bpm > 100 ? "#f59e0b" : "#40E0D0");
        }
        if (this.ecgStateText) {
            this.ecgStateText.textContent = isDead ? "FIBRILACIÓN VENTRICULAR / SIN PULSO" : "RITMO SINUSAL NORMAL";
            this.ecgStateText.style.color = isDead ? "#f43f5e" : "#10b981";
        }

        if (this.bpVal) this.bpVal.textContent = patient.bloodPressure || (isDead ? "0/0 mmHg" : "120/80 mmHg");
        if (this.bpStatus) this.bpStatus.textContent = isDead ? "Colapso Vascular / Hipotensión Severa" : "Presión Arterial Normotensa";

        const spo2 = isDead ? (patient.spo2 || 40) : (patient.spo2 || 98);
        if (this.spo2Val) this.spo2Val.textContent = `${spo2}%`;
        if (this.spo2Bar) this.spo2Bar.style.width = `${spo2}%`;
        if (this.spo2Status) this.spo2Status.textContent = spo2 > 90 ? "Oxigenación Tisular Óptima" : "Hipoxia Severa por Hipoventilación";

        if (this.bleedingVal) {
            this.bleedingVal.textContent = patient.bleedingLevel || (isDead ? "Grave (Arteria Femoral)" : "Sin Hemorragias Activas");
        }

        if (this.tourniquetBadge) {
            if (patient.hasTourniquet || patient.isTourniquetApplied) {
                this.tourniquetBadge.className = "badge-tourniquet active";
                this.tourniquetBadge.innerHTML = `<i class="fa-solid fa-check"></i> Torniquete C-A-T Colocado (Ocluido)`;
            } else if (isDead || (patient.bleedingLevel && patient.bleedingLevel !== "Sin Hemorragias Activas")) {
                this.tourniquetBadge.className = "badge-tourniquet";
                this.tourniquetBadge.innerHTML = `<i class="fa-solid fa-triangle-exclamation text-pink"></i> Requiere Compresión / Torniquete`;
            } else {
                this.tourniquetBadge.className = "badge-tourniquet";
                this.tourniquetBadge.innerHTML = `<i class="fa-solid fa-shield-heart"></i> Sin Torniquete Requerido`;
            }
        }

        // 3. Termorregulación (aura_seasons)
        const coreTemp = patient.temperature !== undefined ? patient.temperature : 36.8;
        if (this.coreTempVal) this.coreTempVal.textContent = coreTemp.toFixed(1);
        if (this.ambientTempVal) this.ambientTempVal.textContent = (patient.ambientTemp || 21.0).toFixed(1);
        if (this.insulationVal) this.insulationVal.textContent = Math.round(patient.insulation || 35);

        if (this.tempBadge) {
            if (coreTemp < 35.0) {
                this.tempBadge.className = "thermal-pill hypo";
                this.tempBadge.textContent = "Hipotermia Severa";
            } else if (coreTemp < 36.2) {
                this.tempBadge.className = "thermal-pill hypo";
                this.tempBadge.textContent = "Hipotermia Leve";
            } else if (coreTemp > 38.5) {
                this.tempBadge.className = "thermal-pill hyper";
                this.tempBadge.textContent = "Hipertermia / Fiebre";
            } else {
                this.tempBadge.className = "thermal-pill normal";
                this.tempBadge.textContent = "Normotermia";
            }
        }

        // 4. Metabolismo y Vitalidad (aura_status)
        const health = patient.health !== undefined ? Math.max(0, Math.min(100, patient.health)) : (isDead ? 0 : 100);
        if (this.healthVal) this.healthVal.textContent = `${health}%`;
        if (this.healthBar) this.healthBar.style.width = `${health}%`;

        const armor = patient.armor !== undefined ? Math.max(0, Math.min(100, patient.armor)) : 0;
        if (this.armorVal) this.armorVal.textContent = `${armor}%`;
        if (this.armorBar) this.armorBar.style.width = `${armor}%`;

        const hunger = patient.hunger !== undefined ? Math.max(0, Math.min(100, Math.floor(patient.hunger))) : 85;
        if (this.hungerVal) this.hungerVal.textContent = `${hunger}%`;
        if (this.hungerBar) this.hungerBar.style.width = `${hunger}%`;

        const thirst = patient.thirst !== undefined ? Math.max(0, Math.min(100, Math.floor(patient.thirst))) : 78;
        if (this.thirstVal) this.thirstVal.textContent = `${thirst}%`;
        if (this.thirstBar) this.thirstBar.style.width = `${thirst}%`;

        const stamina = patient.stamina !== undefined ? Math.max(0, Math.min(100, Math.floor(patient.stamina))) : (isDead ? 0 : 95);
        if (this.staminaVal) this.staminaVal.textContent = `${stamina}%`;
        if (this.staminaBar) this.staminaBar.style.width = `${stamina}%`;

        // 5. Renderizar Daños en las 10 Partes Anatómicas
        this.renderBoneDamage(patient.boneDamage);
    }

    renderBoneDamage(boneDamage) {
        const parts = ['head', 'torso', 'right_arm', 'left_arm', 'right_hand', 'left_hand', 'right_leg', 'left_leg', 'right_foot', 'left_foot'];
        let worstPart = 'torso';
        let lowestHp = 101;
        let worstInjuries = [];
        
        parts.forEach(partKey => {
            const maleEl = document.getElementById(`svg-male-${partKey}`);
            const femaleEl = document.getElementById(`svg-female-${partKey}`);

            let hp = 100;
            let injuries = [];

            if (boneDamage && boneDamage[partKey]) {
                hp = boneDamage[partKey].health !== undefined ? boneDamage[partKey].health : 100;
                injuries = boneDamage[partKey].injuries || [];
            }

            if (hp < lowestHp) {
                lowestHp = hp;
                worstPart = partKey;
                worstInjuries = injuries;
            }

            const stateClass = this.getHpSeverityClass(hp);

            [maleEl, femaleEl].forEach(el => {
                if (el) {
                    el.classList.remove('healthy', 'minor', 'moderate', 'severe', 'critical');
                    el.classList.add(stateClass);
                    el.dataset.health = hp;
                    el.dataset.injuries = JSON.stringify(injuries);
                }
            });
        });

        // Mostrar de entrada la región más afectada en el panel inferior
        this.showPartTooltip(worstPart, lowestHp <= 100 ? lowestHp : 100, worstInjuries);
    }

    getHpSeverityClass(hp) {
        if (hp <= 0) return 'critical';
        if (hp < 40) return 'severe';
        if (hp < 75) return 'moderate';
        if (hp < 100) return 'minor';
        return 'healthy';
    }

    bindAnatomyInteractions() {
        const bodyParts = document.querySelectorAll(".body-part");
        bodyParts.forEach(el => {
            el.addEventListener("mouseenter", (e) => {
                const partKey = el.dataset.part;
                const hp = parseInt(el.dataset.health || "100");
                let injuries = [];
                try {
                    injuries = JSON.parse(el.dataset.injuries || "[]");
                } catch(err) { injuries = []; }

                this.showPartTooltip(partKey, hp, injuries);
            });

            el.addEventListener("click", (e) => {
                const partKey = el.dataset.part;
                const hp = parseInt(el.dataset.health || "100");
                let injuries = [];
                try {
                    injuries = JSON.parse(el.dataset.injuries || "[]");
                } catch(err) { injuries = []; }

                this.showPartTooltip(partKey, hp, injuries);
            });
        });
    }

    showPartTooltip(partKey, hp, injuries) {
        if (!this.tooltip || !this.tooltipBoneName || !this.tooltipBoneHp || !this.tooltipInjuriesList) return;

        const label = this.boneLabels[partKey] || partKey.toUpperCase();
        this.tooltipBoneName.textContent = label.toUpperCase();
        this.tooltipBoneHp.textContent = `${hp}% SALUD`;
        this.tooltipBoneHp.style.color = hp <= 0 ? '#ff007f' : (hp < 40 ? '#f43f5e' : (hp < 75 ? '#fb923c' : (hp < 100 ? '#facc15' : '#10b981')));

        this.tooltipInjuriesList.innerHTML = "";

        if (!injuries || injuries.length === 0) {
            this.tooltipInjuriesList.innerHTML = `<p class="no-injuries">Sin lesiones traumáticas registradas en esta región.</p>`;
        } else {
            injuries.forEach(inj => {
                const item = document.createElement("div");
                item.className = "injury-item";
                item.innerHTML = `
                    <span><i class="fa-solid fa-triangle-exclamation" style="color:${inj.badgeColor || '#ff007f'};"></i> ${inj.severityLabel || inj.typeLabel || 'Traumatismo'}</span>
                    <span class="injury-badge" style="background:${inj.badgeColor ? inj.badgeColor + '33' : 'rgba(255,0,127,0.2)'}; color:${inj.badgeColor || '#ff007f'};">-${inj.damage || 15} HP</span>
                `;
                this.tooltipInjuriesList.appendChild(item);
            });
        }
    }

    // --- ANIMACIÓN ECG OSCILOSCOPIO CANVAS EN VIVO ---
    startEcgAnimation() {
        this.stopEcgAnimation();
        if (!this.canvas || !this.ctx) return;

        this.canvas.width = this.canvas.offsetWidth || 280;
        this.canvas.height = this.canvas.offsetHeight || 90;

        const width = this.canvas.width;
        const height = this.canvas.height;
        const centerY = height / 2;

        let x = 0;
        const points = new Array(width).fill(centerY);

        const animate = () => {
            if (!this.isOpen) return;

            const isDead = this.currentPatient && (this.currentPatient.isDead || (this.currentPatient.health !== undefined && this.currentPatient.health <= 0));
            const bpm = isDead ? 0 : (this.currentPatient ? this.currentPatient.bpm || 72 : 72);

            let newY = centerY;

            if (isDead) {
                // Línea casi plana con leve ruido biológico
                newY = centerY + (Math.random() * 2 - 1);
            } else {
                // Generador de forma de onda P-QRS-T
                const phase = (x % Math.max(25, Math.floor(6000 / bpm))) / Math.max(25, Math.floor(6000 / bpm));

                if (phase >= 0.15 && phase < 0.22) {
                    // Onda P (pequeña elevación auricular)
                    newY = centerY - Math.sin((phase - 0.15) / 0.07 * Math.PI) * 7;
                } else if (phase >= 0.25 && phase < 0.28) {
                    // Onda Q (pequeña deflexión negativa)
                    newY = centerY + 6;
                } else if (phase >= 0.28 && phase < 0.32) {
                    // Complejo QRS (Espiga alta R)
                    newY = centerY - 38;
                } else if (phase >= 0.32 && phase < 0.35) {
                    // Onda S (deflexión negativa post-R)
                    newY = centerY + 14;
                } else if (phase >= 0.45 && phase < 0.60) {
                    // Onda T (repolarización ventricular)
                    newY = centerY - Math.sin((phase - 0.45) / 0.15 * Math.PI) * 11;
                } else {
                    // Línea isoeléctrica con leve ruido
                    newY = centerY + (Math.random() * 1.5 - 0.75);
                }
            }

            points[x] = newY;

            // Limpiar canvas
            this.ctx.fillStyle = "#020712";
            this.ctx.fillRect(0, 0, width, height);

            // Dibujar trazado ECG
            this.ctx.lineWidth = 2.2;
            this.ctx.strokeStyle = isDead ? "#ff2a55" : "#40E0D0";
            this.ctx.shadowColor = isDead ? "#ff007f" : "#40E0D0";
            this.ctx.shadowBlur = 8;
            this.ctx.lineJoin = "round";

            this.ctx.beginPath();
            for (let i = 0; i < width; i++) {
                const drawX = (x + i) % width;
                const drawY = points[drawX];

                if (i === 0) {
                    this.ctx.moveTo(i, drawY);
                } else {
                    this.ctx.lineTo(i, drawY);
                }
            }
            this.ctx.stroke();

            // Puntero de barrido (Cursor brillante)
            this.ctx.fillStyle = "#ffffff";
            this.ctx.beginPath();
            this.ctx.arc(width - 1, points[x], 3, 0, Math.PI * 2);
            this.ctx.fill();

            x = (x + 2) % width;
            this.ecgAnimationId = requestAnimationFrame(animate);
        };

        this.ecgAnimationId = requestAnimationFrame(animate);
    }

    stopEcgAnimation() {
        if (this.ecgAnimationId) {
            cancelAnimationFrame(this.ecgAnimationId);
            this.ecgAnimationId = null;
        }
    }

    // --- ACCIONES MÉDICAS RÁPIDAS (BARRAS DE PROGRESO INTERACTIVAS) ---
    async handleTourniquet() {
        if (!this.currentPatient || !this.btnTourniquet) return;
        if (this.btnTourniquet.classList.contains("in-progress") || this.btnTourniquet.classList.contains("completed")) return;

        if (this.currentPatient.hasTourniquet || this.currentPatient.isTourniquetApplied) {
            showToast("El paciente ya tiene un torniquete de compresión colocado.", true);
            return;
        }

        // 1. Iniciar transformación en Barra de Carga
        this.btnTourniquet.classList.add("in-progress");
        this.btnTourniquet.innerHTML = `
            <div class="btn-progress-track"></div>
            <div class="btn-progress-fill tourniquet-fill" id="btnTourniquetFill" style="width: 0%;"></div>
            <span class="btn-progress-content" id="btnTourniquetText">
                <i class="fa-solid fa-spinner fa-spin"></i> Colocando Torniquete... <strong id="tourniquetPct">0%</strong>
            </span>
        `;

        const fillEl = document.getElementById("btnTourniquetFill");
        const pctEl = document.getElementById("tourniquetPct");

        // Animar barra de carga durante 3.5 segundos
        const totalDuration = 3500;
        const intervalTime = 50;
        let elapsed = 0;

        const progressInterval = setInterval(() => {
            elapsed += intervalTime;
            const pct = Math.min(100, Math.floor((elapsed / totalDuration) * 100));
            if (fillEl) fillEl.style.width = `${pct}%`;
            if (pctEl) pctEl.textContent = `${pct}%`;

            if (elapsed >= totalDuration) {
                clearInterval(progressInterval);
            }
        }, intervalTime);

        // Disparar acción en cliente Lua
        const res = await postFetch('applyTourniquetFromModal', {
            targetSrc: this.currentPatient.targetSrc,
            dummyId: this.currentPatient.dummyId
        });

        clearInterval(progressInterval);

        if (res && res.success) {
            if (fillEl) fillEl.style.width = "100%";
            if (pctEl) pctEl.textContent = "100%";

            setTimeout(() => {
                this.btnTourniquet.classList.remove("in-progress");
                this.btnTourniquet.classList.add("completed");
                this.btnTourniquet.innerHTML = `
                    <i class="fa-solid fa-check"></i>
                    <span>Torniquete C-A-T Aplicado</span>
                `;

                if (this.currentPatient) {
                    this.currentPatient.hasTourniquet = true;
                    this.currentPatient.isTourniquetApplied = true;
                    this.currentPatient.bleedingLevel = "Detenida / Ocluida con Torniquete C-A-T";
                    this.updateData(this.currentPatient);
                }
                showToast(res.message || "Torniquete táctico fijado correctamente. Hemorragia ocluida.", false);
            }, 300);
        } else {
            this.btnTourniquet.classList.remove("in-progress");
            this.btnTourniquet.innerHTML = `
                <i class="fa-solid fa-bandage"></i>
                <span>Aplicar Torniquete C-A-T</span>
            `;
            showToast((res && res.message) || "No dispones de un torniquete táctico en tu inventario.", true);
        }
    }

    async handleDefib() {
        if (!this.currentPatient || !this.btnDefib) return;
        if (this.btnDefib.classList.contains("in-progress") || this.btnDefib.classList.contains("completed")) return;

        if (!this.currentPatient.isDead && (this.currentPatient.bpm && this.currentPatient.bpm > 0)) {
            showToast("El paciente presenta ritmo sinusal activo. No se aconseja descarga.", true);
            return;
        }

        // 1. Iniciar transformación en Barra de Carga de Condensador DEA (200 Joules)
        this.btnDefib.classList.add("in-progress");
        this.btnDefib.innerHTML = `
            <div class="btn-progress-track"></div>
            <div class="btn-progress-fill defib-fill" id="btnDefibFill" style="width: 0%;"></div>
            <span class="btn-progress-content" id="btnDefibText">
                <i class="fa-solid fa-bolt fa-beat"></i> CARGANDO DEA (200J)... <strong id="defibPct">0%</strong>
            </span>
        `;

        const fillEl = document.getElementById("btnDefibFill");
        const pctEl = document.getElementById("defibPct");
        const textEl = document.getElementById("btnDefibText");

        const chargeDuration = 2500;
        const intervalTime = 50;
        let elapsed = 0;

        const chargeInterval = setInterval(() => {
            elapsed += intervalTime;
            const pct = Math.min(100, Math.floor((elapsed / chargeDuration) * 100));
            if (fillEl) fillEl.style.width = `${pct}%`;
            if (pctEl) pctEl.textContent = `${pct}%`;

            if (elapsed >= chargeDuration) {
                clearInterval(chargeInterval);
                if (textEl) {
                    textEl.innerHTML = `<i class="fa-solid fa-bolt-lightning"></i> ¡DESCARGA LISTA - DESPEJEN!`;
                }
            }
        }, intervalTime);

        // Disparar protocolo DEA en cliente Lua
        const res = await postFetch('useDefibFromModal', {
            targetSrc: this.currentPatient.targetSrc,
            dummyId: this.currentPatient.dummyId
        });

        clearInterval(chargeInterval);

        if (res && res.success) {
            if (fillEl) fillEl.style.width = "100%";
            setTimeout(() => {
                this.btnDefib.classList.remove("in-progress");
                this.btnDefib.classList.add("completed");
                this.btnDefib.innerHTML = `
                    <i class="fa-solid fa-heart-circle-check text-cyan"></i>
                    <span>Ritmo Sinusal (78 BPM)</span>
                `;

                if (this.currentPatient) {
                    this.currentPatient.isDead = false;
                    this.currentPatient.bpm = 78;
                    this.currentPatient.bloodPressure = "120/80 mmHg";
                    this.currentPatient.spo2 = 98;
                    this.currentPatient.glasgow = 15;
                    this.currentPatient.health = 100;
                    this.currentPatient.bleedingLevel = "Estable / Sin Hemorragias";
                    this.currentPatient.boneDamage = {
                        head: { health: 100, injuries: [] },
                        torso: { health: 100, injuries: [] },
                        right_arm: { health: 100, injuries: [] },
                        left_arm: { health: 100, injuries: [] },
                        right_hand: { health: 100, injuries: [] },
                        left_hand: { health: 100, injuries: [] },
                        right_leg: { health: 100, injuries: [] },
                        left_leg: { health: 100, injuries: [] },
                        right_foot: { health: 100, injuries: [] },
                        left_foot: { health: 100, injuries: [] }
                    };
                    this.updateData(this.currentPatient);
                }
                showToast(res.message || "¡Descarga sincronizada efectiva! Ritmo sinusal recuperado.", false);
            }, 500);
        } else {
            this.btnDefib.classList.remove("in-progress");
            this.btnDefib.innerHTML = `
                <i class="fa-solid fa-heart-pulse"></i>
                <span>Desfibrilador (DEA)</span>
            `;
            showToast((res && res.message) || "Fallo en la descarga o no dispones del desfibrilador en tu inventario.", true);
        }
    }

    async handleSaveRecord() {
        if (!this.currentPatient) return;
        const patient = this.currentPatient;

        // Abrir modal de nuevo informe clínico prellenando los datos del paciente
        const modal = document.getElementById("modalNewRecord");
        if (modal) {
            document.getElementById("newRecPatientName").value = patient.name || "Paciente Anónimo";
            document.getElementById("newRecCitizenId").value = patient.citizenid || "HLWWIZKU";
            
            // Generar informe automático detallado
            let diagSummary = `[EVALUACIÓN MÉDICA EMS]\n• Estado Clínico: ${patient.isDead ? 'Parada Cardiorrespiratoria (PCR)' : 'Consciente y Orientado (GCS 15/15)'}\n• Constantes: FC ${patient.bpm || 0} BPM | TA ${patient.bloodPressure || '120/80 mmHg'} | SpO2 ${patient.spo2 || 98}%\n• Temperatura Corporal: ${patient.temperature || 36.8}ºC (Aislamiento: ${Math.round(patient.insulation || 0)}/100)\n• Lesiones Óseas: `;
            
            let injuriesFound = [];
            if (patient.boneDamage) {
                for (let k in patient.boneDamage) {
                    if (patient.boneDamage[k].health < 100) {
                        injuriesFound.push(`${this.boneLabels[k] || k} (${patient.boneDamage[k].health}% HP)`);
                    }
                }
            }
            diagSummary += injuriesFound.length > 0 ? injuriesFound.join(", ") : "Sin fracturas detectadas.";
            
            document.getElementById("newRecDiagnosis").value = diagSummary;
            modal.classList.remove("hidden");

            // Ocultar solo el panel del diagnóstico sin desconectar el foco NUI
            if (this.wrapper) {
                this.wrapper.classList.add("hidden");
            }
            this.isOpen = false;
            this.stopEcgAnimation();
        }
    }
}

// ============================================================================
// 2.5. EMS FLEET COMMAND GARAGE (PARQUE MÓVIL SANITARIO)
// ============================================================================

const EMS_GRADE_TITLES = {
    0: "Enfermero en Prácticas",
    1: "Paramédico",
    2: "Médico Titular",
    3: "Cirujano Especialista",
    4: "Director Médico"
};

const EMS_CATEGORY_ICONS = {
    "Ambulancia": "fa-truck-medical",
    "Intervención": "fa-car-side",
    "Rescate": "fa-truck-pickup",
    "Jefatura": "fa-shield-halved",
    "Aéreo": "fa-helicopter"
};

class EmsGarageApp {
    constructor() {
        this.appEl = document.getElementById("garageApp");
        this.gridEl = document.getElementById("vehiclesGrid");
        this.categoryPillsEl = document.getElementById("categoryPills");
        this.stationLabelEl = document.getElementById("stationLabel");
        this.officerNameEl = document.getElementById("officerName");
        this.officerGradeLabelEl = document.getElementById("officerGradeLabel");
        this.vehicleCountBadgeEl = document.getElementById("vehicleCountBadge");

        this.currentCategory = "all";
        this.vehicles = [];
        this.doctorGrade = 0;
        this.doctorName = "Personal Médico";
        this.stationName = "Hospital General de Los Santos";

        this.audioCtx = null;

        this.initEvents();
    }

    initEvents() {
        window.addEventListener("message", (event) => {
            const data = event.data;
            if (data.action === "openEmsGarage") {
                this.vehicles = data.vehicles || [];
                this.doctorGrade = data.doctorGrade || 0;
                this.doctorName = data.doctorName || "Personal Médico";
                this.stationName = data.stationName || "Hospital General de Los Santos";

                if (this.stationLabelEl) this.stationLabelEl.innerText = this.stationName;
                if (this.officerNameEl) this.officerNameEl.innerText = this.doctorName;
                
                const gradeTitle = EMS_GRADE_TITLES[this.doctorGrade] || `Grado ${this.doctorGrade}`;
                if (this.officerGradeLabelEl) this.officerGradeLabelEl.innerText = `Grado ${this.doctorGrade} - ${gradeTitle}`;

                this.currentCategory = "all";
                this.renderCategories();
                this.renderVehicles();

                if (this.appEl) this.appEl.classList.remove("hidden");
                this.playAudio("open");
            } else if (data.action === "closeEmsGarage") {
                this.hideUI();
            }
        });

        // ESC Key to close
        window.addEventListener("keydown", (e) => {
            if ((e.key === "Escape" || e.key === "Esc") && this.appEl && !this.appEl.classList.contains("hidden")) {
                this.close();
            }
        });

        // Close button
        const btnClose = document.getElementById("btnCloseGarage");
        if (btnClose) {
            btnClose.addEventListener("click", () => {
                this.close();
            });
        }

        // Store current vehicle button
        const btnStore = document.getElementById("btnStoreVehicle");
        if (btnStore) {
            btnStore.addEventListener("click", () => {
                this.playAudio("click");
                this.hideUI();
                postFetch("storeVehicle", {});
            });
        }

        // Category pills click
        if (this.categoryPillsEl) {
            this.categoryPillsEl.addEventListener("click", (e) => {
                const pill = e.target.closest(".cat-pill");
                if (!pill) return;

                this.categoryPillsEl.querySelectorAll(".cat-pill").forEach(p => p.classList.remove("active"));
                pill.classList.add("active");
                this.currentCategory = pill.dataset.cat;
                this.playAudio("click");
                this.renderVehicles();
            });
        }
    }

    hideUI() {
        if (this.appEl) this.appEl.classList.add("hidden");
        this.playAudio("close");
    }

    close() {
        this.hideUI();
        postFetch("closeGarage", {});
    }

    renderCategories() {
        if (!this.categoryPillsEl) return;
        this.categoryPillsEl.querySelectorAll(".cat-pill").forEach((pill, idx) => {
            pill.classList.toggle("active", idx === 0);
        });
    }

    renderVehicles() {
        if (!this.gridEl) return;
        this.gridEl.innerHTML = "";

        const filtered = this.vehicles.filter(v => {
            if (this.currentCategory === "all") return true;
            if (this.currentCategory === "Aereo") return (v.category && (v.category.includes("Aéreo") || v.category.includes("Aereo") || v.category.includes("Air")));
            return v.category && v.category.toLowerCase().includes(this.currentCategory.toLowerCase());
        });

        if (this.vehicleCountBadgeEl) {
            this.vehicleCountBadgeEl.innerText = `Mostrando ${filtered.length} de ${this.vehicles.length} vehículos`;
        }

        if (filtered.length === 0) {
            this.gridEl.innerHTML = `
                <div style="grid-column: 1/-1; text-align: center; padding: 60px 20px; color: var(--text-muted);">
                    <i class="fa-solid fa-truck-medical" style="font-size: 40px; margin-bottom: 12px; color: var(--accent-cyan);"></i>
                    <h3>No hay vehículos disponibles en esta categoría</h3>
                    <p style="font-size: 13px; margin-top: 6px;">Selecciona otra categoría o pulsa en "Todos los Vehículos".</p>
                </div>
            `;
            return;
        }

        filtered.forEach(veh => {
            const isUnlocked = this.doctorGrade >= (veh.minGrade || 0);
            const catIcon = veh.icon || EMS_CATEGORY_ICONS[veh.category] || "fa-truck-medical";

            const card = document.createElement("div");
            card.className = `vehicle-card ${isUnlocked ? "" : "locked"}`;
            card.innerHTML = `
                <div class="card-top">
                    <span class="card-cat-badge">${veh.category || 'Sanitario'}</span>
                    <div class="card-rank-badge ${isUnlocked ? "unlocked" : "locked"}">
                        <i class="fa-solid ${isUnlocked ? "fa-unlock" : "fa-lock"}"></i>
                        <span>${isUnlocked ? "Rango Requerido: Grado " + (veh.minGrade || 0) : "Bloqueado: Grado " + (veh.minGrade || 0) + "+"}</span>
                    </div>
                </div>

                <div class="card-hero">
                    <div class="card-icon-box">
                        <i class="${catIcon.startsWith('fa-') ? catIcon : 'fa-solid ' + catIcon}"></i>
                    </div>
                    <div class="card-titles">
                        <div class="card-title">${veh.label}</div>
                        <div class="card-model-code">Modelo: ${veh.model}</div>
                    </div>
                </div>

                <div class="card-desc">${veh.desc || "Dotación reglamentaria del servicio de emergencias sanitarias."}</div>

                <div class="card-specs">
                    <span class="spec-pill"><i class="fa-solid fa-heart-pulse"></i> Soporte Vital</span>
                    <span class="spec-pill"><i class="fa-solid fa-satellite-dish"></i> GPS / Radio</span>
                    <span class="spec-pill"><i class="fa-solid fa-kit-medical"></i> Botiquín Trauma</span>
                </div>

                <button class="card-action-btn ${isUnlocked ? "btn-spawn" : "btn-locked"}" ${isUnlocked ? "" : "disabled"}>
                    <i class="fa-solid ${isUnlocked ? "fa-key" : "fa-lock"}"></i>
                    <span>${isUnlocked ? "SACAR VEHÍCULO" : "RANGO INSUFICIENTE"}</span>
                </button>
            `;

            if (isUnlocked) {
                const btn = card.querySelector(".btn-spawn");
                if (btn) {
                    btn.addEventListener("click", () => {
                        this.playAudio("spawn");
                        this.hideUI();
                        postFetch("spawnVehicle", { model: veh.model });
                    });
                }
            }

            this.gridEl.appendChild(card);
        });
    }

    playAudio(type) {
        try {
            if (!this.audioCtx) {
                this.audioCtx = new (window.AudioContext || window.webkitAudioContext)();
            }
            if (this.audioCtx.state === "suspended") {
                this.audioCtx.resume();
            }

            const osc = this.audioCtx.createOscillator();
            const gain = this.audioCtx.createGain();
            osc.connect(gain);
            gain.connect(this.audioCtx.destination);

            const now = this.audioCtx.currentTime;
            if (type === "open") {
                osc.type = "sine";
                osc.frequency.setValueAtTime(440, now);
                osc.frequency.exponentialRampToValueAtTime(880, now + 0.12);
                gain.gain.setValueAtTime(0.06, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.12);
                osc.start(now);
                osc.stop(now + 0.12);
            } else if (type === "spawn") {
                osc.type = "triangle";
                osc.frequency.setValueAtTime(523.25, now);
                osc.frequency.exponentialRampToValueAtTime(1046.5, now + 0.2);
                gain.gain.setValueAtTime(0.08, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.2);
                osc.start(now);
                osc.stop(now + 0.2);
            } else if (type === "click") {
                osc.type = "sine";
                osc.frequency.setValueAtTime(650, now);
                gain.gain.setValueAtTime(0.04, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.05);
                osc.start(now);
                osc.stop(now + 0.05);
            } else if (type === "close") {
                osc.type = "sine";
                osc.frequency.setValueAtTime(700, now);
                osc.frequency.exponentialRampToValueAtTime(350, now + 0.1);
                gain.gain.setValueAtTime(0.05, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.1);
                osc.start(now);
                osc.stop(now + 0.1);
            }
        } catch (e) {}
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
    window.emsGarageApp = new EmsGarageApp();
    window.emsMdt = new EmsMDT();
    window.diagnosticModal = new DiagnosticModal();
});

