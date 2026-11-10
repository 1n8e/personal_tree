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
import '../../shared/format.dart';
import '../../shared/widgets.dart';
import 'forest_widgets.dart';

/// Экран исполнителя: фото + геоточка обязательны, только после этого
/// у дерева появляются дата, место и начисляются эко-баллы владельцу.
class ConfirmPlantingScreen extends ConsumerStatefulWidget {
  const ConfirmPlantingScreen({super.key, required this.treeId});

  final String treeId;

  @override
  ConsumerState<ConfirmPlantingScreen> createState() => _ConfirmPlantingScreenState();
}

class _ConfirmPlantingScreenState extends ConsumerState<ConfirmPlantingScreen> {
  final _noteController = TextEditingController();
  final _mapController = MapController();

  bool _photoTaken = false;
  bool _photoLoading = false;
  int? _zoneIndex;
  bool _gpsLoading = false;
  bool _showErrors = false;
  bool _submitting = false;

  /// После подтверждения дерево становится «посаженным» — не переключаемся
  /// на экран «уже посажено», пока уходим назад.
  bool _done = false;

  late final DateTime _today = DateTime.now();

  @override
  void dispose() {
    _noteController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_photoLoading) return;
    setState(() => _photoLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _photoLoading = false;
      _photoTaken = true;
    });
  }

  void _selectZone(int index) {
    setState(() => _zoneIndex = index);
    _mapController.move(MockData.plantingZones[index].point, 14);
  }

  Future<void> _detectGps() async {
    if (_gpsLoading) return;
    setState(() => _gpsLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    // Имитация GPS: ближайшая к «текущему положению» исполнителя зона.
    const me = MockData.almatyCenter;
    const distance = Distance();
    var best = 0;
    for (var i = 1; i < MockData.plantingZones.length; i++) {
      if (distance(me, MockData.plantingZones[i].point) < distance(me, MockData.plantingZones[best].point)) {
        best = i;
      }
    }
    setState(() => _gpsLoading = false);
    _selectZone(best);
  }

  Future<void> _submit() async {
    if (!_photoTaken || _zoneIndex == null) {
      setState(() => _showErrors = true);
      return;
    }
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final note = _noteController.text.trim();
    _done = true;
    ref.read(appControllerProvider.notifier).confirmPlanting(
          treeId: widget.treeId,
          zoneIndex: _zoneIndex!,
          note: note.isEmpty ? null : note,
        );
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(Routes.tree(widget.treeId));
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Посадка подтверждена · +100 эко-баллов владельцу')));
  }

  @override
  Widget build(BuildContext context) {
    final tree = ref.watch(appControllerProvider.select((s) => s.treeById(widget.treeId)));

    return Scaffold(
      appBar: AppBar(title: const Text('Подтверждение посадки')),
      body: Column(
        children: [
          const PlanterModeBanner(),
          Expanded(child: _body(context, tree)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, Tree? tree) {
    if (tree == null) {
      return Center(
        child: EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Дерево не найдено',
          message: 'Проверьте номер дерева в задании.',
          actionLabel: 'Назад',
          onAction: () => context.pop(),
        ),
      );
    }
    if (tree.isPlanted && !_done) {
      return Center(
        child: SingleChildScrollView(
          child: EmptyState(
            icon: Icons.task_alt_rounded,
            title: 'Посадка уже подтверждена',
            message: '${tree.code} посажено'
                '${tree.plantedAt != null ? ' ${formatDate(tree.plantedAt!)}' : ''}'
                '${tree.locationName != null ? ' · ${tree.locationName}' : ''}.',
            actionLabel: 'Открыть карточку дерева',
            onAction: () => context.go(Routes.tree(tree.id)),
          ),
        ),
      );
    }

    final species = speciesById(tree.speciesId);
    final textTheme = Theme.of(context).textTheme;
    final photoError = _showErrors && !_photoTaken;
    final zoneError = _showErrors && _zoneIndex == null;

    return AbsorbPointer(
      absorbing: _submitting,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          AppSpacing.page,
          16,
          AppSpacing.page,
          AppSpacing.section + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          // Задание
          BeigeCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(width: 56, child: SpeciesIllustration(species, height: 56, iconSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tree.code, style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                      Text(species.name, style: textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('Заказано ${formatDate(tree.orderedAt)}', style: textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TreeStatusBadge(tree.status, compact: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.section),

          // 1. Фото
          _StepHeader(number: 1, title: 'Фото посадки', done: _photoTaken, required: true),
          const SizedBox(height: 10),
          _PhotoBox(
            species: species,
            taken: _photoTaken,
            loading: _photoLoading,
            error: photoError,
            onTap: _takePhoto,
          ),
          if (photoError) const _FieldError('Сделайте фото посаженного дерева'),
          const SizedBox(height: AppSpacing.section),

          // 2. Геоточка
          _StepHeader(number: 2, title: 'Геоточка', done: _zoneIndex != null, required: true),
          const SizedBox(height: 10),
          _ZonesMap(
            controller: _mapController,
            selected: _zoneIndex,
            error: zoneError,
            onSelect: _selectZone,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _gpsLoading ? null : _detectGps,
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
            icon: _gpsLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.gps_fixed_rounded, size: 20),
            label: Text(_gpsLoading ? 'Определяем…' : 'Определить по GPS'),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < MockData.plantingZones.length; i++)
            _ZoneTile(
              name: MockData.plantingZones[i].name,
              point: MockData.plantingZones[i].point,
              selected: _zoneIndex == i,
              onTap: () => _selectZone(i),
            ),
          if (zoneError) const _FieldError('Выберите место посадки или определите по GPS'),
          const SizedBox(height: AppSpacing.section),

          // 3. Дата и исполнитель
          const _StepHeader(number: 3, title: 'Дата и исполнитель', done: true),
          const SizedBox(height: 10),
          BeigeCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                InfoRow(icon: Icons.event_available_outlined, label: 'Дата посадки', value: formatDate(_today)),
                const Divider(color: AppColors.divider),
                const InfoRow(icon: Icons.engineering_outlined, label: 'Исполнитель', value: MockData.planterName),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.section),

          // 4. Комментарий
          const _StepHeader(number: 4, title: 'Комментарий', done: false, optional: true),
          const SizedBox(height: 10),
          TextField(
            controller: _noteController,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Например: саженец 1,8 м, установлена опора'),
          ),
          const SizedBox(height: AppSpacing.section),

          if (_showErrors && (photoError || zoneError))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Фото и геоточка обязательны для подтверждения посадки',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              disabledBackgroundColor: AppColors.pine.withValues(alpha: 0.85),
              disabledForegroundColor: AppColors.white,
            ),
            child: _submitting
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                      ),
                      SizedBox(width: 12),
                      Text('Отправляем…'),
                    ],
                  )
                : const Text('Подтвердить посадку'),
          ),
          const SizedBox(height: 10),
          Text(
            'После подтверждения владелец увидит фото, дату и место посадки, '
            'а на его счёт поступит +$pointsPerPlantedTree эко-баллов.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.number,
    required this.title,
    required this.done,
    this.required = false,
    this.optional = false,
  });

  final int number;
  final String title;
  final bool done;
  final bool required;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: done ? AppColors.pine : AppColors.mint,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: done
              ? const Icon(Icons.check_rounded, size: 16, color: AppColors.white)
              : Text(
                  '$number',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.pine),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
        if (required)
          const Text('обязательно', style: TextStyle(fontSize: 12, color: AppColors.awaiting))
        else if (optional)
          const Text('необязательно', style: TextStyle(fontSize: 12, color: AppColors.hint)),
      ],
    );
  }
}

class _FieldError extends StatelessWidget {
  const _FieldError(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: color))),
        ],
      ),
    );
  }
}

class _PhotoBox extends StatelessWidget {
  const _PhotoBox({
    required this.species,
    required this.taken,
    required this.loading,
    required this.error,
    required this.onTap,
  });

  final TreeSpecies species;
  final bool taken;
  final bool loading;
  final bool error;
  final VoidCallback onTap;

  static const _height = 190.0;

  @override
  Widget build(BuildContext context) {
    if (taken) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: SizedBox(
              height: _height,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: const Color(0xFFDCEBF2)),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(height: _height * 0.32, color: const Color(0xFFB9CDA6)),
                  ),
                  Align(
                    alignment: const Alignment(0, 0.35),
                    child: Icon(species.icon, size: _height * 0.62, color: AppColors.pine),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: _Chip(icon: Icons.photo_camera_rounded, text: 'IMG_${DateTime.now().year}_0001.jpg'),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: Material(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: loading ? null : onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      loading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      const Text('Переснять', style: TextStyle(fontSize: 13, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final errorColor = Theme.of(context).colorScheme.error;
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: loading ? null : onTap,
        child: Container(
          height: _height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: error ? errorColor : AppColors.sage, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: loading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const Icon(Icons.photo_camera_outlined, size: 28, color: AppColors.pine),
              ),
              const SizedBox(height: 12),
              Text(
                loading ? 'Снимаем…' : 'Сделать фото',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.pine),
              ),
              const SizedBox(height: 4),
              Text('Дерево целиком, с опорой и табличкой', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11, color: Colors.white)),
        ],
      ),
    );
  }
}

class _ZonesMap extends StatelessWidget {
  const _ZonesMap({
    required this.controller,
    required this.selected,
    required this.error,
    required this.onSelect,
  });

  final MapController controller;
  final int? selected;
  final bool error;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final zones = MockData.plantingZones;
    final borderColor = error ? Theme.of(context).colorScheme.error : AppColors.sage;
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card - 1.5),
        child: Stack(
          children: [
            FlutterMap(
              mapController: controller,
              options: MapOptions(
                initialCameraFit: CameraFit.bounds(
                  bounds: LatLngBounds.fromPoints([for (final z in zones) z.point]),
                  padding: const EdgeInsets.all(36),
                ),
                backgroundColor: AppColors.leafLight,
                // Карта внутри списка: двигаем только щипком, чтобы не мешать прокрутке.
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
                ),
              ),
              children: [
                osmTileLayer(),
                MarkerLayer(
                  markers: [
                    for (var i = 0; i < zones.length; i++)
                      Marker(
                        point: zones[i].point,
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () => onSelect(i),
                          child: Center(child: TreeMapPin(selected: selected == i, size: selected == i ? 40 : 30)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (selected != null)
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8)],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.my_location_rounded, size: 16, color: AppColors.pine),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          formatLatLng(zones[selected!].point),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      const Text('точность ± 5 м', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ZoneTile extends StatelessWidget {
  const _ZoneTile({required this.name, required this.point, required this.selected, required this.onTap});

  final String name;
  final LatLng point;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppColors.mint : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.small),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.small),
              border: Border.all(color: selected ? AppColors.pine : Colors.transparent, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  size: 20,
                  color: selected ? AppColors.pine : AppColors.hint,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          color: AppColors.ink,
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(height: 2),
                        Text(formatLatLng(point), style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
