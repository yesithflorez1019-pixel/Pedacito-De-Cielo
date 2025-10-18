// lib/en_reparto_page.dart (Versión Final con Corrección de Nulabilidad)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:postres_app/database.dart';
import 'package:postres_app/mapa_reparto_page.dart';
import 'package:postres_app/registrar_pedido.dart'; // ¡IMPORTANTE! Asegúrate de que esta ruta a tu página de edición sea la correcta.
import 'package:postres_app/pedido.dart';
import 'package:postres_app/util/app_colors.dart';
import 'package:postres_app/widgets/acrylic_card.dart';

class EnRepartoPage extends StatefulWidget {
  const EnRepartoPage({super.key});
  @override
  State<EnRepartoPage> createState() => _EnRepartoPageState();
}

class _EnRepartoPageState extends State<EnRepartoPage> with WidgetsBindingObserver {
  List<Pedido> _pedidosPendientes = [];
  List<Pedido> _pedidosFiltrados = [];
  bool _isLoading = true;
  String _statusMessage = 'Cargando pedidos...';
  Position? _currentPosition;
  final Map<int, double> _distancias = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarYOrdenarPedidos();
    _searchController.addListener(_filtrarPedidos);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
         _cargarYOrdenarPedidos();
      }
    }
  }

  void _filtrarPedidos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _pedidosFiltrados = _pedidosPendientes.where((pedido) {
        return pedido.cliente.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _cargarYOrdenarPedidos() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _statusMessage = 'Obteniendo tu ubicación...';
    });
    try {
      _currentPosition = await _getCurrentLocation();
      if (!mounted) return;
      setState(() => _statusMessage = 'Cargando pedidos pendientes...');
      final pedidos = await AppDatabase.obtenerPedidosNoEntregados();
      if (!mounted) return;
      setState(() {
        _pedidosPendientes = pedidos;
        _filtrarPedidos();
      });
      setState(() => _statusMessage = 'Calculando rutas...');
      await _calcularDistancias(pedidos);
      pedidos.sort((a, b) {
        final distA = _distancias[a.id!] ?? double.infinity;
        final distB = _distancias[b.id!] ?? double.infinity;
        return distA.compareTo(distB);
      });
      if (mounted) {
        setState(() {
          _pedidosPendientes = pedidos;
          _filtrarPedidos();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Error: ${e.toString()}';
        });
      }
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Los servicios de ubicación están desactivados.');
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Los permisos de ubicación fueron denegados.');
    }
    if (permission == LocationPermission.deniedForever) return Future.error('Los permisos de ubicación están permanentemente denegados.');
    return await Geolocator.getCurrentPosition();
  }

  Future<void> _calcularDistancias(List<Pedido> pedidos) async {
    if (_currentPosition == null) return;
    const String apiKey = "AIzaSyAKlgCQN5xuWHmmd931c3tzw6XYmwZz5to"; // Tu Clave de API

    for (var pedido in pedidos) {
      double? lat;
      double? lng;
      try {
        final query = Uri.encodeComponent('${pedido.direccion}, Barrancabermeja, Santander, Colombia');
        final url = Uri.parse('https://maps.googleapis.com/maps/api/geocode/json?address=$query&key=$apiKey');
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final results = json.decode(response.body);
          if (results['status'] == 'OK' && results['results'].isNotEmpty) {
            final location = results['results'][0]['geometry']['location'];
            lat = location['lat'];
            lng = location['lng'];

            // --- ✅ CORRECCIÓN AQUÍ ---
            // Solo intentamos guardar si lat y lng tienen un valor.
            if (lat != null && lng != null) {
              await AppDatabase.guardarCoordenadasPedido(pedido.id!, lat, lng);
            }
          }
        }
      } catch (e) {
        print("Error de geocodificación: $e");
      }
      if (lat != null && lng != null) {
        final distancia = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, lat, lng);
        _distancias[pedido.id!] = distancia;
      }
    }
  }

  Future<void> _confirmarEntrega(Pedido pedido) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Entrega'),
          content: Text('¿Estás segura de que quieres marcar el pedido de ${pedido.cliente} como entregado?'),
          actions: <Widget>[
            TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(context).pop(false)),
            TextButton(child: const Text('Sí, Entregado'), onPressed: () => Navigator.of(context).pop(true)),
          ],
        );
      },
    );
    if (confirmado == true) {
      await AppDatabase.actualizarEstadoPedido(pedido.id!, entregado: true);
      _cargarYOrdenarPedidos();
    }
  }

  void _navegarAEditarPedido(Pedido pedido) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RegistrarPedidoPage(tandaId: pedido.tandaId, pedidoEditar: pedido)),
    );
    _cargarYOrdenarPedidos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [kColorBackground1, kColorBackground2], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre de cliente...',
                  prefixIcon: const Icon(Icons.search, color: kColorPrimary),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(color: kColorPrimary), const SizedBox(height: 16), Text(_statusMessage, style: const TextStyle(color: kColorTextDark))]))
                  : _pedidosFiltrados.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _cargarYOrdenarPedidos,
                          color: kColorPrimary,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            itemCount: _pedidosFiltrados.length,
                            itemBuilder: (context, index) => _buildPedidoCard(_pedidosFiltrados[index]),
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
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [kColorHeader1, kColorHeader2], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.of(context).pop()),
            const Expanded(child: Text('Pedidos en Reparto', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            IconButton(
              icon: const Icon(Icons.map_outlined, color: Colors.white),
              onPressed: () async {
                await _cargarYOrdenarPedidos();
                if (!mounted) return;
                if (!_isLoading && _pedidosPendientes.isNotEmpty) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => MapaRepartoPage(pedidos: _pedidosPendientes, ubicacionActual: _currentPosition)));
                }
              },
            ),
            IconButton(icon: const Icon(Icons.my_location, color: Colors.white), onPressed: _cargarYOrdenarPedidos),
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
          Icon(_searchController.text.isEmpty ? Icons.check_circle_outline : Icons.search_off, size: 80, color: kColorPrimary.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(_searchController.text.isEmpty ? '¡Todo entregado!' : 'Sin resultados', style: const TextStyle(fontSize: 24, color: kColorTextDark)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              _searchController.text.isEmpty ? 'No hay pedidos pendientes de entrega.' : 'No se encontraron pedidos que coincidan con tu búsqueda.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kColorTextDark.withOpacity(0.7), fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildPedidoCard(Pedido pedido) {
  final distancia = _distancias[pedido.id!];
  String distanciaStr = '...';
  if (distancia != null) {
    distanciaStr = distancia > 1000 ? '${(distancia / 1000).toStringAsFixed(1)} km' : '${distancia.toStringAsFixed(0)} m';
  }


  return Padding(
    padding: const EdgeInsets.only(bottom: 20.0), 
    child: InkWell(
      onTap: () => _navegarAEditarPedido(pedido),
      borderRadius: BorderRadius.circular(20),
      child: AcrylicCard(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(pedido.cliente, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kColorTextDark)),
                      if (pedido.nombreTanda != null)
                        Chip(
                          label: Text(pedido.nombreTanda!, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                          backgroundColor: kColorPrimary.withOpacity(0.7),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                          visualDensity: VisualDensity.compact,
                        ),
                    ]),
                  ),
                  Chip(
                    label: Text(distanciaStr, style: const TextStyle(color: kColorPrimary, fontWeight: FontWeight.bold)),
                    backgroundColor: kColorPrimary.withOpacity(0.1),
                    avatar: const Icon(Icons.directions_walk, color: kColorPrimary, size: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  )
                ],
              ),
              const Divider(height: 20),
              const Text('Productos a entregar:', style: TextStyle(fontWeight: FontWeight.bold, color: kColorTextDark)),
              const SizedBox(height: 4),
              ...pedido.detalles.map((detalle) => Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
                    child: Text('• ${detalle.cantidad}x ${detalle.producto.nombre}', style: TextStyle(color: kColorTextDark.withOpacity(0.8))),
              )),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total: ${pedido.totalFormateado}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kColorPrimary)),
                  ElevatedButton.icon(
                    onPressed: () => _confirmarEntrega(pedido),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Entregado'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade100, foregroundColor: Colors.green.shade800, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    ),
  );
}
}