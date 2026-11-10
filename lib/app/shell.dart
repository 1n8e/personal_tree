import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/app_state.dart';
import '../shared/design.dart';
import '../shared/widgets.dart';
import 'theme.dart';

/// Нижнее меню: Главная · Каталог · Мой лес · Карта · Профиль.
/// Плавающая «стеклянная» плашка; у всех вкладок одинаковая раскладка «иконка над подписью»,
/// активная лишь подсвечивается зелёной пилюлей — текст не прыгает.
///
/// `extendBody: true` — контент вкладок уходит под меню, а его высота
/// попадает в `MediaQuery.paddingOf(context).bottom`: экраны добавляют этот отступ в конец скролла.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planterMode = ref.watch(appControllerProvider.select((s) => s.planterMode));
    final awaiting = ref.watch(appControllerProvider.select((s) => s.awaitingTrees.length));
    return Scaffold(
      extendBody: true,
      // Builder: нужен контекст внутри Scaffold — только там padding.bottom уже включает высоту меню.
      body: Builder(
        builder: (context) => Column(
          children: [
            if (planterMode) const SafeArea(bottom: false, child: PlanterModeBanner()),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: planterMode,
                child: shell,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _FloatingNav(
        index: shell.currentIndex,
        badge: awaiting,
        onSelect: (i) {
          HapticFeedback.selectionClick();
          shell.goBranch(i, initialLocation: i == shell.currentIndex);
        },
      ),
    );
  }
}

class _Tab {
  const _Tab(this.label, this.icon);
  final String label;
  final IconData icon;
}

const _tabs = [
  _Tab('Главная', Icons.eco_outlined),
  _Tab('Каталог', Icons.grid_view_rounded),
  _Tab('Мой лес', Icons.forest_outlined),
  _Tab('Карта', Icons.map_outlined),
  _Tab('Профиль', Icons.person_outline_rounded),
];

class _FloatingNav extends StatelessWidget {
  const _FloatingNav({required this.index, required this.badge, required this.onSelect});

  final int index;
  final int badge;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom > 0 ? bottom : 20),
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), boxShadow: AppShadows.nav),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 72,
              color: AppColors.white.withValues(alpha: 0.82),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Row(
                children: [
                  for (var i = 0; i < _tabs.length; i++)
                    Expanded(
                      child: _NavItem(
                        tab: _tabs[i],
                        selected: i == index,
                        badge: i == 2 ? badge : 0,
                        onTap: () => onSelect(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.tab, required this.selected, required this.badge, required this.onTap});

  final _Tab tab;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.white : AppColors.muted;
    final icon = Badge(
      isLabelVisible: badge > 0,
      backgroundColor: AppColors.awaitingDot,
      textColor: AppColors.pine,
      label: Text('$badge'),
      child: selected && tab.label == 'Главная'
          ? LeafIcon(size: 22, color: color, outlined: true)
          : Icon(tab.icon, size: 22, color: color),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      excludeSemantics: true,
      child: PressScale(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: selected ? AppColors.leaf : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(height: 3),
                // Подпись ужимается, а не переполняет вкладку на узких экранах и при крупном шрифте.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    style: TextStyle(
                      fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: color,
                    ),
                    child: Text(tab.label, maxLines: 1),
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
