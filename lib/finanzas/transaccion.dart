class Transaccion {
  int? id;
  double monto;
  String tipo; 
  String categoria;
  String? descripcion;
  DateTime fecha;
  int cuentaId;

  Transaccion({
    this.id,
    required this.monto,
    required this.tipo,
    required this.categoria,
    this.descripcion,
    required this.fecha,
    required this.cuentaId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'monto': monto,
      'tipo': tipo,
      'categoria': categoria,
      'descripcion': descripcion,
      'fecha': fecha.toIso8601String(),
      'cuentaId': cuentaId,
    };
  }

  factory Transaccion.fromMap(Map<String, dynamic> map) {
    return Transaccion(
      id: map['id'] as int,
      monto: (map['monto'] as num).toDouble(),
      tipo: map['tipo'] as String,
      categoria: map['categoria'] as String,
      descripcion: map['descripcion'] as String?,
      fecha: DateTime.parse(map['fecha'] as String),
      cuentaId: map['cuentaId'] as int,
    );
  }
}