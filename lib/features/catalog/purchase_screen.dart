import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/app_state.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../shared/design.dart';
import '../../shared/format.dart';
import 'motion.dart';

const _minQty = 1;
const _maxQty = 20;
const _plans = [1000, 2000, 3000];

/// Доли стоимости посадки по пунктам «Что входит» (из расчёта 6 000 ₸ в дизайне).
const _includeShares = [2800, 1200, 600, 1000, 400];

/// Карточка дерева и оформление: «Сразу / Копить», количество, состав (TreeDetail.dc.html).
class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key, required this.speciesId});

  final String speciesId;

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  PaymentMode _mode = PaymentMode.full;
  int _qty = 1;
  int _dir = 1;
  int _plan = 2000;

  late final TreeSpecies _species = speciesById(widget.speciesId);

  bool get _saving => _mode == PaymentMode.installments;

  int get _price => _species.price * _qty;

  /// Сумма к оплате сейчас: всё целиком или первые взносы по каждому дереву.
  int get _total => _saving ? math.min(_plan, _species.price) * _qty : _price;

  void _setQty(int q) {
    if (q < _minQty || q > _maxQty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _dir = q > _qty ? 1 : -1;
      _qty = q;
    });
  }

  void _checkout() {
    context.push(Routes.nameTree(
      _species.id,
      quantity: _qty,
      mode: _mode,
      installment: _saving ? _plan : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final months = (_species.price / _plan).ceil();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _Hero(species: _species),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(species: _species),
                      const SizedBox(height: 20),
                      _Includes(species: _species),
                      const SizedBox(height: 20),
                      _ModeSwitch(
                        mode: _mode,
                        onChanged: (m) => setState(() => _mode = m),
                      ),
                      AnimatedSize(
                        duration: motion(context, 250),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: _saving
                            ? Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: _PlanCard(
                                  plan: _plan,
                                  months: months,
                                  onPick: (v) => setState(() => _plan = v),
                                ),
                              )
                            : const SizedBox(width: double.infinity),
                      ),
                      const SizedBox(height: 20),
                      _QtyStepper(qty: _qty, dir: _dir, onChange: _setQty),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _TotalBar(
              label: _saving ? 'Первый взнос · всего ${formatPrice(_price)}' : 'Итого',
              total: _total,
              bottomInset: pad.bottom,
              onCheckout: _checkout,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Шапка с иллюстрацией ----------------------------------------------------

class _Hero extends StatelessWidget {
  const _Hero({required this.species});

  final TreeSpecies species;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      height: 320,
      decoration: const BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _MountainsPainter())),
          const Align(alignment: Alignment.bottomCenter, child: _SwayTree()),
          Positioned(
            top: top + 8,
            left: 16,
            child: RoundBackButton(
              onPressed: () => context.canPop() ? context.pop() : context.go(Routes.catalog),
            ),
          ),
        ],
      ),
    );
  }
}

/// Силуэт гор (390×120 в дизайне) у нижнего края шапки.
class _MountainsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 390;
    final base = size.height - 120;
    final p = Path()
      ..moveTo(0, base + 120)
      ..lineTo(80 * sx, base + 50)
      ..lineTo(140 * sx, base + 80)
      ..lineTo(220 * sx, base + 20)
      ..lineTo(300 * sx, base + 70)
      ..lineTo(size.width, base + 40)
      ..lineTo(size.width, base + 120)
      ..close();
    canvas.drawPath(p, Paint()..color = AppColors.sage);
  }

  @override
  bool shouldRepaint(_MountainsPainter old) => false;
}

/// Карагач из дизайна (viewBox 110×120 → 230×250), крона покачивается ±1.5° за 4 с.
class _SwayTree extends StatefulWidget {
  const _SwayTree();

  @override
  State<_SwayTree> createState() => _SwayTreeState();
}

class _SwayTreeState extends State<_SwayTree> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 2));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _c.stop();
      _c.value = 0.5;
      _started = false;
    } else if (!_started) {
      _started = true;
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Иллюстрация дерева',
      image: true,
      child: CustomPaint(size: const Size(230, 250), painter: _TreePainter(_c)),
    );
  }
}

class _TreePainter extends CustomPainter {
  _TreePainter(this.t) : super(repaint: t);

  final Animation<double> t;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 110;
    canvas.scale(k);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(55, 114), width: 68, height: 10),
      Paint()..color = AppColors.sageDark,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(51, 62, 8, 52), const Radius.circular(3)),
      Paint()..color = AppColors.soil,
    );
    final eased = Curves.easeInOut.transform(t.value);
    final angle = ui.lerpDouble(-1.5, 1.5, eased)! * math.pi / 180;
    canvas.save();
    canvas.translate(56, 80);
    canvas.rotate(angle);
    canvas.translate(-56, -80);
    canvas.drawCircle(const Offset(55, 50), 30, Paint()..color = AppColors.leaf);
    canvas.drawCircle(const Offset(36, 62), 18, Paint()..color = AppColors.leafDark);
    canvas.drawCircle(const Offset(74, 60), 20, Paint()..color = AppColors.leafLight);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TreePainter old) => false;
}

// --- Заголовок и состав --------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.species});

  final TreeSpecies species;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (species.isPopular) ...[
          Container(
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.pine, borderRadius: BorderRadius.circular(AppRadius.chip)),
            child: const Text(
              'Популярное',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.white),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Text(species.name, style: AppFonts.display(size: 32)),
        const SizedBox(height: 2),
        Text(
          species.latinName,
          style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.muted),
        ),
        const SizedBox(height: 10),
        Text(
          species.description,
          style: const TextStyle(fontSize: 15, height: 1.55, color: Color(0xFF33402A)),
        ),
      ],
    );
  }
}

class _Includes extends StatelessWidget {
  const _Includes({required this.species});

  final TreeSpecies species;

  /// Сумма по пункту: доля от цены вида, округлено до 100 ₸, последний пункт добирает остаток.
  List<int> get _sums {
    final n = MockData.includes.length;
    final total = _includeShares.fold(0, (a, b) => a + b);
    var rest = species.price;
    return [
      for (var i = 0; i < n; i++)
        if (i == n - 1)
          rest
        else
          () {
            final v = (species.price * _includeShares[i % _includeShares.length] / total / 100).round() * 100;
            rest -= v;
            return v;
          }(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sums = _sums;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Что входит в посадку',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.pine),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < MockData.includes.length; i++)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(12)),
                    child: Icon(MockData.includes[i].icon, size: 18, color: AppColors.pine),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      MockData.includes[i].title,
                      style: const TextStyle(fontSize: 14, color: AppColors.ink),
                    ),
                  ),
                  Text(
                    formatPrice(sums[i]),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.pine,
                      fontFeatures: AppFonts.tabular,
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

// --- Способ оплаты ---------------------------------------------------------------

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.mode, required this.onChanged});

  final PaymentMode mode;
  final ValueChanged<PaymentMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final saving = mode == PaymentMode.installments;
    Widget tab(String label, PaymentMode m) => Expanded(
          child: Semantics(
            button: true,
            selected: mode == m,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(m),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.pine),
                ),
              ),
            ),
          ),
        );

    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(AppRadius.button)),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: motion(context, 250),
            curve: Curves.easeOutCubic,
            alignment: saving ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Color(0x1F234010), blurRadius: 8, offset: Offset(0, 2))],
                ),
              ),
            ),
          ),
          Row(children: [tab('Сразу', PaymentMode.full), tab('Копить взносами', PaymentMode.installments)]),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.months, required this.onPick});

  final int plan;
  final int months;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.tile)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Взнос в месяц — дерево растёт с каждым пополнением',
            style: TextStyle(fontSize: 14, color: Color(0xFF33402A)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final v in _plans) ...[
                if (v != _plans.first) const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onPick(v),
                    child: AnimatedContainer(
                      duration: motion(context, 200),
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: v == plan ? AppColors.mint : AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: v == plan ? AppColors.leaf : AppColors.sage, width: 1.5),
                      ),
                      child: Text(
                        formatPrice(v),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pine,
                          fontFeatures: AppFonts.tabular,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '≈ $months ${plural(months, 'месяц', 'месяца', 'месяцев')} до посадки · можно пополнять в любой момент',
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

// --- Количество ----------------------------------------------------------------------

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({required this.qty, required this.dir, required this.onChange});

  final int qty;
  final int dir;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    Widget button(String label, IconData icon, bool filled, VoidCallback? onTap) => Semantics(
          button: true,
          label: label,
          enabled: onTap != null,
          child: PressScale(
            child: GestureDetector(
              onTap: onTap,
              child: Opacity(
                opacity: onTap == null ? 0.4 : 1,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: filled ? AppColors.leaf : AppColors.mint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 20, color: filled ? AppColors.white : AppColors.pine),
                ),
              ),
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.tile)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Количество деревьев', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          Row(
            children: [
              button('Меньше', Icons.remove_rounded, false, qty > _minQty ? () => onChange(qty - 1) : null),
              const SizedBox(width: 4),
              SizedBox(
                width: 40,
                height: 48,
                child: ClipRect(
                  child: AnimatedSwitcher(
                    duration: motion(context, 200),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, anim) {
                      final incoming = child.key == ValueKey(qty);
                      final begin = Offset(0, (incoming ? 0.6 : -0.6) * dir);
                      return FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween(begin: begin, end: Offset.zero).animate(anim),
                          child: child,
                        ),
                      );
                    },
                    child: Center(
                      key: ValueKey(qty),
                      child: Text(
                        '$qty',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.pine,
                          fontFeatures: AppFonts.tabular,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              button('Больше', Icons.add_rounded, true, qty < _maxQty ? () => onChange(qty + 1) : null),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Нижняя плашка ---------------------------------------------------------------------

class _TotalBar extends StatelessWidget {
  const _TotalBar({
    required this.label,
    required this.total,
    required this.bottomInset,
    required this.onCheckout,
  });

  final String label;
  final int total;
  final double bottomInset;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final bar = ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 14, 20, math.max(bottomInset, 20) + 10),
          decoration: const BoxDecoration(
            color: Color(0xEBFFFFFF),
            boxShadow: [BoxShadow(color: Color(0x14234010), blurRadius: 24, offset: Offset(0, -8))],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: motion(context, 200),
                      child: Text(
                        label,
                        key: ValueKey(label),
                        style: const TextStyle(fontSize: 13, color: AppColors.muted),
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: total.toDouble()),
                      duration: motion(context, 300),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => Text(
                        formatPrice(v.round()),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.pine,
                          fontFeatures: AppFonts.tabular,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              PressScale(
                child: GestureDetector(
                  onTap: onCheckout,
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.pine,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: const Text(
                      'Оформить',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: motion(context, 300),
      curve: Curves.easeOutCubic,
      child: bar,
      builder: (context, v, child) => FractionalTranslation(translation: Offset(0, v), child: child),
    );
  }
}
