import { t } from "./i18n";

const app = document.querySelector<HTMLElement>("#app");
if (app) {
  app.textContent = t("app.title");
}
