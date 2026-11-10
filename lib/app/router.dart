import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/app_state.dart';
import '../data/models.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/onboarding_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/catalog/catalog_screen.dart';
import '../features/catalog/name_tree_screen.dart';
import '../features/catalog/order_success_screen.dart';
import '../features/catalog/purchase_screen.dart';
import '../features/forest/confirm_planting_screen.dart';
import '../features/forest/forest_screen.dart';
import '../features/forest/growth_done_screen.dart';
import '../features/forest/growth_screen.dart';
import '../features/forest/tree_detail_screen.dart';
import '../features/home/home_screen.dart';
import '../features/map/map_screen.dart';
import '../features/profile/achievements_screen.dart';
import '../features/profile/orders_screen.dart';
import '../features/profile/profile_screen.dart';
import 'shell.dart';

/// Пути приложения. Экраны используют их через `context.go(Routes.x)`.
abstract final class Routes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';

  static const home = '/home';
  static const catalog = '/catalog';
  static String purchase(String speciesId) => '/catalog/$speciesId';

  /// Шаг «Имя дереву» после карточки дерева. [installment] — взнос для режима «Копить».
  static String nameTree(String speciesId, {required int quantity, PaymentMode mode = PaymentMode.full, int? installment}) =>
      Uri(path: '/catalog/$speciesId/name', queryParameters: {
        'qty': '$quantity',
        'mode': mode.name,
        'plan': ?installment?.toString(),
      }).toString();
  static String orderSuccess(String orderId) => '/order-success/$orderId';

  static const forest = '/forest';
  static String tree(String treeId) => '/forest/$treeId';

  /// Рост дерева взносами и экран «Из цифры — в почву» на 100%.
  static String growth(String treeId) => '/growth/$treeId';
  static String growthDone(String treeId) => '/growth/$treeId/done';
  static String confirmPlanting(String treeId) => '/planter/confirm/$treeId';

  static const map = '/map';
  static String mapFocus(String treeId) => '/map?tree=$treeId';

  static const profile = '/profile';
  static const orders = '/profile/orders';
  static const achievements = '/profile/achievements';
}

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // go_router перечитывает redirect, когда меняется авторизация.
  final authListenable = ValueNotifier<(bool, bool)>((false, false));
  ref.listen(
    appControllerProvider.select((s) => (s.isLoggedIn, s.hasSeenOnboarding)),
    (_, next) => authListenable.value = next,
    fireImmediately: true,
  );
  ref.onDispose(authListenable.dispose);

  const authRoutes = {Routes.onboarding, Routes.login, Routes.register};

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.splash,
    refreshListenable: authListenable,
    redirect: (context, state) {
      // Splash сам решает, куда идти дальше.
      if (state.matchedLocation == Routes.splash) return null;
      final app = ref.read(appControllerProvider);
      final onAuth = authRoutes.contains(state.matchedLocation);
      if (!app.isLoggedIn) {
        if (onAuth) return null;
        return app.hasSeenOnboarding ? Routes.login : Routes.onboarding;
      }
      return onAuth ? Routes.home : null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.onboarding, builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/order-success/:orderId',
        parentNavigatorKey: _rootKey,
        builder: (_, s) => OrderSuccessScreen(orderId: s.pathParameters['orderId']!),
      ),
      GoRoute(
        path: '/growth/:treeId',
        parentNavigatorKey: _rootKey,
        builder: (_, s) => GrowthScreen(treeId: s.pathParameters['treeId']!),
        routes: [
          GoRoute(
            path: 'done',
            parentNavigatorKey: _rootKey,
            builder: (_, s) => GrowthDoneScreen(treeId: s.pathParameters['treeId']!),
          ),
        ],
      ),
      GoRoute(
        path: '/planter/confirm/:treeId',
        parentNavigatorKey: _rootKey,
        builder: (_, s) => ConfirmPlantingScreen(treeId: s.pathParameters['treeId']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.catalog,
              builder: (_, _) => const CatalogScreen(),
              routes: [
                GoRoute(
                  path: ':speciesId',
                  parentNavigatorKey: _rootKey,
                  builder: (_, s) => PurchaseScreen(speciesId: s.pathParameters['speciesId']!),
                  routes: [
                    GoRoute(
                      path: 'name',
                      parentNavigatorKey: _rootKey,
                      builder: (_, s) {
                        final q = s.uri.queryParameters;
                        return NameTreeScreen(
                          speciesId: s.pathParameters['speciesId']!,
                          quantity: int.tryParse(q['qty'] ?? '') ?? 1,
                          mode: q['mode'] == PaymentMode.installments.name ? PaymentMode.installments : PaymentMode.full,
                          installment: int.tryParse(q['plan'] ?? ''),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.forest,
              builder: (_, _) => const ForestScreen(),
              routes: [
                GoRoute(
                  path: ':treeId',
                  parentNavigatorKey: _rootKey,
                  builder: (_, s) => TreeDetailScreen(treeId: s.pathParameters['treeId']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.map,
              builder: (_, s) => MapScreen(focusTreeId: s.uri.queryParameters['tree']),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.profile,
              builder: (_, _) => const ProfileScreen(),
              routes: [
                GoRoute(path: 'orders', builder: (_, _) => const OrdersScreen()),
                GoRoute(path: 'achievements', builder: (_, _) => const AchievementsScreen()),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});
