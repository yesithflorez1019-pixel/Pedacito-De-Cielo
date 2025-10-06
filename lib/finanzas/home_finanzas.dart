import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:postres_app/database.dart';
import 'package:postres_app/formato.dart';
import 'cuenta.dart';
import 'registrar_cuenta_page.dart';
import 'historial_cuenta_page.dart';

class HomeFinanzasPage extends StatefulWidget {
  const HomeFinanzasPage({super.key});

  @override
  State<HomeFinanzasPage> createState() => _HomeFinanzasPageState();
}

class _HomeFinanzasPageState extends State<HomeFinanzasPage> {
  late Future<List<Cuenta>> _cuentasFuture;

  @override
  void initState() {
    super.initState();
    _cargarCuentas();
  }

  Future<void> _cargarCuentas() async {
    _cuentasFuture = AppDatabase.obtenerCuentas();
  }

  @override
  Widget build(BuildContext context) {


    final Color colorTextoOscuro = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87;
    final Color colorPrimario = Theme.of(context).colorScheme.primary;

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
            top: 90,
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Mis Finanzas',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<Cuenta>>(
                  future: _cuentasFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return const SizedBox();
                    }
                    final totalBalance = snapshot.data!.fold(0.0, (sum, item) => sum + item.balance);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Balance total',
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
                          ),
                          Text(
                            totalBalance.aPesos(),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: totalBalance >= 0 ? Colors.white : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 250.0),
            child: FutureBuilder<List<Cuenta>>(
              future: _cuentasFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No hay cuentas registradas.'));
                } else {
                  final cuentas = snapshot.data!;
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1,
                    ),
                    itemCount: cuentas.length,
                    itemBuilder: (context, index) {
                      final cuenta = cuentas[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                              border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.8),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => HistorialCuentaPage(cuenta: cuenta)),
                                );
                                setState(() {
                                  _cargarCuentas();
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.account_balance_wallet, size: 50, color: colorPrimario),
                                    const SizedBox(height: 12),
                                    Text(
                                      cuenta.nombre,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorTextoOscuro,
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${cuenta.balance.aPesos()}',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: cuenta.balance > 0 ? Colors.green.shade700 : Colors.red.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
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
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nueva Cuenta'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RegistrarCuentaPage()),
          );
          setState(() {
            _cargarCuentas();
          });
        },
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