import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../shared/design.dart';
import '../../shared/format.dart';

/// Главная: дерево пользователя, посадка, вклад, воздух, посадки в городе.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final tree = _featuredTree(app);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: TopoBackground(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 16, 20, bottom + 24),
          children: [
            _Header(app: app),
            const SizedBox(height: 20),
            _TreeCard(tree: tree, app: app),
            const SizedBox(height: 20),
            const _PlantCta(),
            const SizedBox(height: 20),
            _Stats(app: app),
            const SizedBox(height: 20),
            const _AirCard(),
            const SizedBox(height: 20),
            const _CityStories(),
            const SizedBox(height: 20),
            const _AboutCard(),
          ],
        ),
      ),
    );
  }

  /// Дерево для карточки: растущее, иначе ожидающее посадки, иначе последнее посаженное.
  static Tree? _featuredTree(AppState app) {
    if (app.growingTrees.isNotEmpty) return app.growingTrees.first;
    if (app.awaitingTrees.isNotEmpty) return app.awaitingTrees.first;
    if (app.plantedTrees.isNotEmpty) {
      final list = [...app.plantedTrees]..sort((a, b) => (b.plantedAt ?? b.orderedAt).compareTo(a.plantedAt ?? a.orderedAt));
      return list.first;
    }
    return null;
  }
}

String _greeting() {
  final h = DateTime.now().hour;
  if (h >= 5 && h < 12) return 'Доброе утро';
  if (h >= 12 && h < 18) return 'Добрый день';
  if (h >= 18 && h < 23) return 'Добрый вечер';
  return 'Доброй ночи';
}

class _Header extends StatelessWidget {
  const _Header({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final user = app.user;
    final first = user?.name.trim().split(RegExp(r'\s+')).first ?? '';
    final initial = (user?.initials.isNotEmpty ?? false) ? user!.initials : (first.isEmpty ? '' : first[0].toUpperCase());
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandLogo(size: 18),
              const SizedBox(height: 8),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      first.isEmpty ? _greeting() : '${_greeting()}, $first',
                      style: AppFonts.display(size: 26),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.eco_outlined, size: 22, color: AppColors.leaf),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          button: true,
          label: 'Профиль',
          child: PressScale(
            child: GestureDetector(
              onTap: () => context.go(Routes.profile),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.sage,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                  boxShadow: const [BoxShadow(color: Color(0x1F234010), blurRadius: 12, offset: Offset(0, 4))],
                ),
                child: Text(
                  initial,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.pine),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TreeCard extends StatelessWidget {
  const _TreeCard({required this.tree, required this.app});
  final Tree? tree;
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final t = tree;
    final String title;
    final String subtitle;
    final Widget info;
    final String actionLabel;
    final IconData actionIcon;
    final VoidCallback onAction;
    final double progress;
    final GrowthStage stage;

    if (t == null) {
      title = 'Пока нет деревьев';
      subtitle = 'Посадите первое в Алматы';
      info = const SizedBox.shrink();
      actionLabel = 'Выбрать';
      actionIcon = Icons.add_rounded;
      onAction = () => context.go(Routes.catalog);
      progress = 0;
      stage = GrowthStage.seed;
    } else {
      final species = speciesById(t.speciesId).name;
      title = t.displayName;
      stage = t.stage;
      progress = t.progress;
      if (t.isGrowing) {
        subtitle = '$species · ${t.stage.label.toLowerCase()}';
        info = Text.rich(
          TextSpan(children: [
            TextSpan(
              text: '${(t.progress * 100).round()}%',
              style: const TextStyle(fontWeight: FontWeight.w800, fontFeatures: AppFonts.tabular),
            ),
            TextSpan(text: ' · ${formatNumber(t.paidAmount)} из ${formatPrice(t.targetAmount)}'),
          ]),
          style: const TextStyle(fontSize: 13, color: AppColors.ink),
        );
        actionLabel = 'Пополнить';
        actionIcon = Icons.add_rounded;
        onAction = () => context.push(Routes.growth(t.id));
      } else {
        subtitle = species;
        info = Text(treeStatusLabel(t.status), style: const TextStyle(fontSize: 13, color: AppColors.ink));
        actionLabel = 'Открыть';
        actionIcon = Icons.arrow_forward_rounded;
        onAction = () => context.push(Routes.tree(t.id));
      }
    }

    return Semantics(
      container: true,
      label: 'Ваше дерево',
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            GrowthRing(
              progress: progress,
              size: 140,
              stroke: 10,
              child: TreeArt(size: 140, stage: stage, background: AppColors.cream),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ВАШЕ ДЕРЕВО', style: AppFonts.overline()),
                  const SizedBox(height: 6),
                  Text(title, style: AppFonts.display(size: 24).copyWith(height: 1.1), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                  if (t != null) ...[const SizedBox(height: 6), info],
                  const SizedBox(height: 10),
                  PressScale(
                    child: Material(
                      color: AppColors.mint,
                      shape: const StadiumBorder(),
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: onAction,
                        child: SizedBox(
                          height: 44,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(actionIcon, size: 18, color: AppColors.pine),
                              const SizedBox(width: 6),
                              Text(actionLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.pine)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlantCta extends StatelessWidget {
  const _PlantCta();

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: Material(
        color: AppColors.pine,
        elevation: 0,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.tile), boxShadow: const [
            BoxShadow(color: Color(0x38234010), blurRadius: 24, offset: Offset(0, 10)),
          ]),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.tile),
            onTap: () => context.go(Routes.catalog),
            child: Container(
              height: 64,
              padding: const EdgeInsets.fromLTRB(22, 0, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Посадить дерево', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.white)),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: AppColors.leaf, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.arrow_forward_rounded, size: 22, color: AppColors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Ваш вклад',
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _StatTile(value: app.plantedTrees.length, label: 'деревьев посажено')),
            const SizedBox(width: 10),
            Expanded(child: _StatTile(value: app.co2PerYear, label: 'кг CO₂ в год, оценочно')),
            const SizedBox(width: 10),
            Expanded(child: _StatTile(value: app.ecoPoints, label: 'эко-баллов')),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        boxShadow: AppShadows.tile,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: still ? Duration.zero : const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatNumber(v),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.pine,
                  height: 1,
                  fontFeatures: AppFonts.tabular,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, height: 1.3, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _AirCard extends StatelessWidget {
  const _AirCard();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Воздух в Алматы сегодня',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(color: AppColors.sky, borderRadius: BorderRadius.circular(AppRadius.card)),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20)),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('128', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.aqi, height: 1, fontFeatures: AppFonts.tabular)),
                  Text('AQI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Воздух в Алматы сегодня', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  SizedBox(height: 4),
                  Text(
                    'Вредно для чувствительных групп. Каждое дерево — шаг к чистому воздуху.',
                    style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF34495A)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CityStories extends StatelessWidget {
  const _CityStories();

  static const _districts = [
    ('Медеуский', AppColors.mint, true),
    ('Бостандыкский', AppColors.sky, true),
    ('Алмалинский', AppColors.mint, true),
    ('Ауэзовский', AppColors.cream, false),
    ('Турксибский', AppColors.cream, false),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Посадки в городе', style: AppFonts.display(size: 20)),
            InkWell(
              onTap: () => context.go(Routes.map),
              child: const SizedBox(
                height: 44,
                child: Center(
                  child: Text('На карте', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.leaf)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Высота по содержимому: подписи не обрезаются при крупном шрифте.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          physics: const BouncingScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, (name, bg, fresh)) in _districts.indexed) ...[
                if (i > 0) const SizedBox(width: 14),
                PressScale(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.go(Routes.map),
                    child: SizedBox(
                      width: 76,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: fresh ? AppColors.leaf : AppColors.sage, width: 2.5),
                            ),
                            child: Container(
                              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                              child: const Center(child: CustomPaint(size: Size(30, 30), painter: _MiniTreePainter())),
                            ),
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              name,
                              maxLines: 1,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink, height: 1.2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Маленькое дерево в сторис: ствол и крона (viewBox 24×24 из дизайна).
class _MiniTreePainter extends CustomPainter {
  const _MiniTreePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(11 * k, 13 * k, 2 * k, 8 * k), Radius.circular(k)),
      Paint()..color = AppColors.soil,
    );
    canvas.drawCircle(Offset(12 * k, 10 * k), 6 * k, Paint()..color = AppColors.leaf);
  }

  @override
  bool shouldRepaint(_MiniTreePainter old) => false;
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 150),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: AppColors.sage, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Stack(
        children: [
          const Positioned(left: 0, right: 0, bottom: 0, height: 90, child: CustomPaint(painter: _MountainsPainter())),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 250),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('О ПРОЕКТЕ', style: AppFonts.overline(color: AppColors.pine)),
                  const SizedBox(height: 6),
                  Text('Из цифры — в почву Алматы', style: AppFonts.display(size: 20, color: AppColors.pineDeep).copyWith(height: 1.2)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _showHowItWorks(context),
                    child: const SizedBox(
                      height: 44,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: 1,
                        child: Text(
                          'Как это работает',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.pineDeep,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.pineDeep,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Горы из дизайна (viewBox 390×90), растянутые по ширине карточки.
class _MountainsPainter extends CustomPainter {
  const _MountainsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 390;
    final sy = size.height / 90;
    Offset p(double x, double y) => Offset(x * sx, y * sy);
    final ridge = Path()
      ..moveTo(p(0, 90).dx, p(0, 90).dy)
      ..lineTo(p(70, 30).dx, p(70, 30).dy)
      ..lineTo(p(120, 60).dx, p(120, 60).dy)
      ..lineTo(p(190, 10).dx, p(190, 10).dy)
      ..lineTo(p(260, 55).dx, p(260, 55).dy)
      ..lineTo(p(320, 25).dx, p(320, 25).dy)
      ..lineTo(p(390, 70).dx, p(390, 70).dy)
      ..lineTo(p(390, 90).dx, p(390, 90).dy)
      ..close();
    canvas.drawPath(ridge, Paint()..color = AppColors.sageDark);
    final snow = Path()
      ..moveTo(p(180, 18).dx, p(180, 18).dy)
      ..lineTo(p(190, 10).dx, p(190, 10).dy)
      ..lineTo(p(200, 20).dx, p(200, 20).dy)
      ..lineTo(p(194, 18).dx, p(194, 18).dy)
      ..lineTo(p(190, 24).dx, p(190, 24).dy)
      ..lineTo(p(186, 18).dx, p(186, 18).dy)
      ..close();
    canvas.drawPath(snow, Paint()..color = AppColors.white);
  }

  @override
  bool shouldRepaint(_MountainsPainter old) => false;
}

void _showHowItWorks(BuildContext context) {
  const steps = [
    ('Выберите дерево', 'Порода из каталога — платите сразу или по частям.'),
    ('Мы посадим его', 'Исполнитель высадит саженец в Алматы и пришлёт фото.'),
    ('Наблюдайте рост', 'Дерево на карте, а ваш вклад — в эко-баллах и CO₂.'),
  ];
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: AppColors.cream,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Как это работает', style: AppFonts.display(size: 24)),
            const SizedBox(height: 16),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
                      child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.pine)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(steps[i].$1, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                          const SizedBox(height: 2),
                          Text(steps[i].$2, style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.muted)),
                        ],
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
}
