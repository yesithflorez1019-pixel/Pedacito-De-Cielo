// lib/ver_productos.dart
import 'package:flutter/material.dart';
import 'producto.dart';
import 'database.dart';
import 'agregar_producto.dart';
import 'formato.dart';
import 'producto_detalle_page.dart';
import 'util/app_colors.dart';
import 'package:postres_app/widgets/acrylic_card.dart';
class VerProductosPage extends StatefulWidget {
  final bool esSubPagina;

  const VerProductosPage({super.key, this.esSubPagina = false});

  @override
  State<VerProductosPage> createState() => _VerProductosPageState();
}

class _VerProductosPageState extends State<VerProductosPage> {
  List<Map<String, dynamic>> productosConCosto = [];

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    productosConCosto = await AppDatabase.obtenerProductosConCosto();
    if (mounted) setState(() {});
  }

  void navegarADetalle(Producto p) async {
    final bool? huboCambios = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProductoDetallePage(producto: p)),
    );

    if (huboCambios == true) {
      await cargar();
    }
  }

  void _navegarAFormulario({Producto? producto}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AgregarProductoPage(productoExistente: producto)),
    );
    await cargar();
  }
  
  Future<void> _eliminarProducto(int id) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kColorBackground1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar Producto?', style: TextStyle(color: kColorPrimary)),
        content: const Text('Esta acción no se puede deshacer. ¿Estás seguro?', style: TextStyle(color: kColorTextDark)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: kColorTextDark.withOpacity(0.7))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    
    if (confirmacion == true) {

      await AppDatabase.eliminarProductoPorId(id);
      await cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navegarAFormulario(),
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.esSubPagina)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            'Rentabilidad',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            textAlign: widget.esSubPagina ? TextAlign.center : TextAlign.start,
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
              child: productosConCosto.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: cargar,
                      color: kColorPrimary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: productosConCosto.length,
                        itemBuilder: (_, i) {
                          final data = productosConCosto[i];
                          final producto = Producto.fromMap(data);
                          return _buildProductCard(producto, data);
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
          Icon(Icons.cake_outlined, size: 80, color: kColorPrimary.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text(
            '¡Aún no tienes productos!',
            style: TextStyle(fontSize: 24, color: kColorTextDark),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'Toca el botón "+" para agregar el primero y ver su rentabilidad.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kColorTextDark.withOpacity(0.7), fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Producto producto, Map<String, dynamic> data) {
    final costo = (data['costo'] as num?)?.toDouble() ?? 0.0;
    final ganancia = producto.precio - costo;
    final Color gananciaColor = ganancia >= 0 ? Colors.teal : Colors.redAccent;

    return AcrylicCard(
      child: InkWell(
        onTap: () => navegarADetalle(producto),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: kColorPrimary.withOpacity(0.1),
                child: const Icon(Icons.cake_outlined, color: kColorPrimary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kColorTextDark),
                    ),
                    Text(
                      'Venta: ${producto.precio.aPesos()} • Costo: ${costo.aPesos()}',
                      style: TextStyle(color: kColorTextDark.withOpacity(0.7), fontSize: 13),
                    ),
                    Text(
                      'Ganancia: ${ganancia.aPesos()}',
                      style: TextStyle(color: gananciaColor, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 40,
                    child: IconButton(
                      icon: const Icon(Icons.edit_outlined, color: kColorTextDark, size: 22),
                      onPressed: () => _navegarAFormulario(producto: producto),
                      tooltip: 'Editar',
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                      onPressed: () => _eliminarProducto(producto.id!),
                      tooltip: 'Eliminar',
                    ),
                  ),
                ],
              ),
            ],
          ),
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