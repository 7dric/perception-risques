// Shared helpers for the render scripts: argument parsing, running Godot and FFmpeg.
// Godot and FFmpeg are Windows programs (ADR-016): paths passed to them are converted with
// `wslpath -w` when these scripts run from WSL.
import { execFileSync, spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { readdirSync, readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { findFfmpeg, findGodot, isWsl } from "./bins.mjs";

export const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "../..");
export const DEFAULT_SCENARIO = "urban_crossroads_pedestrian";

/** Parses --key=value options; returns defaults merged with the given values. */
export function parseArgs(argv, defaults) {
  const out = { ...defaults };
  for (const arg of argv) {
    const m = /^--([a-z-]+)(?:=(.*))?$/.exec(arg);
    if (!m || !(m[1] in defaults)) {
      console.error(`Option inconnue : ${arg}\nOptions : ${Object.keys(defaults).map((k) => `--${k}`).join(" ")}`);
      process.exit(2);
    }
    out[m[1]] = m[2] ?? true;
  }
  return out;
}

/** Path as seen by Windows programs. */
export function winPath(p) {
  return isWsl ? execFileSync("wslpath", ["-w", p], { encoding: "utf8" }).trim() : p;
}

/** Runs Godot on the production project; streams its output and returns it. */
export function godot(args) {
  const bin = findGodot();
  if (!bin) throw new Error("Godot introuvable (npm run check-env)");
  const res = spawnSync(bin, ["--path", winPath(join(ROOT, "production")), ...args], { encoding: "utf8", maxBuffer: 1 << 28 });
  const output = `${res.stdout ?? ""}${res.stderr ?? ""}`.replace(/\r/g, "");
  const errors = output.split("\n").filter((l) => /SCRIPT ERROR|^ERROR:/.test(l) && !/resources still in use|ObjectDB instances/.test(l));
  if (res.status !== 0 || errors.length) {
    console.error(output.split("\n").slice(-40).join("\n"));
    throw new Error(`Godot a échoué (code ${res.status}, ${errors.length} erreur(s))`);
  }
  return output;
}

export function ffmpeg(args) {
  const bin = findFfmpeg();
  if (!bin) throw new Error("FFmpeg introuvable (npm run check-env)");
  const res = spawnSync(bin, ["-hide_banner", "-loglevel", "error", "-y", ...args], { encoding: "utf8" });
  if (res.status !== 0) throw new Error(`FFmpeg a échoué : ${res.stderr}`);
  return res.stdout;
}

/** Scenario arguments passed to Godot after "--". */
export function scenarioArgs(opts) {
  const args = [`--seed=${opts.seed}`, `--time=${opts.time}`, `--weather=${opts.weather}`];
  if (opts.frames) args.push(`--frames=${opts.frames}`);
  return args;
}

export function clipId(opts) {
  return `${opts.scenario}-s${opts.seed}-${opts.time}-${opts.weather}`.replaceAll("_", "-");
}

/** Sorted list of the frame PNGs written by Movie Maker in a folder. */
export function framesIn(dir) {
  return readdirSync(dir).filter((f) => /^frame\d+\.png$/.test(f)).sort();
}

export function md5File(path) {
  return createHash("md5").update(readFileSync(path)).digest("hex");
}
