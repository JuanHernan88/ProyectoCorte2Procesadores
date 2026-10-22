
import 'dart:io';

import 'package:app_verse/lexer.dart';
import 'package:app_verse/parser.dart';
import 'package:app_verse/token.dart';
import 'package:app_verse/interpreter.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Uso: dart run bin/appverse.dart <archivo.txt>');
    exitCode = 1;
    return;
  }

  final archivo = File(args[0]);

  if (!archivo.existsSync()) {
    stderr.writeln('Error: no existe el archivo "${args[0]}".');
    exitCode = 1;
    return;
  }

  try {
    final fuente = archivo.readAsStringSync();
    final lexer = Lexer(fuente);
    final tokens = lexer.analizar();

    print('\n=== ANALIZADOR LÉXICO DE APPVERSE ===\n');

    for (final token in tokens) {
      if (token.tipo == TipoToken.finArchivo) continue;

      print(
        'Línea ${token.linea}, columna ${token.columna}: '
        '${token.tipo.name.padRight(20)} "${token.lexema}"',
      );
    }

    final parser = Parser(tokens);
    final programa = parser.analizar();

    print('\nAnálisis léxico completado correctamente.');
    print('Análisis sintáctico completado correctamente.');
    print('\n=== EJECUCIÓN DE APPVERSE ===\n');

    final interprete = Interpreter();
    interprete.ejecutar(programa);
  } on ErrorLexico catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln('No se pudo leer el archivo: ${error.message}');
    exitCode = 1;
  }
  on ErrorSintactico catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  }
  on ErrorEjecucion catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  }
}
