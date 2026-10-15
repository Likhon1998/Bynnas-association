import 'package:flutter/material.dart';

/// Bynnas brand palette — navy + magenta→blue ribbon.
class AppColors {
  const AppColors._();

  static const navy = Color(0xFF0B1A3A);
  static const navyDeep = Color(0xFF061228);
  static const textPrimary = Color(0xFF0B1A3A);
  static const textMuted = Color(0xFF5A6275);
  static const fieldBorder = Color(0xFFD8DDE8);
  static const fieldFill = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const page = Color(0xFFF7F8FC);
  static const accent = Color(0xFF6E56CF);
  static const magenta = Color(0xFFE11D74);
  static const blue = Color(0xFF2F6BFF);
  static const lavendar = Color(0xFFD4C6FF);
  static const softBlue = Color(0xFFBFD4FF);
  static const success = Color(0xFF0F7A45);
  static const warning = Color(0xFFB76E00);
  static const danger = Color(0xFFD64545);
  static const mist = Color(0xFFEEF1FA);

  /// Kept as aliases so older screens keep compiling while branding migrates.
  static const ink = navy;
  static const inkSoft = Color(0xFF243B6B);
  static const brass = accent;
  static const brassDeep = accent;
  static const linen = page;
  static const cream = Color(0xFFFFFFFF);

  static const brandGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [magenta, blue],
  );

  static const brandDiagonal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF2D8A), Color(0xFF7B5CFF), Color(0xFF3B6CFF)],
  );

  static const logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [magenta, blue],
  );

  static const heroWash = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF4F6FC)],
  );

  static const metricGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF5F3FF)],
  );
}
