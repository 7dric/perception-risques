// Runs the GDScript unit tests of the production project (no rendering).
//   npm run test:godot
import { godot } from "./lib/render.mjs";

try {
  const out = godot(["--headless", "--script", "res://tests/test_annotation.gd"]);
  const line = out.split("\n").find((l) => l.startsWith("TESTS|")) ?? "TESTS|KO|résultat absent";
  console.log(line);
  process.exit(line.startsWith("TESTS|OK") ? 0 : 1);
} catch (e) {
  console.error(e.message);
  process.exit(1);
}
