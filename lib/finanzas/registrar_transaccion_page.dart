import 'package:flutter/material.dart';
import 'package:postres_app/database.dart';
import 'package:postres_app/formato.dart';
import 'package:postres_app/finanzas/cuenta.dart';
import 'package:postres_app/finanzas/transaccion.dart';
import 'dart:ui';

class RegistrarTransaccionPage extends StatefulWidget {
  final Cuenta? cuentaPorDefecto;
  const RegistrarTransaccionPage({super.key, this.cuentaPorDefecto});

  @override
  State<RegistrarTransaccionPage> createState() => _RegistrarTransaccionPageState();
}

class _RegistrarTransaccionPageState extends State<RegistrarTransaccionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  
  String _tipoTransaccion = 'gasto';
  String? _categoriaSeleccionada;
  late Cuenta _cuentaSeleccionada;
  
  final Map<String, String> _categoriasIngreso = {
    'Sueldo': '💰', 'Ventas': '📦', 'Regalo': '🎁', 'Otros': '✨'
  };
  final Map<String, String> _categoriasGasto = {
    'Comida': '🍔', 'Transporte': '🚗', 'Servicios': '💡', 'Entretenimiento': '🎬', 'Compras': '🛍️', 'Otros': '🤷'
  };

  @override
  void initState() {
    super.initState();
    _cuentaSeleccionada = widget.cuentaPorDefecto!;
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _guardarTransaccion() async {
    if (_formKey.currentState!.validate()) {
      final nuevaTransaccion = Transaccion(
        monto: double.tryParse(_montoController.text) ?? 0.0,
        tipo: _tipoTransaccion,
        categoria: _categoriaSeleccionada!,
        descripcion: _descripcionController.text.isNotEmpty ? _descripcionController.text : null,
        fecha: DateTime.now(),
        cuentaId: _cuentaSeleccionada.id!,
      );
      
      await AppDatabase.insertarTransaccion(nuevaTransaccion);
      
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Widget _buildCategoryChips() {
    final categorias = _tipoTransaccion == 'ingreso' ? _categoriasIngreso : _categoriasGasto;
    final List<Widget> chips = categorias.entries.map((entry) {
      final categoria = entry.key;
      final emoji = entry.value;
      final isSelected = _categoriaSeleccionada == categoria;

      return ChoiceChip(
        label: Text(categoria),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _categoriaSeleccionada = categoria;
            });
          }
        },
        selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        backgroundColor: Colors.grey.shade200,
        labelStyle: TextStyle(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        avatar: Text(emoji, style: const TextStyle(fontSize: 18)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
          ),
        ),
        elevation: isSelected ? 2 : 0,
      );
    }).toList();

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: chips,
    );
  }

  @override
  Widget build(BuildContext context) {

    const Color colorTextoOscuro = Color(0xFF333333);
    final Color colorPrimario = Theme.of(context).colorScheme.primary;

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
                  colors: [Color(0xFFE3AADD), Color(0xFFD4A3C4)],
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
                        'Registrar Transacción',
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
                                    child: Column(
                                      children: [
                                        Icon(Icons.account_balance_wallet, size: 60, color: colorPrimario),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Registrar en ${_cuentaSeleccionada.nombre}',
                                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: colorTextoOscuro),
                                          textAlign: TextAlign.center,
                                        ),
                                        Text(
                                          'Saldo actual: ${_cuentaSeleccionada.balance.aPesos()}',
                                          style: TextStyle(color: colorTextoOscuro.withOpacity(0.7)),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  TextFormField(
                                    controller: _montoController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      labelText: 'Monto',
                                      prefixIcon: Icon(Icons.attach_money, color: colorPrimario),
                                      fillColor: Colors.white.withOpacity(0.5),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty || double.tryParse(value) == null) {
                                        return 'Ingrese un monto válido';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('Tipo de Transacción', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ChoiceChip(
                                        label: const Text('Gasto'),
                                        selected: _tipoTransaccion == 'gasto',
                                        onSelected: (selected) {
                                          if (selected) {
                                            setState(() {
                                              _tipoTransaccion = 'gasto';
                                              _categoriaSeleccionada = null;
                                            });
                                          }
                                        },
                                        selectedColor: Colors.red.shade100,
                                        labelStyle: TextStyle(color: _tipoTransaccion == 'gasto' ? Colors.red.shade900 : colorTextoOscuro),
                                        avatar: Icon(Icons.arrow_downward_rounded, color: _tipoTransaccion == 'gasto' ? Colors.red.shade900 : Colors.grey),
                                      ),
                                      const SizedBox(width: 16),
                                      ChoiceChip(
                                        label: const Text('Ingreso'),
                                        selected: _tipoTransaccion == 'ingreso',
                                        onSelected: (selected) {
                                          if (selected) {
                                            setState(() {
                                              _tipoTransaccion = 'ingreso';
                                              _categoriaSeleccionada = null;
                                            });
                                          }
                                        },
                                        selectedColor: Colors.green.shade100,
                                        labelStyle: TextStyle(color: _tipoTransaccion == 'ingreso' ? Colors.green.shade900 : colorTextoOscuro),
                                        avatar: Icon(Icons.arrow_upward_rounded, color: _tipoTransaccion == 'ingreso' ? Colors.green.shade900 : Colors.grey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  if (_tipoTransaccion.isNotEmpty)
                                    _buildCategoryChips(),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _descripcionController,
                                    decoration: InputDecoration(
                                      labelText: 'Descripción (opcional)',
                                      prefixIcon: Icon(Icons.edit_note, color: colorPrimario),
                                      fillColor: Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: _guardarTransaccion,
                                    icon: const Icon(Icons.save),
                                    label: const Text('Guardar Transacción'),
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