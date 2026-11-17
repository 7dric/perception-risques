import fr from "./fr.json";

export type Lang = "fr" | "nl" | "de" | "en";
type Messages = Record<string, string>;

const catalogs: Partial<Record<Lang, Messages>> = { fr };
let current: Lang = "fr";

export function setLang(lang: Lang): void {
  current = lang;
}

/** Returns the text for a key, falling back to French, then to the key itself. */
export function t(key: string): string {
  return catalogs[current]?.[key] ?? catalogs.fr?.[key] ?? key;
}
