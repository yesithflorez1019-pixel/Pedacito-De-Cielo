

import 'detalle_pedido.dart';
import 'formato.dart';
import 'producto.dart';

class Pedido {
  final int? id;
  final int tandaId;
  final String cliente;
  final String direccion;
  final String? telefono;
  final bool entregado;
  final bool pagado;
  final double pagoParcial;
  final List<DetallePedido> detalles;
  final String? nombreTanda;
  final DateTime fecha;
  

  final double? latitud;
  final double? longitud;


  Pedido({
    this.id,
    required this.tandaId,
    required this.cliente,
    required this.direccion,
    this.telefono,
    this.entregado = false,
    this.pagado = false,
    this.pagoParcial = 0.0,
    List<DetallePedido>? detalles,
    this.nombreTanda,
    required this.fecha,
    

    this.latitud,
    this.longitud,

  }) : detalles = detalles ?? [];

  double get total => detalles.fold(0.0, (a, d) => a + d.subtotal);
  double get totalPendiente => (total - pagoParcial).clamp(0, total);
  String get totalFormateado => total.aPesos();
  String get pagoParcialFormateado => pagoParcial.aPesos();
  String get restanteFormateado => totalPendiente.aPesos();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'tandaId': tandaId,
      'cliente': cliente,
      'direccion': direccion,
      'telefono': telefono,
      'entregado': entregado,
      'pagado': pagado,
      'pagoParcial': pagoParcial,
      'detalles': detalles.map((d) => d.toMap()).toList(),
      'nombreTanda': nombreTanda,
      'fecha': fecha.toIso8601String(),

    };
  }


  factory Pedido.fromMap(Map<String, dynamic> map, List<Producto> todosLosProductos) {
    return Pedido(
      id: map['id'] as int?,
      tandaId: map['tandaId'] as int,
      cliente: map['cliente'] as String,
      direccion: map['direccion'] as String,
      telefono: map['telefono'] as String?,
      entregado: map['entregado'] == 1,
      pagado: map['pagado'] == 1,
      pagoParcial: (map['pagoParcial'] as num).toDouble(),
      detalles: (map['detalles'] as List<dynamic>?)
          ?.map((item) => DetallePedido.fromMap(item as Map<String, dynamic>, todosLosProductos))
          .toList() ?? [],
      nombreTanda: map['nombreTanda'] as String?,
      fecha: DateTime.parse(map['fecha'] as String),

      latitud: (map['latitud'] as num?)?.toDouble(),
      longitud: (map['longitud'] as num?)?.toDouble(),

    );
  }

  Pedido copyWith({
    int? id,
    int? tandaId,
    String? cliente,
    String? direccion,
    String? telefono,
    bool? entregado,
    bool? pagado,
    double? pagoParcial,
    List<DetallePedido>? detalles,
    String? nombreTanda,
    DateTime? fecha,

    double? latitud,
    double? longitud,

  }) {
    return Pedido(
      id: id ?? this.id,
      tandaId: tandaId ?? this.tandaId,
      cliente: cliente ?? this.cliente,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      entregado: entregado ?? this.entregado,
      pagado: pagado ?? this.pagado,
      pagoParcial: pagoParcial ?? this.pagoParcial,
      detalles: detalles ?? this.detalles,
      nombreTanda: nombreTanda ?? this.nombreTanda,
      fecha: fecha ?? this.fecha,

      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,

    );
  }
}