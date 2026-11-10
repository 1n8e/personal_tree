import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/app_state.dart';
import '../../shared/design.dart';
import '../../shared/format.dart';

/// «Из цифры — в почву»: горы, дерево уходит в почву, нижняя плашка (GrowthDone.dc.html).
class GrowthDoneScreen extends ConsumerStatefulWidget {
  const GrowthDoneScreen({super.key, required this.treeId});

  final String treeId;

  @override
  ConsumerState<GrowthDoneScreen> createState() => _GrowthDoneScreenState();
}

class _GrowthDoneScreenState extends ConsumerState<GrowthDoneScreen> with TickerProviderStateMixin {
  // Слои 0/80/160 мс по 500 мс, «погружение» 600–1800 мс.
  late final AnimationController _enter =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _enter.value = 1;
      _pulse.value = 0.5;
      return;
    }
    _enter.forward();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) _pulse.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    _pulse.dispose();
    super.dispose();
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
    final scale = MediaQuery.sizeOf(context).width / 390;
    return Scaffold(
      backgroundColor: AppColors.sky,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            height: 520 * scale,
            child: ExcludeSemantics(
              child: CustomPaint(painter: _ScenePainter(_enter, _pulse, scale)),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 500,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, 28, 24, 32 + MediaQuery.paddingOf(context).bottom * 0.5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 28,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(AppRadius.chip)),
                            child: Text('100% · ${formatNumber(tree.targetAmount)} из ${formatPrice(tree.targetAmount)}',
                                style: const TextStyle(color: AppColors.pine, fontSize: 12, fontWeight: FontWeight.w800, fontFeatures: AppFonts.tabular)),
                          ),
                          const SizedBox(height: 12),
                          Text('Из цифры — в почву Алматы', style: AppFonts.display(size: 32).copyWith(height: 1.12)),
                          const SizedBox(height: 12),
                          Text(
                            '${tree.displayName} вырос. Передаём заказ партнёрам — они подберут место, посадят дерево и подтвердят посадку фото и координатами.',
                            style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.muted),
                          ),
                          const Spacer(),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.pine,
                                foregroundColor: AppColors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              onPressed: () => context.go(Routes.tree(widget.treeId)),
                              child: const Text('Готово'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Сцена 390×520: солнце, три слоя гор, свечение и «погружающееся» дерево.
class _ScenePainter extends CustomPainter {
  _ScenePainter(this.enter, this.pulse, this.scale) : super(repaint: Listenable.merge([enter, pulse]));

  final Animation<double> enter;
  final Animation<double> pulse;
  final double scale;

  static const _ms = 1800.0;

  static Path _poly(List<double> xy) {
    final p = Path()..moveTo(xy[0], xy[1]);
    for (var i = 2; i < xy.length; i += 2) {
      p.lineTo(xy[i], xy[i + 1]);
    }
    return p..close();
  }

  /// Слой въезжает снизу на 40 px и проявляется за 500 мс после [delay].
  void _layer(Canvas canvas, double delay, void Function() draw) {
    final t = Curves.easeOutCubic.transform(((enter.value * _ms - delay) / 500).clamp(0.0, 1.0));
    if (t <= 0) return;
    canvas.saveLayer(const Rect.fromLTWH(-20, -20, 440, 560), Paint()..color = Color.fromRGBO(0, 0, 0, t));
    canvas.translate(0, 40 * (1 - t));
    draw();
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    canvas.scale(scale);
    Paint f(Color c) => Paint()..color = c;

    canvas.drawCircle(const Offset(300, 110), 36, f(AppColors.sun));

    _layer(canvas, 0, () {
      canvas.drawPath(_poly([-10, 330, 70, 200, 120, 250, 200, 120, 270, 220, 330, 160, 400, 260, 400, 520, -10, 520]), f(AppColors.mountain));
      canvas.drawPath(_poly([184, 146, 200, 120, 218, 150, 206, 144, 200, 154, 192, 144]), f(AppColors.white));
      canvas.drawPath(_poly([318, 178, 330, 160, 344, 182, 334, 178, 330, 186, 324, 178]), f(AppColors.white));
    });
    _layer(canvas, 80, () {
      canvas.drawPath(_poly([-10, 370, 60, 290, 130, 340, 210, 260, 290, 330, 360, 290, 400, 320, 400, 520, -10, 520]), f(AppColors.sage));
    });
    _layer(canvas, 160, () {
      final p = Path()
        ..moveTo(-10, 420)
        ..cubicTo(80, 390, 160, 400, 200, 410)
        ..cubicTo(260, 396, 330, 392, 400, 410)
        ..lineTo(400, 520)
        ..lineTo(-10, 520)
        ..close();
      canvas.drawPath(p, f(AppColors.meadow));
    });

    // Свечение: появляется после 1,6 с, пульсирует 0.25–0.6 и 0.9–1.1.
    if (enter.value * _ms >= 1600 || pulse.value > 0) {
      final k = Curves.easeInOut.transform(pulse.value);
      canvas.save();
      canvas.translate(195, 420);
      canvas.scale(0.9 + 0.2 * k);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 140, height: 32),
        f(AppColors.sun.withValues(alpha: 0.25 + 0.35 * k)),
      );
      canvas.restore();
    }

    // Дерево: 600–1800 мс, за 60% пути уходит в почву (y+12, scale .92).
    final sink = Curves.easeInOutCubic.transform(((enter.value * _ms - 600) / 720).clamp(0.0, 1.0));
    canvas.save();
    canvas.translate(196, 420 + 12 * sink);
    canvas.scale(1 - 0.08 * sink);
    canvas.translate(-196, -420);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(190, 340, 10, 80), const Radius.circular(4)), f(AppColors.soil));
    canvas.drawCircle(const Offset(195, 318), 44, f(AppColors.leaf));
    canvas.drawCircle(const Offset(164, 340), 26, f(AppColors.leafDark));
    canvas.drawCircle(const Offset(226, 336), 28, f(AppColors.leafLight));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.scale != scale;
}
