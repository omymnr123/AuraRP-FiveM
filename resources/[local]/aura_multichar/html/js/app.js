let characters = [];
let currentSlot = 1;
let selectedCharId = null;

const countries = [
    "Afganistán", "Albania", "Alemania", "Andorra", "Angola", "Antigua y Barbuda", "Arabia Saudita", "Argelia", "Argentina", "Armenia", "Australia", "Austria", "Azerbaiyán", "Bahamas", "Bangladés", "Barbados", "Baréin", "Bélgica", "Belice", "Benín", "Bielorrusia", "Birmania", "Bolivia", "Bosnia y Herzegovina", "Botsuana", "Brasil", "Brunéi", "Bulgaria", "Burkina Faso", "Burundi", "Bután", "Cabo Verde", "Camboya", "Camerún", "Canadá", "Catar", "Chad", "Chile", "China", "Chipre", "Ciudad del Vaticano", "Colombia", "Comoras", "Corea del Norte", "Corea del Sur", "Costa de Marfil", "Costa Rica", "Croacia", "Cuba", "Dinamarca", "Dominica", "Ecuador", "Egipto", "El Salvador", "Emiratos Árabes Unidos", "Eritrea", "Eslovaquia", "Eslovenia", "España", "Estados Unidos", "Estonia", "Etiopía", "Filipinas", "Finlandia", "Fiyi", "Francia", "Gabón", "Gambia", "Georgia", "Ghana", "Granada", "Grecia", "Guatemala", "Guyana", "Guinea", "Guinea ecuatorial", "Guinea-Bisáu", "Haití", "Honduras", "Hungría", "India", "Indonesia", "Irak", "Irán", "Irlanda", "Islandia", "Islas Marshall", "Islas Salomón", "Israel", "Italia", "Jamaica", "Japón", "Jordania", "Kazajistán", "Kenia", "Kirguistán", "Kiribati", "Kuwait", "Laos", "Lesoto", "Letonia", "Líbano", "Liberia", "Libia", "Liechtenstein", "Lituania", "Luxemburgo", "Macedonia del Norte", "Madagascar", "Malasia", "Malaui", "Maldivas", "Malí", "Malta", "Marruecos", "Mauricio", "Mauritania", "México", "Micronesia", "Moldavia", "Mónaco", "Mongolia", "Montenegro", "Mozambique", "Namibia", "Nauru", "Nepal", "Nicaragua", "Níger", "Nigeria", "Noruega", "Nueva Zelanda", "Omán", "Países Bajos", "Pakistán", "Palaos", "Panamá", "Papúa Nueva Guinea", "Paraguay", "Perú", "Polonia", "Portugal", "Reino Unido", "República Centroafricana", "República Checa", "República del Congo", "República Democrática del Congo", "República Dominicana", "Ruanda", "Rumanía", "Rusia", "Samoa", "San Cristóbal y Nieves", "San Marino", "San Vicente y las Granadinas", "Santa Lucía", "Santo Tomé y Príncipe", "Senegal", "Serbia", "Seychelles", "Sierra Leona", "Singapur", "Siria", "Somalia", "Sri Lanka", "Suazilandia", "Sudáfrica", "Sudán", "Sudán del Sur", "Suecia", "Suiza", "Surinam", "Tailandia", "Tanzania", "Tayikistán", "Timor Oriental", "Togo", "Tonga", "Trinidad y Tobago", "Túnez", "Turkmenistán", "Turquía", "Tuvalu", "Ucrania", "Uganda", "Uruguay", "Uzbekistán", "Vanuatu", "Venezuela", "Vietnam", "Yemen", "Yibuti", "Zambia", "Zimbabue"
];

function initCountries() {
    const natSelect = document.getElementById('nationality');
    if (natSelect && natSelect.options.length <= 1) {
        countries.forEach(c => {
            let opt = document.createElement('option');
            opt.value = c;
            opt.innerHTML = c;
            natSelect.appendChild(opt);
        });
    }
}

// Formateador de moneda profesional
function formatCurrency(amount) {
    const num = Number(amount) || 0;
    return `$ ${num.toLocaleString('es-ES')}`;
}

// Formateador de empleo
function formatJob(job, grade) {
    if (!job || job === 'unemployed' || job === 'none' || job === 'civil') return 'Civil / Desempleado';
    if (job === 'police') return 'LSPD Agente';
    if (job === 'ambulance' || job === 'ems') return 'EMS Médico';
    if (job === 'mechanic') return 'Mecánico LS';
    if (job === 'taxi') return 'Taxista';
    if (job === 'cardealer') return 'Concesionario PDM';
    if (job === 'burgershot') return 'Burgershot';
    return job.charAt(0).toUpperCase() + job.slice(1);
}

// Listener de mensajes NUI procedentes de FiveM Client Lua
window.addEventListener('message', (event) => {
    let data = event.data;
    if (!data) return;
    
    if (data.action === "setupCharacters") {
        document.getElementById('app').style.display = 'block';
        initCountries();
        characters = data.characters || [];
        setupSlots(data.maxSlots || 4);
        switchScreen('character-selection');
    } else if (data.action === "reopenCreation") {
        document.getElementById('app').style.display = 'block';
        initCountries();
        switchScreen('character-creation');
        if (data.lastData) {
            if (data.lastData.slot) currentSlot = data.lastData.slot;
            if (data.lastData.firstname) document.getElementById('firstname').value = data.lastData.firstname;
            if (data.lastData.lastname) document.getElementById('lastname').value = data.lastData.lastname;
            if (data.lastData.nationality) document.getElementById('nationality').value = data.lastData.nationality;
            if (data.lastData.dob) document.getElementById('dob').value = data.lastData.dob;
            if (data.lastData.gender !== undefined) {
                const r = document.querySelector(`input[name="gender"][value="${data.lastData.gender}"]`);
                if (r) r.checked = true;
            }
        }
    } else if (data.action === "hideUI") {
        document.getElementById('app').style.display = 'none';
        resetPanels();
    }
});

function switchScreen(screenId) {
    document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
    const target = document.getElementById(screenId);
    if (target) target.classList.add('active');
}

function setupSlots(maxSlots) {
    const container = document.getElementById('slots-container');
    container.innerHTML = '';
    
    const countDisplay = document.getElementById('slots-count-display');
    if (countDisplay) {
        countDisplay.innerText = `${characters.length} / ${maxSlots} CREADOS`;
    }
    
    for (let i = 1; i <= maxSlots; i++) {
        const char = characters.find(c => c.slot === i);
        const slotDiv = document.createElement('div');
        
        if (char) {
            slotDiv.className = 'slot-card';
            slotDiv.dataset.slot = i;
            
            const avatarHtml = (char.mugshot && char.mugshot !== "none")
                ? `<img src="https://nui-img/${char.mugshot}/${char.mugshot}" class="slot-avatar-img" onerror="this.onerror=null; this.parentElement.innerHTML='<div class=\\'slot-fallback-initials\\'>${char.firstname.charAt(0)}${char.lastname.charAt(0)}</div>'">`
                : `<div class="slot-fallback-initials">${char.firstname.charAt(0)}${char.lastname.charAt(0)}</div>`;

            slotDiv.innerHTML = `
                <span class="slot-badge-num">SLOT 0${i}</span>
                <div class="slot-avatar-wrapper">
                    ${avatarHtml}
                </div>
                <span class="slot-char-name">${char.firstname} ${char.lastname}</span>
            `;
            slotDiv.onclick = () => selectCharacter(i, char);
        } else {
            slotDiv.className = 'slot-card empty';
            slotDiv.dataset.slot = i;
            slotDiv.innerHTML = `
                <span class="slot-badge-num">SLOT 0${i}</span>
                <i class="fa-solid fa-plus slot-empty-icon"></i>
                <span class="slot-empty-text">CREAR PERFIL</span>
            `;
            slotDiv.onclick = () => openCreation(i);
        }
        
        container.appendChild(slotDiv);
    }
    
    // Auto-seleccionar primer personaje existente o limpiar panel
    if (characters.length > 0) {
        selectCharacter(characters[0].slot, characters[0]);
    } else {
        resetPanels();
    }
}

function selectCharacter(slot, char) {
    currentSlot = slot;
    selectedCharId = char.id;
    
    // Actualizar clase activa en tarjetas de ranuras
    document.querySelectorAll('.slot-card').forEach((el) => {
        if (Number(el.dataset.slot) === slot) {
            el.classList.add('selected');
        } else {
            el.classList.remove('selected');
        }
    });

    // Encabezado del panel
    document.getElementById('info-name').innerText = `${char.firstname} ${char.lastname}`;
    document.getElementById('info-slot-badge').innerHTML = `<i class="fa-solid fa-id-badge"></i> SLOT 0${slot}`;
    document.getElementById('info-citizenid').innerHTML = `<i class="fa-solid fa-hashtag"></i> ID #${char.id || char.citizenid || '---'}`;

    // Atributos y Estadísticas Civiles
    document.getElementById('info-nationality').innerText = char.nationality || 'Desconocida';
    
    // Formato amigable de fecha de nacimiento
    let dobString = char.dob;
    if (typeof char.dob === 'number') {
        const d = new Date(char.dob);
        dobString = `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}/${d.getFullYear()}`;
    } else if (typeof char.dob === 'string' && char.dob.includes('-')) {
        const parts = char.dob.split('-');
        if (parts.length === 3) dobString = `${parts[2]}/${parts[1]}/${parts[0]}`;
    }
    document.getElementById('info-dob').innerText = dobString || '--/--/----';

    // Género
    const isFemale = Number(char.gender) === 1;
    document.getElementById('info-gender').innerHTML = isFemale
        ? '<span class="highlight-pink"><i class="fa-solid fa-venus"></i> Femenino</span>'
        : '<span class="highlight-cyan"><i class="fa-solid fa-mars"></i> Masculino</span>';

    // Finanzas (Cuentas bancarias y efectivo)
    const bankVal = (char.accounts && char.accounts.bank !== undefined) ? char.accounts.bank : ((char.metadata && char.metadata.bank) || 5000);
    const cashVal = (char.accounts && char.accounts.cash !== undefined) ? char.accounts.cash : ((char.metadata && char.metadata.cash) || 0);
    
    document.getElementById('info-bank').innerText = formatCurrency(bankVal);
    document.getElementById('info-cash').innerText = formatCurrency(cashVal);

    // Empleo
    const jobName = char.job || (char.metadata && char.metadata.job) || 'unemployed';
    const jobGrade = char.job_grade || 0;
    document.getElementById('info-job').innerText = formatJob(jobName, jobGrade);

    // Teléfono
    const phone = char.phone_number || (char.metadata && char.metadata.phone_number) || 'Sin asignar';
    document.getElementById('info-phone').innerText = phone;

    // Habilitar botones de acción
    document.getElementById('btn-play').disabled = false;
    document.getElementById('btn-delete').disabled = false;

    // Disparar vista previa 3D del Ped en vivo
    fetch(`https://${GetParentResourceName()}/previewCharacter`, {
        method: 'POST',
        body: JSON.stringify({ gender: Number(char.gender), metadata: char.metadata })
    }).catch(() => {});
}

function openCreation(slot) {
    currentSlot = slot;
    document.getElementById('creation-form').reset();
    
    // Marcar Masculino por defecto al abrir
    const maleRadio = document.getElementById('gender-m');
    if (maleRadio) maleRadio.checked = true;

    switchScreen('character-creation');
    
    // Vista previa de ped masculino base para la pantalla de creación
    fetch(`https://${GetParentResourceName()}/previewCharacter`, {
        method: 'POST',
        body: JSON.stringify({ gender: 0 })
    }).catch(() => {});
}

function resetPanels() {
    document.getElementById('info-name').innerText = 'SELECCIONA UN PERFIL';
    document.getElementById('info-slot-badge').innerHTML = '<i class="fa-solid fa-id-badge"></i> SLOT --';
    document.getElementById('info-citizenid').innerHTML = '<i class="fa-solid fa-hashtag"></i> ID #----';
    document.getElementById('info-job').innerText = 'Civil / Desempleado';
    document.getElementById('info-bank').innerText = '$0';
    document.getElementById('info-cash').innerText = '$0';
    document.getElementById('info-phone').innerText = '---';
    document.getElementById('info-nationality').innerText = '-';
    document.getElementById('info-dob').innerText = '-';
    document.getElementById('info-gender').innerText = '-';
    
    document.getElementById('btn-play').disabled = true;
    document.getElementById('btn-delete').disabled = true;
    
    document.querySelectorAll('.slot-card').forEach(el => el.classList.remove('selected'));
    
    // Ocultar el ped de previsualización
    fetch(`https://${GetParentResourceName()}/hidePed`, { method: 'POST' }).catch(() => {});
}

// Listeners de Formulario y Navegación
document.getElementById('btn-cancel-create').addEventListener('click', () => {
    switchScreen('character-selection');
    if (characters.length > 0) {
        selectCharacter(characters[0].slot, characters[0]);
    } else {
        resetPanels();
    }
});

document.getElementById('creation-form').addEventListener('submit', (e) => {
    e.preventDefault();
    
    const firstname = document.getElementById('firstname').value.trim();
    const lastname = document.getElementById('lastname').value.trim();
    const nationality = document.getElementById('nationality').value;
    const dob = document.getElementById('dob').value;
    const gender = parseInt(document.querySelector('input[name="gender"]:checked').value);
    
    fetch(`https://${GetParentResourceName()}/createCharacter`, {
        method: 'POST',
        body: JSON.stringify({
            slot: currentSlot,
            firstname,
            lastname,
            nationality,
            dob,
            gender
        })
    }).then(() => {
        switchScreen('character-selection');
    }).catch(() => {
        switchScreen('character-selection');
    });
});

// Cambio interactivo de género en la creación -> Actualiza el Ped 3D en tiempo real
document.querySelectorAll('input[name="gender"]').forEach(radio => {
    radio.addEventListener('change', (e) => {
        fetch(`https://${GetParentResourceName()}/previewCharacter`, {
            method: 'POST',
            body: JSON.stringify({ gender: Number(e.target.value) })
        }).catch(() => {});
    });
});

// Botón de Jugar / Entrar al Mundo
document.getElementById('btn-play').addEventListener('click', () => {
    if (!selectedCharId) return;
    
    fetch(`https://${GetParentResourceName()}/selectCharacter`, {
        method: 'POST',
        body: JSON.stringify({ id: selectedCharId, slot: currentSlot })
    }).catch(() => {});
});

// Modal de Seguridad para Borrado de Personajes
document.getElementById('btn-delete').addEventListener('click', () => {
    if (!selectedCharId) return;
    const char = characters.find(c => c.id === selectedCharId);
    const deleteNameElem = document.getElementById('delete-char-name');
    if (deleteNameElem && char) {
        deleteNameElem.innerText = `${char.firstname} ${char.lastname}`;
    }
    document.getElementById('delete-modal').style.display = 'flex';
});

document.getElementById('btn-cancel-delete').addEventListener('click', () => {
    document.getElementById('delete-modal').style.display = 'none';
});

document.getElementById('btn-confirm-delete').addEventListener('click', () => {
    document.getElementById('delete-modal').style.display = 'none';
    if (!selectedCharId) return;
    
    fetch(`https://${GetParentResourceName()}/deleteCharacter`, {
        method: 'POST',
        body: JSON.stringify({ slot: currentSlot })
    }).catch(() => {});
});

