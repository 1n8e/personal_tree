import 'dart:math' as math;

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

enum _ForestFilter { all, growing, awaiting, planted, monitoring }

extension on _ForestFilter {
  String get label => switch (this) {
        _ForestFilter.all => 'Все',
        _ForestFilter.growing => 'Растут',
        _ForestFilter.awaiting => 'Ожидают',
        _ForestFilter.planted => 'Посажены',
        _ForestFilter.monitoring => 'Мониторинг',
      };

  bool matches(Tree t) => switch (this) {
        _ForestFilter.all => true,
        _ForestFilter.growing => t.status == TreeStatus.growing,
        _ForestFilter.awaiting => t.status == TreeStatus.awaitingPlanting,
        _ForestFilter.planted => t.status == TreeStatus.planted,
        _ForestFilter.monitoring => t.status == TreeStatus.monitoring,
      };
}

/// Вкладка «Мой лес»: мини-лес со сводкой и список деревьев со статусами.
class ForestScreen extends ConsumerStatefulWidget {
  const ForestScreen({super.key});

  @override
  ConsumerState<ForestScreen> createState() => _ForestScreenState();
}

class _ForestScreenState extends ConsumerState<ForestScreen> {
  _ForestFilter _filter = _ForestFilter.all;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final trees = state.trees;
    if (_filter != _ForestFilter.all && !trees.any(_filter.matches)) _filter = _ForestFilter.all;
    final visible = trees.where(_filter.matches).toList();
    final bottom = MediaQuery.paddingOf(context).bottom + 24;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: trees.isEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Header(),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(bottom: bottom),
                        child: EmptyState(
                          icon: Icons.forest_outlined,
                          title: 'Ваш лес пока пуст',
                          message: 'Выберите дерево в каталоге — мы посадим его в Алматы и пришлём фото с геоточкой.',
                          actionLabel: 'Выбрать дерево',
                          onAction: () => context.go(Routes.catalog),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: _Header()),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                    sliver: SliverToBoxAdapter(child: _Summary(trees: trees)),
                  ),
                  if (trees.length > 1)
                    SliverToBoxAdapter(
                      child: _FilterBar(
                        value: _filter,
                        counts: {for (final f in _ForestFilter.values) f: trees.where(f.matches).length},
                        onChanged: (f) => setState(() => _filter = f),
                      ),
                    ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(AppSpacing.page, 16, AppSpacing.page, bottom),
                    sliver: SliverList.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (_, i) => Entrance(
                        key: ValueKey(visible[i].id),
                        delay: Duration(milliseconds: 60 * math.min(i, 8)),
                        builder: (_, t, child) => Opacity(
                          opacity: t,
                          child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
                        ),
                        child: _TreeCard(tree: visible[i], planterMode: state.planterMode),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.page, 16, AppSpacing.page, 16),
      child: Text('Мой лес', style: AppFonts.display(size: 30)),
    );
  }
}

/// Карточка-сводка: мини-лес и количество деревьев по статусам.
class _Summary extends StatelessWidget {
  const _Summary({required this.trees});

  final List<Tree> trees;

  @override
  Widget build(BuildContext context) {
    final n = trees.length;
    int count(TreeStatus s) => trees.where((t) => t.status == s).length;
    final lines = <String>[
      if (count(TreeStatus.growing) > 0)
        '${count(TreeStatus.growing)} ${plural(count(TreeStatus.growing), 'растёт', 'растут', 'растут')}',
      if (count(TreeStatus.awaitingPlanting) > 0)
        '${count(TreeStatus.awaitingPlanting)} ${plural(count(TreeStatus.awaitingPlanting), 'ожидает', 'ожидают', 'ожидают')} посадки',
      if (count(TreeStatus.planted) > 0) '${count(TreeStatus.planted)} посажено',
      if (count(TreeStatus.monitoring) > 0) '${count(TreeStatus.monitoring)} на мониторинге',
    ];
    return Semantics(
      container: true,
      label: 'Сводка: ${treesCount(n)} в вашем лесу',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: ColoredBox(
          color: AppColors.sage,
          child: Column(
            children: [
              _MiniForest(count: n),
              Container(
                color: AppColors.mint,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$n',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppColors.pine,
                            height: 1,
                            fontFeatures: AppFonts.tabular,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${plural(n, 'дерево', 'дерева', 'деревьев')} в вашем лесу',
                          style: const TextStyle(fontSize: 13, color: forestBodyText),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final l in lines)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              l,
                              style: const TextStyle(fontSize: 12, color: forestBodyText, fontFeatures: AppFonts.tabular),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Мини-лес 350×130: деревья вырастают по очереди (scale 0→1, easeOutBack, +70 мс).
class _MiniForest extends StatefulWidget {
  const _MiniForest({required this.count});

  final int count;

  @override
  State<_MiniForest> createState() => _MiniForestState();
}

class _MiniForestState extends State<_MiniForest> with SingleTickerProviderStateMixin {
  static const _treeMs = 450;
  static const _stepMs = 70;
  late final AnimationController _c = AnimationController(vsync: this);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _c.duration = Duration(milliseconds: _treeMs + _stepMs * _MiniForestPainter.maxTrees);
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 350 / 130,
      child: ExcludeSemantics(
        child: CustomPaint(
          painter: _MiniForestPainter(_c, widget.count, (_c.duration ?? Duration.zero).inMilliseconds),
        ),
      ),
    );
  }
}

class _MiniForestPainter extends CustomPainter {
  _MiniForestPainter(this.anim, this.count, this.totalMs) : super(repaint: anim);

  static const maxTrees = 6;

  final Animation<double> anim;
  final int count;
  final int totalMs;

  /// Слоты: x центра и вид дерева (0 — ель, 1 — клён, 2 — малое).
  static const _slots = [(81.0, 0), (171.0, 1), (264.0, 2), (125.0, 2), (218.0, 0), (32.0, 1)];

  static const _trunk = Color(0xFF6B4A2B);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 350);
    canvas.drawPath(
      Path()
        ..moveTo(0, 70)
        ..lineTo(60, 30)
        ..lineTo(110, 55)
        ..lineTo(170, 15)
        ..lineTo(240, 50)
        ..lineTo(300, 25)
        ..lineTo(350, 45)
        ..lineTo(350, 130)
        ..lineTo(0, 130)
        ..close(),
      Paint()..color = const Color(0xFFA3B699),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, 110)
        ..cubicTo(80, 98, 260, 98, 350, 110)
        ..lineTo(350, 130)
        ..lineTo(0, 130)
        ..close(),
      Paint()..color = AppColors.meadow,
    );

    final ms = anim.value * totalMs;
    double pop(int i) => Curves.easeOutBack.transform(((ms - i * 70) / 450).clamp(0.0, 1.0));

    final shown = math.min(count, maxTrees);
    // Деревья справа налево по x рисуем в порядке слотов; на перекрытие не смотрим.
    for (var i = 0; i < shown; i++) {
      final (x, kind) = _slots[i];
      _tree(canvas, x, kind, pop(i));
    }
    if (count < maxTrees) _placeholder(canvas, pop(shown));
  }

  void _tree(Canvas canvas, double x, int kind, double s) {
    if (s <= 0) return;
    final cx = switch (kind) { 0 => 81.0, 1 => 171.0, _ => 264.0 };
    canvas
      ..save()
      ..translate(x, 108)
      ..scale(s)
      ..translate(-cx, -108);
    final trunk = Paint()..color = _trunk;
    switch (kind) {
      case 0:
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(78, 78, 6, 30), const Radius.circular(2)), trunk);
        canvas.drawPath(
          Path()
            ..moveTo(81, 30)
            ..lineTo(100, 66)
            ..lineTo(90, 66)
            ..lineTo(106, 92)
            ..lineTo(56, 92)
            ..lineTo(72, 66)
            ..lineTo(62, 66)
            ..close(),
          Paint()..color = const Color(0xFF2F5A1E),
        );
      case 1:
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(168, 76, 7, 32), const Radius.circular(3)), trunk);
        canvas
          ..drawOval(Rect.fromCenter(center: const Offset(171, 64), width: 60, height: 44), Paint()..color = const Color(0xFFC46A2E))
          ..drawOval(Rect.fromCenter(center: const Offset(184, 58), width: 24, height: 20), Paint()..color = const Color(0xFFE08A43));
      default:
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(262, 92, 4, 16), const Radius.circular(2)), trunk);
        canvas.drawCircle(const Offset(264, 84), 12, Paint()..color = AppColors.leaf);
    }
    canvas.restore();
  }

  /// Пунктирный кружок «+» — место для следующего дерева.
  void _placeholder(Canvas canvas, double s) {
    if (s <= 0) return;
    canvas
      ..save()
      ..translate(310, 108)
      ..scale(s)
      ..translate(-310, -108);
    final p = Paint()
      ..color = AppColors.pine.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const c = Offset(310, 96);
    for (var i = 0; i < 7; i++) {
      final a = i * 2 * math.pi / 7;
      canvas.drawArc(Rect.fromCircle(center: c, radius: 7), a, math.pi / 7, false, p);
    }
    canvas
      ..drawLine(const Offset(310, 92), const Offset(310, 100), p)
      ..drawLine(const Offset(306, 96), const Offset(314, 96), p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MiniForestPainter old) => old.count != count || old.anim != anim;
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.value, required this.counts, required this.onChanged});

  final _ForestFilter value;
  final Map<_ForestFilter, int> counts;
  final ValueChanged<_ForestFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final filters = [for (final f in _ForestFilter.values) if (f == _ForestFilter.all || (counts[f] ?? 0) > 0) f];
    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, 16, AppSpacing.page, 0),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = filters[i];
          final selected = f == value;
          return Semantics(
            button: true,
            selected: selected,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.pine : AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  boxShadow: selected ? null : AppShadows.tile,
                ),
                child: Text(
                  f == _ForestFilter.all ? f.label : '${f.label} ${counts[f]}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.white : AppColors.muted,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TreeCard extends StatelessWidget {
  const _TreeCard({required this.tree, required this.planterMode});

  final Tree tree;
  final bool planterMode;

  @override
  Widget build(BuildContext context) {
    final species = speciesById(tree.speciesId);
    final meta = switch (tree.status) {
      TreeStatus.growing => 'Выращено на ${(tree.progress * 100).round()}%',
      TreeStatus.awaitingPlanting => 'Место и дата — после подтверждения',
      _ => [
          if (tree.plantedAt != null) formatDate(tree.plantedAt!),
          if (tree.locationName != null) tree.locationName!,
        ].join(' · '),
    };
    final showConfirm = planterMode && tree.status == TreeStatus.awaitingPlanting;

    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(tree.isGrowing ? Routes.growth(tree.id) : Routes.tree(tree.id)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 96,
                      height: 112,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: tree.isPlanted
                            ? TreePhoto(tree: tree, species: species, height: 112, radius: 0)
                            : ColoredBox(
                                color: AppColors.mint,
                                child: Align(
                                  alignment: const Alignment(0, 0.3),
                                  child: TreeArt(
                                    size: 92,
                                    stage: tree.isGrowing ? tree.stage : GrowthStage.ready,
                                    sway: false,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TreeStatusBadge(tree.status),
                          const SizedBox(height: 4),
                          Text(
                            tree.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.display(size: 20),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${species.name} · ${tree.code}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: AppColors.muted, fontFeatures: AppFonts.tabular),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            meta,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: forestBodyText),
                          ),
                          if (tree.isGrowing) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: tree.progress,
                                minHeight: 6,
                                backgroundColor: AppColors.mint,
                                color: AppColors.leaf,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (showConfirm) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => context.push(Routes.confirmPlanting(tree.id)),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                    icon: const Icon(Icons.task_alt_rounded, size: 18),
                    label: const Text('Подтвердить посадку'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
