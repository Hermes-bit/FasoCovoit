import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'model.dart';
import 'painters.dart';
import 'theme.dart';

// ---------------------------------------------------------------------------
// Structure d'écran
// ---------------------------------------------------------------------------

/// Écran standard : fond sable, contenu en colonne, sans AppBar Material.
class Ecran extends StatelessWidget {
  const Ecran({super.key, required this.children, this.fond = C.sable});
  final List<Widget> children;
  final Color fond;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: fond,
    body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
  );
}

/// En-tête « piste » latérite avec pointillés et bord arrondi sable.
class Piste extends StatelessWidget {
  const Piste({
    super.key,
    required this.children,
    this.couleur = C.laterite,
    this.paddingBas = 34,
    this.centre = false,
    this.retour = false,
    this.trailing,
  });
  final List<Widget> children;
  final Color couleur;
  final double paddingBas;
  final bool centre;
  final bool retour;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final haut = MediaQuery.paddingOf(context).top;
    return Stack(
      children: [
        Container(
          width: double.infinity,
          color: couleur,
          padding: EdgeInsets.fromLTRB(20, 22 + haut, 20, paddingBas),
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: Colors.white),
            child: IconTheme.merge(
              data: const IconThemeData(color: Colors.white),
              child: Column(
                crossAxisAlignment: centre ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  if (retour || trailing != null)
                    Row(
                      children: [
                        if (retour)
                          Transform.translate(
                            offset: const Offset(-10, 0),
                            child: IconeBtn(
                              icon: Icons.chevron_left_rounded,
                              label: 'Retour',
                              taille: 30,
                              onTap: () => Navigator.of(context).maybePop(),
                            ),
                          ),
                        const Spacer(),
                        ?trailing,
                      ],
                    ),
                  ...children,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 24,
          child: Opacity(
            opacity: .55,
            child: const Pointilles(color: Colors.white, epaisseur: 3, plein: 14, vide: 12),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 14,
            decoration: const BoxDecoration(
              color: C.sable,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Barre claire avec retour, titre et sous-titre.
class Barre extends StatelessWidget {
  const Barre({
    super.key,
    required this.titre,
    this.sousTitre,
    this.actions = const [],
    this.leading,
    this.onRetour,
  });
  final String titre;
  final String? sousTitre;
  final List<Widget> actions;
  final Widget? leading;
  final VoidCallback? onRetour;

  @override
  Widget build(BuildContext context) {
    final haut = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(8, 12 + haut, 12, 12),
      decoration: const BoxDecoration(
        color: C.surface,
        border: Border(bottom: BorderSide(color: C.trait, width: 1.5)),
      ),
      child: Row(
        children: [
          IconeBtn(
            icon: Icons.chevron_left_rounded,
            label: 'Retour',
            taille: 30,
            onTap: onRetour ?? () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 8),
          ?leading,
          if (leading != null) const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                if (sousTitre != null)
                  Opacity(
                    opacity: .85,
                    child: Text(sousTitre!, style: T.mini),
                  ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// Zone de contenu défilante. Les widgets `bas` restent collés en bas
/// quand le contenu est court (comme `flex:1` dans la maquette).
class Zone extends StatelessWidget {
  const Zone({
    super.key,
    required this.children,
    this.bas = const [],
    this.gap = 16,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 20),
    this.centre = false,
  });
  final List<Widget> children;
  final List<Widget> bas;
  final double gap;
  final EdgeInsets padding;
  final bool centre;

  @override
  Widget build(BuildContext context) {
    final align = centre ? CrossAxisAlignment.center : CrossAxisAlignment.stretch;
    if (bas.isEmpty) {
      return Expanded(
        child: SingleChildScrollView(
          padding: padding,
          child: Column(crossAxisAlignment: align, children: espacer(children, gap)),
        ),
      );
    }
    return Expanded(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: padding,
            sliver: SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: align,
                children: [
                  ...espacer(children, gap),
                  const Spacer(),
                  SizedBox(height: gap),
                  ...espacer(bas, 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<Widget> espacer(List<Widget> items, double gap) => [
  for (var i = 0; i < items.length; i++) ...[
    if (i > 0) SizedBox(height: gap, width: gap),
    items[i],
  ],
];

/// Pied fixe clair (bouton principal en bas d'écran).
class Pied extends StatelessWidget {
  const Pied({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + MediaQuery.paddingOf(context).bottom),
    decoration: const BoxDecoration(
      color: C.surface,
      border: Border(top: BorderSide(color: C.trait, width: 1.5)),
    ),
    child: child,
  );
}

// ---------------------------------------------------------------------------
// Cartes et listes
// ---------------------------------------------------------------------------

class Carte extends StatelessWidget {
  const Carte({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.couleur = C.surface,
    this.bord = C.trait,
    this.epaisseur = 1.5,
    this.onTap,
    this.rayon = 22,
    this.pointillee = false,
  });

  /// Carte sélectionnée : bord vert épais.
  const Carte.sel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  }) : couleur = C.surface,
       bord = C.vert,
       epaisseur = 2.5,
       rayon = 22,
       pointillee = false;

  /// Carte sombre (encre).
  const Carte.sombre({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.couleur = C.encre,
    this.onTap,
  }) : bord = Colors.transparent,
       epaisseur = 0,
       rayon = 22,
       pointillee = false;

  final Widget child;
  final EdgeInsets padding;
  final Color couleur;
  final Color bord;
  final double epaisseur;
  final VoidCallback? onTap;
  final double rayon;
  final bool pointillee;

  @override
  Widget build(BuildContext context) {
    final sombre = couleur == C.encre || couleur == C.encre2;
    Widget contenu = Padding(padding: padding, child: child);
    if (sombre) {
      contenu = DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white),
        child: IconTheme.merge(data: const IconThemeData(color: Colors.white), child: contenu),
      );
    }
    final forme = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(rayon),
      side: epaisseur > 0 && !pointillee
          ? BorderSide(color: bord, width: epaisseur)
          : BorderSide.none,
    );
    Widget carte = Material(
      color: couleur,
      shape: forme,
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? contenu : InkWell(onTap: onTap, child: contenu),
    );
    if (pointillee) {
      carte = CustomPaint(
        foregroundPainter: _BordPointille(bord, rayon, epaisseur),
        child: carte,
      );
    }
    return carte;
  }
}

class _BordPointille extends CustomPainter {
  _BordPointille(this.couleur, this.rayon, this.epaisseur);
  final Color couleur;
  final double rayon;
  final double epaisseur;

  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(epaisseur / 2),
      Radius.circular(rayon),
    );
    final paint = Paint()
      ..color = couleur
      ..style = PaintingStyle.stroke
      ..strokeWidth = epaisseur;
    for (final m in (Path()..addRRect(rr)).computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 12) {
        canvas.drawPath(m.extractPath(d, d + 7), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BordPointille old) => old.couleur != couleur;
}

/// Carte-liste : lignes séparées par un trait.
class ListeCarte extends StatelessWidget {
  const ListeCarte({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Carte(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Sep(),
          children[i],
        ],
      ],
    ),
  );
}

class LigneListe extends StatelessWidget {
  const LigneListe({
    super.key,
    required this.children,
    this.onTap,
    this.couleur,
    this.haut = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  });
  final List<Widget> children;
  final VoidCallback? onTap;
  final Color? couleur;
  final bool haut;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final ligne = Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: haut ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: espacer(children, 12),
      ),
    );
    return Material(
      color: couleur ?? Colors.transparent,
      child: onTap == null ? ligne : InkWell(onTap: onTap, child: ligne),
    );
  }
}

class Sep extends StatelessWidget {
  const Sep({super.key, this.marge = EdgeInsets.zero});
  final EdgeInsets marge;
  @override
  Widget build(BuildContext context) =>
      Container(margin: marge, height: 1.5, color: C.trait);
}

/// Titre + sous-titre empilés, qui prennent la place restante.
class Bloc extends StatelessWidget {
  const Bloc(this.titre, [this.sous, this.couleurSous]) : super(key: null);
  final String titre;
  final String? sous;
  final Color? couleurSous;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titre, style: T.gras),
        if (sous != null)
          Text(sous!, style: T.mini.copyWith(color: couleurSous ?? C.doux)),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Boutons
// ---------------------------------------------------------------------------

class Btn extends StatelessWidget {
  const Btn(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.couleur = C.vert,
    this.texte = Colors.white,
    this.hauteur = 58,
    this.taille = 17,
  });
  const Btn.lat(this.label, {super.key, this.onPressed, this.icon, this.hauteur = 58, this.taille = 17})
    : couleur = C.laterite,
      texte = Colors.white;
  const Btn.sos(this.label, {super.key, this.onPressed, this.icon, this.hauteur = 58, this.taille = 17})
    : couleur = C.sos,
      texte = Colors.white;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color couleur;
  final Color texte;
  final double hauteur;
  final double taille;

  @override
  Widget build(BuildContext context) {
    final actif = onPressed != null;
    final fg = actif ? texte : C.doux;
    return Semantics(
      button: true,
      enabled: actif,
      child: Material(
        color: actif ? couleur : C.sable2,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            height: hauteur,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, color: fg, size: 22), const SizedBox(width: 10)],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(color: fg, fontSize: taille, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BtnClair extends StatelessWidget {
  const BtnClair(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.couleur = C.encre,
    this.hauteur = 52,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color couleur;
  final double hauteur;

  @override
  Widget build(BuildContext context) {
    final c = onPressed == null ? C.doux : couleur;
    return Material(
      color: Colors.transparent,
      shape: StadiumBorder(side: BorderSide(color: onPressed == null ? C.trait : c, width: 2)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: hauteur,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, color: c, size: 20), const SizedBox(width: 8)],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c, fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Petit bouton du back-office et des cartes (« btn-p »).
class BtnP extends StatelessWidget {
  const BtnP(this.label, {super.key, this.onPressed, this.icon, this.couleur = C.vert, this.clair = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color couleur;
  final bool clair;

  @override
  Widget build(BuildContext context) {
    final fg = clair ? C.encre : Colors.white;
    return Material(
      color: clair ? Colors.transparent : couleur,
      shape: StadiumBorder(side: clair ? const BorderSide(color: C.encre, width: 2) : BorderSide.none),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 6)],
              Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lien texte centré (« Annuler ce trajet », « Plus tard »...).
class Lien extends StatelessWidget {
  const Lien(this.label, {super.key, this.onTap, this.couleur = C.vertF, this.souligne = true, this.taille = 14});
  final String label;
  final VoidCallback? onTap;
  final Color couleur;
  final bool souligne;
  final double taille;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: couleur,
          fontSize: taille,
          fontWeight: FontWeight.w700,
          decoration: souligne ? TextDecoration.underline : null,
          decorationColor: couleur,
        ),
      ),
    ),
  );
}

class IconeBtn extends StatelessWidget {
  const IconeBtn({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.bord = false,
    this.taille = 22,
    this.couleur,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool bord;
  final double taille;
  final Color? couleur;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Material(
      color: Colors.transparent,
      shape: CircleBorder(side: bord ? const BorderSide(color: C.trait, width: 2) : BorderSide.none),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: taille, color: onTap == null && bord ? C.trait : couleur),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Petits éléments
// ---------------------------------------------------------------------------

enum TonPastille { neutre, vert, lat, etoile, sos, femmes }

class Pastille extends StatelessWidget {
  const Pastille(
    this.label, {
    super.key,
    this.ton = TonPastille.neutre,
    this.icon,
    this.fond,
    this.texte,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.onTap,
  });
  final String label;
  final TonPastille ton;
  final IconData? icon;
  final Color? fond;
  final Color? texte;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  static (Color, Color) couleurs(TonPastille t) => switch (t) {
    TonPastille.neutre => (C.sable2, C.encre),
    TonPastille.vert => (C.vertC, C.vertF),
    TonPastille.lat => (C.lateriteC, C.lateriteF),
    TonPastille.etoile => (C.etoileC, C.etoileF),
    TonPastille.sos => (C.sosC, C.sosF),
    TonPastille.femmes => (C.femmesC, C.femmesF),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = couleurs(ton);
    final contenu = Padding(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: texte ?? fg), const SizedBox(width: 6)],
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: texte ?? fg),
            ),
          ),
        ],
      ),
    );
    return Material(
      color: fond ?? bg,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? contenu : InkWell(onTap: onTap, child: contenu),
    );
  }
}

/// Puce de choix (filtres, raisons) : latérite quand sélectionnée.
class Puce extends StatelessWidget {
  const Puce(this.label, {super.key, required this.on, required this.onTap, this.tonOn = TonPastille.lat});
  final String label;
  final bool on;
  final VoidCallback onTap;
  final TonPastille tonOn;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: on,
    button: true,
    child: Pastille(
      label,
      ton: on ? tonOn : TonPastille.neutre,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: onTap,
    ),
  );
}

class Ava extends StatelessWidget {
  const Ava(this.initiales, {super.key, this.ton = Ton.lat, this.taille = 46, this.fond, this.texte});
  final String initiales;
  final Ton ton;
  final double taille;
  final Color? fond;
  final Color? texte;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (ton) {
      Ton.lat => (C.lateriteC, C.lateriteF),
      Ton.vert => (C.vertC, C.vertF),
      Ton.etoile => (C.etoileC, C.etoileF),
    };
    return Container(
      width: taille,
      height: taille,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: fond ?? bg, shape: BoxShape.circle),
      child: Text(
        initiales.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Bricolage',
          fontWeight: FontWeight.w800,
          fontSize: taille * .37,
          color: texte ?? fg,
        ),
      ),
    );
  }
}

class NoteEtoile extends StatelessWidget {
  const NoteEtoile(this.note, {super.key, this.couleur});
  final double note;
  final Color? couleur;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Etoile(size: 16),
      const SizedBox(width: 4),
      Text(
        note.toStringAsFixed(1).replaceAll('.', ','),
        style: TextStyle(fontWeight: FontWeight.w700, color: couleur),
      ),
    ],
  );
}

/// « ★ 4,9 · 37 trajets · Corolla grise » qui s'enroule comme un paragraphe.
class LigneNote extends StatelessWidget {
  const LigneNote({super.key, required this.note, required this.suite});
  final double note;
  final String suite;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      style: const TextStyle(fontSize: 13, color: C.doux, height: 1.45),
      children: [
        const WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(padding: EdgeInsets.only(right: 4), child: Etoile(size: 16)),
        ),
        TextSpan(
          text: note.toStringAsFixed(1).replaceAll('.', ','),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.encre),
        ),
        TextSpan(text: suite),
      ],
    ),
  );
}

class Verifie extends StatelessWidget {
  const Verifie({super.key, this.femme = false});
  final bool femme;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.verified_user_outlined, size: 15, color: C.vertF),
      const SizedBox(width: 4),
      Text(
        femme ? 'Vérifiée' : 'Vérifié',
        style: const TextStyle(color: C.vertF, fontWeight: FontWeight.w700, fontSize: 13),
      ),
    ],
  );
}

/// Icône dans un carré arrondi coloré (listes d'opérations, notifications).
class IconeCarre extends StatelessWidget {
  const IconeCarre(this.icon, {super.key, this.fond = C.sable2, this.couleur = C.encre, this.taille = 42});
  final IconData icon;
  final Color fond;
  final Color couleur;
  final double taille;

  @override
  Widget build(BuildContext context) => Container(
    width: taille,
    height: taille,
    decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(14)),
    child: Icon(icon, size: 20, color: couleur),
  );
}

/// Logo d'opérateur (Orange Money, Moov Money, portefeuille, espèces).
class LogoPaiement extends StatelessWidget {
  const LogoPaiement(this.paiement, {super.key});
  final Paiement paiement;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (paiement) {
      Paiement.portefeuille => (C.encre, C.etoile),
      Paiement.orange => (C.orange, C.encre),
      Paiement.moov => (C.moov, Colors.white),
      Paiement.especes => (C.vertC, C.vertF),
    };
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Text(paiement.logo, style: TextStyle(color: fg, fontWeight: FontWeight.w800)),
    );
  }
}

class Anneau extends StatelessWidget {
  const Anneau(this.on, {super.key, this.taille = 24});
  final bool on;
  final double taille;

  @override
  Widget build(BuildContext context) => Container(
    width: taille,
    height: taille,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: on ? C.vert : C.ring, width: on ? 7 : 2),
    ),
  );
}

/// Carte de choix (moyen de paiement, formule, catégorie).
class Choix extends StatelessWidget {
  const Choix({
    super.key,
    required this.on,
    required this.onTap,
    required this.children,
    this.padding = const EdgeInsets.all(14),
    this.anneau = true,
    this.vertical = false,
  });
  final bool on;
  final VoidCallback onTap;
  final List<Widget> children;
  final EdgeInsets padding;
  final bool anneau;
  final bool vertical;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: on,
    button: true,
    child: Material(
      color: on ? C.vertChoix : C.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: on ? C.vert : C.trait, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: vertical
              ? Column(mainAxisSize: MainAxisSize.min, children: children)
              : Row(
                  children: [
                    ...espacer(children, 12),
                    if (anneau) ...[const SizedBox(width: 12), Anneau(on)],
                  ],
                ),
        ),
      ),
    ),
  );
}

class Onglets extends StatelessWidget {
  const Onglets({super.key, required this.labels, required this.index, required this.onChanged});
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(color: C.sable2, borderRadius: BorderRadius.circular(999)),
    child: Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Semantics(
              selected: i == index,
              button: true,
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == index ? C.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: i == index
                        ? const [BoxShadow(color: C.trait, offset: Offset(0, 1))]
                        : null,
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: i == index ? C.encre : C.doux,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class Case extends StatelessWidget {
  const Case({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 30,
    height: 30,
    child: Transform.scale(
      scale: 1.3,
      child: Checkbox(
        value: value,
        onChanged: (v) => onChanged(v ?? false),
        activeColor: C.vert,
        side: const BorderSide(color: C.doux, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    ),
  );
}

/// Ligne avec case à cocher cliquable sur toute sa surface.
class LigneCase extends StatelessWidget {
  const LigneCase({super.key, required this.value, required this.onChanged, required this.child, this.carte = true});
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget child;
  final bool carte;

  @override
  Widget build(BuildContext context) {
    final ligne = Row(
      crossAxisAlignment: carte ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (!carte) ...[Case(value: value, onChanged: onChanged), const SizedBox(width: 12)],
        Expanded(child: child),
        if (carte) ...[const SizedBox(width: 12), Case(value: value, onChanged: onChanged)],
      ],
    );
    if (!carte) {
      return InkWell(onTap: () => onChanged(!value), child: ligne);
    }
    return Carte(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () => onChanged(!value),
      child: ligne,
    );
  }
}

class Etiq extends StatelessWidget {
  const Etiq(this.texte, {super.key});
  final String texte;
  @override
  Widget build(BuildContext context) => Text(texte, style: T.etiq);
}

class Titre extends StatelessWidget {
  const Titre(this.texte, {super.key, this.taille = 26, this.couleur, this.align});
  final String texte;
  final double taille;
  final Color? couleur;
  final TextAlign? align;
  @override
  Widget build(BuildContext context) =>
      Text(texte, textAlign: align, style: T.titre(taille, color: couleur));
}

class Doux extends StatelessWidget {
  const Doux(this.texte, {super.key, this.taille = 13, this.gras = false, this.align});
  final String texte;
  final double taille;
  final bool gras;
  final TextAlign? align;
  @override
  Widget build(BuildContext context) => Text(
    texte,
    textAlign: align,
    style: TextStyle(
      fontSize: taille,
      color: C.doux,
      fontWeight: gras ? FontWeight.w700 : FontWeight.w400,
      height: 1.45,
    ),
  );
}

/// Champ de saisie du thème.
class Champ extends StatelessWidget {
  const Champ({
    super.key,
    this.controller,
    this.hint,
    this.clavier,
    this.lignes = 1,
    this.actif = false,
    this.cache = false,
    this.formatters,
    this.style,
    this.onChanged,
    this.label,
    this.rond = 16,
    this.hauteur,
  });
  final TextEditingController? controller;
  final String? hint;
  final TextInputType? clavier;
  final int lignes;
  final bool actif;
  final bool cache;
  final List<TextInputFormatter>? formatters;
  final TextStyle? style;
  final ValueChanged<String>? onChanged;
  final String? label;
  final double rond;
  final double? hauteur;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder bord(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(rond),
      borderSide: BorderSide(color: c, width: 2),
    );
    final vertical = hauteur == null ? 16.0 : (hauteur! - 24) / 2;
    return Semantics(
      label: label,
      textField: true,
      child: TextField(
        controller: controller,
        keyboardType: clavier,
        maxLines: lignes,
        minLines: lignes,
        obscureText: cache,
        inputFormatters: formatters,
        onChanged: onChanged,
        style: (style ?? const TextStyle()).merge(
          const TextStyle(fontSize: 17, color: C.encre, fontFamily: 'Figtree'),
        ).merge(style),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: C.doux),
          filled: true,
          fillColor: C.surface,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: vertical),
          enabledBorder: bord(actif ? C.vert : C.trait),
          focusedBorder: bord(C.vert),
          border: bord(C.trait),
        ),
      ),
    );
  }
}

/// Saisie d'un code en cases séparées (SMS, code de départ).
class CodeCases extends StatefulWidget {
  const CodeCases({
    super.key,
    required this.controller,
    this.longueur = 6,
    this.hauteur = 62,
    this.taille = 24,
    this.label = 'Code',
    this.onComplet,
    this.autofocus = false,
  });
  final TextEditingController controller;
  final int longueur;
  final double hauteur;
  final double taille;
  final String label;
  final ValueChanged<String>? onComplet;
  final bool autofocus;

  @override
  State<CodeCases> createState() => _CodeCasesState();
}

class _CodeCasesState extends State<CodeCases> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_maj);
    _focus.addListener(_maj);
  }

  void _maj() {
    if (mounted) setState(() {});
    if (widget.controller.text.length == widget.longueur) {
      widget.onComplet?.call(widget.controller.text);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_maj);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.controller.text;
    return SizedBox(
      height: widget.hauteur,
      child: Stack(
        children: [
          Row(
            children: [
              for (var i = 0; i < widget.longueur; i++) ...[
                if (i > 0) SizedBox(width: widget.longueur > 4 ? 8 : 10),
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: C.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _focus.hasFocus && i == t.length.clamp(0, widget.longueur - 1)
                            ? C.vert
                            : C.trait,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      i < t.length ? t[i] : '',
                      style: TextStyle(fontSize: widget.taille, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ],
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                autofocus: widget.autofocus,
                keyboardType: TextInputType.number,
                maxLength: widget.longueur,
                showCursor: false,
                enableInteractiveSelection: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  semanticCounterText: '',
                  labelText: widget.label,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chiffre du code de départ (fond encre, chiffre étoile).
class Chiffre extends StatelessWidget {
  const Chiffre(this.c, {super.key, this.largeur = 58, this.hauteur = 70, this.taille = 38});
  final String c;
  final double largeur;
  final double hauteur;
  final double taille;
  @override
  Widget build(BuildContext context) => Container(
    width: largeur,
    height: hauteur,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: C.encre, borderRadius: BorderRadius.circular(16)),
    child: Text(c, style: T.titre(taille, color: C.etoile)),
  );
}

/// « La route » : départ vert, piste latérite pointillée, arrivée étoile.
class RouteRail extends StatelessWidget {
  const RouteRail({super.key, required this.haut, required this.bas, this.gap = 20, this.voieMin = 26});
  final Widget haut;
  final Widget bas;
  final double gap;
  final double voieMin;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 18,
          child: Column(
            children: [
              const SizedBox(height: 5),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: C.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: C.vert, width: 4),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: voieMin),
                  child: const Pointilles(
                    color: C.laterite,
                    epaisseur: 4,
                    plein: 8,
                    vide: 5,
                    vertical: true,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Etoile(size: 18, color: C.laterite),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [haut, SizedBox(height: gap), bas],
          ),
        ),
      ],
    ),
  );
}

/// Étape d'une frise (validation, réclamation, colis).
enum EtatEtape { fait, encours, afaire }

class Etape extends StatelessWidget {
  const Etape(this.etat, this.titre, this.sous, {super.key, this.icone, this.taille = 30});
  final EtatEtape etat;
  final String titre;
  final String sous;
  final IconData? icone;
  final double taille;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, ic) = switch (etat) {
      EtatEtape.fait => (C.vert, Colors.white, Icons.check_rounded),
      EtatEtape.encours => (C.etoile, C.encre, icone ?? Icons.schedule_rounded),
      EtatEtape.afaire => (C.sable2, C.doux, null),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: taille,
            height: taille,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: ic == null ? null : Icon(ic, size: 17, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre, style: T.gras),
                const SizedBox(height: 4),
                Text(sous, style: T.petit.copyWith(color: C.doux)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compteur − valeur + (places).
class Compteur extends StatelessWidget {
  const Compteur({
    super.key,
    required this.valeur,
    required this.onMoins,
    required this.onPlus,
    this.texte,
    this.largeurTexte = 22,
    this.grand = true,
  });
  final int valeur;
  final VoidCallback? onMoins;
  final VoidCallback? onPlus;
  final String? texte;
  final double largeurTexte;
  final bool grand;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconeBtn(icon: Icons.remove_rounded, label: 'Une place de moins', bord: true, onTap: onMoins, taille: 20),
      const SizedBox(width: 8),
      SizedBox(
        width: largeurTexte,
        child: Text(
          texte ?? '$valeur',
          textAlign: TextAlign.center,
          style: grand ? T.titre(20) : T.gras,
        ),
      ),
      const SizedBox(width: 8),
      IconeBtn(icon: Icons.add_rounded, label: 'Une place de plus', bord: true, onTap: onPlus, taille: 20),
    ],
  );
}

/// Bandeau d'information coloré (vert, jaune, rouge).
class Bandeau extends StatelessWidget {
  const Bandeau(this.texte, {super.key, this.icon = Icons.verified_user_outlined, this.ton = TonPastille.vert, this.riche});
  final String texte;
  final IconData icon;
  final TonPastille ton;
  final InlineSpan? riche;

  @override
  Widget build(BuildContext context) {
    final (bg, bord) = switch (ton) {
      TonPastille.vert => (C.vertC, const Color(0xFFA9D3B7)),
      TonPastille.etoile => (C.etoileC, const Color(0xFFEBCF7C)),
      TonPastille.sos => (C.sosC, C.sosBord),
      _ => (C.surface, C.trait),
    };
    return Carte(
      couleur: bg,
      bord: bord,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: riche != null
                ? Text.rich(riche!, style: T.petit)
                : Text(texte, style: T.petit),
          ),
        ],
      ),
    );
  }
}

/// Navigation du bas (passager ou conducteur).
class NavItem {
  const NavItem(this.icon, this.label, {this.badge = 0});
  final IconData icon;
  final String label;
  final int badge;
}

class NavBas extends StatelessWidget {
  const NavBas({super.key, required this.items, required this.index, required this.onTap});
  final List<NavItem> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(4, 8, 4, 14 + MediaQuery.paddingOf(context).bottom),
    decoration: const BoxDecoration(
      color: C.surface,
      border: Border(top: BorderSide(color: C.trait, width: 1.5)),
    ),
    child: Row(
      children: [
        for (var i = 0; i < items.length; i++)
          Expanded(
            child: Semantics(
              selected: i == index,
              button: true,
              label: items[i].label,
              excludeSemantics: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onTap(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Badge(
                        isLabelVisible: items[i].badge > 0,
                        label: Text('${items[i].badge}'),
                        backgroundColor: C.vert,
                        child: Container(
                          width: 56,
                          height: 30,
                          decoration: BoxDecoration(
                            color: i == index ? C.lateriteC : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Icon(items[i].icon, size: 22, color: i == index ? C.lateriteF : C.doux),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[i].label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: i == index ? FontWeight.w800 : FontWeight.w600,
                          color: i == index ? C.lateriteF : C.doux,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// Billet de gare routière : partie haute, coupe à encoches, partie basse.
class Billet extends StatelessWidget {
  const Billet({super.key, required this.haut, required this.bas});
  final Widget haut;
  final Widget bas;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: C.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: C.trait, width: 1.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(padding: const EdgeInsets.all(18), child: haut),
        SizedBox(
          height: 2,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned(left: 18, right: 18, top: 0, child: Pointilles(epaisseur: 2, plein: 6, vide: 5)),
              for (final gauche in [true, false])
                Positioned(
                  left: gauche ? -13.5 : null,
                  right: gauche ? null : -13.5,
                  top: -12,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: C.sable,
                      shape: BoxShape.circle,
                      border: Border.all(color: C.trait, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(padding: const EdgeInsets.all(18), child: bas),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Retours utilisateur
// ---------------------------------------------------------------------------

void message(BuildContext context, String texte) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texte)));
}

/// Exécute une action métier et affiche son erreur éventuelle.
bool essayer(BuildContext context, void Function() action) {
  try {
    action();
    return true;
  } on ErreurMetier catch (e) {
    message(context, e.message);
    return false;
  }
}

Future<bool> confirmer(
  BuildContext context, {
  required String titre,
  required String texte,
  String oui = 'Confirmer',
  String non = 'Retour',
  bool danger = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(titre, style: T.titre(22)),
      content: Text(texte, style: T.corps),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            danger
                ? Btn.sos(oui, hauteur: 52, onPressed: () => Navigator.pop(c, true))
                : Btn(oui, hauteur: 52, onPressed: () => Navigator.pop(c, true)),
            const SizedBox(height: 10),
            BtnClair(non, onPressed: () => Navigator.pop(c, false)),
          ],
        ),
      ],
    ),
  );
  return r ?? false;
}

Future<void> informer(BuildContext context, String titre, String texte) => showDialog<void>(
  context: context,
  builder: (c) => AlertDialog(
    title: Text(titre, style: T.titre(22)),
    content: Text(texte, style: T.corps),
    actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
    actions: [Btn('Compris', hauteur: 52, onPressed: () => Navigator.pop(c))],
  ),
);

Future<R?> ouvrir<R>(BuildContext context, Widget ecran) =>
    Navigator.of(context).push<R>(MaterialPageRoute(builder: (_) => ecran));

Future<R?> remplacer<R>(BuildContext context, Widget ecran) =>
    Navigator.of(context).pushReplacement<R, void>(MaterialPageRoute(builder: (_) => ecran));

void retourAccueil(BuildContext context) =>
    Navigator.of(context).popUntil((r) => r.isFirst);
