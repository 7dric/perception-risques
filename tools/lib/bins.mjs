// Locates the Windows tools used by the project (Godot, FFmpeg) and runs them.
// Godot and FFmpeg run on Windows (GPU access); this works from WSL or Windows.
// Override the lookup with the GODOT_BIN and FFMPEG_BIN environment variables.
import { execFileSync } from "node:child_process";
import { existsSync, readdirSync } from "node:fs";
import { join } from "node:path";

export const isWsl = process.platform === "linux" && existsSync("/mnt/c/Windows");

export function run(bin, args) {
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
