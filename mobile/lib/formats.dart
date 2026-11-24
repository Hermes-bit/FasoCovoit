/// Formats français utilisés partout dans l'application.
library;

const _jours = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];
const _mois = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];
const _moisLong = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

/// Espace insécable : un montant ne se coupe jamais en fin de ligne.
const nbsp = ' ';

/// 2500 → « 2 500 » (séparateur de milliers insécable).
String milliers(int n) {
  final signe = n < 0 ? '-' : '';
  final s = n.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(nbsp);
    buf.write(s[i]);
  }
  return '$signe$buf';
}

/// 2500 → « 2 500 F ».
String fcfa(int n) => '${milliers(n)}${nbsp}F';

/// Montant signé pour les historiques : « + 5 000 F » ou « − 2 500 F ».
String fcfaSigne(int n) => '${n < 0 ? '−' : '+'} ${fcfa(n.abs())}';

String capitaliser(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// 7:00 → « 7 h 00 ».
String heure(DateTime d) =>
    '${d.hour} h ${d.minute.toString().padLeft(2, '0')}';

/// 7:00 → « 7 h », 7:15 → « 7 h 15 ».
String heureCourte(DateTime d) => d.minute == 0 ? '${d.hour} h' : heure(d);

/// « jeu. 26 nov. »
String jourCourt(DateTime d) =>
    '${_jours[d.weekday - 1]} ${d.day} ${_mois[d.month - 1]}';

/// « 26 nov. »
String dateCourte(DateTime d) => '${d.day} ${_mois[d.month - 1]}';

/// « 26 novembre »
String dateLongue(DateTime d) => '${d.day} ${_moisLong[d.month - 1]}';

/// « Novembre » ou « Novembre 2026 ».
String moisAnnee(DateTime d, {bool annee = false}) =>
    capitaliser(_moisLong[d.month - 1]) + (annee ? ' ${d.year}' : '');

DateTime jour(DateTime d) => DateTime(d.year, d.month, d.day);

int ecartJours(DateTime d, DateTime maintenant) =>
    jour(d).difference(jour(maintenant)).inDays;

/// « Aujourd'hui », « Demain », « Hier » ou « Jeu. 26 nov. ».
String jourRelatif(DateTime d, DateTime maintenant) {
  switch (ecartJours(d, maintenant)) {
    case 0:
      return "Aujourd'hui";
    case 1:
      return 'Demain';
    case -1:
      return 'Hier';
    default:
      return capitaliser(jourCourt(d));
  }
}

/// « Demain, jeu. 26 nov. » pour les en-têtes de recherche.
String jourRelatifComplet(DateTime d, DateTime maintenant) {
  final rel = jourRelatif(d, maintenant);
  final court = jourCourt(d);
  return rel.startsWith(capitaliser(court)) ? rel : '$rel, $court';
}

/// Libellé court pour un horodatage d'opération : « 4 h 12 » ou « 12 nov. ».
String quand(DateTime d, DateTime maintenant) =>
    ecartJours(d, maintenant) == 0 ? heure(d) : dateCourte(d);

/// Durée : 90 min → « 1 h 30 ».
String duree(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h == 0) return '$m min';
  return m == 0 ? '$h h' : '$h h ${m.toString().padLeft(2, '0')}';
}

String pluriel(int n, String singulier, [String? plurielForme]) =>
    '$n ${n > 1 ? (plurielForme ?? '${singulier}s') : singulier}';
