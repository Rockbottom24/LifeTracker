import 'package:flutter/material.dart';

import '../theme/house_theme.dart';
import 'app_style.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData lightTheme({required AppStyle style, required String? houseKey}) {
    return _buildTheme(
      brightness: Brightness.light,
      style: style,
      house: HouseTheme.fromKey(houseKey),
    );
  }

  static ThemeData darkTheme({required AppStyle style, required String? houseKey}) {
    return _buildTheme(
      brightness: Brightness.dark,
      style: style,
      house: HouseTheme.fromKey(houseKey),
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required AppStyle style,
    required HouseTheme house,
  }) {
    final isDark = brightness == Brightness.dark;
    final houseAccent = house.accent;
    final seed = switch (style) {
      AppStyle.classic => const Color(0xFFB3A37A),
      AppStyle.fantasy => houseAccent,
      AppStyle.system => isDark ? houseAccent : const Color(0xFF9B7A56),
    };

    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      primary: style == AppStyle.classic ? const Color(0xFFC4B28B) : houseAccent,
      secondary: style == AppStyle.fantasy ? const Color(0xFFB57A4A) : const Color(0xFF8A98A9),
      tertiary: houseAccent.withValues(alpha: isDark ? 0.92 : 0.82),
    ).copyWith(
      surface: isDark ? const Color(0xFF0B0D10) : const Color(0xFFF5F1E8),
      onSurface: isDark ? const Color(0xFFF2ECE3) : const Color(0xFF191613),
      surfaceContainerLowest: isDark ? const Color(0xFF11151A) : const Color(0xFFF9F6F0),
      surfaceContainerLow: isDark ? const Color(0xFF151A20) : const Color(0xFFF1ECE4),
      surfaceContainer: isDark ? const Color(0xFF1B2129) : const Color(0xFFE8E0D4),
      surfaceContainerHigh: isDark ? const Color(0xFF242B34) : const Color(0xFFD9CDBA),
      surfaceContainerHighest: isDark ? const Color(0xFF2D3641) : const Color(0xFFCBBBA5),
      outline: isDark ? const Color(0xFF5D6672) : const Color(0xFF907D68),
      outlineVariant: isDark ? const Color(0xFF343E49) : const Color(0xFFC4B59F),
      shadow: Colors.black,
      scrim: Colors.black,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
    );

    final serif = base.textTheme.copyWith(
      headlineLarge: _serif(base.textTheme.headlineLarge),
      headlineMedium: _serif(base.textTheme.headlineMedium),
      headlineSmall: _serif(base.textTheme.headlineSmall),
      titleLarge: _serif(base.textTheme.titleLarge),
      titleMedium: _serif(base.textTheme.titleMedium),
      titleSmall: _serif(base.textTheme.titleSmall),
    );

    return base.copyWith(
      scaffoldBackgroundColor: isDark ? const Color(0xFF090B0E) : const Color(0xFFF4EFE5),
      textTheme: serif.copyWith(
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          color: scheme.onSurface,
          height: 1.45,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface,
          height: 1.4,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: serif.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF0F1216) : const Color(0xFFF0E8DB),
        indicatorColor: houseAccent.withValues(alpha: isDark ? 0.24 : 0.16),
        labelTextStyle: WidgetStatePropertyAll(
          serif.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? const Color(0xFF11161C) : const Color(0xFFF8F3EA),
        shadowColor: Colors.black.withValues(alpha: 0.24),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: houseAccent.withValues(alpha: isDark ? 0.18 : 0.22)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF12161B) : const Color(0xFFF8F3EA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF12161B) : const Color(0xFFF8F4EB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: houseAccent.withValues(alpha: 0.18)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: houseAccent.withValues(alpha: 0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: houseAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: houseAccent,
          foregroundColor: isDark ? const Color(0xFF090B0E) : const Color(0xFF101214),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: houseAccent.withValues(alpha: 0.45)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: houseAccent,
        foregroundColor: isDark ? const Color(0xFF090B0E) : const Color(0xFF101214),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  static TextStyle? _serif(TextStyle? style) {
    return style?.copyWith(
      fontFamily: 'Georgia',
      letterSpacing: -0.2,
    );
  }
}
