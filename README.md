# ⚡ FlashAlert

> Système d'alerte réseau léger et instantané — de l'appelant vers les clients en un clic.

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows-lightgrey.svg)](https://www.microsoft.com/windows)
[![Built with AutoIt](https://img.shields.io/badge/Built%20with-AutoIt-green.svg)](https://www.autoitscript.com/)

---

## 📋 Présentation

**FlashAlert** est un outil open source permettant d'envoyer des alertes depuis un poste opérateur (l'**appelant**) vers un ou plusieurs postes équipés d'un **client** en écoute, via un fichier partagé sur le réseau (partage UNC).

Conçu pour les environnements professionnels (accueil, sécurité, administration), il permet de déclencher une alerte visuelle et sonore en quelques secondes, sans serveur, sans installation complexe.

### Cas d'usage typiques

- Alerte agression / danger immédiat à l'accueil
- Demande de renfort
- Urgence médicale
- Information ou réunion imminente

---

## ✨ Fonctionnalités

### Appelant
- Interface graphique simple avec boutons d'alerte configurables
- 3 niveaux de criticité : **urgence** (rouge), **alerte** (orange), **info** (bleu)
- Déclenchement automatique sur le bouton principal après un délai configurable (anti-panique)
- Bouton d'annulation pour les missclics
- Horodatage et journalisation automatiques

### Client
- Agent discret dans la barre des tâches (systray)
- Surveillance continue du fichier partagé réseau
- Popup visuelle colorée en haut à droite de l'écran
- Son d'alerte répété jusqu'à acquittement explicite
- Clignotement de la fenêtre si elle perd le focus
- Acquittement obligatoire ("J'ai lu") — impossible à ignorer

---

## 🗂️ Structure du projet

```
flashalert/
├── LICENSE
├── README.md
├── CHANGELOG.md
│
├── src/
│   ├── appelant/
│   │   ├── Alerte_Appelant.au3       ← Source AutoIt (appelant)
│   │   ├── alerte.ini.example        ← Configuration exemple
│   │   └── appelant.ico
│   └── client/
│       ├── Alerte_Client.au3         ← Source AutoIt (client)
│       ├── alerte.ini.example        ← Configuration exemple
│       └── client.ico
│
└── shared/
    ├── menu.txt.example              ← Définition des boutons d'alerte (à renommer et adapter)
    ├── message.txt                   ← Fichier de communication (vide au départ)
    ├── log.txt                       ← Fichier de log (vide au départ)
    └── alerte.wav                    ← Son d'alerte centralisé
```

> **Note :** Le dossier `shared/` est déposé **une seule fois** sur le serveur réseau. Il n'est jamais embarqué dans les installations appelant ou client — ceux-ci y accèdent via leur chemin UNC configuré dans `alerte.ini`.

---

## 📦 Packages de la release

Chaque release publie **trois archives distinctes** :

| Archive | Destination | Contenu |
|---|---|---|
| `FlashAlert-vX.X.X-shared.zip` | Serveur réseau (une fois) | `message.txt`, `log.txt`, `menu.txt.example`, `alerte.wav` |
| `FlashAlert-vX.X.X-appelant.zip` | Poste opérateur | `Alerte_Appelant.exe`, `alerte.ini.example`, `appelant.ico` |
| `FlashAlert-vX.X.X-client.zip` | Chaque poste client | `Alerte_Client.exe`, `alerte.ini.example`, `client.ico` |

---

## 🚀 Installation

### Prérequis

- Windows 10 / 11
- Un partage réseau accessible depuis tous les postes (UNC type `\\serveur\partage\flashalert\shared\`)
- [AutoIt v3](https://www.autoitscript.com/site/autoit/downloads/) (uniquement si vous compilez les sources)

### Déploiement rapide (binaires pré-compilés)

**Étape 1 — Préparer le partage réseau (une seule fois)**

1. Téléchargez `FlashAlert-vX.X.X-shared.zip` depuis la page [Releases](../../releases).
2. Décompressez son contenu dans votre dossier partagé, par exemple `\\serveur\partage\flashalert\shared\`.
3. Renommez `menu.txt.example` en `menu.txt` et adaptez-le à vos besoins (voir section [Configuration](#️-configuration)).
4. Vérifiez les permissions réseau (voir section [Permissions](#-permissions-réseau-requises)).

**Étape 2 — Installer l'appelant**

1. Téléchargez `FlashAlert-vX.X.X-appelant.zip` et décompressez-le sur le poste opérateur.
2. Renommez `alerte.ini.example` en `alerte.ini` et renseignez les chemins UNC.
3. Lancez `Alerte_Appelant.exe`.

**Étape 3 — Installer les clients**

1. Téléchargez `FlashAlert-vX.X.X-client.zip` et décompressez-le sur chaque poste client.
2. Renommez `alerte.ini.example` en `alerte.ini` et renseignez les chemins UNC.
3. Lancez `Alerte_Client.exe` — idéalement au démarrage de session via GPO ou dossier Démarrage.

### Compilation depuis les sources

1. Installez [AutoIt v3](https://www.autoitscript.com/site/autoit/downloads/).
2. Clonez ce dépôt.
3. Ouvrez `src/appelant/Alerte_Appelant.au3` et `src/client/Alerte_Client.au3` dans **SciTE** (l'éditeur AutoIt) ou compilez via `Aut2Exe`.

---

## ⚙️ Configuration

### Fichier `alerte.ini` — Appelant

```ini
[Chemins]
; Chemin UNC vers le fichier de message partagé
Message=\\serveur\partage\flashalert\shared\message.txt
; Chemin UNC vers le fichier menu
Menu=\\serveur\partage\flashalert\shared\menu.txt
; Chemin UNC vers le fichier de log
Log=\\serveur\partage\flashalert\shared\log.txt

[Options]
; Délai (en secondes) avant déclenchement automatique du bouton principal
Delai=10
```

### Fichier `alerte.ini` — Client

```ini
[Chemins]
Message=\\serveur\partage\flashalert\shared\message.txt
Log=\\serveur\partage\flashalert\shared\log.txt
Son=\\serveur\partage\flashalert\shared\alerte.wav

[Options]
; Intervalle de vérification du fichier en millisecondes
Intervalle=3000
; Délai de répétition du son (en secondes)
SonRepeat=15
```

### Fichier `menu.txt` — Définition des alertes

```
; FORMAT : Texte_bouton|TYPE|Titre|Corps
; TYPE : urgence / alerte / info
; [PRINCIPAL] = bouton déclenché automatiquement si pas de clic

[PRINCIPAL]
AGRESSION / DANGER IMMEDIAT|urgence|AGRESSION A L'ACCUEIL|Situation de danger à l'accueil. Intervention immédiate requise.

[BOUTON]
Besoin d'aide - Accueil saturé|alerte|RENFORT ACCUEIL|File d'attente importante. Renfort demandé à l'accueil.
```

---

## 🔒 Permissions réseau requises

| Poste | Accès requis |
|---|---|
| Appelant | Lecture + **Écriture** sur `message.txt`, `log.txt` — Lecture sur `menu.txt` |
| Client | Lecture sur `message.txt`, `alerte.wav` — Écriture sur `log.txt` |

---

## 📜 Licence

Ce projet est distribué sous licence **GNU Affero General Public License v3.0 (AGPL-3.0)**.

Cela signifie que vous êtes libre d'utiliser, modifier et redistribuer ce logiciel, y compris dans un contexte réseau (SaaS), à condition de publier les sources modifiées sous la même licence.

Voir le fichier [LICENSE](LICENSE) pour le texte complet.

---

## 🤝 Contribuer

Les contributions sont les bienvenues ! Pour proposer une amélioration :

1. Forkez le dépôt
2. Créez une branche (`git checkout -b feature/ma-fonctionnalite`)
3. Committez vos modifications (`git commit -m 'Ajout : ma fonctionnalité'`)
4. Poussez la branche (`git push origin feature/ma-fonctionnalite`)
5. Ouvrez une **Pull Request**

---

## 💡 Idées d'évolution

- Support multi-appelants simultanés
- File d'attente d'alertes (pour ne pas écraser une alerte non acquittée)
- Interface de configuration graphique pour `menu.txt`
- Export des logs en CSV
- Client Linux/macOS (via port Python/tkinter)
