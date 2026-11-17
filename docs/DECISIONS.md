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

## ADR-014 — Analyse du regard par webcam (D6)

- **Contexte** : savoir où l'élève regarde permet de distinguer « pas vu » de « vu mais pas
  reconnu comme danger », et de vérifier l'usage des rétroviseurs. Aucun concurrent ne le fait.
- **Décision** :
  - Détection dans le navigateur avec MediaPipe Tasks Vision, Face Landmarker (Apache-2.0) :
    478 points du visage, dont l'iris, sans serveur.
  - Calibration maison : l'élève fixe 9 points, puis une régression (iris + pose de la tête)
    donne la position à l'écran ; recalibration rapide entre deux clips.
  - Précision attendue d'environ 1 à 2 cm à l'écran : on raisonne par **zones** (pare-brise
    gauche, centre, droite ; rétroviseurs ; compteur) et par **polygones de danger agrandis**.
  - WebGazer.js écarté : licence GPL-3.0, incompatible avec un produit fermé.
- **Conséquences** :
  - Prototype de faisabilité en J2b, avec décision go/no-go selon la précision mesurée.
    Fonction complète en J6b.
  - Fonction optionnelle : ordinateur avec webcam et bon éclairage ; lunettes et mouvements de
    tête dégradent la précision. Elle ne change jamais le barème officiel.
  - Le schéma d'annotation ne change pas : polygones et `views` suffisent.

## ADR-015 — Données du regard : traitement 100 % local

- **Contexte** : l'image du visage est une donnée personnelle sensible, et beaucoup d'élèves
  sont mineurs.
- **Décision** : voir [privacy.md](privacy.md). L'image webcam est traitée dans le navigateur,
  jamais envoyée ni enregistrée. Activation volontaire, consentement clair. Seules des
  statistiques sont conservées, effaçables par l'élève.

## ADR-016 — Outillage entièrement sous Windows

- **Contexte** : Godot a besoin du GPU (Vulkan), indisponible correctement sous WSL. Le dépôt est
  sur `C:`. Le réseau de WSL corrompt les gros téléchargements HTTPS, ce qui empêche
  `npm install`. Sous `/mnt/c`, Vite ne voit pas les fichiers modifiés depuis un éditeur Windows.
- **Décision** : Godot, FFmpeg et Node.js sont installés sous Windows (winget). WSL ne sert qu'à
  appeler ces outils via `tools/winrun.cmd`. Détails dans [SETUP.md](SETUP.md).
- **Conséquences** : les scripts de `tools/` sont écrits en Node.js (pas en bash) pour tourner
  sous Windows ; `npm run check-env` vérifie l'installation.

## ADR-017 — Catalogue des dangers validé

- **Contexte** : J0 demandait un catalogue relu et priorisé avant de produire des scénarios.
- **Décision** : le catalogue de [hazard-catalog.md](hazard-catalog.md) est validé sans
  modification : définition du danger (réaction obligatoire, danger qui se concrétise), règles de
  fenêtre (premier indice, environ 2 s avant le conflit, 3 à 5 s) et de moment idéal (0,3 à 1 s
  après le début), 29 dangers dont 10 en P1, 11 pièges et leurs jumeaux, 1 à 2 pièges par clip,
  liste fermée d'étiquettes, composition provisoire d'un examen, situations belges.
- **Conséquences** : les identifiants `type` sont figés ; un clic avant la fenêtre est un clic
  perdu ; l'ancien type `bus_stop` devient `bus_stop_pedestrian`. Toute modification du
  catalogue passe par une nouvelle ADR. J0 est terminé.

## ADR-018 — Tranche verticale J1 : décor par le code, assets téléchargés, annotations rectangulaires

- **Contexte** : J1 demande un carrefour, un cockpit, un danger, un piège, un scénario
  paramétré et un rendu déterministe avec annotations.
- **Décisions** :
  - **Décor construit par le code** (`Crossroads`, `FacadeKit`) plutôt que dans l'éditeur ou
    avec le plugin Road Generator : pour un carrefour, c'est plus court, entièrement varié par la
    graine (maisons, briques, mobilier) et réutilisable par le générateur de J4.
  - **Assets CC0 téléchargés par script, non versionnés** : `production/assets/assets.json`
    liste les assets Poly Haven ; `npm run fetch-assets` les télécharge (MD5 vérifié) et
    régénère leurs lignes de `ASSETS.md`. Les 18 premiers pèsent 259 Mo : trop pour Git. Les
    modèles Sketchfab (CC-BY, téléchargement avec compte) seront archivés hors de Git de la même
    façon ; leur stockage (Git LFS ou stockage objet) sera tranché à leur arrivée.
  - **Acteurs = fonctions pures du numéro d'image** : trajectoires (`Timeline`) et profils de
    vitesse (`SpeedProfile`) précalculés au démarrage depuis la graine. Pas d'horloge, pas de
    physique dynamique.
  - **Contour annoté = rectangle englobant** de la boîte du danger projetée (4 points, dans
    l'ordre haut-gauche, haut-droit, bas-droit, bas-gauche) au lieu de l'enveloppe convexe prévue
    dans ARCHITECTURE.md : un nombre de points fixe permet au lecteur d'interpoler entre deux
    images clés. Images clés gardées quand l'écart d'interpolation dépasse 0,003.
  - **Masquage** : visible si au moins 30 % de 9 rayons (centre et coins) atteignent la boîte.
    Au pare-brise, un contour dont le centre tombe sous un rétroviseur ou le compteur est
    considéré comme caché.
  - **Rendu** : Forward+, suréchantillonnage ×2 (`scaling_3d/scale = 2.0`), MSAA 2×, SDFGI,
    SSAO, SSIL, SSR, ombres douces, tonemapping AgX. Fenêtre réduite (960×540), viewport en
    1920×1080 (`stretch/mode = viewport`). Coût mesuré : 0,73 s par image sur la RTX 3050 de
    référence, soit environ 9 min pour un clip de 25 s.
  - **Déterminisme** : deux rendus de la même graine donnent des annotations identiques à
    l'octet, mais des images qui ne sont pas identiques au bit près (petites variations du GPU,
    SDFGI et effets temporels). Mesure du 17/11/2026 : PSNR minimal de 55 dB entre deux rendus,
    15 dB entre deux graines. Règle retenue (`npm run check:determinism`) : même graine = PSNR
    ≥ 50 dB sur chaque image ; deux graines = PSNR moyen ≤ 35 dB.

## ADR-019 — Véhicules génériques repeints, second décor résidentiel

- **Contexte** : J1 demande des clips variés d'une graine à l'autre (préparation de D1 et D5) ;
  le pack de voitures n'offre qu'une couleur par modèle et un seul décor existait.
- **Décisions** :
  - **Véhicules génériques uniquement, sans logo ni calandre de marque** : les modèles des
    constructeurs sont protégés ; le pack générique (CC-BY) est conservé.
  - **Peinture recolorée par shader** (`car_paint.gdshader`) : la peinture est repérée dans
    l'atlas de carrosserie par sa rugosité (0,06 à 0,13 sur les 10 modèles, garnitures à part) ;
    l'ombrage cuit est conservé en rapport de luminance. Teintes pondérées comme le parc belge
    (`Car.PAINTS`). Limite : sur quelques modèles, les jantes sont dans l'atlas et prennent la
    teinte.
  - **Décor paramétré** : `Crossroads` porte les dimensions et le style en propriétés d'instance ;
    `ResidentialCrossroads` en hérite (`--environment=residential`, déjà dans l'énumération du
    schéma). L'identifiant de clip contient le décor. Les autres décors de J4 suivront ce modèle.
  - **Ciel** : deux HDRI par moment de la journée, choisis par un générateur dérivé de la graine
    (le choix ne décale pas les autres tirages).
  - `GENERATOR_VERSION` 0.2.0 : une même graine ne donne plus le même clip qu'en 0.1.0.

## ADR-020 — Rendu vidéo direct, préréglages de qualité, une instance

- **Contexte** : un clip de 25 s coûtait 9 min (ADR-018). Mesure (`npm run bench:render`) :
  631 ms par image, dont 500 ms d'écriture PNG par Movie Maker ; le rendu 3D seul prend 130 ms.
- **Décisions** :
  - **Images envoyées directement à FFmpeg** (`FfmpegPipe`, `--movie=<fichier.mkv>`) : Movie
    Maker choisit son format avant l'exécution de tout script, on ne peut pas y brancher un
    format maison ; `Scenario` lit donc l'image après chaque rendu et l'écrit dans le tube de
    FFmpeg, qui encode en parallèle. Résultat : 151 ms par image, 2 min 32 s par clip.
  - **Master sans perte FFV1** (RGB, environ 1,6 Go par clip, fichier de travail) pour les
    contrôles et l'encodage final de J3, et **aperçu H.264** : NVENC si le pilote le permet
    (FFmpeg 9 demande un pilote NVIDIA ≥ 570), sinon libx264. Le déterminisme se vérifie sur les
    masters (MD5 par image, PSNR).
  - **Préréglage `--quality=fast`** (rendu ×1,5, MSAA 4×, rétroviseurs ×1, ombres moyennes,
    SSR 64 pas) : 81 ms de rendu au lieu de 130, briques un peu moins nettes et ombres de
    contact plus claires. La qualité `reference` reste le défaut en attendant la validation.
  - **Une instance Godot à la fois** : une instance occupe 4,2 Go de mémoire vidéo et 80 à 87 %
    du GPU ; deux instances sont 3 fois plus lentes. `render-batch` enchaîne les clips.
  - Vsync désactivée dans le projet (outil de production, sans écran).
