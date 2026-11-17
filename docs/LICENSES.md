# Licences

Règle : n'utiliser que des briques **open source compatibles avec un usage commercial**, et noter
chaque asset dans [ASSETS.md](ASSETS.md).

## Licence du projet

Tous droits réservés pour le moment. Rien ne s'oppose à un changement ultérieur.

## Outils et bibliothèques

| Brique | Licence | Usage | Remarque |
|---|---|---|---|
| Godot 4.x | MIT | Production 3D | Mention de copyright à garder si on distribue le moteur |
| Road Generator (plugin Godot) | MIT | Routes et carrefours | À confirmer au moment de l'ajout |
| FFmpeg | LGPL/GPL selon la compilation | Encodage interne | Non redistribué : pas d'obligation sur le produit |
| SVT-AV1 | BSD-3-Clause-Clear | Encodeur AV1 | |
| libvpx | BSD-3-Clause | Encodeur VP9 | |
| TypeScript | Apache-2.0 | Lecteur web | |
| Vite | MIT | Lecteur web | |
| Vitest | MIT | Tests | |
| Playwright | Apache-2.0 | Tests de bout en bout | |
| MediaPipe Tasks Vision (Face Landmarker) | Apache-2.0 | Analyse du regard par webcam | Modèle fourni par Google, même licence |
| WebGazer.js | GPL-3.0 | **Écarté** | Licence incompatible avec un produit fermé |
| Odoo Community | LGPLv3 | Comptes, paiement (plus tard) | Enterprise est propriétaire et payant |

## Assets graphiques et sonores

Le rendu visé est réaliste (ADR-012).

| Source | Licence | Usage |
|---|---|---|
| Poly Haven | CC0 | Textures PBR, HDRI (ciels), objets réalistes |
| ambientCG | CC0 | Textures PBR (asphalte, pavés, façades) |
| MakeHuman | Modèles exportés en CC0 | Piétons, cyclistes |
| Captures de mouvement libres (ex. base CMU) | Usage libre, à vérifier par jeu de données | Animations de marche, course |
| Kenney, Quaternius | CC0 | Prototypes et éléments secondaires seulement (style trop simple pour le rendu final) |

**CC-BY accepté** : usage commercial permis, à condition de citer l'auteur. Chaque asset CC-BY
est inscrit dans ASSETS.md, et une page « crédits » sera publiée sur le site.

À éviter : licences « NC » (non commercial), « ND » (pas de modification), assets extraits de jeux,
captures des clips officiels, services gratuits mais propriétaires (ex. Mixamo) dont la licence
peut changer.

## Points juridiques

- Pas de logo, de nom commercial ni de charte graphique des centres d'examen ou des autorités.
- Mention « projet indépendant, sans lien avec les autorités » sur le site.
- Panneaux routiers : vérifier la licence de chaque fichier (par exemple sur Wikimedia Commons).
