import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../shared/design.dart';
import '../../shared/format.dart';

/// Чип статуса заказа (высота 22, как в дизайне).
class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip(this.status, {super.key});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (status) {
      OrderStatus.created => (AppColors.muted, const Color(0xFFEEEAE0)),
      OrderStatus.confirmed => (AppColors.awaiting, AppColors.awaitingBg),
      OrderStatus.completed => (AppColors.pine, AppColors.mint),
      OrderStatus.cancelled => (const Color(0xFFB3261E), const Color(0xFFFBE9E7)),
    };
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.chip)),
      child: Text(
        orderStatusLabel(status),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

/// Цвета лицевой стороны достижения (иконка, фон) — по кругу, как в дизайне.
const _badgePalette = <(Color, Color)>[
  (AppColors.leaf, AppColors.mint),
  (AppColors.pine, Color(0xFFE8EFDF)),
  (AppColors.awaiting, AppColors.awaitingBg),
  (AppColors.monitoring, AppColors.sky),
  (AppColors.monitoring, AppColors.sky),
  (AppColors.leaf, AppColors.mint),
];

(Color, Color) _paletteFor(int index) => _badgePalette[index % _badgePalette.length];

/// Круглый значок достижения: цветной, если получено, серый с замком — если нет.
class AchievementBadge extends StatelessWidget {
  const AchievementBadge({super.key, required this.progress, this.size = 56, this.index = 0});

  final AchievementProgress progress;
  final double size;

  /// Номер достижения — выбирает цвет.
  final int index;

  @override
  Widget build(BuildContext context) {
    final earned = progress.earned;
    final (fg, bg) = _paletteFor(index);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: earned ? AppColors.white : const Color(0xFFD5D2C8),
              shape: BoxShape.circle,
              boxShadow: earned ? [BoxShadow(color: AppColors.pine.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))] : null,
              border: earned ? Border.all(color: bg, width: 3) : null,
            ),
            child: Icon(
              progress.achievement.icon,
              size: size * 0.5,
              color: earned ? fg : const Color(0xFF6B6A62),
            ),
          ),
          if (!earned)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                child: Icon(Icons.lock_rounded, size: size * 0.2, color: const Color(0xFF6B6A62)),
              ),
            ),
        ],
      ),
    );
  }
}

const _grayscale = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
]);

/// Карточка достижения 3×N: по нажатию переворачивается (rotateY 0→π, 600 мс)
/// и показывает цветную сторону с бликом. Недоступные — в градациях серого.
class FlipBadgeTile extends StatefulWidget {
  const FlipBadgeTile({super.key, required this.progress, required this.index});

  final AchievementProgress progress;
  final int index;

  @override
  State<FlipBadgeTile> createState() => _FlipBadgeTileState();
}

class _FlipBadgeTileState extends State<FlipBadgeTile> with TickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
    value: widget.progress.earned ? 1 : 0,
  );
  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
    value: 1,
  );
  Timer? _shineDelay;
  late bool _open = widget.progress.earned;

  @override
  void dispose() {
    _shineDelay?.cancel();
    _flip.dispose();
    _shine.dispose();
    super.dispose();
  }

  void _toggle() {
    final reduce = MediaQuery.disableAnimationsOf(context);
    _shineDelay?.cancel();
    final open = !_open;
    _open = open;
    if (reduce) {
      _flip.value = open ? 1 : 0;
      _shine.value = 1;
      return;
    }
    if (open) {
      _flip.forward();
      _shine.value = 0;
      _shine.stop();
      _shineDelay = Timer(const Duration(milliseconds: 500), () {
        if (mounted) _shine.forward(from: 0);
      });
    } else {
      _flip.reverse();
      _shine.value = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.progress;
    final a = p.achievement;
    final earned = p.earned;
    final (fg, bg) = _paletteFor(widget.index);
    const grey = Color(0xFF5F5E57);

    Widget front() => Container(
          decoration: BoxDecoration(color: const Color(0xFFEEEAE0), borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(color: Color(0xFFD5D2C8), shape: BoxShape.circle),
                child: Icon(earned ? a.icon : Icons.lock_outline_rounded, size: 24, color: const Color(0xFF6B6A62)),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  a.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: grey, height: 1.2),
                ),
              ),
            ],
          ),
        );

    Widget back() {
      Widget face = Container(
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.pine.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Icon(a.icon, size: 26, color: fg),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                a.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.2),
              ),
            ),
            if (!earned)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${p.current.clamp(0, a.target)} / ${a.target}',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted, fontFeatures: AppFonts.tabular),
                ),
              ),
          ],
        ),
      );
      // Блик: светлая полоса, пробегающая по лицевой стороне.
      face = AnimatedBuilder(
        animation: _shine,
        builder: (_, child) {
          if (_shine.value >= 1 || _shine.value <= 0) return child!;
          final t = -0.3 + 1.6 * Curves.easeOut.transform(_shine.value);
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (r) => LinearGradient(
              begin: const Alignment(-1, -0.45),
              end: const Alignment(1, 0.45),
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.6),
                Colors.transparent,
              ],
              stops: [(t - 0.12).clamp(0, 1), t.clamp(0, 1), (t + 0.12).clamp(0, 1)],
            ).createShader(r),
            child: child,
          );
        },
        child: face,
      );
      face = ClipRRect(borderRadius: BorderRadius.circular(20), child: face);
      return earned ? face : ColorFiltered(colorFilter: _grayscale, child: face);
    }

    return Semantics(
      button: true,
      label: '${a.title}, ${earned ? 'получено' : 'закрыто'}',
      excludeSemantics: true,
      onTap: _toggle,
      child: GestureDetector(
        onTap: _toggle,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 112,
          child: AnimatedBuilder(
            animation: _flip,
            builder: (_, _) {
              final angle = Curves.linear.transform(const Cubic(0.2, 0, 0, 1).transform(_flip.value)) * math.pi;
              final showBack = angle > math.pi / 2;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                child: showBack
                    ? Transform(alignment: Alignment.center, transform: Matrix4.rotationY(math.pi), child: back())
                    : front(),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Нижний лист с подробностями достижения.
Future<void> showAchievementSheet(BuildContext context, AchievementProgress p, {int index = 0}) {
  final a = p.achievement;
  final shown = p.current.clamp(0, a.target);
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    builder: (ctx) {
      final text = Theme.of(ctx).textTheme;
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.section),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AchievementBadge(progress: p, size: 84, index: index),
            const SizedBox(height: 14),
            Text(a.title, style: AppFonts.display(size: 24), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              a.description,
              style: text.bodyMedium?.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: p.ratio,
                minHeight: 8,
                backgroundColor: AppColors.mint,
                color: AppColors.leaf,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('$shown из ${a.target}', style: text.bodySmall?.copyWith(fontFeatures: AppFonts.tabular)),
                const Spacer(),
                Text(
                  p.earned ? 'Получено' : 'Осталось ${a.target - shown}',
                  style: text.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: p.earned ? AppColors.leaf : AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  Icon(
                    p.earned ? Icons.celebration_rounded : Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.pine,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p.earned
                          ? 'Отличная работа! Достижение уже в вашей коллекции.'
                          : 'Прогресс засчитывается после того, как исполнитель подтвердит посадку.',
                      style: text.bodySmall?.copyWith(color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Строка заказа для истории: название, номер · дата, сумма и статус.
class OrderPreviewTile extends StatelessWidget {
  const OrderPreviewTile({super.key, required this.order, this.onTap, this.divider = false});

  final Order order;
  final VoidCallback? onTap;

  /// Линия сверху (для всех строк, кроме первой).
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final species = speciesById(order.speciesId);
    final title = order.quantity > 1 ? '${species.name} × ${order.quantity}' : species.name;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: divider ? const Border(top: BorderSide(color: AppColors.divider)) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '№ ${order.number} · ${formatDate(order.createdAt)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted, fontFeatures: AppFonts.tabular),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatPrice(order.total),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, fontFeatures: AppFonts.tabular),
                ),
                const SizedBox(height: 4),
                OrderStatusChip(order.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Сетка достижений 3×N из переворачивающихся карточек.
class BadgeGrid extends StatelessWidget {
  const BadgeGrid({super.key, required this.achievements});

  final List<AchievementProgress> achievements;

  @override
  Widget build(BuildContext context) {
    return GridView(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 112,
      ),
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final (i, p) in achievements.indexed)
          FlipBadgeTile(key: ValueKey(p.achievement.id), progress: p, index: i),
      ],
    );
  }
}

/// Шапка внутренних экранов профиля: круглая «Назад» и заголовок Playfair.
class ProfileSubHeader extends StatelessWidget {
  const ProfileSubHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const RoundBackButton(),
        const SizedBox(width: 14),
        Expanded(child: Text(title, style: AppFonts.display(size: 26), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ?trailing,
      ],
    );
  }
}
