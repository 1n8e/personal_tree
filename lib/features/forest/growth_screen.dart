import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../shared/design.dart';
import '../../shared/format.dart';

/// Рост дерева: кольцо прогресса, стадии, пополнение и «капли» монет (Growth.dc.html).
class GrowthScreen extends ConsumerStatefulWidget {
  const GrowthScreen({super.key, required this.treeId});

  final String treeId;

  @override
  ConsumerState<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends ConsumerState<GrowthScreen> with SingleTickerProviderStateMixin {
  static const _amounts = [1000, 2000, 3000];
  static const _dropCount = 7;
  static const _burstMs = 900 + (_dropCount - 1) * 80;

  late final AnimationController _burst =
      AnimationController(vsync: this, duration: const Duration(milliseconds: _burstMs));
  int _amount = 2000;
  int _points = 0;
  bool _bursting = false;

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  Future<void> _topUp() async {
    final controller = ref.read(appControllerProvider.notifier);
    controller.topUp(treeId: widget.treeId, amount: _amount);
    HapticFeedback.lightImpact();
    final tree = ref.read(appControllerProvider).treeById(widget.treeId);
    final done = tree != null && !tree.isGrowing;
    if (MediaQuery.disableAnimationsOf(context)) {
      if (done) context.pushReplacement(Routes.growthDone(widget.treeId));
      return;
    }
    setState(() {
      _points = _amount ~/ 100;
      _bursting = true;
    });
    await _burst.forward(from: 0);
    if (!mounted) return;
    setState(() => _bursting = false);
    if (done) context.pushReplacement(Routes.growthDone(widget.treeId));
  }

  @override
  Widget build(BuildContext context) {
    final tree = ref.watch(appControllerProvider).treeById(widget.treeId);
    if (tree == null) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(16, 8, 0, 0), child: Align(alignment: Alignment.centerLeft, child: RoundBackButton(onPressed: () => context.go(Routes.home)))),
            const Expanded(child: Center(child: Text('Дерево не найдено', style: TextStyle(color: AppColors.muted)))),
          ]),
        ),
      );
    }
    final species = speciesById(tree.speciesId);
    final pct = (tree.progress * 100).round();
    final stage = tree.stage;
    final full = !tree.isGrowing;
    final reduce = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  children: [
                    Row(
                      children: [
                        RoundBackButton(onPressed: () => context.canPop() ? context.pop() : context.go(Routes.home)),
                        Expanded(
                          child: Column(children: [
                            Text(tree.displayName, style: AppFonts.display(size: 22)),
                            Text('${species.name} · ${tree.code}',
                                style: const TextStyle(fontSize: 12, color: AppColors.muted, fontFeatures: AppFonts.tabular)),
                          ]),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: 280,
                      height: 280,
                      child: Stack(clipBehavior: Clip.none, children: [
                        GrowthRing(
                          progress: tree.progress,
                          size: 280,
                          stroke: 16,
                          duration: const Duration(milliseconds: 600),
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                            clipBehavior: Clip.antiAlias,
                            alignment: Alignment.bottomCenter,
                            child: AnimatedSwitcher(
                              duration: reduce ? Duration.zero : const Duration(milliseconds: 450),
                              switchInCurve: Curves.easeOutBack,
                              transitionBuilder: (child, a) => FadeTransition(
                                opacity: a,
                                child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(a), child: child),
                              ),
                              child: Semantics(
                                label: 'Стадия: ${stage.label}',
                                key: ValueKey(stage),
                                child: TreeArt(size: 200, stage: stage),
                              ),
                            ),
                          ),
                        ),
                        if (_bursting) ..._drops(),
                        if (_bursting) _pointsLabel(),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    Text('$pct%',
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.pine, height: 1, fontFeatures: AppFonts.tabular)),
                    const SizedBox(height: 6),
                    Text('${formatPrice(tree.paidAmount)} из ${formatPrice(tree.targetAmount)} · стадия «${stage.label}»',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: AppColors.muted, fontFeatures: AppFonts.tabular)),
                    const SizedBox(height: 20),
                    _stages(stage),
                    const SizedBox(height: 20),
                    _amountCard(full),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: full ? AppColors.leaf : AppColors.pine,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        onPressed: _bursting
                            ? null
                            : full
                                ? () => context.pushReplacement(Routes.growthDone(widget.treeId))
                                : _topUp,
                        child: Text(full ? 'Из цифры — в почву' : 'Пополнить на ${formatPrice(_amount)}'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Капли-монеты: падают в кольцо с отскоком, шаг 80 мс.
  List<Widget> _drops() => [
        for (var i = 0; i < _dropCount; i++)
          Positioned(
            left: 70.0 + i * 22,
            top: 150,
            child: AnimatedBuilder(
              animation: _burst,
              builder: (_, child) {
                final t = ((_burst.value * _burstMs - i * 80) / 900).clamp(0.0, 1.0);
                return Opacity(opacity: _dropOpacity(t), child: Transform.translate(offset: Offset(0, _dropY(t)), child: child));
              },
              child: const CustomPaint(size: Size(22, 26), painter: _CoinPainter()),
            ),
          ),
      ];

  static double _dropY(double t) {
    if (t < 0.7) return -120 * (1 - Curves.easeIn.transform(t / 0.7));
    if (t < 0.82) return -10 * Curves.easeOut.transform((t - 0.7) / 0.12);
    return -10 * (1 - Curves.easeIn.transform((t - 0.82) / 0.18));
  }

  static double _dropOpacity(double t) {
    if (t <= 0) return 0;
    if (t < 0.15) return t / 0.15;
    if (t < 0.82) return 1;
    return 1 - (t - 0.82) / 0.18;
  }

  /// «+N эко-баллов»: всплывает на 24 px и гаснет за 900 мс, старт через 500 мс.
  Widget _pointsLabel() => Positioned(
        right: -6,
        top: 12,
        child: AnimatedBuilder(
          animation: _burst,
          builder: (_, child) {
            final t = ((_burst.value * _burstMs - 500) / 900).clamp(0.0, 1.0);
            final o = t <= 0 ? 0.0 : t < 0.2 ? t / 0.2 : 1 - (t - 0.2) / 0.8;
            return Opacity(opacity: o, child: Transform.translate(offset: Offset(0, -24 * Curves.easeOutCubic.transform(t)), child: child));
          },
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.pine, borderRadius: BorderRadius.circular(AppRadius.chip)),
            child: Text('+$_points эко-баллов', style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w800)),
          ),
        ),
      );

  Widget _stages(GrowthStage current) => Row(
        children: [
          for (final s in GrowthStage.values) ...[
            if (s.index > 0) const SizedBox(width: 4),
            Expanded(
              child: Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 6,
                  decoration: BoxDecoration(
                    color: s.index <= current.index ? AppColors.leaf : AppColors.mint,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 6),
                Text(s.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: s == current ? FontWeight.w800 : FontWeight.w600,
                      color: s == current ? AppColors.pine : AppColors.muted,
                    )),
              ]),
            ),
          ],
        ],
      );

  Widget _amountCard(bool full) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Сумма пополнения', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(children: [
              for (final v in _amounts) ...[
                if (v != _amounts.first) const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: full ? null : () => setState(() => _amount = v),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: v == _amount ? AppColors.mint : AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: v == _amount ? AppColors.leaf : AppColors.sage, width: 1.5),
                      ),
                      child: Text(formatPrice(v),
                          style: const TextStyle(color: AppColors.pine, fontSize: 15, fontWeight: FontWeight.w700, fontFeatures: AppFonts.tabular)),
                    ),
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 12),
            const Text('Каждые 1 000 ₸ = +10 эко-баллов', style: TextStyle(fontSize: 13, color: AppColors.muted)),
          ],
        ),
      );
}

/// Золотая капля-монета из дизайна (viewBox 24×28).
class _CoinPainter extends CustomPainter {
  const _CoinPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 28);
    final p = Path()
      ..moveTo(12, 2)
      ..cubicTo(12, 2, 20, 11, 20, 17)
      ..arcToPoint(const Offset(4, 17), radius: const Radius.circular(8), clockwise: true)
      ..cubicTo(4, 11, 12, 2, 12, 2)
      ..close();
    canvas.drawPath(p, Paint()..color = AppColors.awaitingDot);
    canvas.drawPath(
      p,
      Paint()
        ..color = const Color(0xFFB5832A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_CoinPainter old) => false;
}
