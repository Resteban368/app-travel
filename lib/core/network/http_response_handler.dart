import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_exception.dart';

/// Punto único para convertir una respuesta HTTP en datos o en una excepción
/// tipada. Los repos deben migrar progresivamente sus `catch (e)` ad-hoc a este
/// helper (Fase 1 arranca la jerarquía; la migración completa se cierra en
/// Fases 2/4).
///
/// - 2xx → aplica [parser] al cuerpo ya decodificado (JSON) y lo devuelve.
/// - resto → lanza [ApiException] con el mensaje/código del backend.
///
/// Ejemplo:
/// ```dart
/// final tours = handleResponse(
///   response,
///   (body) => (body as List).map(Tour.fromJson).toList(),
/// );
/// ```
T handleResponse<T>(
  http.Response response,
  T Function(dynamic decodedBody) parser,
) {
  if (response.statusCode >= 200 && response.statusCode < 300) {
    return parser(_decodeBody(response));
  }
  throw ApiException.fromResponse(response);
}

/// Igual que [handleResponse] pero para endpoints 2xx sin cuerpo útil
/// (204 No Content, DELETE, etc.): solo valida el status.
void ensureSuccess(http.Response response) {
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw ApiException.fromResponse(response);
  }
}

dynamic _decodeBody(http.Response response) {
  if (response.body.isEmpty) return null;
  try {
    return jsonDecode(response.body);
  } catch (_) {
    return response.body;
  }
}
