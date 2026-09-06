// ============================================================================
// AURA MEDICAL: INTERFAZ DIAGNÓSTICA 3D & TELEMETRÍA BIOMÉTRICA (JS)
// ============================================================================

(function () {
  const appContainer = document.getElementById('medical-app');
  const nodesContainer = document.getElementById('nodes-container');
  const btnClose = document.getElementById('btn-close-scanner');

  // Elementos de Signos Vitales
  const healthRing = document.getElementById('health-ring');
  const healthPercentEl = document.getElementById('health-percentage');
  const overallBadgeEl = document.getElementById('overall-status-badge');
  const bpmValueEl = document.getElementById('bpm-value');
  const armorValueEl = document.getElementById('armor-value');

  // Metabolismo y Temperatura
  const tempBadgeEl = document.getElementById('temperature-badge');
  const tempStatusEl = document.getElementById('temperature-status');
  const hungerTextEl = document.getElementById('hunger-text');
  const hungerBarEl = document.getElementById('hunger-bar');
  const thirstTextEl = document.getElementById('thirst-text');
  const thirstBarEl = document.getElementById('thirst-bar');

  // Inspector de Extremidad
  const limbNameEl = document.getElementById('selected-limb-name');
  const limbHealthBadge = document.getElementById('selected-limb-health');
  const limbSubEl = document.getElementById('selected-limb-sub');
  const injuriesListEl = document.getElementById('injuries-list');

  // Estado Local
  let currentBonesData = {};
  let bonesConfig = {};
  let selectedLimbKey = 'torso';
  let isAppOpen = false;

  const nodeElements = {};

  // Nombres de Extremidades
  const LimbLabels = {
    head: 'Cabeza y Cuello',
    torso: 'Tórax y Espina Dorsal',
    left_arm: 'Brazo Izquierdo',
    right_arm: 'Brazo Derecho',
    left_leg: 'Pierna Izquierda',
    right_leg: 'Pierna Derecha'
  };

  // Helper de Comunicación NUI
  function postNui(endpoint, data = {}) {
    const resource = (typeof window.GetParentResourceName === 'function')
      ? window.GetParentResourceName()
      : 'aura_medical';

    return fetch(`https://${resource}/${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data)
    }).catch(err => {
      console.warn(`[AURA MEDICAL] Error en postNui (${endpoint}):`, err);
    });
  }

  // Reproducir sonido frontal NUI
  function playUiSound(soundName) {
    postNui('playSound', { sound: soundName, soundSet: 'HUD_FRONTEND_DEFAULT_SOUNDSET' });
  }

  // Inicializar Nodos Flotantes HTML en el DOM
  function createBoneNodes() {
    nodesContainer.innerHTML = '';
    const keys = ['head', 'torso', 'left_arm', 'right_arm', 'left_leg', 'right_leg'];

    keys.forEach(key => {
      const nodeEl = document.createElement('div');
      nodeEl.className = 'node-3d';
      nodeEl.id = `bone-node-${key}`;
      nodeEl.innerHTML = `
        <div class="node-circle-box">
          <div class="node-ring-pulse"></div>
          <div class="node-core"></div>
        </div>
        <div class="node-label-pill">${LimbLabels[key] || key}</div>
      `;

      nodeEl.addEventListener('click', (e) => {
        e.stopPropagation();
        selectLimb(key);
        playUiSound('NAV_UP_DOWN');
      });

      nodesContainer.appendChild(nodeEl);
      nodeElements[key] = nodeEl;
    });
  }

  // Actualizar Posiciones y Estados de los Nodos 3D (desde scanner.lua)
  function updateBoneNodes(nodes) {
    if (!nodes) return;

    for (const [key, data] of Object.entries(nodes)) {
      const el = nodeElements[key];
      if (!el) continue;

      if (!data.onScreen) {
        el.classList.add('hidden');
        continue;
      }

      el.classList.remove('hidden');
      el.style.left = `${data.x}%`;
      el.style.top = `${data.y}%`;

      // Estado de Daño
      if (data.isInjured) {
        el.classList.add('damaged');
      } else {
        el.classList.remove('damaged');
      }

      // Estado Seleccionado
      if (selectedLimbKey === key) {
        el.classList.add('selected');
      } else {
        el.classList.remove('selected');
      }
    }
  }

  // Seleccionar Extremidad e Inspeccionar Lesiones
  function selectLimb(limbKey) {
    selectedLimbKey = limbKey;

    // Actualizar clase seleccionada en todos los nodos
    for (const [key, el] of Object.entries(nodeElements)) {
      if (key === limbKey) {
        el.classList.add('selected');
      } else {
        el.classList.remove('selected');
      }
    }

    const limbData = currentBonesData[limbKey] || { health: 100, injuries: {} };
    const label = LimbLabels[limbKey] || limbKey;

    limbNameEl.textContent = label;
    const health = limbData.health !== undefined ? limbData.health : 100;
    limbHealthBadge.textContent = `${health}%`;

    if (health >= 80) {
      limbHealthBadge.className = 'badge-status badge-healthy';
      limbSubEl.textContent = 'Estructura ósea y tejido muscular en estado óptimo.';
    } else if (health >= 40) {
      limbHealthBadge.className = 'badge-status badge-warning';
      limbSubEl.textContent = 'Trauma moderado. Requiere atención médica para estabilización.';
    } else {
      limbHealthBadge.className = 'badge-status badge-critical';
      limbSubEl.textContent = 'Trauma severo / compromiso vascular crítico.';
    }

    // Renderizar Lista de Lesiones
    renderInjuries(limbData.injuries || []);
  }

  // Renderizar la lista de lesiones en la tarjeta de detalle
  function renderInjuries(injuries) {
    injuriesListEl.innerHTML = '';

    if (!injuries || injuries.length === 0) {
      injuriesListEl.innerHTML = `
        <div class="no-injuries-banner">
          <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="#40E0D0" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
            <polyline points="22 4 12 14.01 9 11.01"></polyline>
          </svg>
          <span>Sin lesiones traumáticas activas en esta extremidad.</span>
        </div>
      `;
      return;
    }

    injuries.forEach(inj => {
      const card = document.createElement('div');
      card.className = 'injury-item-card';
      card.innerHTML = `
        <div class="injury-header-row">
          <span class="injury-type-label">${inj.typeLabel || inj.type}</span>
          <span class="injury-severity-tag">${inj.severityLabel || inj.severity}</span>
        </div>
        <div class="injury-detail-desc">Impacto registrado: -${inj.damage || 0} HP. Daño en tejido y estructura ósea.</div>
        <div class="injury-time-stamp">HORA DEL IMPACTO: ${inj.timeFormatted || 'RECIENTE'}</div>
      `;
      injuriesListEl.appendChild(card);
    });
  }

  // Actualizar Dashboard de Signos Vitales
  function updateVitalSigns(vitals) {
    if (!vitals) return;

    // 1. Salud General
    const health = vitals.health !== undefined ? vitals.health : 100;
    healthPercentEl.textContent = `${health}%`;

    // Radio del círculo = 46 -> Circunferencia = 2 * PI * 46 ≈ 289
    const circumference = 289;
    const offset = circumference - (health / 100) * circumference;
    healthRing.style.strokeDashoffset = offset;

    if (health >= 75) {
      healthRing.style.stroke = '#00f2fe';
      overallBadgeEl.className = 'badge-status badge-healthy';
      overallBadgeEl.textContent = 'ESTABLE';
    } else if (health >= 35) {
      healthRing.style.stroke = '#ffaa00';
      overallBadgeEl.className = 'badge-status badge-warning';
      overallBadgeEl.textContent = 'COMPROMETIDO';
    } else {
      healthRing.style.stroke = '#FF007F';
      overallBadgeEl.className = 'badge-status badge-critical';
      overallBadgeEl.textContent = 'CRÍTICO';
    }

    // 2. Pulso Cardíaco
    bpmValueEl.textContent = vitals.bpm || 72;

    // 3. Blindaje
    armorValueEl.textContent = `${vitals.armor || 0}%`;

    // 4. Temperatura Corporal (aura_seasons)
    const temp = vitals.temperature !== undefined ? vitals.temperature : 36.8;
    tempBadgeEl.textContent = `${temp.toFixed(1)} °C`;
    tempBadgeEl.style.color = vitals.tempColor || '#00f2fe';
    tempStatusEl.textContent = vitals.tempStatus || 'Normal';

    // 5. Hambre y Sed (aura_status)
    const hunger = vitals.hunger !== undefined ? vitals.hunger : 100;
    const thirst = vitals.thirst !== undefined ? vitals.thirst : 100;

    hungerTextEl.textContent = `${hunger}%`;
    hungerBarEl.style.width = `${hunger}%`;

    thirstTextEl.textContent = `${thirst}%`;
    thirstBarEl.style.width = `${thirst}%`;
  }

  // Abrir Escáner
  function openScanner(data) {
    isAppOpen = true;
    currentBonesData = data.bones || {};
    bonesConfig = data.boneConfig || {};

    createBoneNodes();
    updateVitalSigns(data.vitals);
    selectLimb(selectedLimbKey || 'torso');

    appContainer.classList.remove('hidden');
    playUiSound('SELECT');
  }

  // Cerrar Escáner
  function closeScanner() {
    if (!isAppOpen) return;
    isAppOpen = false;
    appContainer.classList.add('hidden');
    postNui('close');
  }

  // Listeners de Eventos
  btnClose.addEventListener('click', () => {
    closeScanner();
  });

  window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' || e.key === 'Backspace' || e.key === 'F6') {
      if (isAppOpen) {
        closeScanner();
      }
    }
  });

  window.addEventListener('message', (e) => {
    const event = e.data;
    if (!event || !event.action) return;

    if (event.action === 'openScanner') {
      openScanner(event);
    } else if (event.action === 'closeScanner') {
      isAppOpen = false;
      appContainer.classList.add('hidden');
    } else if (event.action === 'updateBoneNodes') {
      updateBoneNodes(event.nodes);
    } else if (event.action === 'updateVitals') {
      updateVitalSigns(event.vitals);
    }
  });

  createBoneNodes();
})();
