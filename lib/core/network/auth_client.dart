import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:agente_viajes/core/constants/api_constants.dart';
import 'session_expired_notifier.dart';

class AuthClient extends http.BaseClient {
  final http.Client _inner;
  final FlutterSecureStorage _storage;
  final SessionExpiredNotifier _sessionExpiredNotifier;

  static String get _authBaseUrl => '${ApiConstants.kBaseUrl}/v1/auth';

  AuthClient(this._inner, this._storage, this._sessionExpiredNotifier);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await _storage.read(key: 'access_token');

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Clonamos el request porque si falla (401), consumimos el stream y necesitamos enviarlo de nuevo.
    StreamedRequestProxy? requestClone;
    if (request is http.Request) {
      requestClone = StreamedRequestProxy(
        http.Request(request.method, request.url)
          ..headers.addAll(request.headers)
          ..bodyBytes = request.bodyBytes
          ..encoding = request.encoding
          ..followRedirects = request.followRedirects
          ..maxRedirects = request.maxRedirects
          ..persistentConnection = request.persistentConnection,
      );
    } // Si es Multipart u otros se manejarían de forma similar, aquí usamos requests estándar mayormente.

    // Tratamos de enviar el clon o el original si no lo clonamos
    http.StreamedResponse response = await _inner.send(
      requestClone?.createClone() ?? request,
    );

    // Verificamos error 401
    if (response.statusCode == 401) {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken != null) {
        // Intentar refrescar
        final refreshUrl = Uri.parse('$_authBaseUrl/refresh');
        final refreshResponse = await _inner.post(
          refreshUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh_token': refreshToken}),
        );

        if (refreshResponse.statusCode == 200 ||
            refreshResponse.statusCode == 201) {
          final refreshData = jsonDecode(refreshResponse.body);
          final newAccessToken = refreshData['access_token'];
          final newRefreshToken = refreshData['refresh_token'];

          await _storage.write(key: 'access_token', value: newAccessToken);
          if (newRefreshToken != null) {
            await _storage.write(key: 'refresh_token', value: newRefreshToken);
          }

          // Armamos un nuevo request original clonado para reenviar
          if (requestClone != null) {
            final retryRequest = requestClone.createClone();
            retryRequest.headers['Authorization'] = 'Bearer $newAccessToken';
            return _inner.send(retryRequest);
          }
        } else {
          // Refresh falló — limpiar sesión y notificar UI
          await _storage.delete(key: 'access_token');
          await _storage.delete(key: 'refresh_token');
          await _storage.delete(key: 'user_data');
          _sessionExpiredNotifier.notify();
        }
      } else {
        // Sin refresh token — sesión expirada sin posibilidad de recuperar
        await _storage.delete(key: 'access_token');
        await _storage.delete(key: 'user_data');
        _sessionExpiredNotifier.notify();
      }
    }

    return response;
  }
}

// Clase de ayuda para clonar peticiones HTTP porque BaseRequest se consume luego de usarse.
class StreamedRequestProxy {
  final http.Request original;
  StreamedRequestProxy(this.original);

  http.Request createClone() {
    final copy = http.Request(original.method, original.url);
    copy.headers.addAll(original.headers);
    copy.bodyBytes = original.bodyBytes;
    copy.encoding = original.encoding;
    copy.followRedirects = original.followRedirects;
    copy.maxRedirects = original.maxRedirects;
    copy.persistentConnection = original.persistentConnection;
    return copy;
  }
}
