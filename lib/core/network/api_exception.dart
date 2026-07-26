import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int statusCode;

  /// Código de error de negocio del backend (campo `code`/`error` del JSON),
  /// si viene. Permite a la UI distinguir casos sin comparar mensajes.
  final String? code;

  ApiException({required this.message, required this.statusCode, this.code});

  @override
  String toString() => message;

  /// Crea una [ApiException] a partir de una respuesta HTTP, extrayendo el mensaje
  /// del cuerpo JSON si está disponible (formato común en NestJS).
  factory ApiException.fromResponse(http.Response response) {
    String message = 'Error inesperado en el servidor';
    String? code;
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map) {
        if (decoded.containsKey('message')) {
          final rawMessage = decoded['message'];
          if (rawMessage is List) {
            message = rawMessage.join(', ');
          } else {
            message = rawMessage.toString();
          }
        }
        final rawCode = decoded['code'] ?? decoded['error'];
        if (rawCode != null) code = rawCode.toString();
      }
    } catch (_) {
      message = 'Error del servidor (${response.statusCode})';
    }
    return ApiException(
      message: message,
      statusCode: response.statusCode,
      code: code,
    );
  }
}
