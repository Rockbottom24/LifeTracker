import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: const Color(0xFFDBEAFE),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(fontWeight: FontWeight.w600);
            }
            return const TextStyle(fontWeight: FontWeight.w500);
          }),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF020617),
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      );
}
