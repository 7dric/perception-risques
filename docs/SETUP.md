# Environnement de travail

Tout l'outillage tourne **sous Windows** (ADR-016) : Godot a besoin du GPU, et le dépôt est sur
le disque `C:`. Les commandes ci-dessous se tapent dans PowerShell, à la racine du dépôt.

## Installations

| Outil | Version testée | Installation | Rôle |
|---|---|---|---|
| Git | — | `winget install --id Git.Git -e` | Versionnement |
| Godot 4 (standard, pas Mono) | 4.7.2 | `winget install --id GodotEngine.GodotEngine -e` | Production 3D (J1) |
| FFmpeg, build **complet** | 9.0.2 | `winget install --id Gyan.FFmpeg -e` | Encodage AV1 (SVT-AV1) et VP9 (J3) |
| Node.js LTS | 26.13.1 (minimum 24) | `winget install --id OpenJS.NodeJS.LTS -e` | Lecteur web, outils, validation |

La build *Essentials* de FFmpeg ne suffit pas : elle n'a pas `libsvtav1`.

Ensuite, à la racine du dépôt :

```powershell
npm install                                   # dépendances (racine + web/)
npx -w web playwright install chromium        # navigateur des tests de bout en bout
npm run check-env                             # diagnostic complet
```

`check-env` vérifie Node, Godot, le rendu Godot en **Vulkan sur le GPU** (Forward+), FFmpeg avec
ses encodeurs et les dépendances npm. Godot et FFmpeg sont cherchés dans le `PATH`, puis dans le
dossier des paquets winget. Pour forcer un chemin : variables d'environnement `GODOT_BIN` et
`FFMPEG_BIN` (prendre l'exécutable `..._console.exe` de Godot, qui écrit dans le terminal).

## Commandes courantes

| Commande | Effet |
|---|---|
| `npm run dev` | Lecteur web en local sur <http://localhost:5173> |
| `npm test` | Validation des annotations + tests unitaires (Vitest) |
| `npm run validate:schema [fichiers]` | Valide des JSON contre `schema/clip.schema.json` (par défaut `schema/examples/`) |
| `npm run build -w web` | Vérification des types + build de production dans `web/dist/` |
| `npm run test:e2e -w web` | Tests de bout en bout (Playwright, Chromium) |
| `npm run check-env` | Diagnostic de l'environnement |
| `npm run fetch-assets` | Télécharge les assets CC0 de `production/assets/assets.json` (Poly Haven) et met à jour `docs/ASSETS.md` |
| `npm run render:still -- --frame=300 [--seed= --time= --weather=]` | Image fixe d'un scénario dans `content/stills/` |
| `npm run render:clip -- --seed=42 [--time= --weather= --keep-frames]` | Clip complet : images, annotations JSON validées, aperçu WebM VP9 dans `content/raw/<id>/` |
| `npm run check:determinism -- --frames=60` | Même graine = mêmes images et annotations ; deux graines = deux clips |
| `npm run test:godot` | Tests unitaires GDScript (annotations, trajectoires) |

Après `fetch-assets`, importer les assets une fois dans Godot :
`godot --headless --path production --import`.

Moments du jour : `day`, `dawn`, `dusk`, `night`. Météo : `clear`, `overcast`, `rain`, `fog`,
`low_sun`.

Ouvrir le projet Godot : lancer Godot, « Importer », choisir `production/project.godot`.

## Depuis WSL

Le réseau de WSL (mode `mirrored`) corrompt les gros téléchargements HTTPS (`ERR_SSL_*`,
erreur curl 56) : `npm install` y échoue. Les commandes passent donc par Windows avec un
lanceur qui ajoute Node au `PATH` :

```bash
cmd.exe /c tools\\winrun.cmd npm test
```

Ne pas lancer `npm install` depuis WSL : les `node_modules` contiendraient des binaires Linux
(Vite, Rolldown) inutilisables sous Windows.

## PC de référence

AMD Ryzen 7 7840HS, NVIDIA GeForce RTX 3050 6 Go (portable), Windows + WSL2.
Godot rend sur la RTX 3050 en Vulkan 1.3.
