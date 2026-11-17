# Catalogue des dangers

Types de dangers à modéliser. Le `type` est la valeur utilisée dans le schéma d'annotation.
Priorité : P1 pour J1 et J4, P2 pour plus tard.

| Type | Description | Vue | Priorité |
|---|---|---|---|
| `pedestrian_crossing` | Piéton qui s'engage sur le passage ou hors passage | Pare-brise | P1 |
| `pedestrian_hidden` | Piéton qui sort de derrière un véhicule stationné | Pare-brise | P1 |
| `child_ball` | Ballon sur la route, suivi d'un enfant | Pare-brise | P1 |
| `cyclist_swerve` | Cycliste qui dévie ou tourne sans prévenir | Pare-brise | P1 |
| `car_door_opening` | Portière d'une voiture stationnée qui s'ouvre | Pare-brise | P1 |
| `car_pulling_out` | Véhicule qui quitte une place ou une entrée | Pare-brise | P1 |
| `priority_right` | Véhicule venant de droite qui a la priorité | Pare-brise | P1 |
| `car_running_red` | Véhicule qui brûle un feu rouge | Pare-brise | P1 |
| `vehicle_braking` | Véhicule devant qui freine brusquement | Pare-brise | P1 |
| `bus_stop` | Bus à l'arrêt, piétons qui traversent devant | Pare-brise | P2 |
| `truck_turning` | Camion qui tourne et coupe la trajectoire | Pare-brise | P2 |
| `overtaking_vehicle` | Véhicule qui dépasse ou se rabat | Rétroviseurs | P2 |
| `blind_spot_cyclist` | Cycliste dans l'angle mort en tournant à droite | Rétro droit | P2 |
| `motorbike_filtering` | Moto qui remonte la file | Rétroviseurs | P2 |
| `tram_crossing` | Tram qui traverse ou démarre | Pare-brise | P2 |
| `animal_crossing` | Animal sur la route (campagne) | Pare-brise | P2 |
| `roadworks_worker` | Ouvrier ou obstacle dans une zone de travaux | Pare-brise | P2 |

À valider avec les règles officielles : un « danger » est-il seulement ce qui oblige à réagir
(freiner, dévier), ou aussi un danger potentiel ?
