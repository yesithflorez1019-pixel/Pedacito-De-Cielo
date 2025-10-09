

class Cliente {
  final int? id;
  final String nombre;
  final String? direccion;
  final String? telefono;

  Cliente({
    this.id,
    required this.nombre,
    this.direccion,
    this.telefono,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
    };
  }

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'],
      nombre: map['nombre'],
      direccion: map['direccion'],
      telefono: map['telefono'],
    );
  }
}