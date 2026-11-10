import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../shared/design.dart';
import '../../shared/format.dart';
import 'motion.dart';

enum _Filter { all, popular, broadleaf, conifer, budget }

const _coniferIds = {'spruce'};

extension on _Filter {
  String get label => switch (this) {
        _Filter.all => 'Все',
        _Filter.popular => 'Популярные',
        _Filter.broadleaf => 'Лиственные',
        _Filter.conifer => 'Хвойные',
        _Filter.budget => 'До 7 000 ₸',
      };

  bool matches(TreeSpecies s) => switch (this) {
        _Filter.all => true,
        _Filter.popular => s.isPopular,
        _Filter.broadleaf => !_coniferIds.contains(s.id),
        _Filter.conifer => _coniferIds.contains(s.id),
        _Filter.budget => s.price <= 7000,
      };
}

/// Каталог деревьев: фильтр-чипы и сетка карточек 2 в ряд (Catalog.dc.html).
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final list = [for (final s in MockData.species) if (_filter.matches(s)) s];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, pad.top + 12, 20, 0),
            sliver: SliverList.list(
              children: [
                Text('Каталог деревьев', style: AppFonts.display(size: 30)),
                const SizedBox(height: 4),
                const Text(
                  'Виды, которые хорошо приживаются в Алматы',
                  style: TextStyle(fontSize: 15, color: AppColors.muted),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _Filter.values.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final f = _Filter.values[i];
                  return _FilterChip(
                    label: f.label,
                    selected: f == _filter,
                    onTap: () => setState(() => _filter = f),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (list.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'В этой категории пока нет деревьев',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + pad.bottom),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 280,
                ),
                delegate: SliverChildBuilderDelegate(
                  childCount: list.length,
                  (context, i) => Rise(
                    key: ValueKey('${_filter.name}-${list[i].id}'),
                    delay: Duration(milliseconds: 50 * i),
                    child: _SpeciesCard(
                      species: list[i],
                      onTap: () => context.push(Routes.purchase(list[i].id)),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: motion(context, 200),
          curve: Curves.easeOut,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.leaf : AppColors.mint,
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
          child: AnimatedDefaultTextStyle(
            duration: motion(context, 200),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.white : AppColors.pine,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class _SpeciesCard extends StatelessWidget {
  const _SpeciesCard({required this.species, required this.onTap});

  final TreeSpecies species;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 128,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: AppColors.mint,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CustomPaint(
                      painter: _StripesPainter(),
                      child: Center(child: Icon(species.icon, size: 44, color: AppColors.pine)),
                    ),
                  ),
                  if (species.isPopular)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        height: 24,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.pine,
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                        child: const Text(
                          'Популярное',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.white),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        species.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.display(size: 18),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        species.shortDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, height: 1.35, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatPrice(species.price),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        fontFeatures: AppFonts.tabular,
                      ),
                    ),
                    Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      child: const Text(
                        'Выбрать',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.pine),
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
}

/// Диагональные полосы 135° (#DCE6D3 / #D2DEC8, шаг 10) из дизайна карточки.
class _StripesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD2DEC8)
      ..strokeWidth = 10;
    // Период 20 px поперёк полос = 28.28 px по горизонтали.
    const step = 20 * 1.4142;
    for (double d = 0; d < size.width + size.height + step; d += step) {
      canvas.drawLine(Offset(d, 0), Offset(d - size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_StripesPainter old) => false;
}
