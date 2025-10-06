// lib/ver_pedidos_desde_bd.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:postres_app/formato.dart';
import 'package:postres_app/pedido.dart';
import 'package:postres_app/registrar_pedido.dart';
import 'package:postres_app/database.dart';
import 'package:postres_app/util/app_colors.dart';
import 'package:intl/intl.dart';
import 'widgets/acrylic_card.dart';

class VerPedidosDesdeBDPage extends StatefulWidget {
  final int tandaId;
  final String nombreTanda;

  const VerPedidosDesdeBDPage({
    super.key,
    required this.tandaId,
    required this.nombreTanda,
  });

  @override
  State<VerPedidosDesdeBDPage> createState() => _VerPedidosDesdeBDPageState();
}

class _VerPedidosDesdeBDPageState extends State<VerPedidosDesdeBDPage> {
  List<Pedido> listaPedidos = [];
  List<Pedido> pedidosFiltrados = [];

  String filtroBusqueda = '';
  int filtroPagado = -1;
  int filtroEntregado = -1;

  @override
  void initState() {
    super.initState();
    cargarPedidos();
  }

  Future<void> cargarPedidos() async {
    final pedidos = await AppDatabase.obtenerPedidos(tandaId: widget.tandaId);
    if (!mounted) return;
    setState(() {
      listaPedidos = pedidos..sort((a, b) => a.cliente.compareTo(b.cliente));
      aplicarFiltros();
    });
  }

  void aplicarFiltros() {
    setState(() {
      pedidosFiltrados = listaPedidos.where((pedido) {
        final coincideBusqueda = filtroBusqueda.isEmpty ||
            pedido.cliente.toLowerCase().contains(filtroBusqueda.toLowerCase()) ||
            pedido.detalles.any((d) => d.producto.nombre.toLowerCase().contains(filtroBusqueda.toLowerCase()));

        final coincidePagado = (filtroPagado == -1) || (filtroPagado == 1 && pedido.pagado) || (filtroPagado == 0 && !pedido.pagado);
        final coincideEntregado = (filtroEntregado == -1) || (filtroEntregado == 1 && pedido.entregado) || (filtroEntregado == 0 && !pedido.entregado);

        return coincideBusqueda && coincidePagado && coincideEntregado;
      }).toList();
    });
  }

  void editarPedido(Pedido pedido) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegistrarPedidoPage(
          tandaId: widget.tandaId,
          pedidoEditar: pedido,
        ),
      ),
    );
    cargarPedidos();
  }
  
  Future<void> eliminarPedido(int id) async {

    await AppDatabase.eliminarPedidoPorId(id);
    await cargarPedidos();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pedido eliminado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Pedido'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RegistrarPedidoPage(tandaId: widget.tandaId),
            ),
          );
          cargarPedidos();
        },
        backgroundColor: kColorPrimary,
        foregroundColor: Colors.white,
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
            _buildHeaderConFiltros(),
            Expanded(
              child: pedidosFiltrados.isEmpty
                  ? const Center(child: Text('No hay pedidos que coincidan', style: TextStyle(color: kColorTextDark)))
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 90),
                      itemCount: pedidosFiltrados.length,
                      itemBuilder: (context, index) {
                        final pedido = pedidosFiltrados[index];
                        return _buildPedidoCard(pedido);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderConFiltros() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kColorHeader1, kColorHeader2],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    widget.nombreTanda,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: cargarPedidos,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  filtroBusqueda = value;
                  aplicarFiltros();
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar por cliente o producto...',
                hintStyle: TextStyle(color: kColorTextDark.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, color: kColorTextDark, size: 20),
                filled: true,
                fillColor: Colors.white.withOpacity(0.3),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: kColorTextDark),
            ),
          ),
          _buildFilterSection(),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          _BuildFilterChips(
            selectedValue: filtroPagado,
            labels: const ["No Pagados", "Pagados"],
            onSelected: (newIndex) {
              setState(() => filtroPagado = newIndex);
              aplicarFiltros();
            },
          ),
          _BuildFilterChips(
            selectedValue: filtroEntregado,
            labels: const ["No Entregados", "Entregados"],
            onSelected: (newIndex) {
              setState(() => filtroEntregado = newIndex);
              aplicarFiltros();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPedidoCard(Pedido pedido) {

  final fechaFormateada = DateFormat('dd MMM yyyy, hh:mm a', 'es_CO').format(pedido.fecha);

  return AcrylicCard(
    child: ExpansionTile(
      title: Text(pedido.cliente, style: const TextStyle(fontWeight: FontWeight.bold, color: kColorTextDark, fontSize: 18)),

      subtitle: Text('Fecha: $fechaFormateada', style: TextStyle(color: kColorTextDark.withOpacity(0.7))),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: kColorTextDark),
            onPressed: () => editarPedido(pedido),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () async {
              final confirmacion = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: kColorBackground1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('¿Eliminar pedido?', style: TextStyle(color: kColorPrimary)),
                  content: const Text('Esta acción no se puede deshacer.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancelar', style: TextStyle(color: kColorTextDark.withOpacity(0.7))),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Eliminar'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                    ),
                  ],
                ),
              );
              if (confirmacion == true) {
                eliminarPedido(pedido.id!);
              }
            },
          ),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(top: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(Icons.location_on_outlined, pedido.direccion),
              const Divider(height: 16),
              _buildInfoRow(Icons.payment_outlined, 'Abono: ${pedido.pagoParcialFormateado}'),
              _buildInfoRow(Icons.error_outline, 'Debe: ${pedido.restanteFormateado}', color: pedido.totalPendiente > 0 ? Colors.red.shade700 : Colors.teal),
              const Divider(height: 20),
              const Text('Detalles del Pedido:', style: TextStyle(fontWeight: FontWeight.bold, color: kColorTextDark)),
              ...pedido.detalles.map((detalle) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text('• ${detalle.cantidad}x ${detalle.producto.nombre} (${detalle.subtotal.aPesos()})', style: const TextStyle(color: kColorTextDark)),
              )),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatusChip(icon: Icons.check_circle, label: pedido.pagado ? 'Pagado' : 'Pendiente', color: pedido.pagado ? Colors.teal : Colors.grey),
                  const SizedBox(width: 8),
                  _buildStatusChip(icon: Icons.local_shipping, label: pedido.entregado ? 'Entregado' : 'No Entregado', color: pedido.entregado ? Colors.blue.shade400 : Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(icon, color: kColorTextDark.withOpacity(0.7), size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color ?? kColorTextDark, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildStatusChip({required IconData icon, required String label, required Color color}) {
    return Chip(
      avatar: Icon(icon, color: color, size: 16),
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _BuildFilterChips extends StatelessWidget {
  final int selectedValue;
  final List<String> labels;
  final ValueChanged<int> onSelected;

  const _BuildFilterChips({
    required this.selectedValue,
    required this.labels,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildChip(context, 'Todos', -1),
          const SizedBox(width: 8),
          _buildChip(context, labels[0], 0),
          const SizedBox(width: 8),
          _buildChip(context, labels[1], 1),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, int index) {
    final bool isSelected = selectedValue == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(index),
      selectedColor: Colors.white,
      backgroundColor: Colors.white.withOpacity(0.3),
      labelStyle: TextStyle(color: isSelected ? kColorPrimary : const Color.fromARGB(255, 62, 62, 62), fontWeight: FontWeight.bold),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
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