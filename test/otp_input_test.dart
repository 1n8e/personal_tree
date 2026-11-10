import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:personal_tree/data/app_state.dart';
import 'package:personal_tree/features/auth/login_screen.dart';

/// Код из SMS вводится с клавиатуры: только цифры, не больше 4, после чего «Войти» логинит.
void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('OTP принимает ввод с клавиатуры', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.enterText(find.byType(TextField), '+7 701 123 45 78');
    await tester.tap(find.text('Продолжить'));
    // Ждём, пока закончится переход между шагами.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    final otp = find.byType(TextField);
    expect(otp, findsOneWidget);
    expect(tester.widget<TextField>(otp).focusNode!.hasFocus, isTrue);

    await tester.enterText(otp, '12a3456');
    await tester.pump();
    expect(tester.widget<TextField>(otp).controller!.text, '1234');
    for (final d in ['1', '2', '3', '4']) {
      expect(find.text(d), findsOneWidget);
    }

    await tester.tap(find.text('Войти'));
    await tester.pump();
    expect(container.read(appControllerProvider).isLoggedIn, isTrue);
    tester.takeException();
  });
}
