import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Canonical palette tokens for TREEMATO.
class TM {
  TM._();

  static const ink = Color(0xFF0E0D0C); // paper-black
  static const ink2 = Color(0xFF1A1917);
  static const cream = Color(0xFFF5ECD7); // bone-cream
  static const cream2 = Color(0xFFEFE3C2);
  static const tomato = Color(0xFFFF3B2F);
  static const tomato2 = Color(0xFFD92A20);
  static const lemon = Color(0xFFFFD23F);
  static const cobalt = Color(0xFF2F6BFF);
  static const mint = Color(0xFF9BE3C3);
  static const dim = Color(0xFF3A3632);
  static const dim2 = Color(0xFF2A2724);
}

class TMText {
  TMText._();

  static TextStyle display({
    double fontSize = 48,
    Color color = TM.cream,
    double letterSpacing = -1,
    double? height,
  }) {
    return GoogleFonts.archivoBlack(
      fontSize: fontSize,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle ui({
    double fontSize = 14,
    Color color = TM.cream,
    FontWeight weight = FontWeight.w500,
    double letterSpacing = 0,
    double? height,
  }) {
    return GoogleFonts.spaceGrotesk(
      fontSize: fontSize,
      color: color,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle marker({
    double fontSize = 22,
    Color color = TM.cream,
    FontWeight weight = FontWeight.w700,
    double? height,
  }) {
    return GoogleFonts.caveat(
      fontSize: fontSize,
      color: color,
      fontWeight: weight,
      height: height,
    );
  }
}

ThemeData buildTreematoTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: TM.ink,
    colorScheme: const ColorScheme.dark(
      surface: TM.ink,
      onSurface: TM.cream,
      primary: TM.tomato,
      onPrimary: TM.cream,
      secondary: TM.lemon,
      onSecondary: TM.ink,
    ),
    textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme)
        .apply(bodyColor: TM.cream, displayColor: TM.cream),
  );
}
