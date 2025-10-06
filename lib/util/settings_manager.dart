
import 'package:flutter/material.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

class SettingsManager {

  static final ValueNotifier<bool> efectosVisualesActivos = ValueNotifier(true);

  static Future<void> cargarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();

    efectosVisualesActivos.value = prefs.getBool('efectos_visuales') ?? true;
  }

  static Future<void> guardarPreferenciaEfectos(bool nuevoValor) async {

    efectosVisualesActivos.value = nuevoValor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('efectos_visuales', nuevoValor);
  }
}