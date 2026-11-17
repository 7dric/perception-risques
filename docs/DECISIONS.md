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

> Remplacée en partie par ADR-010 : la génération arrive plus tôt.

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

## ADR-009 — Positionnement face à la concurrence

- **Contexte** : MaTheorie et TheoRoute proposent déjà la 3D, l'écran identique à l'examen, le
  format officiel et une correction au ralenti (voir [benchmark.md](benchmark.md)).
- **Décision** : ces fonctions sont un minimum. Le projet se distingue par cinq points :
  D1 volume quasi illimité par génération, D2 entraînement adaptatif, D3 note de précision
  (délai par rapport au moment idéal), D4 exercices courts, D5 conditions variées.
- **Conséquences** : la feuille de route est réordonnée pour livrer D3 en J2, D1 et D5 en J4,
  D4 en J5, D2 en J6.

## ADR-010 — Scénarios paramétrables dès J1, générateur en J4

- **Contexte** : D1 et D5 reposent sur la génération ; la reporter obligerait à refaire les
  premiers scénarios.
- **Décision** : dès J1, chaque scénario prend une graine aléatoire, un moment du jour et une
  météo. Le générateur à partir de fichiers YAML arrive en J4 (au lieu de J6).
- **Conséquences** : un peu plus de travail en J1 ; le format d'annotation enregistre la graine
  et les conditions de chaque clip.

## ADR-011 — Pièges annotés comme les dangers

- **Contexte** : à l'examen, un clic sur un usager qui n'est pas un danger fait perdre un clic.
  Les concurrents placent des pièges dans leurs films.
- **Décision** : les pièges sont annotés avec des pistes comme les dangers, dans une liste
  `decoys` séparée. Ils servent à la correction (« ce n'était pas un danger, voici pourquoi »)
  et aux statistiques de D2.

## ADR-012 — Rendu soigné, proche de l'examen officiel

- **Contexte** : l'élève doit se sentir dans les conditions de l'examen ; un rendu « jeu
  low-poly » ferait moins sérieux que les concurrents.
- **Décision** : viser un rendu réaliste, propre et lumineux, proche de l'esprit des films
  officiels : rues belges modernes, matériaux PBR, éclairage global, ombres douces, reflets.
  La composition de l'écran (pare-brise, trois rétroviseurs, compteur, clignotants) reprend
  celle de l'examen, mais **avec nos propres graphismes** (aucune image ni élément officiel copié).
- **Moyens** :
  - Godot 4 en rendu Forward+ : éclairage global (SDFGI ou VoxelGI), brouillard volumétrique,
    ombres douces, SSAO, SSR, ciel HDRI.
  - Le rendu vidéo n'est pas en temps réel : chaque image peut prendre le temps qu'il faut.
    Réglages au maximum, rendu en 4K puis réduit en 1080p (anticrénelage par suréchantillonnage),
    flou de mouvement léger.
  - Assets réalistes : Poly Haven et ambientCG (CC0) pour textures, HDRI et objets ; personnages
    créés avec MakeHuman (modèles exportés en CC0) ; animations issues de captures de mouvement
    libres. CC-BY accepté avec attribution (voir LICENSES.md).
- **Conséquences** :
  - Un jalon de « look » est ajouté en J1 : une image de référence validée avant de produire
    des scénarios.
  - Trouver des véhicules réalistes sous licence libre est le principal risque : à traiter dès J1.
  - Le temps de rendu par clip augmente : à mesurer en J3 (impact sur D1, qui demande beaucoup
    de clips).

## ADR-013 — Règles d'examen retenues

- **Contexte** : les règles décrites par les concurrents concordent entre elles.
- **Décision** : elles servent de référence pour le barème (voir exam-rules.md), sans attendre
  de confirmation officielle. Les valeurs restent dans un fichier de paramètres et pourront être
  corrigées si une source officielle les contredit.
