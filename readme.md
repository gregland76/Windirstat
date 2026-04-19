WinDirStat PowerShell
=====================

Ce projet ne repose pas sur une base de donnees relationnelle.
Il n'y a donc pas de schema ERD classique a maintenir.

Structure logique du projet
---------------------------

- windirstat.ps1 : script principal PowerShell
- launch-windirstat.bat : lanceur Windows
- docs/README.md : index de la documentation
- docs/help.md : guide utilisateur
- docs/help.html : guide utilisateur en HTML
- docs/changelog.html : historique des modifications
- docs/screenshots/README.md : consignes pour les captures d'ecran

Relations principales
---------------------

- launch-windirstat.bat -> execute windirstat.ps1
- windirstat.ps1 -> ouvre la documentation du dossier docs/
- docs/README.md -> reference les autres fichiers de documentation