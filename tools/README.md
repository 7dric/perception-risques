# tools/ — scripts de production

Prévus au jalon J3 :

| Script | Rôle |
|---|---|
| `render-all` | Rend tous les scénarios avec Godot sans interface |
| `encode` | Encode les images en WebM AV1 (SVT-AV1) et VP9 (libvpx) avec FFmpeg |
| `validate` | Valide les JSON contre `schema/clip.schema.json` et produit une vidéo de contrôle avec les polygones dessinés |
| `manifest` | Génère `content/manifest.json` |

Déjà disponibles :

| Script | Rôle |
|---|---|
| `check-env.mjs` | Vérifie l'environnement (`npm run check-env`) |
| `validate-schema.mjs` | Valide les JSON contre le schéma (`npm run validate:schema [fichiers]`) |
| `winrun.cmd` | Lance une commande sous Windows depuis WSL (voir docs/SETUP.md) |
