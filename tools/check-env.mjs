// Checks that the tools needed by the project are installed and usable.
// Godot and FFmpeg run on Windows (GPU access); this script works from WSL or Windows.
// Override the lookup with the GODOT_BIN and FFMPEG_BIN environment variables.
import { execFileSync } from "node:child_process";
import { existsSync, readdirSync } from "node:fs";
import { join } from "node:path";

const isWsl = process.platform === "linux" && existsSync("/mnt/c/Windows");

function run(bin, args) {
  try {
    return execFileSync(bin, args, { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] }).replace(/\r/g, "");
  } catch {
    return null;
  }
}

function onPath(names) {
  for (const name of names) {
    const found = run(process.platform === "win32" ? "where" : "which", [name]);
    if (found) return found.split("\n")[0].trim();
  }
  return null;
}

/** Looks inside the winget package folder of the current Windows user. */
function inWinget(packagePrefix, pattern) {
  const users = isWsl ? "/mnt/c/Users" : process.platform === "win32" ? "C:\\Users" : null;
  if (!users) return null;
  for (const user of readdirSync(users)) {
    const pkgs = join(users, user, "AppData/Local/Microsoft/WinGet/Packages");
    if (!existsSync(pkgs)) continue;
    for (const pkg of readdirSync(pkgs).filter((p) => p.startsWith(packagePrefix))) {
      const hit = walk(join(pkgs, pkg), pattern, 3);
      if (hit) return hit;
    }
  }
  return null;
}

function walk(dir, pattern, depth) {
  let entries;
  try { entries = readdirSync(dir, { withFileTypes: true }); } catch { return null; }
  for (const e of entries) if (e.isFile() && pattern.test(e.name)) return join(dir, e.name);
  if (depth > 0) for (const e of entries) if (e.isDirectory()) {
    const hit = walk(join(dir, e.name), pattern, depth - 1);
    if (hit) return hit;
  }
  return null;
}

export function findGodot() {
  return process.env.GODOT_BIN
    ?? onPath(["godot", "godot4", "godot.exe"])
    ?? inWinget("GodotEngine.GodotEngine_", /^Godot_v4.*_win64_console\.exe$/);
}

export function findFfmpeg() {
  return process.env.FFMPEG_BIN
    ?? onPath(["ffmpeg", "ffmpeg.exe"])
    ?? inWinget("Gyan.FFmpeg_", /^ffmpeg\.exe$/);
}

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
