// lib/mapa_reparto_page.dart (versión corregida)

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:postres_app/pedido.dart';
import 'package:postres_app/util/app_colors.dart';

class MapaRepartoPage extends StatelessWidget {
  final List<Pedido> pedidos;
  final Position? ubicacionActual;

  const MapaRepartoPage({
    super.key,
    required this.pedidos,
    this.ubicacionActual,
  });

  @override
  Widget build(BuildContext context) {
    // --- LÓGICA CORREGIDA AQUÍ ---
    // Creamos el set de marcadores directamente en el build
    final Set<Marker> markers = {};

    // Marcador para la ubicación actual
    if (ubicacionActual != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('miUbicacion'),
          position: LatLng(ubicacionActual!.latitude, ubicacionActual!.longitude),
          infoWindow: const InfoWindow(title: 'Tu Ubicación'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }

    // Marcadores para CADA pedido
    for (final pedido in pedidos) {
      if (pedido.latitud != null && pedido.longitud != null) {
        markers.add(
          Marker(
            // La clave es que el MarkerId sea único para cada pedido
            markerId: MarkerId('pedido_${pedido.id}'), 
            position: LatLng(pedido.latitud!, pedido.longitud!),
            infoWindow: InfoWindow(
              title: pedido.cliente,
              snippet: pedido.direccion,
            ),
          ),
        );
      }
    }
    // --- FIN DE LA CORRECCIÓN ---

    final CameraPosition initialCameraPosition = ubicacionActual != null
        ? CameraPosition(
            target: LatLng(ubicacionActual!.latitude, ubicacionActual!.longitude),
            zoom: 14.0,
          )
        : const CameraPosition(
            target: LatLng(7.0653, -73.8544), // Coordenadas de Barrancabermeja
            zoom: 12.0,
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Reparto'),
        backgroundColor: kColorHeader1,
      ),
      body: GoogleMap(
        initialCameraPosition: initialCameraPosition,
        markers: markers, // Usamos el set de marcadores que acabamos de crear
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}