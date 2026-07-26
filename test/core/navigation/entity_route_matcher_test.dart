import 'package:agente_viajes/core/navigation/entity_route_matcher.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseEntityRoute', () {
    test('matchea /tours/123/edit', () {
      expect(parseEntityRoute('/tours/123/edit'),
          const EntityRoute('tours', '123', 'edit'));
    });

    test('matchea /tours/abc/detalle (id como slug)', () {
      expect(parseEntityRoute('/tours/abc/detalle'),
          const EntityRoute('tours', 'abc', 'detalle'));
    });

    test('matchea /reservas/9/edit y /clientes/5/historial', () {
      expect(parseEntityRoute('/reservas/9/edit'),
          const EntityRoute('reservas', '9', 'edit'));
      expect(parseEntityRoute('/clientes/5/historial'),
          const EntityRoute('clientes', '5', 'historial'));
    });

    test('ignora query string al parsear los segmentos', () {
      expect(parseEntityRoute('/clientes/5/edit?foo=bar'),
          const EntityRoute('clientes', '5', 'edit'));
    });

    test('rutas de lista (2 segmentos) → null', () {
      expect(parseEntityRoute('/tours'), isNull);
      expect(parseEntityRoute('/tours/create'), isNull);
    });

    test('rutas estáticas de 3 segmentos siguen parseando (las filtra el router)',
        () {
      // El matcher es genérico; el router decide si resource/action aplican.
      expect(parseEntityRoute('/tours/historico/detalle'),
          const EntityRoute('tours', 'historico', 'detalle'));
    });

    test('más de 3 segmentos → null', () {
      expect(parseEntityRoute('/a/b/c/d'), isNull);
    });

    test('id vacío (//) → null', () {
      expect(parseEntityRoute('/tours//edit'), isNull);
    });

    test('null o vacío → null', () {
      expect(parseEntityRoute(null), isNull);
      expect(parseEntityRoute(''), isNull);
    });
  });

  group('argOf', () {
    test('devuelve el argumento cuando es del tipo esperado', () {
      const settings = RouteSettings(name: '/x', arguments: 'hola');
      expect(argOf<String>(settings), 'hola');
    });

    test('devuelve null cuando arguments es null (caso F5)', () {
      const settings = RouteSettings(name: '/x');
      expect(argOf<String>(settings), isNull);
    });

    test('devuelve null cuando el tipo no coincide (no lanza)', () {
      const settings = RouteSettings(name: '/x', arguments: 42);
      expect(argOf<String>(settings), isNull);
    });
  });
}
