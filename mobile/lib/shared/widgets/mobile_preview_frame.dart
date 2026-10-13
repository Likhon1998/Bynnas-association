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

    return ColoredBox(
      color: const Color(0xFF2A2F2C),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              const SizedBox(height: 12),
              Text(
                'Mobile preview · ${phoneSize.width.toInt()}×${phoneSize.height.toInt()}',
                style: const TextStyle(
                  color: Color(0xFFB8C2BB),
                  fontSize: 12,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: _PhoneShell(child: child),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        },
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
      width: MobilePreviewFrame.phoneSize.width + 18,
      height: MobilePreviewFrame.phoneSize.height + 18,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFF111513),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFF3D4540), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: SizedBox(
          width: MobilePreviewFrame.phoneSize.width,
          height: MobilePreviewFrame.phoneSize.height,
          child: MediaQuery(
            data: hostMedia.copyWith(
              size: MobilePreviewFrame.phoneSize,
              padding: const EdgeInsets.fromLTRB(0, 36, 0, 18),
              viewPadding: const EdgeInsets.fromLTRB(0, 36, 0, 18),
              viewInsets: EdgeInsets.zero,
              devicePixelRatio: hostMedia.devicePixelRatio,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                child,
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        width: 118,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.ink.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        width: 120,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.ink.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
