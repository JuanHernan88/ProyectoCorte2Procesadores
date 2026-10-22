
import 'token.dart';

class ErrorSintactico implements Exception {
  final String mensaje;
  final int linea;
  final int columna;

  ErrorSintactico(this.mensaje, this.linea, this.columna);

  @override
  String toString() =>
      'Error sintáctico en línea $linea, columna $columna: $mensaje';
}

class Parser {
  final List<Token> tokens;
  int _posicion = 0;

  Parser(this.tokens);

  Token get _actual => tokens[_posicion];

  Token _avanzar() {
    final token = _actual;

    if (_actual.tipo != TipoToken.finArchivo) {
      _posicion++;
    }

    return token;
  }

  void _argumentos() {
    _expresionLogica();

    while (_coincide(',')) {
      _expresionLogica();
    }
  }

  bool _coincide(String lexema) {
    if (_actual.lexema != lexema) return false;

    _avanzar();
    return true;
  }

  Token _esperar(String lexema, String mensaje) {
    if (_actual.lexema == lexema) {
      return _avanzar();
    }

    throw ErrorSintactico(
      mensaje,
      _actual.linea,
      _actual.columna,
    );
  }

  void analizar() {
    while (_actual.tipo != TipoToken.finArchivo) {
      _instruccion();
    }
  }

  void _instruccion() {
    if (_coincide('instalar')) {
      _declaracionVariable();
      return;
    }

    if (_coincide('publicar')) {
      _publicar();
      return;
    }

    if (_coincide('pantalla')) {
      _condicional();
      return;
    }

    if (_coincide('actualizar')) {
      _cicloMientras();
      return;
    }

    if (_coincide('recorrer')) {
      _cicloPara();
      return;
    }

    if (_coincide('salirApp')) {
      _esperar(';', 'Falta ";" después de salirApp.');
      return;
    }

    if (_coincide('continuarApp')) {
      _esperar(';', 'Falta ";" después de continuarApp.');
      return;
    }

    
  if (_actual.tipo == TipoToken.identificador ||
      _actual.lexema == 'estaApp') {
    _asignacion();
    return;
  }

    if (_coincide('servicio')) {
      _declaracionFuncion();
      return;
    }

  if (_coincide('componente')) {
    _declaracionClase();
    return;
  }

    if (_coincide('devolver')) {
      _retorno();
      return;
    }

    throw ErrorSintactico(
      'Instrucción no reconocida. Se esperaba instalar, publicar o pantalla.',
      _actual.linea,
      _actual.columna,
    );
  }

  void _declaracionVariable() {
    if (_actual.tipo != TipoToken.tipoDato &&
        _actual.tipo != TipoToken.identificador) {
      throw ErrorSintactico(
        'Se esperaba un tipo de dato o el nombre de una clase.',
        _actual.linea,
        _actual.columna,
      );
    }

    _avanzar();

    if (_actual.tipo != TipoToken.identificador) {
      throw ErrorSintactico(
        'Se esperaba el nombre de la variable.',
        _actual.linea,
        _actual.columna,
      );
    }

    _avanzar();

    _esperar('=', 'Se esperaba "=" para asignar el valor.');

    _expresion();

    _esperar(';', 'Falta ";" al final de la declaración.');
  }
  
  
  
  void _asignacion() {
    _avanzar(); // Nombre de la variable.

    // Permitir atributos de objetos: persona.nombre
    while (_coincide('.')) {
      if (_actual.tipo != TipoToken.identificador) {
        throw ErrorSintactico(
          'Se esperaba el nombre del atributo después de ".".',
          _actual.linea,
          _actual.columna,
        );
      }

      _avanzar();
    }

    // Permitir acceso y modificación de listas: numeros[1]
    while (_coincide('[')) {
      _expresion();

      _esperar(
        ']',
        'Se esperaba "]" después del índice.',
      );
    }

    _esperar('=', 'Se esperaba "=" en la asignación.');

    _expresionLogica();

    _esperar(';', 'Falta ";" al final de la asignación.');
  }

  void _publicar() {
    _esperar('(', 'Se esperaba "(" después de "publicar".');

    _expresion();

    _esperar(')', 'Se esperaba ")" después de la expresión.');

    _esperar(';', 'Falta ";" al final de "publicar".');
  }

  // pantalla (condición) { instrucciones }
  // Puede continuar con otraPantalla o porDefecto.
  void _condicional() {
    _esperar('(', 'Se esperaba "(" después de "pantalla".');

    _expresionLogica();

    _esperar(')', 'Se esperaba ")" después de la condición.');

    _bloque();

    while (_coincide('otraPantalla')) {
      _esperar(
        '(',
        'Se esperaba "(" después de "otraPantalla".',
      );

      _expresionLogica();

      _esperar(
        ')',
        'Se esperaba ")" después de la condición.',
      );

      _bloque();
    }

    if (_coincide('porDefecto')) {
      _bloque();
    }
  }

  void _cicloMientras() {
    _esperar('(', 'Se esperaba "(" después de "actualizar".');

    _expresionLogica();

    _esperar(')', 'Se esperaba ")" después de la condición.');

    _bloque();
  }

  void _cicloPara() {
  _esperar('(', 'Se esperaba "(" después de "recorrer".');

  if (_coincide(';')) {
    // La inicialización es opcional.
  } else {
    _inicializacionFor();
    _esperar(';', 'Falta ";" después de la inicialización.');
  }

  if (!_coincide(';')) {
    _expresionLogica();
    _esperar(';', 'Falta ";" después de la condición.');
  }

  if (_actual.lexema != ')') {
    _asignacionFor();
  }

  _esperar(')', 'Se esperaba ")" al final de "recorrer".');

  _bloque();
}

void _inicializacionFor() {
  if (_coincide('instalar')) {
    if (_actual.tipo != TipoToken.tipoDato) {
      throw ErrorSintactico(
        'Se esperaba un tipo de dato en la inicialización.',
        _actual.linea,
        _actual.columna,
      );
    }

    _avanzar();

    if (_actual.tipo != TipoToken.identificador) {
      throw ErrorSintactico(
        'Se esperaba una variable en la inicialización.',
        _actual.linea,
        _actual.columna,
      );
    }

    _avanzar();
    _esperar('=', 'Se esperaba "=" en la inicialización.');
    _expresion();
    return;
  }

  _asignacionSinPuntoYComa();
}

void _asignacionFor() {
  _asignacionSinPuntoYComa();
}

void _asignacionSinPuntoYComa() {
  if (_actual.tipo != TipoToken.identificador) {
    throw ErrorSintactico(
      'Se esperaba una variable en la asignación del ciclo.',
      _actual.linea,
      _actual.columna,
    );
  }

  _avanzar();

  _esperar('=', 'Se esperaba "=" en la asignación.');

  _expresion();
}

  void _bloque() {
    _esperar('{', 'Se esperaba "{" para iniciar el bloque.');

    while (_actual.lexema != '}' &&
        _actual.tipo != TipoToken.finArchivo) {
      _instruccion();
    }

    _esperar('}', 'Falta "}" para cerrar el bloque.');
  }


void _declaracionFuncion() {
  if (_actual.tipo != TipoToken.tipoDato) {
    throw ErrorSintactico(
      'Se esperaba el tipo de retorno de la función.',
      _actual.linea,
      _actual.columna,
    );
  }

  _avanzar(); // Tipo de retorno.

  if (_actual.tipo != TipoToken.identificador) {
    throw ErrorSintactico(
      'Se esperaba el nombre de la función.',
      _actual.linea,
      _actual.columna,
    );
  }

  _avanzar(); // Nombre de la función.

  _esperar('(', 'Se esperaba "(" después del nombre de la función.');

  if (_actual.lexema != ')') {
    _parametros();
  }

  _esperar(')', 'Se esperaba ")" después de los parámetros.');

  _bloque();
}


void _declaracionClase() {
  if (_actual.tipo != TipoToken.identificador) {
    throw ErrorSintactico(
      'Se esperaba el nombre de la clase.',
      _actual.linea,
      _actual.columna,
    );
  }

  _avanzar(); // Nombre de la clase.

  _esperar(
    '{',
    'Se esperaba "{" para iniciar la clase.',
  );

  while (_actual.lexema != '}' &&
      _actual.tipo != TipoToken.finArchivo) {
    if (_coincide('instalar')) {
      _declaracionAtributo();
    } else if (_coincide('iniciar')) {
      _declaracionConstructor();
    } else if (_coincide('servicio')) {
      _declaracionFuncion();
    } else {
      throw ErrorSintactico(
        'Se esperaba un atributo, un constructor o un método dentro de la clase.',
        _actual.linea,
        _actual.columna,
      );
    }
  }

  _esperar(
    '}',
    'Falta "}" para cerrar la clase.',
  );
}

void _declaracionAtributo() {
  if (_actual.tipo != TipoToken.tipoDato) {
    throw ErrorSintactico(
      'Se esperaba el tipo de dato del atributo.',
      _actual.linea,
      _actual.columna,
    );
  }

  _avanzar();

  if (_actual.tipo != TipoToken.identificador) {
    throw ErrorSintactico(
      'Se esperaba el nombre del atributo.',
      _actual.linea,
      _actual.columna,
    );
  }

  _avanzar();

  _esperar(
    ';',
    'Falta ";" al final de la declaración del atributo.',
  );
}

void _declaracionConstructor() {
  _esperar(
    '(',
    'Se esperaba "(" después de "iniciar".',
  );

  if (_actual.lexema != ')') {
    _parametros();
  }

  _esperar(
    ')',
    'Se esperaba ")" después de los parámetros del constructor.',
  );

  _bloque();
}


void _parametros() {
  _parametro();

  while (_coincide(',')) {
    _parametro();
  }
}

void _parametro() {
  if (_actual.tipo != TipoToken.tipoDato) {
    throw ErrorSintactico(
      'Se esperaba el tipo de dato del parámetro.',
      _actual.linea,
      _actual.columna,
    );
  }

  _avanzar();

  if (_actual.tipo != TipoToken.identificador) {
    throw ErrorSintactico(
      'Se esperaba el nombre del parámetro.',
      _actual.linea,
      _actual.columna,
    );
  }

  _avanzar();
}

void _retorno() {
  _expresionLogica();

  _esperar(';', 'Falta ";" después de devolver.');
}


  // Prioridad: o tiene menor prioridad que y.
  void _expresionLogica() {
    _expresionY();

    while (_coincide('o')) {
      _expresionY();
    }
  }

  void _expresionY() {
    _expresionNo();

    while (_coincide('y')) {
      _expresionNo();
    }
  }

  void _expresionNo() {
    if (_coincide('no')) {
      _expresionNo();
      return;
    }

    _expresionComparacion();
  }

  void _expresionComparacion() {
    _expresion();

    const operadoresRelacionales = [
      '==',
      '!=',
      '>',
      '<',
      '>=',
      '<=',
    ];

    if (operadoresRelacionales.contains(_actual.lexema)) {
      _avanzar();
      _expresion();
    }
  }

  // Expresiones aritméticas: + y -.
  void _expresion() {
    _termino();

    while (_actual.lexema == '+' || _actual.lexema == '-') {
      _avanzar();
      _termino();
    }
  }

  // Multiplicación, división y módulo tienen mayor prioridad.
  void _termino() {
    _factor();

    while (['*', '/', '%'].contains(_actual.lexema)) {
      _avanzar();
      _factor();
    }
  }

  
  void _factor() {
    // Valores simples.
    if (_actual.tipo == TipoToken.numeroEntero ||
        _actual.tipo == TipoToken.numeroReal ||
        _actual.tipo == TipoToken.cadena ||
        _actual.lexema == 'verdadero' ||
        _actual.lexema == 'falso') {
      _avanzar();
      return;
    }

    // Creación de objetos: crearApp Persona("Carlos", 20).
    if (_coincide('crearApp')) {
      if (_actual.tipo != TipoToken.identificador) {
        throw ErrorSintactico(
          'Se esperaba el nombre de la clase después de crearApp.',
          _actual.linea,
          _actual.columna,
        );
      }

      _avanzar(); // Nombre de la clase.

      _esperar(
        '(',
        'Se esperaba "(" después del nombre de la clase.',
      );

      if (_actual.lexema != ')') {
        _argumentos();
      }

      _esperar(
        ')',
        'Se esperaba ")" después de los argumentos del constructor.',
      );

      return;
    }


    // Variables, llamadas a funciones y acceso a listas.
    if (_actual.tipo == TipoToken.identificador) {
      _avanzar();

      // Llamada a función: sumar(3, 5).
      if (_coincide('(')) {
        if (_actual.lexema != ')') {
          _argumentos();
        }

        _esperar(
          ')',
          'Se esperaba ")" después de los argumentos.',
        );

        return;
      }

      // Acceso a una lista: numeros[0].
      while (_coincide('[')) {
        _expresion();

        _esperar(
          ']',
          'Se esperaba "]" después del índice.',
        );
      }

      return;
    }

    // Lista: [10, 20, 30].
    if (_coincide('[')) {
      if (_actual.lexema != ']') {
        _expresionLogica();

        while (_coincide(',')) {
          _expresionLogica();
        }
      }

      _esperar(
        ']',
        'Se esperaba "]" para cerrar la lista.',
      );

      return;
    }

    // Expresión entre paréntesis.
    if (_coincide('(')) {
      _expresionLogica();

      _esperar(
        ')',
        'Falta ")" para cerrar la expresión.',
      );

      return;
    }

    throw ErrorSintactico(
      'Se esperaba un valor, una variable, una lista o una expresión entre paréntesis.',
      _actual.linea,
      _actual.columna,
    );
  }
}
