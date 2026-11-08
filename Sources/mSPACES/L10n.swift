import Foundation

/// Textes de l'interface : français (rédigé en premier), anglais, espagnol, italien. Anglais si la langue système n'en fait pas partie.
private let strings: [String: [String: String]] = [
    "fr": [
        "upd.check": "Rechercher une mise à jour…",
        "upd.auto": "Installer automatiquement les mises à jour",
        "upd.available": "Version %@ disponible. L'installer maintenant ?",
        "upd.none": "mSPACES est à jour.",
        "upd.error": "Mise à jour impossible.",
        "upd.install": "Installer",
        "upd.later": "Plus tard",
        "new": "Nouveau", "remove": "Supprimer", "section": "Séparateur", "more": "Plus",
        "st.space": "espace", "st.tab": "tabulation", "st.dot": ".", "st.bar": "|", "st.dash": "–", "st.long": "—",
        "login": "Lancer à l'ouverture de session",
        "about": "À propos de mSPACES", "quit": "Quitter mSPACES", "hint": "Cmd + glisser pour déplacer",
        "about.tagline": "Organisez les icônes de votre barre des menus en groupes grâce à des séparateurs.",
        "about.help": "Cliquez sur un séparateur et choisissez « Nouveau séparateur » pour en ajouter un. Pour en déplacer un, maintenez Cmd et faites-le glisser.",
        "about.version": "Version %@",
    ],
    "en": [
        "upd.check": "Check for Updates…",
        "upd.auto": "Install Updates Automatically",
        "upd.available": "Version %@ is available. Install it now?",
        "upd.none": "mSPACES is up to date.",
        "upd.error": "Update failed.",
        "upd.install": "Install",
        "upd.later": "Later",
        "new": "New", "remove": "Remove", "section": "Separator", "more": "More",
        "st.space": "space", "st.tab": "tab", "st.dot": ".", "st.bar": "|", "st.dash": "–", "st.long": "—",
        "login": "Launch at Login",
        "about": "About mSPACES", "quit": "Quit mSPACES", "hint": "Hold Cmd and drag to move",
        "about.tagline": "Organize your menu bar items into groups with separators.",
        "about.help": "Click a separator and choose “New Separator” to add another one. To move a separator, hold Command and drag it.",
        "about.version": "Version %@",
    ],
    "es": [
        "upd.check": "Buscar actualizaciones…",
        "upd.auto": "Instalar actualizaciones automáticamente",
        "upd.available": "La versión %@ está disponible. ¿Instalarla ahora?",
        "upd.none": "mSPACES está actualizado.",
        "upd.error": "No se pudo actualizar.",
        "upd.install": "Instalar",
        "upd.later": "Más tarde",
        "new": "Nuevo", "remove": "Eliminar", "section": "Separador", "more": "Más",
        "st.space": "espacio", "st.tab": "tabulación", "st.dot": ".", "st.bar": "|", "st.dash": "–", "st.long": "—",
        "login": "Abrir al iniciar sesión",
        "about": "Acerca de mSPACES", "quit": "Salir de mSPACES", "hint": "Cmd + arrastrar para mover",
        "about.tagline": "Organice los iconos de su barra de menús en grupos con separadores.",
        "about.help": "Haga clic en un separador y elija «Nuevo separador» para añadir otro. Para moverlo, mantenga Cmd y arrástrelo.",
        "about.version": "Versión %@",
    ],
    "it": [
        "upd.check": "Cerca aggiornamenti…",
        "upd.auto": "Installa automaticamente gli aggiornamenti",
        "upd.available": "La versione %@ è disponibile. Installarla ora?",
        "upd.none": "mSPACES è aggiornato.",
        "upd.error": "Aggiornamento non riuscito.",
        "upd.install": "Installa",
        "upd.later": "Più tardi",
        "new": "Nuovo", "remove": "Rimuovi", "section": "Separatore", "more": "Altro",
        "st.space": "spazio", "st.tab": "tabulazione", "st.dot": ".", "st.bar": "|", "st.dash": "–", "st.long": "—",
        "login": "Apri al login",
        "about": "Informazioni su mSPACES", "quit": "Esci da mSPACES", "hint": "Cmd + trascina per spostare",
        "about.tagline": "Organizza le icone della barra dei menu in gruppi con dei separatori.",
        "about.help": "Fai clic su un separatore e scegli «Nuovo separatore» per aggiungerne un altro. Per spostarlo, tieni premuto Cmd e trascinalo.",
        "about.version": "Versione %@",
    ],
]

private let lang: String = {
    let code = Locale.preferredLanguages.first.map { String($0.prefix(2)) } ?? "en"
    return strings[code] != nil ? code : "en"
}()

func L(_ key: String, _ args: CVarArg...) -> String {
    let s = strings[lang]?[key] ?? strings["en"]?[key] ?? key
    return args.isEmpty ? s : String(format: s, arguments: args)
}
