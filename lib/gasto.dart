import 'formato.dart'; // <-- extensión num.aPesos()
import 'package:intl/intl.dart';

class Gasto {
  final int? id;
  final int? tandaId;
  final String descripcion;
  final double monto;
  final DateTime fecha;

  Gasto({
    this.id,
    this.tandaId,
    required this.descripcion,
    required this.monto,
    required this.fecha,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'tandaId': tandaId,
        'descripcion': descripcion,
        'monto': monto,
        'fecha': fecha.toIso8601String(),
      };

  factory Gasto.fromMap(Map<String, dynamic> map) => Gasto(
        id: map['id'] as int?,
        tandaId: map['tandaId'] as int?,
        descripcion: map['descripcion'] as String,
        monto: (map['monto'] as num).toDouble(),
        fecha: DateTime.parse(map['fecha'] as String),
      );


  String get montoFormateado => monto.aPesos();

  String get fechaFormateada => DateFormat('dd/MM/yyyy HH:mm').format(fecha);


  Gasto copyWith({
    int? id,
    int? tandaId,
    String? descripcion,
    double? monto,
    DateTime? fecha,
  }) {
    return Gasto(
      id: id ?? this.id,
      tandaId: tandaId ?? this.tandaId,
      descripcion: descripcion ?? this.descripcion,
      monto: monto ?? this.monto,
      fecha: fecha ?? this.fecha,
    );
  }
}
