// ============================================================================
// AuraRP - Police Fleet Command NUI Controller
// ============================================================================

const GRADE_TITLES = {
    0: "Cadete",
    1: "Oficial I",
    2: "Oficial II",
    3: "Sargento",
    4: "Teniente",
    5: "Capitán",
    6: "Jefe de Policía"
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

document.addEventListener("DOMContentLoaded", () => {
    window.PoliceGarageApp = new PoliceGarageApp();
});
