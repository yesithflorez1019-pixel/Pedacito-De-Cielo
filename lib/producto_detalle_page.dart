// lib/producto_detalle_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'database.dart';
import 'formato.dart';
import 'insumo.dart';
import 'producto.dart';
import 'util/app_colors.dart';
import 'widgets/acrylic_card.dart';

class FacturaFoto {
  int? id;
  String nombre;
  final String path;

  FacturaFoto({this.id, required this.nombre, required this.path});
}

class _FotoViewerPage extends StatelessWidget {
  final FacturaFoto factura;
  const _FotoViewerPage({required this.factura});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(factura.nombre),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 1.0,
          maxScale: 4.0,
          child: Image.file(File(factura.path)),
        ),
      ),
    );
  }
}

class ProductoDetallePage extends StatefulWidget {
  final Producto producto;
  const ProductoDetallePage({super.key, required this.producto});

  @override
  State<ProductoDetallePage> createState() => _ProductoDetallePageState();
}

class _ProductoDetallePageState extends State<ProductoDetallePage> {
  late Producto _productoActual;
  List<Map<String, dynamic>> _insumosAsignados = [];
  double _costoTotalTanda = 0.0;
  late TextEditingController _rendimientoCtrl;

  List<FacturaFoto> _facturas = [];

  @override
  void initState() {
    super.initState();
    _productoActual = widget.producto;
    _rendimientoCtrl = TextEditingController(text: _productoActual.rendimientoTanda.toString());
    _rendimientoCtrl.addListener(() => setState(() {}));
    _cargarDatos();
  }

  @override
  void dispose() {
    _rendimientoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    await _cargarInsumos();
    await _cargarFacturas();
  }

  Future<void> _cargarInsumos() async {
    final data = await AppDatabase.obtenerInsumosDeProducto(_productoActual.id!);
    double costoCalculado = 0;
    for (var insumo in data) {
      final precio = (insumo['precio'] as num?)?.toDouble() ?? 0.0;
      final cantidad = (insumo['cantidad'] as num?)?.toDouble() ?? 0.0;
      costoCalculado += precio * cantidad;
    }
    if (!mounted) return;
    setState(() {
      _insumosAsignados = data;
      _costoTotalTanda = costoCalculado;
    });
  }

  Future<void> _cargarFacturas() async {
    final lista = await AppDatabase.obtenerFacturasDeProducto(_productoActual.id!);
    if (!mounted) return;
    setState(() {
      _facturas = lista
          .map((map) => FacturaFoto(
                id: map['id'] as int,
                nombre: map['nombre'] as String,
                path: map['path'] as String,
              ))
          .toList();
    });
  }


  Future<void> _eliminarInsumoDeReceta(Map<String, dynamic> insumo) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kColorBackground1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmar', style: TextStyle(color: kColorPrimary)),
        content: Text('¿Seguro que quieres quitar "${insumo['nombre']}" de la receta?', style: const TextStyle(color: kColorTextDark)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: kColorTextDark.withOpacity(0.7))),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Sí, Quitar'),
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
      await AppDatabase.eliminarProductoInsumo(_productoActual.id!, insumo['id']);
      _cargarInsumos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return true;
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kColorBackground1, kColorBackground2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: DefaultTabController(
            length: 2,
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
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                      ]),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0, right: 16.0),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                              onPressed: () => Navigator.pop(context, true),
                            ),
                            Expanded(
                              child: Text(
                                _productoActual.nombre,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const TabBar(
                        indicatorColor: Colors.white,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        indicatorWeight: 2.5,
                        tabs: [
                          Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Receta'),
                          Tab(icon: Icon(Icons.photo_library_outlined), text: 'Facturas'),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildRecetaView(),
                      _buildFacturasView(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecetaView() {
    final rendimiento = int.tryParse(_rendimientoCtrl.text) ?? 1;
    final costoPorUnidad = (rendimiento > 0) ? _costoTotalTanda / rendimiento : 0.0;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 90),
          children: [
            AcrylicCard(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    _buildInfoRow(
                        "Costo Tanda:",
                        _costoTotalTanda.aPesos(),
                        const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16, color: kColorTextDark)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _rendimientoCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: kColorTextDark),
                      decoration: InputDecoration(
                        labelText: 'Rendimiento (unidades)',
                        prefixIcon: const Icon(Icons.bakery_dining_outlined, color: kColorPrimary),
                        fillColor: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    const Divider(height: 30, color: kColorPrimary, indent: 20, endIndent: 20),
                    _buildInfoRow(
                        "Costo por Unidad:",
                        costoPorUnidad.aPesos(),
                        Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: kColorPrimary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save_outlined),
                        onPressed: _guardarRendimiento,
                        label: const Text('Guardar Rendimiento'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kColorPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            ..._insumosAsignados.map((insumo) {
              return AcrylicCard(
                child: ListTile(
                  leading: const Icon(Icons.blender_outlined, color: kColorPrimary),
                  title: Text(insumo['nombre'],
                      style: const TextStyle(fontWeight: FontWeight.w600, color: kColorTextDark)),
                  subtitle: Text('${insumo['cantidad']} ${insumo['unidad']}',
                      style: TextStyle(color: kColorTextDark.withOpacity(0.7))),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _eliminarInsumoDeReceta(insumo), // <-- CÓDIGO ACTUALIZADO
                  ),
                ),
              );
            }),
          ],
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: _mostrarDialogoAgregarInsumo,
            label: const Text('Añadir'),
            icon: const Icon(Icons.add),
            backgroundColor: kColorPrimary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, TextStyle? style) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                Theme.of(context).textTheme.titleMedium?.copyWith(color: kColorTextDark.withOpacity(0.7))),
        Text(value, style: style)
      ],
    );
  }

  Future<void> _guardarRendimiento() async {
    final nuevoRendimiento = int.tryParse(_rendimientoCtrl.text) ?? 1;
    final productoActualizado = _productoActual.copyWith(rendimientoTanda: nuevoRendimiento);
    await AppDatabase.actualizarProducto(productoActualizado);
    setState(() => _productoActual = productoActualizado);
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Rendimiento guardado.'),
      backgroundColor: kColorPrimary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(12),
    ));
  }

  Future<void> _mostrarDialogoAgregarInsumo() async {
    final todosLosInsumos = await AppDatabase.getInsumos();
    
    final Insumo? insumoSeleccionado = await showModalBottomSheet<Insumo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InsumoSearchSheet(todosLosInsumos: todosLosInsumos),
    );

    if (insumoSeleccionado != null) {
      final bool? guardado = await _mostrarDialogoCantidad(insumoSeleccionado);
      if (guardado == true) {
        _cargarInsumos();
      }
    }
  }

  Future<bool?> _mostrarDialogoCantidad(Insumo insumo) async {
    final cantidadCtrl = TextEditingController();
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kColorBackground1.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cantidad para ${insumo.nombre}', style: const TextStyle(color: kColorPrimary)),
        content: TextFormField(
          controller: cantidadCtrl,
          autofocus: true,
          decoration: InputDecoration(labelText: 'Cantidad (${insumo.unidad})'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: kColorTextDark.withOpacity(0.7))),
          ),
          ElevatedButton(
            onPressed: () async {
              final cantidad = double.tryParse(cantidadCtrl.text) ?? 0.0;
              if (cantidad > 0) {
                await AppDatabase.addInsumoToProducto(_productoActual.id!, insumo.id!, cantidad);
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: kColorPrimary, foregroundColor: Colors.white),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _buildFacturasView() {
    if (_facturas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 80, color: kColorPrimary.withOpacity(0.7)),
            const SizedBox(height: 16),
            const Text('Aún no has añadido facturas', style: TextStyle(color: kColorTextDark, fontSize: 16)),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Añadir la primera'),
              onPressed: _agregarFotoFactura,
              style: TextButton.styleFrom(foregroundColor: kColorPrimary),
            ),
          ],
        ),
      );
    }
    return Stack(
      children: [
        GridView.builder(
          padding: const EdgeInsets.all(12).copyWith(bottom: 90),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _facturas.length,
          itemBuilder: (_, index) {
            final factura = _facturas[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GridTile(
                footer: GridTileBar(
                  backgroundColor: kColorTextDark.withOpacity(0.7),
                  title: Text(factura.nombre, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.white),
                    // AQUÍ AÑADIMOS LA CONFIRMACIÓN
                    onPressed: () => _eliminarFactura(factura, index),
                  ),
                ),
                child: GestureDetector(
                  // AQUÍ AÑADIMOS EL GESTO PARA ABRIR LA FOTO
                  onTap: () => _verFactura(factura),
                  child: Image.file(File(factura.path), fit: BoxFit.cover),
                ),
              ),
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _agregarFotoFactura,
            backgroundColor: kColorPrimary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add_a_photo),
          ),
        ),
      ],
    );
  }

void _verFactura(FacturaFoto factura) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FotoViewerPage(factura: factura),
      ),
    );
  }

  Future<void> _agregarFotoFactura() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    final directory = await getApplicationDocumentsDirectory();
    final newPath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(pickedFile.path).copy(newPath);

    final nombreCtrl = TextEditingController();
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kColorBackground1.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Nombre de la factura", style: TextStyle(color: kColorPrimary)),
        content:
            TextFormField(controller: nombreCtrl, decoration: const InputDecoration(hintText: "Ej: El Panadero")),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancelar", style: TextStyle(color: kColorTextDark.withOpacity(0.7)))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: kColorPrimary, foregroundColor: Colors.white),
            child: const Text("Guardar"),
          ),
        ],
      ),
    );

    await AppDatabase.insertarFactura(
        _productoActual.id!, nombreCtrl.text.isNotEmpty ? nombreCtrl.text : "Sin nombre", newPath);
    await _cargarFacturas();
  }

 void _eliminarFactura(FacturaFoto factura, int index) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: kColorBackground1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Confirmar eliminación", style: TextStyle(color: kColorPrimary)),
              content: Text("¿Deseas eliminar la factura '${factura.nombre}'?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text("Cancelar", style: TextStyle(color: kColorTextDark.withOpacity(0.7)))),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                  child: const Text("Eliminar"),
                ),
              ],
            ));

    if (confirmed == true) {

      final file = File(factura.path);
      if (await file.exists()) {
        await file.delete();
      }

      await AppDatabase.eliminarFactura(factura.id!);
      await _cargarFacturas(); 
    }
  }



}



class InsumoSearchSheet extends StatefulWidget {
  final List<Insumo> todosLosInsumos;
  const InsumoSearchSheet({super.key, required this.todosLosInsumos});

  @override
  State<InsumoSearchSheet> createState() => _InsumoSearchSheetState();
}

class _InsumoSearchSheetState extends State<InsumoSearchSheet> {
  List<Insumo> _insumosFiltrados = [];
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _insumosFiltrados = widget.todosLosInsumos;
    _searchCtrl.addListener(_filtrar);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filtrar() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _insumosFiltrados = widget.todosLosInsumos
          .where((insumo) => insumo.nombre.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.75,
      minChildSize: 0.5,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: kColorBackground1,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Buscar Insumo...',
                    prefixIcon: const Icon(Icons.search, color: kColorPrimary),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _insumosFiltrados.length,
                  itemBuilder: (context, index) {
                    final insumo = _insumosFiltrados[index];
                    return ListTile(
                      leading: const Icon(Icons.blender_outlined, color: kColorPrimary),
                      title: Text(insumo.nombre, style: const TextStyle(color: kColorTextDark)),
                      onTap: () {
                        Navigator.pop(context, insumo);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}