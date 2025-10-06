
import 'package:flutter/material.dart';
import 'insumos_page.dart';
import 'ver_productos.dart';
import 'util/app_colors.dart';


class InventarioPage extends StatelessWidget {
  const InventarioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(

        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(120.0), 
          child: Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [kColorHeader1, kColorHeader2],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                const Text(
                  "Centro de Inventario",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TabBar(
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorWeight: 2.5,
                  tabs: [
                    Tab(icon: Icon(Icons.blender_outlined), text: 'Insumos'),
                    Tab(icon: Icon(Icons.cake_outlined), text: 'Productos'),
                  ],
                ),
              ],
            ),
          ),
        ),

        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kColorBackground1, kColorBackground2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const TabBarView(
            children: [
              InsumosPage(),
              VerProductosPage(esSubPagina: true),
            ],
          ),
        ),
      ),
    );
  }
}