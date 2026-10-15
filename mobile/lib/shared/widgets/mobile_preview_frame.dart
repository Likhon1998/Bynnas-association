import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// On web/desktop browsers, show the app inside a phone-sized frame
/// so the layout matches a real mobile device.
class MobilePreviewFrame extends StatelessWidget {
  const MobilePreviewFrame({
    super.key,
    required this.child,
  });

  final Widget child;

  static const Size phoneSize = Size(390, 844);

  static bool get enabled {
    if (kIsWeb) {
      return true;
    }
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B1224),
            Color(0xFF1A1030),
            Color(0xFF0E1A36),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -40,
            child: _Glow(color: AppColors.magenta.withValues(alpha: 0.22)),
          ),
          Positioned(
            bottom: -60,
            right: -30,
            child: _Glow(color: AppColors.blue.withValues(alpha: 0.22)),
          ),
          Column(
            children: [
              const SizedBox(height: 18),
              Text(
                'Bynnas Association',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mobile preview',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.38),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: _PhoneShell(child: child),
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _PhoneShell extends StatelessWidget {
  const _PhoneShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final hostMedia = MediaQuery.of(context);

    return Container(
      width: MobilePreviewFrame.phoneSize.width + 20,
      height: MobilePreviewFrame.phoneSize.height + 20,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A3142), Color(0xFF141820)],
        ),
        borderRadius: BorderRadius.circular(42),
        border: Border.all(color: const Color(0xFF4A5368), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 48,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: SizedBox(
          width: MobilePreviewFrame.phoneSize.width,
          height: MobilePreviewFrame.phoneSize.height,
          child: MediaQuery(
            data: hostMedia.copyWith(
              size: MobilePreviewFrame.phoneSize,
              padding: EdgeInsets.zero,
              viewPadding: EdgeInsets.zero,
              viewInsets: EdgeInsets.zero,
              devicePixelRatio: hostMedia.devicePixelRatio,
            ),
            child: ColoredBox(
              color: AppColors.page,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
