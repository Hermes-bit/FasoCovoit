import 'package:flutter/material.dart';

/// Couleurs du thème « Latérite et drapeau » (reprises de la maquette).
abstract final class C {
  static const sable = Color(0xFFF3E7D3);
  static const sable2 = Color(0xFFEADBC2);
  static const surface = Color(0xFFFFFBF3);
  static const trait = Color(0xFFE2CDAE);
  static const encre = Color(0xFF2A1A12);
  static const encre2 = Color(0xFF3D2A1F);
  static const doux = Color(0xFF6E5646);
  static const beige = Color(0xFFF0E4D4);
  static const beige2 = Color(0xFFD9C7B0);
  static const ring = Color(0xFFC9B496);

  static const laterite = Color(0xFFB5532A);
  static const lateriteF = Color(0xFF8E3D1C);
  static const lateriteC = Color(0xFFF6DCCB);

  static const vert = Color(0xFF0E7A3E);
  static const vertF = Color(0xFF0A5C2E);
  static const vertC = Color(0xFFDCEFE2);
  static const vertChoix = Color(0xFFF3FAF5);

  static const etoile = Color(0xFFF2B705);
  static const etoileC = Color(0xFFFCEBB8);
  static const etoileF = Color(0xFF7A5A00);

  static const sos = Color(0xFFC4161C);
  static const sosF = Color(0xFF8F0F14);
  static const sosC = Color(0xFFFBE0DF);
  static const sosBord = Color(0xFFF0B9B7);

  static const femmesC = Color(0xFFF4E1EC);
  static const femmesF = Color(0xFF7A1F55);

  static const orange = Color(0xFFFF7900);
  static const moov = Color(0xFF0057A8);
}

/// Styles de texte. `titre` = Bricolage Grotesque, le reste = Figtree.
abstract final class T {
  static TextStyle titre(double size, {Color? color}) => TextStyle(
    fontFamily: 'Bricolage',
    fontWeight: FontWeight.w800,
    fontSize: size,
    height: 1.1,
    letterSpacing: -0.02 * size,
    color: color,
  );

  static const corps = TextStyle(
    fontFamily: 'Figtree',
    fontSize: 16,
    height: 1.35,
    color: C.encre,
  );
  static const petit = TextStyle(fontSize: 14);
  static const mini = TextStyle(fontSize: 13);
  static const gras = TextStyle(fontWeight: FontWeight.w700);
  static const etiq = TextStyle(fontSize: 14, fontWeight: FontWeight.w700);
}

ThemeData construireTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Figtree',
    scaffoldBackgroundColor: C.sable,
    colorScheme: ColorScheme.fromSeed(
      seedColor: C.laterite,
      primary: C.vert,
      secondary: C.laterite,
      surface: C.surface,
      error: C.sos,
    ),
    splashFactory: InkRipple.splashFactory,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: C.encre,
      displayColor: C.encre,
      fontFamily: 'Figtree',
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: C.laterite,
      inactiveTrackColor: C.trait,
      thumbColor: C.laterite,
      overlayColor: Color(0x22B5532A),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: C.encre,
      behavior: SnackBarBehavior.floating,
      contentTextStyle: TextStyle(
        fontFamily: 'Figtree',
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: C.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: C.surface,
      showDragHandle: true,
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: C.vert),
  );
}
