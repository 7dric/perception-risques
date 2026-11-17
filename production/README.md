# production/ — projet Godot 4

Outil interne qui joue les scénarios 3D et produit les vidéos et les annotations.
Projet Godot 4.7, rendu Forward+ en 1920×1080 (suréchantillonné ×2), 30 pas de physique par
seconde. Commandes : voir [docs/SETUP.md](../docs/SETUP.md).

```
production/
  project.godot
  scenarios/   Scenario (classe de base), ScenarioParams (ligne de commande), un scénario par scène
  roads/       Crossroads (carrefour construit par le code), FacadeKit (maisons mitoyennes), Pbr (matériaux)
  environment/ Conditions : moment du jour, météo, ciel HDRI, soleil, pluie, éclairage public
  cockpit/     Cockpit (caméra pare-brise, rétroviseurs en SubViewport, capot), Dashboard (compteur, clignotants)
  actors/      Timeline et SpeedProfile (trajectoires), Pedestrian, Car, CarLibrary (modèles réalistes)
  hazards/     Hazard (danger ou piège), AnnotationRecorder (polygones image par image, export JSON)
  tests/       tests GDScript sans rendu (npm run test:godot) ; car_sheet.gd : planche de contrôle des voitures
  assets/      assets.json (liste des assets CC0) ; fichiers téléchargés non versionnés (ADR-018)
```

## Principes

- **Déterminisme** : un scénario ne tire au hasard qu'avec le `RandomNumberGenerator` initialisé
  par `--seed`. Les acteurs sont des fonctions pures du numéro d'image (trajectoires
  précalculées), jamais de l'horloge. On peut donc aussi sauter directement à une image
  (`--still-frame`).
- **Paramètres** (après `--`) : `--seed=42 --time=day|dawn|dusk|night
  --weather=clear|overcast|rain|fog|low_sun --environment=urban|residential
  --quality=reference|fast`, plus `--out=<dossier>` (JSON), `--movie=<fichier.mkv>` (vidéo),
  `--frames=N` (clip raccourci), `--still-frame=N --still=<png>` (image fixe), `--profile`
  (temps CPU/GPU par vue).
- **Annotations** : chaque `Hazard` porte une boîte cliquable. À chaque image,
  `AnnotationRecorder` la projette dans chaque vue, teste le masquage par des rayons (bâtiments
  et voitures stationnées ont des collisions), retourne l'image pour les rétroviseurs et ne garde
  que les images clés nécessaires (écart d'interpolation > 0,003).

## Rendu

```
godot --path production --fixed-fps 30 res://scenarios/urban_crossroads_pedestrian.tscn \
      -- --seed=42 --out=<dossier> --movie=<dossier>/<id>.mkv
```

Chaque image rendue part directement dans le tube de FFmpeg (`tools/ffmpeg_pipe.gd`, variable
`PR_FFMPEG`) : master sans perte FFV1 et aperçu H.264 (NVENC si le pilote NVIDIA le permet).
Plus de PNG intermédiaires : ils prenaient 80 % du temps (ADR-020). `--write-movie` (PNG Movie
Maker) reste possible. `npm run render:clip` fait tout cela et valide le JSON ;
`npm run render:batch` rend un lot ; `npm run bench:render` compare les modes.

## Scénario J1 : `urban_crossroads_pedestrian`

Carrefour en zone 30, urbain (`Crossroads`) ou résidentiel (`ResidentialCrossroads` : rue
étroite sans marquage, priorité de droite, maisons à toit en pente et jardinets). Un piéton
marche sur le trottoir de gauche, se tourne vers la route (premier indice, début de fenêtre) et
traverse, au passage en ville, hors passage en résidentiel ; la voiture freine après la fin de
la fenêtre et le laisse passer. Un piège attend, immobile et dos à la route, sur le trottoir de
droite. La graine fait varier les horaires, les vitesses, la place du piège, les maisons, le
mobilier, les arbres, la densité de stationnement, les voitures, leurs peintures et le ciel.
Arbres et arbustes ne sont jamais placés là où les piétons doivent rester visibles
(`Crossroads.keep_clear`).

**Voitures** : `CarLibrary` reconstruit les 10 voitures du pack générique (Comrade1280,
CC-BY 4.0) à partir de `production/assets/sketchfab/generic_passenger_car_pack/` : chaque
carrosserie est regroupée avec ses roues, orientée par son emprise minimale et remise dans notre
convention (pare-chocs avant à l'origine, vers -Z). Le sens avant/arrière de chaque modèle est
fixé à la main dans `CarLibrary.MODELS`, vérifié avec la planche :
`godot --path production --script res://tests/car_sheet.gd -- --out=<png>`. Les modèles sont
tirés au hasard avec des poids adaptés à une ville belge, puis repeints (`car_paint.gdshader`,
palette pondérée `Car.PAINTS`) ; planche d'une teinte : `car_sheet.gd -- --out=<png>
--paint=noir`. Sans le pack, les voitures redeviennent des formes provisoires.

Les **piétons** sont encore des formes provisoires (voir
[docs/assets-candidates.md](../docs/assets-candidates.md)).
