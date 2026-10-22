
import 'package:app_verse/ast.dart';

class ErrorEjecucion implements Exception {
  final String mensaje;

  const ErrorEjecucion(this.mensaje);

  @override
  String toString() => 'Error de ejecución: $mensaje';
}

class _Retorno {
  final Object? valor;
  const _Retorno(this.valor);
}

class _SalirCiclo {}

class _ContinuarCiclo {}

class _Entorno {
  final Map<String, Object?> variables = {};
  final Map<String, DeclaracionFuncion> funciones = {};
  final _Entorno? padre;

  _Entorno([this.padre]);

  bool contiene(String nombre) {
    if (variables.containsKey(nombre)) return true;
    return padre?.contiene(nombre) ?? false;
  }

  Object? obtener(String nombre) {
    if (variables.containsKey(nombre)) return variables[nombre];

    if (padre != null) return padre!.obtener(nombre);

    throw ErrorEjecucion('La variable "$nombre" no está definida.');
  }

  void declarar(String nombre, Object? valor) {
    variables[nombre] = valor;
  }

  void asignar(String nombre, Object? valor) {
    if (variables.containsKey(nombre)) {
      variables[nombre] = valor;
      return;
    }

    if (padre != null && padre!.contiene(nombre)) {
      padre!.asignar(nombre, valor);
      return;
    }

    throw ErrorEjecucion('La variable "$nombre" no está definida.');
  }

  DeclaracionFuncion obtenerFuncion(String nombre) {
    if (funciones.containsKey(nombre)) return funciones[nombre]!;

    if (padre != null) return padre!.obtenerFuncion(nombre);

    throw ErrorEjecucion('La función "$nombre" no está definida.');
  }
}

class Interpreter {
  _Entorno _entorno = _Entorno();

  void ejecutar(Programa programa) {
    for (final instruccion in programa.instrucciones) {
      if (instruccion is DeclaracionFuncion) {
        _entorno.funciones[instruccion.nombre] = instruccion;
      }
    }

    for (final instruccion in programa.instrucciones) {
      if (instruccion is! DeclaracionFuncion &&
          instruccion is! DeclaracionClase) {
        _ejecutarInstruccion(instruccion);
      }
    }
  }

  void _ejecutarInstruccion(Instruccion instruccion) {
    if (instruccion is DeclaracionVariable) {
      _entorno.declarar(
        instruccion.nombre,
        _evaluar(instruccion.valor),
      );
      return;
    }

    if (instruccion is Asignacion) {
      _entorno.asignar(
        instruccion.nombre,
        _evaluar(instruccion.valor),
      );
      return;
    }

    if (instruccion is Publicar) {
      print(_texto(_evaluar(instruccion.valor)));
      return;
    }

    if (instruccion is Condicional) {
      if (_verdad(_evaluar(instruccion.condicion))) {
        _ejecutarBloque(instruccion.entonces);
      } else {
        _ejecutarBloque(instruccion.siNo);
      }
      return;
    }

    if (instruccion is CicloMientras) {
      while (_verdad(_evaluar(instruccion.condicion))) {
        try {
          _ejecutarBloque(instruccion.cuerpo);
        } on _SalirCiclo {
          break;
        } on _ContinuarCiclo {
          continue;
        }
      }
      return;
    }

    if (instruccion is CicloPara) {
      if (instruccion.inicializacion != null) {
        _ejecutarInstruccion(instruccion.inicializacion!);
      }

      while (instruccion.condicion == null ||
          _verdad(_evaluar(instruccion.condicion!))) {
        try {
          _ejecutarBloque(instruccion.cuerpo);
        } on _SalirCiclo {
          break;
        } on _ContinuarCiclo {
          // Ejecutar la actualización antes de continuar.
        }

        if (instruccion.actualizacion != null) {
          _ejecutarInstruccion(instruccion.actualizacion!);
        }
      }
      return;
    }

    if (instruccion is SalirApp) throw _SalirCiclo();
    if (instruccion is ContinuarApp) throw _ContinuarCiclo();

    if (instruccion is Devolver) {
      throw _Retorno(_evaluar(instruccion.valor));
    }

    if (instruccion is DeclaracionClase) {
      _entorno.declarar(instruccion.nombre, instruccion);
      return;
    }

    if (instruccion is AsignacionAtributo) {
      final objeto = _evaluar(instruccion.objeto);
      if (objeto is! Map<String, Object?>) {
        throw ErrorEjecucion('El destino no es un objeto válido.');
      }

      objeto[instruccion.atributo] = _evaluar(instruccion.valor);
      return;
    }

    if (instruccion is AsignacionLista) {
      final lista = _evaluar(instruccion.lista);
      final indice = _evaluar(instruccion.indice);
      final valor = _evaluar(instruccion.valor);

      if (lista is! List) {
        throw ErrorEjecucion(
          'No se pueden modificar elementos de un valor que no es una lista.',
        );
      }

      if (indice is! int) {
        throw ErrorEjecucion(
          'El índice de una lista debe ser un entero.',
        );
      }

      if (indice < 0 || indice >= lista.length) {
        throw ErrorEjecucion(
          'Índice $indice fuera de rango para una lista de ${lista.length} elementos.',
        );
      }

      lista[indice] = valor;
      return;
    }

    throw ErrorEjecucion(
      'Instrucción no implementada: ${instruccion.runtimeType}.',
    );
  }

  void _ejecutarBloque(List<Instruccion> instrucciones) {
    for (final instruccion in instrucciones) {
      _ejecutarInstruccion(instruccion);
    }
  }

  Object? _evaluar(Expresion expresion) {
    if (expresion is Literal) return expresion.valor;

    if (expresion is Variable) return _entorno.obtener(expresion.nombre);

    if (expresion is ListaLiteral) {
      return expresion.elementos.map(_evaluar).toList();
    }

    if (expresion is AccesoLista) {
      final lista = _evaluar(expresion.lista);
      final indice = _evaluar(expresion.indice);

      if (lista is! List || indice is! int) {
        throw ErrorEjecucion('Acceso a lista o índice inválido.');
      }

      if (indice < 0 || indice >= lista.length) {
        throw ErrorEjecucion(
          'Índice $indice fuera de rango para una lista de ${lista.length} elementos.',
        );
      }

      return lista[indice];
    }

    if (expresion is AccesoAtributo) {
      final objeto = _evaluar(expresion.objeto);

      if (objeto is! Map<String, Object?>) {
        throw ErrorEjecucion('No se puede acceder al atributo solicitado.');
      }

      if (!objeto.containsKey(expresion.atributo)) {
        throw ErrorEjecucion(
          'El atributo "${expresion.atributo}" no existe.',
        );
      }

      return objeto[expresion.atributo];
    }

    if (expresion is CrearObjeto) {
      throw ErrorEjecucion(
        'La creación de objetos requiere conectar el constructor de la clase.',
      );
    }

    if (expresion is LlamadaMetodo) {
      throw ErrorEjecucion(
        'Las llamadas a métodos todavía no están implementadas.',
      );
    }

    if (expresion is LlamadaFuncion) {
      final funcion = _entorno.obtenerFuncion(expresion.nombre);

      if (funcion.parametros.length != expresion.argumentos.length) {
        throw ErrorEjecucion(
          'La función "${funcion.nombre}" espera '
          '${funcion.parametros.length} argumentos.',
        );
      }

      final entornoAnterior = _entorno;
      final entornoFuncion = _Entorno(entornoAnterior);

      for (var i = 0; i < funcion.parametros.length; i++) {
        entornoFuncion.declarar(
          funcion.parametros[i],
          _evaluar(expresion.argumentos[i]),
        );
      }

      _entorno = entornoFuncion;

      try {
        _ejecutarBloque(funcion.cuerpo);
      } on _Retorno catch (retorno) {
        return retorno.valor;
      } finally {
        _entorno = entornoAnterior;
      }

      return null;
    }

    if (expresion is OperacionUnaria) {
      final valor = _evaluar(expresion.operando);

      switch (expresion.operador) {
        case 'no':
          return !_verdad(valor);
        case '-':
          if (valor is num) return -valor;
          throw ErrorEjecucion('El operador "-" requiere un número.');
      }
    }

    if (expresion is OperacionBinaria) {
      final izquierda = _evaluar(expresion.izquierda);

      if (expresion.operador == 'y' && !_verdad(izquierda)) {
        return false;
      }

      if (expresion.operador == 'o' && _verdad(izquierda)) {
        return true;
      }

      final derecha = _evaluar(expresion.derecha);

      switch (expresion.operador) {
        case '+':
          if (izquierda is String || derecha is String) {
            return _texto(izquierda) + _texto(derecha);
          }
          if (izquierda is num && derecha is num) return izquierda + derecha;
          break;
        case '-':
          if (izquierda is num && derecha is num) return izquierda - derecha;
          break;
        case '*':
          if (izquierda is num && derecha is num) return izquierda * derecha;
          break;
        case '/':
          if (izquierda is num && derecha is num) {
            if (derecha == 0) {
              throw ErrorEjecucion('No se puede dividir entre cero.');
            }
            return izquierda / derecha;
          }
          break;
        case '%':
          if (izquierda is int && derecha is int) {
            if (derecha == 0) {
              throw ErrorEjecucion('No se puede calcular módulo entre cero.');
            }
            return izquierda % derecha;
          }
          break;
        case '>':
          if (izquierda is num && derecha is num) return izquierda > derecha;
          break;
        case '<':
          if (izquierda is num && derecha is num) return izquierda < derecha;
          break;
        case '>=':
          if (izquierda is num && derecha is num) return izquierda >= derecha;
          break;
        case '<=':
          if (izquierda is num && derecha is num) return izquierda <= derecha;
          break;
        case '==':
          return izquierda == derecha;
        case '!=':
          return izquierda != derecha;
        case 'y':
          return _verdad(izquierda) && _verdad(derecha);
        case 'o':
          return _verdad(izquierda) || _verdad(derecha);
      }

      throw ErrorEjecucion(
        'Operación "${expresion.operador}" inválida para los valores dados.',
      );
    }

    throw ErrorEjecucion(
      'Expresión no implementada: ${expresion.runtimeType}.',
    );
  }

  bool _verdad(Object? valor) {
    if (valor is bool) return valor;
    throw ErrorEjecucion('Se esperaba un valor booleano.');
  }

  String _texto(Object? valor) {
    if (valor == null) return 'nulo';
    return valor.toString();
  }
}
