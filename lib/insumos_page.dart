// lib/insumos_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'database.dart';
import 'insumo.dart';
import 'formato.dart';
import 'util/app_colors.dart';
import 'package:postres_app/widgets/acrylic_card.dart';
class InsumosPage extends StatefulWidget {
  const InsumosPage({super.key});

  @override
  State<InsumosPage> createState() => _InsumosPageState();
}

class _InsumosPageState extends State<InsumosPage> {
  List<Insumo> _insumos = [];

  @override
  void initState() {
    super.initState();
    _cargarInsumos();
  }

  Future<void> _cargarInsumos() async {
    final data = await AppDatabase.getInsumos();
    if (!mounted) return;
    setState(() {
      _insumos = data;
    });
  }

  Future<void> _eliminarInsumo(Insumo insumo) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kColorBackground1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar Insumo?', style: TextStyle(color: kColorPrimary)),
        content: Text('¿Seguro que quieres eliminar "${insumo.nombre}"? Se quitará de todas tus recetas.', style: const TextStyle(color: kColorTextDark)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: kColorTextDark.withOpacity(0.7))),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Sí, Eliminar'),
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )
        ],
      ),
    );

    if (confirmado == true) {

      await AppDatabase.eliminarInsumo(insumo.id!);
      _cargarInsumos();
    }
  }

  Future<void> _mostrarDialogoInsumo({Insumo? insumo}) async {
    final esNuevo = insumo == null;
    final nombreCtrl = TextEditingController(text: insumo?.nombre ?? '');
    final precioTotalCtrl = TextEditingController();
    final cantidadCompradaCtrl = TextEditingController();

    String unidadSeleccionada = insumo?.unidad ?? 'g';
    final precioUnitarioCtrl =
        TextEditingController(text: insumo?.precio.toString() ?? '');

    final guardado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void calcularCosto() {
              final precioTotal = double.tryParse(precioTotalCtrl.text) ?? 0.0;
              final cantidadTotal =
                  double.tryParse(cantidadCompradaCtrl.text) ?? 0.0;
              if (cantidadTotal > 0) {
                setDialogState(() {
                  final costoCalculado = precioTotal / cantidadTotal;
                  precioUnitarioCtrl.text = costoCalculado.toStringAsFixed(2);
                });
              }
            }

            return AlertDialog(
              backgroundColor: kColorBackground1.withOpacity(0.95),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(esNuevo ? 'Nuevo Insumo' : 'Actualizar Insumo',
                  style: const TextStyle(
                      color: kColorPrimary, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nombreCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Nombre del Insumo',
                          prefixIcon: Icon(Icons.label_outline,
                              color: kColorPrimary)),
                    ),
                    const SizedBox(height: 24),
                    Text('Calcular Costo por Unidad (Opcional)',
                        style: TextStyle(color: kColorTextDark.withOpacity(0.8))),
                    const Divider(color: kColorPrimary, thickness: 0.5),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: precioTotalCtrl,
                            onChanged: (_) => calcularCosto(),
                            decoration: const InputDecoration(
                                labelText: 'Precio Paquete', prefixText: '\$ '),
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: cantidadCompradaCtrl,
                            onChanged: (_) => calcularCosto(),
                            decoration:
                                const InputDecoration(labelText: 'Cantidad Total'),
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: unidadSeleccionada,
                      decoration: const InputDecoration(
                          labelText: 'Unidad de Medida',
                          prefixIcon: Icon(Icons.straighten_outlined,
                              color: kColorPrimary)),
                      items: const [
                        DropdownMenuItem(
                            value: 'g', child: Text('Gramos (g)')),
                        DropdownMenuItem(
                            value: 'ml', child: Text('Mililitros (ml)')),
                        DropdownMenuItem(
                            value: 'unidad', child: Text('Unidad (u)')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => unidadSeleccionada = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: precioUnitarioCtrl,
                      decoration: InputDecoration(
                        labelText:
                            'Costo Final por Unidad (\$ / $unidadSeleccionada)',
                        prefixIcon: const Icon(Icons.monetization_on_outlined,
                            color: kColorPrimary),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancelar',
                        style: TextStyle(color: kColorTextDark.withOpacity(0.7)))),
                ElevatedButton(
                  onPressed: () async {
                    final nombre = nombreCtrl.text.trim();
                    final precioFinal =
                        double.tryParse(precioUnitarioCtrl.text) ?? 0.0;

                    if (nombre.isNotEmpty && precioFinal > 0) {
                      final nuevoInsumo = Insumo(
                        id: insumo?.id,
                        nombre: nombre,
                        precio: precioFinal,
                        unidad: unidadSeleccionada,
                      );
                      

                      if (esNuevo) {
                        await AppDatabase.insertarInsumo(nuevoInsumo);
                      } else {
                        await AppDatabase.actualizarInsumo(nuevoInsumo);
                      }
                      Navigator.pop(context, true);
                    }
                  },
                  child: const Text('Guardar'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kColorPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                ),
              ],
            );
          },
        );
      },
    );

    if (guardado == true) {
      _cargarInsumos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoInsumo(),
        backgroundColor: kColorPrimary,
        child: const Icon(Icons.add, color: Colors.white),
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
                        const Expanded(
                          child: Text(
                            'Gestión de Insumos',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: _cargarInsumos,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _insumos.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _cargarInsumos,
                      color: kColorPrimary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: _insumos.length,
                        itemBuilder: (context, index) {
                          final insumo = _insumos[index];
                          return _buildInsumoCard(insumo);
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
          Icon(Icons.inventory_2_outlined, size: 80, color: kColorPrimary.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text('No hay insumos', style: TextStyle(fontSize: 24, color: kColorTextDark)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'Agrega tu materia prima tocando el botón "+".',
              textAlign: TextAlign.center,
              style: TextStyle(color: kColorTextDark.withOpacity(0.7), fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInsumoCard(Insumo insumo) {
    return AcrylicCard(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: kColorPrimary,
          child: Icon(Icons.blender_outlined, color: Colors.white),
        ),
        title: Text(insumo.nombre, style: const TextStyle(fontWeight: FontWeight.bold, color: kColorTextDark)),
        subtitle: Text('Costo: ${insumo.precio.aPesos()} / ${insumo.unidad}', style: TextStyle(color: kColorTextDark.withOpacity(0.7))),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: kColorTextDark),
              onPressed: () => _mostrarDialogoInsumo(insumo: insumo),
              tooltip: 'Editar Costo',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _eliminarInsumo(insumo),
              tooltip: 'Eliminar Insumo',
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