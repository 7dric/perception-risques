# Analyse de la concurrence

Pages lues le 17/11/2026 :
- MaTheorie : <https://matheorie.be/perception-des-risques>
- TheoRoute : <https://theoroute.com/test-perception-risques>

## Ce que proposent les deux concurrents

| | MaTheorie | TheoRoute |
|---|---|---|
| Rendu | 3D, une « rue » générique | 3D, 50 films dans de vraies rues belges recréées à partir d'OpenStreetMap (environ 30 villes) |
| Volume | 1 examen gratuit, puis 8 examens de 5 vidéos | 50 films, ajouts réguliers (« accès anticipé ») |
| Écran | Vue conducteur avec rétroviseurs | Vue avant, 3 rétroviseurs, compteur, clignotants |
| Format | 5 vidéos, 10 risques, 10 clics, 6/10 | Identique + mode flamand (questions après le film) |
| Correction | Rien d'indiqué sur la page | Replay au ralenti, danger encadré, pièges signalés, clics de l'élève |
| Pièges | Non mentionnés | Oui, dans chaque film |
| Plateforme | Web (test gratuit), app iPhone/Android (contenu payant) | Web |
| Prix | 6,99 € par semaine | 3,99 € / 30 jours (lancement), puis 7,99 € ; paiement unique |
| Langues | Français | Français, néerlandais ; offre dyslexie |

## Ce qui ne nous démarquera pas

Fonctions déjà présentes chez TheoRoute, donc indispensables mais pas distinctives :
3D, écran identique à l'examen, format 5 films / 10 clics, correction au ralenti, pièges,
mode flamand « questions après le film ».

## Nos différenciateurs retenus

| # | Différenciateur | Ce que ça demande | Jalon |
|---|---|---|---|
| D1 | **Volume quasi illimité** : scénarios générés et variés automatiquement, examen différent à chaque fois, impossible à apprendre par cœur | Générateur de scénarios, variations par graine aléatoire | J4 |
| D2 | **Entraînement adaptatif** : erreurs suivies par type de danger, séries ciblées sur les faiblesses | Types et étiquettes sur chaque danger, historique des réponses | J6 |
| D3 | **Note de précision** : délai de réaction par rapport au moment idéal, en plus du barème officiel binaire | `idealFrame` dans les annotations, affichage en correction | J2 |
| D4 | **Exercices courts** : clips de 10 s à un seul danger, « pause : que va-t-il se passer ? » | Format de clip court, mode d'exercice dans le lecteur | J5 |
| D5 | **Conditions variées** : nuit, pluie, brouillard, soleil rasant, campagne, voie rapide, travaux | Lumière, météo et décors paramétrables dans Godot | J4 |

Non retenus pour l'instant : offre auto-écoles, allemand et anglais, modèle de prix (à revoir plus tard).
