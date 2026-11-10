import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme.dart';

const osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const osmUserAgent = 'kz.personaltree.app';

/// Основной цвет текста на светлых плашках (#33402A).
const forestBodyText = Color(0xFF33402A);

/// Слой тайлов OpenStreetMap с единым user-agent.
TileLayer osmTileLayer() => TileLayer(urlTemplate: osmTileUrl, userAgentPackageName: osmUserAgent);

/// Маркер дерева на карте: зелёный кружок с листиком.
class TreeMapPin extends StatelessWidget {
  const TreeMapPin({super.key, this.selected = true, this.size = 36});

  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.leaf : AppColors.muted;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected ? color : AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(color: selected ? AppColors.white : color, width: 2.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Icon(Icons.park_rounded, size: size * 0.5, color: selected ? AppColors.white : color),
    );
  }
}

/// Строка «подпись — значение» в карточке информации.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.muted = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.leaf),
          const SizedBox(width: 10),
          SizedBox(
            width: 112,
            child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: muted ? FontWeight.w400 : FontWeight.w700,
                color: muted ? AppColors.faint : AppColors.ink,
                fontStyle: muted ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Белая карточка с мягкой зелёной тенью (радиус 24).
class BeigeCard extends StatelessWidget {
  const BeigeCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.white;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: c == AppColors.white ? AppShadows.card : null,
      ),
      child: child,
    );
  }
}

/// Форматирование координаты: `43.25870, 76.95350`.
String formatLatLng(LatLng p) => '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';

/// Координаты как в дизайне: `43.2185° N, 76.9282° E`.
String formatLatLngDeg(LatLng p) {
  final lat = '${p.latitude.abs().toStringAsFixed(4)}° ${p.latitude >= 0 ? 'N' : 'S'}';
  final lng = '${p.longitude.abs().toStringAsFixed(4)}° ${p.longitude >= 0 ? 'E' : 'W'}';
  return '$lat, $lng';
}

/// Появление с задержкой: [t] идёт 0→1 по [curve] после [delay].
/// При отключённых анимациях сразу показывает конечное состояние.
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.builder,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
    this.child,
  });

  final Widget Function(BuildContext context, double t, Widget? child) builder;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final Widget? child;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.delay + widget.duration);
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Interval(
      widget.delay.inMilliseconds / (widget.delay + widget.duration).inMilliseconds,
      1,
      curve: widget.curve,
    ),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
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
  Widget build(BuildContext context) =>
      AnimatedBuilder(animation: _t, builder: (ctx, child) => widget.builder(ctx, _t.value, child), child: widget.child);
}
