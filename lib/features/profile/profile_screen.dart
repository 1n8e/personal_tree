import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../shared/format.dart';
import 'profile_widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notifications = true;

  void _soon(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  void _togglePlanterMode(bool value) {
    ref.read(appControllerProvider.notifier).setPlanterMode(value);
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          value ? 'Режим исполнителя включён — откройте дерево в «Моём лесу»' : 'Режим исполнителя выключен',
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Демо-данные этой сессии будут сброшены.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFB3261E)),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    if (ok == true) ref.read(appControllerProvider.notifier).logout();
  }

  void _showAbout() {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => const _AboutSheet(),
    );
  }

  void _showSupport() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        icon: const Icon(Icons.support_agent_rounded, color: AppColors.forest, size: 32),
        title: const Text('Поддержка'),
        content: const Text(
          'Напишите нам: support@personaltree.kz\nОтвечаем ежедневно с 9:00 до 21:00.',
          textAlign: TextAlign.center,
        ),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Понятно'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final user = state.user;
    if (user == null) return const Scaffold(body: SizedBox.shrink());

    final media = MediaQuery.of(context);
    final achievements = state.achievements;
    final orders = [...state.orders]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, media.padding.top + 12, 20, media.padding.bottom + 20),
        children: [
          _Header(user: user, points: state.ecoPoints),
          const SizedBox(height: 18),
          Row(
            children: [
              _StatTile(value: '${state.trees.length}', label: 'куплено деревьев'),
              const SizedBox(width: 8),
              _StatTile(value: '${state.plantedTrees.length}', label: 'посажено'),
              const SizedBox(width: 8),
              _StatTile(value: '${state.co2PerYear}', label: 'кг CO₂/год'),
              const SizedBox(width: 8),
              _StatTile(value: '${state.ecoPoints}', label: 'эко-баллы'),
            ],
          ),
          const SizedBox(height: 18),
          _SectionTitle('Достижения', onAll: () => context.push(Routes.achievements)),
          const SizedBox(height: 10),
          BadgeGrid(achievements: achievements),
          const SizedBox(height: 18),
          _OrdersCard(orders: orders),
          const SizedBox(height: 18),
          _SettingsCard(
            children: [
              _SettingRow(
                icon: Icons.notifications_none_rounded,
                title: 'Уведомления',
                value: _notifications ? 'Вкл.' : 'Выкл.',
                onTap: () => setState(() => _notifications = !_notifications),
              ),
              _SettingRow(
                icon: Icons.dark_mode_outlined,
                title: 'Тема',
                value: 'Светлая',
                onTap: () => _soon('Тёмная тема появится позже'),
              ),
              _SettingRow(
                icon: Icons.language_rounded,
                title: 'Язык',
                value: 'Русский',
                onTap: () => _soon('Казахский и английский появятся позже'),
              ),
              _SettingRow(
                icon: Icons.credit_card_rounded,
                title: 'Способы оплаты',
                onTap: () => _soon('Способы оплаты появятся позже'),
              ),
              _SettingRow(
                icon: Icons.engineering_outlined,
                title: 'Режим исполнителя (демо)',
                trailing: Switch(value: state.planterMode, onChanged: _togglePlanterMode),
                onTap: () => _togglePlanterMode(!state.planterMode),
              ),
              _SettingRow(icon: Icons.info_outline_rounded, title: 'О проекте', onTap: _showAbout),
              _SettingRow(icon: Icons.help_outline_rounded, title: 'Поддержка', onTap: _showSupport),
              _SettingRow(icon: Icons.logout_rounded, title: 'Выйти', danger: true, onTap: _confirmLogout),
            ],
          ),
          const SizedBox(height: 14),
          const Center(
            child: Text('Personal Tree · прототип 0.1', style: TextStyle(fontSize: 12, color: AppColors.hint)),
          ),
        ],
      ),
    );
  }
}

/// Уровни эко-активиста: порог баллов, с которого уровень начинается.
const _levels = <(int, String)>[
  (0, 'Росток'),
  (120, 'Саженец'),
  (320, 'Эко-активист'),
  (550, 'Хранитель леса'),
  (900, 'Лесник'),
  (1400, 'Легенда леса'),
];

class _Header extends StatelessWidget {
  const _Header({required this.user, required this.points});

  final UserProfile user;
  final int points;

  String _tenure() {
    final now = DateTime.now();
    final r = user.registeredAt;
    var months = (now.year - r.year) * 12 + now.month - r.month;
    if (now.day < r.day) months--;
    if (months >= 1) return '$months мес. в проекте';
    final days = now.difference(r).inDays.clamp(0, 31);
    return days == 0 ? 'Сегодня с нами' : '$days ${plural(days, 'день', 'дня', 'дней')} в проекте';
  }

  @override
  Widget build(BuildContext context) {
    var level = 0;
    for (var i = 0; i < _levels.length; i++) {
      if (points >= _levels[i].$1) level = i;
    }
    final isMax = level == _levels.length - 1;
    final next = isMax ? points : _levels[level + 1].$1;
    final ratio = isMax || next == 0 ? 1.0 : (points / next).clamp(0.0, 1.0);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final name = user.name.trim();
    final letter = name.isEmpty ? '?' : name.characters.first.toUpperCase();

    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.sage,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 3),
            boxShadow: [
              BoxShadow(color: AppColors.pine.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: Text(letter, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.pine)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      user.name,
                      style: AppFonts.display(size: 26),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(_tenure(), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '${_levels[level].$2} · уровень ${level + 1}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.leaf),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    isMax ? '$points' : '$points / $next',
                    style: const TextStyle(fontSize: 13, color: AppColors.muted, fontFeatures: AppFonts.tabular),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 8,
                  color: AppColors.mint,
                  alignment: Alignment.centerLeft,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: ratio),
                    duration: reduce ? Duration.zero : const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => FractionallySizedBox(
                      widthFactor: v,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: AppColors.leaf, borderRadius: BorderRadius.circular(4)),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18)),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.pine,
                fontFeatures: AppFonts.tabular,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.onAll});

  final String title;
  final VoidCallback? onAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppFonts.display(size: 20))),
        if (onAll != null)
          TextButton(
            onPressed: onAll,
            style: TextButton.styleFrom(minimumSize: const Size(48, 40), padding: const EdgeInsets.symmetric(horizontal: 8)),
            child: const Text('Все'),
          ),
      ],
    );
  }
}

class _OrdersCard extends StatelessWidget {
  const _OrdersCard({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [BoxShadow(color: Color(0x14234010), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('История заказов', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                  if (orders.isNotEmpty)
                    GestureDetector(
                      onTap: () => context.push(Routes.orders),
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          'Все',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.leaf),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (orders.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Заказов пока нет', style: TextStyle(fontSize: 14, color: AppColors.muted)),
                    ),
                    TextButton(onPressed: () => context.go(Routes.catalog), child: const Text('В каталог')),
                  ],
                ),
              )
            else
              for (final o in orders.take(3))
                OrderPreviewTile(order: o, divider: true, onTap: () => context.push(Routes.orders)),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Material(type: MaterialType.transparency, child: Column(children: children)),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    this.value,
    this.trailing,
    this.danger = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? value;
  final Widget? trailing;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFB3261E);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: danger ? const Color(0xFFFBE9E7) : AppColors.mint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: danger ? red : AppColors.pine),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: danger ? red : AppColors.ink),
                ),
              ),
              if (value != null) ...[
                Text(value!, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                const SizedBox(width: 6),
              ],
              ?trailing ??
                  (danger ? null : const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, size: 18, color: AppColors.pine),
    );
  }
}

class _AboutSheet extends StatelessWidget {
  const _AboutSheet();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget point(IconData icon, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SettingsIcon(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.titleMedium?.copyWith(fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(body, style: text.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: AppColors.forest, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.park_rounded, color: AppColors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Personal Tree', style: text.headlineMedium)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Сервис, в котором каждый житель Алматы может посадить своё дерево и следить за ним. '
            'Мы сажаем деревья в парках и зонах озеленения города вместе с проверенными исполнителями.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 20),
          point(Icons.shopping_basket_outlined, 'Выберите дерево', 'Саженец, посадка, доставка и уход в первый год — в одной цене.'),
          point(Icons.photo_camera_outlined, 'Подтверждение посадки', 'Исполнитель прикладывает фото и геоточку — только после этого дерево появляется на карте.'),
          point(Icons.qr_code_2_rounded, 'Цифровая карточка', 'У каждого дерева свой номер, история ухода и место на карте города.'),
          const SizedBox(height: 4),
          Text('Прототип · данные демонстрационные', style: text.bodySmall?.copyWith(color: AppColors.hint)),
        ],
      ),
    );
  }
}
