import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database.dart';
import 'pedido.dart';
import 'producto.dart';
import 'registrar_pedido.dart';
import 'util/app_colors.dart';
import 'widgets/acrylic_card.dart';

// Enum para manejar los tipos de filtro y ordenamiento
enum DeudorSortOrder { porDeuda, porAntiguedad }

class InformeNoPagadosPage extends StatefulWidget {
  const InformeNoPagadosPage({super.key});

  @override
  State<InformeNoPagadosPage> createState() => _InformeNoPagadosPageState();
}

class _InformeNoPagadosPageState extends State<InformeNoPagadosPage> {
  // Estado para la lista de clientes completa y la filtrada
  List<Map<String, dynamic>> _clientesCompletos = [];
  List<Map<String, dynamic>> _clientesFiltrados = [];
  double _deudaTotalGeneral = 0.0;

  // Controladores y estado para los filtros
  final _searchController = TextEditingController();
  DeudorSortOrder _sortOrder = DeudorSortOrder.porDeuda;
  Producto? _productoSeleccionado;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  List<Producto> _listaDeProductos = [];
  bool _isLoading = true;

  final formatoPesos = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );
  
  // Formato para mostrar las fechas en la UI
  final formatoFecha = DateFormat('dd MMM, yyyy', 'es_CO');

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_aplicarFiltros);
    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Carga tanto los productos (para el dropdown) como los clientes deudores.
  Future<void> _cargarDatosIniciales() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final productos = await AppDatabase.obtenerTodosLosProductos();
    if (mounted) {
      setState(() {
        _listaDeProductos = productos;
      });
    }

    await _cargarClientes();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// Carga y procesa la información de todos los clientes con deudas.
  Future<void> _cargarClientes() async {
    final todosLosPedidosNoPagados = await AppDatabase.obtenerPedidos()
      ..retainWhere((p) => !p.pagado && p.totalPendiente > 0);

    final Map<String, dynamic> clientesMap = {};

    for (final pedido in todosLosPedidosNoPagados) {
      final clienteNombre = pedido.cliente;
      if (!clientesMap.containsKey(clienteNombre)) {
        clientesMap[clienteNombre] = {
          'cliente': clienteNombre,
          'deuda': 0.0,
          'pedidos': <Pedido>[],
          'fechaMasAntigua': pedido.fecha,
        };
      }
      clientesMap[clienteNombre]['deuda'] += pedido.totalPendiente;
      clientesMap[clienteNombre]['pedidos'].add(pedido);
      if (pedido.fecha.isBefore(clientesMap[clienteNombre]['fechaMasAntigua'])) {
        clientesMap[clienteNombre]['fechaMasAntigua'] = pedido.fecha;
      }
    }

    if (!mounted) return;
    setState(() {
      _clientesCompletos = List<Map<String, dynamic>>.from(clientesMap.values);
      _deudaTotalGeneral = _clientesCompletos.fold(0.0, (sum, c) => sum + c['deuda']);
      _aplicarFiltros();
    });
  }

  /// Aplica todos los filtros en cascada: fecha, producto, texto y ordenamiento.
  void _aplicarFiltros() {
    List<Map<String, dynamic>> resultado = List.from(_clientesCompletos);

    // 1. Filtro por RANGO DE FECHAS
    if (_fechaInicio != null && _fechaFin != null) {
      resultado = resultado.where((cliente) {
        final pedidos = cliente['pedidos'] as List<Pedido>;
        return pedidos.any((pedido) {
          final fechaPedido = pedido.fecha;
          // Normalizar fechas para comparar solo el día, sin la hora
          final fechaInicioDia = DateTime(_fechaInicio!.year, _fechaInicio!.month, _fechaInicio!.day);
          final fechaFinDia = DateTime(_fechaFin!.year, _fechaFin!.month, _fechaFin!.day, 23, 59, 59);
          return !fechaPedido.isBefore(fechaInicioDia) && !fechaPedido.isAfter(fechaFinDia);
        });
      }).toList();
    }
    
    // 2. Filtro por producto seleccionado
    if (_productoSeleccionado != null) {
      final productoId = _productoSeleccionado!.id;
      resultado = resultado.where((cliente) {
        final pedidos = cliente['pedidos'] as List<Pedido>;
        return pedidos.any((pedido) =>
            pedido.detalles.any((detalle) => detalle.producto.id == productoId));
      }).toList();
    }

    // 3. Filtro por texto de búsqueda
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      resultado = resultado
          .where((c) => (c['cliente'] as String).toLowerCase().contains(query))
          .toList();
    }

    // 4. Ordenamiento
    switch (_sortOrder) {
      case DeudorSortOrder.porDeuda:
        resultado.sort((a, b) => (b['deuda'] as double).compareTo(a['deuda']));
        break;
      case DeudorSortOrder.porAntiguedad:
        resultado.sort((a, b) =>
            (a['fechaMasAntigua'] as DateTime).compareTo(b['fechaMasAntigua']));
        break;
    }

    if (!mounted) return;
    setState(() {
      _clientesFiltrados = resultado;
    });
  }
  
  /// Muestra el selector de fechas.
  Future<void> _seleccionarFecha(BuildContext context, {required bool esFechaInicio}) async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: esFechaInicio ? (_fechaInicio ?? DateTime.now()) : (_fechaFin ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (fechaSeleccionada != null) {
      setState(() {
        if (esFechaInicio) {
          _fechaInicio = fechaSeleccionada;
          // Si no hay fecha de fin, se pone la misma que la de inicio
          _fechaFin ??= fechaSeleccionada;
        } else {
          _fechaFin = fechaSeleccionada;
        }
      });
      _aplicarFiltros();
    }
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
            _buildFiltrosUI(),
            _buildResumenGeneral(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: kColorPrimary))
                  : _clientesFiltrados.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _cargarClientes,
                          color: kColorPrimary,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(top: 8, bottom: 20),
                            itemCount: _clientesFiltrados.length,
                            itemBuilder: (context, i) {
                              final clienteData = _clientesFiltrados[i];
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
                  onPressed: _cargarDatosIniciales,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
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

  /// Widget que contiene todos los filtros
  Widget _buildFiltrosUI() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           // --- NUEVO FILTRO DE FECHA ---
          const Text("Filtrar por fecha de pedido:", style: TextStyle(fontWeight: FontWeight.bold, color: kColorTextDark)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _seleccionarFecha(context, esFechaInicio: true),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_fechaInicio != null ? formatoFecha.format(_fechaInicio!) : "Desde"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.7), foregroundColor: kColorTextDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _seleccionarFecha(context, esFechaInicio: false),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_fechaFin != null ? formatoFecha.format(_fechaFin!) : "Hasta"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.7), foregroundColor: kColorTextDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                ),
              ),
              if (_fechaInicio != null || _fechaFin != null)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.redAccent),
                  onPressed: () {
                    setState(() {
                      _fechaInicio = null;
                      _fechaFin = null;
                    });
                    _aplicarFiltros();
                  },
                  tooltip: "Limpiar filtro de fecha",
                ),
            ],
          ),
          const Divider(height: 24),
          // --- FILTROS ANTERIORES ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Ordenar por:", style: TextStyle(fontWeight: FontWeight.bold, color: kColorTextDark)),
              PopupMenuButton<DeudorSortOrder>(
                onSelected: (DeudorSortOrder result) {
                  setState(() {
                    _sortOrder = result;
                    _aplicarFiltros();
                  });
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<DeudorSortOrder>>[
                  const PopupMenuItem<DeudorSortOrder>(
                    value: DeudorSortOrder.porDeuda,
                    child: Text('Mayor Deuda'),
                  ),
                  const PopupMenuItem<DeudorSortOrder>(
                    value: DeudorSortOrder.porAntiguedad,
                    child: Text('Más Antiguos'),
                  ),
                ],
                child: Row(
                  children: [
                    Text(
                      _sortOrder == DeudorSortOrder.porDeuda ? 'Mayor Deuda' : 'Más Antiguos',
                      style: const TextStyle(color: kColorPrimary, fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.arrow_drop_down, color: kColorPrimary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<Producto>(
            value: _productoSeleccionado,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: "Filtrar por producto",
              prefixIcon: const Icon(Icons.cake_outlined, color: kColorPrimary),
              filled: true,
              fillColor: Colors.white.withOpacity(0.5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              suffixIcon: _productoSeleccionado != null ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  setState(() {
                    _productoSeleccionado = null;
                    _aplicarFiltros();
                  });
                },
              ) : null,
            ),
            items: _listaDeProductos.map<DropdownMenuItem<Producto>>((Producto producto) {
              return DropdownMenuItem<Producto>(
                value: producto,
                child: Text(producto.nombre, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (Producto? nuevoValor) {
              setState(() {
                _productoSeleccionado = nuevoValor;
                _aplicarFiltros();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResumenGeneral() {
    final double deudaFiltrada = _clientesFiltrados.fold(0.0, (sum, c) => sum + c['deuda']);
    return AcrylicCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.filter_list, color: Colors.blue.shade300),
                const SizedBox(width: 12),
                const Expanded(
                    child: Text("Deuda (Filtrada)",
                        style: TextStyle(fontWeight: FontWeight.bold, color: kColorTextDark))),
                Text(
                  formatoPesos.format(deudaFiltrada),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue.shade700),
                )
              ],
            ),
            const Divider(height: 12, thickness: 0.5),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.redAccent.shade200),
                const SizedBox(width: 12),
                const Expanded(
                    child: Text("Deuda Total General",
                        style: TextStyle(fontWeight: FontWeight.bold, color: kColorTextDark))),
                Text(
                  formatoPesos.format(_deudaTotalGeneral),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red.shade700),
                )
              ],
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
          Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.teal.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('¡Todo en orden!',
              style: TextStyle(fontSize: 24, color: kColorTextDark)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              _productoSeleccionado == null && _searchController.text.isEmpty && _fechaInicio == null
                  ? 'No hay clientes con deudas pendientes. 🎉'
                  : 'No se encontraron deudores que coincidan con los filtros.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kColorTextDark.withOpacity(0.7), fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildClienteCard(Map<String, dynamic> clienteData) {
    final cliente = clienteData['cliente'] as String;
    final deuda = clienteData['deuda'] as double;
    final pedidos = clienteData['pedidos'] as List<Pedido>;

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
      ),
    );
  }

  Widget _buildPedidoItem(Pedido pedido) {
    final fechaFormateada = DateFormat('dd MMM yyyy, hh:mm a', 'es_CO').format(pedido.fecha);

    return ListTile(
      title: Text(
        "Tanda: ${pedido.nombreTanda ?? 'General'}",
        style: const TextStyle(fontWeight: FontWeight.bold, color: kColorTextDark),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Fecha: $fechaFormateada", style: const TextStyle(color: kColorTextDark)),
          Text("Pendiente: ${formatoPesos.format(pedido.totalPendiente)}", style: const TextStyle(color: kColorTextDark)),
          ...pedido.detalles.map((d) => Text("• ${d.cantidad}x ${d.producto.nombre}", style: TextStyle(color: kColorTextDark.withOpacity(0.7)))),
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
                pedidoEditar: pedido,
                tandaId: pedido.tandaId,
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