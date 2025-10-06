
class Producto {
  final int? id;
  final String nombre;
  final double precio;
  final int rendimientoTanda;

  const Producto({
    this.id,
    required this.nombre,
    required this.precio,
    this.rendimientoTanda = 1,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'nombre': nombre,
        'precio': precio,
        'rendimiento_tanda': rendimientoTanda,
      };

  factory Producto.fromMap(Map<String, dynamic> map) => Producto(
        id: map['id'] as int?,
        nombre: map['nombre'] as String,
        precio: (map['precio'] as num).toDouble(),
        rendimientoTanda: map['rendimiento_tanda'] as int? ?? 1,
      );


  Producto copyWith({
    int? id,
    String? nombre,
    double? precio,
    int? rendimientoTanda,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      rendimientoTanda: rendimientoTanda ?? this.rendimientoTanda,
    );
  }
}