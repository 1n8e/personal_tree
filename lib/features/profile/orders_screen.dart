import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../shared/format.dart';
import '../../shared/widgets.dart';
import 'profile_widgets.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final _expanded = <String>{};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final orders = [...state.orders]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final media = MediaQuery.of(context);
    final pad = EdgeInsets.fromLTRB(20, media.padding.top + 12, 20, media.padding.bottom + 20);

    return Scaffold(
      body: orders.isEmpty
          ? Padding(
              padding: pad,
              child: Column(
                children: [
                  const ProfileSubHeader('История заказов'),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'Заказов пока нет',
                          message: 'Выберите дерево в каталоге — после посадки оно появится в вашем лесу и на карте.',
                          actionLabel: 'Перейти в каталог',
                          onAction: () => context.go(Routes.catalog),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: pad,
              itemCount: orders.length + 1,
              separatorBuilder: (_, i) => SizedBox(height: i == 0 ? 18 : AppSpacing.gap),
              itemBuilder: (_, i) {
                if (i == 0) return const ProfileSubHeader('История заказов');
                final o = orders[i - 1];
                return _OrderCard(
                  order: o,
                  trees: [for (final id in o.treeIds) ?state.treeById(id)],
                  expanded: _expanded.contains(o.id),
                  onToggle: () => setState(() => _expanded.contains(o.id) ? _expanded.remove(o.id) : _expanded.add(o.id)),
                );
              },
            ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.trees, required this.expanded, required this.onToggle});

  final Order order;
  final List<Tree> trees;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final species = speciesById(order.speciesId);
    final text = Theme.of(context).textTheme;
    final planted = trees.where((t) => t.isPlanted).length;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 60, child: SpeciesIllustration(species, height: 60)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Заказ № ${order.number}',
                                      style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OrderStatusChip(order.status),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(formatDate(order.createdAt), style: text.bodySmall),
                              const SizedBox(height: 6),
                              Text(
                                '${species.name} × ${order.quantity}',
                                style: text.bodyMedium,
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
                        Expanded(
                          child: Text(
                            'Посажено $planted из ${trees.length}',
                            style: text.bodySmall?.copyWith(color: AppColors.leaf, fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          formatPrice(order.total),
                          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800, fontFeatures: AppFonts.tabular),
                        ),
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          turns: expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.expand_more_rounded, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: expanded
                  ? Column(
                      children: [
                        const Divider(height: 1, color: AppColors.divider),
                        for (final t in trees)
                          InkWell(
                            onTap: () => context.go(Routes.tree(t.id)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  const Icon(Icons.park_outlined, size: 18, color: AppColors.pine),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      t.code,
                                      style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.3),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TreeStatusBadge(t.status, compact: true),
                                  const Icon(Icons.chevron_right_rounded, color: AppColors.hint),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 4),
                      ],
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}
