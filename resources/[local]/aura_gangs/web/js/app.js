// ============================================================================
// AURA GANGS: JAVASCRIPT UI CONTROLLER (PROJECT GREENHOUSE)
// ============================================================================

const app = document.getElementById('app');
const plantIdTag = document.getElementById('plant-id-tag');
const plantStageBadge = document.getElementById('plant-stage-badge');

const growthValue = document.getElementById('growth-value');
const growthFill = document.getElementById('growth-fill');

const thirstValue = document.getElementById('thirst-value');
const thirstFill = document.getElementById('thirst-fill');

const nutritionValue = document.getElementById('nutrition-value');
const nutritionFill = document.getElementById('nutrition-fill');

const statusAlertBox = document.getElementById('status-alert-box');
const alertIconWrap = document.getElementById('alert-icon-wrap');
const alertTitle = document.getElementById('alert-title');
const alertDesc = document.getElementById('alert-desc');

const btnClose = document.getElementById('btn-close');

function closeUI() {
    app.classList.add('hidden');
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).catch(() => {});
}

btnClose.addEventListener('click', closeUI);

window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' || e.key === 'Esc') {
        closeUI();
    }
});

window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.action === 'openPlantDiagnosis') {
        const plant = data.data;

        plantIdTag.innerText = `MACETA #${plant.id}`;
        plantStageBadge.innerText = plant.stageLabel ? plant.stageLabel.toUpperCase() : `FASE ${plant.stage}`;

        // Crecimiento
        const gPct = Math.min(100, Math.max(0, plant.growth)).toFixed(1);
        growthValue.innerText = `${gPct}%`;
        growthFill.style.width = `${gPct}%`;

        // Hidratación
        const tPct = Math.min(100, Math.max(0, plant.thirst)).toFixed(0);
        thirstValue.innerText = `${tPct}%`;
        thirstFill.style.width = `${tPct}%`;

        // Nutrientes
        const nPct = Math.min(100, Math.max(0, plant.nutrition)).toFixed(0);
        nutritionValue.innerText = `${nPct}%`;
        nutritionFill.style.width = `${nPct}%`;

        // Alerta de Diagnóstico Reactiva
        if (plant.isReady) {
            statusAlertBox.className = 'status-alert';
            alertIconWrap.innerHTML = '<i class="fa-solid fa-sparkles text-cyan"></i>';
            alertTitle.innerText = '¡Maduración Completa!';
            alertDesc.innerText = 'Los tricomas están en su punto óptimo. Utiliza tus tijeras de podar y bolsitas herméticas para cosechar.';
        } else if (plant.thirst <= 15.0 && plant.nutrition <= 15.0) {
            statusAlertBox.className = 'status-alert warning';
            alertIconWrap.innerHTML = '<i class="fa-solid fa-triangle-exclamation text-pink"></i>';
            alertTitle.innerText = 'Sustrato Seco y Sin Nutrientes';
            alertDesc.innerText = 'El cultivo no crecerá hasta ser regado con una botella de agua y nutrido con fertilizante NPK.';
        } else if (plant.thirst <= 15.0) {
            statusAlertBox.className = 'status-alert warning';
            alertIconWrap.innerHTML = '<i class="fa-solid fa-triangle-exclamation text-pink"></i>';
            alertTitle.innerText = 'Sustrato Seco (Estrés Hídrico)';
            alertDesc.innerText = 'La planta ha detenido su crecimiento por falta de agua. Riégala con una botella de agua inmediatamente.';
        } else if (plant.nutrition <= 15.0) {
            statusAlertBox.className = 'status-alert warning';
            alertIconWrap.innerHTML = '<i class="fa-solid fa-triangle-exclamation text-pink"></i>';
            alertTitle.innerText = 'Carencia Nutricional NPK';
            alertDesc.innerText = 'El sustrato ha agotado sus nutrientes. Aplica fertilizante para reactivar el ciclo de crecimiento.';
        } else if (plant.thirst > 50.0 && plant.nutrition > 50.0) {
            statusAlertBox.className = 'status-alert';
            alertIconWrap.innerHTML = '<i class="fa-solid fa-circle-check text-cyan"></i>';
            alertTitle.innerText = 'Condiciones Óptimas (+30% Bonus)';
            alertDesc.innerText = 'Niveles ideales de agua y fertilizante. La planta se desarrolla a máxima velocidad.';
        } else {
            statusAlertBox.className = 'status-alert';
            alertIconWrap.innerHTML = '<i class="fa-solid fa-circle-check text-cyan"></i>';
            alertTitle.innerText = 'Condiciones Estables';
            alertDesc.innerText = 'Los niveles actuales permiten que la planta siga creciendo con normalidad.';
        }

        app.classList.remove('hidden');
    }
});
