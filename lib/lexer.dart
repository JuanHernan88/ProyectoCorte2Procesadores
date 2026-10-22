
import 'token.dart';

class ErrorLexico implements Exception {
  final String mensaje;
  final int linea;
  final int columna;

  ErrorLexico(this.mensaje, this.linea, this.columna);

  @override
  String toString() =>
      'Error léxico en línea $linea, columna $columna: $mensaje';
}

class Lexer {
  final String fuente;

  int _posicion = 0;
  int _linea = 1;
  int _columna = 1;

  Lexer(this.fuente);

  static const Set<String> palabrasReservadas = {
    'instalar',
    'pantalla',
    'otraPantalla',
    'porDefecto',
    'actualizar',
    'recorrer',
    'salirApp',
    'continuarApp',
    'notificar',
    'publicar',
    'servicio',
    'devolver',
    'componente',
    'iniciar',
    'crearApp',
    'estaApp',
    'intentar',
    'capturar',
    'siempre',
    'lanzarError',
    'y',
    'o',
    'no',
    'verdadero',
    'falso',
  };

  static const Set<String> tiposDato = {
    'int',
    'real',
    'string',
    'bool',
  };

  static const Map<String, TipoToken> delimitadores = {
    '(': TipoToken.delimitador,
    ')': TipoToken.delimitador,
    '{': TipoToken.delimitador,
    '}': TipoToken.delimitador,
    '[': TipoToken.delimitador,
    ']': TipoToken.delimitador,
    ';': TipoToken.delimitador,
    ',': TipoToken.delimitador,
    '.': TipoToken.delimitador,
    ':': TipoToken.delimitador,
  };

  static const Set<String> operadores = {
    '+',
    '-',
    '*',
    '/',
    '%',
    '=',
    '==',
    '!',
    '!=',
    '>',
    '<',
    '>=',
    '<=',
    '&&',
    '||',
  };

  bool get _fin => _posicion >= fuente.length;

  String get _actual => _fin ? '' : fuente[_posicion];

  String get _siguiente =>
      _posicion + 1 >= fuente.length ? '' : fuente[_posicion + 1];

  bool _esLetra(String c) =>
      RegExp(r'^[a-zA-Z_]$').hasMatch(c);

  bool _esDigito(String c) =>
      RegExp(r'^[0-9]$').hasMatch(c);

  bool _esEspacio(String c) =>
      c == ' ' || c == '\t' || c == '\r' || c == '\n';

  void _avanzar() {
    if (_fin) return;

    if (_actual == '\n') {
      _linea++;
      _columna = 1;
    } else {
      _columna++;
    }

    _posicion++;
  }

  List<Token> analizar() {
    final List<Token> tokens = [];

    while (!_fin) {
      if (_esEspacio(_actual)) {
        _avanzar();
        continue;
      }

      if (_actual == '/' && _siguiente == '/') {
        while (!_fin && _actual != '\n') {
          _avanzar();
        }
        continue;
      }

      final int lineaInicial = _linea;
      final int columnaInicial = _columna;

      if (_esLetra(_actual)) {
        final String palabra = _leerIdentificador();

        if (tiposDato.contains(palabra)) {
          tokens.add(Token(
            tipo: TipoToken.tipoDato,
            lexema: palabra,
            linea: lineaInicial,
            columna: columnaInicial,
          ));
        } else if (palabrasReservadas.contains(palabra)) {
          tokens.add(Token(
            tipo: TipoToken.palabraReservada,
            lexema: palabra,
            linea: lineaInicial,
            columna: columnaInicial,
          ));
        } else {
          tokens.add(Token(
            tipo: TipoToken.identificador,
            lexema: palabra,
            linea: lineaInicial,
            columna: columnaInicial,
          ));
        }

        continue;
      }

      if (_esDigito(_actual)) {
        tokens.add(_leerNumero(lineaInicial, columnaInicial));
        continue;
      }

      if (_actual == '"') {
        tokens.add(_leerCadena(lineaInicial, columnaInicial));
        continue;
      }

      final String dosCaracteres = _actual + _siguiente;

      if (operadores.contains(dosCaracteres)) {
        tokens.add(Token(
          tipo: TipoToken.operador,
          lexema: dosCaracteres,
          linea: lineaInicial,
          columna: columnaInicial,
        ));

        _avanzar();
        _avanzar();
        continue;
      }

      if (operadores.contains(_actual)) {
        tokens.add(Token(
          tipo: TipoToken.operador,
          lexema: _actual,
          linea: lineaInicial,
          columna: columnaInicial,
        ));

        _avanzar();
        continue;
      }

      if (delimitadores.containsKey(_actual)) {
        tokens.add(Token(
          tipo: TipoToken.delimitador,
          lexema: _actual,
          linea: lineaInicial,
          columna: columnaInicial,
        ));

        _avanzar();
        continue;
      }

      throw ErrorLexico(
        'Carácter no reconocido "$_actual".',
        lineaInicial,
        columnaInicial,
      );
    }

    tokens.add(Token(
      tipo: TipoToken.finArchivo,
      lexema: '',
      linea: _linea,
      columna: _columna,
    ));

    return tokens;
  }

  String _leerIdentificador() {
    final inicio = _posicion;

    while (!_fin && (_esLetra(_actual) || _esDigito(_actual))) {
      _avanzar();
    }

    return fuente.substring(inicio, _posicion);
  }

  Token _leerNumero(int linea, int columna) {
    final inicio = _posicion;

    while (!_fin && _esDigito(_actual)) {
      _avanzar();
    }

    bool esReal = false;

    if (!_fin &&
        _actual == '.' &&
        _esDigito(_siguiente)) {
      esReal = true;
      _avanzar();

      while (!_fin && _esDigito(_actual)) {
        _avanzar();
      }
    }

    return Token(
      tipo: esReal ? TipoToken.numeroReal : TipoToken.numeroEntero,
      lexema: fuente.substring(inicio, _posicion),
      linea: linea,
      columna: columna,
    );
  }

  Token _leerCadena(int linea, int columna) {
    _avanzar(); // Comilla inicial
    final StringBuffer contenido = StringBuffer();

    while (!_fin && _actual != '"') {
      if (_actual == '\n') {
        throw ErrorLexico(
          'La cadena no puede terminar en otra línea.',
          linea,
          columna,
        );
      }

      if (_actual == '\\') {
        _avanzar();

        if (_fin) {
          throw ErrorLexico(
            'Cadena sin cerrar.',
            linea,
            columna,
          );
        }

        switch (_actual) {
          case 'n':
            contenido.write('\n');
            break;
          case 't':
            contenido.write('\t');
            break;
          case '"':
            contenido.write('"');
            break;
          case '\\':
            contenido.write('\\');
            break;
          default:
            throw ErrorLexico(
              'Secuencia de escape no válida.',
              _linea,
              _columna,
            );
        }

        _avanzar();
      } else {
        contenido.write(_actual);
        _avanzar();
      }
    }

    if (_fin) {
      throw ErrorLexico('Cadena sin cerrar.', linea, columna);
    }

    _avanzar(); // Comilla final

    return Token(
      tipo: TipoToken.cadena,
      lexema: contenido.toString(),
      linea: linea,
      columna: columna,
    );
  }
}
