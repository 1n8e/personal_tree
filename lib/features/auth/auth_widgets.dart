import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/design.dart';

/// Мини-парсер SVG-пути (M L H V C S Z и их строчные варианты) —
/// чтобы переносить контуры из дизайна «как есть».
Path svgPath(String d) {
  final tokens = RegExp(r'([a-zA-Z])|([-+]?(?:\d+\.?\d*|\.\d+))').allMatches(d).map((m) => m.group(0)!).toList();
  const argc = {'m': 2, 'l': 2, 'h': 1, 'v': 1, 'c': 6, 's': 4, 'z': 0};
  final path = Path();
  var i = 0;
  var x = 0.0, y = 0.0, sx = 0.0, sy = 0.0;
  var cpx = 0.0, cpy = 0.0; // последняя контрольная точка для S
  String? cmd;
  while (i < tokens.length) {
    if (RegExp(r'[a-zA-Z]').hasMatch(tokens[i])) cmd = tokens[i++];
    final lower = cmd!.toLowerCase();
    final rel = cmd == lower;
    final n = argc[lower]!;
    final a = <double>[for (var k = 0; k < n; k++) double.parse(tokens[i + k])];
    i += n;
    final ox = rel ? x : 0.0, oy = rel ? y : 0.0;
    switch (lower) {
      case 'm':
        x = ox + a[0];
        y = oy + a[1];
        sx = x;
        sy = y;
        path.moveTo(x, y);
        cmd = rel ? 'l' : 'L';
        cpx = x;
        cpy = y;
      case 'l':
        x = ox + a[0];
        y = oy + a[1];
        path.lineTo(x, y);
        cpx = x;
        cpy = y;
      case 'h':
        x = ox + a[0];
        path.lineTo(x, y);
        cpx = x;
        cpy = y;
      case 'v':
        y = oy + a[0];
        path.lineTo(x, y);
        cpx = x;
        cpy = y;
      case 'c':
        path.cubicTo(ox + a[0], oy + a[1], ox + a[2], oy + a[3], ox + a[4], oy + a[5]);
        cpx = ox + a[2];
        cpy = oy + a[3];
        x = ox + a[4];
        y = oy + a[5];
      case 's':
        final c1x = 2 * x - cpx, c1y = 2 * y - cpy;
        path.cubicTo(c1x, c1y, ox + a[0], oy + a[1], ox + a[2], oy + a[3]);
        cpx = ox + a[0];
        cpy = oy + a[1];
        x = ox + a[2];
        y = oy + a[3];
      case 'z':
        path.close();
        x = sx;
        y = sy;
        cpx = x;
        cpy = y;
    }
  }
  return path;
}

/// Едва заметные листья, медленно падающие на фоне экрана входа (opacity 0.25).
/// Цикл 9 и 11 секунд, как в дизайне; при reduce motion — неподвижны.
class FloatingLeaves extends StatefulWidget {
  const FloatingLeaves({super.key});

  @override
  State<FloatingLeaves> createState() => _FloatingLeavesState();
}

class _FloatingLeavesState extends State<FloatingLeaves> with SingleTickerProviderStateMixin {
  // 99 с — общее кратное 9 и 11, одного контроллера хватает на обе группы.
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 99));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce && _started) {
      _c.stop();
      _started = false;
    } else if (!reduce && !_started) {
      _c.repeat();
      _started = true;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // x, y, размер, цвет, длительность цикла, направление.
    const leaves = [
      (300.0, 120.0, 34.0, AppColors.leaf, 9, 1.0),
      (40.0, 300.0, 24.0, AppColors.leaf, 11, -1.0),
      (330.0, 520.0, 20.0, AppColors.leafLight, 9, 1.0),
      (160.0, 700.0, 28.0, AppColors.leaf, 11, -1.0),
    ];
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Stack(
            children: [
              for (final l in leaves)
                () {
                  final phase = (_c.value * 99 / l.$5) % 1;
                  final half = phase < 0.5;
                  final k = half ? phase * 2 : (phase - 0.5) * 2;
                  final dx = l.$6 * (half ? lerpDouble(0, 18, k)! : lerpDouble(18, 0, k)!);
                  final dy = half ? lerpDouble(0, 40, k)! : lerpDouble(40, 80, k)!;
                  final rot = l.$6 * (half ? lerpDouble(0, 40, k)! : lerpDouble(40, 80, k)!) * 0.0174533;
                  return Positioned(
                    left: l.$1,
                    top: l.$2,
                    child: Opacity(
                      opacity: 0.25 * (half ? 1 : 1 - k),
                      child: Transform.translate(
                        offset: Offset(dx, dy),
                        child: Transform.rotate(angle: rot, child: LeafIcon(size: l.$3, color: l.$4)),
                      ),
                    ),
                  );
                }(),
            ],
          ),
        ),
      ),
    );
  }
}
