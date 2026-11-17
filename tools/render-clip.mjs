// Renders one clip and its annotation JSON, then validates the JSON against the schema.
//   npm run render:clip -- --seed=42 --time=dusk --weather=rain --environment=residential
// Output: content/raw/<clip id>/
//   <clip id>.mkv          lossless master (FFV1), frames piped from Godot to FFmpeg (ADR-020)
//   <clip id>.preview.mp4  H.264 preview (NVENC when the driver allows it, else libx264)
//   <clip id>.json         annotations
// Options: --vp9 also encodes a VP9 WebM from the master; --png renders PNG frames with Movie
// Maker instead (much slower: PNG encoding took 80 % of the time).
import { spawnSync } from "node:child_process";
import { existsSync, mkdirSync, rmSync } from "node:fs";
import { join } from "node:path";
import { DEFAULT_SCENARIO, ROOT, clipId, ffmpeg, frameMd5s, framesIn, godot, parseArgs, scenarioArgs, winPath } from "./lib/render.mjs";

export function renderClip(opts) {
  const id = clipId(opts);
  const out = opts.out || join(ROOT, "content/raw", id);
  rmSync(out, { recursive: true, force: true });
  mkdirSync(out, { recursive: true });
  const started = Date.now();
  const master = join(out, `${id}.mkv`);
  const movie = opts.png
    ? ["--write-movie", winPath(join(out, "frame.png")), "--fixed-fps", "30"]
    : ["--fixed-fps", "30"];
  godot([
    ...movie,
    `res://scenarios/${opts.scenario}.tscn`,
    "--", ...scenarioArgs(opts), `--out=${winPath(out)}`,
    ...(opts.png ? [] : [`--movie=${winPath(master)}`]),
  ], { preview: opts.preview !== false });
  const frames = opts.png ? framesIn(out) : [];
  const json = join(out, `${id}.json`);
  if (!existsSync(json)) throw new Error(`Annotations absentes : ${json}`);
  if (!opts.png && !existsSync(master)) throw new Error(`Vidéo absente : ${master}`);
  const count = opts.png ? frames.length : frameMd5s(master).length;
  const seconds = (Date.now() - started) / 1000;
  console.log(`${id} : ${count} images en ${seconds.toFixed(0)} s (${(seconds / count).toFixed(2)} s/image, démarrage compris)`);
  return { id, out, frames, json, master: opts.png ? null : master, count };
}

/** VP9 WebM from the master or from the PNG frames. */
export function encodeVp9(clip) {
  const webm = join(clip.out, `${clip.id}.vp9.webm`);
  const input = clip.master ? ["-i", winPath(clip.master)] : ["-framerate", "30", "-i", winPath(join(clip.out, "frame%08d.png"))];
  ffmpeg([
    ...input,
    "-c:v", "libvpx-vp9", "-b:v", "0", "-crf", "32", "-row-mt", "1", "-deadline", "good", "-cpu-used", "4",
    "-pix_fmt", "yuv420p", winPath(webm),
  ]);
  return webm;
}

export function validate(json) {
  const res = spawnSync(process.execPath, [join(ROOT, "tools/validate-schema.mjs"), json], { stdio: "inherit" });
  if (res.status !== 0) throw new Error("Annotations non conformes au schéma");
}

if (process.argv[1]?.endsWith("render-clip.mjs")) {
  const opts = parseArgs(process.argv.slice(2), {
    scenario: DEFAULT_SCENARIO, seed: "42", time: "day", weather: "clear", environment: "urban",
    quality: "reference", frames: "", out: "", png: false, vp9: false, "keep-frames": false, "no-preview": false,
  });
  opts.preview = !opts["no-preview"];
  try {
    const clip = renderClip(opts);
    validate(clip.json);
    if (clip.master) console.log(`Master : ${clip.master}\nAperçu : ${clip.master.replace(/\.mkv$/, ".preview.mp4")}`);
    if (opts.vp9 || opts.png) console.log(`Vidéo : ${encodeVp9(clip)}`);
    if (opts.png && !opts["keep-frames"]) for (const f of clip.frames) rmSync(join(clip.out, f));
  } catch (e) {
    console.error(e.message);
    process.exit(1);
  }
}
