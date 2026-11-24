import 'dart:typed_data';

import 'package:fasocovoit/formats.dart';
import 'package:fasocovoit/model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mardi 24 novembre 2026, 18 h : le trajet de demain 7 h est à 13 h.
final maintenant = DateTime(2026, 11, 24, 18);

AppState etat() => AppState(horloge: () => maintenant);

void main() {
  group('formats', () {
    test('montants en francs CFA avec espaces insécables', () {
      expect(fcfa(2500), '2${nbsp}500${nbsp}F');
      expect(fcfa(100000), '100${nbsp}000${nbsp}F');
      expect(fcfaSigne(-1500), '− 1${nbsp}500${nbsp}F');
    });

    test('dates relatives en français', () {
      expect(jourRelatif(DateTime(2026, 11, 25, 7), maintenant), 'Demain');
      expect(jourCourt(DateTime(2026, 11, 26)), 'jeu. 26 nov.');
      expect(heure(DateTime(2026, 11, 26, 7)), '7 h 00');
    });
  });

  group('connexion par code SMS', () {
    test('70 00 00 00 est le compte existant de démonstration', () {
      final s = etat();
      expect(s.compteExiste('70 00 00 00'), isTrue);
      expect(s.compteExiste('76543210'), isFalse);
      expect(() => s.envoyerCode('70 00'), throwsA(isA<ErreurMetier>()));
    });

    test('un code faux est refusé, le bon code ouvre la session', () {
      final s = etat();
      final code = s.envoyerCode('70 00 00 00');
      expect(code, hasLength(6));
      expect(() => s.verifierCode('000000'), throwsA(isA<ErreurMetier>()));
      expect(s.connecte, isFalse);
      expect(s.verifierCode(code), isTrue);
      expect(s.connecte, isTrue);
      expect(s.moi.complet, 'Hermès Barry');
      expect(s.codeParrainage, 'HER-25');
      expect(s.dernierCodeSms, isNull);
    });

    test('T2 : après 5 codes faux, attendre 15 min avant un nouveau code', () {
      var heureCourante = maintenant;
      final s = AppState(horloge: () => heureCourante);
      final code = s.envoyerCode('70000000');
      for (var i = 0; i < AppState.essaisMax; i++) {
        expect(() => s.verifierCode('000000'), throwsA(isA<ErreurMetier>()));
      }
      expect(() => s.verifierCode(code), throwsA(isA<ErreurMetier>()));
      expect(() => s.envoyerCode('70000000'), throwsA(isA<ErreurMetier>()));
      heureCourante = maintenant.add(const Duration(minutes: 16));
      expect(s.verifierCode(s.envoyerCode('70000000')), isTrue);
    });

    test('T1 : un code reste valable 10 minutes, puis expire', () {
      var heureCourante = maintenant;
      final s = AppState(horloge: () => heureCourante);
      var code = s.envoyerCode('70000000');
      heureCourante = maintenant.add(const Duration(minutes: 9));
      expect(s.verifierCode(code), isTrue);
      s.deconnecter();
      code = s.envoyerCode('70000000');
      heureCourante = heureCourante.add(const Duration(minutes: 11));
      expect(() => s.verifierCode(code), throwsA(isA<ErreurMetier>()));
    });

    test('nouveau numéro : compte vierge, puis retour au compte de démonstration', () {
      final s = etat();
      expect(s.verifierCode(s.envoyerCode('76543210')), isFalse);
      expect(s.connecte, isFalse, reason: 'l’inscription doit encore être terminée');
      expect(s.compteExiste('76543210'), isTrue);
      expect(s.telephone, '76 54 32 10');
      expect(s.prenom, isEmpty);
      expect(s.solde, 0);
      expect(s.reservations, isEmpty);
      expect(s.trajets, isNotEmpty, reason: 'les trajets des conducteurs restent visibles');
      s.connecter();
      s.deconnecter();

      expect(s.verifierCode(s.envoyerCode('70000000')), isTrue);
      expect(s.prenom, 'Hermès');
      expect(s.solde, 7500);
    });

    test('à l’entrée, on choisit passager ou conducteur', () {
      final s = etat();
      expect(s.verifierCode(s.envoyerCode('70000000')), isTrue);
      expect(s.espaceAChoisir, isTrue);
      s.choisirEspace(Mode.conducteur);
      expect(s.espaceAChoisir, isFalse);
      expect(s.mode, Mode.conducteur, reason: 'pas besoin d’être passager');
      expect(s.estConducteur, isFalse, reason: 'il finit son inscription dans son espace');
      s.basculerMode(Mode.passager);
      expect(s.mode, Mode.passager);
    });
  });

  group('trajets entre deux lieux', () {
    test('Ouaga → n’importe quel quartier de Koudougou reprend la ligne connue', () {
      final l = Ligne.entre(lOuagaGare, lKoudS7);
      expect(l.km, 98);
      expect(l.car, 2000);
      expect(l.interVilles, isTrue);
      expect(calculerTarif(l).plafond, 2500);
      expect(Ligne.entre(lCissin, const Lieu('Koudougou', 'Chez Tanti')).km, 98);
    });

    test('R39 : ligne sans tarif de car connu, prix calculé sur les frais', () {
      final l = Ligne.entre(lKoudCentre, lBoboCentre);
      expect(l.km, inInclusiveRange(250, 320));
      expect(l.car, 0);
      final t = calculerTarif(l);
      int r(double x) => (x / 100).round() * 100;
      expect(t.conseille, r(t.fraisTrajet / 4));
      expect(t.plafond, r(t.conseille * 1.3));
      expect(t.plancher, r(t.conseille * 0.5));
    });

    test('en ville : Dassasgho → Ouaga 2000 fait environ 9 km', () {
      final l = Ligne.entre(lDassasgho, lOuaga2000);
      expect(l.km, inInclusiveRange(7, 11));
      expect(l.interVilles, isFalse);
      expect(l.rdv, lDassasgho.rdv);
    });

    test('recherche par lieux choisis', () {
      final s = etat();
      // Hermès : les trajets « Entre femmes » ne lui sont pas proposés.
      expect(s.rechercher(depart: lDassasgho, arrivee: lOuaga2000), hasLength(1));
      expect(s.rechercher(depart: lTampouy, arrivee: lZogona), isEmpty);
      expect(s.rechercher(depart: lCissin, arrivee: lKoudS7), hasLength(2));
      expect(s.rechercher(depart: lOuagaGare, arrivee: lBoboCentre), isEmpty);
      s.majProfil(femme: true);
      expect(s.rechercher(depart: lDassasgho, arrivee: lOuaga2000), hasLength(2));
      // Le trajet d'Aminata part de Tampouy, à plus de 8 km de Cissin.
      expect(s.rechercher(depart: lCissin, arrivee: lKoudS7), hasLength(2));
    });

    test('recherche à la date et à l’heure choisies', () {
      final s = etat();
      List<String> ids(DateTime quand) =>
          s.rechercher(depart: lOuagaGare, arrivee: lKoudCentre, quand: quand).map((t) => t.id).toList();
      // Demain : Issouf part à 7 h, Boukary à 16 h (Aminata : entre femmes).
      expect(ids(DateTime(2026, 11, 25, 7)), ['t1', 't3']);
      expect(ids(DateTime(2026, 11, 25, 6, 30)), ['t1', 't3'], reason: 'le conducteur part un peu après');
      expect(ids(DateTime(2026, 11, 25, 15)), ['t3'], reason: 'Issouf est déjà parti');
      expect(ids(DateTime(2026, 11, 26, 7)), isEmpty, reason: 'aucun trajet ce jour-là');
      // Montée en chemin : le conducteur passe à mi-route 45 min après son départ.
      expect(
        heurePassage(DateTime(2026, 11, 25, 7), const Duration(minutes: 90), (monte: 0, descend: 0, fraction: .5)),
        DateTime(2026, 11, 25, 7, 45),
      );
    });

    test('demande du passager : les conducteurs acceptent, il en choisit un', () {
      final s = etat();
      expect(
        () => s.demanderTrajet(depart: lPatteOie, arrivee: lKoudS7, quand: maintenant.subtract(const Duration(hours: 1))),
        throwsA(isA<ErreurMetier>()),
      );
      expect(
        () => s.demanderTrajet(depart: lPatteOie, arrivee: lKoudS7, adultes: 3, enfants: 2),
        throwsA(isA<ErreurMetier>()),
        reason: '4 places au plus',
      );
      // Demain 7 h : Issouf (7 h) et Boukary (16 h) ont publié Ouaga → Koudougou.
      final d = s.demanderTrajet(
        depart: lOuagaGare,
        arrivee: lKoudCentre,
        quand: DateTime(2026, 11, 25, 7),
        bagages: 1,
        paiement: Paiement.portefeuille,
      );
      expect(d.bagagesTexte, '1 bagage');
      expect(s.lieuxRecents.first, lKoudCentre);
      final issouf = s.recevoirOffre(d)!;
      expect(issouf.trajet.id, 't1');
      expect(s.recevoirOffre(d)!.trajet.id, 't3');
      expect(s.recevoirOffre(d), isNull, reason: 'les conducteurs de la ligne ont déjà répondu');
      expect(d.contactes, greaterThan(0));

      final r = s.accepterOffre(d, issouf);
      expect(r.statut, StatutResa.confirmee, reason: 'le conducteur a déjà accepté');
      expect(r.montee, lOuagaGare);
      expect(s.depose, 5000, reason: '2 500 F dont 500 F de bonus');
      expect(s.demandesTrajet.contains(d), isFalse);
      expect(s.notifications.first.titre, 'Demande acceptée');
      expect(s.aVenir, contains(r));
    });

    test('maintenant, en ville : un trajet publié, puis un conducteur alerté', () {
      var h = maintenant;
      final s = AppState(horloge: () => h);
      final d = s.demanderTrajet(depart: lDassasgho, arrivee: lOuaga2000);
      expect(d.desQuePossible, isTrue);
      expect(s.recevoirOffre(d)!.trajet.conducteur.prenom, 'Ousmane');
      final alerte = s.recevoirOffre(d)!;
      expect(alerte.trajet.conducteur.prenom, 'Salif');
      expect(alerte.minutes, 6);
      expect(alerte.trajet.depart, lDassasgho, reason: 'il vient à l’adresse du passager');
      expect(alerte.prix, calculerTarif(Ligne.entre(lDassasgho, lOuaga2000)).conseille);
      expect(s.recevoirOffre(d), isNull);

      // 15 minutes pour confirmer, puis l'acceptation expire.
      h = h.add(const Duration(minutes: 16));
      expect(s.offresValables(d), isEmpty);
      expect(() => s.accepterOffre(d, alerte), throwsA(isA<ErreurMetier>()));
      s.retirerDemande(d);
      expect(s.demandesTrajet.contains(d), isFalse);
    });

    test('croisement : montée sur la route, dépose près de l’adresse, dans le bon sens', () {
      final c = correspondance(lOuagaGare, lKoudCentre, lCissin, lKoudS7);
      expect(c, isNotNull);
      expect(c!.monte, lessThan(3));
      expect(c.descend, lessThan(3));
      expect(correspondance(lOuagaGare, lKoudCentre, lKoudCentre, lOuagaGare), isNull, reason: 'mauvais sens');
      expect(correspondance(lDassasgho, lOuaga2000, lZogona, lPatteOie), isNotNull);
      expect(correspondance(lDassasgho, lOuaga2000, lTampouy, lZogona), isNull, reason: 'trop loin');
      expect(
        correspondance(lOuagaGare, lKoudCentre, lDassasgho, lUnivOuaga),
        isNull,
        reason: 'trajet en ville : 3 km au plus, même sur une route entre villes',
      );
      expect(ecartTexte(0.1), 'sur la route');
      expect(ecartTexte(2.4), 'à 2,4 km');
    });

    test('photos : profil et documents gardés en mémoire', () {
      final s = etat();
      final octets = Uint8List.fromList([1, 2, 3]);
      s.majPhoto(octets);
      expect(s.photo, octets);
      s.majPhoto(null);
      expect(s.photo, isNull);
      s.envoyerDocument('CNIB', photo: octets);
      expect(s.photosDocuments['CNIB'], octets);
      expect(s.documentsEnvoyes, contains('CNIB'));
    });

    test('la recherche ignore accents et majuscules', () {
      expect(normaliser('Université Ki-Zerbo'), 'universite ki-zerbo');
      expect(normaliser("PATTE D'OIE"), "patte d'oie");
    });
  });

  group('tarifs (R30 à R41)', () {
    test('Ouaga → Koudougou : plancher, conseillé et plafond de la maquette', () {
      final t = calculerTarif(ligneParId('ouaga-koudougou'));
      expect(t.plancher, 1000);
      expect(t.conseille, 1800);
      expect(t.plafond, 2500);
      expect(t.limiteFrais, 2800);
    });

    test('Ouaga → Bobo : le plafond VIP est ramené à la limite des frais', () {
      final t = calculerTarif(ligneParId('ouaga-bobo'));
      expect(t.plafond, lessThanOrEqualTo(t.limiteFrais));
      expect(t.conseille, lessThanOrEqualTo(t.plafond));
    });

    test('en ville : minimum conseillé de 400 F et plafond d’au moins 700 F', () {
      final t = calculerTarif(ligneParId('dassasgho-ouaga2000'));
      expect(t.conseille, 400);
      expect(t.plafond, 700);
      expect(t.plancher, 200);
      expect(t.borner(1000), 700);
    });
  });

  group('règles d’annulation (B7, C3)', () {
    test('entre villes : 100 %, 50 % puis 0 %', () {
      expect(tauxRemboursement(interVilles: true, avantDepart: const Duration(hours: 30)), 100);
      expect(tauxRemboursement(interVilles: true, avantDepart: const Duration(hours: 13)), 50);
      expect(tauxRemboursement(interVilles: true, avantDepart: const Duration(minutes: 90)), 0);
    });

    test('annulation par le conducteur ou demande en attente : 100 %', () {
      expect(tauxRemboursement(interVilles: true, avantDepart: Duration.zero, parConducteur: true), 100);
      expect(tauxRemboursement(interVilles: true, avantDepart: Duration.zero, enAttente: true), 100);
    });

    test('en ville : gratuit tant que le conducteur n’est pas arrivé', () {
      expect(tauxRemboursement(interVilles: false, avantDepart: const Duration(minutes: 5)), 100);
      expect(
        tauxRemboursement(interVilles: false, avantDepart: Duration.zero, conducteurArrive: true),
        0,
      );
    });
  });

  group('réservation et portefeuille', () {
    test('le bonus paie au plus la moitié du prix', () {
      final s = etat();
      expect(s.bonusUtilisable(2500), 500);
      s.bonus = 3000;
      expect(s.bonusUtilisable(2500), 1250);
    });

    test('payer avec le portefeuille bloque l’argent puis l’annulation rembourse 50 %', () {
      final s = etat();
      final trajet = s.trajets.firstWhere((t) => t.id == 't1');
      final libres = trajet.placesLibres;
      final r = s.reserver(trajet, places: 1, paiement: Paiement.portefeuille);
      expect(r.bonusUtilise, 500);
      expect(s.depose, 5000);
      expect(s.bonus, 0);
      expect(s.bloque, 2500);
      expect(trajet.placesLibres, libres - 1);

      s.simulerAcceptation(r);
      expect(r.statut, StatutResa.confirmee);
      expect(s.conversationPour(trajet.conducteur), isNotNull);

      expect(s.tauxPour(r), 50);
      final rendu = s.annulerReservation(r);
      expect(rendu, 1250);
      expect(s.bonus, 250);
      expect(s.depose, 6000);
      expect(s.bloque, 0);
      expect(trajet.placesLibres, libres);
    });

    test('solde insuffisant : la réservation est refusée sans rien débiter', () {
      final s = etat()..depose = 100;
      final trajet = s.trajets.firstWhere((t) => t.id == 't1');
      expect(
        () => s.reserver(trajet, places: 1, paiement: Paiement.portefeuille),
        throwsA(isA<ErreurMetier>()),
      );
      expect(s.depose, 100);
      expect(s.bonus, 500);
    });

    test('une demande sans réponse expire et est remboursée', () {
      var heureCourante = maintenant;
      final s = AppState(horloge: () => heureCourante);
      final trajet = s.trajets.firstWhere((t) => t.id == 't1');
      final r = s.reserver(trajet, places: 1, paiement: Paiement.portefeuille);
      heureCourante = maintenant.add(const Duration(minutes: 31));
      s.verifierDelais();
      expect(r.statut, StatutResa.expiree);
      expect(s.depose, 7000);
      expect(s.bonus, 500);
    });

    test('T5 : plus de place, « Trajet complet »', () {
      final s = etat();
      final t = s.trajets.firstWhere((t) => t.id == 't1');
      t.placesPrises = t.places;
      expect(
        () => s.reserver(t, places: 1, paiement: Paiement.especes),
        throwsA(isA<ErreurMetier>().having((e) => e.message, 'message', 'Trajet complet.')),
      );
    });

    test('R43 : dépôt de 500 à 50 000 F, solde plafonné à 100 000 F', () {
      final s = etat();
      s.deposer(5000, Paiement.orange);
      expect(s.depose, 12000);
      expect(() => s.deposer(60000, Paiement.moov), throwsA(isA<ErreurMetier>()));
      s.deposer(50000, Paiement.moov);
      expect(() => s.deposer(40000, Paiement.moov), throwsA(isA<ErreurMetier>()));
      s.depose = 12000;
      expect(() => s.retirer(500, '1234'), throwsA(isA<ErreurMetier>()));
      expect(() => s.retirer(20000, '1234'), throwsA(isA<ErreurMetier>()));
      expect(() => s.retirer(2000, '12'), throwsA(isA<ErreurMetier>()));
      s.retirer(2000, '1234');
      expect(s.depose, 10000);
      expect(s.bonus, 500);
    });

    test('une réclamation est ouverte une seule fois par opération', () {
      final s = etat();
      final op = s.operations.firstWhere((o) => o.statut == StatutOp.enAttente);
      final a = s.reclamer(op, 'SMS reçu');
      final b = s.reclamer(op, 'encore');
      expect(identical(a, b), isTrue);
      expect(op.statut, StatutOp.reclamation);
    });
  });

  group('dossier du conducteur', () {
    /// Nouveau compte : dossier vide.
    AppState vierge() {
      final s = etat();
      s.verifierCode(s.envoyerCode('76543210'));
      return s;
    }

    void remplir(AppState s) {
      for (final d in documentsConducteur.keys) {
        s.envoyerDocument(d, photo: Uint8List.fromList([1]));
      }
      s.majDossier(
        (d) => d
          ..naissance = DateTime(2000, 1, 10)
          ..cnibNumero = 'B123'
          ..cnibExpire = DateTime(2030, 1, 1)
          ..permisNumero = 'P456'
          ..permisDelivre = DateTime(2020, 5, 2)
          ..plaque = '11 gl-1234'
          ..vehicule = 'Kia Picanto bleue'
          ..assureur = 'Assureur'
          ..police = 'A-1'
          ..plaqueAssurance = '11GL1234'
          ..assuranceFin = DateTime(2027, 6, 30),
      );
    }

    List<String> aCorriger(AppState s) => [for (final c in s.controlesDossier) if (!c.ok) c.libelle];

    test('contrôles automatiques : âge, permis, validités, plaques, photos', () {
      final s = vierge();
      expect(s.dossierComplet, isFalse);
      expect(() => s.envoyerPourValidation(), throwsA(isA<ErreurMetier>()));
      remplir(s);
      expect(aCorriger(s), isEmpty);

      s.majDossier((d) => d.naissance = DateTime(2006, 1, 1));
      expect(aCorriger(s), ['21 ans ou plus']);
      s.majDossier((d) => d.naissance = DateTime(2000, 1, 10));

      s.majDossier((d) => d.permisDelivre = DateTime(2025, 6, 1));
      expect(aCorriger(s), ['Permis depuis 2 ans au moins']);
      s.majDossier((d) => d.permisDelivre = DateTime(2020, 5, 2));

      s.majDossier((d) => d.plaqueAssurance = '11 GL 9999');
      expect(aCorriger(s), ["Même plaque sur la carte grise et l'assurance"]);
      s.majDossier((d) => d.plaqueAssurance = '11 GL 1234');

      s.majDossier((d) => d.assuranceFin = DateTime(2026, 11, 1));
      expect(aCorriger(s), ['Assurance en cours de validité']);
      s.majDossier((d) => d.assuranceFin = DateTime(2027, 6, 30));

      s.envoyerDocument('CNIB', photo: Uint8List.fromList([2]), appareil: false);
      expect(aCorriger(s), ["Photos prises avec l'appareil photo"]);
      expect(() => s.envoyerPourValidation(), throwsA(isA<ErreurMetier>()));
      s.envoyerDocument('CNIB', photo: Uint8List.fromList([3]));

      expect(plaqueValide('11 HH 2345'), isTrue);
      expect(plaqueValide('ABC'), isFalse);
      s.envoyerPourValidation();
      expect(s.etapeConducteur, EtapeConducteur.documentsEnvoyes);
    });

    test('l’équipe valide seulement avec toute sa liste cochée, ou refuse', () {
      final s = vierge();
      remplir(s);
      s.envoyerPourValidation();
      final points = [for (final (_, p) in verificationEquipe) ...p];
      expect(points, hasLength(13));
      for (final p in points.skip(1)) {
        s.cocherVerification(p);
      }
      expect(s.pointsRestants, 1);
      expect(() => s.validerParEquipe(), throwsA(isA<ErreurMetier>()));

      s.refuserDossier('Photo illisible');
      expect(s.etapeConducteur, EtapeConducteur.aucune);
      expect(s.motifRefus, 'Photo illisible');
      expect(s.verificationsFaites, isEmpty);

      s.envoyerPourValidation();
      expect(s.motifRefus, isNull);
      for (final p in points) {
        s.cocherVerification(p);
      }
      s.validerParEquipe();
      expect(s.etapeConducteur, EtapeConducteur.valide);
      expect(s.valideLe, maintenant);
    });

    test('document qui expire : rappel, puis blocage, puis renouvellement', () {
      final s = etat();
      for (final d in documentsConducteur.keys) {
        s.envoyerDocument(d);
      }
      s.envoyerPourValidation();
      s.simulerValidation();
      s.activerAbonnement(Formule.mensuel);
      // Démo : l'assurance d'Hermès expire dans 20 jours.
      expect(s.alertesDocuments.single.doc, 'Assurance');
      expect(s.alertesDocuments.single.bloquant, isFalse);

      s.majDossier((d) => d.assuranceFin = DateTime(2026, 11, 20));
      expect(s.documentsExpires, isTrue);
      Ligne l = ligneParId('dassasgho-ouaga2000');
      expect(
        () => s.publier(ligne: l, depart: maintenant.add(const Duration(days: 1)), places: 2, prix: 400),
        throwsA(isA<ErreurMetier>()),
      );

      expect(
        () => s.renouvelerDocument('Assurance', fin: DateTime(2026, 1, 1), photo: Uint8List.fromList([1])),
        throwsA(isA<ErreurMetier>()),
      );
      s.renouvelerDocument('Assurance', fin: DateTime(2027, 11, 30), photo: Uint8List.fromList([1]));
      expect(s.alertesDocuments, isEmpty);
      l = ligneParId('dassasgho-ouaga2000');
      expect(s.publier(ligne: l, depart: maintenant.add(const Duration(days: 1)), places: 2, prix: 400).ligne, l);
    });
  });

  group('espace conducteur', () {
    AppState conducteurActif() {
      final s = etat();
      for (final d in documentsConducteur.keys) {
        s.envoyerDocument(d);
      }
      s.envoyerPourValidation();
      s.simulerValidation();
      s.activerAbonnement(Formule.trimestriel);
      return s;
    }

    test('l’abonnement exige la validation puis offre le premier mois', () {
      final s = etat();
      expect(() => s.activerAbonnement(Formule.mensuel), throwsA(isA<ErreurMetier>()));
      final c = conducteurActif();
      expect(c.estConducteur, isTrue);
      expect(c.abonnement!.offertJusquau, DateTime(2026, 12, 24, 18));
      c.payerAbonnement();
      expect(c.abonnement!.prochainPaiement, DateTime(2027, 3, 24, 18));
    });

    test('publier vers une destination choisie, mais jamais vers le départ', () {
      final s = conducteurActif();
      final t = s.publier(
        ligne: Ligne.entre(lOuagaGare, lKoudUniv),
        depart: maintenant.add(const Duration(days: 2)),
        places: 3,
        prix: 2000,
        rdv: '  Devant la station  ',
      );
      expect(t.ligne.arrivee, lKoudUniv);
      expect(t.rdv, 'Devant la station');
      expect(
        () => s.publier(
          ligne: Ligne.entre(lDassasgho, lDassasgho),
          depart: maintenant.add(const Duration(days: 2)),
          places: 3,
          prix: 400,
        ),
        throwsA(isA<ErreurMetier>()),
      );
    });

    test('alerte : le conducteur passe chez un passager inscrit vers son heure', () {
      final s = conducteurActif();
      // Fatou attend à Patte d'Oie demain à 7 h, pour Koudougou Secteur 7.
      bool fatou(DemandeTrajet d) => d.passager.prenom == 'Fatou';
      expect(s.coursesPossibles.where((c) => fatou(c.demande)), isEmpty, reason: 'aucun trajet publié');
      expect(s.passagersSansCourse.any(fatou), isTrue, reason: 'tous les passagers inscrits sont visibles');

      // Départ à 11 h : trop tard pour Fatou (1 h de tolérance entre villes).
      s.publier(ligne: Ligne.entre(lOuagaGare, lKoudCentre), depart: DateTime(2026, 11, 25, 11), places: 3, prix: 2000);
      expect(s.coursesPossibles.where((c) => fatou(c.demande)), isEmpty);

      final t = s.publier(
        ligne: Ligne.entre(lOuagaGare, lKoudCentre),
        depart: DateTime(2026, 11, 25, 7),
        places: 3,
        prix: 2000,
      );
      final c = s.coursesPossibles.firstWhere((c) => fatou(c.demande));
      expect(c.trajet, t);
      expect(c.passage, DateTime(2026, 11, 25, 7));
      expect(s.coursesPour(t), contains(c));
      expect(s.passagersSansCourse.any(fatou), isFalse);

      s.prendreCourse(c);
      final p = t.confirmes.firstWhere((p) => p.personne.prenom == 'Fatou');
      expect(p.montee, lPatteOie);
      expect(p.descente, lKoudS7);
      expect(s.demandesTrajet.contains(c.demande), isFalse);
      expect(() => s.prendreCourse(c), throwsA(isA<ErreurMetier>()), reason: 'déjà prise');

      // Le passager connecté publie sa propre demande : pas d'alerte pour lui-même.
      final mienne = s.demanderTrajet(depart: lTampouy, arrivee: lZogona);
      expect(mienne.moi, isTrue);
      expect(s.coursesPossibles.any((c) => c.demande == mienne), isFalse);
      expect(s.passagersSansCourse.contains(mienne), isFalse);
    });

    test('le conducteur ignore une course : le passager reste visible', () {
      final s = conducteurActif();
      s.publier(ligne: Ligne.entre(lOuagaGare, lKoudCentre), depart: DateTime(2026, 11, 25, 7), places: 3, prix: 2000);
      final c = s.coursesPossibles.firstWhere((c) => c.demande.passager.prenom == 'Fatou');
      s.ignorerCourse(c);
      expect(s.coursesPossibles.any((x) => x.demande == c.demande), isFalse);
      expect(s.passagersSansCourse, contains(c.demande));
    });

    test('premier trajet publié : un passager fictif attend sur la route', () {
      final s = conducteurActif();
      final t = s.publier(
        ligne: ligneParId('dassasgho-ouaga2000'),
        depart: maintenant.add(const Duration(days: 1)),
        places: 3,
        prix: 400,
      );
      final exemple = s.coursesPour(t).where((c) => c.demande.exemple).toList();
      expect(exemple, hasLength(1));
      expect(exemple.single.croisement.monte, greaterThan(0.3));
      expect(exemple.single.ecart.inMinutes.abs(), lessThan(5));
    });

    test('en route : un passager pris en chemin monte à bord', () {
      final s = conducteurActif();
      final t = s.publier(ligne: Ligne.entre(lOuagaGare, lKoudCentre), depart: DateTime(2026, 11, 25, 7), places: 3, prix: 2000);
      final c = s.coursesPour(t).firstWhere((c) => c.demande.passager.prenom == 'Fatou');
      for (final p in t.confirmes) {
        s.validerCode(p, p.code);
      }
      s.demarrerTrajet(t);
      s.prendreCourse(c);
      final fatou = t.confirmes.firstWhere((p) => p.personne.prenom == 'Fatou');
      expect(fatou.aBord, isFalse);
      s.monterEnChemin(t, fatou);
      expect(fatou.aBord, isTrue);
    });

    test('sans compte actif, le conducteur voit les passagers mais ne prend pas de course', () {
      final s = etat();
      s.choisirEspace(Mode.conducteur);
      expect(s.mode, Mode.conducteur);
      expect(s.passagersSansCourse, isNotEmpty);
      expect(
        () => s.publier(ligne: ligneParId('ouaga-koudougou'), depart: maintenant.add(const Duration(days: 2)), places: 3, prix: 2000),
        throwsA(isA<ErreurMetier>()),
      );
    });

    test('liste des demandes : écarter, tout effacer ; voiture ; taux d’annulation', () {
      final s = conducteurActif();
      final d = s.passagersSansCourse.first;
      s.ecarterDemande(d);
      expect(s.passagersSansCourse, isNot(contains(d)));

      s.publier(ligne: Ligne.entre(lOuagaGare, lKoudCentre), depart: DateTime(2026, 11, 25, 7), places: 3, prix: 2000);
      expect(s.coursesPossibles, isNotEmpty);
      s.toutEffacer();
      expect(s.coursesPossibles, isEmpty);
      expect(s.passagersSansCourse, isEmpty);

      expect(s.tauxAnnulation, isNull, reason: 'pas encore de trajet terminé');
      expect(
        () => s.majVoiture(vehicule: 'Kia Picanto', couleur: 'bleue', plaque: 'ABC'),
        throwsA(isA<ErreurMetier>()),
      );
      s.majVoiture(vehicule: 'Kia Picanto', couleur: 'bleue', plaque: '11 gl 1234');
      expect(s.dossier.voiture, 'Kia Picanto bleue');
      expect(s.dossier.plaque, '11 GL 1234');

      s.majReglages(enLigne: true, silence: true);
      expect(s.enLigneUniquement && s.sourdine, isTrue);
    });

    test('publier refuse un prix au-dessus du plafond', () {
      final s = conducteurActif();
      expect(
        () => s.publier(
          ligne: ligneParId('ouaga-koudougou'),
          depart: maintenant.add(const Duration(days: 2)),
          places: 3,
          prix: 3000,
        ),
        throwsA(isA<ErreurMetier>()),
      );
    });

    test('du départ à l’arrivée : codes, montée, gains', () {
      final s = conducteurActif();
      final t = s.publier(
        ligne: ligneParId('ouaga-koudougou'),
        depart: maintenant.add(const Duration(days: 2)),
        places: 3,
        prix: 2500,
      );
      expect(t.exemple, isTrue);
      expect(t.confirmes, hasLength(1));
      expect(t.enAttente, hasLength(1));

      s.repondre(t, t.enAttente.single, accepter: true);
      expect(t.reservees, 2);
      expect(t.toutLeMondeABord, isFalse);
      expect(() => s.demarrerTrajet(t), throwsA(isA<ErreurMetier>()));

      final moussa = t.confirmes.firstWhere((p) => p.paiement == Paiement.especes);
      expect(s.validerCode(moussa, '0000'), isFalse);
      expect(s.validerCode(moussa, moussa.code), isTrue);
      expect(s.monterParQr(t)?.personne.prenom, 'Rasmata');
      expect(s.gainsEnAttente, 2500);

      s.demarrerTrajet(t);
      final g = s.terminerTrajet(t);
      expect(g.especes, 2500);
      expect(g.mobile, 2500);
      expect(s.gainsDisponibles, 2500);
      expect(s.trajetsConducteur, 1);
      s.retirerGains();
      expect(s.gainsDisponibles, 0);
    });

    test('trois annulations avec passagers suspendent le compte 7 jours', () {
      final s = conducteurActif();
      for (var i = 0; i < 3; i++) {
        final t = s.publier(
          ligne: ligneParId('dassasgho-ouaga2000'),
          depart: maintenant.add(Duration(days: i + 1)),
          places: 2,
          prix: 400,
        );
        if (t.confirmes.isEmpty) {
          t.passagers.add(
            Passager(
              personne: const Personne('Test', 'Passager'),
              places: 1,
              paiement: Paiement.especes,
              code: '1111',
              recueLe: maintenant,
              prixPlace: 400,
              statut: StatutDemande.acceptee,
            ),
          );
        }
        s.annulerTrajetPublie(t);
      }
      expect(s.annulationsConducteur, 3);
      expect(s.suspendu, isTrue);
      expect(
        () => s.publier(
          ligne: ligneParId('dassasgho-ouaga2000'),
          depart: maintenant.add(const Duration(days: 9)),
          places: 2,
          prix: 400,
        ),
        throwsA(isA<ErreurMetier>()),
      );
    });
  });
}
