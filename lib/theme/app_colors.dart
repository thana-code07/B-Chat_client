import 'package:flutter/material.dart';

class AppColors {
  static const brand = Color(0xFF8ECAE6);
  static const ink = Color(0xFF16324F);
  static const button = Color(0xFF2F6F9F);
  static const link = Color(0xFF1D4E89);
  static const muted = Color(0xFF5C6B7A);
  static const line = Color(0xFFD5E3EE);
  static const danger = Color(0xFF9B2C2C);
  static const surface = Colors.white;
  static const inbox = Color(0xFFF6F3F7);
  static const chatInk = Color(0xFF2C2836);
  static const chatMuted = Color(0xFF6F6A78);
  static const avatarFill = Color(0xFFE6E4EA);
  static const avatarLetter = Color(0xFF4A4458);
  static const chatAvatar = Color(0xFFE25C5C);
  static const incoming = Color(0xFFE7E7EA);
  static const outgoing = Color(0xFFF6C9DA);
  static const online = Color(0xFF1B7F3A);
  static const send = Color(0xFF6D4AFF);
  static const sendDisabled = Color(0xFFD5CCFF);
  static const deliveredReceipt = Color(0xFF8A8494);
  static const readReceipt = Color(0xFF1A73E8);
}

ThemeData buildAppTheme() {
  const shape = StadiumBorder();
  const label = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.button,
      primary: AppColors.button,
      onPrimary: Colors.white,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.brand,
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      bodyMedium: TextStyle(fontSize: 16, color: AppColors.ink),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      errorMaxLines: 3,
      labelStyle: TextStyle(color: AppColors.muted),
      floatingLabelStyle: TextStyle(color: AppColors.link),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.line),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.button, width: 2),
      ),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.danger, width: 2),
      ),
    ),
    filledButtonTheme: const FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.button),
        foregroundColor: WidgetStatePropertyAll(Colors.white),
        minimumSize: WidgetStatePropertyAll(Size(0, 48)),
        shape: WidgetStatePropertyAll(shape),
        textStyle: WidgetStatePropertyAll(label),
      ),
    ),
    outlinedButtonTheme: const OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(AppColors.button),
        minimumSize: WidgetStatePropertyAll(Size(0, 48)),
        side: WidgetStatePropertyAll(BorderSide(color: AppColors.button, width: 1.5)),
        shape: WidgetStatePropertyAll(shape),
        textStyle: WidgetStatePropertyAll(label),
      ),
    ),
    textButtonTheme: const TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(AppColors.link),
        textStyle: WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w600)),
      ),
    ),
  );
}
