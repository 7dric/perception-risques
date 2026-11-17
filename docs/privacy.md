# Vie privée — analyse du regard par webcam

Règles qui s'appliquent à la fonction D6 (ADR-015). Elles serviront de base à la politique de
confidentialité (RGPD) du site.

## Principes

1. **Optionnel.** La fonction est désactivée par défaut. Le lecteur fonctionne entièrement
   sans webcam.
2. **Consentement clair.** Avant d'activer la caméra, un écran explique en mots simples ce qui
   est fait, ce qui est gardé et comment l'effacer. Le texte doit être compréhensible par un
   élève mineur.
3. **Traitement 100 % local.** L'image de la webcam est analysée dans le navigateur. Elle n'est
   **jamais envoyée** à un serveur, **jamais enregistrée** (ni image, ni vidéo, ni capture).
4. **Données minimales.** Les points du visage et la calibration restent en mémoire pendant la
   séance et sont effacés à sa fin. Seules des statistiques peuvent être gardées, par exemple :
   délai du premier regard sur un danger, nombre de coups d'œil aux rétroviseurs.
5. **Effacement.** Un bouton efface toutes les statistiques de regard.
6. **Arrêt immédiat.** La caméra peut être coupée à tout moment ; un indicateur montre quand elle
   est active.

## Données concernées

| Donnée | Où | Durée |
|---|---|---|
| Image de la webcam | Mémoire du navigateur, image par image | Immédiatement oubliée |
| Points du visage, point de regard | Mémoire du navigateur | Fin de la séance |
| Modèle de calibration | Mémoire du navigateur | Fin de la séance |
| Statistiques de regard | Stockage du navigateur (puis compte, quand il existera) | Jusqu'à effacement par l'élève |

## À faire avant la mise en ligne

- Faire relire la politique de confidentialité par un juriste.
- Vérifier le cas des mineurs : âge du consentement numérique en Belgique et formulation.
- Quand les comptes arriveront (Odoo) : préciser si les statistiques sont synchronisées et
  demander un consentement distinct.
