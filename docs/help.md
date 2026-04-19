# Aide Utilisateur

## 1. Objectif

WinDirStat PowerShell permet d'analyser l'occupation disque d'un dossier ou d'un lecteur,
avec une vue liste et une visualisation treemap.

## 2. Demarrage

1. Lancez le script PowerShell `windirstat.ps1`.
2. Cliquez sur **Browse** pour choisir un dossier.
3. Cliquez sur **Scan** (ou laissez le scan auto actif).

Capture suggeree : `screenshots/01-interface-principale.png`

## 3. Utilisation de l'interface

- **Browse** : selectionne un dossier a analyser.
- **Scan** : lance l'analyse du chemin courant.
- **Parent** : remonte d'un niveau puis relance l'analyse.
- **Docs** : ouvre la documentation du projet.
- **About** : affiche les informations de l'application.

Capture suggeree : `screenshots/02-apres-scan.png`

## 4. Liste des elements

La liste a droite affiche :

- Objet
- Type (Folder/File)
- Taille
- Pourcentage de l'espace total

Actions disponibles :

- Double-clic sur un dossier pour l'analyser.
- Clic droit sur un element pour :
  - ouvrir le fichier/dossier,
  - ouvrir le dossier parent.

Capture suggeree : `screenshots/03-menu-contextuel.png`

## 5. Treemap

Le panneau de gauche affiche une treemap des elements les plus volumineux.
Chaque rectangle represente un element avec une surface proportionnelle a sa taille.

## 6. Depannage

- Message "The path does not exist": verifiez que le chemin existe toujours.
- Aucun element affiche: testez un autre dossier ou verifiez les permissions.
- Ouverture d'un element impossible: l'element a peut-etre ete deplace/supprime.

## 7. Contact

Voir la fenetre **About** pour les informations de contact.

Capture suggeree : `screenshots/04-fenetre-about.png`

## 8. Historique des mises a jour

Pour suivre les evolutions du projet, consultez :

- `changelog.md` pour la version Markdown dans le depot.
- `changelog.html` pour la version HTML.
