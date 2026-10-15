import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Living brand wash — soft ribbons + drifting orbs behind content.
class BrandAtmosphere extends StatefulWidget {
  const BrandAtmosphere({
    super.key,
    required this.child,
    this.intense = false,
  });

  final Widget child;
  final bool intense;

  @override
  State<BrandAtmosphere> createState() => _BrandAtmosphereState();
}

class _BrandAtmosphereState extends State<BrandAtmosphere>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intensity = widget.intense ? 1.15 : 1.0;

    return ColoredBox(
      color: AppColors.page,
      child: AnimatedBuilder(
        animation: _drift,
        builder: (context, child) {
          final t = _drift.value;
          final sway = math.sin(t * math.pi) * 18;

          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.heroWash),
              ),
              Positioned(
                top: -110 + sway * 0.35,
                right: -80 - sway * 0.4,
                child: _Orb(
                  width: 300 * intensity,
                  height: 260 * intensity,
                  colors: [
                    AppColors.lavendar.withValues(alpha: 0.45),
                    AppColors.softBlue.withValues(alpha: 0.18),
                  ],
                ),
              ),
              Positioned(
                top: 70 - sway * 0.25,
                right: -10 + sway * 0.5,
                child: _Orb(
                  width: 170 * intensity,
                  height: 150 * intensity,
                  colors: [
                    AppColors.blue.withValues(alpha: 0.16),
                    AppColors.lavendar.withValues(alpha: 0.08),
                  ],
                ),
              ),
              Positioned(
                bottom: -140 - sway * 0.3,
                left: -100 + sway * 0.45,
                child: _Orb(
                  width: 360 * intensity,
                  height: 300 * intensity,
                  colors: [
                    AppColors.magenta.withValues(alpha: 0.14),
                    AppColors.blue.withValues(alpha: 0.18),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.magenta.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(child: child!),
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
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
