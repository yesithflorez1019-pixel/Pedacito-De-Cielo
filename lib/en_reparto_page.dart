// lib/en_reparto_page.dart (versión final y completa)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:postres_app/database.dart';
import 'package:postres_app/mapa_reparto_page.dart';
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
  bool _isLoading = true;
  String _statusMessage = 'Cargando pedidos...';
  Position? _currentPosition;
  final Map<int, double> _distancias = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _cargarYOrdenarPedidos();
  }

  @override
  void dispose() {

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }



  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {

    if (state == AppLifecycleState.resumed) {
      print("✅ Página de reparto visible de nuevo. Forzando recarga de datos...");

      if (mounted) {
         _cargarYOrdenarPedidos();
      }
    }
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
    if (!serviceEnabled) {
      return Future.error('Los servicios de ubicación están desactivados.');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Los permisos de ubicación fueron denegados.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Los permisos de ubicación están permanentemente denegados.');
    }
    return await Geolocator.getCurrentPosition();
  }

  Future<void> _calcularDistancias(List<Pedido> pedidos) async {
    if (_currentPosition == null) return;
    const String apiKey = "AIzaSyAKlgCQN5xuWHmmd931c3tzw6XYmwZz5to"; 

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
            await AppDatabase.guardarCoordenadasPedido(pedido.id!, lat!, lng!);
          } else {
             print("Google no encontró resultados para: ${pedido.direccion}. Status: ${results['status']}");
          }
        }
      } catch (e) {
        print("Error de geocodificación con Google para '${pedido.direccion}': $e");
      }

      if (lat != null && lng != null) {
        final distancia = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, lat, lng);
        _distancias[pedido.id!] = distancia;
      }
    }
  }

  Future<void> _marcarComoEntregado(int pedidoId) async {
    await AppDatabase.actualizarEstadoPedido(pedidoId, entregado: true);
    _cargarYOrdenarPedidos();
  }

  Future<void> _marcarComoPagado(int pedidoId) async {
    await AppDatabase.actualizarEstadoPedido(pedidoId, pagado: true);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [kColorBackground1, kColorBackground2], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(color: kColorPrimary), const SizedBox(height: 16), Text(_statusMessage, style: const TextStyle(color: kColorTextDark))]))
                  : _pedidosPendientes.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _cargarYOrdenarPedidos,
                          color: kColorPrimary,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            itemCount: _pedidosPendientes.length,
                            itemBuilder: (context, index) {
                              final pedido = _pedidosPendientes[index];
                              return _buildPedidoCard(pedido);
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
          const Expanded(
            child: Text('Pedidos en Reparto', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ),
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
          Icon(Icons.check_circle_outline, size: 80, color: kColorPrimary.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text('¡Todo entregado!', style: TextStyle(fontSize: 24, color: kColorTextDark)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text('No hay pedidos pendientes de entrega por el momento.', textAlign: TextAlign.center, style: TextStyle(color: kColorTextDark.withOpacity(0.7), fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildPedidoCard(Pedido pedido) {
    final distancia = _distancias[pedido.id!];
    String distanciaStr = 'Calculando...';
    if (distancia != null) {
      distanciaStr = distancia > 1000 ? '${(distancia / 1000).toStringAsFixed(1)} km' : '${distancia.toStringAsFixed(0)} m';
    }

    return AcrylicCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(pedido.cliente, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kColorTextDark))),
                Chip(
                  label: Text(distanciaStr, style: const TextStyle(color: kColorPrimary, fontWeight: FontWeight.bold)),
                  backgroundColor: kColorPrimary.withOpacity(0.1),
                  avatar: const Icon(Icons.directions_walk, color: kColorPrimary, size: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                )
              ],
            ),
            const SizedBox(height: 4),
            Text(pedido.direccion, style: TextStyle(fontSize: 14, color: kColorTextDark.withOpacity(0.8))),
            const SizedBox(height: 8),
            Text('Total: ${pedido.totalFormateado}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kColorPrimary)),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(onPressed: () => _marcarComoPagado(pedido.id!), icon: const Icon(Icons.price_check), label: const Text('Pagado'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade100, foregroundColor: Colors.green.shade800)),
                ElevatedButton.icon(onPressed: () => _marcarComoEntregado(pedido.id!), icon: const Icon(Icons.check_circle), label: const Text('Entregado'), style: ElevatedButton.styleFrom(backgroundColor: kColorPrimary.withOpacity(0.2), foregroundColor: kColorPrimary)),
              ],
            )
          ],
        ),
      ),
    );
  }
}