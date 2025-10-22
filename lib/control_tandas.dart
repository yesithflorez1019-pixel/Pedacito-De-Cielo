// lib/control_tandas.dart
import 'package:flutter/material.dart';
import 'package:postres_app/crear_tanda_page.dart';
import 'package:postres_app/database.dart';
import 'package:postres_app/informe_ingresos.dart';
import 'package:postres_app/tanda.dart';
import 'package:postres_app/ver_pedidos_desde_bd.dart';
import 'util/app_colors.dart';
import 'package:postres_app/widgets/acrylic_card.dart';

class ControlTandasPage extends StatefulWidget {
  const ControlTandasPage({super.key});

  @override
  State<ControlTandasPage> createState() => _ControlTandasPageState();
}

class _ControlTandasPageState extends State<ControlTandasPage> {
  List<Tanda> tandas = [];
  Map<int, int> pedidosCount = {};

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    final data = await AppDatabase.obtenerTandasConConteo();
    if (!mounted) return;
    setState(() {
      tandas = data.map((e) => Tanda.fromMap(e)).toList();
      pedidosCount = {
        for (var e in data) e['id'] as int: e['pedidosCount'] as int
      };
    });
  }

  Future<void> crearOEditarTanda({Tanda? tanda}) async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CrearTandaPage(tandaExistente: tanda),
      ),
    );

    if (guardado == true) {
      await cargar();
    }
  }

  Future<void> eliminar(Tanda tanda) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kColorBackground1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar Tanda', style: TextStyle(color: kColorPrimary)),
        content: Text('¿Seguro que deseas eliminar "${tanda.nombre}"? Se borrarán todos sus pedidos y gastos asociados.', style: const TextStyle(color: kColorTextDark)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar', style: TextStyle(color: kColorTextDark.withOpacity(0.7)))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Sí, Eliminar'),
          ),
        ],
      ),
    );

    if (ok == true && tanda.id != null) {

      await AppDatabase.eliminarTanda(tanda.id!);
      await cargar();
    }
  }

  void abrirTanda(Tanda tanda) async {
    if (tanda.id == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TandaHomePage(
          tandaId: tanda.id!,
          nombreTanda: tanda.nombre,
        ),
      ),
    );
    await cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => crearOEditarTanda(),
        backgroundColor: kColorPrimary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kColorBackground1, kColorBackground2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            ClipPath(
              clipper: HeaderClipper(),
              child: Container(
                height: 150,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kColorHeader1, kColorHeader2],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                         const SizedBox(width: 48),
                        const Expanded(
                          child: Text(
                            'Tandas y Pedidos',
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: cargar,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: tandas.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: cargar,
                      color: kColorPrimary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: tandas.length,
                        itemBuilder: (context, i) {
                          final t = tandas[i];
                          return _buildTandaCard(t);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
     return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.collections_bookmark_outlined, size: 80, color: kColorPrimary.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text('No hay tandas creadas', style: TextStyle(fontSize: 24, color: kColorTextDark)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'Toca el botón "+" para crear la primera tanda de producción.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kColorTextDark.withOpacity(0.7), fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTandaCard(Tanda t) {
    final count = pedidosCount[t.id ?? 0] ?? 0;
    return AcrylicCard(
      child: InkWell(
        onTap: () => abrirTanda(t),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: kColorPrimary,
                radius: 24,
                child: Icon(Icons.collections_bookmark_outlined, size: 28, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kColorTextDark)),
                    const SizedBox(height: 4),
                    Text(
                      '$count pedidos',
                      style: TextStyle(fontSize: 14, color: kColorTextDark.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: kColorTextDark),
                    onPressed: () => crearOEditarTanda(tanda: t)
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => eliminar(t)
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}


class TandaHomePage extends StatelessWidget {
  final int tandaId;
  final String nombreTanda;
  const TandaHomePage({super.key, required this.tandaId, required this.nombreTanda});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kColorBackground1, kColorBackground2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [kColorHeader1, kColorHeader2],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        nombreTanda,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                padding: const EdgeInsets.all(24),
                children: [
                  _buildOptionCard(
                    context,
                    icon: Icons.receipt_long_outlined,
                    label: "Control de pedidos",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VerPedidosDesdeBDPage(
                              tandaId: tandaId, nombreTanda: nombreTanda),
                        ),
                      );
                    },
                  ),
                  _buildOptionCard(
                    context,
                    icon: Icons.bar_chart_outlined,
                    label: "Informe de ingresos",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InformeIngresosPage(
                              tandaId: tandaId, nombreTanda: nombreTanda),
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

  Widget _buildOptionCard(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return AcrylicCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: kColorPrimary.withOpacity(0.1),
              child: Icon(icon, size: 32, color: kColorPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, color: kColorTextDark),
            ),
          ],
        ),
      ),
    );
  }
}

class HeaderClipper extends CustomClipper<Path> {
 @override
 Path getClip(Size size) {
   var path = Path();
   path.lineTo(0, size.height);
   var firstControlPoint = Offset(size.width * 0.25, size.height);
   var firstEndPoint = Offset(size.width * 0.5, size.height - 30);
   path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);
   var secondControlPoint = Offset(size.width * 0.75, size.height - 60);
   var secondEndPoint = Offset(size.width, size.height - 40);
   path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);
   path.lineTo(size.width, 0);
   path.close();
   return path;
 }

 @override
 bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

