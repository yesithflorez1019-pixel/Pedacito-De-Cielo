import 'package:intl/intl.dart';

extension FormatoMoneda on num {
  String aPesos({bool conSimbolo = true}) {
    final formatter = NumberFormat.currency(
      locale: 'es_CL', 
      symbol: conSimbolo ? r'$' : '',
      decimalDigits: 0,
    );
    return formatter.format(this);
  }
}
