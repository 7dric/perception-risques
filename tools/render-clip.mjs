// Renders one clip: Godot Movie Maker frames + annotation JSON, then a VP9 WebM for viewing
// (the final AV1 encoding comes in J3), then validates the JSON against the schema.
//   npm run render:clip -- --seed=42 --time=dusk --weather=rain
// Output: content/raw/<clip id>/ (frame*.png, <clip id>.json, <clip id>.vp9.webm)
import { spawnSync } from "node:child_process";
import { existsSync, mkdirSync, rmSync } from "node:fs";
import { join } from "node:path";
import { DEFAULT_SCENARIO, ROOT, clipId, ffmpeg, framesIn, godot, parseArgs, scenarioArgs, winPath } from "./lib/render.mjs";

export function renderClip(opts) {
  const id = clipId(opts);
  const out = opts.out || join(ROOT, "content/raw", id);
  rmSync(out, { recursive: true, force: true });
  mkdirSync(out, { recursive: true });
  const started = Date.now();
  godot([
    "--write-movie", winPath(join(out, "frame.png")),
    "--fixed-fps", "30",
    `res://scenarios/${opts.scenario}.tscn`,
    "--", ...scenarioArgs(opts), `--out=${winPath(out)}`,
  ]);
  const frames = framesIn(out);
  const json = join(out, `${id}.json`);
  if (!existsSync(json)) throw new Error(`Annotations absentes : ${json}`);
  const seconds = (Date.now() - started) / 1000;
  console.log(`${id} : ${frames.length} images en ${seconds.toFixed(0)} s (${(seconds / frames.length).toFixed(2)} s/image)`);
  return { id, out, frames, json };
}

export function encodePreview(clip) {
  const webm = join(clip.out, `${clip.id}.vp9.webm`);
  ffmpeg([
    "-framerate", "30", "-i", winPath(join(clip.out, "frame%08d.png")),
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
    scenario: DEFAULT_SCENARIO, seed: "42", time: "day", weather: "clear", out: "", "keep-frames": false,
  });
  try {
    const clip = renderClip(opts);
    validate(clip.json);
    console.log(`Vidéo : ${encodePreview(clip)}`);
    if (!opts["keep-frames"]) for (const f of clip.frames) rmSync(join(clip.out, f));
  } catch (e) {
    console.error(e.message);
    process.exit(1);
  }
}
