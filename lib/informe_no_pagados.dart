import 'widgets/acrylic_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database.dart';
import 'registrar_pedido.dart';
import 'dart:ui';
import 'util/app_colors.dart';
import 'package:postres_app/pedido.dart';



class InformeNoPagadosPage extends StatefulWidget {
  const InformeNoPagadosPage({super.key});

  @override
  State<InformeNoPagadosPage> createState() => _InformeNoPagadosPageState();
}

class _InformeNoPagadosPageState extends State<InformeNoPagadosPage> {
  List<Map<String, dynamic>> clientes = [];
  List<Map<String, dynamic>> clientesFiltrados = [];
  double _deudaTotalGeneral = 0.0;
  final searchController = TextEditingController();

  final formatoPesos = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filtrarClientes);
    _cargarClientes();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarClientes() async {
    final data = await AppDatabase.obtenerClientesDeudores();
    double deudaGeneral = 0;

    final clientesConDeuda = <Map<String, dynamic>>[];
    for (var clienteNombre in data) {
      final pedidos = await AppDatabase.obtenerPedidosNoPagadosPorCliente(clienteNombre);
      final deudaCliente = pedidos.fold<double>(0.0, (sum, p) => sum + p.totalPendiente);

      if (deudaCliente > 0) {
        clientesConDeuda.add({'cliente': clienteNombre, 'deuda': deudaCliente});
        deudaGeneral += deudaCliente;
      }
    }

    if (!mounted) return;
    setState(() {
      clientes = clientesConDeuda..sort((a, b) => (b['deuda'] as double).compareTo(a['deuda']));
      clientesFiltrados = List.from(clientes);
      _deudaTotalGeneral = deudaGeneral;
    });
  }

  void _filtrarClientes() {
    final query = searchController.text.toLowerCase();
    setState(() {
      clientesFiltrados =
          clientes.where((c) => (c['cliente'] as String).toLowerCase().contains(query)).toList();
    });
  }

  Future<void> _liquidarCliente(String cliente) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kColorBackground1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Confirmar Liquidación", style: TextStyle(color: kColorPrimary)),
        content: Text("¿Estás seguro de marcar todos los pedidos de $cliente como pagados?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancelar", style: TextStyle(color: kColorTextDark.withOpacity(0.7)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sí, liquidar"),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await AppDatabase.liquidarCliente(cliente);
      await _cargarClientes();
    }
  }

  Future<List<Map<String, dynamic>>> _obtenerPedidosCliente(String cliente) async {
    final pedidos = await AppDatabase.obtenerPedidosNoPagadosPorCliente(cliente);
    return Future.wait(pedidos.map((p) async {
      String nombreTanda = '';
      if (p.tandaId != 0) {
        final tanda = await AppDatabase.obtenerTandasConConteo();
        final match = tanda.firstWhere((t) => t['id'] == p.tandaId, orElse: () => {'nombre': 'Desconocida'});
        nombreTanda = match['nombre'] as String;
      }
      return {
        'objetoPedido': p,
        'tandaId': p.tandaId,
        'tanda': nombreTanda,
        'pendiente': p.totalPendiente,
        'detalles': p.detalles
            .map((d) => {'producto': d.producto.nombre, 'cantidad': d.cantidad, 'subtotal': d.subtotal})
            .toList(),
      };
    }).toList());
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
            _buildHeader(),
            _buildResumenGeneral(),
            Expanded(
              child: clientesFiltrados.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _cargarClientes,
                      color: kColorPrimary,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 20),
                        itemCount: clientesFiltrados.length,
                        itemBuilder: (context, i) {
                          final clienteData = clientesFiltrados[i];
                          return _buildClienteCard(clienteData);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, bottom: 16),
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
                const Expanded(
                  child: Text(
                    "Informe de Deudas",
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _cargarClientes,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar cliente...',
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
        ],
      ),
    );
  }

  Widget _buildResumenGeneral() {
    return AcrylicCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent.shade200),
            const SizedBox(width: 12),
            const Expanded(
                child: Text("Deuda Total Pendiente",
                    style: TextStyle(fontWeight: FontWeight.bold, color: kColorTextDark))),
            Text(
              formatoPesos.format(_deudaTotalGeneral),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red.shade700),
            )
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
          Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.teal.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('¡Felicidades!',
              style: TextStyle(fontSize: 24, color: kColorTextDark)),
          const SizedBox(height: 8),
          Text('No hay clientes con deudas pendientes. 🎉',
              style: TextStyle(color: kColorTextDark.withOpacity(0.7), fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildClienteCard(Map<String, dynamic> clienteData) {
    final cliente = clienteData['cliente'] as String;
    final deuda = clienteData['deuda'] as double;
    return AcrylicCard(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: kColorPrimary.withOpacity(0.1),
          child: Text(
            cliente.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: kColorPrimary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(cliente, style: const TextStyle(color: kColorTextDark, fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text("Deuda total: ${formatoPesos.format(deuda)}",
            style: const TextStyle(color: Colors.redAccent)),
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _obtenerPedidosCliente(cliente),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(color: kColorPrimary,)));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("No se encontraron pedidos pendientes.", style: TextStyle(color: kColorTextDark)));
              }
              final pedidos = snapshot.data!;
              return Column(
                children: [
                  ...pedidos.map((pedido) => _buildPedidoItem(pedido)).toList(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text("Liquidar Deuda del Cliente"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                      onPressed: () => _liquidarCliente(cliente),
                    ),
                  )
                ],
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildPedidoItem(Map<String, dynamic> pedido) {
  final detalles = pedido['detalles'] as List<Map<String, dynamic>>;

  final objetoPedido = pedido['objetoPedido'] as Pedido;

  final fechaFormateada = DateFormat('dd MMM yyyy, hh:mm a', 'es_CO').format(objetoPedido.fecha);

  return ListTile(
    title: Text(
      "Tanda: ${pedido['tanda']}",
      style: const TextStyle(fontWeight: FontWeight.bold, color: kColorTextDark),
    ),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text("Fecha: $fechaFormateada", style: const TextStyle(color: kColorTextDark)),
        Text("Pendiente: ${formatoPesos.format(pedido['pendiente'])}", style: const TextStyle(color: kColorTextDark)),
        ...detalles.map((d) => Text("• ${d['cantidad']}x ${d['producto']}", style: TextStyle(color: kColorTextDark.withOpacity(0.7)))),
      ],
    ),
    trailing: IconButton(
      icon: const Icon(Icons.edit_outlined, color: kColorTextDark),
      tooltip: "Editar Pedido",
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RegistrarPedidoPage(
              pedidoEditar: pedido['objetoPedido'],
              tandaId: pedido['tandaId'],
            ),
          ),
        );
        await _cargarClientes();
      },
    ),
    isThreeLine: true,
  );
}
}


