// Validates every annotation file against schema/clip.schema.json.
// Usage: node tools/validate-schema.mjs [file.json ...]   (default: schema/examples/*.json)
import { readFileSync, readdirSync } from "node:fs";
import { join, resolve } from "node:path";
import Ajv2020 from "ajv/dist/2020.js";

const root = resolve(import.meta.dirname, "..");
const schema = JSON.parse(readFileSync(join(root, "schema/clip.schema.json"), "utf8"));
const validate = new Ajv2020({ allErrors: true, strict: true }).compile(schema);

const examplesDir = join(root, "schema/examples");
const files = process.argv.length > 2
  ? process.argv.slice(2).map((f) => resolve(f))
  : readdirSync(examplesDir).filter((f) => f.endsWith(".json")).map((f) => join(examplesDir, f));

let failed = 0;
for (const file of files) {
  const data = JSON.parse(readFileSync(file, "utf8"));
  if (validate(data)) {
    console.log(`OK      ${file}`);
  } else {
    failed++;
    console.log(`INVALID ${file}`);
    for (const err of validate.errors ?? []) console.log(`  ${err.instancePath || "/"} ${err.message}`);
  }
}
process.exit(failed ? 1 : 0);
