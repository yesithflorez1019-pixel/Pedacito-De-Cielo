class Cuenta {
  int? id;
  String nombre;
  double balance;

  Cuenta({this.id, required this.nombre, required this.balance});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'balance': balance,
    };
  }

  factory Cuenta.fromMap(Map<String, dynamic> map) {
    return Cuenta(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      balance: (map['balance'] as num).toDouble(),
    );
  }
}