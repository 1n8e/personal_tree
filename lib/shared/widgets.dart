import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../data/models.dart';
import 'format.dart';

/// Бейдж статуса дерева: «Ожидает посадки» / «Посажено» / «На мониторинге».
class TreeStatusBadge extends StatelessWidget {
  const TreeStatusBadge(this.status, {super.key, this.compact = false});

  final TreeStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (fg, bg, dot) = switch (status) {
      TreeStatus.growing => (AppColors.pine, AppColors.growingBg, AppColors.growing),
      TreeStatus.awaitingPlanting => (AppColors.awaiting, AppColors.awaitingBg, AppColors.awaitingDot),
      TreeStatus.planted => (AppColors.planted, AppColors.plantedBg, AppColors.plantedDot),
      TreeStatus.monitoring => (AppColors.monitoring, AppColors.monitoringBg, AppColors.monitoringDot),
    };
    return Container(
      height: compact ? 24 : 28,
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.chip)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            treeStatusLabel(status),
            style: TextStyle(fontSize: compact ? 11 : 12, fontWeight: FontWeight.w800, color: fg),
          ),
        ],
      ),
    );
  }
}

/// Иллюстрация вида дерева вместо фото (в прототипе нет реальных снимков).
class SpeciesIllustration extends StatelessWidget {
  const SpeciesIllustration(
    this.species, {
    super.key,
    this.height = 120,
    this.iconSize,
    this.radius = AppRadius.small,
  });

  final TreeSpecies species;
  final double height;
  final double? iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(color: species.tint, borderRadius: BorderRadius.circular(radius)),
      alignment: Alignment.center,
      child: Icon(species.icon, size: iconSize ?? height * 0.45, color: AppColors.forest),
    );
  }
}

/// «Фото» дерева. До посадки — заглушка с пунктиром, после — снимок исполнителя.
class TreePhoto extends StatelessWidget {
  const TreePhoto({
    super.key,
    required this.tree,
    required this.species,
    this.height = 180,
    this.radius = AppRadius.card,
  });

  final Tree tree;
  final TreeSpecies species;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (!tree.isPlanted) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.beige,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppColors.beigeDark, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_camera_outlined, size: height * 0.18, color: AppColors.hint),
            if (height > 90) ...[
              const SizedBox(height: 6),
              Text('Фото появится после посадки', style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      );
    }
    // «Снимок» с места посадки: небо, земля и дерево.
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: const Color(0xFFDCEBF2)),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(height: height * 0.32, color: const Color(0xFFB9CDA6)),
            ),
            Align(
              alignment: const Alignment(0, 0.35),
              child: Icon(species.icon, size: height * 0.62, color: AppColors.forest),
            ),
            if (height > 90)
              Positioned(
                left: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_camera_rounded, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        tree.plantedAt != null ? formatDate(tree.plantedAt!) : '',
                        style: const TextStyle(fontSize: 11, color: Colors.white),
                      ),
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

/// Заголовок секции с необязательной ссылкой справа.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

/// Плитка статистики: подпись + крупное число.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.beige, borderRadius: BorderRadius.circular(AppRadius.small)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.forest),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Пустое состояние с призывом к действию.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(color: AppColors.leafLight, shape: BoxShape.circle),
            child: Icon(icon, size: 40, color: AppColors.forest),
          ),
          const SizedBox(height: 20),
          Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 24),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Плашка «Режим исполнителя», чтобы на демо было видно, чья это роль.
class PlanterModeBanner extends StatelessWidget {
  const PlanterModeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.awaitingBg,
      child: const Row(
        children: [
          Icon(Icons.engineering_rounded, size: 16, color: AppColors.awaiting),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Режим исполнителя (демо)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.awaiting),
            ),
          ),
        ],
      ),
    );
  }
}
