// Aura Appearance UI Controller - Solid State Architecture v5 (Extended Luxury Color System)

const GTA_HAIR_PALETTE = [
  { id: 0, hex: "#1c1f21", name: "Negro Azabache", cat: "black_brown" },
  { id: 1, hex: "#272a2c", name: "Negro Oscuro", cat: "black_brown" },
  { id: 2, hex: "#312e2c", name: "Castaño Muy Oscuro", cat: "black_brown" },
  { id: 3, hex: "#35261c", name: "Castaño Café", cat: "black_brown" },
  { id: 4, hex: "#4b321f", name: "Castaño Profundo", cat: "black_brown" },
  { id: 5, hex: "#5c3b24", name: "Castaño Chocolate", cat: "black_brown" },
  { id: 6, hex: "#6d4c35", name: "Castaño Medio", cat: "black_brown" },
  { id: 7, hex: "#6b503b", name: "Castaño Claro", cat: "black_brown" },
  { id: 8, hex: "#765c45", name: "Castaño Avellana", cat: "black_brown" },
  { id: 9, hex: "#7f684e", name: "Rubio Ceniza Oscuro", cat: "blonde" },
  { id: 10, hex: "#99815d", name: "Rubio Dorado Oscuro", cat: "blonde" },
  { id: 11, hex: "#a79369", name: "Rubio Medio", cat: "blonde" },
  { id: 12, hex: "#af9c70", name: "Rubio Trigo", cat: "blonde" },
  { id: 13, hex: "#bba063", name: "Rubio Claro", cat: "blonde" },
  { id: 14, hex: "#d6b97b", name: "Rubio Platino Cálido", cat: "blonde" },
  { id: 15, hex: "#dac38e", name: "Rubio Miel", cat: "blonde" },
  { id: 16, hex: "#9f7f59", name: "Caramelo Tostado", cat: "blonde" },
  { id: 17, hex: "#845039", name: "Castaño Caoba", cat: "red" },
  { id: 18, hex: "#682b1f", name: "Auburn / Castaño Rojizo", cat: "red" },
  { id: 19, hex: "#61120c", name: "Rojo Oscuro", cat: "red" },
  { id: 20, hex: "#640f0a", name: "Rojo Carmesí", cat: "red" },
  { id: 21, hex: "#7c140f", name: "Rojo Intenso", cat: "red" },
  { id: 22, hex: "#a02e19", name: "Rojo Cobrizo", cat: "red" },
  { id: 23, hex: "#b24225", name: "Cobre Brillante", cat: "red" },
  { id: 24, hex: "#b4522a", name: "Naranja Tiziano", cat: "red" },
  { id: 25, hex: "#933f1e", name: "Fresa Oscuro", cat: "red" },
  { id: 26, hex: "#7d3e2c", name: "Rubio Fresa", cat: "red" },
  { id: 27, hex: "#56241c", name: "Castaño Castaña", cat: "black_brown" },
  { id: 28, hex: "#301008", name: "Chocolate Oscuro", cat: "black_brown" },
  { id: 29, hex: "#1e0904", name: "Carbón Suave", cat: "black_brown" },
  { id: 30, hex: "#4e322e", name: "Ceniza Profundo", cat: "black_brown" },
  { id: 31, hex: "#704935", name: "Ceniza Medio", cat: "black_brown" },
  { id: 32, hex: "#875a3c", name: "Castaño Ámbar", cat: "blonde" },
  { id: 33, hex: "#a47853", name: "Bronce Cálido", cat: "blonde" },
  { id: 34, hex: "#b99066", name: "Rubio Bronce", cat: "blonde" },
  { id: 35, hex: "#c3a27a", name: "Rubio Soleado", cat: "blonde" },
  { id: 36, hex: "#dfb586", name: "Rubio Arena", cat: "blonde" },
  { id: 37, hex: "#b28b67", name: "Rubio Ceniza Claro", cat: "blonde" },
  { id: 38, hex: "#6f4534", name: "Cobre Apagado", cat: "red" },
  { id: 39, hex: "#4c281e", name: "Bronce Rojizo", cat: "red" },
  { id: 40, hex: "#351810", name: "Caoba Oscuro", cat: "red" },
  { id: 41, hex: "#241109", name: "Ébano Oscuro", cat: "black_brown" },
  { id: 42, hex: "#4f443b", name: "Gris Pizarra", cat: "silver" },
  { id: 43, hex: "#574334", name: "Gris Ceniza", cat: "silver" },
  { id: 44, hex: "#49372b", name: "Plata Oscuro", cat: "silver" },
  { id: 45, hex: "#30241b", name: "Gris Carbón", cat: "silver" },
  { id: 46, hex: "#453831", name: "Plata Medio", cat: "silver" },
  { id: 47, hex: "#604f44", name: "Plata Brillante", cat: "silver" },
  { id: 48, hex: "#796756", name: "Blanco Plata", cat: "silver" },
  { id: 49, hex: "#8d7967", name: "Blanco Platino", cat: "silver" },
  { id: 50, hex: "#b19e8a", name: "Escarcha Ártica", cat: "silver" },
  { id: 51, hex: "#c6b5a1", name: "Blanco Puro", cat: "silver" },
  { id: 52, hex: "#a68b72", name: "Hielo Platino", cat: "silver" },
  { id: 53, hex: "#886b53", name: "Hielo Dorado", cat: "silver" },
  { id: 54, hex: "#2b3e42", name: "Azul Acero", cat: "fantasy" },
  { id: 55, hex: "#1d536b", name: "Azul Marino Neón", cat: "fantasy" },
  { id: 56, hex: "#287594", name: "Azul Eléctrico", cat: "fantasy" },
  { id: 57, hex: "#359ec7", name: "Azul Turquesa", cat: "fantasy" },
  { id: 58, hex: "#296d4e", name: "Verde Bosque", cat: "fantasy" },
  { id: 59, hex: "#3aa16a", name: "Verde Esmeralda", cat: "fantasy" },
  { id: 60, hex: "#78b438", name: "Verde Lima Neón", cat: "fantasy" },
  { id: 61, hex: "#a88827", name: "Amarillo Dorado", cat: "fantasy" },
  { id: 62, hex: "#b8478f", name: "Rosa Magenta", cat: "fantasy" },
  { id: 63, hex: "#783387", name: "Púrpura Imperial", cat: "fantasy" }
];

const GTA_MAKEUP_PALETTE = [
  { id: 0, hex: "#99253b", name: "Rojo Rubí", cat: "reds" },
  { id: 1, hex: "#b83b54", name: "Rosa Carmesí", cat: "pinks" },
  { id: 2, hex: "#c44b63", name: "Frambuesa", cat: "pinks" },
  { id: 3, hex: "#a82e46", name: "Vino Suave", cat: "reds" },
  { id: 4, hex: "#871f34", name: "Borgoña Intenso", cat: "reds" },
  { id: 5, hex: "#d45771", name: "Rosa Coral", cat: "pinks" },
  { id: 6, hex: "#e06c84", name: "Rosa Pastel", cat: "pinks" },
  { id: 7, hex: "#b0435b", name: "Rosa Malva", cat: "pinks" },
  { id: 8, hex: "#6b1223", name: "Cereza Negro", cat: "dark" },
  { id: 9, hex: "#82192d", name: "Granate Profundo", cat: "reds" },
  { id: 10, hex: "#ba324c", name: "Rojo Pasión", cat: "reds" },
  { id: 11, hex: "#db4867", name: "Fucsia Vibrante", cat: "pinks" },
  { id: 12, hex: "#f06e8b", name: "Rosa Chicle", cat: "pinks" },
  { id: 13, hex: "#c74662", name: "Rosa Clásico", cat: "pinks" },
  { id: 14, hex: "#9e2840", name: "Sangría", cat: "reds" },
  { id: 15, hex: "#631022", name: "Vampiro", cat: "dark" },
  { id: 16, hex: "#8f1c32", name: "Rojo Granate", cat: "reds" },
  { id: 17, hex: "#ab2c45", name: "Rojo Terciopelo", cat: "reds" },
  { id: 18, hex: "#c9425e", name: "Rosa Sandía", cat: "pinks" },
  { id: 19, hex: "#de5977", name: "Flamingo", cat: "pinks" },
  { id: 20, hex: "#f57896", name: "Rosa Bebé", cat: "pinks" },
  { id: 21, hex: "#bd3a55", name: "Flor de Loto", cat: "pinks" },
  { id: 22, hex: "#942038", name: "Rojo Cereza", cat: "reds" },
  { id: 23, hex: "#611022", name: "Ciruela Oscuro", cat: "dark" },
  { id: 24, hex: "#a6324b", name: "Orquídea", cat: "purple" },
  { id: 25, hex: "#c44965", name: "Peonía", cat: "pinks" },
  { id: 26, hex: "#db607e", name: "Tulipán", cat: "pinks" },
  { id: 27, hex: "#f07a99", name: "Algodón de Azúcar", cat: "pinks" },
  { id: 28, hex: "#ff96b3", name: "Rosa Suave", cat: "pinks" },
  { id: 29, hex: "#cc5270", name: "Rosa Antiguo", cat: "pinks" },
  { id: 30, hex: "#9c2a44", name: "Grosella", cat: "reds" },
  { id: 31, hex: "#661427", name: "Mora Negra", cat: "dark" },
  { id: 32, hex: "#b54a3a", name: "Terracota", cat: "nudes" },
  { id: 33, hex: "#c75c4c", name: "Coral Cálido", cat: "nudes" },
  { id: 34, hex: "#db7363", name: "Salmón", cat: "nudes" },
  { id: 35, hex: "#eb8878", name: "Melocotón Suave", cat: "nudes" },
  { id: 36, hex: "#faa193", name: "Nude Melocotón", cat: "nudes" },
  { id: 37, hex: "#cc6252", name: "Ladrillo Claro", cat: "nudes" },
  { id: 38, hex: "#9e3f31", name: "Ladrillo Intenso", cat: "nudes" },
  { id: 39, hex: "#6e251a", name: "Café Rojizo", cat: "dark" },
  { id: 40, hex: "#c4724d", name: "Caramelo Nude", cat: "nudes" },
  { id: 41, hex: "#d48663", name: "Canela Suave", cat: "nudes" },
  { id: 42, hex: "#e39a78", name: "Nude Cálido", cat: "nudes" },
  { id: 43, hex: "#f0ad8d", name: "Beige Rosado", cat: "nudes" },
  { id: 44, hex: "#fcc2a4", name: "Nude Porcelana", cat: "nudes" },
  { id: 45, hex: "#d48663", name: "Arena Suave", cat: "nudes" },
  { id: 46, hex: "#a85d3b", name: "Bronce Natural", cat: "nudes" },
  { id: 47, hex: "#75391d", name: "Chocolate Caliente", cat: "dark" },
  { id: 48, hex: "#8f447d", name: "Lavanda Oscuro", cat: "purple" },
  { id: 49, hex: "#a35591", name: "Violeta Místico", cat: "purple" },
  { id: 50, hex: "#b869a6", name: "Lila Eléctrico", cat: "purple" },
  { id: 51, hex: "#cc7dbb", name: "Orquídea Suave", cat: "purple" },
  { id: 52, hex: "#df91cf", name: "Lila Pastel", cat: "purple" },
  { id: 53, hex: "#b563a1", name: "Baya Malva", cat: "purple" },
  { id: 54, hex: "#873c73", name: "Ciruela Silvestre", cat: "purple" },
  { id: 55, hex: "#5c204d", name: "Medianoche Púrpura", cat: "dark" },
  { id: 56, hex: "#4a3832", name: "Marrón Moca", cat: "dark" },
  { id: 57, hex: "#634d45", name: "Cacao", cat: "nudes" },
  { id: 58, hex: "#7d6359", name: "Nude Ceniza", cat: "nudes" },
  { id: 59, hex: "#94786e", name: "Gris Cálido", cat: "nudes" },
  { id: 60, hex: "#ad8f84", name: "Champagne Nude", cat: "nudes" },
  { id: 61, hex: "#695047", name: "Tierra de Sombra", cat: "dark" },
  { id: 62, hex: "#47342e", name: "Espresso", cat: "dark" },
  { id: 63, hex: "#1f1512", name: "Negro Ónix", cat: "dark" }
];

const HAIR_CATEGORIES = [
  { id: "all", label: "Todos (64)" },
  { id: "black_brown", label: "🖤 Negros & Castaños" },
  { id: "blonde", label: "💛 Rubios & Dorados" },
  { id: "red", label: "🧡 Rojos & Cobrizos" },
  { id: "silver", label: "🤍 Platinos & Canas" },
  { id: "fantasy", label: "💜 Fantasía & Neón" }
];

const MAKEUP_CATEGORIES = [
  { id: "all", label: "Todos (64)" },
  { id: "nudes", label: "🌸 Nudes & Naturales" },
  { id: "pinks", label: "💄 Rosas & Fucsias" },
  { id: "reds", label: "💋 Rojos & Carmesí" },
  { id: "purple", label: "🍇 Morados & Lilas" },
  { id: "dark", label: "🖤 Oscuros & Góticos" }
];

const EYE_COLORS = [
  "Verde", "Esmeralda", "Azul Claro", "Azul Océano", "Marrón Claro", "Marrón Oscuro",
  "Avellana", "Gris Oscuro", "Gris Claro", "Rosa", "Amarillo", "Púrpura", "Blackout",
  "Gris Degradado", "Tequila Sunrise", "Atómico", "Warp", "ECola", "Space Ranger",
  "Ying Yang", "Bullseye", "Lagarto", "Dragón", "Extraterrestre", "Cabra", "Smiley",
  "Poseído", "Demonio", "Infectado", "Alien", "No Muerto", "Zombie"
];

const FATHERS = {
  0: "Benjamin", 1: "Daniel", 2: "Joshua", 3: "Noah", 4: "Andrew", 5: "Juan", 6: "Alex",
  7: "Isaac", 8: "Evan", 9: "Ethan", 10: "Vincent", 11: "Angel", 12: "Diego", 13: "Adrian",
  14: "Gabriel", 15: "Michael", 16: "Santiago", 17: "Kevin", 18: "Louis", 19: "Samuel",
  20: "Anthony", 42: "John", 43: "Niko", 44: "Claude"
};

const MOTHERS = {
  21: "Hannah", 22: "Audrey", 23: "Jasmine", 24: "Giselle", 25: "Amelia", 26: "Isabella",
  27: "Zoe", 28: "Ava", 29: "Camila", 30: "Violet", 31: "Sophia", 32: "Evelyn",
  33: "Nicole", 34: "Paige", 35: "Natalie", 36: "Olivia", 37: "Elizabeth", 38: "Charlotte",
  39: "Emma", 40: "Misty", 41: "Grace", 45: "Debra"
};

const FACE_FEATURE_GROUPS = {
  nose: {
    title: "Nariz",
    icon: "fa-solid fa-wind",
    features: {
      noseWidth: "Ancho de la Nariz",
      nosePeakHigh: "Altura de la Punta",
      nosePeakSize: "Longitud de la Punta",
      noseBoneHigh: "Puente Nasal (Altura)",
      nosePeakLowering: "Inclinación de la Punta",
      noseBoneTwist: "Torsión del Tabique"
    }
  },
  eyes: {
    title: "Ojos y Cejas",
    icon: "fa-solid fa-eye",
    features: {
      eyesOpening: "Apertura de los Ojos",
      eyeBrownHigh: "Altura de las Cejas",
      eyeBrownForward: "Profundidad de las Cejas"
    }
  },
  cheeks: {
    title: "Pómulos y Mejillas",
    icon: "fa-solid fa-face-smile",
    features: {
      cheeksBoneHigh: "Altura de Pómulos",
      cheeksBoneWidth: "Ancho de Pómulos",
      cheeksWidth: "Profundidad de Mejillas"
    }
  },
  mouth: {
    title: "Boca y Labios",
    icon: "fa-solid fa-lips",
    features: {
      lipsThickness: "Grosor de los Labios",
      jawBoneWidth: "Ancho de la Mandíbula",
      jawBoneBackSize: "Longitud de Mandíbula"
    }
  },
  chin: {
    title: "Mentón y Cuello",
    icon: "fa-solid fa-user",
    features: {
      chinBoneLowering: "Altura del Mentón",
      chinBoneLenght: "Longitud del Mentón",
      chinBoneSize: "Ancho del Mentón",
      chinHole: "Hendidura del Mentón",
      neckThickness: "Grosor del Cuello"
    }
  }
};

const CLOTHING_UPPER = [
  { id: 11, label: "Chaquetas y Abrigos", icon: "fa-vest" },
  { id: 8, label: "Camisetas / Interior", icon: "fa-shirt" },
  { id: 3, label: "Torso / Brazos / Guantes", icon: "fa-hand" },
  { id: 9, label: "Chalecos Antibalas", icon: "fa-shield-halved" },
  { id: 10, label: "Insignias / Calcomanías", icon: "fa-certificate" }
];

const CLOTHING_LOWER = [
  { id: 4, label: "Pantalones", icon: "fa-socks" },
  { id: 6, label: "Calzado / Zapatos", icon: "fa-shoe-prints" },
  { id: 5, label: "Mochilas y Bolsas", icon: "fa-bag-shopping" },
  { id: 1, label: "Máscaras y Pasamontañas", icon: "fa-mask" },
  { id: 7, label: "Cadenas y Cuello", icon: "fa-gem" }
];

const PROP_ITEMS = [
  { id: 0, label: "Sombreros y Cascos", icon: "fa-hat-cowboy" },
  { id: 1, label: "Gafas de Sol / Lentes", icon: "fa-glasses" },
  { id: 2, label: "Pendientes / Orejas", icon: "fa-ear-listen" },
  { id: 6, label: "Relojes", icon: "fa-clock" },
  { id: 7, label: "Pulseras", icon: "fa-ring" }
];

class AppearanceApp {
  constructor() {
    this.appEl = document.getElementById("app");
    this.contentEl = document.getElementById("tab-content");
    this.subNavEl = document.getElementById("sub-nav");
    this.currentTab = "genetics";
    this.currentSubTab = null;
    this.config = {};
    this.settings = {};
    this.data = {};
    this.isUndressed = false;
    this.isDragging = false;
    this.lastMouseX = 0;

    this.initEvents();
    this.initDragOrbit();
  }

  post(endpoint, data = {}) {
    return fetch(`https://illenium-appearance/${endpoint}`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify(data)
    }).then(res => res.json()).catch(() => ({}));
  }

  initEvents() {
    window.addEventListener("message", async (e) => {
      const msg = e.data;
      if (msg.type === "appearance_display") {
        await this.loadInitialData();
        this.appEl.classList.add("visible");
      } else if (msg.type === "appearance_hide") {
        this.appEl.classList.remove("visible");
      }
    });

    // Wheel Scroll Support across the whole panel
    const panelEl = document.querySelector(".appearance-panel");
    panelEl.addEventListener("wheel", (e) => {
      // Check if mouse is hovering over an inner color palette grid that can still scroll
      const innerGrid = e.target.closest(".color-palette-grid");
      if (innerGrid) {
        const canScrollUp = innerGrid.scrollTop > 0 && e.deltaY < 0;
        const canScrollDown = (innerGrid.scrollTop + innerGrid.clientHeight < innerGrid.scrollHeight - 1) && e.deltaY > 0;
        if (canScrollUp || canScrollDown) return;
      }
      this.contentEl.scrollTop += e.deltaY * 0.9;
    }, { passive: true });

    // Main Tab Navigation
    document.querySelectorAll(".nav-tab").forEach(tab => {
      tab.addEventListener("click", () => {
        if (this.currentTab === tab.dataset.tab) return;
        document.querySelectorAll(".nav-tab").forEach(t => t.classList.remove("active"));
        tab.classList.add("active");
        this.currentTab = tab.dataset.tab;
        this.currentSubTab = null;
        this.handleAutoCamera(this.currentTab);
        this.render();
      });
    });

    // Vertical HUD Camera Buttons
    document.querySelectorAll(".hud-cam-btn").forEach(btn => {
      btn.addEventListener("click", () => {
        document.querySelectorAll(".hud-cam-btn").forEach(b => b.classList.remove("active"));
        btn.classList.add("active");
        this.post("appearance_set_camera", btn.dataset.cam);
      });
    });

    // HUD 180° Turn
    document.getElementById("btn-turn-around").addEventListener("click", () => {
      this.post("appearance_turn_around");
    });

    // HUD Rotate Left / Right
    document.getElementById("btn-rotate-left").addEventListener("click", () => {
      this.post("rotate_left");
    });
    document.getElementById("btn-rotate-right").addEventListener("click", () => {
      this.post("rotate_right");
    });

    // HUD Toggle Clothes (Undress)
    document.getElementById("btn-toggle-clothes").addEventListener("click", () => {
      this.isUndressed = !this.isUndressed;
      const btn = document.getElementById("btn-toggle-clothes");
      if (this.isUndressed) {
        btn.classList.add("active");
        btn.innerHTML = '<i class="fa-solid fa-shirt"></i> <span>Vestir</span>';
        this.post("appearance_remove_clothes", "body");
        this.post("appearance_remove_clothes", "bottom");
      } else {
        btn.classList.remove("active");
        btn.innerHTML = '<i class="fa-solid fa-shirt"></i> <span>Desvestir</span>';
        this.post("appearance_wear_clothes", { data: this.data, key: "body" });
        this.post("appearance_wear_clothes", { data: this.data, key: "bottom" });
      }
    });

    // Save Modal
    document.getElementById("btn-save-character").addEventListener("click", () => {
      document.getElementById("save-modal").classList.add("active");
    });

    document.getElementById("btn-cancel-save").addEventListener("click", () => {
      document.getElementById("save-modal").classList.remove("active");
    });

    document.getElementById("btn-confirm-save").addEventListener("click", () => {
      document.getElementById("save-modal").classList.remove("active");
      this.data.tattoos = this.data.tattoos || {};
      this.post("appearance_save", this.data);
    });

    // Exit
    document.getElementById("btn-exit-character").addEventListener("click", () => {
      this.post("appearance_exit");
    });
  }

  initDragOrbit() {
    const dragLayer = document.querySelector(".viewport-drag-layer");
    
    dragLayer.addEventListener("mousedown", (e) => {
      if (e.button === 0 || e.button === 2) {
        this.isDragging = true;
        this.lastMouseX = e.clientX;
      }
    });

    window.addEventListener("mousemove", (e) => {
      if (!this.isDragging) return;
      const deltaX = e.clientX - this.lastMouseX;
      this.lastMouseX = e.clientX;

      if (Math.abs(deltaX) > 0) {
        this.post("appearance_rotate_heading", { delta: -deltaX * 0.9 });
      }
    });

    window.addEventListener("mouseup", () => {
      this.isDragging = false;
    });

    window.addEventListener("contextmenu", (e) => {
      if (this.isDragging) e.preventDefault();
    });
  }

  handleAutoCamera(tab) {
    let targetCam = "default";
    if (tab === "genetics" || tab === "features" || tab === "appearance") {
      targetCam = "head";
    } else if (tab === "clothes") {
      targetCam = (this.currentSubTab === "lower") ? "bottom" : "body";
    } else if (tab === "props") {
      targetCam = "head";
    }

    document.querySelectorAll(".hud-cam-btn").forEach(b => {
      b.classList.toggle("active", b.dataset.cam === targetCam);
    });
    this.post("appearance_set_camera", targetCam);
  }

  async loadInitialData() {
    const [settingsRes, dataRes] = await Promise.all([
      this.post("appearance_get_settings"),
      this.post("appearance_get_data")
    ]);

    this.settings = settingsRes.appearanceSettings || {};
    this.config = dataRes.config || {};
    this.data = dataRes.appearanceData || {};

    // Ensure headOverlays table is fully populated with proper casing
    this.data.headOverlays = this.data.headOverlays || {};
    const defaultOverlays = [
      "blemishes", "beard", "eyebrows", "ageing", "makeUp", "blush",
      "complexion", "sunDamage", "lipstick", "moleAndFreckles", "chestHair", "bodyBlemishes"
    ];
    defaultOverlays.forEach(k => {
      if (!this.data.headOverlays[k]) {
        this.data.headOverlays[k] = { style: 0, opacity: 0, color: 0, secondColor: 0 };
      }
    });

    const isFemale = this.data.model === "mp_f_freemode_01";
    document.getElementById("gender-label").innerText = isFemale ? "Femenino" : "Masculino";
    document.getElementById("gender-icon").className = isFemale ? "fa-solid fa-venus" : "fa-solid fa-mars";

    const exitBtn = document.getElementById("btn-exit-character");
    if (exitBtn) {
      exitBtn.style.display = "flex";
    }

    this.render();
  }

  render() {
    this.subNavEl.innerHTML = "";
    this.contentEl.innerHTML = "";

    switch (this.currentTab) {
      case "genetics":
        this.renderGenetics();
        break;
      case "features":
        this.renderFaceFeatures();
        break;
      case "appearance":
        this.renderAppearance();
        break;
      case "clothes":
        this.renderClothes();
        break;
      case "props":
        this.renderProps();
        break;
    }
  }

  // 🧬 1. GENÉTICA
  renderGenetics() {
    this.subNavEl.innerHTML = "";
    this.contentEl.innerHTML = "";

    const blend = this.data.headBlend || {
      shapeFirst: 0, shapeSecond: 21, shapeMix: 0.5,
      skinFirst: 0, skinSecond: 21, skinMix: 0.5
    };

    const container = document.createElement("div");
    container.className = "section-group";
    container.innerHTML = `
      <div class="section-header">
        <div class="section-title"><i class="fa-solid fa-dna"></i> Herencia Genética</div>
      </div>

      <div class="heritage-stack">
        <!-- Padre -->
        <div class="heritage-card">
          <div class="heritage-card-header">
            <span><i class="fa-solid fa-mars"></i> Padre</span>
            <span class="parent-name-badge" id="father-name">${FATHERS[blend.shapeFirst] || "Padre #" + blend.shapeFirst}</span>
          </div>
          <div class="stepper-holder" id="step-shape-first"></div>
        </div>

        <!-- Madre -->
        <div class="heritage-card">
          <div class="heritage-card-header">
            <span><i class="fa-solid fa-venus"></i> Madre</span>
            <span class="parent-name-badge" id="mother-name">${MOTHERS[blend.shapeSecond] || "Madre #" + blend.shapeSecond}</span>
          </div>
          <div class="stepper-holder" id="step-shape-second"></div>
        </div>
      </div>

      <!-- Mezcla Facial -->
      <div class="control-item" style="margin-top: 4px;">
        <div class="control-header">
          <span>Mezcla de Rasgos Faciales</span>
          <span class="control-val" id="val-shape-mix">${Math.round((blend.shapeMix || 0.5) * 100)}%</span>
        </div>
        <div class="bipolar-container">
          <span style="font-size: 11px; color: var(--text-dim);">Padre</span>
          <input type="range" class="range-slider" id="slider-shape-mix" min="0" max="1" step="0.01" value="${blend.shapeMix || 0.5}">
          <span style="font-size: 11px; color: var(--text-dim);">Madre</span>
        </div>
      </div>

      <div class="heritage-stack" style="margin-top: 6px;">
        <!-- Tono Piel Padre -->
        <div class="heritage-card">
          <div class="heritage-card-header">
            <span><i class="fa-solid fa-droplet"></i> Tono de Piel Padre</span>
          </div>
          <div class="stepper-holder" id="step-skin-first"></div>
        </div>

        <!-- Tono Piel Madre -->
        <div class="heritage-card">
          <div class="heritage-card-header">
            <span><i class="fa-solid fa-droplet"></i> Tono de Piel Madre</span>
          </div>
          <div class="stepper-holder" id="step-skin-second"></div>
        </div>
      </div>

      <!-- Mezcla Piel -->
      <div class="control-item" style="margin-top: 4px;">
        <div class="control-header">
          <span>Mezcla de Color de Piel</span>
          <span class="control-val" id="val-skin-mix">${Math.round((blend.skinMix || 0.5) * 100)}%</span>
        </div>
        <div class="bipolar-container">
          <span style="font-size: 11px; color: var(--text-dim);">Padre</span>
          <input type="range" class="range-slider" id="slider-skin-mix" min="0" max="1" step="0.01" value="${blend.skinMix || 0.5}">
          <span style="font-size: 11px; color: var(--text-dim);">Madre</span>
        </div>
      </div>
    `;

    this.contentEl.appendChild(container);

    this.attachStepper(container.querySelector("#step-shape-first"), blend.shapeFirst || 0, 0, 45, (val) => {
      blend.shapeFirst = val;
      container.querySelector("#father-name").innerText = FATHERS[val] || `Padre #${val}`;
      this.data.headBlend = blend;
      this.post("appearance_change_head_blend", blend);
    });

    this.attachStepper(container.querySelector("#step-shape-second"), blend.shapeSecond || 21, 0, 45, (val) => {
      blend.shapeSecond = val;
      container.querySelector("#mother-name").innerText = MOTHERS[val] || `Madre #${val}`;
      this.data.headBlend = blend;
      this.post("appearance_change_head_blend", blend);
    });

    this.attachStepper(container.querySelector("#step-skin-first"), blend.skinFirst || 0, 0, 45, (val) => {
      blend.skinFirst = val;
      this.data.headBlend = blend;
      this.post("appearance_change_head_blend", blend);
    });

    this.attachStepper(container.querySelector("#step-skin-second"), blend.skinSecond || 21, 0, 45, (val) => {
      blend.skinSecond = val;
      this.data.headBlend = blend;
      this.post("appearance_change_head_blend", blend);
    });

    container.querySelector("#slider-shape-mix").addEventListener("input", (e) => {
      blend.shapeMix = parseFloat(e.target.value);
      container.querySelector("#val-shape-mix").innerText = `${Math.round(blend.shapeMix * 100)}%`;
      this.data.headBlend = blend;
      this.post("appearance_change_head_blend", blend);
    });

    container.querySelector("#slider-skin-mix").addEventListener("input", (e) => {
      blend.skinMix = parseFloat(e.target.value);
      container.querySelector("#val-skin-mix").innerText = `${Math.round(blend.skinMix * 100)}%`;
      this.data.headBlend = blend;
      this.post("appearance_change_head_blend", blend);
    });
  }

  // 👤 2. RASGOS FACIALES
  renderFaceFeatures() {
    this.currentSubTab = this.currentSubTab || "nose";
    this.subNavEl.innerHTML = "";

    Object.keys(FACE_FEATURE_GROUPS).forEach(key => {
      const g = FACE_FEATURE_GROUPS[key];
      const pill = document.createElement("button");
      pill.className = `sub-pill ${this.currentSubTab === key ? "active" : ""}`;
      pill.innerHTML = `<i class="${g.icon}"></i> ${g.title}`;
      pill.addEventListener("click", () => {
        this.currentSubTab = key;
        this.renderFaceFeaturesContent();
      });
      this.subNavEl.appendChild(pill);
    });

    this.renderFaceFeaturesContent();
  }

  renderFaceFeaturesContent() {
    this.contentEl.innerHTML = "";

    this.subNavEl.querySelectorAll(".sub-pill").forEach((pill, idx) => {
      const key = Object.keys(FACE_FEATURE_GROUPS)[idx];
      pill.classList.toggle("active", key === this.currentSubTab);
    });

    const activeGroup = FACE_FEATURE_GROUPS[this.currentSubTab];
    const features = this.data.faceFeatures || {};

    const container = document.createElement("div");
    container.className = "section-group";
    container.innerHTML = `
      <div class="section-header">
        <div class="section-title"><i class="${activeGroup.icon}"></i> ${activeGroup.title}</div>
      </div>
    `;

    Object.keys(activeGroup.features).forEach(featKey => {
      const label = activeGroup.features[featKey];
      const currentVal = features[featKey] !== undefined ? features[featKey] : 0;
      const formattedVal = (currentVal > 0 ? "+" : "") + Math.round(currentVal * 100) + "%";

      const item = document.createElement("div");
      item.className = "control-item";
      item.innerHTML = `
        <div class="control-header">
          <span>${label}</span>
          <span class="control-val reset-btn" title="Haz clic para restablecer a 0">${formattedVal}</span>
        </div>
        <div class="bipolar-container">
          <input type="range" class="range-slider" min="-1" max="1" step="0.05" value="${currentVal}">
        </div>
      `;

      const slider = item.querySelector(".range-slider");
      const valBadge = item.querySelector(".control-val");

      slider.addEventListener("input", (e) => {
        const val = parseFloat(e.target.value);
        features[featKey] = val;
        valBadge.innerText = (val > 0 ? "+" : "") + Math.round(val * 100) + "%";
        this.data.faceFeatures = features;
        this.post("appearance_change_face_feature", features);
      });

      valBadge.addEventListener("click", () => {
        slider.value = 0;
        features[featKey] = 0;
        valBadge.innerText = "0%";
        this.data.faceFeatures = features;
        this.post("appearance_change_face_feature", features);
      });

      container.appendChild(item);
    });

    this.contentEl.appendChild(container);
  }

  // 💇 3. ASPECTO
  renderAppearance() {
    this.currentSubTab = this.currentSubTab || "hair";
    this.subNavEl.innerHTML = "";

    const subTabs = [
      { id: "hair", label: "Pelo y Barba", icon: "fa-scissors" },
      { id: "makeup", label: "Maquillaje y Ojos", icon: "fa-wand-magic-sparkles" },
      { id: "skin", label: "Piel y Envejecimiento", icon: "fa-sun" }
    ];

    subTabs.forEach(st => {
      const pill = document.createElement("button");
      pill.className = `sub-pill ${this.currentSubTab === st.id ? "active" : ""}`;
      pill.innerHTML = `<i class="fa-solid ${st.icon}"></i> ${st.label}`;
      pill.addEventListener("click", () => {
        this.currentSubTab = st.id;
        this.renderAppearanceContent();
      });
      this.subNavEl.appendChild(pill);
    });

    this.renderAppearanceContent();
  }

  renderAppearanceContent() {
    this.contentEl.innerHTML = "";

    this.subNavEl.querySelectorAll(".sub-pill").forEach((pill, idx) => {
      const ids = ["hair", "makeup", "skin"];
      pill.classList.toggle("active", ids[idx] === this.currentSubTab);
    });

    if (this.currentSubTab === "hair") {
      this.renderHairAndBeard();
    } else if (this.currentSubTab === "makeup") {
      this.renderMakeupAndEyes();
    } else {
      this.renderSkinDetails();
    }
  }

  renderHairAndBeard() {
    const hair = this.data.hair || { style: 0, color: 0, highlight: 0 };
    const hairSettings = this.settings.hair || { style: { max: 76 } };
    const maxHair = (hairSettings.style && hairSettings.style.max) ? hairSettings.style.max : 76;

    // Hair Section
    const hairGroup = document.createElement("div");
    hairGroup.className = "section-group";
    hairGroup.innerHTML = `
      <div class="section-header">
        <div class="section-title"><i class="fa-solid fa-scissors"></i> Cabello y Peinado</div>
        <span class="control-val" id="val-hair-style">Modelo: ${hair.style} / ${maxHair}</span>
      </div>
      <div class="control-item">
        <div class="stepper-holder" id="step-hair-style"></div>
      </div>
      <div class="control-item" style="margin-top: 6px;">
        <div class="control-header"><span>Color Principal del Cabello (64 Tonos)</span></div>
        <div id="picker-hair-color"></div>
      </div>
      <div class="control-item" style="margin-top: 6px;">
        <div class="control-header"><span>Color de Mechas / Reflejos (64 Tonos)</span></div>
        <div id="picker-hair-highlight"></div>
      </div>
    `;

    this.attachStepper(hairGroup.querySelector("#step-hair-style"), hair.style || 0, 0, maxHair, (val) => {
      hair.style = val;
      this.data.hair = hair;
      this.post("appearance_change_hair", hair);
      hairGroup.querySelector("#val-hair-style").innerText = `Modelo: ${val} / ${maxHair}`;
    });

    this.createExtendedColorPicker(hairGroup.querySelector("#picker-hair-color"), hair.color || 0, "hair", (colorIdx) => {
      hair.color = colorIdx;
      this.data.hair = hair;
      this.post("appearance_change_hair", hair);
    });

    this.createExtendedColorPicker(hairGroup.querySelector("#picker-hair-highlight"), hair.highlight || 0, "hair", (colorIdx) => {
      hair.highlight = colorIdx;
      this.data.hair = hair;
      this.post("appearance_change_hair", hair);
    });

    this.contentEl.appendChild(hairGroup);

    // Beard Section
    const overlays = this.data.headOverlays || {};
    const overlaySettings = this.settings.headOverlays || {};
    const beardSetting = overlaySettings.beard || { style: { max: 28 } };
    const maxBeard = (beardSetting.style && beardSetting.style.max) ? beardSetting.style.max : 28;
    const beard = overlays.beard || { style: 0, opacity: 0, color: 0 };

    const beardGroup = document.createElement("div");
    beardGroup.className = "section-group";
    beardGroup.innerHTML = `
      <div class="section-header">
        <div class="section-title"><i class="fa-solid fa-user-ninja"></i> Barba y Vello Facial</div>
        <span class="control-val" id="val-beard-style">${beard.style === 0 ? "Afeitado" : "Estilo: " + beard.style}</span>
      </div>
      <div class="control-item">
        <div class="stepper-holder" id="step-beard-style"></div>
      </div>
      <div class="control-item" style="margin-top: 6px;">
        <div class="control-header">
          <span>Opacidad / Densidad</span>
          <span class="control-val" id="val-beard-opac">${Math.round((beard.opacity || 0) * 100)}%</span>
        </div>
        <div class="bipolar-container">
          <input type="range" class="range-slider" id="slider-beard-opac" min="0" max="1" step="0.05" value="${beard.opacity || 0}">
        </div>
      </div>
      <div class="control-item" style="margin-top: 6px;">
        <div class="control-header"><span>Color de la Barba</span></div>
        <div id="picker-beard-color"></div>
      </div>
    `;

    this.attachStepper(beardGroup.querySelector("#step-beard-style"), beard.style || 0, 0, maxBeard, (val) => {
      beard.style = val;
      overlays.beard = beard;
      this.data.headOverlays = overlays;
      beardGroup.querySelector("#val-beard-style").innerText = val === 0 ? "Afeitado" : `Estilo: ${val}`;
      this.post("appearance_change_head_overlay", overlays);
    });

    beardGroup.querySelector("#slider-beard-opac").addEventListener("input", (e) => {
      beard.opacity = parseFloat(e.target.value);
      beardGroup.querySelector("#val-beard-opac").innerText = `${Math.round(beard.opacity * 100)}%`;
      overlays.beard = beard;
      this.data.headOverlays = overlays;
      this.post("appearance_change_head_overlay", overlays);
    });

    this.createExtendedColorPicker(beardGroup.querySelector("#picker-beard-color"), beard.color || 0, "hair", (colorIdx) => {
      beard.color = colorIdx;
      overlays.beard = beard;
      this.data.headOverlays = overlays;
      this.post("appearance_change_head_overlay", overlays);
    });

    this.contentEl.appendChild(beardGroup);
  }

  renderMakeupAndEyes() {
    const overlays = this.data.headOverlays || {};
    const overlaySettings = this.settings.headOverlays || {};

    // Eye Color
    const eyeGroup = document.createElement("div");
    eyeGroup.className = "section-group";
    const currentEye = this.data.eyeColor || 0;
    eyeGroup.innerHTML = `
      <div class="section-header">
        <div class="section-title"><i class="fa-solid fa-eye"></i> Color de Ojos</div>
        <span class="control-val" id="val-eye-color">${EYE_COLORS[currentEye] || currentEye}</span>
      </div>
      <div class="stepper-holder" id="step-eye-color"></div>
    `;

    this.attachStepper(eyeGroup.querySelector("#step-eye-color"), currentEye, 0, 31, (val) => {
      this.data.eyeColor = val;
      eyeGroup.querySelector("#val-eye-color").innerText = EYE_COLORS[val] || val;
      this.post("appearance_change_eye_color", val);
    });

    this.contentEl.appendChild(eyeGroup);

    // Cosmetics (Cejas, Maquillaje, Colorete, Pintalabios)
    const cosmetics = [
      { key: "eyebrows", label: "Cejas", icon: "fa-eye", type: "hair" },
      { key: "makeUp", label: "Maquillaje de Ojos", icon: "fa-wand-magic-sparkles", type: "makeup" },
      { key: "blush", label: "Colorete / Rubor", icon: "fa-face-flushed", type: "makeup" },
      { key: "lipstick", label: "Pintalabios", icon: "fa-lips", type: "makeup" }
    ];

    cosmetics.forEach(cosm => {
      const setting = overlaySettings[cosm.key] || { style: { max: 30 } };
      const maxStyle = (setting.style && setting.style.max) ? setting.style.max : 30;
      const current = overlays[cosm.key] || { style: 0, opacity: 0, color: 0 };

      const group = document.createElement("div");
      group.className = "section-group";
      group.innerHTML = `
        <div class="section-header">
          <div class="section-title"><i class="fa-solid ${cosm.icon}"></i> ${cosm.label}</div>
          <span class="control-val">${current.style === 0 ? "Ninguno" : "Estilo " + current.style}</span>
        </div>
        <div class="control-item">
          <div class="stepper-holder"></div>
        </div>
        <div class="control-item" style="margin-top: 6px;">
          <div class="control-header">
            <span>Opacidad</span>
            <span class="control-val val-opac">${Math.round((current.opacity || 0) * 100)}%</span>
          </div>
          <div class="bipolar-container">
            <input type="range" class="range-slider" min="0" max="1" step="0.05" value="${current.opacity || 0}">
          </div>
        </div>
        <div class="control-item" style="margin-top: 6px;">
          <div class="control-header"><span>Gama de Color (64 Tonos)</span></div>
          <div class="picker-holder"></div>
        </div>
      `;

      const titleVal = group.querySelector(".section-header .control-val");
      const opacVal = group.querySelector(".val-opac");
      const opacSlider = group.querySelector(".range-slider");

      this.attachStepper(group.querySelector(".stepper-holder"), current.style || 0, 0, maxStyle, (val) => {
        current.style = val;
        overlays[cosm.key] = current;
        this.data.headOverlays = overlays;
        titleVal.innerText = val === 0 ? "Ninguno" : `Estilo ${val}`;
        this.post("appearance_change_head_overlay", overlays);
      });

      opacSlider.addEventListener("input", (e) => {
        current.opacity = parseFloat(e.target.value);
        opacVal.innerText = `${Math.round(current.opacity * 100)}%`;
        overlays[cosm.key] = current;
        this.data.headOverlays = overlays;
        this.post("appearance_change_head_overlay", overlays);
      });

      this.createExtendedColorPicker(group.querySelector(".picker-holder"), current.color || 0, cosm.type, (colorIdx) => {
        current.color = colorIdx;
        overlays[cosm.key] = current;
        this.data.headOverlays = overlays;
        this.post("appearance_change_head_overlay", overlays);
      });

      this.contentEl.appendChild(group);
    });
  }

  renderSkinDetails() {
    const overlays = this.data.headOverlays || {};
    const overlaySettings = this.settings.headOverlays || {};

    const skinOverlays = [
      { key: "ageing", label: "Envejecimiento / Arrugas", icon: "fa-hourglass" },
      { key: "blemishes", label: "Imperfecciones / Acné", icon: "fa-circle-dot" },
      { key: "moleAndFreckles", label: "Pecas y Lunares", icon: "fa-braille" },
      { key: "sunDamage", label: "Daño Solar", icon: "fa-sun" },
      { key: "complexion", label: "Manchas de Tez", icon: "fa-face-meh" },
      { key: "chestHair", label: "Vello Pectoral", icon: "fa-person" },
      { key: "bodyBlemishes", label: "Imperfecciones Corporales", icon: "fa-virus" }
    ];

    const group = document.createElement("div");
    group.className = "section-group";
    group.innerHTML = `
      <div class="section-header">
        <div class="section-title"><i class="fa-solid fa-sun"></i> Detalles de la Piel</div>
      </div>
    `;

    skinOverlays.forEach(so => {
      const setting = overlaySettings[so.key] || { style: { max: 20 } };
      const maxStyle = (setting.style && setting.style.max) ? setting.style.max : 20;
      const current = overlays[so.key] || { style: 0, opacity: 0 };

      const item = document.createElement("div");
      item.className = "control-item";
      item.style.marginBottom = "14px";
      item.innerHTML = `
        <div class="control-header">
          <span><i class="fa-solid ${so.icon}"></i> ${so.label}</span>
          <span class="control-val val-title">${current.style === 0 ? "Ninguno" : "Tipo " + current.style}</span>
        </div>
        <div class="stepper-holder"></div>
        <div class="control-header" style="margin-top: 4px;">
          <span>Opacidad</span>
          <span class="control-val val-opac">${Math.round((current.opacity || 0) * 100)}%</span>
        </div>
        <div class="bipolar-container">
          <input type="range" class="range-slider" min="0" max="1" step="0.05" value="${current.opacity || 0}">
        </div>
      `;

      const titleVal = item.querySelector(".val-title");
      const opacVal = item.querySelector(".val-opac");
      const opacSlider = item.querySelector(".range-slider");

      this.attachStepper(item.querySelector(".stepper-holder"), current.style || 0, 0, maxStyle, (val) => {
        current.style = val;
        overlays[so.key] = current;
        this.data.headOverlays = overlays;
        titleVal.innerText = val === 0 ? "Ninguno" : `Tipo ${val}`;
        this.post("appearance_change_head_overlay", overlays);
      });

      opacSlider.addEventListener("input", (e) => {
        current.opacity = parseFloat(e.target.value);
        opacVal.innerText = `${Math.round(current.opacity * 100)}%`;
        overlays[so.key] = current;
        this.data.headOverlays = overlays;
        this.post("appearance_change_head_overlay", overlays);
      });

      group.appendChild(item);
    });

    this.contentEl.appendChild(group);
  }

  // 👕 4. ROPA Y VESTUARIO
  renderClothes() {
    this.currentSubTab = this.currentSubTab || "upper";
    this.subNavEl.innerHTML = "";

    const subTabs = [
      { id: "upper", label: "Tronco y Brazos", icon: "fa-shirt" },
      { id: "lower", label: "Piernas y Calzado", icon: "fa-socks" }
    ];

    subTabs.forEach(st => {
      const pill = document.createElement("button");
      pill.className = `sub-pill ${this.currentSubTab === st.id ? "active" : ""}`;
      pill.innerHTML = `<i class="fa-solid ${st.icon}"></i> ${st.label}`;
      pill.addEventListener("click", () => {
        this.currentSubTab = st.id;
        this.handleAutoCamera(this.currentTab);
        this.renderClothesContent();
      });
      this.subNavEl.appendChild(pill);
    });

    this.renderClothesContent();
  }

  renderClothesContent() {
    this.contentEl.innerHTML = "";

    this.subNavEl.querySelectorAll(".sub-pill").forEach((pill, idx) => {
      const ids = ["upper", "lower"];
      pill.classList.toggle("active", ids[idx] === this.currentSubTab);
    });

    const activeList = (this.currentSubTab === "upper") ? CLOTHING_UPPER : CLOTHING_LOWER;
    const components = this.data.components || [];
    const compSettings = this.settings.components || [];

    const container = document.createElement("div");
    container.className = "section-group";
    container.innerHTML = `
      <div class="section-header">
        <div class="section-title"><i class="fa-solid fa-shirt"></i> ${this.currentSubTab === "upper" ? "Prendas Superiores" : "Prendas Inferiores"}</div>
      </div>
    `;

    activeList.forEach(item => {
      const id = item.id;
      const comp = components.find(c => c.component_id === id) || { drawable: 0, texture: 0 };
      const compSetting = compSettings.find(s => s.component_id === id) || { drawable: { max: 150 }, texture: { max: 15 } };
      const maxDraw = (compSetting.drawable && compSetting.drawable.max) ? compSetting.drawable.max : 150;
      const maxTex = (compSetting.texture && compSetting.texture.max) ? compSetting.texture.max : 15;

      const el = document.createElement("div");
      el.className = "control-item";
      el.style.marginBottom = "14px";
      el.innerHTML = `
        <div class="control-header">
          <span><i class="fa-solid ${item.icon}"></i> ${item.label}</span>
          <span class="control-val val-model">Modelo: ${comp.drawable} / ${maxDraw}</span>
        </div>
        <div class="stepper-holder step-model"></div>
        <div class="control-header" style="margin-top: 4px;">
          <span style="font-size: 11px; color: var(--text-dim);">Variante de Textura / Color</span>
          <span class="control-val val-tex">Color: ${comp.texture} / ${maxTex}</span>
        </div>
        <div class="stepper-holder step-tex"></div>
      `;

      const valModel = el.querySelector(".val-model");
      const valTex = el.querySelector(".val-tex");
      const stepTexHolder = el.querySelector(".step-tex");

      let currentTexStepper = null;

      this.attachStepper(el.querySelector(".step-model"), comp.drawable || 0, 0, maxDraw, async (val) => {
        comp.drawable = val;
        comp.texture = 0;
        valModel.innerText = `Modelo: ${val} / ${maxDraw}`;
        const updatedSetting = await this.post("appearance_change_component", { component_id: id, drawable: val, texture: 0 });
        if (updatedSetting && updatedSetting.texture) {
          const newMaxTex = updatedSetting.texture.max || 15;
          valTex.innerText = `Color: 0 / ${newMaxTex}`;
          if (currentTexStepper) {
            currentTexStepper.updateLimits(0, newMaxTex);
            currentTexStepper.setValue(0);
          }
        }
      });

      currentTexStepper = this.attachStepper(stepTexHolder, comp.texture || 0, 0, maxTex, (val) => {
        comp.texture = val;
        valTex.innerText = `Color: ${val} / ${maxTex}`;
        this.post("appearance_change_component", { component_id: id, drawable: comp.drawable, texture: val });
      });

      container.appendChild(el);
    });

    this.contentEl.appendChild(container);
  }

  // 🕶️ 5. ACCESORIOS
  renderProps() {
    this.subNavEl.innerHTML = "";
    this.contentEl.innerHTML = "";

    const props = this.data.props || [];
    const propSettings = this.settings.props || [];

    const container = document.createElement("div");
    container.className = "section-group";
    container.innerHTML = `
      <div class="section-header">
        <div class="section-title"><i class="fa-solid fa-glasses"></i> Accesorios y Complementos</div>
      </div>
    `;

    PROP_ITEMS.forEach(item => {
      const id = item.id;
      const prop = props.find(p => p.prop_id === id) || { drawable: -1, texture: -1 };
      const propSetting = propSettings.find(s => s.prop_id === id) || { drawable: { max: 100 }, texture: { max: 10 } };
      const maxDraw = (propSetting.drawable && propSetting.drawable.max) ? propSetting.drawable.max : 100;
      const maxTex = (propSetting.texture && propSetting.texture.max) ? propSetting.texture.max : 10;

      const el = document.createElement("div");
      el.className = "control-item";
      el.style.marginBottom = "14px";
      el.innerHTML = `
        <div class="control-header">
          <span><i class="fa-solid ${item.icon}"></i> ${item.label}</span>
          <span class="control-val val-model">${prop.drawable === -1 ? "Ninguno" : "Modelo: " + prop.drawable + " / " + maxDraw}</span>
        </div>
        <div class="stepper-holder step-model"></div>
        <div class="control-header" style="margin-top: 4px;">
          <span style="font-size: 11px; color: var(--text-dim);">Variante de Color</span>
          <span class="control-val val-tex">${prop.texture === -1 ? "-" : "Color: " + prop.texture + " / " + maxTex}</span>
        </div>
        <div class="stepper-holder step-tex"></div>
      `;

      const valModel = el.querySelector(".val-model");
      const valTex = el.querySelector(".val-tex");
      const stepTexHolder = el.querySelector(".step-tex");

      let currentTexStepper = null;

      this.attachStepper(el.querySelector(".step-model"), prop.drawable, -1, maxDraw, async (val) => {
        prop.drawable = val;
        prop.texture = val === -1 ? -1 : 0;
        valModel.innerText = val === -1 ? "Ninguno" : `Modelo: ${val} / ${maxDraw}`;
        const updatedSetting = await this.post("appearance_change_prop", { prop_id: id, drawable: val, texture: prop.texture });
        if (updatedSetting && updatedSetting.texture) {
          const newMaxTex = updatedSetting.texture.max || 10;
          valTex.innerText = prop.texture === -1 ? "-" : `Color: 0 / ${newMaxTex}`;
          if (currentTexStepper) {
            currentTexStepper.updateLimits(-1, newMaxTex);
            currentTexStepper.setValue(prop.texture);
          }
        }
      });

      currentTexStepper = this.attachStepper(stepTexHolder, prop.texture, -1, maxTex, (val) => {
        prop.texture = val;
        valTex.innerText = val === -1 ? "-" : `Color: ${val} / ${maxTex}`;
        this.post("appearance_change_prop", { prop_id: id, drawable: prop.drawable, texture: val });
      });

      container.appendChild(el);
    });

    this.contentEl.appendChild(container);
  }

  // 🎨 EXTENDED LUXURY COLOR PICKER COMPONENT
  createExtendedColorPicker(container, currentColor, paletteType, onSelect) {
    if (!container) return;

    const palette = (paletteType === "makeup") ? GTA_MAKEUP_PALETTE : GTA_HAIR_PALETTE;
    const categories = (paletteType === "makeup") ? MAKEUP_CATEGORIES : HAIR_CATEGORIES;

    let selectedIdx = Math.max(0, Math.min(palette.length - 1, currentColor || 0));
    let activeCategory = "all";

    const block = document.createElement("div");
    block.className = "color-picker-block";
    block.innerHTML = `
      <!-- Header Preview -->
      <div class="color-preview-header">
        <span style="font-size: 11px; color: var(--text-dim);">Tono Seleccionado</span>
        <div class="color-badge-preview">
          <div class="color-circle-dot" style="background-color: ${palette[selectedIdx].hex};"></div>
          <span class="color-badge-text">#${selectedIdx} ${palette[selectedIdx].name}</span>
        </div>
      </div>

      <!-- Categories Filter Chips -->
      <div class="color-category-bar"></div>

      <!-- Swatches Grid -->
      <div class="color-palette-grid"></div>

      <!-- Realtime Slider / Stepper Scrubber -->
      <div class="stepper-holder" style="margin-top: 4px;"></div>
    `;

    const catBar = block.querySelector(".color-category-bar");
    const grid = block.querySelector(".color-palette-grid");
    const dot = block.querySelector(".color-circle-dot");
    const badgeText = block.querySelector(".color-badge-text");
    const stepperHolder = block.querySelector(".stepper-holder");

    // Render Categories
    categories.forEach(cat => {
      const chip = document.createElement("button");
      chip.className = `color-cat-chip ${cat.id === activeCategory ? "active" : ""}`;
      chip.innerText = cat.label;
      chip.addEventListener("click", () => {
        catBar.querySelectorAll(".color-cat-chip").forEach(c => c.classList.remove("active"));
        chip.classList.add("active");
        activeCategory = cat.id;
        renderSwatches();
      });
      catBar.appendChild(chip);
    });

    // Render Swatches
    const renderSwatches = () => {
      grid.innerHTML = "";
      const filtered = (activeCategory === "all") 
        ? palette 
        : palette.filter(p => p.cat === activeCategory);

      filtered.forEach(colorItem => {
        const swatch = document.createElement("div");
        swatch.className = `color-swatch ${colorItem.id === selectedIdx ? "active" : ""}`;
        swatch.style.backgroundColor = colorItem.hex;
        swatch.title = `#${colorItem.id} - ${colorItem.name}`;
        swatch.addEventListener("click", () => {
          selectColor(colorItem.id);
        });
        grid.appendChild(swatch);
      });
    };

    let stepperObj = null;

    const selectColor = (newIdx) => {
      selectedIdx = Math.max(0, Math.min(palette.length - 1, newIdx));
      const col = palette[selectedIdx];
      dot.style.backgroundColor = col.hex;
      badgeText.innerText = `#${selectedIdx} ${col.name}`;

      // Update grid selection active state
      grid.querySelectorAll(".color-swatch").forEach((s) => {
        const isThis = s.title.startsWith(`#${selectedIdx} `);
        s.classList.toggle("active", isThis);
      });

      if (stepperObj) {
        stepperObj.setValue(selectedIdx);
      }

      onSelect(selectedIdx);
    };

    stepperObj = this.attachStepper(stepperHolder, selectedIdx, 0, palette.length - 1, (val) => {
      selectColor(val);
    });

    renderSwatches();
    container.innerHTML = "";
    container.appendChild(block);
  }

  // Scoped Helpers: Steppers
  attachStepper(container, initialVal, min, max, onChange) {
    if (!container) return null;

    let currentVal = initialVal;

    container.innerHTML = `
      <div class="stepper-control">
        <button class="stepper-btn btn-prev"><i class="fa-solid fa-chevron-left"></i></button>
        <input type="range" class="stepper-slider" min="${min}" max="${max}" value="${currentVal}">
        <button class="stepper-btn btn-next"><i class="fa-solid fa-chevron-right"></i></button>
      </div>
    `;

    const slider = container.querySelector(".stepper-slider");
    const prevBtn = container.querySelector(".btn-prev");
    const nextBtn = container.querySelector(".btn-next");

    const updateValue = (newVal) => {
      currentVal = Math.max(min, Math.min(max, newVal));
      slider.value = currentVal;
      onChange(currentVal);
    };

    prevBtn.addEventListener("click", () => updateValue(currentVal - 1));
    nextBtn.addEventListener("click", () => updateValue(currentVal + 1));
    slider.addEventListener("input", (e) => updateValue(parseInt(e.target.value)));

    return {
      updateLimits: (newMin, newMax) => {
        min = newMin;
        max = newMax;
        slider.min = newMin;
        slider.max = newMax;
      },
      setValue: (newVal) => {
        currentVal = Math.max(min, Math.min(max, newVal));
        slider.value = currentVal;
      }
    };
  }
}

document.addEventListener("DOMContentLoaded", () => {
  window.AppearanceApp = new AppearanceApp();
});
