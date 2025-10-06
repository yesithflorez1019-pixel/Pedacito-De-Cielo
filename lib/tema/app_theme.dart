import 'package:flutter/material.dart';


class AppColors {
  static const Color fondo1 = Color(0xFFFCFAF2);
  static const Color fondo2 = Color(0xFFF6BCBA);
  static const Color header1 = Color(0xFFE3AADD);
  static const Color header2 = Color(0xFFD4A3C4);
  static const Color primario = Color(0xFFEB8DB5);
  static const Color tarjeta = Color(0xFFFFFFFF);
  static const Color textoOscuro = Color(0xFF333333);
}


final ThemeData appTheme = ThemeData(
  useMaterial3: true,

  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primario,
    primary: AppColors.primario,
    background: const Color.fromARGB(255, 220, 195, 231),
    surface: AppColors.tarjeta,
    brightness: Brightness.light,
  ),
  textTheme: const TextTheme(
    headlineMedium: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textoOscuro, fontSize: 24),
    titleLarge: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textoOscuro, fontSize: 18),
    bodyMedium: TextStyle(fontSize: 16.0, color: AppColors.textoOscuro),
    labelLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0, color: Colors.white),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.textoOscuro,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textoOscuro),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    clipBehavior: Clip.antiAlias,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primario,
    foregroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primario,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
    ),
  ),
);