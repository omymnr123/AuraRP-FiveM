// ============================================================================
// AuraRP - Police Fleet Command NUI Controller
// ============================================================================

const GRADE_TITLES = {
    0: "Cadete",
    1: "Oficial",
    2: "Sargento",
    3: "Teniente",
    4: "Detective",
    5: "Comisario"
};

const CATEGORY_ICONS = {
    "Cruiser": "fa-car-side",
    "Interceptor": "fa-gauge-high",
    "Encubierto": "fa-user-secret",
    "Transporte": "fa-van-shuttle",
    "SWAT": "fa-shield",
    "SUV Blindado": "fa-truck-monster",
    "Aéreo": "fa-helicopter"
};

class PoliceGarageApp {
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
        this.officerGrade = 0;
        this.officerName = "Oficial";
        this.stationName = "Comisaría Central - Mission Row";

        this.audioCtx = null;

        this.initEvents();
    }

    initEvents() {
        // Message listener from Lua client
        window.addEventListener("message", (event) => {
            const data = event.data;
            if (data.action === "openPoliceGarage") {
                this.vehicles = data.vehicles || [];
                this.officerGrade = data.officerGrade || 0;
                this.officerName = data.officerName || "Oficial";
                this.stationName = data.stationName || "Comisaría Central - Mission Row";

                this.stationLabelEl.innerText = this.stationName;
                this.officerNameEl.innerText = this.officerName;
                
                const gradeTitle = GRADE_TITLES[this.officerGrade] || `Grado ${this.officerGrade}`;
                this.officerGradeLabelEl.innerText = `Grado ${this.officerGrade} - ${gradeTitle}`;

                this.currentCategory = "all";
                this.renderCategories();
                this.renderVehicles();

                this.appEl.classList.remove("hidden");
                this.playAudio("open");
            } else if (data.action === "closePoliceGarage") {
                this.hideUI();
            }
        });

        // ESC Key to close
        window.addEventListener("keydown", (e) => {
            if (e.key === "Escape" || e.key === "Esc") {
                this.close();
            }
        });

        // Close button
        document.getElementById("btnCloseGarage").addEventListener("click", () => {
            this.close();
        });

        // Store current vehicle button
        document.getElementById("btnStoreVehicle").addEventListener("click", () => {
            this.playAudio("click");
            this.hideUI();
            fetch(`https://${GetParentResourceName()}/storeVehicle`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({})
            }).catch(() => {});
        });

        // Category pills click
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

    hideUI() {
        this.appEl.classList.add("hidden");
        this.playAudio("close");
    }

    close() {
        this.hideUI();
        fetch(`https://${GetParentResourceName()}/closeGarage`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({})
        }).catch(() => {});
    }

    renderCategories() {
        // Reset active state to 'all'
        this.categoryPillsEl.querySelectorAll(".cat-pill").forEach((pill, idx) => {
            pill.classList.toggle("active", idx === 0);
        });
    }

    renderVehicles() {
        this.gridEl.innerHTML = "";

        const filtered = this.vehicles.filter(v => {
            if (this.currentCategory === "all") return true;
            if (this.currentCategory === "SWAT") return v.category.includes("SWAT") || v.category.includes("Blindado");
            if (this.currentCategory === "Aereo") return v.category.includes("Aérea") || v.category.includes("Air");
            return v.category.toLowerCase().includes(this.currentCategory.toLowerCase());
        });

        this.vehicleCountBadgeEl.innerText = `Mostrando ${filtered.length} de ${this.vehicles.length} vehículos`;

        if (filtered.length === 0) {
            this.gridEl.innerHTML = `
                <div style="grid-column: 1/-1; text-align: center; padding: 60px 20px; color: var(--text-muted);">
                    <i class="fa-solid fa-car-tunnel" style="font-size: 40px; margin-bottom: 12px; color: var(--border-cyan);"></i>
                    <h3>No hay vehículos disponibles en esta categoría</h3>
                    <p style="font-size: 13px; margin-top: 6px;">Selecciona otra categoría o pulsa en "Todos los Vehículos".</p>
                </div>
            `;
            return;
        }

        filtered.forEach(veh => {
            const isUnlocked = this.officerGrade >= veh.minGrade;
            const catIcon = CATEGORY_ICONS[veh.category] || "fa-car";

            const card = document.createElement("div");
            card.className = `vehicle-card ${isUnlocked ? "" : "locked"}`;
            card.innerHTML = `
                <div class="card-top">
                    <span class="card-cat-badge">${veh.category}</span>
                    <div class="card-rank-badge ${isUnlocked ? "unlocked" : "locked"}">
                        <i class="fa-solid ${isUnlocked ? "fa-unlock" : "fa-lock"}"></i>
                        <span>${isUnlocked ? "Rango Requerido: Grado " + veh.minGrade : "Bloqueado: Grado " + veh.minGrade + "+"}</span>
                    </div>
                </div>

                <div class="card-hero">
                    <div class="card-icon-box">
                        <i class="fa-solid ${catIcon}"></i>
                    </div>
                    <div class="card-titles">
                        <div class="card-title">${veh.label}</div>
                        <div class="card-model-code">Modelo: ${veh.model}</div>
                    </div>
                </div>

                <div class="card-desc">${veh.desc || "Unidad policial de dotación reglamentaria LSPD."}</div>

                <div class="card-specs">
                    <span class="spec-pill"><i class="fa-solid fa-bolt"></i> Reforzado</span>
                    <span class="spec-pill"><i class="fa-solid fa-satellite-dish"></i> GPS / Radio</span>
                    <span class="spec-pill"><i class="fa-solid fa-shield"></i> LSPD Spec</span>
                </div>

                <button class="card-action-btn ${isUnlocked ? "btn-spawn" : "btn-locked"}" ${isUnlocked ? "" : "disabled"}>
                    <i class="fa-solid ${isUnlocked ? "fa-key" : "fa-lock"}"></i>
                    <span>${isUnlocked ? "SACAR PATRULLA" : "RANGO INSUFICIENTE"}</span>
                </button>
            `;

            if (isUnlocked) {
                const btn = card.querySelector(".btn-spawn");
                btn.addEventListener("click", () => {
                    this.playAudio("spawn");
                    this.hideUI();
                    fetch(`https://${GetParentResourceName()}/spawnVehicle`, {
                        method: "POST",
                        headers: { "Content-Type": "application/json" },
                        body: JSON.stringify({ model: veh.model })
                    }).catch(() => {});
                });
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

            if (type === "click") {
                osc.frequency.setValueAtTime(800, now);
                osc.frequency.exponentialRampToValueAtTime(1200, now + 0.04);
                gain.gain.setValueAtTime(0.06, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.04);
                osc.start(now);
                osc.stop(now + 0.04);
            } else if (type === "spawn") {
                osc.frequency.setValueAtTime(450, now);
                osc.frequency.exponentialRampToValueAtTime(880, now + 0.12);
                gain.gain.setValueAtTime(0.12, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.12);
                osc.start(now);
                osc.stop(now + 0.12);
            } else if (type === "open") {
                osc.frequency.setValueAtTime(300, now);
                osc.frequency.exponentialRampToValueAtTime(600, now + 0.08);
                gain.gain.setValueAtTime(0.08, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.08);
                osc.start(now);
                osc.stop(now + 0.08);
            }
        } catch (e) {}
    }
}

// ============================================================================
// AuraRP - Tactical Dispatch HUD & Active Calls Board Manager
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

        const isGunshot = alert.type === 'gunshot';
        const card = document.createElement("div");
        card.className = `dispatch-alert-card ${isGunshot ? 'gunshot' : 'theft'}`;

        card.innerHTML = `
            <div class="dispatch-glow-strip"></div>
            <div class="dispatch-card-inner">
                <div class="dispatch-icon-badge ${isGunshot ? 'gun-icon-red' : 'veh-icon-orange'}">
                    <i class="fa-solid ${isGunshot ? 'fa-gun' : 'fa-car-side'}"></i>
                </div>
                <div class="dispatch-content">
                    <div class="dispatch-meta-row">
                        <span class="dispatch-code ${isGunshot ? 'code-red' : 'code-orange'}">${alert.code}</span>
                        <span class="dispatch-time"><i class="fa-regular fa-clock"></i> ${alert.time || 'AHORA'}</span>
                    </div>
                    <div class="dispatch-title-row">
                        <span class="dispatch-title">${alert.title}</span>
                    </div>
                    <div class="dispatch-location-row">
                        <i class="fa-solid fa-location-dot"></i>
                        <span>${alert.street} <strong class="zone-highlight">(${alert.zone})</strong></span>
                    </div>
                    ${alert.plate ? `
                        <div class="dispatch-plate-tag">
                            <i class="fa-solid fa-car"></i> Matrícula: <strong>${alert.plate}</strong> <span style="color:#64748b;">|</span> ${alert.model || 'Vehículo'}
                        </div>
                    ` : ''}
                    <div class="dispatch-footer-tip">
                        <div class="dispatch-pill-btn">
                            <kbd>G</kbd> <span>ACUDIR / GPS</span>
                        </div>
                        <div class="dispatch-pill-btn alt">
                            <kbd>U</kbd> <span>CENTRAL 911</span>
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
                fetch(`https://${GetParentResourceName()}/getDispatchBoardCalls`, {
                    method: 'POST',
                    body: JSON.stringify({})
                }).catch(() => {});
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
        fetch(`https://${GetParentResourceName()}/closeDispatchBoard`, {
            method: 'POST',
            body: JSON.stringify({})
        }).catch(() => {});
    }

    renderCalls() {
        if (!this.listEl) return;
        this.listEl.innerHTML = "";

        if (!this.calls || this.calls.length === 0) {
            this.listEl.innerHTML = `
                <div class="board-empty-state">
                    <i class="fa-solid fa-shield-halved"></i>
                    <h4>Sin Incidentes Activos</h4>
                    <p>La central de emergencias no registra llamadas de despacho pendientes en este momento.</p>
                </div>
            `;
            return;
        }

        this.calls.forEach(call => {
            const isGunshot = call.type === 'gunshot';
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
                        <span class="board-code-pill ${isGunshot ? 'red' : 'orange'}">${call.code}</span>
                        <h4 class="board-call-title">${call.title}</h4>
                        <span class="board-call-time"><i class="fa-regular fa-clock"></i> ${call.time}</span>
                    </div>
                    <div class="board-status-pill ${statusPillClass}">
                        <span class="pulse-dot"></span>
                        <span>${statusLabel}</span>
                    </div>
                </div>

                <div class="board-card-body">
                    <div class="board-loc-row">
                        <i class="fa-solid fa-location-dot"></i>
                        <span>${call.street} <strong>(${call.zone})</strong></span>
                    </div>
                    ${call.plate ? `
                        <div class="board-veh-tag">
                            <i class="fa-solid fa-car"></i> Matrícula: <strong>${call.plate}</strong> | Modelo: <span>${call.model || 'Desconocido'}</span>
                        </div>
                    ` : ''}
                    <p class="board-call-desc">${call.description || ''}</p>
                </div>

                <div class="board-units-section">
                    <div class="board-units-label">
                        <i class="fa-solid fa-car-side"></i> Patrullas en camino (${units.length}/${maxUnits}):
                    </div>
                    <div class="board-units-list">
                        ${units.length > 0 ? units.map(u => `
                            <span class="unit-badge ${u.src === this.mySrc ? 'my-unit' : ''}">
                                <i class="fa-solid fa-user-shield"></i> ${u.name} <small>(${u.callsign || 'UNIT'})</small>
                            </span>
                        `).join('') : '<span class="no-units-text">Ninguna patrulla asignada todavía</span>'}
                    </div>
                </div>

                <div class="board-card-actions">
                    <button class="btn-board-action gps" onclick="window.dispatchBoardApp.setGps(${call.coords ? call.coords.x : 0}, ${call.coords ? call.coords.y : 0})">
                        <i class="fa-solid fa-location-crosshairs"></i>
                        <span>Fijar GPS</span>
                    </button>

                    ${!isResolved ? `
                        ${amIAttending ? `
                            <button class="btn-board-action cancel" onclick="window.dispatchBoardApp.cancelCall(${call.id})">
                                <i class="fa-solid fa-user-xmark"></i>
                                <span>Cancelar Respuesta</span>
                            </button>
                        ` : `
                            <button class="btn-board-action respond ${isFull ? 'disabled' : ''}" ${isFull ? 'disabled' : ''} onclick="window.dispatchBoardApp.respondCall(${call.id})">
                                <i class="fa-solid fa-shield-heart"></i>
                                <span>${isFull ? 'Cupo Completo' : 'Acudir / Responder'}</span>
                            </button>
                        `}

                        <button class="btn-board-action resolve" onclick="window.dispatchBoardApp.resolveCall(${call.id})">
                            <i class="fa-solid fa-check-double"></i>
                            <span>Marcar Resuelto</span>
                        </button>
                    ` : ''}
                </div>
            `;

            this.listEl.appendChild(card);
        });
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

    respondCall(callId) {
        fetch(`https://${GetParentResourceName()}/respondDispatchCall`, {
            method: 'POST',
            body: JSON.stringify({ callId: callId })
        }).catch(() => {});
    }

    cancelCall(callId) {
        fetch(`https://${GetParentResourceName()}/cancelDispatchCall`, {
            method: 'POST',
            body: JSON.stringify({ callId: callId })
        }).catch(() => {});
    }

    resolveCall(callId) {
        fetch(`https://${GetParentResourceName()}/resolveDispatchCall`, {
            method: 'POST',
            body: JSON.stringify({ callId: callId })
        }).catch(() => {});
    }

    setGps(x, y) {
        fetch(`https://${GetParentResourceName()}/setDispatchGps`, {
            method: 'POST',
            body: JSON.stringify({ x: x, y: y })
        }).catch(() => {});
    }
}

document.addEventListener("DOMContentLoaded", () => {
    window.PoliceGarageApp = new PoliceGarageApp();
    window.DispatchHUD = new DispatchHUD();
    window.dispatchBoardApp = new DispatchBoard();
});

