
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:postres_app/util/settings_manager.dart';

class AcrylicCard extends StatelessWidget {
  final Widget child;
  const AcrylicCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {

    return ValueListenableBuilder<bool>(
      valueListenable: SettingsManager.efectosVisualesActivos,
      builder: (context, efectosActivos, _) {
        
        Widget backgroundWidget;
        if (efectosActivos) {

          backgroundWidget = BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.white.withOpacity(0.3)),
          );
        } else {

          backgroundWidget = Container(color: Colors.white.withOpacity(0.5));
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(child: backgroundWidget),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.0),
                ),
              ),
              child,
            ],
          ),
        );
      },
    );
  }
}