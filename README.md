# FasoCovoit

Projet de covoiturage pour le Burkina Faso : trajets en ville à Ouagadougou et
ligne pilote Ouagadougou–Koudougou. Deux démonstrations indépendantes sont
disponibles : la maquette web initiale et l'application Flutter, reconstruite
d'après le prototype « Latérite et drapeau ». Elles utilisent uniquement des
données fictives.

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

### Ce que contient l'application

L'application reprend les écrans mobiles du prototype « Latérite » (couleurs,
polices Figtree et Bricolage Grotesque, en-tête « piste », billet) :

- **Compte** : bienvenue, numéro, code SMS, profil, contact d'urgence,
  suppression du compte. La photo de profil se prend avec l'appareil photo ou
  s'importe depuis la galerie ; les documents du conducteur se prennent
  **seulement avec l'appareil photo** (gardés en mémoire pendant la session,
  rien n'est envoyé à un serveur).
- **Documents du conducteur** : CNIB, selfie avec la CNIB, permis, carte grise,
  assurance et photo du véhicule. Le conducteur saisit ce que disent ses
  documents (date de naissance, numéros, dates de validité, plaques) et
  l'application contrôle : 21 ans ou plus, permis depuis 2 ans, CNIB et
  assurance valides, plaque au format habituel et identique sur la carte grise
  et l'assurance, photos prises avec l'appareil. Un rappel arrive 30 jours avant
  l'expiration de l'assurance ou de la CNIB ; une fois expirée, le conducteur ne
  peut plus publier jusqu'à l'envoi du nouveau document.
- **Liste de vérification de l'équipe** (écran de démonstration du futur
  back-office) : 13 points à cocher (identité, permis, véhicule, assurance,
  entretien avec les originaux et la voiture) avant de pouvoir valider un
  conducteur, ou refus avec un motif que le conducteur voit et corrige.
- **Passager** : recherche en ville ou entre villes, résultats filtrables, fiche
  du trajet, paiement (portefeuille avec bonus, Orange Money, Moov Money,
  espèces), demande en attente, billet avec QR et code de départ, mes trajets,
  annulation, trajet en cours, SOS, notation, signalement.
- **Messages, notifications et profil**.
- **Portefeuille** : solde, dépôt, historique, parrainage, retrait, réclamation.
- **Conducteur** : inscription (documents, validation, abonnement), publication
  avec prix plafonné, demandes, codes ou QR au départ, trajet en cours, gains,
  portefeuille conducteur, abonnement, annulation.
- **Départ et destination** : le conducteur (« D'où partez-vous ? », « Où
  allez-vous ? ») comme le passager choisissent leurs lieux dans une recherche
  (quartiers de Ouaga, Koudougou, Bobo-Dioulasso) ou saisissent un lieu absent
  de la liste. Distance, durée et prix plafond se calculent pour le trajet
  choisi ; pendant le trajet, « Itinéraire » ouvre Google Maps vers la
  destination. Les coordonnées des quartiers sont approximatives : la recherche
  Google Places pourra les remplacer.
- **Date et heure du départ** : le passager choisit le jour et l'heure où il
  veut partir (ou « Partir maintenant »). La recherche ne garde que les
  conducteurs qui passent à son adresse ce jour-là, pas avant l'heure choisie
  (moins 1 h entre villes, 30 min en ville), et donne l'heure de passage quand
  il monte en chemin.
- **Croisement des adresses** : un trajet convient si le passager peut monter au
  départ ou le long de la route et descendre près de son adresse, dans le bon
  sens (8 km entre villes, 3 km pour un trajet en ville). Sans offre, il publie
  sa demande, visible dans « Mes trajets ».
- **Alertes de course** : tous les passagers inscrits qui cherchent un trajet
  sont visibles par les conducteurs. Quand la route d'un conducteur passe chez
  l'un d'eux à peu près à son heure, l'application l'alerte (accueil, badge,
  écran du trajet en cours) : il prend la course ou l'ignore. Pour un passager
  qu'aucun trajet ne croise, « Accepter la course » publie le trajet depuis son
  adresse, à son heure, et l'y ajoute.
- **Colis** : aperçu des écrans de la version 2.

Les règles de la maquette sont réellement calculées : plafond et prix conseillé
d'après les tarifs (Ouaga–Koudougou : plancher 1 000 F, conseillé 1 800 F,
plafond 2 500 F), bonus limité à la moitié du prix, remboursements à 100 %,
50 % ou 0 % selon le délai, expiration d'une demande après 30 minutes,
suspension du conducteur après 3 annulations en 30 jours.

### Connexion

- **Compte existant de démonstration : 70 00 00 00** (Hermès Barry, avec son historique,
  son portefeuille et ses trajets). « J'ai déjà un compte » le propose déjà.
- Tout autre numéro crée un **nouveau compte vierge** (portefeuille à 0 F) après
  le profil et le contact d'urgence. Un numéro inconnu saisi dans « J'ai déjà un
  compte » propose de créer le compte.
- À l'entrée, l'utilisateur choisit son espace : **« Je cherche un trajet »**
  (passager) ou **« Je propose mes trajets »** (conducteur). Être passager n'est
  pas obligatoire : un conducteur arrive directement dans son espace, où il
  finit son inscription (documents, validation, abonnement). La bascule
  Passager / Conducteur des en-têtes permet de changer à tout moment.
- Le code à 6 chiffres expire après 10 minutes ; après 5 codes faux, le numéro
  est bloqué 15 minutes. Aucun fournisseur SMS
  n'est encore branché : l'application affiche le SMS reçu (simulation) et il
  faut recopier le code.
- « Continuer avec Google » est affiché mais pas encore actif. Il faudra des
  vrais comptes côté serveur (par exemple Supabase Auth ou Firebase Auth avec le
  fournisseur Google) et un identifiant client OAuth Google.

### Plein écran

L'application occupe toute la fenêtre, sur téléphone comme sur ordinateur. Sur
téléphone, l'ajouter à l'écran d'accueil (menu du navigateur → « Ajouter à
l'écran d'accueil » ou « Installer l'application ») l'ouvre en plein écran, sans
la barre du navigateur.

### Raccourcis de démonstration
- « Simuler l'acceptation du conducteur » et « Vérification par l'équipe
  (démo) » remplacent les actions qui seront faites par d'autres personnes.
- Pour le compte de démonstration, ce que disent les documents d'Hermès est
  pré-rempli (seules les photos restent à prendre) et son assurance expire
  dans 20 jours : le rappel s'affiche dans l'espace conducteur.
- Au premier trajet publié, deux demandes fictives arrivent. Les codes de départ
  de ces passagers sont affichés à l'écran ; le scanner propose de simuler son
  résultat (la caméra n'est pas encore utilisée).
- Au premier trajet publié, un passager fictif attend aussi le long de la route,
  à l'heure du passage : l'alerte de course s'affiche. Des passagers de
  démonstration (Fatou S., Salam O., Ali K.) cherchent déjà un trajet.
- Côté passager, « Simuler la réponse d'un conducteur » (dans « Mes trajets »)
  fait accepter la demande par un conducteur, qui vient le prendre à son adresse
  à la date et à l'heure choisies.

Le code est organisé ainsi dans `mobile/lib` : `model.dart` (règles et données
en mémoire), `ui.dart` et `theme.dart` (composants du thème), `screens/`
(un fichier par parcours).

Le back-office de l'équipe (écrans 32 à 35, 42, 50 à 52, 54 et 58 de la
maquette, prévu en Next.js) n'est pas encore construit.

### Carte Google Maps sur le Web

Sur le Web, la carte du trajet est une vraie carte Google Maps (Maps
JavaScript API) avec un **style clair et coloré proche de Plans** : terrain
crème, routes blanches, grands axes jaunes, parcs verts, eau bleue, itinéraire
bleu, départ vert, arrivée latérite et position de la voiture. La recherche
de lieux propose les **adresses de la base Google Maps** au Burkina Faso
(Places API) en plus des quartiers de l'application ; l'adresse choisie garde
sa vraie position pour les distances, les prix et le croisement des trajets.
Le code est dans `web/carte.js` et `lib/carte.dart`.

La clé n’est pas incluse dans le dépôt. Dans la console Google Cloud, sur le
projet de la clé, **activer Maps JavaScript API, Places API (New) et Routes
API**. Pour l’essai local :

```powershell
flutter run -d chrome "--dart-define=GOOGLE_MAPS_EMBED_API_KEY=VOTRE_CLE"
```

Pour GitHub Pages, le secret d’action `GOOGLE_MAPS_EMBED_API_KEY` (ou
`GOOGLE_MAPS_API`) reste utilisé. La clé est intégrée au JavaScript public du
site : restreindre son référent HTTP à `https://hermes-bit.github.io/*` et ses
API aux trois ci-dessus. Un secret GitHub ne rend pas une clé incluse dans le
navigateur privée. Sans clé, si une API n’est pas activée ou hors réseau,
l’application affiche une carte dessinée dans le même style et la liste de
lieux de l’application. L’application Flutter native (Android, iOS) utilise
cette carte dessinée.

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

Les places, le portefeuille, les messages et les trajets publiés sont mis à jour
**dans la session locale**. Les données ne persistent pas au redémarrage et ne
sont pas partagées entre utilisateurs. L'application Flutter et la maquette web
ne partagent pas leurs données.

## Limites importantes

Ces démonstrations ne fournissent ni vrais comptes, ni réservation réelle, ni
paiement, ni vérification d'identité, ni géolocalisation, ni messagerie réelle,
ni dispositif SOS : aucune alerte ni aucun SMS n'est envoyé. Sur le Web, les
boutons « Appeler la police · 17 » et « pompiers · 18 » ouvrent le composeur du
téléphone ; ailleurs, ils affichent le numéro à composer. Le QR du billet est
une illustration non lisible. La position de la voiture sur la carte est
simulée (pas de GPS). La carte du trajet est un dessin, remplacé par Google
Maps sur le Web lorsqu'une clé est configurée. Les règles de prix
et de remboursement sont calculées mais ne déplacent aucun argent réel. Ne
saisissez pas de coordonnées bancaires ou d’informations personnelles réelles.

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
