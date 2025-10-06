class Tanda {
  final int? id;
  final String nombre;

  const Tanda({this.id, required this.nombre});

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'nombre': nombre,
      };

  factory Tanda.fromMap(Map<String, dynamic> map) => Tanda(
        id: map['id'] as int?,
        nombre: map['nombre'] as String,
      );


  Tanda copyWith({
    int? id,
    String? nombre,
  }) {
    return Tanda(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
    );
  }
}