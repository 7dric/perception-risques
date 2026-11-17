// Downloads the CC0 assets listed in production/assets/assets.json (Poly Haven API),
// checks their MD5, and refreshes the generated part of docs/ASSETS.md.
// Run on Windows (the WSL network corrupts large downloads):  npm run fetch-assets
// Options: --dry-run (list only), --docs-only (only rewrite docs/ASSETS.md).
import { createHash } from "node:crypto";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const MANIFEST = join(ROOT, "production/assets/assets.json");
const OUT = join(ROOT, "production/assets/polyhaven");
const DOCS = join(ROOT, "docs/ASSETS.md");
const API = "https://api.polyhaven.com";
const args = new Set(process.argv.slice(2));

/** Texture maps used by Godot's ORM material: albedo, OpenGL normal, AO/roughness/metal packed. */
const TEXTURE_MAPS = { Diffuse: "diff", nor_gl: "nor_gl", arm: "arm" };

async function getJson(url) {
  const res = await fetch(url, { headers: { "User-Agent": "perception-risques-asset-fetcher" } });
  if (!res.ok) throw new Error(`${url}: HTTP ${res.status}`);
  return res.json();
}

const md5 = (buf) => createHash("md5").update(buf).digest("hex");

async function download(url, dest, expectedMd5) {
  if (existsSync(dest) && (!expectedMd5 || md5(readFileSync(dest)) === expectedMd5)) return false;
  if (args.has("--dry-run")) { console.log(`  [dry-run] ${url}`); return false; }
  mkdirSync(dirname(dest), { recursive: true });
  for (let attempt = 1; ; attempt++) {
    const res = await fetch(url);
    if (!res.ok) throw new Error(`${url}: HTTP ${res.status}`);
    const buf = Buffer.from(await res.arrayBuffer());
    if (!expectedMd5 || md5(buf) === expectedMd5) { writeFileSync(dest, buf); return true; }
    if (attempt >= 3) throw new Error(`${url}: MD5 incorrect après ${attempt} essais`);
  }
}

/** Returns the list of {url, md5, path} to download for one asset. */
function filesFor(kind, id, files, resolution) {
  if (kind === "hdris") {
    const f = files.hdri[resolution].hdr;
    return [{ url: f.url, md5: f.md5, path: `${id}_${resolution}.hdr` }];
  }
  if (kind === "textures") {
    return Object.entries(TEXTURE_MAPS).map(([key, suffix]) => {
      const f = files[key][resolution].jpg;
      return { url: f.url, md5: f.md5, path: `${id}_${suffix}_${resolution}.jpg` };
    });
  }
  const g = files.gltf[resolution].gltf;
  return [
    { url: g.url, md5: g.md5, path: `${id}.gltf` },
    ...Object.entries(g.include ?? {}).map(([path, f]) => ({ url: f.url, md5: f.md5, path })),
  ];
}

const KIND_LABEL = { textures: "Texture", hdris: "HDRI", models: "Modèle" };

async function main() {
  const manifest = JSON.parse(readFileSync(MANIFEST, "utf8"));
  const ph = manifest.polyhaven;
  const rows = [];
  for (const kind of ["textures", "hdris", "models"]) {
    for (const entry of ph[kind]) {
      const resolution = entry.resolution ?? ph.resolution;
      const info = await getJson(`${API}/info/${entry.id}`);
      const authors = Object.keys(info.authors ?? {}).join(", ");
      rows.push(`| \`production/assets/polyhaven/${entry.id}/\` | https://polyhaven.com/a/${entry.id} | ${authors} | CC0 | ${KIND_LABEL[kind]} ${resolution} — ${entry.use} | ${entry.added ?? ph.added} | Non |`);
      if (args.has("--docs-only")) continue;
      const files = await getJson(`${API}/files/${entry.id}`);
      let fetched = 0;
      for (const f of filesFor(kind, entry.id, files, resolution)) {
        if (await download(f.url, join(OUT, entry.id, f.path), f.md5)) fetched++;
      }
      console.log(`${fetched ? "↓" : "="} ${entry.id}${fetched ? ` (${fetched} fichier(s))` : ""}`);
    }
  }
  writeDocs(rows);
}

function writeDocs(rows) {
  const begin = "<!-- fetch-assets:begin -->";
  const end = "<!-- fetch-assets:end -->";
  const doc = readFileSync(DOCS, "utf8");
  const i = doc.indexOf(begin);
  const j = doc.indexOf(end);
  if (i < 0 || j < 0) throw new Error(`Marqueurs ${begin} / ${end} absents de docs/ASSETS.md`);
  const block = `${begin}\n${rows.join("\n")}\n${end}`;
  writeFileSync(DOCS, doc.slice(0, i) + block + doc.slice(j + end.length));
  console.log(`docs/ASSETS.md : ${rows.length} ligne(s) Poly Haven`);
}

main().catch((e) => { console.error(e.message); process.exit(1); });
