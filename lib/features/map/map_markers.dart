import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../app/theme.dart';
import '../../data/models.dart';

/// Контур листа из дизайна (viewBox 26×32), кончик внизу.
Path _leafPath(Size size) {
  final sx = size.width / 26;
  final sy = size.height / 32;
  Offset p(double x, double y) => Offset(x * sx, y * sy);
  return Path()
    ..moveTo(p(13, 31).dx, p(13, 31).dy)
    ..cubicTo(p(4, 22).dx, p(4, 22).dy, p(1, 15).dx, p(1, 15).dy, p(3, 8).dx, p(3, 8).dy)
    ..cubicTo(p(6, 1).dx, p(6, 1).dy, p(20, 1).dx, p(20, 1).dy, p(23, 8).dx, p(23, 8).dy)
    ..cubicTo(p(25, 15).dx, p(25, 15).dy, p(22, 22).dx, p(22, 22).dy, p(13, 31).dx, p(13, 31).dy)
    ..close();
}

class _LeafPinPainter extends CustomPainter {
  _LeafPinPainter({required this.fill, required this.stem, required this.shadow});

  final Color fill;
  final bool stem;
  final Color shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _leafPath(size);
    final k = size.width / 26;
    canvas.drawPath(
      path.shift(Offset(0, 4 * k)),
      Paint()
        ..color = shadow
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * k),
    );
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * k
        ..strokeJoin = StrokeJoin.round,
    );
    if (stem) {
      final line = Paint()
        ..color = AppColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * k
        ..strokeCap = StrokeCap.round;
      Offset p(double x, double y) => Offset(x * k, y * size.height / 32);
      canvas.drawLine(p(13, 22), p(13, 10), line);
      canvas.drawLine(p(13, 15), p(9, 12), line);
      canvas.drawLine(p(13, 13), p(17, 10), line);
    }
  }

  @override
  bool shouldRepaint(_LeafPinPainter old) => old.fill != fill || old.stem != stem || old.shadow != shadow;
}

/// Маленький листик — дерево другого жителя.
class CityTreeDot extends StatelessWidget {
  const CityTreeDot({super.key, this.size = 26});

  /// Ширина листа; высота ≈ 1,23 × ширины.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
        size: Size(size, size * 32 / 26),
        painter: _LeafPinPainter(fill: AppColors.sage, stem: false, shadow: const Color(0x00000000)),
      ),
    );
  }
}

/// Кластер из нескольких посадок жителей с числом внутри.
class CityClusterBubble extends StatelessWidget {
  const CityClusterBubble({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.sage,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: 3),
          boxShadow: const [BoxShadow(color: Color(0x2E234010), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Text(
          '$count',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.pineDeep,
            fontFeatures: AppFonts.tabular,
          ),
        ),
      ),
    );
  }
}

/// Лист-пин своего дерева. При выборе подпрыгивает на 14 px (пружина) и темнеет.
/// Новый [hopToken] запускает прыжок повторно.
class OwnTreePin extends StatefulWidget {
  const OwnTreePin({super.key, this.selected = false, this.hopToken = 0});

  static const width = 48.0;
  static const height = 56.0;

  final bool selected;
  final int hopToken;

  @override
  State<OwnTreePin> createState() => _OwnTreePinState();
}

class _OwnTreePinState extends State<OwnTreePin> with SingleTickerProviderStateMixin {
  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  // Ключевые кадры из дизайна: 0 → −14 → 0 → −5 → 0.
  late final Animation<double> _dy = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: -14.0).chain(CurveTween(curve: Curves.easeOut)), weight: 35),
    TweenSequenceItem(tween: Tween(begin: -14.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 25),
    TweenSequenceItem(tween: Tween(begin: 0.0, end: -5.0).chain(CurveTween(curve: Curves.easeOut)), weight: 18),
    TweenSequenceItem(tween: Tween(begin: -5.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 22),
  ]).animate(_hop);

  @override
  void didUpdateWidget(OwnTreePin old) {
    super.didUpdateWidget(old);
    if (widget.selected && (!old.selected || widget.hopToken != old.hopToken)) {
      _hop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _hop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.selected;
    return AnimatedBuilder(
      animation: _dy,
      builder: (context, child) => Transform.translate(offset: Offset(0, _dy.value), child: child),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: on ? 38 : 30,
          height: on ? 46 : 37,
          child: CustomPaint(
            painter: _LeafPinPainter(
              fill: on ? AppColors.pine : AppColors.leaf,
              stem: true,
              shadow: const Color(0x4D234010),
            ),
          ),
        ),
      ),
    );
  }
}

/// Группа посадок для самодельной кластеризации.
class TreeCluster {
  TreeCluster(this.trees);

  final List<Tree> trees;

  LatLng get center {
    var lat = 0.0;
    var lng = 0.0;
    for (final t in trees) {
      lat += t.location!.latitude;
      lng += t.location!.longitude;
    }
    return LatLng(lat / trees.length, lng / trees.length);
  }
}

/// Простая сеточная кластеризация в пикселях проекции Меркатора.
/// На крупных масштабах (zoom ≥ 15) деревья показываются по одному.
List<TreeCluster> clusterTrees(List<Tree> trees, int zoom, {double cellPx = 44}) {
  if (zoom >= 15) return [for (final t in trees) TreeCluster([t])];
  final scale = 256 * math.pow(2, zoom);
  final cells = <(int, int), List<Tree>>{};
  for (final t in trees) {
    final p = t.location!;
    final x = (p.longitude + 180) / 360 * scale;
    final latRad = p.latitude * math.pi / 180;
    final y = (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) / 2 * scale;
    final key = ((x / cellPx).floor(), (y / cellPx).floor());
    (cells[key] ??= []).add(t);
  }
  return [for (final list in cells.values) TreeCluster(list)];
}
