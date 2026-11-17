import { expect, test } from "@playwright/test";

test("the home page shows the title", async ({ page }) => {
  await page.goto("/");
  await expect(page.locator("#app")).toContainText("Perception des risques");
});
