import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../shared/format.dart';
import 'profile_widgets.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final achievements = state.achievements;
    final earned = achievements.where((a) => a.earned).length;
    final text = Theme.of(context).textTheme;

    final rows = <Widget>[];
    for (var i = 0; i < achievements.length; i += 2) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _AchievementCard(progress: achievements[i], index: i)),
              const SizedBox(width: AppSpacing.gap),
              Expanded(
                child: i + 1 < achievements.length
                    ? _AchievementCard(progress: achievements[i + 1], index: i + 1)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
      rows.add(const SizedBox(height: AppSpacing.gap));
    }

    final media = MediaQuery.of(context);
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, media.padding.top + 12, 20, media.padding.bottom + 20),
        children: [
          const ProfileSubHeader('Достижения'),
          const SizedBox(height: 18),
          _PointsHero(points: state.ecoPoints, plantedCount: state.plantedTrees.length),
          const SizedBox(height: AppSpacing.section),
          Row(
            children: [
              Expanded(child: Text('Все достижения', style: AppFonts.display(size: 20))),
              Text('Получено $earned из ${achievements.length}', style: text.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.gap),
          ...rows,
        ],
      ),
    );
  }
}

class _PointsHero extends StatelessWidget {
  const _PointsHero({required this.points, required this.plantedCount});

  final int points;
  final int plantedCount;

  @override
  Widget build(BuildContext context) {
    final onForest = AppColors.white.withValues(alpha: 0.78);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.pine, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: AppColors.sage, size: 20),
              const SizedBox(width: 6),
              Text('Эко-баллы', style: TextStyle(fontSize: 14, color: onForest, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$points',
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: AppColors.white, height: 1.1),
          ),
          const SizedBox(height: 16),
          _PointsRow(
            icon: Icons.how_to_reg_rounded,
            title: 'За регистрацию',
            value: '+$registrationPoints',
          ),
          const SizedBox(height: 8),
          _PointsRow(
            icon: Icons.park_rounded,
            title: 'За каждое подтверждённое дерево',
            value: '+$pointsPerPlantedTree',
            hint: plantedCount > 0 ? '${treesCount(plantedCount)} · +${plantedCount * pointsPerPlantedTree}' : null,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: onForest),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Баллы за деревья начисляются только после посадки — когда исполнитель подтвердит её фото и геоточкой.',
                    style: TextStyle(fontSize: 12, color: onForest, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PointsRow extends StatelessWidget {
  const _PointsRow({required this.icon, required this.title, required this.value, this.hint});

  final IconData icon;
  final String title;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.14), shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: AppColors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, color: AppColors.white)),
              if (hint != null)
                Text(hint!, style: TextStyle(fontSize: 12, color: AppColors.white.withValues(alpha: 0.65))),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.sage)),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.progress, required this.index});

  final AchievementProgress progress;
  final int index;

  @override
  Widget build(BuildContext context) {
    final a = progress.achievement;
    final text = Theme.of(context).textTheme;
    final shown = progress.current.clamp(0, a.target);
    return Material(
      color: progress.earned ? AppColors.white : const Color(0xFFEEEAE0),
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => showAchievementSheet(context, progress, index: index),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AchievementBadge(progress: progress, size: 48, index: index),
                  const Spacer(),
                  if (progress.earned) const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.leaf),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                a.title,
                style: text.titleMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: progress.earned ? AppColors.ink : AppColors.muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(a.description, style: text.bodySmall),
              const Spacer(),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress.ratio,
                  minHeight: 6,
                  backgroundColor: AppColors.mint,
                  color: AppColors.leaf,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                progress.earned ? 'Получено' : '$shown / ${a.target}',
                style: text.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: progress.earned ? AppColors.leaf : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
