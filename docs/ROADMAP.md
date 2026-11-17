# Feuille de route

Chaque jalon se termine par un livrable vérifiable. Statut : ⬜ à faire · 🟡 en cours · ✅ terminé.

Les jalons sont ordonnés pour livrer au plus tôt nos différenciateurs D1 à D5
(voir [benchmark.md](benchmark.md)).

## J0 — Fondations 🟡

- ✅ Décisions de départ (voir [DECISIONS.md](DECISIONS.md))
- ✅ Architecture, licences, arborescence du dépôt
- ✅ Brouillon du format d'annotation `schema/clip.schema.json` v0 (pièges, conditions, graine)
- ✅ Analyse de la concurrence et choix des différenciateurs (voir [benchmark.md](benchmark.md))
- 🟡 Règles officielles (voir [exam-rules.md](exam-rules.md)) : format connu par les concurrents,
  à confirmer auprès des sources officielles
- ⬜ Catalogue des dangers relu et priorisé (voir [hazard-catalog.md](hazard-catalog.md))
- ⬜ Choix du niveau de réalisme visuel

**Terminé quand** : règles confirmées avec sources officielles, schéma v0 relu.

## J1 — Tranche verticale Godot, paramétrable dès le départ ⬜

- Un carrefour urbain, le véhicule de l'élève suit un `Path3D` à vitesse scriptée
- Cockpit : vue pare-brise, rétroviseur central et deux rétroviseurs latéraux (`SubViewport`),
  compteur, clignotants
- Un danger (piéton qui traverse) et un piège (piéton immobile sur le trottoir)
- **Scénario paramétré** : graine aléatoire, moment du jour, météo (préparation de D1 et D5)
- Rendu avec Movie Maker (`--write-movie`, `--fixed-fps`) et export JSON par `AnnotationRecorder`

**Terminé quand** : un clip de 20 à 30 s et son JSON valide ; même graine = mêmes images ;
deux graines différentes = deux clips différents.

## J2 — Lecteur web MVP ⬜

- Lecture du clip, `<canvas>` superposé, synchro par `requestVideoFrameCallback`
- Mode examen au barème officiel : 5 clips, 10 clics pour tout le test, seul le premier clic sur
  un danger compte, clic hors danger perdu, arrêt quand les clics sont épuisés
- Correction : replay, ralenti, dangers et pièges encadrés, clics de l'élève, explication
- **D3 — note de précision** : délai de chaque clic par rapport au moment idéal

**Terminé quand** : tests `vitest` du score et test `playwright` de clics dans et hors zone au vert.

## J3 — Pipeline industrialisé ⬜

- `tools/render-all` : rendu en lot avec Godot sans interface, une ou plusieurs graines par scénario
- `tools/encode` : FFmpeg vers WebM AV1, repli VP9
- `tools/validate` : vidéo de contrôle avec les polygones dessinés, validation du JSON
- `manifest.json` (catalogue des clips, conditions, types de danger) et validation en CI

## J4 — Générateur de scénarios (D1) et conditions variées (D5) ⬜

- Briques de route : ville, campagne, voie rapide, rond-point, carrefour à priorité de droite, travaux
- Bibliothèque de comportements d'acteurs réutilisables (piéton, cycliste, voiture, bus, camion,
  enfant, moto…), dangers et pièges
- Scénarios décrits en YAML, assemblés automatiquement, variés par graine
  (positions, timings, acteurs, trafic de fond)
- Conditions : jour, nuit, aube, pluie, brouillard, soleil rasant
- Garde-fous : vérification automatique qu'un danger est bien visible pendant sa fenêtre

**Terminé quand** : une commande produit 100 clips valides et différents.

## J5 — Contenu et exercices courts (D4) ⬜

- Explications en français pour chaque type de danger et de piège
- Exercices courts : clips de 10 s à un seul danger
- Exercice « pause : que va-t-il se passer ? » (choix parmi plusieurs propositions)
- Examens tirés au hasard dans le catalogue, en respectant la répartition officielle

## J6 — Entraînement adaptatif (D2) ⬜

- Historique des réponses par type de danger et par condition
  (dans le navigateur d'abord, sur un compte ensuite)
- Tableau de progression : points faibles, délai moyen de réaction
- Séries ciblées générées sur les points faibles

## J7 — Bêta ⬜

- Tests avec des élèves et des auto-écoles, accessibilité, finitions

## J8 — Plus tard ⬜

- Comptes, suivi multi-appareil et paiement via Odoo
- Mode flamand « questions après le film » et traductions (NL, puis DE et EN)
- Offre auto-écoles, éventuelle application desktop

## Questions ouvertes

1. Confirmer les règles officielles par région (sources officielles).
2. Hébergement des vidéos : avec la génération, le volume grossit vite (environ 5 à 15 Mo par clip
   en AV1 1080p) : CDN, stockage objet.
3. Odoo Community (LGPLv3) ou Enterprise (propriétaire, payant).
4. Réalisme visuel visé : low-poly soigné ou proche du photoréalisme.
