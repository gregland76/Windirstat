WinDirStat PowerShell
=====================

WinDirStat PowerShell est une application Windows ecrite en PowerShell qui analyse l'occupation disque d'un dossier ou d'un lecteur.
Elle fournit une vue rapide des elements les plus volumineux pour aider a comprendre ou l'espace est utilise.

Ce que fait le programme
------------------------

- Analyse le contenu d'un dossier ou d'un lecteur selectionne.
- Calcule la taille des fichiers et des sous-dossiers.
- Trie les elements par taille decroissante.
- Affiche les resultats dans une liste detaillee.
- Genere une treemap visuelle pour reperer rapidement les elements les plus lourds.
- Permet de naviguer dans l'arborescence en relancant une analyse sur un sous-dossier.
- Permet d'ouvrir directement un fichier, un dossier ou le dossier contenant un fichier.

Fonctionnalites principales
---------------------------

- Bouton Browse pour choisir un dossier a analyser.
- Bouton Scan pour lancer l'analyse manuellement.
- Option de scan automatique apres selection d'un dossier.
- Bouton Parent pour remonter d'un niveau et relancer l'analyse.
- Liste des objets avec leur type, leur taille et leur pourcentage d'occupation.
- Double-clic sur un dossier pour l'analyser directement.
- Menu contextuel pour ouvrir un element ou son dossier parent.
- Bouton Docs pour ouvrir la documentation.
- Bouton About pour afficher les informations sur l'application.

Interface
---------

Le programme ouvre une fenetre graphique Windows Forms avec deux zones principales :

- a gauche, une treemap qui represente visuellement la taille relative des elements ;
- a droite, une liste detaillee des dossiers et fichiers analyses.

Le programme affiche jusqu'a 50 elements tries par taille pour garder une interface lisible et rapide.

Lancement
---------

Deux options sont prevues :

- lancer directement le script [windirstat.ps1](windirstat.ps1) ;
- utiliser [launch-windirstat.bat](launch-windirstat.bat), qui demarre automatiquement PowerShell ou PowerShell 7 si disponible.

Documentation
-------------

La documentation utilisateur est disponible dans le dossier [docs/README.md](docs/README.md), avec notamment :

- [docs/help.md](docs/help.md) pour le guide utilisateur ;
- [docs/help.html](docs/help.html) pour la version HTML ;
- [docs/changelog.html](docs/changelog.html) pour l'historique des versions.