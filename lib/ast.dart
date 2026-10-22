
abstract class Nodo {
  const Nodo();
}

abstract class Instruccion extends Nodo {
  const Instruccion();
}

abstract class Expresion extends Nodo {
  const Expresion();
}

// Programa completo
class Programa extends Nodo {
  final List<Instruccion> instrucciones;

  const Programa(this.instrucciones);
}

// Declaración y asignación de variables
class DeclaracionVariable extends Instruccion {
  final String tipo;
  final String nombre;
  final Expresion valor;

  const DeclaracionVariable(this.tipo, this.nombre, this.valor);
}

class Asignacion extends Instruccion {
  final String nombre;
  final Expresion valor;

  const Asignacion(this.nombre, this.valor);
}

// Entrada y salida
class Publicar extends Instruccion {
  final Expresion valor;

  const Publicar(this.valor);
}

class Notificar extends Instruccion {
  final String nombre;
  const Notificar(this.nombre);
}

// Control de flujo
class Condicional extends Instruccion {
  final Expresion condicion;
  final List<Instruccion> entonces;
  final List<Instruccion> siNo;

  const Condicional(this.condicion, this.entonces, this.siNo);
}

class CicloMientras extends Instruccion {
  final Expresion condicion;
  final List<Instruccion> cuerpo;

  const CicloMientras(this.condicion, this.cuerpo);
}

class CicloPara extends Instruccion {
  final Instruccion? inicializacion;
  final Expresion? condicion;
  final Instruccion? actualizacion;
  final List<Instruccion> cuerpo;

  const CicloPara(
    this.inicializacion,
    this.condicion,
    this.actualizacion,
    this.cuerpo,
  );
}

class SalirApp extends Instruccion {
  const SalirApp();
}

class ContinuarApp extends Instruccion {
  const ContinuarApp();
}

// Funciones
class DeclaracionFuncion extends Instruccion {
  final String tipoRetorno;
  final String nombre;
  final List<String> parametros;
  final List<Instruccion> cuerpo;

  const DeclaracionFuncion(
    this.tipoRetorno,
    this.nombre,
    this.parametros,
    this.cuerpo,
  );
}

class Devolver extends Instruccion {
  final Expresion valor;
  const Devolver(this.valor);
}

// Expresiones
class Literal extends Expresion {
  final Object? valor;
  const Literal(this.valor);
}

class Variable extends Expresion {
  final String nombre;
  const Variable(this.nombre);
}

class OperacionUnaria extends Expresion {
  final String operador;
  final Expresion operando;

  const OperacionUnaria(this.operador, this.operando);
}

class OperacionBinaria extends Expresion {
  final Expresion izquierda;
  final String operador;
  final Expresion derecha;

  const OperacionBinaria(
    this.izquierda,
    this.operador,
    this.derecha,
  );
}

class LlamadaFuncion extends Expresion {
  final String nombre;
  final List<Expresion> argumentos;

  const LlamadaFuncion(this.nombre, this.argumentos);
}

class ListaLiteral extends Expresion {
  final List<Expresion> elementos;
  const ListaLiteral(this.elementos);
}

class AccesoLista extends Expresion {
  final Expresion lista;
  final Expresion indice;

  const AccesoLista(this.lista, this.indice);
}


class DeclaracionClase extends Instruccion {
  final String nombre;
  final List<DeclaracionVariable> atributos;
  final DeclaracionFuncion? constructor;
  final List<DeclaracionFuncion> metodos;

  const DeclaracionClase({
    required this.nombre,
    required this.atributos,
    required this.constructor,
    required this.metodos,
  });
}

class CrearObjeto extends Expresion {
  final String nombreClase;
  final List<Expresion> argumentos;

  const CrearObjeto(this.nombreClase, this.argumentos);
}

class AccesoAtributo extends Expresion {
  final Expresion objeto;
  final String atributo;

  const AccesoAtributo(this.objeto, this.atributo);
}

class AsignacionAtributo extends Instruccion {
  final Expresion objeto;
  final String atributo;
  final Expresion valor;

  const AsignacionAtributo(this.objeto, this.atributo, this.valor);
}

class LlamadaMetodo extends Expresion {
  final Expresion objeto;
  final String metodo;
  final List<Expresion> argumentos;

  const LlamadaMetodo(this.objeto, this.metodo, this.argumentos);
}

class AsignacionLista extends Instruccion {
  final Expresion lista;
  final Expresion indice;
  final Expresion valor;

  const AsignacionLista(
    this.lista,
    this.indice,
    this.valor,
  );
}