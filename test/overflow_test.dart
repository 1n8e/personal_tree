import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:personal_tree/app/router.dart';
import 'package:personal_tree/data/app_state.dart';
import 'package:personal_tree/data/models.dart';
import 'package:personal_tree/main.dart';

/// Прогоняет все экраны на узком телефоне и с крупным шрифтом
/// и падает только на ошибках раскладки (overflow), а не на сети/шрифтах.
void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  const sizes = [Size(320, 640), Size(390, 844)];
  const scales = [1.0, 1.3];

  final routes = <String, String Function(AppState)>{
    'splash': (_) => Routes.splash,
    'home': (_) => Routes.home,
    'catalog': (_) => Routes.catalog,
    'purchase': (_) => Routes.purchase('elm'),
    'nameTree': (_) => Routes.nameTree('elm', quantity: 2, mode: PaymentMode.installments, installment: 2000),
    'orderSuccess': (s) => Routes.orderSuccess(s.orders.first.id),
    'forest': (_) => Routes.forest,
    'tree awaiting': (_) => Routes.tree('t3'),
    'tree planted': (_) => Routes.tree('t1'),
    'tree growing': (_) => Routes.tree('t4'),
    'growth': (_) => Routes.growth('t4'),
    'growthDone': (_) => Routes.growthDone('t1'),
    'confirmPlanting': (_) => Routes.confirmPlanting('t3'),
    'map': (_) => Routes.map,
    'profile': (_) => Routes.profile,
    'orders': (_) => Routes.orders,
    'achievements': (_) => Routes.achievements,
  };

  for (final size in sizes) {
    for (final scale in scales) {
      for (final MapEntry(key: name, value: path) in routes.entries) {
        testWidgets('$name ${size.width.toInt()}×${size.height.toInt()} ×$scale', (tester) async {
          await _expectNoOverflow(tester, size, scale, path);
        });
      }
      for (final name in ['onboarding', 'login']) {
        testWidgets('$name ${size.width.toInt()}×${size.height.toInt()} ×$scale', (tester) async {
          await _expectNoOverflow(tester, size, scale, (_) => '/$name', loggedIn: false);
        });
      }
    }
  }
}

Future<void> _expectNoOverflow(
  WidgetTester tester,
  Size size,
  double scale,
  String Function(AppState) path, {
  bool loggedIn = true,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final overflows = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    final text = details.exceptionAsString();
    if (text.contains('overflowed')) overflows.add(text.split('\n').first);
  };

  final container = ProviderContainer();
  addTearDown(container.dispose);
  if (loggedIn) {
    container.read(appControllerProvider.notifier).loginDemo();
  } else {
    container.read(appControllerProvider.notifier).completeOnboarding();
  }
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const PersonalTreeApp()));
  container.read(routerProvider).go(path(container.read(appControllerProvider)));
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  // Убираем дерево до окончания теста, чтобы бесконечные анимации не мешали.
  await tester.pumpWidget(const SizedBox());
  FlutterError.onError = previous;
  // Ошибки шрифтов и тайлов карты в тестах ожидаемы (нет сети).
  tester.takeException();

  expect(overflows, isEmpty, reason: overflows.toSet().join('\n'));
}

