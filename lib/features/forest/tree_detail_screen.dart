import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../shared/design.dart';
import '../../shared/format.dart';
import '../../shared/widgets.dart';
import 'forest_widgets.dart';

/// Высота одной строки «Пути дерева» (по дизайну).
const _rowHeight = 56.0;

/// Карточка дерева: макет зависит от статуса (растёт / ожидает посадки /
/// посажено / на мониторинге). До подтверждения исполнителем фото, координат
/// и даты посадки нет — только честная иллюстрация и пояснение.
class TreeDetailScreen extends ConsumerWidget {
  const TreeDetailScreen({super.key, required this.treeId});

  final String treeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tree = ref.watch(appControllerProvider.select((s) => s.treeById(treeId)));
    final planterMode = ref.watch(appControllerProvider.select((s) => s.planterMode));

    if (tree == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Дерево не найдено',
            message: 'Возможно, ссылка устарела.',
            actionLabel: 'К моему лесу',
            onAction: () => context.go(Routes.forest),
          ),
        ),
      );
    }

    final species = speciesById(tree.speciesId);
    final planted = tree.isPlanted;
    final top = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    void back() => context.canPop() ? context.pop() : context.go(Routes.forest);

    final bar = switch (tree.status) {
      TreeStatus.growing => _BottomBar(
          children: [
            _BarButton(
              label: 'Продолжить рост',
              icon: Icons.spa_outlined,
              onTap: () => context.push(Routes.growth(tree.id)),
            ),
          ],
        ),
      TreeStatus.awaitingPlanting => _BottomBar(
          children: [
            Expanded(
              child: _DashedButton(
                label: 'Демо: исполнитель подтвердил посадку',
                onTap: () => context.push(Routes.confirmPlanting(tree.id)),
              ),
            ),
          ],
        ),
      _ => _BottomBar(
          children: [
            _ShareButton(onTap: () => _share(context, tree, species)),
            const SizedBox(width: 10),
            _BarButton(
              label: 'Показать на карте',
              icon: Icons.location_on_outlined,
              onTap: () => context.go(Routes.mapFocus(tree.id)),
            ),
          ],
        ),
    };

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 110 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (planted)
                    _PhotoHeader(tree: tree, species: species, top: top, onBack: back)
                  else
                    Padding(
                      padding: EdgeInsets.fromLTRB(AppSpacing.page, top + 8, AppSpacing.page, 0),
                      child: Row(
                        children: [
                          RoundBackButton(onPressed: back),
                          const SizedBox(width: 12),
                          Text(
                            tree.code,
                            style: const TextStyle(fontSize: 13, color: AppColors.muted, fontFeatures: AppFonts.tabular),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(AppSpacing.page, planted ? 18 : 16, AppSpacing.page, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (planted) ...[
                          _PlantedTitle(tree: tree, species: species),
                          const SizedBox(height: 16),
                          _PlantedData(tree: tree),
                          if (planterMode) ...[
                            const SizedBox(height: 16),
                            _CareButtons(tree: tree),
                          ],
                        ] else ...[
                          _Hero(tree: tree, species: species),
                          const SizedBox(height: 16),
                          if (tree.isGrowing) _GrowingCard(tree: tree) else const _WhyNoPhoto(),
                        ],
                        const SizedBox(height: 16),
                        _PathCard(tree: tree),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: bar),
        ],
      ),
    );
  }

  void _share(BuildContext context, Tree tree, TreeSpecies species) {
    final text = tree.isPlanted
        ? 'Ссылка на ${species.name.toLowerCase()} ${tree.code} скопирована'
        : 'Ссылка скопирована · фото появится после посадки';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}

// ---------------------------------------------------------------------------
// Шапки
// ---------------------------------------------------------------------------

/// Плашка с иллюстрацией, статусом и названием (растёт / ожидает посадки).
class _Hero extends StatelessWidget {
  const _Hero({required this.tree, required this.species});

  final Tree tree;
  final TreeSpecies species;

  @override
  Widget build(BuildContext context) {
    final percent = (tree.progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Row(
        children: [
          Container(
            width: 110,
            height: 120,
            decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(18)),
            alignment: Alignment.bottomCenter,
            child: Semantics(
              label: 'Иллюстрация: ${species.name.toLowerCase()}',
              child: TreeArt(size: 110, stage: tree.isGrowing ? tree.stage : GrowthStage.ready),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TreeStatusBadge(tree.status),
                const SizedBox(height: 6),
                Text(tree.displayName, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppFonts.display(size: 28)),
                const SizedBox(height: 6),
                Text(
                  '${species.name} · $percent% собрано',
                  style: const TextStyle(fontSize: 14, color: forestBodyText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Фото посадки (300 px, низ скруглён 32) с кнопкой «назад» и бейджем подтверждения.
class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({required this.tree, required this.species, required this.top, required this.onBack});

  final Tree tree;
  final TreeSpecies species;
  final double top;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Entrance(
            duration: const Duration(milliseconds: 500),
            builder: (_, t, child) =>
                Opacity(opacity: t, child: Transform.scale(scale: 1 + 0.04 * (1 - t), child: child)),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              // Фото выше окна, чтобы подпись с датой внутри TreePhoto ушла за край.
              child: OverflowBox(
                alignment: Alignment.topCenter,
                minHeight: 340,
                maxHeight: 340,
                child: TreePhoto(tree: tree, species: species, height: 340, radius: 0),
              ),
            ),
          ),
          Positioned(
            top: top + 8,
            left: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: SizedBox.square(
                dimension: 48,
                child: IconButton(
                  tooltip: 'Назад',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.pine, size: 22),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            child: Entrance(
              delay: const Duration(milliseconds: 350),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutBack,
              builder: (_, t, child) => Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 10 * (1 - t)),
                  child: Transform.scale(scale: 0.8 + 0.2 * t, child: child),
                ),
              ),
              child: Container(
                height: 34,
                padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  boxShadow: const [BoxShadow(color: Color(0x29234010), blurRadius: 16, offset: Offset(0, 6))],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user_outlined, size: 20, color: AppColors.leaf),
                    SizedBox(width: 6),
                    Text(
                      'Подтверждено исполнителем',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.pine),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlantedTitle extends StatelessWidget {
  const _PlantedTitle({required this.tree, required this.species});

  final Tree tree;
  final TreeSpecies species;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tree.displayName, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppFonts.display(size: 30)),
              Text(
                '${species.name} · ${tree.code}',
                style: const TextStyle(fontSize: 14, color: AppColors.muted, fontFeatures: AppFonts.tabular),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TreeStatusBadge(tree.status),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Карточки содержимого
// ---------------------------------------------------------------------------

/// «Почему пока нет фото?» — правило продукта: никаких «примерных» снимков.
class _WhyNoPhoto extends StatelessWidget {
  const _WhyNoPhoto();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule_rounded, size: 22, color: AppColors.aqi),
              SizedBox(width: 10),
              Text('Почему пока нет фото?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Партнёр-исполнитель подбирает место и сезонное окно для посадки. Фото, координаты и дату вы увидите, '
            'только когда исполнитель подтвердит реальную посадку — никаких «примерных» снимков.',
            style: TextStyle(fontSize: 14, height: 1.5, color: forestBodyText),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: _EmptyCell('Место')),
              SizedBox(width: 8),
              Expanded(child: _EmptyCell('Дата')),
              SizedBox(width: 8),
              Expanded(child: _EmptyCell('Координаты')),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyCell extends StatelessWidget {
  const _EmptyCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          const Text('—', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.faint)),
        ],
      ),
    );
  }
}

/// Прогресс выращивания: сколько внесено из нужной суммы.
class _GrowingCard extends StatelessWidget {
  const _GrowingCard({required this.tree});

  final Tree tree;

  @override
  Widget build(BuildContext context) {
    final percent = (tree.progress * 100).round();
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Рост дерева', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
              ),
              Text(
                '$percent%',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.leaf, fontFeatures: AppFonts.tabular),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: tree.progress),
              duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                backgroundColor: AppColors.mint,
                color: AppColors.leaf,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Внесено ${formatPrice(tree.paidAmount)} из ${formatPrice(tree.targetAmount)}. '
            'На 100% дерево передадут исполнителю на посадку.',
            style: const TextStyle(fontSize: 14, height: 1.5, color: forestBodyText),
          ),
        ],
      ),
    );
  }
}

/// Данные посадки: дата, район, координаты — только после подтверждения.
class _PlantedData extends StatelessWidget {
  const _PlantedData({required this.tree});

  final Tree tree;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _DataCell(label: 'Дата посадки', value: tree.plantedAt != null ? formatDate(tree.plantedAt!) : '—'),
            ),
            const SizedBox(width: 10),
            Expanded(child: _DataCell(label: 'Район', value: tree.locationName ?? '—')),
          ],
        ),
        const SizedBox(height: 10),
        _DataCell(
          label: 'Координаты',
          value: tree.location != null ? formatLatLngDeg(tree.location!) : '—',
          sub: tree.plantedBy != null ? 'Исполнитель · ${tree.plantedBy}' : null,
        ),
      ],
    );
  }
}

class _DataCell extends StatelessWidget {
  const _DataCell({required this.label, required this.value, this.sub});

  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink, fontFeatures: AppFonts.tabular),
          ),
          if (sub != null) Text(sub!, style: const TextStyle(fontSize: 13, color: forestBodyText)),
        ],
      ),
    );
  }
}

/// Запись ухода (демо-режим исполнителя): полив и осмотр.
class _CareButtons extends ConsumerWidget {
  const _CareButtons({required this.tree});

  final Tree tree;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _addCare(context, ref, TreeEventType.watered),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
            icon: const Icon(Icons.water_drop_outlined, size: 20),
            label: const FittedBox(child: Text('Добавить полив')),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _addCare(context, ref, TreeEventType.checked),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
            icon: const Icon(Icons.fact_check_outlined, size: 20),
            label: const FittedBox(child: Text('Добавить осмотр')),
          ),
        ),
      ],
    );
  }

  Future<void> _addCare(BuildContext context, WidgetRef ref, TreeEventType type) async {
    final messenger = ScaffoldMessenger.of(context);
    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => _CareSheet(type: type),
    );
    if (note == null) return;
    ref.read(appControllerProvider.notifier).addCareUpdate(
          treeId: tree.id,
          type: type,
          note: note.trim().isEmpty ? null : note.trim(),
        );
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            type == TreeEventType.watered
                ? 'Полив добавлен · дерево на мониторинге'
                : 'Осмотр добавлен · дерево на мониторинге',
          ),
        ),
      );
  }
}

// ---------------------------------------------------------------------------
// Путь дерева
// ---------------------------------------------------------------------------

enum _NodeState { done, current, todo }

class _PathStep {
  const _PathStep(this.title, this.subtitle, this.state);

  final String title;
  final String subtitle;
  final _NodeState state;
}

DateTime? _eventDate(Tree t, TreeEventType type) {
  for (final e in t.events) {
    if (e.type == type) return e.date;
  }
  return null;
}

String _shortDate(DateTime d) => formatDate(d);

/// Шесть узлов пути; даты и состояния выводятся из событий и статуса дерева.
({List<_PathStep> steps, int current}) _buildPath(Tree t) {
  final ordered = _eventDate(t, TreeEventType.ordered) ?? t.orderedAt;
  final grown = _eventDate(t, TreeEventType.grown);
  final handed = grown ?? (t.status == TreeStatus.growing ? null : t.orderedAt);

  final current = switch (t.status) {
    TreeStatus.growing => 1,
    TreeStatus.awaitingPlanting => 3,
    TreeStatus.planted => 4,
    TreeStatus.monitoring => 5,
  };

  String waited() {
    final from = handed;
    final to = t.plantedAt;
    if (from == null || to == null) return 'Посадка подтверждена';
    final days = to.difference(from).inDays.clamp(0, 9999);
    return '$days ${plural(days, 'день', 'дня', 'дней')}';
  }

  String care() {
    TreeEvent? last;
    for (final e in t.events) {
      if ((e.type == TreeEventType.watered || e.type == TreeEventType.checked) &&
          (last == null || e.date.isAfter(last.date))) {
        last = e;
      }
    }
    return last == null ? 'Уход и полив первый год' : '${last.title} · ${_shortDate(last.date)}';
  }

  final titles = [
    'Заказ оформлен',
    'Дерево выращено до 100%',
    'Передано исполнителю',
    t.isPlanted ? 'Ожидало посадки' : 'Ожидает посадки',
    'Посажено',
    'На мониторинге',
  ];
  final subtitles = [
    _shortDate(ordered),
    t.status == TreeStatus.growing
        ? '${(t.progress * 100).round()}% · внесено ${formatPrice(t.paidAmount)} из ${formatPrice(t.targetAmount)}'
        : (grown != null ? _shortDate(grown) : '100% собрано'),
    handed != null ? 'Партнёр-исполнитель · ${_shortDate(handed)}' : 'После выращивания до 100%',
    t.isPlanted ? waited() : 'Обычно до 14 дней в сезон посадок',
    t.isPlanted && t.plantedAt != null
        ? '${_shortDate(t.plantedAt!)} · подтверждено'
        : 'Фото и координаты от исполнителя',
    t.status == TreeStatus.monitoring ? care() : 'Уход и полив первый год',
  ];
  return (
    steps: [
      for (var i = 0; i < 6; i++)
        _PathStep(
          titles[i],
          subtitles[i],
          i < current ? _NodeState.done : (i == current ? _NodeState.current : _NodeState.todo),
        ),
    ],
    current: current,
  );
}

/// Карточка «Путь дерева»: вертикальный «ствол» дорастает до текущего узла (600 мс).
class _PathCard extends StatefulWidget {
  const _PathCard({required this.tree});

  final Tree tree;

  @override
  State<_PathCard> createState() => _PathCardState();
}

class _PathCardState extends State<_PathCard> with TickerProviderStateMixin {
  late final AnimationController _grow = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (!_started) {
      _started = true;
      if (reduce) {
        _grow.value = 1;
      } else {
        _grow.forward();
      }
    }
    if (reduce) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _grow.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tree = widget.tree;
    final (:steps, :current) = _buildPath(tree);
    final isPlantedNow = tree.status == TreeStatus.planted;
    // Для «Посажено» ствол продолжает рост от предыдущего узла и заполняет последний.
    final to = current * _rowHeight;
    final from = (tree.isPlanted ? (current - 1) * _rowHeight : 0.0);
    final ringColor = tree.status == TreeStatus.monitoring ? AppColors.monitoringDot : AppColors.awaitingDot;
    const nodeCenter = 14.5;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Путь дерева', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 14),
          Stack(
            children: [
              Positioned(
                left: 13,
                top: 14,
                bottom: _rowHeight - nodeCenter,
                width: 3,
                child: const DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xFFE4E9DE), borderRadius: BorderRadius.all(Radius.circular(2))),
                ),
              ),
              AnimatedBuilder(
                animation: _grow,
                builder: (_, _) {
                  final t = Curves.easeOutCubic.transform(_grow.value);
                  return Positioned(
                    left: 13,
                    top: 14,
                    height: from + (to - from) * t,
                    width: 3,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(color: AppColors.leaf, borderRadius: BorderRadius.all(Radius.circular(2))),
                    ),
                  );
                },
              ),
              Column(
                children: [
                  for (var i = 0; i < steps.length; i++)
                    SizedBox(
                      height: _rowHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Node(
                            state: steps[i].state,
                            ringColor: ringColor,
                            pulse: _pulse,
                            grow: _grow,
                            check: !tree.isPlanted,
                            fillIn: isPlantedNow && i == current,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    steps[i].title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: steps[i].state == _NodeState.todo ? AppColors.faint : AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    steps[i].subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13, color: AppColors.muted, fontFeatures: AppFonts.tabular),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Узел пути 29×29: выполнен — зелёный с галочкой, текущий — с пульсирующим кольцом.
class _Node extends StatelessWidget {
  const _Node({
    required this.state,
    required this.ringColor,
    required this.pulse,
    required this.grow,
    required this.check,
    required this.fillIn,
  });

  final _NodeState state;
  final Color ringColor;
  final Animation<double> pulse;
  final Animation<double> grow;
  final bool check;

  /// Последний узел «Посажено» заливается снизу вверх (400 мс, +200 мс).
  final bool fillIn;

  @override
  Widget build(BuildContext context) {
    final done = state == _NodeState.done || fillIn;
    final border = switch (state) {
      _NodeState.done => AppColors.leaf,
      _NodeState.current => fillIn ? AppColors.leaf : ringColor,
      _NodeState.todo => AppColors.stepTodo,
    };
    final fillColor = (state == _NodeState.done && !fillIn) ? AppColors.leaf : AppColors.white;

    Widget dot = Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fillColor,
        border: Border.all(color: border, width: 3),
      ),
      child: fillIn
          ? ClipOval(
              child: AnimatedBuilder(
                animation: grow,
                builder: (_, _) => FractionallySizedBox(
                  alignment: Alignment.bottomCenter,
                  heightFactor: Curves.easeOutCubic.transform(((grow.value - 1 / 3) / (2 / 3)).clamp(0.0, 1.0)),
                  widthFactor: 1,
                  child: const ColoredBox(color: AppColors.leaf),
                ),
              ),
            )
          : (done && check ? const Icon(Icons.check_rounded, size: 12, color: AppColors.white) : null),
    );

    return SizedBox(
      width: 29,
      height: 29,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (state == _NodeState.current && !fillIn)
            AnimatedBuilder(
              animation: pulse,
              builder: (_, _) {
                final e = Curves.easeInOut.transform(pulse.value);
                return Opacity(
                  opacity: 0.5 * (1 - e),
                  child: Transform.scale(
                    scale: 1 + 0.6 * e,
                    child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: ringColor), child: const SizedBox.expand()),
                  ),
                );
              },
            ),
          dot,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Нижняя панель
// ---------------------------------------------------------------------------

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: AppColors.cream.withValues(alpha: 0.92),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + (MediaQuery.paddingOf(context).bottom > 0 ? MediaQuery.paddingOf(context).bottom - 4 : 16)),
          child: Row(children: children),
        ),
      ),
    );
  }
}

/// Основная кнопка панели: pine, 56 px, радиус 16.
class _BarButton extends StatelessWidget {
  const _BarButton({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: PressScale(
        child: Material(
          color: AppColors.pine,
          borderRadius: BorderRadius.circular(AppRadius.button),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: AppColors.white),
                  const SizedBox(width: 8),
                  Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.white)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: Material(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(AppRadius.button),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const SizedBox.square(
            dimension: 56,
            child: Icon(Icons.share_outlined, size: 22, color: AppColors.pine, semanticLabel: 'Поделиться'),
          ),
        ),
      ),
    );
  }
}

/// Кнопка с пунктирной рамкой для демо-действия.
class _DashedButton extends StatelessWidget {
  const _DashedButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: CustomPaint(
        foregroundPainter: _DashedBorderPainter(),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.button),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              height: 52,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.pine)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
      const Radius.circular(AppRadius.button),
    );
    final paint = Paint()
      ..color = AppColors.leaf
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final m in (Path()..addRRect(rect)).computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 8) {
        canvas.drawPath(m.extractPath(d, (d + 4).clamp(0, m.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => false;
}

/// Нижний лист для записи ухода с необязательным комментарием.
class _CareSheet extends StatefulWidget {
  const _CareSheet({required this.type});

  final TreeEventType type;

  @override
  State<_CareSheet> createState() => _CareSheetState();
}

class _CareSheetState extends State<_CareSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final watered = widget.type == TreeEventType.watered;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.page),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    watered ? Icons.water_drop_rounded : Icons.fact_check_rounded,
                    color: AppColors.pine,
                  ),
                  const SizedBox(width: 10),
                  Text(watered ? 'Полив' : 'Плановый осмотр', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Запись появится в истории дерева, владелец увидит её в приложении.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: watered
                      ? 'Комментарий, например: 20 л воды'
                      : 'Комментарий, например: листья здоровые',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(_controller.text),
                child: const Text('Сохранить запись'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
