# FasoCovoit

Projet de covoiturage pour le Burkina Faso. La première étape cible les trajets
interurbains, avec Ouagadougou–Bobo-Dioulasso comme ligne pilote envisagée.
Deux démonstrations indépendantes sont disponibles : la maquette web initiale et
une première base Flutter. Elles utilisent uniquement des données fictives.

Pour préparer les premiers retours, utiliser le
[guide des tests utilisateurs](docs/guide-tests-utilisateurs.md). Il distingue
le test d'ergonomie de la maquette de l'étude de marché plus large avant le
lancement.

## Essayer la maquette web

Ouvrir `index.html` dans un navigateur. Aucun compte, serveur ou installation n'est nécessaire.

- Rechercher un trajet entre villes : essayer Ouagadougou → Bobo-Dioulasso à la date proposée.
- Consulter un trajet, choisir des places et simuler une réservation.
- Publier un trajet fictif et le retrouver dans « Mes trajets ».
- Choisir « En ville » pour voir une illustration de course partagée.

Les données sont fictives et les essais sont conservés uniquement en mémoire, jusqu'au rechargement de la page. Les prix sont des exemples, pas des tarifs recommandés.

## Application Flutter

Depuis un terminal avec Flutter installé :

```powershell
cd mobile
flutter pub get
flutter run -d chrome
```

Pour Android, connecter un appareil ou démarrer un émulateur, accepter les
licences du SDK Android, puis utiliser `flutter run`. iOS nécessite macOS et
Xcode. Tests et analyse : `flutter test` et `flutter analyze` depuis `mobile`.

### Accès sur téléphone par GitHub Pages

Le dépôt public construit et publie automatiquement la version web après chaque
mise à jour de la branche `main` :

**https://hermes-bit.github.io/FasoCovoit/**

Le premier déploiement peut prendre quelques minutes. Suivre son état dans
l'onglet **Actions** du dépôt. Si Pages n'est pas encore activé pour ce dépôt,
choisir **Settings → Pages → Build and deployment → GitHub Actions**.
Le site public est une démonstration ; le code du dépôt est également public.
Le workflow utilise Flutter 3.44.6 afin d'aligner la compilation sur la version
validée localement.

### Accès direct par Flutter sur le même Wi-Fi

Depuis `mobile`, démarrer le serveur Flutter en écoutant sur le réseau :

```powershell
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

Sur le téléphone connecté au même Wi-Fi, ouvrir `http://ADRESSE-IP-DU-PC:8080`.
L'adresse IP locale du PC se trouve avec `ipconfig`. Il faut laisser la commande
en cours ; le pare-feu Windows peut demander l'autorisation pour le réseau privé.
Cette méthode sert au développement et ne rend pas le site accessible sur Internet.

Le parcours passager est accessible dans l’onglet « Voyager » ou depuis
« Prendre un trajet » dans le profil ; il permet de rechercher par villes, date
et nombre de places, de consulter les détails, puis de simuler une réservation
ou une demande en attente du conducteur, puis son annulation. Le conducteur
peut publier un trajet avec point de rendez-vous, notes, équipements et choix
entre demande manuelle ou acceptation automatique. « Mes trajets » affiche les
demandes et leur statut ; l'exemple conducteur préchargé permet d'essayer
l'acceptation ou le refus d'une demande. Tous ces états sont uniquement locaux
et fictifs. L’application inclut aussi un profil de démonstration,
un parcours
« Comment ça marche ? », une FAQ, un centre de sécurité et un formulaire de
signalement qui confirme explicitement qu'il n'envoie rien. Les disponibilités
sont mises à jour **dans la session locale**.
Les données ne persistent pas au redémarrage et ne sont pas partagées entre
utilisateurs. L'application Flutter et la maquette web ne partagent pas leurs données.

## Limites importantes

Ces démonstrations ne fournissent ni vrais comptes, ni réservation, ni paiement,
ni vérification d'identité, ni carte, ni géolocalisation, ni appel, ni messagerie,
ni dispositif SOS. Elles ne doivent pas être utilisées pour organiser de vrais trajets.
Le centre d'aide et le formulaire de signalement sont des écrans d'exemple,
non surveillés : aucune demande n'est transmise à une équipe.
Les prix et profils affichés sont fictifs et aucune règle réelle de plafonnement
ou de remboursement n'est appliquée.

## Prochaines étapes avant un pilote réel

1. Tester les parcours de démonstration avec des passagers et conducteurs
   (voir le [guide des tests](docs/guide-tests-utilisateurs.md)), puis valider
   les règles : prix plafonds, annulations, remboursements et acceptation des
   demandes. En parallèle, mener l'étude de marché prévue dans la checklist.
2. Créer les comptes de l'entreprise et un projet Supabase. Concevoir et tester
   la base PostgreSQL, les autorisations, les réservations atomiques et la
   protection des données avant de connecter l'application ; aucun service
   Supabase n'est encore configuré.
3. Mettre en place les comptes SMS, l'envoi sécurisé des documents et leur
   validation, le back-office et le support.
4. Vérifier les obligations de transport, d'assurance et de protection des
   données auprès des autorités et conseils compétents.
5. Négocier et intégrer les paiements mobiles et les règles de gestion des fonds,
   puis réaliser les fonctions de sécurité et tester les situations d'incident.
6. Tester sur de vrais appareils et réseaux, faire une recette de sécurité et
   un pilote fermé ; développer ensuite la course partagée en ville et le suivi.
