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
      expect(s.prenom, 'Awa');
      expect(s.dernierCodeSms, isNull);
    });

    test('après 5 essais faux, même le bon code est refusé', () {
      final s = etat();
      final code = s.envoyerCode('70000000');
      for (var i = 0; i < AppState.essaisMax; i++) {
        expect(() => s.verifierCode('000000'), throwsA(isA<ErreurMetier>()));
      }
      expect(() => s.verifierCode(code), throwsA(isA<ErreurMetier>()));
      expect(s.verifierCode(s.envoyerCode('70000000')), isTrue);
    });

    test('un code expire après 5 minutes', () {
      var heureCourante = maintenant;
      final s = AppState(horloge: () => heureCourante);
      final code = s.envoyerCode('70000000');
      heureCourante = maintenant.add(const Duration(minutes: 6));
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
      expect(s.prenom, 'Awa');
      expect(s.solde, 7500);
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

    test('dépôt plafonné à 100 000 F et retrait limité à l’argent déposé', () {
      final s = etat();
      s.deposer(5000, Paiement.orange);
      expect(s.depose, 12000);
      expect(() => s.deposer(100000, Paiement.moov), throwsA(isA<ErreurMetier>()));
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
