

class Insumo {
  final int? id;
  final String nombre;
  final double precio;
  final String? unidad;

  Insumo({this.id, required this.nombre, this.precio = 0.0, this.unidad});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'unidad': unidad,
    };
  }


  factory Insumo.fromMap(Map<String, dynamic> map) {
    return Insumo(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      precio: (map['precio'] as num?)?.toDouble() ?? 0.0,
      unidad: map['unidad'] as String?,
    );
  }

  Insumo copyWith({
    int? id,
    String? nombre,
    double? precio,
    String? unidad,
  }) {
    return Insumo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      unidad: unidad ?? this.unidad,
    );
  }
}