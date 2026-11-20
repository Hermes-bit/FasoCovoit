# FasoCovoit — guide des premiers tests utilisateurs

## Objectif

Vérifier que des passagers et conducteurs comprennent les parcours de la
démonstration interurbaine avant de décider des règles produit et de développer
le serveur. Ce test évalue les écrans, pas la demande commerciale et encore
moins un service de covoiturage réel.

## Participants et durée

- Prévoir 8 à 10 sessions individuelles de 20 à 25 minutes.
- Inclure des passagers et des conducteurs potentiels, par exemple 4 à 5 de
  chaque profil.
- Demander leur accord avant de commencer. Leur participation est facultative
  et ils peuvent arrêter à tout moment.
- Ne pas demander ni enregistrer les noms, numéros, adresses, documents
  d'identité ou informations financières. Pas d'enregistrement audio ou vidéo
  par défaut.
- Attribuer un code neutre à chaque session (P01, P02…) et garder les notes
  localement. Le dépôt et la maquette étant publics, ne pas y publier de notes
  individuelles, captures contenant des données personnelles ou citations
  identifiantes.

## Introduction à lire

> Merci de tester une maquette, pas un service opérationnel. Les trajets,
> profils et tarifs sont fictifs ; aucune place ne sera réellement réservée et
> aucun paiement ne sera demandé. Nous testons l'interface, pas vos capacités.
> Vous pouvez arrêter à tout moment. Puis-je noter vos retours sans votre nom ?

## Déroulé

Demander à la personne de penser à voix haute. Lire seulement la consigne,
sans montrer où appuyer. Noter ce qu'elle réussit sans aide, les hésitations,
les erreurs et ses mots exacts lorsqu'ils ne contiennent aucune donnée
personnelle. Ne pas expliquer comment fonctionne le service pendant l'exercice.

### Parcours passager

1. « Vous souhaitez aller de Ouagadougou à Bobo-Dioulasso demain pour deux
   personnes. Cherchez un trajet. »
2. « Choisissez un trajet et trouvez l'heure et le lieu de départ, le conducteur,
   les places disponibles et le prix par personne. »
3. « Simulez la réservation de deux places. Où retrouvez-vous votre réservation ?
   Comment l'annuleriez-vous ? »

### Parcours conducteur

4. « Vous proposez un trajet fictif de Ouagadougou à Bobo-Dioulasso demain à
   7 h, avec un arrêt à Boromo, trois places et un prix de 5 000 FCFA par place.
   Publiez-le dans la démonstration. »
5. « Où retrouvez-vous le trajet que vous venez de publier ? Quelles informations
   voudriez-vous préciser avant de proposer un vrai trajet ? »

La publication n'est visible que dans la session et disparaît au rechargement.
Réinitialiser la maquette avant la session suivante.

### Questions de fin

- Quelle étape vous a semblé la plus simple ? La moins claire ?
- À quel moment avez-vous hésité ou manqué d'information ?
- Le prix, les places et le point de rendez-vous étaient-ils faciles à comprendre ?
- Qu'aimeriez-vous savoir sur le conducteur ou le véhicule avant de voyager ?
- Qu'est-ce qui vous rassurerait ou vous inquiéterait dans ce parcours ?
- Si vous pouviez changer une seule chose, laquelle choisiriez-vous ?

Ne pas suggérer les réponses et ne pas promettre que les fonctionnalités de
sécurité, de vérification ou de paiement montrées dans les maquettes sont déjà
disponibles.

### Parcours profil et aide

Si le temps le permet, demander à la personne de :

6. « Vous voulez savoir si une réservation est réelle. Trouvez la réponse dans
   l’application. »
7. « Vous avez repéré un problème dans la maquette. Montrez comment vous le
   signaleriez. »

Vérifier qu’elle trouve la FAQ et le centre de sécurité, et qu’elle comprend
qu’un signalement n’est pas envoyé et n’est pas surveillé. Ces écrans sont des
exemples d’interface, pas un vrai service d’aide ou d’urgence.

## Fiche de notes anonyme

Copier cette grille hors du dépôt, sur une feuille ou dans un fichier local :

| Code | Profil (passager/conducteur) | Tâche | Réussi sans aide / avec aide / non | Hésitation ou blocage observé | Proposition de la personne |
|---|---|---|---|---|---|
| P01 | | Recherche | | | |
| P01 | | Détail et réservation simulée | | | |
| P01 | | Publication simulée | | | |

Après chaque session, résumer les trois principaux blocages et les expressions
incompréhensibles. À la fin, compter les réussites par tâche, comparer les
retours des deux profils et prioriser les problèmes qui empêchent de chercher,
réserver ou publier. Ne conserver dans ce dépôt public que des conclusions
agrégées et anonymes, sans données brutes.

## À distinguer de l'étude de marché

La checklist FasoRoute recommande séparément d'interroger 30 à 50 personnes,
dont au moins 15 conducteurs, d'observer les solutions existantes et de tester
un pilote manuel avant la décision Go / No-go. Les 8 à 10 sessions ci-dessus
servent uniquement à déceler des problèmes d'ergonomie dans la maquette ; elles
ne remplacent pas cette étude ni la validation des règles, de l'assurance ou
des obligations applicables au Burkina Faso.
