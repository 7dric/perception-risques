# production/ — projet Godot 4

Outil interne qui joue les scénarios 3D et produit les vidéos et les annotations.
Le projet Godot sera créé au jalon J1. Organisation prévue :

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
