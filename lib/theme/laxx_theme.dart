import 'package:flutter/material.dart';

class Laxx {
  static const bg = Color(0xFF0B0E14);
  static const surface = Color(0xFF141A24);
  static const surfaceHi = Color(0xFF1C2431);
  static const border = Color(0xFF2A3446);
  static const accent = Color(0xFF00E0C6);
  static const accent2 = Color(0xFF7C5CFF);
  static const danger = Color(0xFFFF4D6D);
  static const warn = Color(0xFFFFB84D);
  static const ok = Color(0xFF3DDC84);
  static const text = Color(0xFFE6EDF7);
  static const muted = Color(0xFF8A96AB);

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
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          foregroundColor: text,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: text),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: text),
          bodyMedium: TextStyle(fontSize: 14, color: text),
          bodySmall: TextStyle(fontSize: 12, color: muted),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          hintStyle: const TextStyle(color: muted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
