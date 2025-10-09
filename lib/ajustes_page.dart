
import 'package:flutter/material.dart';
import 'package:postres_app/util/app_colors.dart';
import 'package:postres_app/util/settings_manager.dart';
import 'package:postres_app/widgets/acrylic_card.dart';

class AjustesPage extends StatefulWidget {
  const AjustesPage({super.key});

  @override
  State<AjustesPage> createState() => _AjustesPageState();
}

class _AjustesPageState extends State<AjustesPage> {

  
  void _onToggle(bool newValue) {

    SettingsManager.guardarPreferenciaEfectos(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(  ),
        child: Column(
          children: [

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [

                  ValueListenableBuilder<bool>(
                    valueListenable: SettingsManager.efectosVisualesActivos,
                    builder: (context, efectosActivos, child) {
                      return AcrylicCard(
                        child: SwitchListTile(
                          title: const Text('Efectos Visuales Avanzados', style: TextStyle(fontWeight: FontWeight.bold, color: kColorTextDark)),
                          subtitle: Text('Desactiva esto si la app se siente lenta.', style: TextStyle(color: kColorTextDark.withOpacity(0.7))),
                          value: efectosActivos,
                          onChanged: _onToggle,
                          activeThumbColor: kColorPrimary,
                          secondary: const Icon(Icons.blur_on_outlined, color: kColorPrimary),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}