import 'dart:convert';

import 'package:agente_viajes/core/network/api_exception.dart';
import 'package:agente_viajes/core/network/http_response_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('handleResponse', () {
    test('200 aplica el parser sobre el JSON decodificado', () {
      final resp = http.Response(jsonEncode({'id': 7, 'nombre': 'Tour'}), 200);
      final nombre = handleResponse(resp, (b) => b['nombre'] as String);
      expect(nombre, 'Tour');
    });

    test('201 también se considera éxito', () {
      final resp = http.Response(jsonEncode([1, 2, 3]), 201);
      final list = handleResponse(resp, (b) => (b as List).length);
      expect(list, 3);
    });

    test('200 con cuerpo vacío entrega null al parser', () {
      final resp = http.Response('', 200);
      final result = handleResponse(resp, (b) => b);
      expect(result, isNull);
    });

    test('4xx lanza ApiException con el message del backend', () {
      final resp = http.Response(
        jsonEncode({'message': 'Documento duplicado', 'code': 'DUP_DOC'}),
        400,
      );
      expect(
        () => handleResponse(resp, (b) => b),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.message, 'message', 'Documento duplicado')
              .having((e) => e.code, 'code', 'DUP_DOC'),
        ),
      );
    });

    test('5xx sin JSON legible lanza ApiException genérica', () {
      final resp = http.Response('<html>502</html>', 502);
      expect(
        () => handleResponse(resp, (b) => b),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 's', 502)),
      );
    });

    test('message como lista (validación NestJS) se une con comas', () {
      final resp = http.Response(
        jsonEncode({
          'message': ['correo inválido', 'teléfono requerido'],
        }),
        422,
      );
      expect(
        () => handleResponse(resp, (b) => b),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          'correo inválido, teléfono requerido',
        )),
      );
    });
  });

  group('ensureSuccess', () {
    test('no lanza en 2xx', () {
      expect(() => ensureSuccess(http.Response('', 204)), returnsNormally);
    });

    test('lanza ApiException fuera de 2xx', () {
      expect(
        () => ensureSuccess(http.Response('{"message":"no"}', 403)),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 's', 403)),
      );
    });
  });
}
