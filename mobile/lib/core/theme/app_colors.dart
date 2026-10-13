import 'package:flutter/material.dart';

/// Brand colors matching the approved Bynnas login design.
class AppColors {
  const AppColors._();

  static const navy = Color(0xFF0D1B3E);
  static const textPrimary = Color(0xFF0D1B3E);
  static const textMuted = Color(0xFF7E8494);
  static const fieldBorder = Color(0xFFE4E7EE);
  static const fieldFill = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const page = Color(0xFFFFFFFF);
  static const accent = Color(0xFF7B5CFF);
  static const magenta = Color(0xFFFF2D8A);
  static const blue = Color(0xFF3B6CFF);
  static const lavendar = Color(0xFFC9B8FF);
  static const softBlue = Color(0xFFB7D0FF);
  static const danger = Color(0xFFD64545);

  /// Kept as aliases so older screens keep compiling while branding migrates.
  static const ink = navy;
  static const inkSoft = Color(0xFF243B6B);
  static const brass = accent;
  static const brassDeep = accent;
  static const linen = page;
  static const mist = Color(0xFFF5F7FF);
  static const cream = Color(0xFFFFFFFF);

  static const brandGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [magenta, blue],
  );

  static const logoGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [magenta, blue],
  );
}
