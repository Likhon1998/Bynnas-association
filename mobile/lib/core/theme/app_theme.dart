import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final base = GoogleFonts.plusJakartaSansTextTheme();
    final textTheme = base.copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
        color: AppColors.navy,
        fontWeight: FontWeight.w800,
        fontSize: 40,
        height: 1.05,
        letterSpacing: -0.8,
      ),
      headlineLarge: GoogleFonts.plusJakartaSans(
        color: AppColors.navy,
        fontWeight: FontWeight.w800,
        fontSize: 32,
        height: 1.1,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        color: AppColors.navy,
        fontWeight: FontWeight.w800,
        fontSize: 26,
        height: 1.12,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        color: AppColors.navy,
        fontWeight: FontWeight.w800,
        fontSize: 22,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        color: AppColors.navy,
        fontWeight: FontWeight.w800,
        fontSize: 20,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        color: AppColors.navy,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        color: AppColors.navy,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
        fontSize: 15,
        height: 1.45,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w500,
        fontSize: 14,
        height: 1.45,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w500,
        fontSize: 12.5,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        fontSize: 15,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w600,
        fontSize: 12,
        letterSpacing: 0.2,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.light,
        primary: AppColors.accent,
        onPrimary: Colors.white,
        secondary: AppColors.blue,
        surface: AppColors.surface,
        onSurface: AppColors.navy,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.page,
      textTheme: textTheme,
      dividerColor: AppColors.fieldBorder,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.navy,
        titleTextStyle: textTheme.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fieldFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: textTheme.bodyMedium,
        labelStyle: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.w700,
        ),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.blue,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.navyDeep,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        height: 68,
        indicatorColor: AppColors.accent.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.plusJakartaSans(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 11.5,
            color: selected ? AppColors.navy : AppColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 23,
            color: selected ? AppColors.magenta : AppColors.textMuted,
          );
        }),
      ),
    );
  }
}
