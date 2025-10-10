import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:postres_app/database.dart';
import 'package:postres_app/finanzas/cuenta.dart';

class RegistrarCuentaPage extends StatefulWidget {
  const RegistrarCuentaPage({super.key});

  @override
  State<RegistrarCuentaPage> createState() => _RegistrarCuentaPageState();
}

class _RegistrarCuentaPageState extends State<RegistrarCuentaPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController(text: '0');

  @override
  void dispose() {
    _nombreController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _guardarCuenta() async {
    if (_formKey.currentState!.validate()) {
      final nuevaCuenta = Cuenta(
        nombre: _nombreController.text,
        balance: double.tryParse(_balanceController.text) ?? 0.0,
      );
      await AppDatabase.insertarCuenta(nuevaCuenta);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    const Color colorHeader1 = Color(0xFFE3AADD);
    const Color colorHeader2 = Color(0xFFC8A8E9);
    const Color colorPrimario = Color(0xFFEB8DB5);
    const Color colorTextoOscuro = Color(0xFF333333);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                  colors: [colorHeader1, colorHeader2],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 50.0),
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
                        'Nueva Cuenta',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white.withOpacity(0.3),
                            border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Form(
                              key: _formKey,
                              child: ListView(
                                children: [
                                  Center(
                                    child: Icon(Icons.account_balance_wallet, size: 60, color: colorPrimario),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Crea una nueva cuenta',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: colorTextoOscuro),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    'Dale un nombre y un saldo inicial',
                                    style: TextStyle(color: colorTextoOscuro.withOpacity(0.7)),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 32),
                                  TextFormField(
                                    controller: _nombreController,
                                    decoration: InputDecoration(
                                      labelText: 'Nombre de la cuenta',
                                      prefixIcon: Icon(Icons.label, color: colorPrimario),
                                      fillColor: Colors.white.withOpacity(0.5),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'El nombre es requerido.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _balanceController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      labelText: 'Balance inicial',
                                      prefixIcon: Icon(Icons.attach_money, color: colorPrimario),
                                      fillColor: Colors.white.withOpacity(0.5),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'El balance inicial es requerido.';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Ingrese un número válido.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: _guardarCuenta,
                                    icon: const Icon(Icons.save),
                                    label: const Text('Guardar Cuenta'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(255, 226, 226, 226),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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