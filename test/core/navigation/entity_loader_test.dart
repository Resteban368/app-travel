import 'dart:async';

import 'package:agente_viajes/core/navigation/entity_loader.dart';
import 'package:agente_viajes/core/navigation/not_found_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EntityLoader', () {
    testWidgets('muestra spinner mientras carga y luego construye la pantalla',
        (tester) async {
      final completer = Completer<String>();
      await tester.pumpWidget(MaterialApp(
        home: EntityLoader<String>(
          fetch: () => completer.future,
          builder: (_, value) => Scaffold(body: Text('Cargado: $value')),
        ),
      ));

      // Aún cargando.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.textContaining('Cargado'), findsNothing);

      completer.complete('Tour A');
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Cargado: Tour A'), findsOneWidget);
    });

    testWidgets('muestra NotFoundScreen si el fetch falla', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: EntityLoader<String>(
          fetch: () async => throw Exception('404 del backend'),
          builder: (_, value) => Text('nunca: $value'),
          notFoundMessage: 'No se encontró el tour solicitado.',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundScreen), findsOneWidget);
      expect(find.text('No se encontró el tour solicitado.'), findsOneWidget);
      expect(find.textContaining('nunca'), findsNothing);
    });

    testWidgets('el fetch se dispara una sola vez aunque haya rebuilds',
        (tester) async {
      var calls = 0;
      final loader = EntityLoader<int>(
        fetch: () async {
          calls++;
          return 7;
        },
        builder: (_, v) => Text('v=$v'),
      );
      await tester.pumpWidget(MaterialApp(home: loader));
      await tester.pumpAndSettle();
      // Forzar un rebuild del árbol.
      await tester.pumpWidget(MaterialApp(home: loader));
      await tester.pumpAndSettle();

      expect(calls, 1);
    });
  });

  group('NotFoundScreen', () {
    testWidgets('renderiza el mensaje y el botón de volver', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: NotFoundScreen(message: 'La ruta "/xyz" no existe.'),
      ));

      expect(find.text('Página no encontrada'), findsOneWidget);
      expect(find.text('La ruta "/xyz" no existe.'), findsOneWidget);
      expect(find.text('Volver al inicio'), findsOneWidget);
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    });
  });
}
