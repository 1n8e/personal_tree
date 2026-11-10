import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../shared/design.dart';
import 'motion.dart';

const _ideas = ['Листик', 'Алма', 'Шёпот', 'Тянь-Шань'];

/// Шаг 2 из 3: имя дереву. Росток в горшке с табличкой, по «Назвать» — всплеск листьев (NameTree.dc.html).
class NameTreeScreen extends ConsumerStatefulWidget {
  const NameTreeScreen({
    super.key,
    required this.speciesId,
    required this.quantity,
    required this.mode,
    this.installment,
  });

  final String speciesId;
  final int quantity;
  final PaymentMode mode;
  final int? installment;

  @override
  ConsumerState<NameTreeScreen> createState() => _NameTreeScreenState();
}

class _NameTreeScreenState extends ConsumerState<NameTreeScreen> with TickerProviderStateMixin {
  final _text = TextEditingController(text: _ideas.first);
  final _focus = FocusNode();
  late final AnimationController _wob = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  late final AnimationController _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 990));
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(_onChanged);
    _focus.addListener(() => setState(() {}));
  }

  String _lastText = _ideas.first;

  void _onChanged() {
    if (_text.text == _lastText) return;
    _lastText = _text.text;
    if (!MediaQuery.disableAnimationsOf(context)) _wob.forward(from: 0);
    setState(() {});
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    _wob.dispose();
    _burst.dispose();
    super.dispose();
  }

  void _pick(String name) {
    if (_done) return;
    _text.text = name;
    _text.selection = TextSelection.collapsed(offset: name.length);
  }

  Future<void> _confirm() async {
    final name = _text.text.trim();
    if (_done || name.isEmpty) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();
    final reduce = MediaQuery.disableAnimationsOf(context);
    setState(() => _done = true);
    if (!reduce) {
      await _burst.forward(from: 0);
    }
    if (!mounted) return;
    final order = ref.read(appControllerProvider.notifier).placeOrder(
          speciesId: widget.speciesId,
          quantity: widget.quantity,
          name: name,
          mode: widget.mode,
          installment: widget.installment,
        );
    context.go(Routes.orderSuccess(order.id));
  }

  @override
  Widget build(BuildContext context) {
    final name = _text.text.trim();
    final plate = name.isEmpty ? '…' : name;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 20, 0),
              child: Row(
                children: [
                  RoundBackButton(onPressed: _done ? null : () => context.pop()),
                  const SizedBox(width: 12),
                  const Expanded(child: _StepBars()),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                  child: Column(
                    children: [
                      Text('Как назовём?', textAlign: TextAlign.center, style: AppFonts.display(size: 32)),
                      const SizedBox(height: 8),
                      const Text(
                        'Имя увидите вы — в приложении и на табличке в карточке дерева',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: AppColors.muted),
                      ),
                      const SizedBox(height: 24),
                      _Pot(plate: plate, wob: _wob, burst: _burst),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'Имя дерева',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.muted),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedContainer(
                        duration: motion(context, 150),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _focus.hasFocus
                              ? const [BoxShadow(color: Color(0x264F7A2A), spreadRadius: 4)]
                              : const [],
                        ),
                        child: TextField(
                          controller: _text,
                          focusNode: _focus,
                          readOnly: _done,
                          maxLength: 20,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _confirm(),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.pine),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: 'Например, Листик',
                            filled: true,
                            fillColor: AppColors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                            constraints: const BoxConstraints(minHeight: 60, maxHeight: 60),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppColors.sage, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppColors.leaf, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final idea in _ideas)
                              PressScale(
                                child: GestureDetector(
                                  onTap: () => _pick(idea),
                                  child: Container(
                                    height: 44,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.mint,
                                      borderRadius: BorderRadius.circular(AppRadius.chip),
                                    ),
                                    child: Text(
                                      idea,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.pine,
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
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: PressScale(
                child: GestureDetector(
                  onTap: name.isEmpty ? null : _confirm,
                  child: AnimatedContainer(
                    duration: motion(context, 200),
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _done ? AppColors.leaf : AppColors.pine,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: Opacity(
                      opacity: name.isEmpty && !_done ? 0.5 : 1,
                      child: Text(
                        _done ? 'Привет, $plate!' : 'Назвать дерево',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBars extends StatelessWidget {
  const _StepBars();

  @override
  Widget build(BuildContext context) {
    Widget bar(Color c) => Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
          ),
        );
    return Semantics(
      label: 'Шаг 2 из 3',
      child: Row(children: [
        bar(AppColors.leaf),
        const SizedBox(width: 6),
        bar(AppColors.leaf),
        const SizedBox(width: 6),
        bar(AppColors.sage),
      ]),
    );
  }
}

/// Росток в горшке 240×280 с табличкой; свечение и листья появляются при [burst].
class _Pot extends StatelessWidget {
  const _Pot({required this.plate, required this.wob, required this.burst});

  final String plate;
  final Animation<double> wob;
  final Animation<double> burst;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Росток в горшке',
      image: true,
      child: SizedBox(
        width: 240,
        height: 280,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: CustomPaint(painter: _PotPainter(wob))),
            Positioned(
              left: 84,
              top: 210,
              width: 72,
              height: 30,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(plate, maxLines: 1, style: AppFonts.hand(size: 22)),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(child: CustomPaint(painter: _BurstPainter(burst))),
            ),
          ],
        ),
      ),
    );
  }
}

class _PotPainter extends CustomPainter {
  _PotPainter(this.wob) : super(repaint: wob);

  final Animation<double> wob;

  static final _seq = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: -4), weight: 25),
    TweenSequenceItem(tween: Tween(begin: -4, end: 3), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 3, end: -1.5), weight: 25),
    TweenSequenceItem(tween: Tween(begin: -1.5, end: 0), weight: 20),
  ]);

  @override
  void paint(Canvas canvas, Size size) {
    Paint fill(Color c) => Paint()..color = c;
    canvas.drawCircle(const Offset(120, 130), 104, fill(AppColors.mint));

    // Росток: качается вокруг основания стебля (50% 100% рамки группы).
    final deg = wob.value == 0 ? 0.0 : _seq.transform(Curves.easeOut.transform(wob.value));
    canvas.save();
    canvas.translate(121, 190);
    canvas.rotate(deg * math.pi / 180);
    canvas.translate(-121, -190);
    canvas.drawPath(
      Path()
        ..moveTo(120, 190)
        ..cubicTo(120, 160, 122, 140, 120, 100),
      Paint()
        ..color = AppColors.leaf
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      Path()
        ..moveTo(120, 124)
        ..cubicTo(96, 120, 80, 100, 84, 76)
        ..cubicTo(106, 80, 120, 100, 120, 124)
        ..close(),
      fill(AppColors.leaf),
    );
    canvas.drawPath(
      Path()
        ..moveTo(121, 112)
        ..cubicTo(144, 106, 160, 86, 158, 62)
        ..cubicTo(134, 66, 120, 88, 121, 112)
        ..close(),
      fill(AppColors.leafLight),
    );
    canvas.restore();

    canvas.drawPath(
      Path()
        ..moveTo(72, 186)
        ..lineTo(168, 186)
        ..lineTo(156, 262)
        ..lineTo(84, 262)
        ..close(),
      fill(AppColors.clay),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(64, 176, 112, 20), const Radius.circular(7)),
      fill(const Color(0xFFB26A3C)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(84, 210, 72, 30), const Radius.circular(8)),
      fill(AppColors.cream),
    );
  }

  @override
  bool shouldRepaint(_PotPainter old) => false;
}

/// Свечение (240 px, scale 0→1.4, fade) и 14 листьев, разлетающихся по кругу за 900 мс.
class _BurstPainter extends CustomPainter {
  _BurstPainter(this.t) : super(repaint: t);

  final Animation<double> t;

  static const _colors = [AppColors.leaf, AppColors.leafLight, AppColors.sage, AppColors.awaitingDot];
  static const _total = 990.0;
  static final _fly = Cubic(0.2, 0.6, 0.4, 1);

  @override
  void paint(Canvas canvas, Size size) {
    final ms = t.value * _total;
    if (t.value == 0) return;

    // Свечение: центр иллюстрации.
    final g = Curves.easeOutCubic.transform((ms / 900).clamp(0, 1));
    final center = Offset(size.width / 2, 120);
    canvas.drawCircle(
      center,
      120 * 1.4 * g,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFE3B04B).withValues(alpha: 0.55 * 0.9 * (1 - g)),
          const Color(0x00DCE6D3),
        ], stops: const [0, 0.7]).createShader(Rect.fromCircle(center: center, radius: 120 * 1.4 * g + 0.01)),
    );

    final leaf = Path()
      ..moveTo(12, 22)
      ..cubicTo(6, 18, 4, 12, 6, 4)
      ..relativeCubicTo(8, 0, 14, 6, 12, 14)
      ..relativeCubicTo(-2, 3, -4, 4, -6, 4)
      ..close();
    final origin = Offset(size.width / 2, 90);
    for (var i = 0; i < 14; i++) {
      final a = i / 14 * math.pi * 2;
      final r = 110.0 + (i % 3) * 30;
      final delay = (i % 4) * 30.0;
      final p = ((ms - delay) / 900).clamp(0.0, 1.0);
      if (p <= 0) continue;
      final e = _fly.transform(p);
      final pos = origin + Offset(math.cos(a) * r, math.sin(a) * r + 60) * e;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(220 * math.pi / 180 * e);
      canvas.scale(16 / 24);
      canvas.translate(-12, -12);
      canvas.drawPath(leaf, Paint()..color = _colors[i % 4].withValues(alpha: 1 - p));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => false;
}
