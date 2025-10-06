
import 'package:flutter/material.dart';
import 'package:postres_app/database.dart';
import 'package:postres_app/formato.dart';
import 'dart:ui';
import 'widgets/acrylic_card.dart';

import 'util/app_colors.dart';

class ReportesPage extends StatefulWidget {
  const ReportesPage({super.key});

  @override
  State<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends State<ReportesPage> {
  late Future<Map<String, dynamic>> _informesFuture;

  @override
  void initState() {
    super.initState();
    _cargarInformes();
  }

  void _cargarInformes() {
    setState(() {
      _informesFuture = _obtenerDatosGenerales();
    });
  }

  Future<Map<String, dynamic>> _obtenerDatosGenerales() async {

    final totalIngresosCobrados = await AppDatabase.obtenerTotalPagosParcialesGeneral();
    final totalGastos = await AppDatabase.obtenerTotalGastosGeneral();
    final productosMasVendidos = await AppDatabase.obtenerProductosMasVendidosGeneral();
    
    final cuentas = await AppDatabase.obtenerCuentas();
    final balancePersonal = cuentas.fold<double>(0.0, (sum, cuenta) => sum + cuenta.balance);

    return {
      'totalIngresos': totalIngresosCobrados,
      'totalGastos': totalGastos,
      'utilidadNeta': totalIngresosCobrados - totalGastos,
      'productosMasVendidos': productosMasVendidos.take(3).toList(),
      'balancePersonal': balancePersonal,
    };
  }

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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: Text(
                            'Panel de Control',
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: _cargarInformes,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _informesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: kColorPrimary));
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: kColorTextDark)));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No se encontraron datos.', style: TextStyle(color: kColorTextDark)));
                  }

                  final data = snapshot.data!;
                  return _buildReportContent(data);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent(Map<String, dynamic> data) {
    final utilidadNeta = data['utilidadNeta'] as double;
    final colorUtilidad = utilidadNeta >= 0 ? Colors.teal : Colors.redAccent;
    final productosVendidos = data['productosMasVendidos'] as List;

    return RefreshIndicator(
      onRefresh: () async => _cargarInformes(),
      color: kColorPrimary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildReportCard(
            title: 'Resumen General del Negocio',
            icon: Icons.business_center_outlined,
            content: [
              _buildMetricRow(Icons.arrow_downward, 'Ingresos (Cobrado)', (data['totalIngresos'] as double).aPesos(), Colors.teal),
              _buildMetricRow(Icons.arrow_upward, 'Gastos Totales', (data['totalGastos'] as double).aPesos(), Colors.redAccent),
              const Divider(color: Colors.white30),
              _buildMetricRow(Icons.bar_chart, 'Utilidad Neta', utilidadNeta.aPesos(), colorUtilidad, isTotal: true),
            ],
          ),
          const SizedBox(height: 16),
          _buildReportCard(
            title: 'Productos Más Vendidos',
            icon: Icons.emoji_events_outlined,
            content: productosVendidos.isEmpty
              ? [const Text("Aún no hay datos de ventas.", style: TextStyle(color: kColorTextDark))]
              : productosVendidos.map((prod) => Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
                  child: Text('• ${prod['producto']} (${prod['cantidadTotal']} uds.)', style: const TextStyle(color: kColorTextDark, fontSize: 15)),
              )).toList(),
          ),
          const SizedBox(height: 16),
          _buildReportCard(
            title: 'Finanzas Personales',
            icon: Icons.account_balance_wallet_outlined,
            content: [
              _buildMetricRow(Icons.attach_money, 'Balance Total', (data['balancePersonal'] as double).aPesos(), kColorPrimary),
              const SizedBox(height: 8),
              Text(
                'Nota: Este es el balance combinado de tus cuentas personales registradas.',
                style: TextStyle(fontStyle: FontStyle.italic, color: kColorTextDark.withOpacity(0.7), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({required String title, required IconData icon, required List<Widget> content}) {
    return AcrylicCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: kColorPrimary, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kColorTextDark)),
              ],
            ),
            const Divider(height: 24, color: Colors.white30),
            ...content,
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(IconData icon, String label, String value, Color color, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontSize: 15, color: kColorTextDark.withOpacity(0.9)))),
          Text(value, style: TextStyle(fontSize: isTotal ? 18 : 16, fontWeight: FontWeight.bold, color: color)),
        ],
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