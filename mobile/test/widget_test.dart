import 'package:bynnas_association/app.dart';
import 'package:bynnas_association/features/auth/domain/auth_user.dart';
import 'package:bynnas_association/features/auth/presentation/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _GuestAuthController extends AuthController {
  @override
  Future<AuthUser?> build() async => null;
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('login screen renders branded association identity', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_GuestAuthController.new),
        ],
        child: const BynnasApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Bynnas'), findsOneWidget);
    expect(find.text('ASSOCIATION'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
