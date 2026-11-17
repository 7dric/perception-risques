// Renders one still image of a scenario at a given frame (reference look, ADR-012).
//   npm run render:still -- --frame=300 --time=dusk --weather=rain
// Output: content/stills/<clip id>-f<frame>.png
import { mkdirSync } from "node:fs";
import { join } from "node:path";
import { DEFAULT_SCENARIO, ROOT, clipId, godot, parseArgs, scenarioArgs, winPath } from "./lib/render.mjs";

const opts = parseArgs(process.argv.slice(2), {
  scenario: DEFAULT_SCENARIO, seed: "42", time: "day", weather: "clear", environment: "urban",
  quality: "reference", frame: "300",
});
const dir = join(ROOT, "content/stills");
mkdirSync(dir, { recursive: true });
const png = join(dir, `${clipId(opts)}-f${opts.frame}${opts.quality === "reference" ? "" : `-${opts.quality}`}.png`);
try {
  const out = godot([
    `res://scenarios/${opts.scenario}.tscn`, "--",
    ...scenarioArgs(opts), `--still-frame=${opts.frame}`, `--still=${winPath(png)}`,
  ]);
  const line = out.split("\n").find((l) => l.startsWith("STILL|"));
  if (!line?.endsWith("|OK")) throw new Error("Image non enregistrée");
  const sky = out.split("\n").find((l) => l.startsWith("SKY|"));
  if (sky) console.log(`Ciel : ${sky.slice(4)}`);
  console.log(png);
} catch (e) {
  console.error(e.message);
  process.exit(1);
}
