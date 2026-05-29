import 'package:flutter/material.dart';

class AppTheme {
  static const _seedColor = Color(0xFF6B8F71); // 森林绿
  static const _warmBrown = Color(0xFFC4956A); // 暖木色

  // ── Light Theme ──
  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
      secondary: _warmBrown,
    );
    return _buildTheme(scheme, Brightness.light);
  }

  // ── Dark Theme ──
  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
      secondary: const Color(0xFFD4A87C),
    );
    return _buildTheme(scheme, Brightness.dark);
  }

  static ThemeData _buildTheme(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,

      // ── Typography ──
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.5,
          color: scheme.onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: scheme.onSurface.withAlpha(220),
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.4,
          color: scheme.onSurface.withAlpha(180),
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: scheme.onSurface,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          letterSpacing: 0.5,
          color: scheme.onSurface.withAlpha(180),
        ),
      ),

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),

      // ── Card ──
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: scheme.outlineVariant.withAlpha(isDark ? 40 : 60),
          ),
        ),
      ),

      // ── Input ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withAlpha(isDark ? 80 : 120),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant.withAlpha(80)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ── ElevatedButton ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // ── OutlinedButton ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),

      // ── FilledButton (tonal) ──
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      // ── FAB ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 4,
      ),

      // ── Chip ──
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: BorderSide.none,
        backgroundColor: scheme.surfaceContainerHighest,
        labelStyle: TextStyle(
          fontSize: 13,
          color: scheme.onSurface.withAlpha(200),
        ),
      ),

      // ── NavigationBar (mobile bottom nav) ──
      navigationBarTheme: NavigationBarThemeData(
        elevation: 1,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            );
          }
          return TextStyle(
            fontSize: 11,
            color: scheme.onSurface.withAlpha(160),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: scheme.primary, size: 24);
          }
          return IconThemeData(
            color: scheme.onSurface.withAlpha(160),
            size: 24,
          );
        }),
      ),

      // ── NavigationRail (desktop sidebar) ──
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        selectedIconTheme: IconThemeData(color: scheme.primary),
        selectedLabelTextStyle: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedIconTheme: IconThemeData(
          color: scheme.onSurface.withAlpha(160),
        ),
        unselectedLabelTextStyle: TextStyle(
          color: scheme.onSurface.withAlpha(160),
          fontSize: 12,
        ),
        indicatorColor: scheme.primaryContainer.withAlpha(120),
      ),

      // ── Divider ──
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withAlpha(60),
        thickness: 1,
      ),

      // ── TabBar ──
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurface.withAlpha(160),
        indicatorColor: scheme.primary,
        dividerColor: Colors.transparent,
      ),

      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
