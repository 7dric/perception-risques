# web/ — lecteur élève

Site statique TypeScript + Vite, créé au jalon J2. Organisation prévue :

```
web/
  src/
    player/     lecture vidéo, synchro image par image, capture des clics
    scoring/    moteur de score pur (sans DOM), testé avec vitest
    review/     écran de correction (replay, ralenti, polygones, frise)
    i18n/       clés de traduction (fr d'abord)
  rules/
    official-be.json   paramètres du barème (voir docs/exam-rules.md)
  tests/        tests playwright
```
