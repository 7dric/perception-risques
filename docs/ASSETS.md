# Registre des assets

Tout fichier tiers (modèle 3D, texture, son, police, panneau) ajouté au projet doit avoir une
ligne ici. Pas de ligne, pas d'asset.

Les assets Poly Haven sont listés dans `production/assets/assets.json` et téléchargés par
`npm run fetch-assets` (non versionnés, voir ADR-018) ; leurs lignes ci-dessous sont générées
par ce script. Les autres lignes sont tenues à la main.

Les modèles Sketchfab (téléchargement avec compte) sont déposés en archive dans
`production/assets/_inbox/`, extraits dans `production/assets/sketchfab/<id>/` avec leur
`license.txt`, et ne sont pas versionnés non plus (ADR-018). Crédit CC-BY à reprendre tel quel
sur la page de crédits :

- This work is based on "Generic passenger car pack"
  (https://sketchfab.com/3d-models/generic-passenger-car-pack-20f9af9b8a404d5cb022ac6fe87f21f5)
  by Comrade1280 (https://sketchfab.com/comrade1280) licensed under CC-BY-4.0
  (http://creativecommons.org/licenses/by/4.0/)

| Fichier ou dossier | Source (URL) | Auteur | Licence | Usage | Date d'ajout | Modifié ? |
|---|---|---|---|---|---|---|
| `production/assets/sketchfab/generic_passenger_car_pack/` | https://sketchfab.com/3d-models/generic-passenger-car-pack-20f9af9b8a404d5cb022ac6fe87f21f5 | Comrade1280 | CC-BY-4.0 | Modèle — 10 voitures génériques sans marque (stationnement, trafic) | 2026-11-17 | Non (à débadger si un détail de marque apparaît) |
<!-- fetch-assets:begin -->
| `production/assets/polyhaven/asphalt_02/` | https://polyhaven.com/a/asphalt_02 | Rob Tuytel | CC0 | Texture 2k — Chaussée | 2026-11-17 | Non |
| `production/assets/polyhaven/square_concrete_pavers/` | https://polyhaven.com/a/square_concrete_pavers | Amal Kumar | CC0 | Texture 2k — Trottoir (dalles 30 × 30) | 2026-11-17 | Non |
| `production/assets/polyhaven/granular_concrete/` | https://polyhaven.com/a/granular_concrete | Dario Barresi, Michael Jenkins | CC0 | Texture 2k — Bordures | 2026-11-17 | Non |
| `production/assets/polyhaven/red_brick_03/` | https://polyhaven.com/a/red_brick_03 | Rob Tuytel | CC0 | Texture 2k — Façade en brique rouge | 2026-11-17 | Non |
| `production/assets/polyhaven/brown_brick_02/` | https://polyhaven.com/a/brown_brick_02 | Rob Tuytel | CC0 | Texture 2k — Façade en brique brune | 2026-11-17 | Non |
| `production/assets/polyhaven/whitewashed_brick/` | https://polyhaven.com/a/whitewashed_brick | Charlotte Baglioni | CC0 | Texture 2k — Façade en brique peinte | 2026-11-17 | Non |
| `production/assets/polyhaven/plaster_grey_04/` | https://polyhaven.com/a/plaster_grey_04 | Rob Tuytel | CC0 | Texture 2k — Façade enduite | 2026-11-17 | Non |
| `production/assets/polyhaven/kloofendal_48d_partly_cloudy_puresky/` | https://polyhaven.com/a/kloofendal_48d_partly_cloudy_puresky | Greg Zaal, Jarod Guest | CC0 | HDRI 4k — Jour, ciel partiellement nuageux | 2026-11-17 | Non |
| `production/assets/polyhaven/kloofendal_overcast_puresky/` | https://polyhaven.com/a/kloofendal_overcast_puresky | Greg Zaal | CC0 | HDRI 4k — Jour couvert, pluie, brouillard | 2026-11-17 | Non |
| `production/assets/polyhaven/qwantani_dusk_2_puresky/` | https://polyhaven.com/a/qwantani_dusk_2_puresky | Greg Zaal, Jarod Guest | CC0 | HDRI 4k — Crépuscule | 2026-11-17 | Non |
| `production/assets/polyhaven/qwantani_sunrise_puresky/` | https://polyhaven.com/a/qwantani_sunrise_puresky | Greg Zaal, Jarod Guest | CC0 | HDRI 4k — Aube | 2026-11-17 | Non |
| `production/assets/polyhaven/qwantani_night_puresky/` | https://polyhaven.com/a/qwantani_night_puresky | Greg Zaal, Jarod Guest | CC0 | HDRI 4k — Nuit | 2026-11-17 | Non |
| `production/assets/polyhaven/syferfontein_6d_clear_puresky/` | https://polyhaven.com/a/syferfontein_6d_clear_puresky | Greg Zaal, Jarod Guest | CC0 | HDRI 4k — Soleil rasant | 2026-11-17 | Non |
| `production/assets/polyhaven/modular_urban_apartments_facade/` | https://polyhaven.com/a/modular_urban_apartments_facade | James Ray Cock | CC0 | Modèle 2k — Façades d'immeubles en brique | 2026-11-17 | Non |
| `production/assets/polyhaven/street_lamp_01/` | https://polyhaven.com/a/street_lamp_01 | Josh Dean | CC0 | Modèle 2k — Lampadaire | 2026-11-17 | Non |
| `production/assets/polyhaven/metal_trash_can/` | https://polyhaven.com/a/metal_trash_can | GurJas Studios | CC0 | Modèle 2k — Poubelle | 2026-11-17 | Non |
| `production/assets/polyhaven/modular_street_seating/` | https://polyhaven.com/a/modular_street_seating | Stuart Attenborrow | CC0 | Modèle 2k — Banc | 2026-11-17 | Non |
| `production/assets/polyhaven/planter_box_01/` | https://polyhaven.com/a/planter_box_01 | James Ray Cock | CC0 | Modèle 2k — Bac à fleurs | 2026-11-17 | Non |
<!-- fetch-assets:end -->
