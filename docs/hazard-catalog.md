# Catalogue des dangers

> **Statut : validé le 17/11/2026** (ADR-017, voir les [points validés](#points-validés) en fin de page).
> Une fois validé, ce catalogue fait foi pour la production (Godot), les annotations
> (`schema/clip.schema.json`) et l'entraînement adaptatif (D2).

Le `type` est la valeur écrite dans le champ `type` des annotations. Les identifiants sont en
anglais, en `snake_case`, et ne changent plus une fois des clips produits.

## 1. Définitions

**Danger** : un usager ou un objet qui **oblige le conducteur à adapter sa conduite** (lever le
pied, freiner, dévier, attendre) pour éviter un conflit. Le danger doit se concrétiser dans le
clip : si rien ne se passe, ce n'est pas un danger.

**Piège** (`decoys`, ADR-011) : un usager qui attire l'œil, ressemble à un danger, mais ne
demande aucune réaction. Un clic dessus est un clic perdu. Chaque piège a une explication.

**Fenêtre et moment idéal** (champs `window` et `idealFrame`) :

| Champ | Règle d'annotation |
|---|---|
| `window.startFrame` | Premier **indice objectif** que l'usager va croiser notre trajectoire : il quitte le bord du trottoir, ses roues tournent, son feu de recul s'allume, le ballon roule vers la route… Avant cet instant, un clic est perdu. |
| `idealFrame` | Moment où un conducteur attentif **signale** le danger : l'indice est net et l'usager visible. En général entre 0,3 et 1 s après `startFrame` (10 à 30 images). Sert à la note de précision (D3). |
| `window.endFrame` | Dernier moment où un **freinage normal** (pas d'urgence) évite encore le conflit, ou fin de la situation si elle arrive avant. Repère : environ 2 s avant le point de conflit. |

Durée de fenêtre visée : **3 à 5 s** (90 à 150 images à 30 i/s). Plus courte = trop dur, plus
longue = trop facile.

## 2. Règles de conception d'un clip

1. **Cliquable** : le danger est visible pendant toute sa fenêtre (masquage partiel toléré
   jusqu'à 50 %, jamais totalement caché). Taille minimale de la zone cliquable : 40 × 40 px en
   1080p (environ 0,02 × 0,04 en coordonnées normalisées). Une zone plus petite est agrandie.
2. **Au plus 3 dangers par clip**, 0 accepté. Deux dangers peuvent avoir des fenêtres qui se
   chevauchent, mais leurs zones cliquables ne se superposent jamais.
3. **Au moins un piège par clip**, deux au plus. Le piège est visible quand un danger proche est
   actif, ou il précède un danger du même genre (voir les « jumeaux » en section 6).
4. **Rétroviseurs** : un danger venant de l'arrière est annoté dans la vue du rétroviseur
   (`mirrorCenter`, `mirrorLeft`, `mirrorRight`). S'il passe ensuite dans le pare-brise, il a une
   seconde piste dans `windshield`.
5. **Déterminisme** : tous les mouvements sont scriptés (pas de physique libre, même pour un
   ballon), pour que même graine = mêmes images.
6. **Explication** : elle suit toujours le même plan en trois phrases : *ce qui se passe* ·
   *l'indice qui permettait de l'anticiper* · *la bonne réaction*.
   Exemple : « Le piéton à gauche s'engage sans regarder. Il fixait son téléphone et avançait
   vers le bord du trottoir. Il fallait lever le pied et se préparer à freiner. »

## 3. Étiquettes (`tags`) pour l'entraînement adaptatif (D2)

Chaque danger reçoit les étiquettes de sa ligne du catalogue ; le scénario peut en ajouter.
Liste fermée : toute nouvelle étiquette s'ajoute d'abord ici.

| Famille | Étiquettes |
|---|---|
| Où regarder | `windshield`, `mirror`, `blind_spot` |
| Qui | `vulnerable_user`, `child`, `cyclist`, `motorcyclist`, `heavy_vehicle`, `public_transport`, `animal` |
| Mécanisme | `hidden` (sort de derrière un obstacle), `priority` (règle de priorité), `distraction` (usager inattentif), `rule_violation` (usager en infraction), `sudden` (changement brusque), `rear` (vient de l'arrière) |
| Lieu | `intersection`, `school_zone`, `parking`, `bus_stop`, `roundabout`, `expressway`, `rural`, `roadworks` |

## 4. Dangers

Colonnes : **Indice** = ce qui fixe `startFrame` ; **Prio** = priorité de production (section 7).

### 4.1 Usagers vulnérables

| Type | Situation | Indice (début de fenêtre) | Vue | Étiquettes | Prio |
|---|---|---|---|---|---|
| `pedestrian_crossing` | Piéton qui s'engage sur la chaussée, sur un passage ou ailleurs | Il se tourne vers la route ou accélère vers le bord du trottoir | Pare-brise | `vulnerable_user`, `distraction` | P1 |
| `pedestrian_hidden` | Piéton qui surgit de derrière un véhicule stationné ou une camionnette | Une partie du corps ou des pieds apparaît au bord de l'obstacle | Pare-brise | `vulnerable_user`, `hidden` | P1 |
| `child_ball` | Ballon qui roule sur la route, suivi d'un enfant | Le ballon franchit le bord du trottoir (l'enfant suit 1 à 2 s après) | Pare-brise | `vulnerable_user`, `child`, `hidden` | P1 |
| `child_school` | Enfant qui court vers la route près d'une école (zone 30) | L'enfant se détache du groupe et court vers la chaussée | Pare-brise | `vulnerable_user`, `child`, `school_zone` | P2 |
| `pedestrian_slow_crossing` | Piéton âgé encore sur le passage quand notre feu passe au vert | Notre feu passe au vert alors qu'il est au milieu du passage | Pare-brise | `vulnerable_user`, `intersection` | P2 |
| `bus_stop_pedestrian` | Bus à l'arrêt, un passager descendu traverse devant le bus | Le passager contourne l'avant du bus | Pare-brise | `vulnerable_user`, `hidden`, `bus_stop` | P2 |
| `cyclist_swerve` | Cycliste qui dévie vers le milieu de la chaussée (voiture garée, obstacle) ou tourne sans prévenir | Il regarde par-dessus l'épaule ou s'approche de l'obstacle sur sa trajectoire | Pare-brise | `vulnerable_user`, `cyclist`, `sudden` | P1 |
| `cyclist_contraflow` | Cycliste à contresens dans une rue à sens unique limité (SUL), qui débouche d'un carrefour | Il apparaît dans la rue transversale ou dans notre rue, face à nous | Pare-brise | `vulnerable_user`, `cyclist`, `intersection` | P2 |
| `scooter_sidewalk` | Trottinette électrique qui descend du trottoir ou traverse rapidement | Elle se dirige vers la bordure à vitesse élevée | Pare-brise | `vulnerable_user`, `sudden` | P2 |
| `blind_spot_cyclist` | Cycliste qui remonte à droite pendant que nous tournons à droite | Le cycliste apparaît dans le rétroviseur droit, notre clignotant droit est actif | Rétro droit | `vulnerable_user`, `cyclist`, `mirror`, `blind_spot`, `rear` | P2 |

### 4.2 Véhicules devant ou sur le côté

| Type | Situation | Indice (début de fenêtre) | Vue | Étiquettes | Prio |
|---|---|---|---|---|---|
| `vehicle_braking` | Véhicule devant qui freine fort (y compris fin de bouchon sur voie rapide) | Ses feux stop s'allument et la distance se réduit | Pare-brise | `sudden` | P1 |
| `car_door_opening` | Portière d'une voiture garée qui s'ouvre sur notre trajectoire | Une personne est visible au volant, puis la portière bouge | Pare-brise | `parking`, `sudden` | P1 |
| `car_pulling_out` | Véhicule qui quitte une place de parking ou une entrée de garage | Roues braquées, clignotant, ou le véhicule avance | Pare-brise | `parking` | P1 |
| `car_reversing` | Voiture qui sort en marche arrière d'une place ou d'une allée | Les feux de recul s'allument | Pare-brise | `parking` | P2 |
| `bus_pulling_out` | Bus qui quitte l'arrêt (priorité au bus qui signale en agglomération) | Clignotant gauche du bus | Pare-brise | `public_transport`, `heavy_vehicle`, `bus_stop`, `priority` | P2 |
| `truck_turning` | Camion qui tourne et empiète sur notre voie | Clignotant et début de virage large | Pare-brise | `heavy_vehicle`, `intersection` | P2 |
| `oncoming_overtaking` | Véhicule en face qui dépasse et arrive dans notre voie | Il se décale vers l'axe de la route | Pare-brise | `rule_violation`, `rural` | P2 |
| `agricultural_vehicle` | Tracteur lent qui sort d'un chemin de campagne | Il apparaît au bout du chemin et avance | Pare-brise | `heavy_vehicle`, `rural` | P3 |

### 4.3 Priorités et carrefours

| Type | Situation | Indice (début de fenêtre) | Vue | Étiquettes | Prio |
|---|---|---|---|---|---|
| `priority_right` | Véhicule venant de droite qui a la priorité (carrefour sans signalisation) | Le véhicule apparaît dans la rue de droite et ne ralentit pas | Pare-brise | `priority`, `intersection` | P1 |
| `vehicle_ignoring_priority` | Véhicule qui ne respecte pas son stop ou son cédez-le-passage | Il ne ralentit pas à l'approche de la ligne | Pare-brise | `priority`, `rule_violation`, `intersection` | P1 |
| `car_running_red` | Véhicule qui brûle un feu rouge | Il ne ralentit pas alors que son feu est rouge | Pare-brise | `rule_violation`, `intersection` | P1 |
| `roundabout_unsignaled` | Véhicule dans le rond-point qui ne sort pas alors qu'on pensait qu'il sortait | Il dépasse la sortie sans clignotant de sortie | Pare-brise | `priority`, `roundabout` | P2 |
| `tram_crossing` | Tram qui traverse ou démarre (Bruxelles, Anvers, Gand) | Signal lumineux du tram ou tram en mouvement vers le carrefour | Pare-brise | `public_transport`, `heavy_vehicle`, `priority` | P3 |

### 4.4 Dangers venant de l'arrière (rétroviseurs)

| Type | Situation | Indice (début de fenêtre) | Vue | Étiquettes | Prio |
|---|---|---|---|---|---|
| `overtaking_vehicle` | Véhicule qui nous dépasse et se rabat trop court | Il se rapproche vite dans le rétroviseur gauche, clignotant gauche | Rétro gauche, puis pare-brise | `mirror`, `rear` | P2 |
| `motorbike_filtering` | Moto qui remonte la file entre deux voies | Phare de la moto dans le rétroviseur central ou gauche | Rétroviseurs | `motorcyclist`, `mirror`, `rear` | P2 |
| `merging_vehicle` | Véhicule qui s'insère depuis une bretelle sans adapter sa vitesse | Il arrive à notre hauteur sur la bretelle, dans le rétroviseur droit | Rétro droit, puis pare-brise | `mirror`, `expressway` | P2 |
| `emergency_vehicle` | Véhicule prioritaire (ambulance, police) qui arrive par l'arrière | Gyrophares bleus dans le rétroviseur central, sirène | Rétro central | `mirror`, `rear`, `priority` | P3 |

### 4.5 Environnement et obstacles

| Type | Situation | Indice (début de fenêtre) | Vue | Étiquettes | Prio |
|---|---|---|---|---|---|
| `animal_crossing` | Chevreuil ou chien qui traverse (campagne, souvent à l'aube ou la nuit) | L'animal apparaît en lisière ou sur l'accotement | Pare-brise | `animal`, `rural`, `sudden` | P3 |
| `roadworks_worker` | Ouvrier qui entre sur la chaussée dans une zone de travaux | Il se tourne vers la route ou recule hors de la zone balisée | Pare-brise | `vulnerable_user`, `roadworks` | P3 |

**Total : 29 types de dangers** (10 en P1, 14 en P2, 5 en P3).

## 5. Pièges

| Type | Description | Ce qui montre que ce n'est pas un danger |
|---|---|---|
| `decoy_pedestrian_static` | Piéton immobile sur le trottoir | Il est dos à la route, au téléphone, attend le bus |
| `decoy_pedestrian_parallel` | Piéton qui marche le long du trottoir | Sa trajectoire est parallèle à la route, loin du bord |
| `decoy_pedestrian_waiting` | Piéton qui attend au feu piéton rouge | Son feu est rouge, il est arrêté, il nous regarde |
| `decoy_child_supervised` | Enfant sur le trottoir tenu par la main | Un adulte le tient, ils marchent loin du bord |
| `decoy_cyclist_lane` | Cycliste qui roule droit sur sa piste séparée | Piste physiquement séparée, trajectoire stable |
| `decoy_parked_car` | Voiture garée sans conducteur | Personne à bord, pas de feux allumés |
| `decoy_car_stopped` | Voiture bien arrêtée au cédez-le-passage ou au stop | Elle est immobile à la ligne, conducteur tourné vers nous |
| `decoy_car_turning_away` | Voiture qui tourne en signalant, hors de notre trajectoire | Clignotant, elle quitte notre rue |
| `decoy_oncoming_car` | Voiture qui nous croise normalement | Elle reste dans sa voie, vitesse stable |
| `decoy_bus_stopped` | Bus à l'arrêt, portes fermées, personne autour | Pas de clignotant, aucun passager à proximité |
| `decoy_vehicle_behind` | Véhicule qui nous suit à distance normale | Distance stable dans le rétroviseur, pas de clignotant |

## 6. Jumeaux danger / piège

Chaque danger a un piège « jumeau » qui lui ressemble. Montrer les deux dans des clips différents
(ou le même clip) apprend à lire **l'indice** plutôt qu'à cliquer sur tout ce qui bouge. Le
générateur (J4) les associe automatiquement, et D2 suit séparément les dangers manqués et les
pièges cliqués.

| Danger | Piège jumeau | Indice qui fait la différence |
|---|---|---|
| `pedestrian_crossing` | `decoy_pedestrian_parallel`, `decoy_pedestrian_waiting` | Orientation et trajectoire vers la route |
| `pedestrian_hidden` | `decoy_parked_car` | Présence de pieds ou de mouvement au bord de l'obstacle |
| `child_ball`, `child_school` | `decoy_child_supervised` | Enfant seul, attention captée par le jeu |
| `cyclist_swerve` | `decoy_cyclist_lane` | Obstacle devant le cycliste, regard par-dessus l'épaule |
| `car_door_opening` | `decoy_parked_car` | Quelqu'un est assis au volant |
| `car_pulling_out`, `car_reversing` | `decoy_parked_car` | Roues braquées, feux allumés |
| `vehicle_ignoring_priority` | `decoy_car_stopped` | Le véhicule ralentit-il avant la ligne ? |
| `priority_right` | `decoy_car_turning_away` | Le véhicule vient-il vers notre trajectoire ? |
| `bus_pulling_out`, `bus_stop_pedestrian` | `decoy_bus_stopped` | Clignotant, passagers autour du bus |
| `oncoming_overtaking` | `decoy_oncoming_car` | Décalage vers l'axe de la route |
| `overtaking_vehicle`, `motorbike_filtering` | `decoy_vehicle_behind` | Vitesse d'approche dans le rétroviseur |

## 7. Priorités de production

La priorité tient compte de la fréquence de la situation à l'examen et du **coût de production**
(assets et animations à trouver, voir ADR-012).

| Priorité | Quand | Contenu | Assets nécessaires |
|---|---|---|---|
| **P1** | J1 (un danger), puis premier lot du générateur en J4 | 10 dangers et les pièges associés | Piétons adultes et enfant (marche, course, arrêt, téléphone), voitures (portières, feux stop, clignotants, feux de recul), ballon, vélo et cycliste |
| **P2** | Second lot, J4 à J5 | 14 dangers : rétroviseurs, bus, camions, motos, carrefours complexes, voie rapide | Bus, camion, moto, trottinette, personne âgée, rond-point, bretelle |
| **P3** | Après J5 | 5 dangers liés à des décors ou assets rares | Tram, tracteur, chevreuil, chien, ouvrier, zone de travaux, véhicule prioritaire avec gyrophares et sirène |

Ordre conseillé dans P1 : `pedestrian_crossing` (déjà prévu en J1) → `pedestrian_hidden` →
`car_door_opening` → `vehicle_braking` → `car_pulling_out` → `priority_right` →
`vehicle_ignoring_priority` → `car_running_red` → `child_ball` → `cyclist_swerve`.
Le cycliste est en dernier : c'est l'asset animé le plus difficile à trouver (vélo et pédalage).

## 8. Conditions (D5)

Chaque clip enregistre ses conditions dans `conditions`, pour varier les examens et suivre les
erreurs par condition (D2).

| Champ | Valeurs |
|---|---|
| `timeOfDay` | `day`, `dawn`, `dusk`, `night` |
| `weather` | `clear`, `overcast`, `rain`, `fog`, `low_sun`, `snow` |
| `environment` | `urban`, `residential`, `rural`, `expressway`, `roundabout`, `roadworks` |

Environnements où chaque danger peut apparaître (les autres combinaisons sont refusées par le
générateur) :

| Environnement | Dangers possibles |
|---|---|
| `urban` | Tous sauf `oncoming_overtaking`, `agricultural_vehicle`, `animal_crossing`, `merging_vehicle` |
| `residential` | Piétons, enfants, cyclistes, trottinette, véhicules en stationnement, `priority_right`, `vehicle_ignoring_priority` |
| `rural` | `cyclist_swerve`, `vehicle_braking`, `oncoming_overtaking`, `agricultural_vehicle`, `animal_crossing`, `priority_right`, `overtaking_vehicle` |
| `expressway` | `vehicle_braking`, `overtaking_vehicle`, `motorbike_filtering`, `merging_vehicle`, `emergency_vehicle` |
| `roundabout` | `roundabout_unsignaled`, `cyclist_swerve`, `pedestrian_crossing`, `scooter_sidewalk` |
| `roadworks` | `roadworks_worker`, `vehicle_braking`, `truck_turning` |

Effets des conditions sur les dangers :
- **Nuit, aube, crépuscule** : piétons et cyclistes sans éclairage ou en vêtements sombres ;
  le phare d'une moto, les feux stop et les gyrophares deviennent les indices principaux.
- **Pluie, brouillard** : fenêtre décalée plus tôt (`endFrame` avancé), car il faut freiner plus
  tôt ; visibilité réduite au loin.
- **Soleil rasant** : éblouissement qui masque partiellement un usager (dans la limite de la
  règle « cliquable »).
- **Neige** : réservée aux scénarios P3 (coût de rendu, rare à l'examen).

## 9. Composition d'un examen (proposition pour J5)

La répartition officielle n'est pas connue (voir [exam-rules.md](exam-rules.md)). En attendant :

- 5 clips notés, 10 dangers au total, 0 à 3 par clip ;
- au moins 1 danger dans un rétroviseur ;
- au moins 4 dangers impliquant un usager vulnérable ;
- au plus 2 dangers du même type ;
- au moins 3 environnements différents parmi les 5 clips ;
- au moins 1 clip qui n'est pas en plein jour par temps clair.

## Points validés

Tous les points ont été validés tels quels le 17/11/2026 (ADR-017). Toute modification
passera par une nouvelle ADR.

- [x] **V1 — Définition du danger** : seulement ce qui oblige à réagir et se concrétise dans le
  clip (un danger potentiel qui ne se concrétise pas devient un piège).
- [x] **V2 — Fenêtre** : début au premier indice objectif, fin environ 2 s avant le conflit,
  3 à 5 s au total ; clic avant la fenêtre = clic perdu.
- [x] **V3 — Moment idéal** : 0,3 à 1 s après le début de la fenêtre.
- [x] **V4 — Liste des 29 dangers** : retenue sans ajout ni retrait.
- [x] **V5 — Priorités** : les 10 dangers P1 et leur ordre (cycliste en dernier).
- [x] **V6 — Pièges** : 1 à 2 par clip, et le principe des jumeaux danger / piège.
- [x] **V7 — Étiquettes** : liste fermée de la section 3.
- [x] **V8 — Composition d'un examen** (section 9), en attendant une source officielle.
- [x] **V9 — Situations belges** retenues : sens unique limité (`cyclist_contraflow`), priorité
  de droite, priorité au bus qui quitte l'arrêt, tram, trottinettes.
