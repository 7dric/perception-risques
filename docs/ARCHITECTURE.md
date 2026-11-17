# Architecture

Le projet a deux parties reliées par un seul contrat : le **format d'annotation des clips**
(`schema/clip.schema.json`).

```
┌──────────────────────── Production (interne, PC) ────────────────────────┐
│  Scénario (scène Godot .tscn, plus tard fichier YAML)                    │
│     │                                                                    │
│     ▼                                                                    │
│  Simulation déterministe Godot 4 (--fixed-fps 30)                        │
│     ├─► Movie Maker (--write-movie) : images + audio                     │
│     └─► AnnotationRecorder : polygones 2D des dangers, image par image   │
│     │                                                                    │
│     ▼                                                                    │
│  tools/encode (FFmpeg) : WebM AV1, repli VP9                             │
│  tools/validate : contrôle du JSON et vidéo de contrôle                  │
│     │                                                                    │
│     ▼                                                                    │
│  content/ : clip.webm + clip.json + manifest.json                        │
└──────────────────────────────────────────────────────────────────────────┘
                              │ (publication sur un stockage statique / CDN)
                              ▼
┌──────────────────────── Lecteur (public, web) ───────────────────────────┐
│  TypeScript + Vite, 100 % côté navigateur                                │
│  <video> + <canvas> superposé                                            │
│  Mode examen → clics (image, x, y) → moteur de score → correction         │
└──────────────────────────────────────────────────────────────────────────┘
```

## Production (Godot 4)

- **Déterminisme** : toute la logique avance au pas fixe de la simulation, avec une graine aléatoire
  fixée par scénario. Deux rendus d'un même scénario doivent donner les mêmes images.
- **Cockpit** : la caméra principale filme le pare-brise. Trois caméras de rétroviseur rendent
  dans des `SubViewport`, affichés sur l'interface du cockpit. Le compteur et les clignotants font
  partie de l'interface. Le tout est capturé dans la vidéo.
- **Dangers** : chaque danger est un nœud `Hazard` (identifiant, type, fenêtre de temps, moment idéal,
  textes). Il porte une forme 3D simple (boîte ou ensemble de points) qui sert de zone cliquable.
- **AnnotationRecorder** : à chaque image, il projette les points de la forme avec
  `Camera3D.unproject_position`, calcule l'enveloppe convexe et vérifie par raycast que le danger n'est
  pas masqué. Pour les rétroviseurs, la projection passe par la caméra du rétroviseur puis est placée
  dans le rectangle du rétroviseur à l'écran (avec l'effet miroir horizontal). Les coordonnées sont
  normalisées entre 0 et 1.
- **Compression** : seules les images clés sont gardées ; le lecteur interpole entre elles.

## Lecteur web

- **Synchro** : `requestVideoFrameCallback` donne l'image affichée ; repli sur `currentTime × fps`.
- **Clics** : enregistrés en coordonnées normalisées, avec le numéro d'image.
- **Score** : moteur pur (sans DOM), paramétré par un fichier de règles
  (`rules/official-be.json`), testé unitairement.
- **Correction** : replay, ralenti, polygone du danger, fenêtre de temps sur une frise, clics de
  l'élève, explication.
- **Langues** : tous les textes passent par des clés de traduction dès le départ ; seul le français
  est rempli au début.

## Données

| Fichier | Rôle |
|---|---|
| `clip.webm` | Vidéo du scénario (AV1, repli VP9) |
| `clip.json` | Annotations conformes à `schema/clip.schema.json` |
| `manifest.json` | Liste des clips, durée, difficulté, types de danger |
| `rules/official-be.json` | Paramètres du barème |

Les vidéos ne sont pas versionnées dans Git (voir `.gitignore`).
