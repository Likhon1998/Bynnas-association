import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/mobile_preview_frame.dart';

class BynnasApp extends ConsumerWidget {
  const BynnasApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Bynnas Association',
      theme: AppTheme.light(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MobilePreviewFrame(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
