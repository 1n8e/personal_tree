import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/app_state.dart';
import '../../shared/design.dart';
import 'auth_widgets.dart';

/// Три слайда: росток в ладонях, горшок с табличкой имени, дерево на фоне гор.
const _slides = [
  (
    title: 'Получи росток',
    text: 'Выберите вид дерева — карагач, клён, ель или берёзу. Это ваше личное дерево в Алматы.',
    name: 'Получи росток',
  ),
  (
    title: 'Дай имя',
    text: 'Назовите дерево так, как хочется. Под этим именем оно будет расти в приложении и на карте.',
    name: 'Дай имя',
  ),
  (
    title: 'Расти и посади в Алматы',
    text:
        'Оплатите сразу или копите взносами. Когда дерево «вырастет», партнёры посадят настоящее — и вы увидите его на карте.',
    name: 'Посади',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> with SingleTickerProviderStateMixin {
  final _page = PageController();
  late final AnimationController _sway = AnimationController(vsync: this, duration: const Duration(seconds: 4));
  int _index = 0;
  bool _swaying = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce && _swaying) {
      _sway.stop();
      _swaying = false;
    } else if (!reduce && !_swaying) {
      _sway.repeat(reverse: true);
      _swaying = true;
    }
  }

  @override
  void dispose() {
    _page.dispose();
    _sway.dispose();
    super.dispose();
  }

  double get _pos => _page.hasClients && _page.position.haveDimensions ? (_page.page ?? 0) : _index.toDouble();

  void _go(int i) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _page.jumpToPage(i);
    } else {
      _page.animateToPage(i, duration: const Duration(milliseconds: 450), curve: const Cubic(.2, 0, 0, 1));
    }
  }

  /// «Пропустить» и «Начать» — отметить онбординг пройденным и перейти ко входу.
  void _finish() {
    ref.read(appControllerProvider.notifier).completeOnboarding();
    context.go(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final d = mq.size.height - 844; // запас/нехватка высоты относительно макета
    final last = _index == _slides.length - 1;
    return Scaffold(
      body: AnimatedBuilder(
        animation: _page,
        builder: (context, _) {
          final pos = _pos;
          return Stack(
            fit: StackFit.expand,
            children: [
              TopoBackground(shift: pos * 60),
              // Лоза: серая основа и зелёная, растущая со страницей.
              Positioned(
                left: 0,
                right: 0,
                top: 476 + d,
                height: 120,
                child: ExcludeSemantics(child: CustomPaint(painter: _VinePainter(pos))),
              ),
              Positioned.fill(
                child: PageView.builder(
                  controller: _page,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => _SlidePage(index: i, d: d, sway: _sway),
                ),
              ),
              Positioned(
                top: math.max(56, mq.padding.top + 8),
                left: 24,
                right: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const BrandLogo(),
                    TextButton(
                      onPressed: _finish,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.muted,
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Пропустить'),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Semantics(
                      label: 'Страница ${_index + 1} из 3',
                      container: true,
                      child: Row(
                        children: [
                          for (var k = 0; k < _slides.length; k++)
                            Semantics(
                              button: true,
                              selected: k == _index,
                              label: 'Слайд ${k + 1}: ${_slides[k].name}',
                              child: InkResponse(
                                onTap: () => _go(k),
                                radius: 20,
                                child: SizedBox(
                                  width: 28,
                                  height: 48,
                                  child: Center(child: _Dot(proximity: (1 - (pos - k).abs()).clamp(0.0, 1.0))),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: FilledButton(
                        key: ValueKey(last),
                        onPressed: last ? _finish : () => _go(_index + 1),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 56),
                          padding: EdgeInsets.symmetric(horizontal: last ? 32 : 28),
                        ),
                        child: last
                            ? const Text('Начать')
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Далее'),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 20),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Лист-индикатор: активный — leaf и масштаб 1.35, остальные — sage.
class _Dot extends StatelessWidget {
  const _Dot({required this.proximity});
  final double proximity;

  @override
  Widget build(BuildContext context) => Transform.scale(
    scale: 1 + 0.35 * proximity,
    child: LeafIcon(size: 18, color: Color.lerp(AppColors.sage, AppColors.leaf, proximity)!),
  );
}

/// Один слайд: иллюстрация 300×300 и подпись «Шаг N из 3» с заголовком.
class _SlidePage extends StatelessWidget {
  const _SlidePage({required this.index, required this.d, required this.sway});
  final int index;
  final double d;
  final Animation<double> sway;

  @override
  Widget build(BuildContext context) {
    final s = _slides[index];
    final labels = ['Росток в ладонях', 'Росток в горшке с табличкой имени', 'Дерево на фоне гор Алматы'];
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 130,
          height: 340 + d,
          child: Center(
            child: FittedBox(
              child: Semantics(
                image: true,
                label: labels[index],
                child: SizedBox.square(
                  dimension: 300,
                  child: CustomPaint(painter: _IllustrationPainter(index, sway)),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          top: 596 + d,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ШАГ ${index + 1} ИЗ 3',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.04,
                  color: AppColors.leaf,
                ),
              ),
              const SizedBox(height: 8),
              Text(s.title, style: AppFonts.display(size: 32)),
              const SizedBox(height: 10),
              Text(s.text, style: const TextStyle(fontSize: 16, height: 1.5, color: AppColors.muted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _VinePainter extends CustomPainter {
  _VinePainter(this.pos);
  final double pos;

  static final _vine = svgPath('M-10 70 C 60 20, 110 110, 190 60 S 320 20, 400 70');
  static final _l1 = svgPath('M70 52 c-10-12-6-24 6-30 c4 12 2 22-6 30z');
  static final _l2 = svgPath('M190 60 c10-14 24-16 34-10 c-8 10-20 14-34 10z');
  static final _l3 = svgPath('M310 44 c-12-8-14-22-6-32 c10 8 12 20 6 32z');

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 390, 1);
    Paint stroke(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(_vine, stroke(AppColors.sage));
    final shown = ((pos + 1) * 153).clamp(0.0, 460.0);
    for (final m in _vine.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, math.min(shown, m.length)), stroke(AppColors.leaf));
    }
    canvas
      ..drawPath(_l1, Paint()..color = AppColors.leaf)
      ..drawPath(_l2, Paint()..color = AppColors.leafLight)
      ..drawPath(_l3, Paint()..color = AppColors.leaf);
  }

  @override
  bool shouldRepaint(_VinePainter old) => old.pos != pos;
}

/// Иллюстрации слайдов (SVG 300×300 из дизайна). Крона/росток покачиваются ±2°.
class _IllustrationPainter extends CustomPainter {
  _IllustrationPainter(this.kind, this.sway) : super(repaint: sway);
  final int kind;
  final Animation<double> sway;

  static final _s1 = [
    svgPath('M150 140 C128 136 112 118 116 96 C136 98 150 116 150 140Z'),
    svgPath('M151 130 C172 124 188 106 186 84 C164 88 150 106 151 130Z'),
  ];
  static final _s2 = [
    svgPath('M150 128 C126 124 110 104 114 80 C136 84 150 104 150 128Z'),
    svgPath('M151 116 C174 110 190 90 188 66 C164 70 150 92 151 116Z'),
  ];

  Paint _fill(Color c) => Paint()..color = c;
  Paint _line(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round;

  /// Покачивание вокруг основания группы.
  void _swayed(Canvas canvas, Offset pivot, VoidCallback draw) {
    final deg = -2 + 4 * Curves.easeInOut.transform(sway.value);
    canvas
      ..save()
      ..translate(pivot.dx, pivot.dy)
      ..rotate(deg * math.pi / 180)
      ..translate(-pivot.dx, -pivot.dy);
    draw();
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 300);
    const c = Offset(150, 160);
    switch (kind) {
      case 0:
        canvas.drawCircle(c, 120, _fill(AppColors.mint));
        _swayed(canvas, const Offset(150, 200), () {
          canvas.drawPath(svgPath('M150 200 C150 170 152 150 150 120'), _line(AppColors.leaf, 6));
          canvas
            ..drawPath(_s1[0], _fill(AppColors.leaf))
            ..drawPath(_s1[1], _fill(AppColors.leafLight));
        });
        canvas
          ..drawPath(
            svgPath('M70 210 C90 190 120 196 150 206 C180 196 210 190 230 210 C214 244 186 256 150 256 C114 256 86 244 70 210Z'),
            _fill(AppColors.sand),
          )
          ..drawPath(
            svgPath('M78 212 C100 200 126 206 150 212 C174 206 200 200 222 212'),
            _line(const Color(0xFFC9A57C), 3),
          )
          ..drawOval(Rect.fromCenter(center: const Offset(150, 206), width: 88, height: 20), _fill(AppColors.soilLight));
      case 1:
        canvas.drawCircle(c, 120, _fill(AppColors.sky));
        _swayed(canvas, const Offset(150, 190), () {
          canvas.drawPath(svgPath('M150 190 C150 160 152 140 150 104'), _line(AppColors.leaf, 6));
          canvas
            ..drawPath(_s2[0], _fill(AppColors.leaf))
            ..drawPath(_s2[1], _fill(AppColors.leafLight));
        });
        canvas
          ..drawPath(svgPath('M104 190 H196 L186 256 H114 Z'), _fill(AppColors.clay))
          ..drawRRect(
            RRect.fromRectAndRadius(const Rect.fromLTWH(98, 182, 104, 18), const Radius.circular(6)),
            _fill(const Color(0xFFB26A3C)),
          );
        final plate = RRect.fromRectAndRadius(const Rect.fromLTWH(188, 196, 78, 34), const Radius.circular(10));
        canvas
          ..drawRRect(plate, _fill(AppColors.white))
          ..drawRRect(plate, _line(AppColors.pine, 2))
          ..drawPath(svgPath('M188 210 L170 196'), _line(AppColors.pine, 2));
        final tp = TextPainter(
          text: TextSpan(text: 'Листик', style: AppFonts.hand(size: 20)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(227 - tp.width / 2, 219 - tp.computeDistanceToActualBaseline(TextBaseline.alphabetic)));
      default:
        canvas.drawCircle(c, 120, _fill(AppColors.mint));
        canvas
          ..drawPath(svgPath('M40 210 L95 120 L130 170 L175 96 L262 210Z'), _fill(AppColors.sage))
          ..drawPath(svgPath('M160 118 L175 96 L192 120 L182 116 L175 124 L168 116Z'), _fill(AppColors.white))
          ..drawPath(svgPath('M30 220 C90 200 210 200 270 220 L270 260 L30 260Z'), _fill(AppColors.meadow))
          ..drawRRect(
            RRect.fromRectAndRadius(const Rect.fromLTWH(144, 170, 12, 54), const Radius.circular(4)),
            _fill(AppColors.soil),
          );
        _swayed(canvas, const Offset(152, 190), () {
          canvas
            ..drawCircle(const Offset(150, 150), 38, _fill(AppColors.leaf))
            ..drawCircle(const Offset(126, 166), 24, _fill(AppColors.leafDark))
            ..drawCircle(const Offset(176, 164), 26, _fill(AppColors.leafLight));
        });
    }
  }

  @override
  bool shouldRepaint(_IllustrationPainter old) => old.kind != kind;
}
