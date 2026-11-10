import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:personal_tree/app/router.dart';
import 'package:personal_tree/data/app_state.dart';
import 'package:personal_tree/features/catalog/catalog_screen.dart';
import 'package:personal_tree/features/forest/forest_screen.dart';
import 'package:personal_tree/features/home/home_screen.dart';
import 'package:personal_tree/features/map/map_screen.dart';
import 'package:personal_tree/features/profile/profile_screen.dart';
import 'package:personal_tree/main.dart';

/// Вкладки получают в padding.bottom высоту плавающего меню, иначе низ контента прячется под ним.
void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  final tabs = <String, (String, Type)>{
    'home': (Routes.home, HomeScreen),
    'catalog': (Routes.catalog, CatalogScreen),
    'forest': (Routes.forest, ForestScreen),
    'map': (Routes.map, MapScreen),
    'profile': (Routes.profile, ProfileScreen),
  };

  for (final MapEntry(key: name, value: (path, type)) in tabs.entries) {
    testWidgets('$name видит отступ под меню', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(appControllerProvider.notifier).loginDemo();
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const PersonalTreeApp()));
      container.read(routerProvider).go(path);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Меню 72 + безопасная зона 34.
      expect(MediaQuery.paddingOf(tester.element(find.byType(type))).bottom, greaterThanOrEqualTo(106));
      await tester.pumpWidget(const SizedBox());
      tester.takeException();
    });
  }
}
