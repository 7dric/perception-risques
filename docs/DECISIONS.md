# Décisions d'architecture (ADR)

Format court : contexte, décision, conséquences. On n'efface pas une décision, on la remplace
par une nouvelle qui y fait référence.

## ADR-001 — Godot 4 comme outil de production 3D

- **Contexte** : il faut de la 3D temps réel, une licence libre compatible avec un usage commercial,
  et un éditeur visuel pour placer routes, véhicules et dangers sans être expert 3D.
- **Décision** : Godot 4.x (MIT), scripts en GDScript.
- **Conséquences** : pas de redevance ; éditeur de scènes intégré ; Movie Maker intégré pour le rendu
  vidéo. Rendu moins photoréaliste qu'Unreal, ce qui est acceptable.

## ADR-002 — Vidéos pré-rendues et annotées, pas de 3D dans le navigateur

- **Contexte** : l'élève s'entraîne sur un site web ; les PC des élèves sont très variés.
- **Décision** : Godot tourne en local et produit des vidéos et des annotations JSON. Le site ne
  lit que des vidéos.
- **Conséquences** : qualité identique pour tous, site léger ; chaque variation de scénario demande
  un nouveau rendu (automatisé en J3 et J6).

## ADR-003 — Lecteur web statique en TypeScript + Vite

- **Décision** : site statique, sans serveur applicatif, hébergeable n'importe où.
- **Conséquences** : l'intégration d'Odoo (comptes, paiement) se fera plus tard par API.

## ADR-004 — Codecs libres de redevances : AV1 et VP9 en WebM

- **Contexte** : H.264 et HEVC sont soumis à des brevets et à des licences payantes possibles.
- **Décision** : AV1 (SVT-AV1) en principal, VP9 en repli, conteneur WebM. FFmpeg est utilisé
  comme outil interne, non redistribué.

## ADR-005 — Scénarios : éditeur d'abord, données ensuite

- **Décision** : en J1 à J5, un scénario est une scène Godot. En J6, un format YAML permet
  l'assemblage et les variations automatiques.

## ADR-006 — Barème identique à l'officiel, moteur paramétrable

- **Décision** : le moteur de score lit ses paramètres dans un fichier de règles. Les valeurs
  officielles y seront saisies une fois la recherche faite (voir `exam-rules.md`).

## ADR-007 — Français d'abord, i18n prévue

- **Décision** : tous les textes passent par des clés de traduction ; les annotations portent
  des textes par langue (`{"fr": "..."}`). NL, DE et EN viendront ensuite.

## ADR-008 — Périmètre de la V1

- **Décision** : mode examen et correction expliquée. Comptes, suivi et paiement plus tard, via Odoo.
