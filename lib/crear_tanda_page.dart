// lib/crear_tanda_page.dart
import 'package:flutter/material.dart';
import 'package:postres_app/database.dart';
import 'package:postres_app/producto.dart';
import 'package:postres_app/tanda.dart';
import 'dart:ui';
import 'util/app_colors.dart';
import 'package:postres_app/widgets/acrylic_card.dart';

class CrearTandaPage extends StatefulWidget {
  final Tanda? tandaExistente;
  const CrearTandaPage({super.key, this.tandaExistente});

  @override
  State<CrearTandaPage> createState() => _CrearTandaPageState();
}

class _CrearTandaPageState extends State<CrearTandaPage> {
  final _nombreTandaCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Producto> _todosLosProductos = [];
  List<Producto> _productosFiltrados = [];
  Map<int, int> _productosSeleccionados = {};
  final Map<int, TextEditingController> _stockControllers = {};

  @override
  void initState() {
    super.initState();
    _cargarProductos();
    _searchCtrl.addListener(_filtrarProductos);

    if (widget.tandaExistente != null) {
      _nombreTandaCtrl.text = widget.tandaExistente!.nombre;
      _cargarDatosTanda();
    }
  }

  @override
  void dispose() {
    _nombreTandaCtrl.dispose();
    _searchCtrl.dispose();
    _stockControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _cargarProductos() async {
    _todosLosProductos = await AppDatabase.obtenerProductos();
    setState(() {
      _productosFiltrados = _todosLosProductos;
    });
  }

  Future<void> _cargarDatosTanda() async {
    if (widget.tandaExistente?.id == null) return;
    
    final productosTanda = await AppDatabase.obtenerProductosDeTanda(widget.tandaExistente!.id!);

    setState(() {
      _productosSeleccionados.clear();
      _stockControllers.clear();

      for (var p in productosTanda) {
        final productoId = p['productoId'] as int;
        final stockActual = p['stock'] as int;
        
        _productosSeleccionados[productoId] = stockActual;
        _stockControllers[productoId] = TextEditingController(text: stockActual.toString());
      }
    });
  }

  void _filtrarProductos() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _productosFiltrados = _todosLosProductos
          .where((p) => p.nombre.toLowerCase().contains(query))
          .toList();
    });
  }

  void _onProductoSeleccionado(Producto producto) {
    setState(() {
      if (_productosSeleccionados.containsKey(producto.id)) {
        _productosSeleccionados.remove(producto.id);
        _stockControllers.remove(producto.id)?.dispose();
      } else {
        _productosSeleccionados[producto.id!] = 1;
        _stockControllers[producto.id!] = TextEditingController(text: '1');
      }
    });
  }

  void _actualizarStock(int productoId, String stockStr) {
    final stock = int.tryParse(stockStr) ?? 0;
    _productosSeleccionados[productoId] = stock;
  }

Future<void> _guardarTanda() async {
  if (!_formKey.currentState!.validate()) return;

  final nombreTanda = _nombreTandaCtrl.text.trim();
  if (nombreTanda.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa un nombre para la tanda.')));
    return;
  }

  final esNombreDiferente = widget.tandaExistente == null || widget.tandaExistente!.nombre.toLowerCase() != nombreTanda.toLowerCase();

  if (esNombreDiferente) {
    final bool yaExiste = await AppDatabase.existeTandaConNombre(nombreTanda);
    if (yaExiste) {
      if (!mounted) return;
     
      _mostrarAlertaDuplicado(); 
      return; 
    }
  }

  final productosAGuardar = Map.of(_productosSeleccionados)
      ..removeWhere((key, value) => value <= 0);

  if (productosAGuardar.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos un producto con stock.')));
    return;
  }

  if (widget.tandaExistente == null) {
    final nuevaTanda = Tanda(nombre: nombreTanda);
    final tandaId = await AppDatabase.insertarTanda(nuevaTanda);
    await AppDatabase.addProductosToTanda(tandaId, productosAGuardar);
  } else {
    final tandaId = widget.tandaExistente!.id!;
    final tandaActualizada = Tanda(id: tandaId, nombre: nombreTanda);
    await AppDatabase.actualizarTanda(tandaActualizada);
    await AppDatabase.actualizarProductosDeTanda(tandaId, productosAGuardar);
  }

  if (mounted) Navigator.pop(context, true);
}

  @override
  Widget build(BuildContext context) {
    final bool esEdicion = widget.tandaExistente != null;
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
                        esEdicion ? "Editar Tanda" : "Nueva Tanda",
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.save_outlined, color: Colors.white),
                      onPressed: _guardarTanda,
                      tooltip: 'Guardar Tanda',
                    )
                  ],
                ),
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildNombreYBusquedaCard(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Toca para seleccionar productos'),
                    _buildSelectorHorizontal(),
                    const Divider(height: 32),
                    _buildSectionTitle('Resumen y Stock de la Tanda'),
                    _buildResumenList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNombreYBusquedaCard() {
    return AcrylicCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _nombreTandaCtrl,
              decoration: const InputDecoration(labelText: 'Nombre de la tanda', prefixIcon: Icon(Icons.label_outline, color: kColorPrimary)),
              validator: (v) => v!.isEmpty ? 'El nombre es requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _searchCtrl,
              decoration: const InputDecoration(labelText: 'Buscar producto', prefixIcon: Icon(Icons.search, color: kColorPrimary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorHorizontal() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _productosFiltrados.length,
        itemBuilder: (context, index) {
          final producto = _productosFiltrados[index];
          final isSelected = _productosSeleccionados.containsKey(producto.id);
          return _ProductoSelectorCard(
            producto: producto,
            isSelected: isSelected,
            onTap: () => _onProductoSeleccionado(producto),
          );
        },
      ),
    );
  }

  Widget _buildResumenList() {
    final productosEnResumen = _todosLosProductos
        .where((p) => _productosSeleccionados.containsKey(p.id))
        .toList();

    if (productosEnResumen.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Selecciona productos de la lista de arriba.', style: TextStyle(color: kColorTextDark, fontSize: 16)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: productosEnResumen.length,
      itemBuilder: (context, index) {
        final producto = productosEnResumen[index];
        return AcrylicCard(
          child:Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
            children: [
              const Icon(Icons.cake_outlined, color: kColorPrimary),
              const SizedBox(width: 16),
              Expanded(child: Text(producto.nombre, style: const TextStyle(color: kColorTextDark, fontWeight: FontWeight.bold))),
              const Text('Stock:', style: TextStyle(color: kColorTextDark)),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: TextFormField(
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  controller: _stockControllers[producto.id!],
                  onChanged: (value) => _actualizarStock(producto.id!, value),
                  decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(8)),
                ),
              ),
            ],
          ),
        ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
      child: Text(title, style: TextStyle(fontSize: 16, color: kColorTextDark.withOpacity(0.8))),
    );
  }

void _mostrarAlertaDuplicado() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color(0xFFFCF2F2), // Un fondo rosado muy suave
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.pink.shade100, width: 2),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.pink.shade300, size: 28),
            const SizedBox(width: 10),
            const Text('Nombre Repetido', style: TextStyle(color: kColorPrimary)),
          ],
        ),
        content: const Text(
          'Ya existe una tanda con este nombre. Por favor, elige uno diferente.',
          style: TextStyle(color: kColorTextDark),
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: kColorPrimary.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Entendido', style: TextStyle(color: kColorPrimary, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

}



class _ProductoSelectorCard extends StatelessWidget {
  final Producto producto;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProductoSelectorCard({required this.producto, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isSelected ? 8 : 2,
        color: isSelected ? kColorPrimary.withOpacity(0.8) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        child: Container(
          width: 110,
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    producto.nombre,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : kColorTextDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Icon(
                isSelected ? Icons.check_circle : Icons.add_circle_outline,
                color: isSelected ? Colors.white : kColorPrimary,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}