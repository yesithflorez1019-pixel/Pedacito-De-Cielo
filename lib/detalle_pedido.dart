import 'producto.dart';
import 'formato.dart';

class DetallePedido {
  final int? id;
  int? pedidoId;
  final Producto producto;
  int cantidad;

  DetallePedido({
    this.id,
    this.pedidoId,
    required this.producto,
    required this.cantidad,
  });

  double get subtotal => producto.precio * cantidad.toDouble();


  Map<String, dynamic> toMap() => {
        'id': id,
        'pedidoId': pedidoId,
        'productoId': producto.id, 
        'cantidad': cantidad,
      };


  factory DetallePedido.fromMap(Map<String, dynamic> map, List<Producto> todosLosProductos) {
    final productoId = map['productoId'] as int;
    final producto = todosLosProductos.firstWhere(
      (p) => p.id == productoId,

      orElse: () => Producto(id: productoId, nombre: 'Producto no encontrado', precio: 0),
    );

    return DetallePedido(
      id: map['id'] as int?,
      pedidoId: map['pedidoId'] as int?,
      producto: producto,
      cantidad: map['cantidad'] as int,
    );
  }


  DetallePedido copyWith({
    int? id,
    int? pedidoId,
    Producto? producto,
    int? cantidad,
  }) {
    return DetallePedido(
      id: id ?? this.id,
      pedidoId: pedidoId ?? this.pedidoId,
      producto: producto ?? this.producto,
      cantidad: cantidad ?? this.cantidad,
    );
  }

  @override
  String toString() => '${producto.nombre} x$cantidad — ${subtotal.aPesos()}';
}