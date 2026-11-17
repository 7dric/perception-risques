# production/ — projet Godot 4

Outil interne qui joue les scénarios 3D et produit les vidéos et les annotations.
Le projet Godot 4.7 (Forward+, 1920×1080, 30 pas de physique par seconde) est créé ; les
scénarios arrivent au jalon J1. `tools/gpu_info.gd` affiche le pilote et le GPU utilisés.

Organisation prévue :

```
production/
  project.godot
  cockpit/      caméra pare-brise, rétroviseurs (SubViewport), compteur, clignotants
  actors/       piétons, cyclistes, véhicules et leurs comportements
  hazards/      nœud Hazard, AnnotationRecorder
  roads/        modules de route
  scenarios/    une scène par scénario
  assets/       assets tiers (chacun déclaré dans docs/ASSETS.md)
```

Rendu prévu :

```
godot --path production --write-movie ../content/raw/<id>/frame.png --fixed-fps 30 res://scenarios/<id>.tscn
```
