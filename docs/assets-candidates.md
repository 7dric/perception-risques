# Candidats pour les véhicules et les piétons réalistes (J1)

Recherche du 17/11/2026. La licence de chaque modèle Sketchfab a été lue dans l'API publique
`api.sketchfab.com/v3/models/{uid}` (`license.label`). Ce sont les mêmes données que la page.
La qualité visuelle reste **à confirmer dans la visionneuse** avant de télécharger.

Le téléchargement Sketchfab demande un compte. Déposer les archives (glTF/GLB de préférence)
dans `production/assets/_inbox/`, sans les décompresser. Chaque modèle retenu sera ensuite
inscrit dans [ASSETS.md](ASSETS.md) avec auteur, lien et licence, et cité sur la page de crédits.

## À écarter : modèles extraits de jeux

Beaucoup de voitures récentes en « CC Attribution » sont extraites de jeux (mods GTA, fiches
Forza, Asphalt 8) ou n'indiquent pas leur origine. On les exclut, même si la licence affichée
les autoriserait : celui qui les a publiées n'en détient pas les droits. Comptes concernés :
BHP3D, Car2022, tonielpro520, niev, DR1KING100K, Res1n, iwillsearch69, dannzjs.

## Voitures

Le pack générique (10 voitures sans marque) est **intégré** depuis le 17/11/2026 : il suffit pour
le stationnement et le trafic de J1. Les modèles de marque ci-dessous ne seront ajoutés qu'après
retrait des logos et retouche des traits reconnaissables (voitures génériques uniquement, à cause
des droits des constructeurs). Calandres du SUV et du pick-up à vérifier de près.

| Priorité | Modèle | Lien | Auteur | Licence | Triangles | Remarque |
|---|---|---|---|---|---|---|
| 1 | Iveco Daily Van 2014 | https://sketchfab.com/3d-models/30003fba5b074d6eb7bc74fd5e1e7d19 | Max-7215 | CC-BY | 90 k | PBR, textures 4K |
| 2 | Opel Astra GTC 2012 | https://sketchfab.com/3d-models/d76ad5a0495443eda24a9052565ef9a8 | comrade1280 | CC-BY | 254 k | Compacte ; matériaux sans doute à refaire |
| 3 | Fiat Punto GT 1995 | https://sketchfab.com/3d-models/48db6facb4b64e99b60f36b8c01185e1 | lionsharp | CC-BY 4.0 | 35 k | Citadine ancienne |
| 4 | Small price car (Nexia 2004) | https://sketchfab.com/3d-models/67c84e4d30ae42fda22c0a0c7526df26 | Oliv1e | CC-BY | 42 k | Berline, PBR |
| fond | Generic passenger car pack (10 voitures) | https://sketchfab.com/3d-models/20f9af9b8a404d5cb022ac6fe87f21f5 | comrade1280 | CC-BY | < 8 k chacune | Trafic lointain, voitures en stationnement |
| attente | Mercedes Sprinter 2006 | https://sketchfab.com/3d-models/f69de1315bb049c8946d57f6006acd73 | Max-7215 | CC-BY | 38 k | La description dit « not free of rights » : il faut l'accord écrit de l'auteur |

Aucun SUV compact ni break récent à provenance propre en CC0 ou CC-BY. Il faudra en acheter
(licence royalty-free) ou les modéliser. Logos et calandres reconnaissables : à retirer (droit
des marques, dessins et modèles).

## Piétons

| Priorité | Modèle | Lien | Auteur | Licence | Rig / animation |
|---|---|---|---|---|---|
| 1 | Nathan Animated 003 (marche) | https://sketchfab.com/3d-models/143a2b1ea5eb4385ae90a73657aca3bc | renderpeople | CC-BY 4.0 | Marche mocap en boucle |
| 2 | Sophia Animated 003 (attente) | https://sketchfab.com/3d-models/dc448c3be0e74f96a55fb475a13433cf | renderpeople | CC-BY | Attente en boucle |
| 3 | Eric Rigged 001 | https://sketchfab.com/3d-models/a46bc9f67aaa415bb4f3241eef900e7f | renderpeople | CC-BY 4.0 | Riggé, sans animation |
| 3 | Carla Rigged 001 | https://sketchfab.com/3d-models/acf520f450d14dd799f98a6fede3edf5 | renderpeople | CC-BY | Riggé, sans animation |
| 3 | Claudia Rigged 002 | https://sketchfab.com/3d-models/c659bd0accab47c6bbe390cf822a2b92 | renderpeople | CC-BY | Riggé, sans animation |

- **Enfants** : Microsoft Rocketbox (MIT, https://github.com/microsoft/Microsoft-Rocketbox,
  4 enfants riggés) ou un export MakeHuman (CC0).
- **Animations** : 100STYLE (CC-BY 4.0, https://www.ianxmason.com/100style/, BVH, marche,
  course, attente). CMU : licence non vérifiée sur le site d'origine. La conversion FBX de 4TU
  est en CC BY-NC : à exclure.
- Squelettes différents (Renderpeople, Rocketbox, Xsens) : retargeting par
  `SkeletonProfileHumanoid` dans Godot.

## Mobilier

| Modèle | Lien | Auteur | Licence |
|---|---|---|---|
| Feux tricolores Siemens | https://sketchfab.com/3d-models/d03dfd56151b448d8f7dd841d9dd4242 | Signalrenders | CC-BY |
| Potelet en béton scanné | https://sketchfab.com/3d-models/f475b7954bae4acdb00183171744aece | kaimoisch | CC-BY |
| Street Asset Pack 01 | https://sketchfab.com/3d-models/9752f598cc5541acb3de07150d1a4ae4 | crazyyuan | CC-BY |
| Standard Bus Stop | https://sketchfab.com/3d-models/32cc4c5f6aa147acabdb173e2d2373fa | pukkafilms | CC-BY |

Panneaux belges : SVG du domaine public sur Wikimedia Commons (exemple :
`File:Belgian_road_sign_B1.svg`), plaqués sur un poteau modélisé par nous. Vérifier chaque
fichier.

## Risques

- Une licence CC-BY ne prouve pas que l'auteur détient les droits. Garder une trace datée de
  la réponse de l'API pour chaque modèle retenu.
- Sketchfab migre vers Fab (Epic) : télécharger et archiver tôt.
- Textures 8K des Renderpeople à réduire en 2K ; modèles à plus de 250 k triangles à alléger.
