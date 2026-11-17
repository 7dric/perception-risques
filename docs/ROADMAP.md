# Feuille de route

Chaque jalon se termine par un livrable vérifiable. Statut : ⬜ à faire · 🟡 en cours · ✅ terminé.

Les jalons sont ordonnés pour livrer au plus tôt nos différenciateurs D1 à D5
(voir [benchmark.md](benchmark.md)).

## J0 — Fondations ✅

- ✅ Décisions de départ (voir [DECISIONS.md](DECISIONS.md))
- ✅ Architecture, licences, arborescence du dépôt
- ✅ Brouillon du format d'annotation `schema/clip.schema.json` v0 (pièges, conditions, graine)
- ✅ Analyse de la concurrence et choix des différenciateurs (voir [benchmark.md](benchmark.md))
- ✅ Règles de l'examen retenues (voir [exam-rules.md](exam-rules.md), ADR-013)
- ✅ Niveau de rendu : soigné et proche de l'examen officiel (ADR-012)
- ✅ Environnement de travail : Godot 4.7, FFmpeg (AV1, VP9), Node.js, Vite, Vitest, Playwright,
  validation du schéma, diagnostic `npm run check-env` (voir [SETUP.md](SETUP.md), ADR-016)
- ✅ Catalogue des dangers relu et priorisé : 29 dangers, 11 pièges, étiquettes, fenêtres
  (voir [hazard-catalog.md](hazard-catalog.md), ADR-017)
- ✅ Schéma v0 relu, exemple validé par `npm run validate:schema`

**Terminé quand** : catalogue relu, schéma v0 relu.

## J1 — Tranche verticale Godot, paramétrable dès le départ ⬜

- **Look de référence d'abord** : une image fixe du carrefour, depuis le cockpit, au niveau de
  qualité visé (matériaux PBR, éclairage global, HDRI, véhicules et piétons réalistes), validée
  avant de passer à l'animation
- Recherche des assets réalistes sous licence libre (véhicules, piétons, mobilier urbain belge),
  inscrits dans [ASSETS.md](ASSETS.md)
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

## J2b — Prototype d'analyse du regard (D6) ⬜

- Activation volontaire, écran de consentement (voir [privacy.md](privacy.md))
- Webcam + MediaPipe Face Landmarker dans le navigateur, calibration sur 9 points
- Mesure de la précision réelle : plusieurs PC et webcams, éclairages, porteurs de lunettes
- Superposition de la trajectoire du regard dans l'écran de correction

**Terminé quand** : rapport de précision (erreur moyenne en cm et en % d'écran) et décision
go/no-go pour J6b.

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

## J6b — Analyse du regard complète (D6) ⬜

Si J2b est concluant :
- « Vu ou pas vu » : moment du premier regard sur un danger comparé au moment du clic
- Coups d'œil aux rétroviseurs et au compteur : fréquence et durée
- Vision tunnel : dispersion du regard
- Pièges : l'élève a-t-il été attiré par un piège ?
- Carte de chaleur du regard en correction
- Nouvelles faiblesses suivies par l'entraînement adaptatif (« oublie les rétroviseurs »)

## J7 — Bêta ⬜

- Tests avec des élèves et des auto-écoles, accessibilité, finitions

## J8 — Plus tard ⬜

- Comptes, suivi multi-appareil et paiement via Odoo
- Mode flamand « questions après le film » et traductions (NL, puis DE et EN)
- Offre auto-écoles, éventuelle application desktop

## Questions ouvertes

1. Véhicules et piétons réalistes sous licence libre : assez nombreux et assez beaux ? (risque
   principal du rendu, à lever en J1)
2. Temps de rendu par clip au niveau de qualité visé, et donc nombre de clips réaliste pour D1.
3. Hébergement des vidéos : avec la génération, le volume grossit vite (environ 5 à 15 Mo par clip
   en AV1 1080p) : CDN, stockage objet.
4. Odoo Community (LGPLv3) ou Enterprise (propriétaire, payant).
5. Précision réelle de l'analyse du regard par webcam : suffisante pour les zones ? (levée par J2b)
