import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Palet warna ala iOS (System Colors).
class AppColors {
  AppColors._();

  static const Color accentLight = Color(0xFF007AFF);
  static const Color accentDark = Color(0xFF0A84FF);
  static const Color red = Color(0xFFFF3B30);
  static const Color green = Color(0xFF34C759);
  static const Color orange = Color(0xFFFF9F0A);

  static const Color bgLight = Color(0xFFF2F2F7);
  static const Color bgDark = Color(0xFF000000);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1C1C1E);
  static const Color separatorLight = Color(0xFFE5E5EA);
  static const Color separatorDark = Color(0xFF38383A);
  static const Color mutedLight = Color(0xFF8E8E93);
  static const Color mutedDark = Color(0xFF98989D);
  static const Color textLight = Color(0xFF1C1C1E);
  static const Color textDark = Color(0xFFF2F2F7);
}

/// Tema Cupertino (light & dark) dengan nuansa iOS 17.
class AppTheme {
  AppTheme._();

  static const CupertinoThemeData light = CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.accentLight,
    scaffoldBackgroundColor: AppColors.bgLight,
    barBackgroundColor: Color(0xFDF2F2F7),
    textTheme: CupertinoTextThemeData(
      navLargeTitleTextStyle: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.15,
        color: AppColors.textLight,
      ),
      navTitleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textLight,
      ),
    ),
  );

  static const CupertinoThemeData dark = CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.accentDark,
    scaffoldBackgroundColor: AppColors.bgDark,
    barBackgroundColor: Color(0xE6000000),
    textTheme: CupertinoTextThemeData(
      navLargeTitleTextStyle: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.15,
        color: AppColors.textDark,
      ),
      navTitleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    ),
  );
}

/// Akses warna sesuai mode terang/gelap yang aktif.
class Ctx {
  Ctx(this.context);
  final BuildContext context;

  bool get dark => CupertinoTheme.brightnessOf(context) == Brightness.dark;

  Color get accent => dark ? AppColors.accentDark : AppColors.accentLight;
  Color get bg => dark ? AppColors.bgDark : AppColors.bgLight;
  Color get surface => dark ? AppColors.surfaceDark : AppColors.surfaceLight;
  Color get separator =>
      dark ? AppColors.separatorDark : AppColors.separatorLight;
  Color get muted => dark ? AppColors.mutedDark : AppColors.mutedLight;
  Color get text => dark ? AppColors.textDark : AppColors.textLight;
  Color get cardShadow =>
      dark ? Colors.transparent : Colors.black.withValues(alpha: 0.05);
}
