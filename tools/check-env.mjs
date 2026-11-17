// Checks that the tools needed by the project are installed and usable.
// Godot and FFmpeg run on Windows (GPU access); this script works from WSL or Windows.
// Override the lookup with the GODOT_BIN and FFMPEG_BIN environment variables.
import { existsSync } from "node:fs";
import { findFfmpeg, findGodot, run } from "./lib/bins.mjs";

const checks = [
  {
    name: "Node.js >= 24",
    test: () => Number(process.versions.node.split(".")[0]) >= 24 ? `v${process.versions.node}` : null,
  },
  {
    name: "Godot 4",
    test: () => {
      const bin = findGodot();
      const v = bin && run(bin, ["--version"]);
      return v && v.trim().startsWith("4.") ? `${v.trim().split("\n").pop()}  (${bin})` : null;
    },
    hint: "winget install --id GodotEngine.GodotEngine -e   (puis GODOT_BIN si introuvable)",
  },
  {
    name: "Godot rend sur GPU en Vulkan (Forward+)",
    test: () => {
      const bin = findGodot();
      const out = bin && run(bin, ["--path", "production", "--script", "res://tools/gpu_info.gd"]);
      const line = out?.split("\n").find((l) => l.startsWith("GPU_INFO|"));
      if (!line) return null;
      const [, driver, gpu, method] = line.trim().split("|");
      return driver === "vulkan" && method === "forward_plus" ? gpu : null;
    },
    hint: "mettre à jour le pilote graphique ; sur PC portable, forcer le GPU dédié pour Godot",
  },
  {
    name: "FFmpeg avec SVT-AV1 et VP9",
    test: () => {
      const bin = findFfmpeg();
      const enc = bin && run(bin, ["-hide_banner", "-encoders"]);
      if (!enc) return null;
      const missing = ["libsvtav1", "libvpx-vp9"].filter((e) => !enc.includes(e));
      return missing.length ? null : bin;
    },
    hint: "winget install --id Gyan.FFmpeg -e   (build complet, pas Essentials)",
  },
  {
    name: "Dépendances npm installées",
    test: () => existsSync("node_modules/vite") || existsSync("web/node_modules/vite") ? "ok" : null,
    hint: "npm install",
  },
];

let ok = true;
for (const c of checks) {
  const result = c.test();
  console.log(`${result ? "✔" : "✘"} ${c.name}${result ? ` — ${result}` : ""}`);
  if (!result) {
    ok = false;
    if (c.hint) console.log(`    → ${c.hint}`);
  }
}
process.exit(ok ? 0 : 1);
