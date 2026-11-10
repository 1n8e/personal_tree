import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/app_state.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../shared/design.dart';
import 'map_markers.dart';
import 'map_tree_sheet.dart';

/// Карта посадок Алматы. На карте только посаженные деревья:
/// у ожидающих посадки ещё нет координат.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key, this.focusTreeId});

  final String? focusTreeId;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with SingleTickerProviderStateMixin {
  static const _initialZoom = 12.0;
  static const _focusZoom = 15.5;
  static final _cityBounds = LatLngBounds(const LatLng(43.10, 76.70), const LatLng(43.40, 77.15));

  final _mapController = MapController();
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );
  VoidCallback? _animListener;

  bool _mapReady = false;
  bool _onlyMine = false;

  /// Тайлы не загрузились (нет сети / DNS) — показываем плашку вместо пустого фона.
  bool _tilesFailed = false;
  int _zoomBucket = _initialZoom.floor();
  String? _selectedId;
  int _hopToken = 0;
  String? _handledFocusId;

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusTreeId != oldWidget.focusTreeId) {
      _handledFocusId = null;
      if (_mapReady) _scheduleFocus();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ---------- Камера ----------

  void _animateTo(LatLng target, double zoom) {
    if (!_mapReady) return;
    final camera = _mapController.camera;
    final startCenter = camera.center;
    final startZoom = camera.zoom;
    final curve = CurvedAnimation(parent: _anim, curve: Curves.easeInOutCubic);
    if (_animListener != null) _anim.removeListener(_animListener!);
    _animListener = () {
      final t = curve.value;
      _mapController.move(
        LatLng(
          startCenter.latitude + (target.latitude - startCenter.latitude) * t,
          startCenter.longitude + (target.longitude - startCenter.longitude) * t,
        ),
        startZoom + (zoom - startZoom) * t,
      );
    };
    _anim
      ..addListener(_animListener!)
      ..forward(from: 0);
  }

  void _recenter() => _animateTo(MockData.almatyCenter, _initialZoom);

  // ---------- Фокус по ?tree=id ----------

  void _scheduleFocus() {
    final id = widget.focusTreeId;
    if (id == null || id == _handledFocusId) return;
    _handledFocusId = id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tree = ref.read(appControllerProvider).treeById(id);
      if (tree == null) return;
      if (tree.location == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Дерево ещё не посажено — оно появится на карте после подтверждения')),
        );
        return;
      }
      if (!tree.isMine && _onlyMine) setState(() => _onlyMine = false);
      _animateTo(tree.location!, _focusZoom);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _select(tree);
      });
    });
  }

  void _select(Tree tree) {
    setState(() {
      _selectedId = tree.id;
      _hopToken++;
    });
  }

  void _setOnlyMine(bool value) {
    setState(() {
      _onlyMine = value;
      // Выбранное чужое дерево исчезает вместе с остальными.
      if (value && _selectedId != null && !(ref.read(appControllerProvider).treeById(_selectedId!)?.isMine ?? true)) {
        _selectedId = null;
      }
    });
  }

  // ---------- UI ----------

  /// Топографическая подложка OpenTopoMap: рельеф и горы Заилийского Алатау.
  /// Лёгкий тёплый тон, чтобы карта сочеталась с кремовым фоном и не спорила с пинами.
  static const _tileTint = ColorFilter.matrix(<double>[
    0.82, 0.14, 0.04, 0, 8, //
    0.08, 0.86, 0.06, 0, 8, //
    0.06, 0.14, 0.72, 0, 6, //
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final mine = [for (final t in state.plantedTrees) if (t.location != null) t];
    final city = [for (final t in state.cityTrees) if (t.location != null) t];
    final selected = _selectedId == null ? null : state.treeById(_selectedId!);
    final insets = MediaQuery.paddingOf(context);

    final cityMarkers = <Marker>[
      for (final c in clusterTrees(city, _zoomBucket))
        if (c.trees.length == 1)
          Marker(
            point: c.trees.first.location!,
            width: 44,
            height: 44,
            alignment: Alignment.topCenter,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _select(c.trees.first),
              child: Center(child: CityTreeDot(size: c.trees.first.id == _selectedId ? 30 : 26)),
            ),
          )
        else
          Marker(
            point: c.center,
            width: 44,
            height: 44,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _animateTo(c.center, (_mapController.camera.zoom + 2).clamp(10.0, 18.0)),
              child: CityClusterBubble(count: c.trees.length),
            ),
          ),
    ];
    final myMarkers = <Marker>[
      for (final t in mine)
        Marker(
          point: t.location!,
          width: OwnTreePin.width,
          height: OwnTreePin.height,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _select(t),
            child: OwnTreePin(selected: t.id == _selectedId, hopToken: _hopToken),
          ),
        ),
    ];

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: MockData.almatyCenter,
              initialZoom: _initialZoom,
              minZoom: 10,
              maxZoom: 18,
              backgroundColor: AppColors.cream,
              cameraConstraint: CameraConstraint.containCenter(bounds: _cityBounds),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onMapReady: () {
                _mapReady = true;
                _scheduleFocus();
              },
              onTap: (_, _) {
                if (_selectedId != null) setState(() => _selectedId = null);
              },
              onPositionChanged: (camera, _) {
                final bucket = camera.zoom.floor();
                if (bucket != _zoomBucket) setState(() => _zoomBucket = bucket);
              },
            ),
            children: [
              ColorFiltered(
                colorFilter: _tileTint,
                child: TileLayer(
                  urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  maxNativeZoom: 17,
                  userAgentPackageName: 'kz.personaltree.app',
                  errorTileCallback: (_, _, _) {
                    if (!_tilesFailed && mounted) setState(() => _tilesFailed = true);
                  },
                ),
              ),
              // Чужие посадки плавно гаснут в режиме «Мои».
              IgnorePointer(
                ignoring: _onlyMine,
                child: AnimatedOpacity(
                  opacity: _onlyMine ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: MarkerLayer(markers: cityMarkers),
                ),
              ),
              MarkerLayer(markers: myMarkers),
            ],
          ),
          Positioned(
            top: insets.top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(child: _ModeToggle(onlyMine: _onlyMine, onChanged: _setOnlyMine)),
                const SizedBox(width: 10),
                _LocateButton(onTap: _recenter),
              ],
            ),
          ),
          Positioned(
            left: 16,
            bottom: insets.bottom + 4,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '© OpenStreetMap · OpenTopoMap (CC-BY-SA)',
                  style: TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ),
            ),
          ),
          if (_tilesFailed)
            Positioned(
              top: insets.top + 80,
              left: 16,
              right: 16,
              child: _OfflineNotice(onRetry: () => setState(() => _tilesFailed = false)),
            ),
          if (selected != null)
            Positioned.fill(
              child: MapTreeSheet(
                tree: selected,
                onOpenTree: () => context.go(Routes.tree(selected.id)),
                onRoute: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Построение маршрута скоро появится')),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Стеклянная плашка «Мои / Все посадки» со скользящей «таблеткой» (250 мс).
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.onlyMine, required this.onChanged});

  final bool onlyMine;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, bool value) {
      final on = onlyMine == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(value),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: on ? AppColors.white : AppColors.pine,
                ),
                child: Text(label),
              ),
            ),
          ),
        ),
      );
    }

    return _Glass(
      child: SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                alignment: onlyMine ? Alignment.centerLeft : Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: AppColors.leaf, borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              Row(children: [tab('Мои', true), tab('Все посадки', false)]),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocateButton extends StatelessWidget {
  const _LocateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: GestureDetector(
        onTap: onTap,
        child: Semantics(
          button: true,
          label: 'Моё местоположение',
          child: const _Glass(
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(Icons.near_me_outlined, size: 22, color: AppColors.pine),
            ),
          ),
        ),
      ),
    );
  }
}

/// Полупрозрачная белая подложка с размытием.
class _Glass extends StatelessWidget {
  const _Glass({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x1F234010), blurRadius: 18, offset: Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: ColoredBox(color: const Color(0xE0FFFFFF), child: child),
        ),
      ),
    );
  }
}

/// Плашка «карта не загрузилась»: без сети видны только пины на пустом фоне.
class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, size: 20, color: AppColors.muted),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Карта не загрузилась — проверьте интернет',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Скрыть')),
          ],
        ),
      ),
    );
  }
}
