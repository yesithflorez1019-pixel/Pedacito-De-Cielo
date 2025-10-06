import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:postres_app/database.dart';
import 'package:postres_app/formato.dart';

import 'cuenta.dart';
import 'transaccion.dart';
import 'registrar_transaccion_page.dart';

class HistorialCuentaPage extends StatefulWidget {
  final Cuenta cuenta;
  const HistorialCuentaPage({super.key, required this.cuenta});

  @override
  State<HistorialCuentaPage> createState() => _HistorialCuentaPageState();
}

class _HistorialCuentaPageState extends State<HistorialCuentaPage> {
  late Future<List<Transaccion>> _transaccionesFuture;

  @override
  void initState() {
    super.initState();
    _cargarTransacciones();
  }

  Future<void> _cargarTransacciones() async {
    _transaccionesFuture = AppDatabase.obtenerTransaccionesPorCuenta(widget.cuenta.id!);
  }

  @override
  Widget build(BuildContext context) {



    final Color colorTextoOscuro = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87;


    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        children: [

          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFCFAF2), Color(0xFFF6BCBA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          ClipPath(
            clipper: HeaderClipper(),
            child: Container(
              height: 250,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE3AADD), Color(0xFFD4A3C4)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Text(
                        'Atrás',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    widget.cuenta.nombre,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Saldo: ${widget.cuenta.balance.aPesos()}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 250.0),
            child: FutureBuilder<List<Transaccion>>(
              future: _transaccionesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No hay transacciones registradas.'));
                } else {
                  final transacciones = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: transacciones.length,
                    itemBuilder: (context, index) {
                      final transaccion = transacciones[index];
                      final esIngreso = transaccion.tipo == 'ingreso';
                      final icono = esIngreso ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
                      final color = esIngreso ? Colors.green.shade700 : Colors.red.shade700;

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                              border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.8),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: color.withOpacity(0.2),
                                child: Icon(icono, color: color),
                              ),
                              title: Text(
                                transaccion.categoria,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorTextoOscuro,
                                ),
                              ),
                              subtitle: Text(
                                DateFormat('dd/MM/yyyy - hh:mm a').format(transaccion.fecha),
                                style: TextStyle(color: colorTextoOscuro.withOpacity(0.7)),
                              ),
                              trailing: Text(
                                '${transaccion.monto.aPesos()}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RegistrarTransaccionPage(cuentaPorDefecto: widget.cuenta)),
          );
          setState(() {
            _cargarTransacciones();
          });
        },
        child: const Icon(Icons.add),
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