/* ============================================================================
   AURA MEDICAL: JAVASCRIPT CONTROLLER (PHASE 11: P2P MEDICAL DIAGNOSTICS & 3D SCANNER)
   Synchronized Dual-View NUI & 3D Holographic Body Telemetry
   ============================================================================ */

class AuraMedicalApp {
  constructor() {
    this.mode = 'patient'; // 'patient', 'ems', o 'scanner'
    this.isMale = true;
    this.selectedZone = 'head';
    this.medicSrc = null;
    this.patientSrc = null;
    this.patientName = 'Paciente';
    this.currentBpm = 75;

    // Estado del Escáner 3D
    this.isScannerOpen = false;
    this.scannerBones = {};
    this.scannerBoneConfig = {};
    this.selectedScannerLimb = 'head';
    this.cachedNodeElements = {};
    
    // Diccionario de lesiones por cada una de las 10 zonas anatómicas diferenciadas
    this.injuries = {
      head: [],
      torso: [],
      right_arm: [],
      left_arm: [],
      right_hand: [],
      left_hand: [],
      right_leg: [],
      left_leg: [],
      right_foot: [],
      left_foot: []
    };

    // Configuración recibida de Lua (con fallbacks estables)
    this.zonesConfig = {
      head: { id: "head", label: "Cabeza y Cuello", icon: "fa-solid fa-head-side-medical", desc: "Región craneoencefálica, macizo facial y vértebras cervicales." },
      torso: { id: "torso", label: "Tronco y Tórax", icon: "fa-solid fa-lungs", desc: "Caja torácica, órganos vitales, abdomen y columna dorsal." },
      right_arm: { id: "right_arm", label: "Brazo Derecho", icon: "fa-solid fa-hand-fist", desc: "Húmero derecho, cúbito, radio y articulación del codo derecho." },
      left_arm: { id: "left_arm", label: "Brazo Izquierdo", icon: "fa-solid fa-hand-fist", desc: "Húmero izquierdo, cúbito, radio y articulación del codo izquierdo." },
      right_hand: { id: "right_hand", label: "Mano Derecha", icon: "fa-solid fa-hands", desc: "Carpianos, metacarpianos y falanges de la mano derecha." },
      left_hand: { id: "left_hand", label: "Mano Izquierda", icon: "fa-solid fa-hands", desc: "Carpianos, metacarpianos y falanges de la mano izquierda." },
      right_leg: { id: "right_leg", label: "Pierna Derecha", icon: "fa-solid fa-person-running", desc: "Fémur derecho, rótula, tibia, peroné y cuádriceps derecho." },
      left_leg: { id: "left_leg", label: "Pierna Izquierda", icon: "fa-solid fa-person-running", desc: "Fémur izquierdo, rótula, tibia, peroné y cuádriceps izquierdo." },
      right_foot: { id: "right_foot", label: "Pie Derecho", icon: "fa-solid fa-shoe-prints", desc: "Tarso, metatarso y falanges del pie derecho." },
      left_foot: { id: "left_foot", label: "Pie Izquierdo", icon: "fa-solid fa-shoe-prints", desc: "Tarso, metatarso y falanges del pie izquierdo." }
    };

    this.injuryTypesConfig = {
      contusion: { id: "contusion", label: "Contusión", desc: "Impacto con hematoma subcutáneo.", treatment: "Aplicar Compresa Fría", icon: "fa-solid fa-snowflake" },
      scratch: { id: "scratch", label: "Rasguño superficial", desc: "Abrasión epidérmica con sangrado leve.", treatment: "Desinfectar y Vendar", icon: "fa-solid fa-bandage" },
      puncture: { id: "puncture", label: "Herida punzante", desc: "Perforación profunda por objeto afilado.", treatment: "Cauterizar y Suturar", icon: "fa-solid fa-syringe" },
      bullet: { id: "bullet", label: "Herida de bala", desc: "Impacto balístico con sangrado activo.", treatment: "Extraer Proyectil", icon: "fa-solid fa-crosshairs" },
      bone_break: { id: "bone_break", label: "Rotura de hueso", desc: "Fractura ósea o fisura estructural.", treatment: "Entablillar Fractura", icon: "fa-solid fa-bone" },
      sprain: { id: "sprain", label: "Esguince", desc: "Distensión ligamentosa aguda.", treatment: "Vendaje Compresivo", icon: "fa-solid fa-tape" },
      burn: { id: "burn", label: "Quemadura", desc: "Lesión dérmica térmica.", treatment: "Aplicar Pomada Dérmica", icon: "fa-solid fa-fire-flame-curved" },
      muscle_tear: { id: "muscle_tear", label: "Desgarro muscular", desc: "Ruptura fibrilar muscular aguda.", treatment: "Infiltración Muscular", icon: "fa-solid fa-heart-pulse" }
    };

    this.stableBpmRange = { min: 60, max: 100 };

    this.initDOMElements();
    this.bindEvents();
  }

  initDOMElements() {
    // Modo 1: Escáner 3D
    this.scannerApp = document.getElementById('scannerApp');
    this.btnCloseScanner = document.getElementById('btnCloseScanner');
    this.scannerNodesContainer = document.getElementById('scannerNodesContainer');
    this.scannerGeneralStatus = document.getElementById('scannerGeneralStatus');
    this.scannerVitalityCircle = document.getElementById('scannerVitalityCircle');
    this.scannerVitalityVal = document.getElementById('scannerVitalityVal');
    this.scannerBpm = document.getElementById('scannerBpm');
    this.scannerArmor = document.getElementById('scannerArmor');
    this.scannerTempStatus = document.getElementById('scannerTempStatus');
    this.scannerTempVal = document.getElementById('scannerTempVal');
    this.scannerHungerVal = document.getElementById('scannerHungerVal');
    this.scannerHungerBar = document.getElementById('scannerHungerBar');
    this.scannerThirstVal = document.getElementById('scannerThirstVal');
    this.scannerThirstBar = document.getElementById('scannerThirstBar');
    this.scannerLimbName = document.getElementById('scannerLimbName');
    this.scannerLimbHealthBadge = document.getElementById('scannerLimbHealthBadge');
    this.scannerLimbDesc = document.getElementById('scannerLimbDesc');
    this.scannerLimbStatusBox = document.getElementById('scannerLimbStatusBox');
    this.scannerLimbStatusIcon = document.getElementById('scannerLimbStatusIcon');
    this.scannerLimbStatusText = document.getElementById('scannerLimbStatusText');

    // Modo 2: App de Diagnóstico P2P
    this.appContainer = document.getElementById('medicalApp');
    this.headerModeTag = document.getElementById('headerModeTag');
    this.headerSubtitle = document.getElementById('headerSubtitle');
    this.patientNameDisplay = document.getElementById('patientNameDisplay');
    this.silhouetteImg = document.getElementById('silhouetteImg');
    this.silhouetteGenderTag = document.getElementById('silhouetteGenderTag');
    this.btnCloseModal = document.getElementById('btnCloseModal');

    // Paneles de vista P2P
    this.patientViewPanel = document.getElementById('patientViewPanel');
    this.emsViewPanel = document.getElementById('emsViewPanel');

    // Elementos de la vista del paciente
    this.patientZoneTitle = document.getElementById('patientZoneTitle');
    this.patientZoneDesc = document.getElementById('patientZoneDesc');
    this.patientZoneIcon = document.getElementById('patientZoneIcon');
    this.injuriesChecklist = document.getElementById('injuriesChecklist');
    this.patientBpmSlider = document.getElementById('patientBpmSlider');
    this.patientBpmVal = document.getElementById('patientBpmVal');
    this.patientBpmTag = document.getElementById('patientBpmTag');
    this.btnSubmitDiagnosis = document.getElementById('btnSubmitDiagnosis');

    // Elementos de la vista del médico
    this.emsZoneTitle = document.getElementById('emsZoneTitle');
    this.emsZoneDesc = document.getElementById('emsZoneDesc');
    this.emsZoneIcon = document.getElementById('emsZoneIcon');
    this.emsZoneStatusBadge = document.getElementById('emsZoneStatusBadge');
    this.emsTreatmentsContainer = document.getElementById('emsTreatmentsContainer');
    this.emsBpmVal = document.getElementById('emsBpmVal');
    this.emsBpmTag = document.getElementById('emsBpmTag');
    this.unlockLockedBanner = document.getElementById('unlockLockedBanner');
    this.unlockSuccessRibbon = document.getElementById('unlockSuccessRibbon');
    this.btnFinalTourniquet = document.getElementById('btnFinalTourniquet');
    this.btnFinalDefib = document.getElementById('btnFinalDefib');

    // Hotspots de la Silueta
    this.hotspots = document.querySelectorAll('.zone-hotspot');

    // Botón de alternancia de perspectiva (Médico <-> Paciente)
    this.btnTogglePerspective = document.getElementById('btnTogglePerspective');
    this.togglePerspectiveLabel = document.getElementById('togglePerspectiveLabel');
    this.currentPerspective = 'ems';
  }

  bindEvents() {
    // --- Eventos del Escáner 3D ---
    if (this.btnCloseScanner) {
      this.btnCloseScanner.addEventListener('click', () => {
        this.closeScanner();
      });
    }

    // --- Eventos del Sistema de Diagnóstico P2P ---
    // 1. Clic en Hotspots de la Silueta
    this.hotspots.forEach(hotspot => {
      hotspot.addEventListener('click', () => {
        const zone = hotspot.getAttribute('data-zone');
        if (zone) this.selectZone(zone);
      });
    });

    // 2. Slider de BPM del Paciente
    if (this.patientBpmSlider) {
      this.patientBpmSlider.addEventListener('input', (e) => {
        const val = parseInt(e.target.value, 10) || 0;
        this.currentBpm = val;
        this.updateBpmDisplay();
      });
    }

    // 3. Botón de Envío de Diagnóstico (Paciente)
    if (this.btnSubmitDiagnosis) {
      this.btnSubmitDiagnosis.addEventListener('click', () => {
        this.submitPatientDiagnosis();
      });
    }

    // 4. Botones de Medicación (Médico)
    const medButtons = document.querySelectorAll('.btn-medication');
    medButtons.forEach(btn => {
      btn.addEventListener('click', () => {
        const med = btn.getAttribute('data-med');
        if (med) this.injectMedication(med);
      });
    });

    // 5. Botones Finales (Médico)
    if (this.btnFinalTourniquet) {
      this.btnFinalTourniquet.addEventListener('click', () => {
        this.applyTourniquetFinal();
      });
    }

    if (this.btnFinalDefib) {
      this.btnFinalDefib.addEventListener('click', () => {
        this.useDefibFinal();
      });
    }

    // 6. Botón de Cierre Modal P2P
    if (this.btnCloseModal) {
      this.btnCloseModal.addEventListener('click', () => {
        this.closeUI();
      });
    }

    // 7. Alternancia de Perspectiva (Médico <-> Paciente)
    if (this.btnTogglePerspective) {
      this.btnTogglePerspective.addEventListener('click', () => {
        this.togglePerspective();
      });
    }

    // 8. Tecla ESC y TAB (Manejo inteligente de foco y alternancia)
    window.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' || e.keyCode === 27) {
        if (this.isScannerOpen) {
          this.closeScanner();
        } else if (this.appContainer && !this.appContainer.classList.contains('hidden')) {
          this.closeUI();
        }
      } else if (e.key === 'Tab' || e.keyCode === 9) {
        if (this.appContainer && !this.appContainer.classList.contains('hidden') && !this.isScannerOpen) {
          e.preventDefault();
          this.togglePerspective();
        }
      }
    });

    // 8. Mensajes NUI desde FiveM
    window.addEventListener('message', (e) => {
      const data = e.data;
      if (!data || !data.action) return;

      switch (data.action) {
        // Modo 1: Escáner 3D (Salud en ox_inventory / Export)
        case 'openScanner':
          this.openScanner(data);
          break;
        case 'updateBoneNodes':
          this.updateBoneNodes(data.nodes);
          break;
        case 'closeScanner':
          this.closeScannerFromLua();
          break;

        // Modo 2: Diagnóstico P2P (EMS vs Paciente)
        case 'openPatientView':
          this.openPatientView(data);
          break;
        case 'openEmsView':
          this.openEmsView(data);
          break;
        case 'syncTreatmentApplied':
          this.onTreatmentApplied(data);
          break;
        case 'syncBpmUpdated':
          this.onBpmUpdated(data);
          break;
        case 'forceClose':
          this.hideAll();
          break;
      }
    });
  }

  // ==========================================================================
  // MODO 1: CONTROLADOR DEL ESCÁNER MÉDICO 3D
  // ==========================================================================
  openScanner(payload) {
    this.mode = 'scanner';
    this.isScannerOpen = true;

    // Asegurar que la ventana P2P esté oculta
    if (this.appContainer) this.appContainer.classList.add('hidden');

    // Mostrar HUD del escáner
    if (this.scannerApp) this.scannerApp.classList.remove('hidden');

    // Guardar datos óseos y configuración
    this.scannerBones = payload.bones || {};
    this.scannerBoneConfig = payload.boneConfig || this.zonesConfig || {};

    // Actualizar telemetría vital
    const vitals = payload.vitals || {};
    const health = (vitals.health !== undefined && vitals.health !== null) ? Number(vitals.health) : 100;
    const bpm = vitals.bpm || 72;
    const armor = vitals.armor || 0;
    const temp = vitals.temperature ? Number(vitals.temperature).toFixed(1) : '37.0';
    const tempStatus = vitals.tempStatus || 'Normal';
    const hunger = vitals.hunger !== undefined ? Number(vitals.hunger) : 100;
    const thirst = vitals.thirst !== undefined ? Number(vitals.thirst) : 100;
    const statusText = vitals.statusText || (health > 75 ? 'ESTABLE' : (health > 35 ? 'COMPROMETIDO' : 'CRÍTICO'));

    // 1. Vitalidad Circular SVG
    if (this.scannerVitalityVal) this.scannerVitalityVal.textContent = `${health}%`;
    if (this.scannerVitalityCircle) {
      const circumference = 238.76;
      const offset = circumference - (circumference * (health / 100));
      this.scannerVitalityCircle.style.strokeDashoffset = offset;
    }

    // 2. Estado General Badge
    if (this.scannerGeneralStatus) {
      this.scannerGeneralStatus.textContent = statusText;
      this.scannerGeneralStatus.className = 'scanner-status-pill ' + (health > 75 ? 'status-stable' : (health > 35 ? 'status-warning' : 'status-danger'));
    }

    // 3. Pulso & Armadura
    if (this.scannerBpm) this.scannerBpm.textContent = bpm;
    if (this.scannerArmor) this.scannerArmor.textContent = `${armor}%`;

    // 4. Metabolismo & Temperatura
    if (this.scannerTempVal) this.scannerTempVal.textContent = `${temp} °C`;
    if (this.scannerTempStatus) this.scannerTempStatus.textContent = tempStatus;

    if (this.scannerHungerVal) this.scannerHungerVal.textContent = `${hunger}%`;
    if (this.scannerHungerBar) this.scannerHungerBar.style.width = `${hunger}%`;

    if (this.scannerThirstVal) this.scannerThirstVal.textContent = `${thirst}%`;
    if (this.scannerThirstBar) this.scannerThirstBar.style.width = `${thirst}%`;

    // 5. Seleccionar extremidad por defecto
    this.selectScannerLimb(this.selectedScannerLimb || 'head');
  }

  updateBoneNodes(nodes) {
    if (!this.isScannerOpen || !nodes || !this.scannerNodesContainer) return;

    Object.keys(nodes).forEach(groupKey => {
      const nodeData = nodes[groupKey];
      if (!nodeData) return;

      let el = this.cachedNodeElements[groupKey];
      if (!el) {
        el = document.createElement('div');
        el.className = 'bone-3d-node';
        el.innerHTML = `
          <div class="bone-node-anchor">
            <div class="bone-node-dot"></div>
          </div>
          <div class="bone-node-label">${nodeData.label || groupKey}</div>
        `;

        el.addEventListener('click', (e) => {
          e.stopPropagation();
          this.selectScannerLimb(groupKey);
        });

        this.scannerNodesContainer.appendChild(el);
        this.cachedNodeElements[groupKey] = el;
      }

      if (!nodeData.onScreen) {
        el.style.display = 'none';
      } else {
        el.style.display = 'flex';
        el.style.left = `${nodeData.x}%`;
        el.style.top = `${nodeData.y}%`;

        if (nodeData.isInjured) {
          el.classList.add('injured');
        } else {
          el.classList.remove('injured');
        }

        if (this.selectedScannerLimb === groupKey) {
          el.classList.add('selected');
        } else {
          el.classList.remove('selected');
        }

        const labelEl = el.querySelector('.bone-node-label');
        if (labelEl && nodeData.label && labelEl.textContent !== nodeData.label) {
          labelEl.textContent = nodeData.label;
        }
      }
    });
  }

  selectScannerLimb(groupKey) {
    this.selectedScannerLimb = groupKey;

    // Actualizar clases .selected en los nodos 3D
    Object.keys(this.cachedNodeElements).forEach(k => {
      const nodeEl = this.cachedNodeElements[k];
      if (nodeEl) {
        if (k === groupKey) {
          nodeEl.classList.add('selected');
        } else {
          nodeEl.classList.remove('selected');
        }
      }
    });

    const boneInfo = (this.scannerBones && this.scannerBones[groupKey]) || { health: 100, injuries: [] };
    const config = (this.scannerBoneConfig && this.scannerBoneConfig[groupKey]) || (this.zonesConfig && this.zonesConfig[groupKey]) || { label: groupKey, description: '' };

    const label = config.label || groupKey;
    const health = boneInfo.health !== undefined ? boneInfo.health : 100;
    const injuries = boneInfo.injuries || [];
    const isDamaged = (health < 100 || injuries.length > 0);

    if (this.scannerLimbName) this.scannerLimbName.textContent = label.toUpperCase();
    if (this.scannerLimbHealthBadge) {
      this.scannerLimbHealthBadge.textContent = `${health}%`;
      if (isDamaged) {
        this.scannerLimbHealthBadge.classList.add('damaged');
      } else {
        this.scannerLimbHealthBadge.classList.remove('damaged');
      }
    }

    if (this.scannerLimbDesc) {
      this.scannerLimbDesc.textContent = config.description || 'Estructura ósea y tejido muscular bajo inspección.';
    }

    if (this.scannerLimbStatusBox && this.scannerLimbStatusIcon && this.scannerLimbStatusText) {
      if (isDamaged) {
        this.scannerLimbStatusBox.className = 'inspector-status-box status-damaged';
        this.scannerLimbStatusIcon.className = 'fa-solid fa-triangle-exclamation';
        this.scannerLimbStatusText.textContent = `Lesiones activas detectadas (${injuries.length > 0 ? injuries.length : 1}). Requiere atención facultativa.`;
      } else {
        this.scannerLimbStatusBox.className = 'inspector-status-box status-ok';
        this.scannerLimbStatusIcon.className = 'fa-solid fa-circle-check';
        this.scannerLimbStatusText.textContent = 'Sin lesiones traumáticas activas en esta extremidad.';
      }
    }
  }

  closeScanner() {
    this.isScannerOpen = false;
    if (this.scannerApp) this.scannerApp.classList.add('hidden');
    if (this.scannerNodesContainer) this.scannerNodesContainer.innerHTML = '';
    this.cachedNodeElements = {};

    fetch(`https://${GetParentResourceName()}/close`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify({})
    }).catch(err => console.error(err));
  }

  closeScannerFromLua() {
    this.isScannerOpen = false;
    if (this.scannerApp) this.scannerApp.classList.add('hidden');
    if (this.scannerNodesContainer) this.scannerNodesContainer.innerHTML = '';
    this.cachedNodeElements = {};
  }

  // ==========================================================================
  // MODO 2: APERTURA VISTA DEL PACIENTE (DATA INPUT P2P)
  // ==========================================================================
  openPatientView(payload) {
    this.mode = 'patient';
    this.isScannerOpen = false;
    if (this.scannerApp) this.scannerApp.classList.add('hidden');

    this.medicSrc = payload.medicSrc;
    this.isMale = payload.isMale !== false;
    this.patientName = payload.patientName || 'Tú (Paciente)';
    this.currentBpm = (payload.initialBpm !== undefined && payload.initialBpm !== null) ? Number(payload.initialBpm) : 75;
    
    if (payload.zones) this.zonesConfig = payload.zones;
    if (payload.injuryTypes) this.injuryTypesConfig = payload.injuryTypes;

    // Resetear lesiones seleccionadas para las 10 zonas
    this.injuries = {
      head: [],
      torso: [],
      right_arm: [],
      left_arm: [],
      right_hand: [],
      left_hand: [],
      right_leg: [],
      left_leg: [],
      right_foot: [],
      left_foot: []
    };

    // Actualizar cabeceras
    this.headerModeTag.innerHTML = '<span class="pulse-dot"></span> SELECCIÓN DE LESIONES (PACIENTE)';
    this.headerSubtitle.textContent = 'Indica los traumatismos sufridos y ajusta tu pulso cardíaco para el facultativo.';
    this.patientNameDisplay.textContent = this.patientName;

    // Configurar silueta
    this.setSilhouetteImage(this.isMale);

    // Configurar slider
    if (this.patientBpmSlider) {
      this.patientBpmSlider.value = this.currentBpm;
    }
    this.updateBpmDisplay();

    // Alternar paneles
    this.currentPerspective = 'patient';
    this.patientViewPanel.classList.remove('hidden');
    this.emsViewPanel.classList.add('hidden');

    if (this.togglePerspectiveLabel) {
      this.togglePerspectiveLabel.textContent = 'Ver Vista Médico (TAB)';
    }
    if (this.btnTogglePerspective) {
      this.btnTogglePerspective.classList.add('view-patient');
    }

    this.selectZone('head');
    this.updateAllHotspotCounters();
    this.show();
  }

  // ==========================================================================
  // MODO 2: APERTURA VISTA DEL MÉDICO (TREATMENT & MONITOR P2P)
  // ==========================================================================
  openEmsView(payload) {
    this.mode = 'ems';
    this.isScannerOpen = false;
    if (this.scannerApp) this.scannerApp.classList.add('hidden');

    const data = payload.data || {};
    this.patientSrc = data.patientSrc;
    this.medicSrc = data.medicSrc;
    this.isMale = data.isMale !== false;
    this.patientName = data.patientName || 'Paciente';
    this.currentBpm = (data.bpm !== undefined && data.bpm !== null) ? Number(data.bpm) : 75;

    // Sanitizar y mapear lesiones asegurando estrictamente las 10 zonas anatómicas
    const rawInjuries = data.injuries || {};
    this.injuries = {
      head: rawInjuries.head || [],
      torso: rawInjuries.torso || [],
      right_arm: rawInjuries.right_arm || rawInjuries.arms || [],
      left_arm: rawInjuries.left_arm || [],
      right_hand: rawInjuries.right_hand || rawInjuries.hands || [],
      left_hand: rawInjuries.left_hand || [],
      right_leg: rawInjuries.right_leg || rawInjuries.legs || [],
      left_leg: rawInjuries.left_leg || [],
      right_foot: rawInjuries.right_foot || rawInjuries.feet || [],
      left_foot: rawInjuries.left_foot || []
    };

    if (payload.zones) this.zonesConfig = payload.zones;
    if (payload.injuryTypes) this.injuryTypesConfig = payload.injuryTypes;
    if (payload.stableBpmRange) this.stableBpmRange = payload.stableBpmRange;

    // Actualizar cabeceras
    this.headerModeTag.innerHTML = '<span class="pulse-dot"></span> MONITOR MÉDICO & TRATAMIENTOS (EMS)';
    this.headerSubtitle.textContent = 'Trata las lesiones anatómicas, estabiliza el ritmo cardíaco y aplica los procedimientos finales.';
    this.patientNameDisplay.textContent = this.patientName;

    // Configurar silueta
    this.setSilhouetteImage(this.isMale);

    // Alternar paneles
    this.currentPerspective = 'ems';
    this.patientViewPanel.classList.add('hidden');
    this.emsViewPanel.classList.remove('hidden');

    if (this.togglePerspectiveLabel) {
      this.togglePerspectiveLabel.textContent = 'Ver Vista Paciente (TAB)';
    }
    if (this.btnTogglePerspective) {
      this.btnTogglePerspective.classList.remove('view-patient');
    }

    this.updateBpmDisplay();
    this.selectZone('head');
    this.updateAllHotspotCounters();
    this.checkUnlockState();
    this.show();
  }

  // ==========================================================================
  // ALTERNANCIA DE PERSPECTIVA (MÉDICO <-> PACIENTE EN VIVO)
  // ==========================================================================
  togglePerspective() {
    if (this.currentPerspective === 'ems') {
      this.switchToPatientPerspective();
    } else {
      this.switchToEmsPerspective();
    }
  }

  switchToPatientPerspective() {
    this.currentPerspective = 'patient';
    this.patientViewPanel.classList.remove('hidden');
    this.emsViewPanel.classList.add('hidden');

    if (this.headerModeTag) {
      this.headerModeTag.innerHTML = '<span class="pulse-dot"></span> VISTA DEL PACIENTE (SIMULACIÓN EN VIVO)';
    }
    if (this.headerSubtitle) {
      this.headerSubtitle.textContent = 'Esto es exactamente lo que ve el paciente en su pantalla en tiempo real.';
    }
    if (this.togglePerspectiveLabel) {
      this.togglePerspectiveLabel.textContent = 'Volver a Vista Médico (TAB)';
    }
    if (this.btnTogglePerspective) {
      this.btnTogglePerspective.classList.add('view-patient');
    }

    if (this.patientBpmSlider) {
      this.patientBpmSlider.value = this.currentBpm;
    }
    this.updateBpmDisplay();
    this.renderPatientChecklist(this.selectedZone, this.zonesConfig[this.selectedZone] || {});
    this.updateAllHotspotCounters();
  }

  switchToEmsPerspective() {
    this.currentPerspective = 'ems';
    this.patientViewPanel.classList.add('hidden');
    this.emsViewPanel.classList.remove('hidden');

    if (this.headerModeTag) {
      this.headerModeTag.innerHTML = '<span class="pulse-dot"></span> MONITOR MÉDICO & TRATAMIENTOS (EMS)';
    }
    if (this.headerSubtitle) {
      this.headerSubtitle.textContent = 'Trata las lesiones anatómicas, estabiliza el ritmo cardíaco y aplica los procedimientos finales.';
    }
    if (this.togglePerspectiveLabel) {
      this.togglePerspectiveLabel.textContent = 'Ver Vista Paciente (TAB)';
    }
    if (this.btnTogglePerspective) {
      this.btnTogglePerspective.classList.remove('view-patient');
    }

    this.updateBpmDisplay();
    this.renderEmsTreatments(this.selectedZone, this.zonesConfig[this.selectedZone] || {});
    this.updateAllHotspotCounters();
    this.checkUnlockState();
  }

  setSilhouetteImage(isMale) {
    this.isMale = isMale;
    if (this.silhouetteImg) {
      this.silhouetteImg.src = isMale ? 'images/silueta_hombre.png' : 'images/silueta_mujer.png';
    }
    if (this.silhouetteGenderTag) {
      this.silhouetteGenderTag.textContent = isMale ? 'Masculino' : 'Femenino';
    }
  }

  // ==========================================================================
  // SELECCIÓN Y GESTIÓN DE ZONAS ANATÓMICAS
  // ==========================================================================
  selectZone(zoneId) {
    this.selectedZone = zoneId;
    const config = this.zonesConfig[zoneId] || { label: zoneId, desc: '', icon: 'fa-solid fa-bone' };

    // Actualizar clases activas en los hotspots
    this.hotspots.forEach(hotspot => {
      const hZone = hotspot.getAttribute('data-zone');
      if (hZone === zoneId) {
        hotspot.classList.add('active-zone');
      } else {
        hotspot.classList.remove('active-zone');
      }
    });

    if (this.mode === 'patient') {
      this.renderPatientChecklist(zoneId, config);
    } else {
      this.renderEmsTreatments(zoneId, config);
    }
  }

  renderPatientChecklist(zoneId, config) {
    if (this.patientZoneTitle) this.patientZoneTitle.textContent = config.label;
    if (this.patientZoneDesc) this.patientZoneDesc.textContent = config.description || 'Selecciona los traumatismos sufridos en esta zona.';
    if (this.patientZoneIcon) this.patientZoneIcon.innerHTML = `<i class="${config.icon || 'fa-solid fa-bone'}"></i>`;

    if (!this.injuriesChecklist) return;
    this.injuriesChecklist.innerHTML = '';

    const currentZoneInjuries = this.injuries[zoneId] || [];

    Object.keys(this.injuryTypesConfig).forEach(injKey => {
      const inj = this.injuryTypesConfig[injKey];
      const isChecked = currentZoneInjuries.includes(injKey);

      const card = document.createElement('div');
      card.className = `injury-checkbox-card ${isChecked ? 'checked' : ''}`;
      card.innerHTML = `
        <div class="injury-info-left">
          <div class="injury-icon-pill">
            <i class="${inj.icon || 'fa-solid fa-circle-exclamation'}"></i>
          </div>
          <div>
            <div class="injury-label-title">${inj.label}</div>
            <div class="injury-subdesc">${inj.description || ''}</div>
          </div>
        </div>
        <div class="custom-checkbox-box">
          <i class="fa-solid fa-check"></i>
        </div>
      `;

      card.addEventListener('click', () => {
        this.toggleInjury(zoneId, injKey);
      });

      this.injuriesChecklist.appendChild(card);
    });
  }

  toggleInjury(zoneId, injuryKey) {
    if (!this.injuries[zoneId]) this.injuries[zoneId] = [];
    const index = this.injuries[zoneId].indexOf(injuryKey);

    if (index > -1) {
      this.injuries[zoneId].splice(index, 1);
    } else {
      this.injuries[zoneId].push(injuryKey);
    }

    const config = this.zonesConfig[zoneId] || {};
    this.renderPatientChecklist(zoneId, config);
    this.updateHotspotCounter(zoneId);
  }

  renderEmsTreatments(zoneId, config) {
    if (this.emsZoneTitle) this.emsZoneTitle.textContent = config.label;
    if (this.emsZoneDesc) this.emsZoneDesc.textContent = config.description || 'Aplica los tratamientos clínicos adecuados.';
    if (this.emsZoneIcon) this.emsZoneIcon.innerHTML = `<i class="${config.icon || 'fa-solid fa-bone'}"></i>`;

    const currentZoneInjuries = this.injuries[zoneId] || [];
    const count = currentZoneInjuries.length;

    if (this.emsZoneStatusBadge) {
      if (count > 0) {
        this.emsZoneStatusBadge.textContent = `${count} ${count === 1 ? 'LESIÓN' : 'LESIONES'}`;
        this.emsZoneStatusBadge.style.color = 'var(--color-pink)';
        this.emsZoneStatusBadge.style.borderColor = 'rgba(255, 0, 127, 0.4)';
        this.emsZoneStatusBadge.style.background = 'rgba(255, 0, 127, 0.15)';
      } else {
        this.emsZoneStatusBadge.textContent = 'CURADO / SANO';
        this.emsZoneStatusBadge.style.color = 'var(--color-turquoise)';
        this.emsZoneStatusBadge.style.borderColor = 'rgba(64, 224, 208, 0.4)';
        this.emsZoneStatusBadge.style.background = 'rgba(64, 224, 208, 0.15)';
      }
    }

    if (!this.emsTreatmentsContainer) return;
    this.emsTreatmentsContainer.innerHTML = '';

    if (count === 0) {
      this.emsTreatmentsContainer.innerHTML = `
        <div class="no-injuries-banner">
          <i class="fa-solid fa-circle-check" style="font-size: 26px;"></i>
          <span>Extremidad en perfecto estado clínico o totalmente estabilizada.</span>
        </div>
      `;
      return;
    }

    currentZoneInjuries.forEach(injKey => {
      const inj = this.injuryTypesConfig[injKey] || { label: injKey, treatment: 'Tratar Lesión', icon: 'fa-solid fa-bandage' };

      const card = document.createElement('div');
      card.className = 'treatment-card';
      card.innerHTML = `
        <div class="treatment-info">
          <div class="treatment-icon-pill">
            <i class="${inj.icon || 'fa-solid fa-stethoscope'}"></i>
          </div>
          <div>
            <div class="treatment-name">${inj.label}</div>
            <div class="treatment-desc">${inj.description || ''}</div>
          </div>
        </div>
        <button class="btn-apply-treatment" data-inj="${injKey}">
          <i class="fa-solid fa-hand-holding-medical"></i>
          <span>${inj.treatment || 'Aplicar Tratamiento'}</span>
        </button>
      `;

      const btn = card.querySelector('.btn-apply-treatment');
      btn.addEventListener('click', () => {
        this.applyTreatment(zoneId, injKey);
      });

      this.emsTreatmentsContainer.appendChild(card);
    });
  }

  // ==========================================================================
  // ACTUALIZACIÓN VISUAL DE HOTSPOTS Y DAÑOS (10 ZONAS)
  // ==========================================================================
  updateAllHotspotCounters() {
    ['head', 'torso', 'right_arm', 'left_arm', 'right_hand', 'left_hand', 'right_leg', 'left_leg', 'right_foot', 'left_foot'].forEach(zone => {
      this.updateHotspotCounter(zone);
    });
  }

  updateHotspotCounter(zoneId) {
    const list = this.injuries[zoneId] || [];
    const count = list.length;
    const hasDamage = count > 0;

    this.hotspots.forEach(hotspot => {
      const hZone = hotspot.getAttribute('data-zone');
      if (hZone === zoneId) {
        if (hasDamage) {
          hotspot.classList.add('has-damage');
        } else {
          hotspot.classList.remove('has-damage');
        }

        const counter = hotspot.querySelector('.damage-counter');
        if (counter) {
          counter.textContent = count;
        }
      }
    });
  }

  // ==========================================================================
  // FRECUENCIA CARDÍACA (BPM) Y ESTADO HEMODINÁMICO
  // ==========================================================================
  updateBpmDisplay() {
    const bpm = this.currentBpm;
    let label = 'NORMAL';
    let cssClass = 'bpm-normal';

    if (bpm === 0) {
      label = 'PARADA / ASISTOLIA';
      cssClass = 'bpm-danger';
    } else if (bpm < 50) {
      label = 'BRADICARDIA CRÍTICA';
      cssClass = 'bpm-danger';
    } else if (bpm < 60) {
      label = 'BRADICARDIA LEVE';
      cssClass = 'bpm-warning';
    } else if (bpm <= 100) {
      label = 'RITMO SINUSAL';
      cssClass = 'bpm-normal';
    } else if (bpm <= 140) {
      label = 'TAQUICARDIA';
      cssClass = 'bpm-warning';
    } else {
      label = 'TAQUICARDIA SEVERA';
      cssClass = 'bpm-danger';
    }

    if (this.patientBpmVal) this.patientBpmVal.textContent = bpm;
    if (this.patientBpmTag) {
      this.patientBpmTag.textContent = label;
      this.patientBpmTag.className = `badge-bpm ${cssClass}`;
    }

    if (this.emsBpmVal) this.emsBpmVal.textContent = bpm;
    if (this.emsBpmTag) {
      this.emsBpmTag.textContent = label;
      this.emsBpmTag.className = `badge-bpm ${cssClass}`;
    }
  }

  // ==========================================================================
  // ESTADO DE DESBLOQUEO FINAL (TORNIQUETE Y DESFIBRILADOR EN BLANCO Y NEGRO / COLOR)
  // ==========================================================================
  checkUnlockState() {
    let totalInjuries = 0;
    const activeZones = ['head', 'torso', 'right_arm', 'left_arm', 'right_hand', 'left_hand', 'right_leg', 'left_leg', 'right_foot', 'left_foot'];
    activeZones.forEach(zoneKey => {
      const arr = this.injuries[zoneKey];
      if (arr && Array.isArray(arr)) {
        totalInjuries += arr.length;
      }
    });

    const isBpmStable = (this.currentBpm >= this.stableBpmRange.min && this.currentBpm <= this.stableBpmRange.max);
    const canUnlock = (totalInjuries === 0 && isBpmStable);

    if (canUnlock) {
      if (this.unlockLockedBanner) this.unlockLockedBanner.classList.add('hidden');
      if (this.unlockSuccessRibbon) this.unlockSuccessRibbon.classList.remove('hidden');

      if (this.btnFinalTourniquet) {
        this.btnFinalTourniquet.classList.remove('btn-locked');
        this.btnFinalTourniquet.classList.add('btn-unlocked');
        this.btnFinalTourniquet.removeAttribute('disabled');
        this.btnFinalTourniquet.disabled = false;
      }
      if (this.btnFinalDefib) {
        this.btnFinalDefib.classList.remove('btn-locked');
        this.btnFinalDefib.classList.add('btn-unlocked');
        this.btnFinalDefib.removeAttribute('disabled');
        this.btnFinalDefib.disabled = false;
      }
    } else {
      if (this.unlockLockedBanner) this.unlockLockedBanner.classList.remove('hidden');
      if (this.unlockSuccessRibbon) this.unlockSuccessRibbon.classList.add('hidden');

      if (this.btnFinalTourniquet) {
        this.btnFinalTourniquet.classList.add('btn-locked');
        this.btnFinalTourniquet.classList.remove('btn-unlocked');
        this.btnFinalTourniquet.setAttribute('disabled', 'true');
        this.btnFinalTourniquet.disabled = true;
      }
      if (this.btnFinalDefib) {
        this.btnFinalDefib.classList.add('btn-locked');
        this.btnFinalDefib.classList.remove('btn-unlocked');
        this.btnFinalDefib.setAttribute('disabled', 'true');
        this.btnFinalDefib.disabled = true;
      }
    }
  }

  // ==========================================================================
  // ENVÍO DE ACCIONES NUI (POST FETCH A FIVEM)
  // ==========================================================================
  submitPatientDiagnosis() {
    fetch(`https://${GetParentResourceName()}/submitPatientDiagnosis`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify({
        medicSrc: this.medicSrc,
        isMale: this.isMale,
        bpm: this.currentBpm,
        injuries: this.injuries,
        patientName: this.patientName
      })
    }).then(res => res.json()).then(() => {
      if (this.btnSubmitDiagnosis) {
        this.btnSubmitDiagnosis.innerHTML = '<i class="fa-solid fa-satellite-dish"></i> TELEMETRÍA ENVIADA AL MÉDICO';
        this.btnSubmitDiagnosis.style.background = 'linear-gradient(135deg, #10b981 0%, #059669 100%)';
        this.btnSubmitDiagnosis.disabled = true;
      }
    }).catch(err => console.error(err));
  }

  applyTreatment(zoneId, injuryKey) {
    fetch(`https://${GetParentResourceName()}/applyTreatment`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify({
        zone: zoneId,
        injuryId: injuryKey
      })
    }).catch(err => console.error(err));
  }

  injectMedication(medKey) {
    fetch(`https://${GetParentResourceName()}/injectMedication`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify({
        medication: medKey
      })
    }).catch(err => console.error(err));
  }

  applyTourniquetFinal() {
    fetch(`https://${GetParentResourceName()}/applyTourniquetFinal`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify({})
    }).catch(err => console.error(err));
  }

  useDefibFinal() {
    fetch(`https://${GetParentResourceName()}/useDefibFinal`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify({})
    }).catch(err => console.error(err));
  }

  // ==========================================================================
  // SINCRONIZACIÓN EN TIEMPO REAL DESDE EVENTOS DE RED
  // ==========================================================================
  onTreatmentApplied(data) {
    const zone = data.zone;
    if (this.injuries[zone]) {
      this.injuries[zone] = data.remainingInjuries || [];
    }
    if (data.allInjuries) {
      const raw = data.allInjuries;
      this.injuries = {
        head: raw.head || [],
        torso: raw.torso || [],
        right_arm: raw.right_arm || (raw.arms && !raw.right_arm ? raw.arms : (this.injuries.right_arm || [])),
        left_arm: raw.left_arm || (this.injuries.left_arm || []),
        right_hand: raw.right_hand || (raw.hands && !raw.right_hand ? raw.hands : (this.injuries.right_hand || [])),
        left_hand: raw.left_hand || (this.injuries.left_hand || []),
        right_leg: raw.right_leg || (raw.legs && !raw.right_leg ? raw.legs : (this.injuries.right_leg || [])),
        left_leg: raw.left_leg || (this.injuries.left_leg || []),
        right_foot: raw.right_foot || (raw.feet && !raw.right_foot ? raw.feet : (this.injuries.right_foot || [])),
        left_foot: raw.left_foot || (this.injuries.left_foot || [])
      };
    }

    this.updateAllHotspotCounters();
    const config = this.zonesConfig[this.selectedZone] || {};

    if (this.mode === 'ems') {
      this.renderEmsTreatments(this.selectedZone, config);
      this.checkUnlockState();
    } else {
      this.renderPatientChecklist(this.selectedZone, config);
    }
  }

  onBpmUpdated(data) {
    this.currentBpm = data.bpm || this.currentBpm;
    this.updateBpmDisplay();

    if (this.mode === 'ems') {
      this.checkUnlockState();
    }
  }

  // ==========================================================================
  // CONTROL DE VENTANAS (SHOW / HIDE / CLOSE)
  // ==========================================================================
  show() {
    if (this.appContainer) {
      this.appContainer.classList.remove('hidden');
    }
  }

  hide() {
    if (this.appContainer) {
      this.appContainer.classList.add('hidden');
    }
  }

  hideAll() {
    this.hide();
    this.closeScannerFromLua();
  }

  closeUI() {
    this.hide();
    fetch(`https://${GetParentResourceName()}/closeUI`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify({})
    }).catch(err => console.error(err));
  }
}

// Inicializar la aplicación cuando el DOM esté listo
document.addEventListener('DOMContentLoaded', () => {
  window.auraMedicalApp = new AuraMedicalApp();
});


