import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Laxx {
  static const bg = Color(0xFF07090F);
  static const surface = Color(0xFF111724);
  static const surfaceHi = Color(0xFF1A2233);
  static const border = Color(0xFF26314A);
  static const accent = Color(0xFF00F0D0);
  static const accent2 = Color(0xFF8B5CFF);
  static const danger = Color(0xFFFF4D6D);
  static const warn = Color(0xFFFFB84D);
  static const ok = Color(0xFF3DDC84);
  static const text = Color(0xFFEAF0FA);
  static const muted = Color(0xFF8C97AD);

  static TextTheme get _text => TextTheme(
        headlineMedium: GoogleFonts.sairaStencilOne(
            fontSize: 30, color: text, letterSpacing: 3),
        titleLarge: GoogleFonts.sairaStencilOne(
            fontSize: 20, color: text, letterSpacing: 1.5),
        titleMedium: GoogleFonts.sairaStencilOne(
            fontSize: 16, color: text, letterSpacing: 1),
        labelLarge: GoogleFonts.sairaStencilOne(
            fontSize: 15, color: text, letterSpacing: 1),
        bodyMedium: GoogleFonts.rajdhani(
            fontSize: 16, height: 1.3, color: text, fontWeight: FontWeight.w600),
        bodySmall: GoogleFonts.rajdhani(
            fontSize: 13, color: muted, fontWeight: FontWeight.w500),
      );

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
          primary: accent,
          secondary: accent2,
          surface: surface,
          error: danger,
        ),
        textTheme: _text,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: text,
          elevation: 0,
          titleTextStyle: GoogleFonts.sairaStencilOne(
              fontSize: 20, color: text, letterSpacing: 1.5),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          hintStyle: GoogleFonts.rajdhani(color: muted, fontSize: 15),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: accent, width: 1.5),
          ),
        ),
      );
}
