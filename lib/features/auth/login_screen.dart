import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/app_state.dart';
import '../../shared/design.dart';
import 'auth_widgets.dart';

enum _Step { login, otp }

/// Вход и регистрация одним потоком: телефон или email → код из 4 цифр.
/// Пароля нет. После «Войти» роутер сам уводит на главную.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _resendSeconds = 42;

  final _field = TextEditingController();

  /// Скрытое поле кода: принимает системную и аппаратную клавиатуру и автоподстановку из SMS.
  final _otp = TextEditingController();
  final _otpFocus = FocusNode();
  _Step _step = _Step.login;
  bool _byPhone = true;
  bool _forward = true;
  int _left = _resendSeconds;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _field.dispose();
    _otp.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _otp.addListener(() => setState(() {}));
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _left = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_left <= 1) t.cancel();
      setState(() => _left = math.max(0, _left - 1));
    });
  }

  void _sendCode() {
    FocusScope.of(context).unfocus();
    setState(() {
      _forward = true;
      _step = _Step.otp;
      _otp.clear();
    });
    _startTimer();
    // Открываем клавиатуру, когда шаг уже на экране.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _otpFocus.requestFocus(),
    );
  }

  void _back() {
    _timer?.cancel();
    setState(() {
      _forward = false;
      _step = _Step.login;
      _otp.clear();
    });
    _otpFocus.unfocus();
  }

  void _signIn() => ref.read(appControllerProvider.notifier).loginDemo();

  /// Маска получателя для подписи «Отправили 4 цифры на …».
  String get _sentTo {
    final v = _field.text.trim();
    if (_byPhone) {
      return v.length < 7
          ? '+7 701 ••• •• 78'
          : '${v.substring(0, 5)} ••• •• ${v.substring(v.length - 2)}';
    }
    final at = v.indexOf('@');
    return at < 2
        ? 'al•••@mail.kz'
        : '${v.substring(0, 2)}•••${v.substring(at)}';
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final isLogin = _step == _Step.login;
    return PopScope(
      canPop: isLogin,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.cream, AppColors.mint],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const FloatingLeaves(),
              AnimatedSwitcher(
                duration: reduce
                    ? Duration.zero
                    : const Duration(milliseconds: 300),
                switchInCurve: const Cubic(.2, 0, 0, 1),
                switchOutCurve: const Cubic(.2, 0, 0, 1),
                transitionBuilder: (child, anim) {
                  final incoming = child.key == ValueKey(_step);
                  final dir = _forward ? 1.0 : -1.0;
                  final offset = Tween<Offset>(
                    begin: Offset((incoming ? dir : -dir) * 0.12, 0),
                    end: Offset.zero,
                  ).animate(anim);
                  return FadeTransition(
                    opacity: anim,
                    child: SlideTransition(position: offset, child: child),
                  );
                },
                layoutBuilder: (current, previous) => Stack(
                  fit: StackFit.expand,
                  children: [...previous, ?current],
                ),
                child: isLogin
                    ? _LoginStep(
                        key: const ValueKey(_Step.login),
                        field: _field,
                        byPhone: _byPhone,
                        onMode: (v) => setState(() => _byPhone = v),
                        onContinue: _sendCode,
                      )
                    : _OtpStep(
                        key: const ValueKey(_Step.otp),
                        controller: _otp,
                        focusNode: _otpFocus,
                        sentTo: _sentTo,
                        secondsLeft: _left,
                        onBack: _back,
                        onResend: _startTimer,
                        onSignIn: _signIn,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

double _headerTop(BuildContext context) =>
    math.max(56, MediaQuery.paddingOf(context).top + 8);

TextStyle get _heading => AppFonts.display(size: 34);

/// Шаг 1: заголовок, переключатель «Телефон / Email», поле, условия.
class _LoginStep extends StatelessWidget {
  const _LoginStep({
    super.key,
    required this.field,
    required this.byPhone,
    required this.onMode,
    required this.onContinue,
  });

  final TextEditingController field;
  final bool byPhone;
  final ValueChanged<bool> onMode;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    const underline = TextStyle(
      decoration: TextDecoration.underline,
      color: AppColors.pine,
    );
    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              math.max(150, _headerTop(context) + 94),
              24,
              120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Добро пожаловать\nв свой лес', style: _heading),
                const SizedBox(height: 10),
                const Text(
                  'Войдите или создайте аккаунт — пароль не нужен, пришлём код.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 24),
                _ModeTabs(byPhone: byPhone, onChanged: onMode),
                const SizedBox(height: 24),
                Text(
                  byPhone ? 'Номер телефона' : 'Электронная почта',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 60,
                  child: TextField(
                    key: ValueKey(byPhone),
                    controller: field,
                    keyboardType: byPhone
                        ? TextInputType.phone
                        : TextInputType.emailAddress,
                    autofillHints: [
                      byPhone
                          ? AutofillHints.telephoneNumber
                          : AutofillHints.email,
                    ],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => onContinue(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                    decoration: InputDecoration(
                      hintText: byPhone ? '+7 700 000 00 00' : 'name@mail.kz',
                      hintStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.hint,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  const TextSpan(
                    children: [
                      TextSpan(text: 'Нажимая «Продолжить», вы принимаете '),
                      TextSpan(text: 'условия', style: underline),
                      TextSpan(text: ' и '),
                      TextSpan(
                        text: 'политику конфиденциальности',
                        style: underline,
                      ),
                      TextSpan(text: '.'),
                    ],
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.hint,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: _headerTop(context),
          left: 24,
          child: const BrandLogo(),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 40,
          child: _ShadowButton(label: 'Продолжить', onPressed: onContinue),
        ),
      ],
    );
  }
}

/// Сегментированный переключатель с плавающей «таблеткой» (250 мс).
class _ModeTabs extends StatelessWidget {
  const _ModeTabs({required this.byPhone, required this.onChanged});

  final bool byPhone;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, bool phone) => Expanded(
      child: Semantics(
        button: true,
        selected: byPhone == phone,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onChanged(phone),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.pine,
              ),
            ),
          ),
        ),
      ),
    );
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 250),
            curve: const Cubic(.2, 0, 0, 1),
            alignment: byPhone ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Row(children: [tab('Телефон', true), tab('Email', false)]),
        ],
      ),
    );
  }
}

/// Шаг 2: 4 ячейки кода, экранная клавиатура, таймер повторной отправки.
class _OtpStep extends StatelessWidget {
  const _OtpStep({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.sentTo,
    required this.secondsLeft,
    required this.onBack,
    required this.onResend,
    required this.onSignIn,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String sentTo;
  final int secondsLeft;
  final VoidCallback onBack;
  final VoidCallback onResend;
  final VoidCallback onSignIn;

  String get _time =>
      '${secondsLeft ~/ 60}:${(secondsLeft % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final code = controller.text;
    final complete = code.length == 4;
    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              math.max(150, _headerTop(context) + 94),
              24,
              120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Введите код', style: _heading),
                const SizedBox(height: 10),
                Text(
                  'Отправили 4 цифры на $sentTo',
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 28),
                // Ячейки рисуют код, а вводит его невидимое поле под ними; тап по ячейкам открывает клавиатуру.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: focusNode.requestFocus,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0,
                          child: Semantics(
                            label:
                                'Код подтверждения, введено ${code.length} из 4',
                            child: TextField(
                              controller: controller,
                              focusNode: focusNode,
                              autofocus: true,
                              showCursor: false,
                              enableInteractiveSelection: false,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.oneTimeCode],
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              onSubmitted: (_) {
                                if (complete) onSignIn();
                              },
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                counterText: '',
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (var i = 0; i < 4; i++) ...[
                            if (i > 0) const SizedBox(width: 12),
                            Expanded(
                              child: _CodeCell(
                                digit: i < code.length ? code[i] : null,
                                active: i == code.length && focusNode.hasFocus,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                if (secondsLeft > 0)
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Отправить код повторно через '),
                        TextSpan(
                          text: _time,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.pine,
                            fontFeatures: AppFonts.tabular,
                          ),
                        ),
                      ],
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.muted,
                    ),
                  )
                else
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: onResend,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Отправить код повторно'),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          top: _headerTop(context),
          left: 16,
          child: RoundBackButton(onPressed: onBack),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 40,
          child: _ShadowButton(
            label: complete ? 'Войти' : 'Введите код целиком',
            onPressed: complete ? onSignIn : null,
          ),
        ),
      ],
    );
  }
}

/// Ячейка кода: цифра «выпрыгивает» за 150 мс, у активной мигает курсор.
class _CodeCell extends StatelessWidget {
  const _CodeCell({required this.digit, required this.active});

  final String? digit;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final filled = digit != null;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return AnimatedContainer(
      duration: reduce ? Duration.zero : const Duration(milliseconds: 150),
      height: 72,
      decoration: BoxDecoration(
        color: filled
            ? AppColors.white
            : AppColors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: filled || active ? AppColors.leaf : AppColors.sage,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: filled
          ? TweenAnimationBuilder<double>(
              key: ValueKey(digit),
              tween: Tween(begin: reduce ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 150),
              curve: const Cubic(.2, 0, 0, 1),
              builder: (_, k, child) => Opacity(
                opacity: k,
                child: Transform.translate(
                  offset: Offset(0, 8 * (1 - k)),
                  child: child,
                ),
              ),
              child: Text(
                digit!,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.pine,
                  fontFeatures: AppFonts.tabular,
                ),
              ),
            )
          : active
          ? const _Caret()
          : null,
    );
  }
}

class _Caret extends StatefulWidget {
  const _Caret();

  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && !MediaQuery.disableAnimationsOf(context)) {
      _c.repeat();
      _started = true;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Opacity(
        opacity: _c.value < 0.5 ? 1 : 0,
        child: Container(width: 2, height: 30, color: AppColors.leaf),
      ),
    ),
  );
}

/// Главная кнопка шага: высота 56 и мягкая тень, когда доступна.
class _ShadowButton extends StatelessWidget {
  const _ShadowButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.button),
        boxShadow: onPressed == null
            ? null
            : const [
                BoxShadow(
                  color: Color(0x2E234010),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: FilledButton(onPressed: onPressed, child: Text(label)),
    );
  }
}
