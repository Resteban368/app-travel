import 'package:agente_viajes/core/widgets/auth_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthNetworkImage cacheWidth', () {
    testWidgets('deriva cacheWidth de width × devicePixelRatio', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(devicePixelRatio: 3.0),
          child: AuthNetworkImage(
            url: 'https://example.test/foto.png',
            width: 100,
            height: 80,
          ),
        ),
      ));

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<ResizeImage>());
      final resize = image.image as ResizeImage;
      expect(resize.width, 300, reason: '100 logical × 3 DPR');
      // No cortamos por alto cuando ya hay ancho (preserva aspect ratio).
      expect(resize.height, isNull);
    });

    testWidgets('usa height cuando no hay width', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(devicePixelRatio: 2.0),
          child: AuthNetworkImage(
            url: 'https://example.test/foto.png',
            height: 50,
          ),
        ),
      ));

      final image = tester.widget<Image>(find.byType(Image));
      final resize = image.image as ResizeImage;
      expect(resize.width, isNull);
      expect(resize.height, 100, reason: '50 logical × 2 DPR');
    });

    testWidgets('cacheWidth explícito tiene prioridad sobre width', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(devicePixelRatio: 3.0),
          child: AuthNetworkImage(
            url: 'https://example.test/foto.png',
            width: 100,
            cacheWidth: 64,
          ),
        ),
      ));

      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as ResizeImage).width, 64);
    });

    testWidgets('sin dimensiones → NetworkImage a resolución completa (sin resize)',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: AuthNetworkImage(url: 'https://example.test/foto.png'),
      ));

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<NetworkImage>());
    });
  });
}
