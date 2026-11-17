# Feuille de route

Chaque jalon se termine par un livrable vérifiable. Statut : ⬜ à faire · 🟡 en cours · ✅ terminé.

## J0 — Fondations 🟡

- ✅ Décisions de départ (voir [DECISIONS.md](DECISIONS.md))
- ✅ Architecture, licences, arborescence du dépôt
- ✅ Brouillon du format d'annotation `schema/clip.schema.json` v0
- ⬜ Recherche des règles officielles (voir [exam-rules.md](exam-rules.md)), avec sources
- ⬜ Catalogue des dangers relu et priorisé (voir [hazard-catalog.md](hazard-catalog.md))
- ⬜ Choix du niveau de réalisme visuel (voir les questions ouvertes)

**Terminé quand** : règles documentées avec sources, schéma v0 relu.

## J1 — Tranche verticale Godot ⬜

- Un carrefour urbain, le véhicule de l'élève suit un `Path3D` à vitesse scriptée
- Cockpit : vue pare-brise, rétroviseur central et deux rétroviseurs latéraux (`SubViewport`),
  compteur, clignotants
- Un danger : un piéton qui traverse
- Rendu avec Movie Maker (`--write-movie`, `--fixed-fps`)
- `AnnotationRecorder` : polygones 2D du danger à chaque image, export JSON conforme au schéma

**Terminé quand** : un clip de 20 à 30 s et son JSON valide ; deux rendus donnent des images identiques.

## J2 — Lecteur web MVP ⬜

- Lecture du clip, superposition d'un `<canvas>`, synchro par `requestVideoFrameCallback`
- Mode examen : pas de pause ni d'avance rapide, capture des clics (image + position normalisée)
- Moteur de score paramétrable (barème provisoire, puis officiel)
- Correction : replay, ralenti, zone du danger, fenêtre de temps, clics de l'élève, explication

**Terminé quand** : tests `vitest` du score et test `playwright` de clics dans et hors zone au vert.

## J3 — Pipeline industrialisé ⬜

- `tools/render-all` : rendu de tous les scénarios avec Godot sans interface
- `tools/encode` : FFmpeg vers WebM AV1, repli VP9
- `tools/validate` : vidéo de contrôle avec les polygones dessinés, validation du JSON
- `manifest.json` (catalogue des clips) et validation du schéma en CI

## J4 — Bibliothèque de contenu ⬜

- Modules de route : ville, campagne, autoroute, rond-point, carrefour à priorité de droite
- Comportements d'acteurs réutilisables (piéton, cycliste, voiture, bus, camion, enfant…)
- Météo et lumière variables, trafic de fond
- 20 à 30 scénarios avec explications en français

## J5 — Mode examen complet et bêta ⬜

- Série de clips conforme à l'examen officiel, score final, seuil de réussite
- Correction expliquée soignée, accessibilité
- Tests avec des élèves et des auto-écoles

## J6 — Scénarios pilotés par données ⬜

- Scénarios décrits en YAML et assemblés automatiquement
- Variations procédurales (positions, timings, acteurs) pour produire des centaines de clips

## J7 — Plus tard ⬜

- Comptes, suivi de progression et paiement via Odoo
- Traductions : néerlandais, allemand, anglais
- Éventuelle application desktop

## Questions ouvertes

1. Règles officielles exactes : nombre de clips, durée, fenêtre de réponse, barème, seuil.
2. Plusieurs dangers par clip ? Clics multiples autorisés ? Pénalité pour les clics hors zone ?
3. Hébergement des vidéos (environ 5 à 15 Mo par clip en AV1 1080p) : CDN, stockage objet, Git LFS.
4. Odoo Community (LGPLv3) ou Enterprise (propriétaire, payant).
5. Réalisme visuel visé : low-poly soigné ou proche du photoréalisme.
