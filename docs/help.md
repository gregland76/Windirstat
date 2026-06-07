# Aide Utilisateur

## 1. Objectif

WinDirStat PowerShell permet d'analyser l'occupation disque d'un dossier ou d'un lecteur,
avec une vue liste et une visualisation treemap.

## 2. Demarrage

1. Lancez le script PowerShell `windirstat.ps1`.
2. Cliquez sur **Parcourir** pour choisir un dossier.
3. Cliquez sur **Analyser** (ou laissez le scan automatique actif).

Capture suggeree : `screenshots/01-interface-principale.png`

## 3. Utilisation de l'interface

- **Parcourir** : sélectionne un dossier à analyser.
- **Analyser** : lance l'analyse du chemin courant.
- **Dossier parent** : remonte d'un niveau puis relance l'analyse.
- **Aide** : ouvre la documentation du projet.
- **À propos** : affiche les informations de l'application.

Capture suggeree : `screenshots/02-apres-scan.png`

## 4. Liste des elements

La liste a droite affiche :

- Objet
- Type (Dossier/Fichier)
- Taille
- Pourcentage de l'espace total

Actions disponibles :

- Double-clic sur un dossier pour l'analyser.
- Clic droit sur un element pour :
  - ouvrir le fichier/dossier,
  - ouvrir le dossier contenant.

Capture suggeree : `screenshots/03-menu-contextuel.png`

## 5. Treemap

Le panneau de gauche affiche une treemap des elements les plus volumineux.
Chaque bloc represente un element avec une surface proportionnelle a sa taille.
Le layout privilegie des zones plus carrees et place les plus gros elements en haut a gauche.

## 6. Depannage

- Message "Le chemin d'accès n'existe pas." : vérifiez que le chemin existe toujours.
- Aucun element affiche: testez un autre dossier ou verifiez les permissions.
- Ouverture d'un élément impossible : l'élément a peut-être été déplacé ou supprimé.

## 7. Contact

Voir la fenêtre **À propos** pour les informations de contact.

Capture suggeree : `screenshots/04-fenetre-about.png`

## 8. Historique des mises a jour

Pour suivre les evolutions du projet, consultez :

- `changelog.md` pour la version Markdown dans le depot.
- `changelog.html` pour la version HTML.
