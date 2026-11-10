import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Палитра из дизайна Personal Tree (docs/design/project/*.dc.html).
abstract final class AppColors {
  // Основа
  static const cream = Color(0xFFF6F1E7); // фон экранов
  static const pine = Color(0xFF234010); // главный тёмно-зелёный: кнопки, заголовки
  static const pineDeep = Color(0xFF1C330C);
  static const leaf = Color(0xFF4F7A2A); // акцент: активные элементы, прогресс
  static const leafLight = Color(0xFF6E9A43);
  static const leafDark = Color(0xFF3F6620);
  static const sage = Color(0xFFB3C3AA); // неактивные листья, рамки
  static const sageDark = Color(0xFF9DB092);
  static const mint = Color(0xFFDCE6D3); // мягкие плашки, выбранные чипы
  static const sky = Color(0xFFD9E9F2); // логотип, блок «воздух»
  static const white = Color(0xFFFFFFFF);

  // Текст
  static const ink = Color(0xFF1E2B14);
  static const muted = Color(0xFF4E5A44);
  static const hint = Color(0xFF5B6650);
  static const faint = Color(0xFF6B7560);
  static const divider = Color(0xFFEEF0E8);
  static const stepTodo = Color(0xFFD2DAC9);

  // Земля и иллюстрации
  static const soil = Color(0xFF6B4A2B);
  static const soilLight = Color(0xFF8A6A44);
  static const clay = Color(0xFFC97B4A);
  static const sand = Color(0xFFE7C9A3);
  static const sun = Color(0xFFF6E3B4);
  static const meadow = Color(0xFF8FB070);
  static const mountain = Color(0xFFB9CCD6);

  // Статусы дерева
  static const growing = leaf;
  static const growingBg = mint;
  static const awaiting = Color(0xFF6E4A00);
  static const awaitingBg = Color(0xFFFBF1DC);
  static const awaitingDot = Color(0xFFE3B04B);
  static const planted = pine;
  static const plantedBg = mint;
  static const plantedDot = leaf;
  static const monitoring = Color(0xFF1F5577);
  static const monitoringBg = Color(0xFFDDEBF3);
  static const monitoringDot = Color(0xFF4A8FB5);
  static const aqi = Color(0xFF8A5A00);

  // Старые имена — пока экраны не переведены на новую палитру.
  static const forest = pine;
  static const forestDark = pineDeep;
  static const leafLightOld = mint;
  static const beige = cream;
  static const beigeDark = Color(0xFFE8DFD0);
}

abstract final class AppRadius {
  static const card = 24.0;
  static const tile = 20.0;
  static const button = 16.0;
  static const small = 12.0;
  static const chip = 999.0;
}

abstract final class AppSpacing {
  static const page = 20.0;
  static const gap = 12.0;
  static const section = 20.0;
}

abstract final class AppShadows {
  static const card = [BoxShadow(color: Color(0x14234010), blurRadius: 24, offset: Offset(0, 8))];
  static const tile = [BoxShadow(color: Color(0x0F234010), blurRadius: 16, offset: Offset(0, 4))];
  static const button = [BoxShadow(color: Color(0x2E234010), blurRadius: 24, offset: Offset(0, 8))];
  static const nav = [BoxShadow(color: Color(0x24234010), blurRadius: 30, offset: Offset(0, 10))];
}

/// Шрифты дизайна: Manrope — текст, Playfair Display — заголовки, Caveat — логотип и подписи.
abstract final class AppFonts {
  static TextStyle display({double size = 32, FontWeight weight = FontWeight.w700, Color color = AppColors.pine}) =>
      GoogleFonts.playfairDisplay(fontSize: size, fontWeight: weight, color: color, height: 1.15);

  static TextStyle hand({double size = 22, Color color = AppColors.pine}) =>
      GoogleFonts.caveat(fontSize: size, fontWeight: FontWeight.w700, color: color, height: 1);

  /// Мелкая подпись капсом над заголовком: «ВАШЕ ДЕРЕВО», «ШАГ 1 ИЗ 3».
  static TextStyle overline({Color color = AppColors.leaf}) =>
      const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8).copyWith(color: color);

  static const tabular = [FontFeature.tabularFigures()];
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.leaf,
    primary: AppColors.pine,
    onPrimary: AppColors.white,
    secondary: AppColors.leaf,
    onSecondary: AppColors.white,
    surface: AppColors.cream,
    onSurface: AppColors.ink,
  );

  final base = GoogleFonts.manropeTextTheme();
  final text = base.copyWith(
    headlineLarge: AppFonts.display(size: 32),
    headlineMedium: AppFonts.display(size: 26),
    headlineSmall: AppFonts.display(size: 20),
    titleLarge: base.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink),
    titleMedium: base.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
    titleSmall: base.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
    bodyLarge: base.bodyLarge?.copyWith(fontSize: 16, color: AppColors.muted, height: 1.5),
    bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, color: AppColors.ink, height: 1.4),
    bodySmall: base.bodySmall?.copyWith(fontSize: 13, color: AppColors.muted, height: 1.4),
    labelLarge: base.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
    labelMedium: base.labelMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
    labelSmall: base.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
  );

  final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button));
  final buttonText = GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.cream,
    textTheme: text,
    fontFamily: GoogleFonts.manrope().fontFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.pine,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppFonts.display(size: 22),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.pine,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: AppColors.sage,
        disabledForegroundColor: AppColors.pine,
        minimumSize: const Size.fromHeight(56),
        shape: buttonShape,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.pine,
        backgroundColor: AppColors.white,
        minimumSize: const Size.fromHeight(56),
        side: const BorderSide(color: AppColors.sage, width: 1.5),
        shape: buttonShape,
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.leaf,
        textStyle: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.sage, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.sage, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.leaf, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.hint),
      labelStyle: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.white,
      selectedColor: AppColors.leaf,
      side: const BorderSide(color: AppColors.sage),
      shape: const StadiumBorder(),
      labelStyle: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.pine),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.pine,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.cream,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(AppColors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.leaf : AppColors.sage,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
