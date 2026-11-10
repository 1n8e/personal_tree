import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../shared/format.dart';
import '../../shared/widgets.dart';

/// Нижний лист с карточкой дерева поверх карты: 0.38 → 0.85 высоты, въезжает снизу.
/// Свои деревья — с кнопками «Карточка» и «Маршрут», чужие — обезличенно.
class MapTreeSheet extends StatelessWidget {
  const MapTreeSheet({
    super.key,
    required this.tree,
    required this.onOpenTree,
    required this.onRoute,
  });

  final Tree tree;
  final VoidCallback onOpenTree;
  final VoidCallback onRoute;

  @override
  Widget build(BuildContext context) {
    final species = speciesById(tree.speciesId);
    final text = Theme.of(context).textTheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final loc = tree.location;
    final date = tree.plantedAt != null ? formatDate(tree.plantedAt!) : '—';

    final sheet = DraggableScrollableSheet(
      initialChildSize: 0.38,
      minChildSize: 0.38,
      maxChildSize: 0.85,
      snap: true,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [BoxShadow(color: Color(0x24234010), blurRadius: 30, offset: Offset(0, -10))],
        ),
        child: SingleChildScrollView(
          controller: controller,
          padding: EdgeInsets.fromLTRB(20, 10, 20, bottom + 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(color: AppColors.stepTodo, borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 88,
                    child: tree.isMine
                        ? TreePhoto(tree: tree, species: species, height: 88, radius: 18)
                        : SpeciesIllustration(species, height: 88, radius: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TreeStatusBadge(tree.status, compact: true),
                        const SizedBox(height: 3),
                        Text(
                          tree.isMine ? tree.displayName : species.name,
                          style: AppFonts.display(size: 22),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tree.isMine ? '${species.name} · посажено $date' : 'Дерево жителя · посажено $date',
                          style: text.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _InfoTile(label: 'Адрес', value: tree.locationName ?? 'Алматы')),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _InfoTile(
                      label: 'Координаты',
                      value: loc == null
                          ? '—'
                          : '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}',
                      tabular: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (tree.isMine)
                Row(
                  children: [
                    Expanded(
                      child: _SheetButton(
                        label: 'Карточка',
                        bg: AppColors.mint,
                        fg: AppColors.pine,
                        onTap: onOpenTree,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 13,
                      child: _SheetButton(
                        label: 'Маршрут',
                        icon: Icons.near_me_outlined,
                        bg: AppColors.pine,
                        fg: AppColors.white,
                        onTap: onRoute,
                      ),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.muted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Посадки других жителей показываются обезличенно — без имён и личных данных.',
                          style: text.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    // Въезд снизу с лёгким перелётом, как в дизайне (.sheet 450 мс).
    return TweenAnimationBuilder<double>(
      key: ValueKey(tree.id),
      tween: Tween(begin: 1.1, end: 0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => FractionalTranslation(translation: Offset(0, t), child: child),
      child: sheet,
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value, this.tabular = false});

  final String label;
  final String value;
  final bool tabular;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              fontFeatures: tabular ? AppFonts.tabular : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({required this.label, required this.bg, required this.fg, required this.onTap, this.icon});

  final String label;
  final IconData? icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 8)],
              Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}
