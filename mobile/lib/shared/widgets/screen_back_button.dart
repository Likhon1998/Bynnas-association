import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

/// Back control that only shows when the route stack can pop.
class ScreenBackButton extends StatelessWidget {
  const ScreenBackButton({super.key, this.fallback});

  final String? fallback;

  @override
  Widget build(BuildContext context) {
    final canPop = context.canPop();
    if (!canPop && fallback == null) {
      return const SizedBox(width: 8);
    }

    return IconButton(
      onPressed: () {
        if (canPop) {
          context.pop();
        } else if (fallback != null) {
          context.go(fallback!);
        }
      },
      icon: const Icon(Icons.arrow_back_rounded),
      color: AppColors.navy,
    );
  }
}
