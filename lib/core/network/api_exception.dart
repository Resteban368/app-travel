import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException({required this.message, required this.statusCode});

  @override
  String toString() => message;

  /// Crea una [ApiException] a partir de una respuesta HTTP, extrayendo el mensaje
  /// del cuerpo JSON si está disponible (formato común en NestJS).
  factory ApiException.fromResponse(http.Response response) {
    String message = 'Error inesperado en el servidor';
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map && decoded.containsKey('message')) {
        final rawMessage = decoded['message'];
        if (rawMessage is List) {
          message = rawMessage.join(', ');
        } else {
          message = rawMessage.toString();
        }
      }
    } catch (_) {
      message = 'Error del servidor (${response.statusCode})';
    }
    return ApiException(message: message, statusCode: response.statusCode);
  }
}
