let characters = [];
let currentSlot = 1;
let selectedCharId = null;

const countries = [
    "Afganistán", "Albania", "Alemania", "Andorra", "Angola", "Antigua y Barbuda", "Arabia Saudita", "Argelia", "Argentina", "Armenia", "Australia", "Austria", "Azerbaiyán", "Bahamas", "Bangladés", "Barbados", "Baréin", "Bélgica", "Belice", "Benín", "Bielorrusia", "Birmania", "Bolivia", "Bosnia y Herzegovina", "Botsuana", "Brasil", "Brunéi", "Bulgaria", "Burkina Faso", "Burundi", "Bután", "Cabo Verde", "Camboya", "Camerún", "Canadá", "Catar", "Chad", "Chile", "China", "Chipre", "Ciudad del Vaticano", "Colombia", "Comoras", "Corea del Norte", "Corea del Sur", "Costa de Marfil", "Costa Rica", "Croacia", "Cuba", "Dinamarca", "Dominica", "Ecuador", "Egipto", "El Salvador", "Emiratos Árabes Unidos", "Eritrea", "Eslovaquia", "Eslovenia", "España", "Estados Unidos", "Estonia", "Etiopía", "Filipinas", "Finlandia", "Fiyi", "Francia", "Gabón", "Gambia", "Georgia", "Ghana", "Granada", "Grecia", "Guatemala", "Guyana", "Guinea", "Guinea ecuatorial", "Guinea-Bisáu", "Haití", "Honduras", "Hungría", "India", "Indonesia", "Irak", "Irán", "Irlanda", "Islandia", "Islas Marshall", "Islas Salomón", "Israel", "Italia", "Jamaica", "Japón", "Jordania", "Kazajistán", "Kenia", "Kirguistán", "Kiribati", "Kuwait", "Laos", "Lesoto", "Letonia", "Líbano", "Liberia", "Libia", "Liechtenstein", "Lituania", "Luxemburgo", "Macedonia del Norte", "Madagascar", "Malasia", "Malaui", "Maldivas", "Malí", "Malta", "Marruecos", "Mauricio", "Mauritania", "México", "Micronesia", "Moldavia", "Mónaco", "Mongolia", "Montenegro", "Mozambique", "Namibia", "Nauru", "Nepal", "Nicaragua", "Níger", "Nigeria", "Noruega", "Nueva Zelanda", "Omán", "Países Bajos", "Pakistán", "Palaos", "Panamá", "Papúa Nueva Guinea", "Paraguay", "Perú", "Polonia", "Portugal", "Reino Unido", "República Centroafricana", "República Checa", "República del Congo", "República Democrática del Congo", "República Dominicana", "Ruanda", "Rumanía", "Rusia", "Samoa", "San Cristóbal y Nieves", "San Marino", "San Vicente y las Granadinas", "Santa Lucía", "Santo Tomé y Príncipe", "Senegal", "Serbia", "Seychelles", "Sierra Leona", "Singapur", "Siria", "Somalia", "Sri Lanka", "Suazilandia", "Sudáfrica", "Sudán", "Sudán del Sur", "Suecia", "Suiza", "Surinam", "Tailandia", "Tanzania", "Tayikistán", "Timor Oriental", "Togo", "Tonga", "Trinidad y Tobago", "Túnez", "Turkmenistán", "Turquía", "Tuvalu", "Ucrania", "Uganda", "Uruguay", "Uzbekistán", "Vanuatu", "Venezuela", "Vietnam", "Yemen", "Yibuti", "Zambia", "Zimbabue"
];

function initCountries() {
    const natSelect = document.getElementById('nationality');
    if(natSelect && natSelect.options.length <= 1) {
        countries.forEach(c => {
            let opt = document.createElement('option');
            opt.value = c;
            opt.innerHTML = c;
            natSelect.appendChild(opt);
        });
    }
}

window.addEventListener('message', (event) => {
    let data = event.data;
    
    if (data.action === "setupCharacters") {
        document.getElementById('app').style.display = 'block';
        initCountries();
        characters = data.characters;
        setupSlots(data.maxSlots);
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
    document.getElementById(screenId).classList.add('active');
}

function setupSlots(maxSlots) {
    const container = document.getElementById('slots-container');
    container.innerHTML = '';
    
    for (let i = 1; i <= maxSlots; i++) {
        const char = characters.find(c => c.slot === i);
        const slotDiv = document.createElement('div');
        
        if (char) {
            slotDiv.className = 'slot';
            if (char.mugshot && char.mugshot !== "none") {
                slotDiv.innerHTML = `<img src="https://nui-img/${char.mugshot}/${char.mugshot}" class="slot-avatar">`;
            } else {
                slotDiv.innerHTML = `<div class="slot-avatar fallback-avatar">${char.firstname.charAt(0)}${char.lastname.charAt(0)}</div>`;
            }
            slotDiv.onclick = () => selectCharacter(i, char);
        } else {
            slotDiv.className = 'slot empty';
            slotDiv.innerHTML = '+';
            slotDiv.onclick = () => openCreation(i);
        }
        
        container.appendChild(slotDiv);
    }
    
    // Select first slot auto if exists
    if(characters.length > 0) {
        selectCharacter(characters[0].slot, characters[0]);
    } else {
        resetPanels();
    }
}

function selectCharacter(slot, char) {
    currentSlot = slot;
    selectedCharId = char.id;
    
    document.querySelectorAll('.slot').forEach((el, idx) => {
        if(idx + 1 === slot) el.classList.add('selected');
        else el.classList.remove('selected');
    });

    document.getElementById('info-name').innerText = `${char.firstname} ${char.lastname}`;
    document.getElementById('info-nationality').innerText = char.nationality;
    
    // Parsear fecha de nacimiento para evitar Unix Timestamps o mal formato
    let dobString = char.dob;
    if (typeof char.dob === 'number') {
        const d = new Date(char.dob);
        dobString = `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}/${d.getFullYear()}`;
    } else if (typeof char.dob === 'string' && char.dob.includes('-')) {
        const parts = char.dob.split('-');
        if (parts.length === 3) dobString = `${parts[2]}/${parts[1]}/${parts[0]}`;
    }
    document.getElementById('info-dob').innerText = dobString;
    
    document.getElementById('btn-play').disabled = false;
    document.getElementById('btn-delete').disabled = false;

    // Trigger visual preview of Ped
    fetch(`https://${GetParentResourceName()}/previewCharacter`, {
        method: 'POST',
        body: JSON.stringify({ gender: Number(char.gender), metadata: char.metadata })
    });
}

function openCreation(slot) {
    currentSlot = slot;
    document.getElementById('creation-form').reset();
    switchScreen('character-creation');
    
    // Preview base male ped for creation screen
    fetch(`https://${GetParentResourceName()}/previewCharacter`, {
        method: 'POST',
        body: JSON.stringify({ gender: 0 })
    });
}

function resetPanels() {
    document.getElementById('info-name').innerText = 'SELECCIONA UN PERFIL';
    document.getElementById('info-nationality').innerText = '-';
    document.getElementById('info-dob').innerText = '-';
    document.getElementById('btn-play').disabled = true;
    document.getElementById('btn-delete').disabled = true;
    
    document.querySelectorAll('.slot').forEach(el => el.classList.remove('selected'));
    
    // Ocultar el ped de previsualización si no hay perfil seleccionado
    fetch(`https://${GetParentResourceName()}/hidePed`, { method: 'POST' }).catch(() => {});
}

// Listeners Formulario y Botones
document.getElementById('btn-cancel-create').addEventListener('click', () => {
    switchScreen('character-selection');
    if(characters.length > 0) {
        selectCharacter(characters[0].slot, characters[0]);
    } else {
        resetPanels();
    }
});

document.getElementById('creation-form').addEventListener('submit', (e) => {
    e.preventDefault();
    
    const firstname = document.getElementById('firstname').value;
    const lastname = document.getElementById('lastname').value;
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
    });
});

document.querySelectorAll('input[name="gender"]').forEach(radio => {
    radio.addEventListener('change', (e) => {
        fetch(`https://${GetParentResourceName()}/previewCharacter`, {
            method: 'POST',
            body: JSON.stringify({ gender: Number(e.target.value) })
        });
    });
});

document.getElementById('btn-play').addEventListener('click', () => {
    if(!selectedCharId) return;
    const char = characters.find(c => c.id === selectedCharId);
    
    fetch(`https://${GetParentResourceName()}/selectCharacter`, {
        method: 'POST',
        body: JSON.stringify({ id: selectedCharId, slot: currentSlot })
    });
});

// Lógica de Borrado con Modal
document.getElementById('btn-delete').addEventListener('click', () => {
    if(!selectedCharId) return;
    document.getElementById('delete-modal').style.display = 'flex';
});

document.getElementById('btn-cancel-delete').addEventListener('click', () => {
    document.getElementById('delete-modal').style.display = 'none';
});

document.getElementById('btn-confirm-delete').addEventListener('click', () => {
    document.getElementById('delete-modal').style.display = 'none';
    if(!selectedCharId) return;
    
    fetch(`https://${GetParentResourceName()}/deleteCharacter`, {
        method: 'POST',
        body: JSON.stringify({ slot: currentSlot })
    });
});
