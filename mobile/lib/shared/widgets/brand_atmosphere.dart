import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Soft purple/blue wave atmosphere from the approved login design.
class BrandAtmosphere extends StatelessWidget {
  const BrandAtmosphere({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.page,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _Blob(
              width: 280,
              height: 240,
              colors: [
                AppColors.lavendar.withValues(alpha: 0.55),
                AppColors.softBlue.withValues(alpha: 0.35),
              ],
            ),
          ),
          Positioned(
            top: 40,
            right: -20,
            child: _Blob(
              width: 160,
              height: 140,
              colors: [
                AppColors.softBlue.withValues(alpha: 0.40),
                AppColors.lavendar.withValues(alpha: 0.20),
              ],
            ),
          ),
          Positioned(
            bottom: -120,
            left: -90,
            child: _Blob(
              width: 340,
              height: 280,
              colors: [
                AppColors.magenta.withValues(alpha: 0.22),
                AppColors.blue.withValues(alpha: 0.28),
              ],
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.width,
    required this.height,
    required this.colors,
  });

  final double width;
  final double height;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: colors,
            center: Alignment.center,
            radius: 0.85,
          ),
        ),
      ),
    );
  }
}
