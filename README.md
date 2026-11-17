# Perception des risques — entraîneur pour le permis belge

Logiciel d'entraînement au **test de perception des risques** du permis de conduire belge.

L'élève voit une scène de conduite depuis l'habitacle (pare-brise, trois rétroviseurs, compteur,
clignotants). Quand un danger apparaît, il doit cliquer dessus avant la fin d'un délai.

> Projet indépendant, **sans lien** avec les centres d'examen ni les autorités régionales.

## Principe

1. **Production** (interne, sur PC) : des scénarios 3D temps réel dans **Godot 4** sont rendus en
   **vidéos** et en **annotations JSON** qui décrivent où se trouve chaque danger, image par image.
2. **Lecteur** (public, site web) : un site statique **TypeScript + Vite** lit les vidéos, enregistre
   les clics, calcule le score avec le barème officiel et affiche une correction expliquée.

## Arborescence

| Dossier | Contenu |
|---|---|
| `docs/` | Feuille de route, architecture, décisions, licences, règles d'examen, catalogue des dangers |
| `schema/` | Format d'annotation des clips (contrat entre Godot et le web) |
| `production/` | Projet Godot (scénarios, acteurs, cockpit, enregistreur d'annotations) |
| `tools/` | Scripts de rendu en lot, d'encodage et de validation |
| `web/` | Lecteur élève (TypeScript + Vite) |
| `content/` | Sorties générées : vidéos et JSON (hors Git) |

## Documentation

- [Feuille de route](docs/ROADMAP.md)
- [Concurrence et différenciateurs](docs/benchmark.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Décisions (ADR)](docs/DECISIONS.md)
- [Licences](docs/LICENSES.md) et [registre des assets](docs/ASSETS.md)
- [Règles de l'examen officiel](docs/exam-rules.md)
- [Catalogue des dangers](docs/hazard-catalog.md)

## Licence

Tous droits réservés pour le moment (voir [docs/LICENSES.md](docs/LICENSES.md)).
