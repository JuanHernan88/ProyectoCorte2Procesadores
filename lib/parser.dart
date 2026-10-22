
import 'package:app_verse/ast.dart';
import 'package:app_verse/token.dart';

class ErrorSintactico implements Exception {
  final String mensaje;
  final int linea;
  final int columna;

  const ErrorSintactico(this.mensaje, this.linea, this.columna);

  @override
  String toString() =>
      'Error sintáctico en línea $linea, columna $columna: $mensaje';
}

class Parser {
  final List<Token> tokens;
  int _posicion = 0;

  Parser(this.tokens);

  Token get _actual => tokens[_posicion];

  bool _es(String lexema) => _actual.lexema == lexema;

  bool _coincide(String lexema) {
    if (_es(lexema)) {
      _avanzar();
      return true;
    }
    return false;
  }

  Token _avanzar() {
    final anterior = _actual;
    if (_actual.tipo != TipoToken.finArchivo) {
      _posicion++;
    }
    return anterior;
  }

  Token _esperar(String lexema, String mensaje) {
    if (_es(lexema)) return _avanzar();
    throw ErrorSintactico(mensaje, _actual.linea, _actual.columna);
  }

  Token _esperarTipo(TipoToken tipo, String mensaje) {
    if (_actual.tipo == tipo) return _avanzar();
    throw ErrorSintactico(mensaje, _actual.linea, _actual.columna);
  }

  Programa analizar() {
    final instrucciones = <Instruccion>[];

    while (_actual.tipo != TipoToken.finArchivo) {
      instrucciones.add(_instruccion());
    }

    return Programa(instrucciones);
  }

  Instruccion _instruccion() {
    if (_es('componente')) return _declaracionClase();
    if (_es('instalar')) return _declaracionVariable();
    if (_es('publicar')) return _publicar();
    if (_es('pantalla')) return _condicional();
    if (_es('actualizar')) return _cicloMientras();
    if (_es('recorrer')) return _cicloPara();
    if (_es('salirApp')) {
      _avanzar();
      _esperar(';', 'Se esperaba ";" después de salirApp.');
      return const SalirApp();
    }
    if (_es('continuarApp')) {
      _avanzar();
      _esperar(';', 'Se esperaba ";" después de continuarApp.');
      return const ContinuarApp();
    }
    if (_es('servicio')) return _declaracionFuncion();
    if (_es('devolver')) return _devolver();

    if (_actual.tipo == TipoToken.identificador) {
      return _asignacion();
    }

    throw ErrorSintactico(
      'Instrucción no reconocida: "${_actual.lexema}".',
      _actual.linea,
      _actual.columna,
    );
  }

  List<Instruccion> _bloque() {
    _esperar('{', 'Se esperaba "{" para iniciar el bloque.');
    final instrucciones = <Instruccion>[];

    while (!_es('}') && _actual.tipo != TipoToken.finArchivo) {
      instrucciones.add(_instruccion());
    }

    _esperar('}', 'Se esperaba "}" para cerrar el bloque.');
    return instrucciones;
  }

  Instruccion _declaracionVariable() {
    _esperar('instalar', 'Se esperaba "instalar".');

    final tipo = _avanzar().lexema;
    final nombre = _esperarTipo(
      TipoToken.identificador,
      'Se esperaba el nombre de la variable.',
    ).lexema;

    _esperar('=', 'Se esperaba "=" en la declaración.');
    final valor = _expresion();
    _esperar(';', 'Se esperaba ";" después de la declaración.');

    return DeclaracionVariable(tipo, nombre, valor);
  }
  
  Instruccion _asignacion() {
    Expresion destino = Variable(
      _esperarTipo(
        TipoToken.identificador,
        'Se esperaba el nombre de la variable.',
      ).lexema,
    );

    while (true) {
      if (_coincide('.')) {
        final atributo = _esperarTipo(
          TipoToken.identificador,
          'Se esperaba el nombre del atributo después de ".".',
        ).lexema;

        destino = AccesoAtributo(destino, atributo);
      } else if (_coincide('[')) {
        final indice = _expresion();
        _esperar(']', 'Se esperaba "]" después del índice.');
        destino = AccesoLista(destino, indice);
      } else {
        break;
      }
    }

    _esperar('=', 'Se esperaba "=" en la asignación.');
    final valor = _expresion();
    _esperar(';', 'Se esperaba ";" después de la asignación.');

    if (destino is Variable) {
      return Asignacion(destino.nombre, valor);
    }

    if (destino is AccesoAtributo) {
      return AsignacionAtributo(
        destino.objeto,
        destino.atributo,
        valor,
      );
    }

    if (destino is AccesoLista) {
      return AsignacionLista(
        destino.lista,
        destino.indice,
        valor,
      );
    }

    throw ErrorSintactico(
      'El destino de la asignación no es válido.',
      _actual.linea,
      _actual.columna,
    );
  }


  Instruccion _publicar() {
    _esperar('publicar', 'Se esperaba "publicar".');
    _esperar('(', 'Se esperaba "(" después de publicar.');
    final valor = _expresion();
    _esperar(')', 'Se esperaba ")" después del valor.');
    _esperar(';', 'Se esperaba ";" después de publicar.');

    return Publicar(valor);
  }

  Instruccion _condicional() {
    _esperar('pantalla', 'Se esperaba "pantalla".');
    _esperar('(', 'Se esperaba "(" después de pantalla.');
    final condicion = _expresion();
    _esperar(')', 'Se esperaba ")" después de la condición.');

    final entonces = _bloque();
    var siNo = <Instruccion>[];

    while (_coincide('otraPantalla')) {
      _esperar('(', 'Se esperaba "(" después de otraPantalla.');
      final condicionAlterna = _expresion();
      _esperar(')', 'Se esperaba ")" después de la condición.');

      final bloqueAlterno = _bloque();

      siNo = [
        Condicional(condicionAlterna, bloqueAlterno, siNo),
      ];
    }

    if (_coincide('porDefecto')) {
      siNo = _bloque();
    }

    return Condicional(condicion, entonces, siNo);
  }

  Instruccion _cicloMientras() {
    _esperar('actualizar', 'Se esperaba "actualizar".');
    _esperar('(', 'Se esperaba "(" después de actualizar.');
    final condicion = _expresion();
    _esperar(')', 'Se esperaba ")" después de la condición.');

    return CicloMientras(condicion, _bloque());
  }

  Instruccion _cicloPara() {
    _esperar('recorrer', 'Se esperaba "recorrer".');
    _esperar('(', 'Se esperaba "(" después de recorrer.');

    Instruccion? inicializacion;
    Expresion? condicion;
    Instruccion? actualizacion;

    if (!_es(';')) {
      if (_es('instalar')) {
        _avanzar();

        final tipo = _avanzar().lexema;
        final nombre = _esperarTipo(
          TipoToken.identificador,
          'Se esperaba el nombre de la variable del ciclo.',
        ).lexema;

        _esperar('=', 'Se esperaba "=" en la inicialización.');
        final valor = _expresion();

        inicializacion = DeclaracionVariable(tipo, nombre, valor);
      } else {
        final nombre = _esperarTipo(
          TipoToken.identificador,
          'Se esperaba una variable en la inicialización.',
        ).lexema;

        _esperar('=', 'Se esperaba "=" en la inicialización.');
        inicializacion = Asignacion(nombre, _expresion());
      }
    }

    _esperar(';', 'Se esperaba ";" después de la inicialización.');

    if (!_es(';')) {
      condicion = _expresion();
    }

    _esperar(';', 'Se esperaba ";" después de la condición.');

    if (!_es(')')) {
      final nombre = _esperarTipo(
        TipoToken.identificador,
        'Se esperaba una variable en la actualización.',
      ).lexema;

      _esperar('=', 'Se esperaba "=" en la actualización.');
      actualizacion = Asignacion(nombre, _expresion());
    }

    _esperar(')', 'Se esperaba ")" después de recorrer.');

    return CicloPara(
      inicializacion,
      condicion,
      actualizacion,
      _bloque(),
    );
  }

  DeclaracionFuncion _declaracionFuncion() {
    _esperar('servicio', 'Se esperaba "servicio".');

    final tipoRetorno = _avanzar().lexema;
    final nombre = _esperarTipo(
      TipoToken.identificador,
      'Se esperaba el nombre de la función.',
    ).lexema;

    _esperar('(', 'Se esperaba "(" después del nombre de la función.');
    final parametros = <String>[];

    if (!_es(')')) {
      do {
        _avanzar(); // Tipo del parámetro.
        final parametro = _esperarTipo(
          TipoToken.identificador,
          'Se esperaba el nombre del parámetro.',
        );
        parametros.add(parametro.lexema);
      } while (_coincide(','));
    }

    _esperar(')', 'Se esperaba ")" después de los parámetros.');
    final cuerpo = _bloque();

    return DeclaracionFuncion(tipoRetorno, nombre, parametros, cuerpo);
  }

  Instruccion _devolver() {
    _esperar('devolver', 'Se esperaba "devolver".');
    final valor = _expresion();
    _esperar(';', 'Se esperaba ";" después de devolver.');
    return Devolver(valor);
  }

  Expresion _expresion() => _o();

  Expresion _o() {
    var expr = _y();

    while (_coincide('o')) {
      expr = OperacionBinaria(expr, 'o', _y());
    }

    return expr;
  }

  Expresion _y() {
    var expr = _comparacion();

    while (_coincide('y')) {
      expr = OperacionBinaria(expr, 'y', _comparacion());
    }

    return expr;
  }

  Expresion _comparacion() {
    var expr = _suma();

    while (['==', '!=', '>', '<', '>=', '<='].contains(_actual.lexema)) {
      final operador = _avanzar().lexema;
      expr = OperacionBinaria(expr, operador, _suma());
    }

    return expr;
  }

  Expresion _suma() {
    var expr = _multiplicacion();

    while (_es('+') || _es('-')) {
      final operador = _avanzar().lexema;
      expr = OperacionBinaria(expr, operador, _multiplicacion());
    }

    return expr;
  }

  Expresion _multiplicacion() {
    var expr = _unaria();

    while (['*', '/', '%'].contains(_actual.lexema)) {
      final operador = _avanzar().lexema;
      expr = OperacionBinaria(expr, operador, _unaria());
    }

    return expr;
  }

  Expresion _unaria() {
    if (_coincide('no')) {
      return OperacionUnaria('no', _unaria());
    }

    if (_coincide('-')) {
      return OperacionUnaria('-', _unaria());
    }

    return _factor();
  }

  Expresion _factor() {
    if (_coincide('(')) {
      final expr = _expresion();
      _esperar(')', 'Se esperaba ")" para cerrar la expresión.');
      return expr;
    }

    if (_actual.tipo == TipoToken.numeroEntero) {
      return Literal(int.parse(_avanzar().lexema));
    }

    if (_actual.tipo == TipoToken.numeroReal) {
      return Literal(double.parse(_avanzar().lexema));
    }

    if (_actual.tipo == TipoToken.cadena) {
      return Literal(_avanzar().lexema);
    }

    if (_coincide('verdadero')) return const Literal(true);
    if (_coincide('falso')) return const Literal(false);

    if (_coincide('[')) {
      final elementos = <Expresion>[];

      if (!_es(']')) {
        do {
          elementos.add(_expresion());
        } while (_coincide(','));
      }

      _esperar(']', 'Se esperaba "]" para cerrar la lista.');
      return ListaLiteral(elementos);
    }

    
    if (_coincide('crearApp')) {
      final nombreClase = _esperarTipo(
        TipoToken.identificador,
        'Se esperaba el nombre de la clase después de crearApp.',
      ).lexema;

      _esperar('(', 'Se esperaba "(" después del nombre de la clase.');

      final argumentos = <Expresion>[];
      if (!_es(')')) {
        do {
          argumentos.add(_expresion());
        } while (_coincide(','));
      }

      _esperar(')', 'Se esperaba ")" después de los argumentos.');

      return CrearObjeto(nombreClase, argumentos);
    }

    if (_actual.tipo == TipoToken.identificador ||
        _es('estaApp')) {
      Expresion expr = Variable(_avanzar().lexema);

      while (true) {
        if (_coincide('.')) {
          final nombre = _esperarTipo(
            TipoToken.identificador,
            'Se esperaba un atributo o método después de ".".',
          ).lexema;

          if (_coincide('(')) {
            final argumentos = <Expresion>[];

            if (!_es(')')) {
              do {
                argumentos.add(_expresion());
              } while (_coincide(','));
            }

            _esperar(')', 'Se esperaba ")" después de los argumentos.');

            expr = LlamadaMetodo(expr, nombre, argumentos);
          } else {
            expr = AccesoAtributo(expr, nombre);
          }
        } else if (_coincide('(')) {
          final argumentos = <Expresion>[];

          if (!_es(')')) {
            do {
              argumentos.add(_expresion());
            } while (_coincide(','));
          }

          _esperar(')', 'Se esperaba ")" después de los argumentos.');

          if (expr is Variable) {
            expr = LlamadaFuncion(expr.nombre, argumentos);
          } else {
            throw ErrorSintactico(
              'La expresión no puede invocarse como función.',
              _actual.linea,
              _actual.columna,
            );
          }
        } else if (_coincide('[')) {
          final indice = _expresion();
          _esperar(']', 'Se esperaba "]" después del índice.');
          expr = AccesoLista(expr, indice);
        } else {
          break;
        }
      }

      return expr;
    }

    throw ErrorSintactico(
      'Se esperaba una expresión, pero se encontró "${_actual.lexema}".',
      _actual.linea,
      _actual.columna,
    );
  }

  Instruccion _declaracionClase() {
    _esperar('componente', 'Se esperaba "componente".');

    final nombre = _esperarTipo(
      TipoToken.identificador,
      'Se esperaba el nombre de la clase.',
    ).lexema;

    _esperar('{', 'Se esperaba "{" después del nombre de la clase.');

    final atributos = <DeclaracionVariable>[];
    final metodos = <DeclaracionFuncion>[];
    DeclaracionFuncion? constructor;

    while (!_es('}') && _actual.tipo != TipoToken.finArchivo) {
      if (_es('instalar')) {
        final instruccion = _declaracionAtributoClase();
        atributos.add(instruccion);
      } else if (_es('iniciar')) {
        if (constructor != null) {
          throw ErrorSintactico(
            'Una clase solo puede tener un constructor.',
            _actual.linea,
            _actual.columna,
          );
        }
        constructor = _declaracionConstructor();
      } else if (_es('servicio')) {
        metodos.add(_declaracionFuncion());
      } else {
        throw ErrorSintactico(
          'Se esperaba un atributo, un constructor o un método dentro de la clase.',
          _actual.linea,
          _actual.columna,
        );
      }
    }

    _esperar('}', 'Se esperaba "}" para cerrar la clase.');

    return DeclaracionClase(
      nombre: nombre,
      atributos: atributos,
      constructor: constructor,
      metodos: metodos,
    );
  }

  DeclaracionVariable _declaracionAtributoClase() {
    _esperar('instalar', 'Se esperaba "instalar".');

    final tipo = _avanzar().lexema;
    final nombre = _esperarTipo(
      TipoToken.identificador,
      'Se esperaba el nombre del atributo.',
    ).lexema;

    _coincide(';');

    return DeclaracionVariable(tipo, nombre, const Literal(null));
  }

  DeclaracionFuncion _declaracionConstructor() {
    _esperar('iniciar', 'Se esperaba "iniciar".');

    _esperar('(', 'Se esperaba "(" después de iniciar.');
    final parametros = <String>[];

    if (!_es(')')) {
      do {
        _avanzar(); // Tipo del parámetro.
        final parametro = _esperarTipo(
          TipoToken.identificador,
          'Se esperaba el nombre del parámetro.',
        );
        parametros.add(parametro.lexema);
      } while (_coincide(','));
    }

    _esperar(')', 'Se esperaba ")" después de los parámetros.');

    final cuerpo = _bloque();

    return DeclaracionFuncion('void', 'iniciar', parametros, cuerpo);
  }
}
