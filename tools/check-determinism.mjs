// Checks the J1 rule "same seed = same images, two seeds = two different clips".
// Renders seed A twice and seed B once (shortened clips, lossless FFV1 masters), then compares:
//  - annotations: A/A byte-identical, A/B different;
//  - images: A/A identical (MD5 of each decoded frame), or else PSNR >= MIN_PSNR on every frame
//    (GPU effects such as SDFGI may not be bit-exact, ADR-018); A/B clearly different.
//   npm run check:determinism -- --frames=60
import { readFileSync, rmSync } from "node:fs";
import { join } from "node:path";
import { renderClip } from "./render-clip.mjs";
import { DEFAULT_SCENARIO, ROOT, ffmpeg, frameMd5s, parseArgs, winPath } from "./lib/render.mjs";

const MIN_PSNR = 50;       // dB, same seed
const MAX_PSNR_OTHER = 35; // dB, different seeds (average)

const opts = parseArgs(process.argv.slice(2), {
  scenario: DEFAULT_SCENARIO, a: "42", b: "7", time: "day", weather: "clear", environment: "urban",
  quality: "reference", frames: "60", keep: false,
});
const base = join(ROOT, "content/determinism");
const render = (seed, run) => renderClip({ ...opts, seed, preview: false, out: join(base, `s${seed}-${run}`) });

/** Average and minimum PSNR between two videos (FFmpeg psnr filter). */
function psnr(videoA, videoB) {
  const log = join(base, "psnr.log");
  ffmpeg([
    "-i", winPath(videoA), "-i", winPath(videoB),
    "-lavfi", `psnr=stats_file='${winPath(log).replaceAll("\\", "/").replace(":", "\\:")}'`, "-f", "null", "-",
  ]);
  const values = readFileSync(log, "utf8").trim().split("\n")
    .map((l) => /psnr_avg:(\S+)/.exec(l)?.[1]).map((v) => (v === "inf" ? Infinity : Number(v)));
  const finite = values.filter(Number.isFinite);
  const avg = finite.length ? finite.reduce((s, v) => s + v, 0) / finite.length : Infinity;
  return { min: Math.min(...values), avg };
}

let ok = true;
const check = (cond, msg) => { console.log(`${cond ? "✔" : "✘"} ${msg}`); ok &&= cond; };

try {
  rmSync(base, { recursive: true, force: true });
  const a1 = render(opts.a, 1);
  const a2 = render(opts.a, 2);
  const b = render(opts.b, 1);

  check(readFileSync(a1.json, "utf8") === readFileSync(a2.json, "utf8"), `graine ${opts.a} : annotations identiques`);
  check(readFileSync(a1.json, "utf8") !== readFileSync(b.json, "utf8"), `graines ${opts.a} et ${opts.b} : annotations différentes`);
  const md5a1 = frameMd5s(a1.master);
  const md5a2 = frameMd5s(a2.master);
  check(md5a1.length === md5a2.length && md5a1.length === Number(opts.frames),
    `nombre d'images : ${md5a1.length} / ${md5a2.length} (attendu ${opts.frames})`);

  const identical = md5a1.filter((m, i) => m === md5a2[i]).length;
  if (identical === md5a1.length) {
    check(true, `graine ${opts.a} : ${identical}/${md5a1.length} images identiques au bit près`);
  } else {
    const p = psnr(a1.master, a2.master);
    check(p.min >= MIN_PSNR, `graine ${opts.a} : ${identical}/${md5a1.length} images identiques au bit près, PSNR minimal ${p.min.toFixed(1)} dB (seuil ${MIN_PSNR})`);
  }
  const other = psnr(a1.master, b.master);
  check(other.avg <= MAX_PSNR_OTHER, `graines ${opts.a} et ${opts.b} : images différentes (PSNR moyen ${other.avg.toFixed(1)} dB, seuil ${MAX_PSNR_OTHER})`);
  if (!opts.keep) rmSync(base, { recursive: true, force: true });
} catch (e) {
  console.error(e.message);
  ok = false;
}
process.exit(ok ? 0 : 1);
