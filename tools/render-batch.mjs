// Renders several clips (seeds × times × weathers × environments), --jobs Godot instances at a
// time. First step towards the render-all of J3.
//   npm run render:batch -- --seeds=1-6 --times=day,dusk --weathers=clear,rain
// One instance by default: on the RTX 3050 6 GB, two instances were 3 times slower than one
// (GPU-bound render, video memory full; measured 2026-11-17, ADR-020).
// Each clip goes to content/raw/<clip id>/ (see render-clip.mjs). Prints the throughput.
import { spawn } from "node:child_process";
import { join } from "node:path";
import { DEFAULT_SCENARIO, ROOT, parseArgs } from "./lib/render.mjs";

const opts = parseArgs(process.argv.slice(2), {
  scenario: DEFAULT_SCENARIO, seeds: "42", times: "day", weathers: "clear", environments: "urban",
  quality: "reference", frames: "", jobs: "1", preview: "yes",
});

/** "1-3,7" -> [1, 2, 3, 7] */
const range = (s) => s.split(",").flatMap((p) => {
  const [a, b] = p.split("-").map(Number);
  return b === undefined ? [a] : Array.from({ length: b - a + 1 }, (_, i) => a + i);
});
const list = (s) => s.split(",").filter(Boolean);

const queue = [];
for (const environment of list(opts.environments))
  for (const time of list(opts.times))
    for (const weather of list(opts.weathers))
      for (const seed of range(opts.seeds))
        queue.push({ seed, time, weather, environment });

function renderOne(clip) {
  const args = [join(ROOT, "tools/render-clip.mjs"), `--scenario=${opts.scenario}`, `--seed=${clip.seed}`,
    `--time=${clip.time}`, `--weather=${clip.weather}`, `--environment=${clip.environment}`, `--quality=${opts.quality}`];
  if (opts.frames) args.push(`--frames=${opts.frames}`);
  if (opts.preview === "no") args.push("--no-preview");
  return new Promise((resolve) => {
    const child = spawn(process.execPath, args, { stdio: ["ignore", "pipe", "pipe"] });
    let log = "";
    child.stdout.on("data", (d) => { log += d; });
    child.stderr.on("data", (d) => { log += d; });
    child.on("close", (code) => {
      const summary = log.split("\n").find((l) => / images en /.test(l)) ?? "";
      console.log(`${code === 0 ? "✔" : "✘"} ${summary || JSON.stringify(clip)}`);
      if (code !== 0) console.log(log.split("\n").slice(-15).join("\n"));
      resolve(code === 0);
    });
  });
}

const total = queue.length;
const started = Date.now();
let failed = 0;
const workers = Array.from({ length: Math.max(1, Number(opts.jobs)) }, async () => {
  while (queue.length) if (!(await renderOne(queue.shift()))) failed += 1;
});
await Promise.all(workers);
const seconds = (Date.now() - started) / 1000;
console.log(`${total} clip(s) en ${seconds.toFixed(0)} s avec ${opts.jobs} instance(s) : ${(seconds / total).toFixed(0)} s/clip, ${failed} échec(s)`);
process.exit(failed ? 1 : 0);
