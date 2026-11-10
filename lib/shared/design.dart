import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../data/models.dart';

/// Общие элементы дизайна Personal Tree: логотип, топографический фон,
/// нарисованное дерево, кольцо роста, лист. Используются всеми экранами.

/// Логотип «Personal tree» на голубой плашке неровной формы.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 22});

  /// Кегль надписи: 18 на главной, 22 в шапках, 40 на splash.
  final double size;

  @override
  Widget build(BuildContext context) {
    final k = size / 22;
    return Container(
      padding: EdgeInsets.fromLTRB(10 * k, 6 * k, 14 * k, 6 * k),
      decoration: BoxDecoration(
        color: AppColors.sky,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22 * k),
          topRight: Radius.circular(26 * k),
          bottomRight: Radius.circular(20 * k),
          bottomLeft: Radius.circular(24 * k),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LeafIcon(size: 18 * k, color: AppColors.leaf, outlined: true),
          SizedBox(width: 6 * k),
          Text('Personal tree', style: AppFonts.hand(size: size)),
        ],
      ),
    );
  }
}

/// Лист: контурный (как в логотипе и меню) или залитый (индикаторы, частицы).
class LeafIcon extends StatelessWidget {
  const LeafIcon({super.key, this.size = 24, this.color = AppColors.leaf, this.outlined = false});

  final double size;
  final Color color;
  final bool outlined;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _LeafPainter(color, outlined));
}

class _LeafPainter extends CustomPainter {
  _LeafPainter(this.color, this.outlined);
  final Color color;
  final bool outlined;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    if (outlined) {
      final p = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.75
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final leaf = Path()
        ..moveTo(11, 20)
        ..arcToPoint(const Offset(9.8, 6.1), radius: const Radius.circular(7))
        ..cubicTo(15.5, 5, 17, 4.48, 19, 2)
        ..cubicTo(20, 4, 21, 6.18, 21, 10)
        ..cubicTo(21, 15.5, 16.22, 20, 11, 20)
        ..close();
      final stem = Path()
        ..moveTo(2, 21)
        ..cubicTo(2, 18, 3.85, 15.64, 7.08, 15)
        ..cubicTo(9.5, 14.52, 12, 13, 13, 12);
      canvas
        ..drawPath(leaf, p)
        ..drawPath(stem, p);
    } else {
      final path = Path()
        ..moveTo(12, 22)
        ..cubicTo(6, 18, 4, 12, 6, 4)
        ..cubicTo(14, 4, 20, 10, 18, 18)
        ..cubicTo(16, 21, 14, 22, 12, 22)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_LeafPainter old) => old.color != color || old.outlined != outlined;
}

/// Едва заметные топографические линии на фоне экранов (opacity 0.05).
class TopoBackground extends StatelessWidget {
  const TopoBackground({super.key, this.shift = 0, this.child});

  /// Горизонтальный сдвиг для параллакса онбординга.
  final double shift;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.cream),
        Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: _TopoPainter(shift))),
        ),
        ?child,
      ],
    );
  }
}

class _TopoPainter extends CustomPainter {
  _TopoPainter(this.shift);
  final double shift;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.pine.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final w = size.width;
    void band(double top, int count) {
      for (var i = 0; i < count; i++) {
        final y = top + i * 40;
        final path = Path()..moveTo(-20 - shift, y);
        for (var x = -20.0; x < w + 400; x += 260) {
          path.cubicTo(x + 90 - shift, y - 40, x + 170 - shift, y + 50, x + 260 - shift, y + 5);
        }
        canvas.drawPath(path, p);
      }
    }

    band(size.height * 0.1, 3);
    band(size.height * 0.72, 4);
  }

  @override
  bool shouldRepaint(_TopoPainter old) => old.shift != shift;
}

/// Нарисованное дерево: крона из трёх кругов, ствол, тень.
/// [stage] задаёт размер — от семени до готового дерева.
/// [sway] — лёгкое покачивание ±2° (4 с), отключается при reduce motion.
class TreeArt extends StatefulWidget {
  const TreeArt({super.key, this.size = 140, this.stage = GrowthStage.ready, this.sway = true, this.background});

  final double size;
  final GrowthStage stage;
  final bool sway;

  /// Круг-подложка за деревом (например [AppColors.cream] на главной).
  final Color? background;

  @override
  State<TreeArt> createState() => _TreeArtState();
}

class _TreeArtState extends State<TreeArt> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 4));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (widget.sway && !reduce) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          painter: _TreePainter(
            stage: widget.stage,
            angle: math.sin(_c.value * 2 * math.pi) * 2 * math.pi / 180,
            background: widget.background,
          ),
        ),
      ),
    );
  }
}

class _TreePainter extends CustomPainter {
  _TreePainter({required this.stage, required this.angle, this.background});
  final GrowthStage stage;
  final double angle;
  final Color? background;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 140);
    if (background != null) canvas.drawCircle(const Offset(70, 70), 50, Paint()..color = background!);
    canvas.drawOval(Rect.fromCenter(center: const Offset(70, 104), width: 60, height: 12), Paint()..color = AppColors.sage);

    final ground = const Offset(70, 104);
    void sway(void Function() draw) {
      canvas
        ..save()
        ..translate(ground.dx, ground.dy)
        ..rotate(angle)
        ..translate(-ground.dx, -ground.dy);
      draw();
      canvas.restore();
    }

    final stroke = Paint()
      ..color = AppColors.leaf
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    switch (stage) {
      case GrowthStage.seed:
        canvas.drawOval(Rect.fromCenter(center: const Offset(70, 98), width: 14, height: 18), Paint()..color = AppColors.soil);
      case GrowthStage.sprout:
        sway(() {
          canvas.drawLine(const Offset(70, 104), const Offset(70, 82), stroke);
          _leaf(canvas, const Offset(70, 86), -1, 14, AppColors.leaf);
          _leaf(canvas, const Offset(70, 84), 1, 16, AppColors.leafLight);
        });
      case GrowthStage.sapling:
        sway(() {
          canvas.drawLine(const Offset(70, 104), const Offset(70, 66), stroke);
          _leaf(canvas, const Offset(70, 76), -1, 20, AppColors.leaf);
          _leaf(canvas, const Offset(70, 70), 1, 22, AppColors.leafLight);
          _leaf(canvas, const Offset(70, 90), 1, 14, AppColors.leaf);
        });
      case GrowthStage.young || GrowthStage.ready:
        final k = stage == GrowthStage.ready ? 1.0 : 0.8;
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(67, 70 + (1 - k) * 20, 6, 34 - (1 - k) * 20), const Radius.circular(3)),
          Paint()..color = AppColors.soil,
        );
        sway(() {
          final dy = (1 - k) * 18;
          canvas
            ..drawCircle(Offset(70, 60 + dy), 22 * k, Paint()..color = AppColors.leaf)
            ..drawCircle(Offset(56 + (1 - k) * 4, 70 + dy), 13 * k, Paint()..color = AppColors.leafDark)
            ..drawCircle(Offset(84 - (1 - k) * 4, 68 + dy), 14 * k, Paint()..color = AppColors.leafLight);
        });
    }
  }

  void _leaf(Canvas canvas, Offset base, int dir, double len, Color color) {
    final tip = base + Offset(dir * len * 0.8, -len);
    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(base.dx + dir * len * 0.1, tip.dy + len * 0.2, tip.dx, tip.dy)
      ..quadraticBezierTo(tip.dx - dir * len * 0.1, base.dy - len * 0.2, base.dx, base.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TreePainter old) => old.stage != stage || old.angle != angle || old.background != background;
}

/// Кольцо прогресса роста: от прежнего значения к новому (600–900 мс, easeOutCubic).
class GrowthRing extends StatelessWidget {
  const GrowthRing({
    super.key,
    required this.progress,
    this.size = 140,
    this.stroke = 10,
    this.child,
    this.duration = const Duration(milliseconds: 900),
  });

  final double progress;
  final double size;
  final double stroke;
  final Widget? child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: progress),
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration,
        curve: Curves.easeOutCubic,
        builder: (_, value, child) => CustomPaint(
          painter: _RingPainter(value, stroke),
          child: Center(child: child),
        ),
        child: child,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.stroke);
  final double value;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    final track = Paint()
      ..color = AppColors.mint
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(r, 0, 2 * math.pi, false, track);
    if (value <= 0) return;
    final fill = Paint()
      ..color = AppColors.leaf
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, -math.pi / 2, 2 * math.pi * value, false, fill);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.stroke != stroke;
}

/// Белая карточка дизайна: радиус 24, мягкая зелёная тень.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = AppColors.white,
    this.radius = AppRadius.card,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: color == AppColors.white ? AppShadows.card : null,
      ),
      child: Material(
        color: color,
        borderRadius: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
      ),
    );
  }
}

/// Квадратная кнопка «Назад» на белой плашке 48×48 из шапок дизайна.
class RoundBackButton extends StatelessWidget {
  const RoundBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.button),
          boxShadow: AppShadows.tile,
        ),
        child: IconButton(
          tooltip: 'Назад',
          onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.pine, size: 22),
        ),
      ),
    );
  }
}

/// Нажатие кнопок: scale 0.96 за 150 мс.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child});
  final Widget child;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 150),
        child: widget.child,
      ),
    );
  }
}
