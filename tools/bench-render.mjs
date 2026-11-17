// Measures the render speed (seconds per frame) of a scenario in several output modes, to see
// where the time goes (ADR-020).
//   npm run bench:render -- --frames=90 --modes=none,png,mkv
// Modes: none (render only, nothing written), png (Movie Maker PNG frames),
//        mkv (frames piped to FFmpeg: lossless master + NVENC preview, production/tools/ffmpeg_pipe.gd).
// Each run also prints Godot's own measures (--profile): CPU and GPU time per viewport.
import { mkdirSync, rmSync } from "node:fs";
import { join } from "node:path";
import { DEFAULT_SCENARIO, ROOT, godot, parseArgs, scenarioArgs, winPath } from "./lib/render.mjs";

const opts = parseArgs(process.argv.slice(2), {
  scenario: DEFAULT_SCENARIO, seed: "42", time: "day", weather: "clear", environment: "urban",
  quality: "reference", frames: "90", modes: "none,png,mkv", preview: "yes",
});
const base = join(ROOT, "content/bench");
const rows = [];

for (const mode of opts.modes.split(",")) {
  const out = join(base, mode);
  rmSync(out, { recursive: true, force: true });
  mkdirSync(out, { recursive: true });
  const movie = mode === "png" ? ["--write-movie", winPath(join(out, "frame.png"))] : [];
  const pipe = mode === "mkv" ? [`--movie=${winPath(join(out, "bench.mkv"))}`] : [];
  const started = Date.now();
  const log = godot([...movie, "--fixed-fps", "30", `res://scenarios/${opts.scenario}.tscn`,
    "--", ...scenarioArgs(opts), ...pipe, "--profile"], { preview: opts.preview !== "no" });
  const seconds = (Date.now() - started) / 1000;
  const profile = log.split("\n").find((l) => l.startsWith("PROFILE|")) ?? "";
  rows.push({ mode, seconds, perFrame: seconds / Number(opts.frames), profile });
  console.log(`${mode.padEnd(5)} ${seconds.toFixed(1)} s, ${(seconds / Number(opts.frames)).toFixed(3)} s/image (démarrage compris)\n      ${profile}`);
}
rmSync(base, { recursive: true, force: true });
