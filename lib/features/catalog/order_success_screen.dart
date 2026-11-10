import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../shared/design.dart';
import '../../shared/format.dart';
import '../../shared/widgets.dart';
import 'motion.dart';

/// «Заказ оформлен»: галочка превращается в лист, листья-конфетти, строки деталей (OrderSuccess.dc.html).
class OrderSuccessScreen extends ConsumerStatefulWidget {
  const OrderSuccessScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends ConsumerState<OrderSuccessScreen> with TickerProviderStateMixin {
  late final AnimationController _badge = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  late final AnimationController _typing = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  late final AnimationController _confetti = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _badge.value = 1;
      _typing.value = 1;
    } else {
      _badge.forward();
      _typing.forward();
      _confetti.repeat();
    }
  }

  @override
  void dispose() {
    _badge.dispose();
    _typing.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final order = state.orderById(widget.orderId);
    final trees = [
      if (order != null)
        for (final id in order.treeIds)
          if (state.treeById(id) case final Tree t) t,
    ];

    if (order == null || trees.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Заказ не найден',
              message: 'Возможно, он был оформлен в другой сессии. Загляните в «Мой лес» или в каталог.',
              actionLabel: 'На главную',
              onAction: () => context.go(Routes.home),
            ),
          ),
        ),
      );
    }

    final species = speciesById(order.speciesId);
    final first = trees.first;
    final growing = first.isGrowing;
    final single = trees.length == 1;
    final paid = trees.fold<int>(0, (s, t) => s + t.paidAmount);
    final target = trees.fold<int>(0, (s, t) => s + t.targetAmount);
    final named = first.name != null && first.name!.trim().isNotEmpty;

    final title = !single
        ? 'Заказ № ${order.number} оформлен'
        : named
            ? (growing ? '${first.displayName} начал расти' : '${first.displayName} в вашем лесу')
            : 'Заказ оформлен';
    final body = growing
        ? 'Первый взнос получен. ${single ? 'Дерево' : 'Деревья'} в вашем лесу — растите ${single ? 'его' : 'их'} до 100%, и мы передадим заказ на посадку.'
        : 'Оплата получена. ${single ? 'Дерево' : 'Деревья'} в вашем лесу — мы передадим заказ исполнителю на посадку.';

    final rows = <(String, Widget)>[
      (
        'Дерево',
        _value(single && named ? '${species.name} «${first.displayName}»' : '${species.name} × ${trees.length}'),
      ),
      ('Номер', _TypedCode(code: first.code, extra: single ? '' : ' +${trees.length - 1}', t: _typing)),
      (
        'Способ',
        _value(order.paymentMode == PaymentMode.installments
            ? 'Взносами · ${formatPrice(order.installment ?? 0)}/мес'
            : 'Сразу'),
      ),
      ('Внесено', _value('${formatNumber(paid)} из ${formatPrice(target)}')),
      (
        'Статус',
        _value(growing
            ? '${treeStatusLabel(first.status)} · ${(first.progress * 100).round()}%'
            : treeStatusLabel(first.status)),
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _ConfettiPainter(_confetti)))),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            children: [
                              Container(
                                width: 112,
                                height: 112,
                                decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
                                alignment: Alignment.center,
                                child: _CheckToLeaf(t: _badge),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                style: AppFonts.display(size: 30),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                body,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            boxShadow: AppShadows.card,
                          ),
                          child: Column(
                            children: [
                              for (var i = 0; i < rows.length; i++)
                                Rise(
                                  delay: Duration(milliseconds: 300 + i * 60),
                                  dy: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      border: i < rows.length - 1
                                          ? const Border(bottom: BorderSide(color: AppColors.divider))
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(rows[i].$1, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                                        const SizedBox(width: 12),
                                        Flexible(child: rows[i].$2),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.awaitingBg,
                            borderRadius: BorderRadius.circular(AppRadius.tile),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.notifications_none_rounded, size: 22, color: AppColors.aqi),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Мы сообщим, когда исполнитель подтвердит посадку. '
                                  'Фото, координаты и дата появятся только после этого.',
                                  style: TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF4A3A12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 10,
                        child: _ActionButton(
                          label: 'На главную',
                          background: AppColors.mint,
                          foreground: AppColors.pine,
                          onTap: () => context.go(Routes.home),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 14,
                        child: _ActionButton(
                          label: growing ? 'Следить за ростом' : 'Смотреть дерево',
                          background: AppColors.pine,
                          foreground: AppColors.white,
                          onTap: () => context.go(growing ? Routes.growth(first.id) : Routes.tree(first.id)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _value(String text) => Text(
        text,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          fontFeatures: AppFonts.tabular,
        ),
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.button)),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: foreground),
          ),
        ),
      ),
    );
  }
}

/// Номер дерева «печатается» по символу; место под всю строку занято заранее.
class _TypedCode extends StatelessWidget {
  const _TypedCode({required this.code, required this.extra, required this.t});

  final String code;
  final String extra;
  final Animation<double> t;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
      fontFeatures: AppFonts.tabular,
    );
    return AnimatedBuilder(
      animation: t,
      builder: (context, _) {
        // Печать начинается на 40% (600 мс) и идёт 900 мс.
        final p = ((t.value - 0.4) / 0.6).clamp(0.0, 1.0);
        final n = (p * code.length).round();
        return Text.rich(
          TextSpan(style: style, children: [
            TextSpan(text: code.substring(0, n)),
            TextSpan(text: code.substring(n), style: const TextStyle(color: Colors.transparent)),
            TextSpan(text: extra),
          ]),
          textAlign: TextAlign.right,
        );
      },
    );
  }
}

/// Галочка рисуется 0.4 с, затем гаснет и на её месте вырастает лист (всего 1.2 с).
class _CheckToLeaf extends StatelessWidget {
  const _CheckToLeaf({required this.t});

  final Animation<double> t;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: t,
      builder: (context, _) {
        final v = t.value;
        final lt = ((v - 0.55) / 0.45).clamp(0.0, 1.0);
        final grow = Curves.easeOutBack.transform(lt);
        return SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(size: const Size(64, 64), painter: _CheckPainter(v)),
              Opacity(
                opacity: (lt * 3).clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: (-40 * (1 - grow)) * math.pi / 180,
                  child: Transform.scale(
                    scale: 0.4 + 0.6 * grow,
                    child: const LeafIcon(size: 64),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.v);

  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    final draw = Curves.easeOutCubic.transform(((v * 1200 - 100) / 400).clamp(0.0, 1.0));
    final opacity = 1 - ((v - 0.55) / 0.2).clamp(0.0, 1.0);
    if (draw <= 0 || opacity <= 0) return;
    final k = size.width / 24;
    final path = Path()
      ..moveTo(5 * k, 12.5 * k)
      ..lineTo(9.5 * k, 17 * k)
      ..lineTo(19 * k, 7 * k);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * draw),
      Paint()
        ..color = AppColors.pine.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 * k
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.v != v;
}

/// 18 листьев, падающих сверху вниз по кругу (2.4 с, со сдвигом фаз).
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t) : super(repaint: t);

  final Animation<double> t;

  static const _colors = [AppColors.leaf, AppColors.leafLight, AppColors.sage, AppColors.awaitingDot];
  static final _fall = Cubic(0.3, 0.2, 0.6, 1);

  @override
  void paint(Canvas canvas, Size size) {
    final leaf = Path()
      ..moveTo(12, 22)
      ..cubicTo(6, 18, 4, 12, 6, 4)
      ..relativeCubicTo(8, 0, 14, 6, 12, 14)
      ..relativeCubicTo(-2, 3, -4, 4, -6, 4)
      ..close();
    final sx = size.width / 390;
    for (var i = 0; i < 18; i++) {
      final delay = ((i * 130) % 2400) / 2400;
      final p = (t.value - delay) % 1.0;
      final e = _fall.transform(p);
      final opacity = p < 0.1 ? p / 0.1 : 1 - (p - 0.1) / 0.9;
      final x = (12 + (i * 53) % 366) * sx;
      canvas.save();
      canvas.translate(x + 7, -40 + 600 * e + 7);
      canvas.rotate(300 * math.pi / 180 * e);
      canvas.scale(14 / 24);
      canvas.translate(-12, -12);
      canvas.drawPath(leaf, Paint()..color = _colors[i % 4].withValues(alpha: opacity.clamp(0.0, 1.0)));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}
