import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/app_state.dart';
import '../../shared/design.dart';
import 'auth_widgets.dart';

/// Splash: семя падает, из него вырастает росток, раскрываются два листа,
/// проявляется логотип. Дальше — автопереход или кнопка «Продолжить».
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  Timer? _auto;
  bool _left = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.isCompleted || _auto != null) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
      _auto = Timer(const Duration(milliseconds: 1200), _next);
    } else {
      _c.forward().whenComplete(() {
        if (mounted) _auto = Timer(const Duration(milliseconds: 700), _next);
      });
    }
  }

  @override
  void dispose() {
    _auto?.cancel();
    _c.dispose();
    super.dispose();
  }

  /// Дом — если вошли, иначе онбординг (первый раз) или вход.
  void _next() {
    if (_left || !mounted) return;
    _left = true;
    final s = ref.read(appControllerProvider);
    context.go(s.isLoggedIn ? Routes.home : (s.hasSeenOnboarding ? Routes.login : Routes.onboarding));
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final dy = (h - 844) / 2;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const TopoBackground(),
          Positioned.fill(
            child: ExcludeSemantics(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, _) => CustomPaint(painter: _SproutPainter(_c.value, dy)),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 200 + dy,
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, child) {
                final k = Curves.easeOutCubic.transform(((_c.value - 0.68) / 0.17).clamp(0.0, 1.0));
                return Opacity(
                  opacity: k,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - k)),
                    child: Transform.scale(scale: 0.94 + 0.06 * k, child: child),
                  ),
                );
              },
              child: const Center(child: _SplashLogo()),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 120,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Посади сегодня,\nдыши завтра',
                  textAlign: TextAlign.center,
                  style: AppFonts.display(size: 28).copyWith(height: 1.2),
                ),
                const SizedBox(height: 10),
                const Text('Озеленяем Алматы вместе', style: TextStyle(fontSize: 15, color: AppColors.muted)),
              ],
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, child) {
                final k = ((_c.value - 0.8) / 0.2).clamp(0.0, 1.0);
                return IgnorePointer(ignoring: k < 1, child: Opacity(opacity: k, child: child));
              },
              child: SizedBox(
                height: 52,
                child: FilledButton(onPressed: _next, child: const Text('Продолжить')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Крупный логотип splash: плашка неровной формы, лист и надпись Caveat 40.
class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Personal tree',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 24, 12),
          decoration: const BoxDecoration(
            color: AppColors.sky,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(34),
              topRight: Radius.circular(40),
              bottomRight: Radius.circular(30),
              bottomLeft: Radius.circular(38),
            ),
            boxShadow: [BoxShadow(color: Color(0x14234010), blurRadius: 24, offset: Offset(0, 8))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LeafIcon(size: 26, color: AppColors.leaf, outlined: true),
              const SizedBox(width: 8),
              Text('Personal tree', style: AppFonts.hand(size: 40)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Семя, росток и два листа. Координаты — из SVG 390×844, центрируются по высоте.
class _SproutPainter extends CustomPainter {
  _SproutPainter(this.t, this.dy);
  final double t;
  final double dy;

  static final _stem = svgPath('M195 470 C195 440 196 420 195 392');
  static final _leafA = svgPath('M195 402 C176 398 164 384 166 364 C184 366 196 380 195 402Z');
  static final _leafB = svgPath('M196 396 C214 392 228 376 226 354 C206 358 194 374 196 396Z');

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate((size.width - 390) / 2, dy);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(195, 486), width: 240, height: 44),
      Paint()..color = AppColors.sage,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(195, 480), width: 192, height: 28),
      Paint()..color = AppColors.soilLight.withValues(alpha: 0.85),
    );

    // Росток: scaleY 0 → 1.08 → 1 от основания.
    final double sy;
    if (t <= 0.3) {
      sy = 0;
    } else if (t <= 0.55) {
      sy = 1.08 * Curves.easeOutBack.transform((t - 0.3) / 0.25).clamp(0.0, 1.2);
    } else {
      sy = lerpDouble(1.08, 1, ((t - 0.55) / 0.07).clamp(0.0, 1.0))!;
    }
    if (sy > 0) {
      canvas
        ..save()
        ..translate(195, 470)
        ..scale(1, sy)
        ..translate(-195, -470)
        ..drawPath(
          _stem,
          Paint()
            ..color = AppColors.leaf
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round,
        )
        ..restore();
    }

    // Листья: поворот 40° → 0 и масштаб 0 → 1 вокруг нижней точки.
    final u = Curves.easeOutBack.transform(((t - 0.5) / 0.2).clamp(0.0, 1.0));
    void leaf(Path p, Offset pivot, Color color) {
      if (u <= 0) return;
      canvas
        ..save()
        ..translate(pivot.dx, pivot.dy)
        ..rotate(40 * math.pi / 180 * (1 - u))
        ..scale(u)
        ..translate(-pivot.dx, -pivot.dy)
        ..drawPath(p, Paint()..color = color)
        ..restore();
    }

    leaf(_leafA, const Offset(180.5, 402), AppColors.leaf);
    leaf(_leafB, const Offset(211, 396), AppColors.leafLight);

    // Семя падает за первые 28% и остаётся у земли.
    final fall = Curves.easeIn.transform((t / 0.28).clamp(0.0, 1.0));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(195, 466 - 260 * (1 - fall)), width: 18, height: 24),
      Paint()..color = AppColors.soil.withValues(alpha: (t / 0.1).clamp(0.0, 1.0)),
    );
  }

  @override
  bool shouldRepaint(_SproutPainter old) => old.t != t || old.dy != dy;
}
