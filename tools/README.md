# tools/ — scripts de production

Prévus au jalon J3 :

| Script | Rôle |
|---|---|
| `render-all` | Rend tous les scénarios avec Godot sans interface |
| `encode` | Encode les images en WebM AV1 (SVT-AV1) et VP9 (libvpx) avec FFmpeg |
| `validate` | Valide les JSON contre `schema/clip.schema.json` et produit une vidéo de contrôle avec les polygones dessinés |
| `manifest` | Génère `content/manifest.json` |

Validation du schéma dès maintenant :

```
npx ajv-cli validate --spec=draft2020 -s schema/clip.schema.json -d "schema/examples/*.json"
```
