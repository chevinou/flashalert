# Changelog

Toutes les modifications notables de ce projet sont documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Versionnage Sémantique](https://semver.org/lang/fr/).

---

## [1.0.0] — 2026-06-05

### 🎉 Première version publique

#### Ajouté
- **Appelant** : interface graphique avec boutons d'alerte configurables via `menu.txt`
- **Appelant** : 3 niveaux de criticité — urgence (rouge), alerte (orange), info (bleu)
- **Appelant** : déclenchement automatique du bouton principal après délai configurable
- **Appelant** : bouton d'annulation pour les missclics
- **Appelant** : horodatage et identification de l'expéditeur (nom d'utilisateur + poste)
- **Client** : agent silencieux en systray, démarrage automatique possible
- **Client** : surveillance du fichier partagé par polling configurable
- **Client** : popup visuelle colorée avec badge de criticité, titre et corps du message
- **Client** : son d'alerte répété à intervalle configurable jusqu'à acquittement
- **Client** : maintien au premier plan et clignotement de la fenêtre si elle perd le focus
- **Client** : acquittement explicite obligatoire ("J'ai lu")
- **Partagé** : communication via fichier texte UNC — aucune dépendance serveur
- **Partagé** : journalisation des envois et réceptions dans `log.txt`
- **Partagé** : fichier `menu.txt` entièrement configurable (boutons, types, titres, corps)
- Configuration par fichiers `alerte.ini` indépendants pour l'appelant et le client
- Icônes distinctes pour l'appelant et le client
- Protection contre les instances multiples (`_Singleton`)

---

## À venir

Voir la section [Idées d'évolution](README.md#-idées-dévolution) du README.
