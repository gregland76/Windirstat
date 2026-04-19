# Historique des mises a jour

Ce document resume les evolutions de WinDirStat PowerShell.
La version HTML equivalente est disponible dans `changelog.html`.

## Version 1.8 - 2026-04-19

### Ajoute

- Captures d'ecran `01-interface-principale.png`, `02-apres-scan.png`, `03-menu-contextuel.png` et `04-fenetre-about.png` dans `docs/screenshots/`.
- Script `docs/generate-screenshots.ps1` pour regenerer les captures de documentation.

### Modifie

- Mise a jour de `docs/screenshots/README.md` pour documenter la regeneration des captures.

## Version 1.7 - 2026-04-19

### Ajoute

- Version Markdown de l'historique dans `changelog.md`.

### Modifie

- Mise a jour de `README.md`, `docs/README.md` et `help.md` pour referencer l'historique des mises a jour.

## Version 1.6 - 2026-04-19

### Ajoute

- Fichier de lancement Windows `launch-windirstat.bat` pour demarrer l'application plus facilement.
- Support des chemins contenant des espaces dans le lanceur BAT.
- Fallback automatique sur `powershell.exe` si `pwsh` n'est pas disponible.

## Version 1.5 - 2026-04-19

### Ajoute

- Navigation croisee entre `help.html` et `changelog.html`.
- Boutons de navigation visibles en haut des pages HTML Aide et Changelog.

### Modifie

- Amelioration du parcours de lecture de la documentation HTML.

## Version 1.4 - 2026-04-19

### Ajoute

- Version HTML de l'aide utilisateur dans `help.html`.
- Version HTML du changelog dans `changelog.html`.
- Ouverture prioritaire de l'aide HTML depuis le bouton Docs.

## Version 1.3 - 2026-04-19

### Ajoute

- Bouton Docs dans l'interface principale pour ouvrir la documentation.
- Documentation projet dans `README.md` du dossier `docs`.
- Guide utilisateur dans `help.md`.
- Dossier `screenshots/` pour les captures d'ecran.

### Modifie

- Repositionnement des boutons de la deuxieme ligne pour integrer Docs.
- Mise a jour de l'historique de version du projet.

## Version 1.2 - 2026-04-18

### Ajoute

- Menu contextuel clic droit sur la liste de droite.
- Ouverture de l'element selectionne fichier ou dossier.
- Ouverture du dossier parent de l'element.
- Selection automatique de la ligne au clic droit.

## Version 1.1 - 2026-04-18

### Modifie

- Ajustements de layout hint, liste droite et panneau gauche.
- Ajout des informations de version dans le script.

## Version 1.0 - 2026-04-18

### Ajoute

- Premiere version avec scan des dossiers et fichiers.
- Interface graphique WinForms.
- Visualisation treemap.