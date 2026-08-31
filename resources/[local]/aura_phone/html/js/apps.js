// Registro Global de Aplicaciones (Aura OS V2)
const AuraAppsRegistry = [
    {
        id: "app-phone",
        name: "Llamadas",
        icon: "fas fa-phone",
        colorClass: "bg-phone",
        inDock: true,
        isSystem: true,
        script: "AuraPhoneApp"
    },
    {
        id: "app-messages",
        name: "Mensajes",
        icon: "fas fa-comment",
        colorClass: "bg-msg",
        inDock: true,
        isSystem: true,
        script: "AuraMessagesApp"
    },
    {
        id: "app-camera",
        name: "Cámara",
        icon: "fas fa-camera",
        colorClass: "bg-camera",
        inDock: true,
        isSystem: true
    },
    {
        id: "app-bank",
        name: "AuraBank",
        icon: "fas fa-university",
        colorClass: "bg-bank",
        inDock: false,
        isSystem: true,
        script: "AuraBankApp" // Objeto JS que maneja esta app
    },
    {
        id: "app-contacts",
        name: "Contactos",
        icon: "fas fa-address-book",
        colorClass: "bg-contacts",
        inDock: false,
        isSystem: true,
        script: "AuraContactsApp"
    },
    {
        id: "app-settings",
        name: "Ajustes",
        icon: "fas fa-cog",
        colorClass: "bg-settings",
        inDock: false,
        isSystem: true
    },
    {
        id: "app-twitter",
        name: "Bleeter",
        icon: "fab fa-twitter",
        colorClass: "bg-twitter",
        inDock: false,
        isSystem: false
    },
    {
        id: "app-garage",
        name: "Garaje",
        icon: "fas fa-car",
        colorClass: "bg-garage",
        inDock: false,
        isSystem: false
    },
    {
        id: "app-darkweb",
        name: "DarkWeb",
        icon: "fas fa-user-secret",
        colorClass: "bg-darkweb",
        inDock: false,
        isSystem: false
    }
];
