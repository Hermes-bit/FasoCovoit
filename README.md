# FasoCovoit

Projet de covoiturage pour le Burkina Faso. La première étape cible les trajets
interurbains, avec Ouagadougou–Bobo-Dioulasso comme ligne pilote envisagée.
Deux démonstrations indépendantes sont disponibles : la maquette web initiale et
une première base Flutter. Elles utilisent uniquement des données fictives.

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

Le parcours Flutter comprend la recherche, les réservations simulées et un
profil passager. Le profil conducteur sera construit dans une étape suivante.
La publication n’est donc pas proposée dans l’espace passager.

### Carte Google Maps sur le Web

L’aperçu d’itinéraire utilise l’API officielle Maps Embed, sans frais d’usage
selon Google, et nécessite une clé API. La clé n’est pas incluse dans le dépôt.
Pour l’essai local, créer une clé restreinte à l’API Maps Embed puis lancer :

```powershell
flutter run -d chrome "--dart-define=GOOGLE_MAPS_EMBED_API_KEY=VOTRE_CLE"
```

Pour GitHub Pages, ajouter `GOOGLE_MAPS_EMBED_API_KEY` comme secret d’action du
dépôt. La clé est intégrée au JavaScript public du site : restreindre son
référent HTTP à `https://hermes-bit.github.io/*` et l’API autorisée à Maps
Embed. Un secret GitHub ne rend pas une clé incluse dans le navigateur privée.
Sans clé, l’application indique explicitement que la carte n’est pas configurée.
Maps Embed est réservé au Web; l’application Flutter native n’affiche pas cette
carte intégrée.

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

### Accès direct par Flutter sur le même Wi-Fi

Depuis `mobile`, démarrer le serveur Flutter en écoutant sur le réseau :

```powershell
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

Sur le téléphone connecté au même Wi-Fi, ouvrir `http://ADRESSE-IP-DU-PC:8080`.
L'adresse IP locale du PC se trouve avec `ipconfig`. Il faut laisser la commande
en cours ; le pare-feu Windows peut demander l'autorisation pour le réseau privé.
Cette méthode sert au développement et ne rend pas le site accessible sur Internet.

Cette base permet de rechercher par villes, date et nombre de places, de consulter
les détails, de publier un trajet fictif, de simuler une réservation et de
l'annuler. Les disponibilités sont mises à jour **dans la session locale**.
Les données ne persistent pas au redémarrage et ne sont pas partagées entre
utilisateurs. L'application Flutter et la maquette web ne partagent pas leurs données.

## Limites importantes

Ces démonstrations ne fournissent ni vrais comptes, ni réservation réelle, ni
paiement, ni vérification d'identité, ni géolocalisation, ni appel, ni
messagerie, ni dispositif SOS. Google Maps Embed n’affiche une carte Web que
lorsqu’une clé configurée est disponible. Les avis, portefeuilles, réductions
et profils restent fictifs ou désactivés; aucune règle réelle de plafonnement
ou de remboursement n'est appliquée. Ne saisissez pas de coordonnées bancaires
ou d’informations personnelles réelles.

## Prochaines étapes avant un pilote réel

1. Valider le périmètre et les règles avec des passagers et conducteurs : prix
   plafonds, annulations, remboursements et acceptation des demandes.
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
