
enum TipoToken {
  palabraReservada,
  tipoDato,
  identificador,
  numeroEntero,
  numeroReal,
  cadena,
  operador,
  delimitador,
  finArchivo,
}

class Token {
  final TipoToken tipo;
  final String lexema;
  final int linea;
  final int columna;

  const Token({
    required this.tipo,
    required this.lexema,
    required this.linea,
    required this.columna,
  });

  @override
  String toString() {
    return 'Token($tipo, "$lexema", línea: $linea, columna: $columna)';
  }
}
