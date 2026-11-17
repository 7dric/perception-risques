import { describe, expect, it } from "vitest";
import { t } from "./index";

describe("i18n", () => {
  it("returns the French text for a known key", () => {
    expect(t("app.title")).toContain("Perception des risques");
  });

  it("returns the key itself when it is missing", () => {
    expect(t("missing.key")).toBe("missing.key");
  });
});
