import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:agente_viajes/core/constants/api_constants.dart';
import 'network_exceptions.dart';
import 'session_expired_notifier.dart';
import 'token_cache.dart';
import 'token_storage_listener.dart';

/// Cliente HTTP central: inyecta el JWT, renueva en 401 y aplica timeouts.
///
/// Garantías de Fase 1:
/// - **Nunca reintenta automáticamente métodos no idempotentes.** El retry en
///   500 solo aplica a GET/HEAD; reintentar un POST/PUT/PATCH/DELETE podía
///   duplicar reservas o pagos si el backend procesó la petición y luego
///   respondió 500.
/// - **Refresh de token serializado.** N peticiones concurrentes que reciben
///   401 comparten una sola llamada a `/refresh` (evita logouts aleatorios por
///   rotación del refresh token).
/// - **Todo request se bufferiza y puede reenviarse**, incluidos los
///   `MultipartRequest` (uploads sobreviven al ciclo 401 → refresh → retry).
/// - **Timeout global**: una petición colgada lanza [NetworkTimeoutException]
///   en vez de dejar el spinner girando para siempre.
class AuthClient extends http.BaseClient {
  final http.Client _inner;
  final FlutterSecureStorage _storage;
  final SessionExpiredNotifier _sessionExpiredNotifier;
  final TokenCache _tokenCache;

  /// Detecta cambios de token hechos por OTRAS pestañas (web). No-op en móvil/VM.
  final TokenStorageListener _storageListener;

  /// Tiempo máximo para recibir la respuesta (cabeceras) del servidor.
  final Duration timeout;

  /// Refresh en curso, compartido por todas las peticiones concurrentes.
  Future<String?>? _ongoingRefresh;

  static String get _authBaseUrl => '${ApiConstants.kBaseUrl}/v1/auth';

  AuthClient(
    this._inner,
    this._storage,
    this._sessionExpiredNotifier,
    this._tokenCache, {
    this.timeout = const Duration(seconds: 30),
    TokenStorageListener? storageListener,
  }) : _storageListener = storageListener ?? TokenStorageListener() {
    // Si otra pestaña renueva/rota el token, nuestro caché en memoria queda
    // obsoleto: lo invalidamos para rehidratar desde el storage compartido en
    // la próxima petición, en vez de disparar un /refresh redundante (que con
    // refresh tokens rotativos podría rechazarse y cerrar la sesión).
    _storageListener.start(_tokenCache.invalidate);
  }

  @override
  void close() {
    _storageListener.stop();
    _inner.close();
    super.close();
  }

  static const Set<String> _idempotentMethods = {'GET', 'HEAD'};

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Bufferizamos el request una sola vez: al fallar (500/401) necesitamos
    // reenviarlo, y un BaseRequest solo puede consumirse una vez.
    final replayable = await _ReplayableRequest.capture(request);

    final token = await _accessToken();
    var response = await _rawSend(replayable.build(_bearer(token)));

    // Retry en 500 SOLO para métodos idempotentes (nunca POST/PUT/PATCH/DELETE).
    if (response.statusCode == 500 &&
        _idempotentMethods.contains(request.method.toUpperCase())) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      response = await _rawSend(replayable.build(_bearer(token)));
    }

    // 401 → intentar recuperar el token y reenviar una vez.
    if (response.statusCode == 401) {
      debugPrint('🔑 [AuthClient] 401 en ${request.method} ${request.url.path}');
      // Primero: ¿otra pestaña ya renovó el token en el storage compartido?
      // Releemos storage (saltándonos el caché, que puede ir por detrás del
      // evento `storage`) y, si cambió, reintentamos con ese antes de gastar
      // un /refresh —y de arriesgar una carrera de rotación entre pestañas—.
      final storageToken = await _storage.read(key: 'access_token');
      if (storageToken != null && storageToken != token) {
        _tokenCache.set(storageToken);
        response = await _rawSend(replayable.build(_bearer(storageToken)));
      }

      // Si sigue 401, renovamos de verdad (serializado) y reenviamos una vez.
      if (response.statusCode == 401) {
        final newToken = await _refreshAccessToken();
        if (newToken != null) {
          response = await _rawSend(replayable.build(_bearer(newToken)));
        }
        // Si newToken es null, _performRefresh ya limpió la sesión y notificó.
      }
    }

    return response;
  }

  /// Envía un request ya construido, aplicando el timeout global.
  Future<http.StreamedResponse> _rawSend(http.BaseRequest request) async {
    try {
      return await _inner.send(request).timeout(timeout);
    } on TimeoutException catch (e) {
      throw NetworkTimeoutException(
        'La solicitud a ${request.url.path} tardó demasiado en responder.',
        e,
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        'No se pudo conectar con el servidor. Verifica tu conexión.',
        e,
      );
    }
  }

  String? _bearer(String? token) => token == null ? null : 'Bearer $token';

  /// Access token desde el caché en memoria; hidrata desde storage solo la
  /// primera vez (o tras invalidación).
  Future<String?> _accessToken() async {
    if (_tokenCache.isLoaded) return _tokenCache.accessToken;
    final token = await _storage.read(key: 'access_token');
    _tokenCache.set(token);
    return token;
  }

  /// Renueva el access token de forma serializada: el primer 401 dispara el
  /// refresh; las demás peticiones concurrentes esperan el mismo resultado.
  Future<String?> _refreshAccessToken() {
    final ongoing = _ongoingRefresh;
    if (ongoing != null) return ongoing;

    final future = _performRefresh();
    _ongoingRefresh = future;
    // Liberamos el gate al terminar (éxito o error) para permitir futuros refresh.
    unawaited(future.whenComplete(() {
      if (identical(_ongoingRefresh, future)) _ongoingRefresh = null;
    }));
    return future;
  }

  /// Llama a `/refresh`. Devuelve el nuevo access token, o `null` si no se pudo
  /// renovar (en cuyo caso limpia la sesión y notifica a la UI).
  Future<String?> _performRefresh() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null) {
      // Sin refresh token, pero otra pestaña pudo dejar un access token válido
      // en el storage compartido: adóptalo antes de cerrar la sesión.
      final freshAccess = await _storage.read(key: 'access_token');
      if (freshAccess != null) {
        _tokenCache.set(freshAccess);
        return freshAccess;
      }
      await _clearSession();
      return null;
    }

    http.Response refreshResponse;
    try {
      refreshResponse = await _inner
          .post(
            Uri.parse('$_authBaseUrl/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(timeout);
    } on TimeoutException {
      // No pudimos confirmar la expiración: no destruimos la sesión por un
      // timeout de red. La petición original devolverá su 401 al llamador.
      debugPrint('⏱️ [AuthClient] /refresh TIMEOUT — se mantiene la sesión');
      return null;
    } on http.ClientException {
      debugPrint('🔌 [AuthClient] /refresh sin red (ClientException)');
      return null;
    }

    if (refreshResponse.statusCode == 200 ||
        refreshResponse.statusCode == 201) {
      final data = jsonDecode(refreshResponse.body);
      final newAccessToken = data['access_token'] as String?;
      final newRefreshToken = data['refresh_token'] as String?;

      if (newAccessToken == null) {
        await _clearSession();
        return null;
      }

      await _storage.write(key: 'access_token', value: newAccessToken);
      if (newRefreshToken != null) {
        await _storage.write(key: 'refresh_token', value: newRefreshToken);
      }
      _tokenCache.set(newAccessToken);
      return newAccessToken;
    }

    // Refresh rechazado por el backend. Antes de destruir la sesión: ¿otra
    // pestaña ya renovó con éxito? Con refresh tokens rotativos, el nuestro pudo
    // quedar invalidado porque otra pestaña rotó primero. Si el refresh token
    // del storage compartido cambió desde que lo leímos, adoptamos el access
    // token nuevo en vez de cerrar sesión (evita el logout aleatorio al tener
    // varias pestañas abiertas).
    final currentRefresh = await _storage.read(key: 'refresh_token');
    if (currentRefresh != null && currentRefresh != refreshToken) {
      final freshAccess = await _storage.read(key: 'access_token');
      if (freshAccess != null) {
        _tokenCache.set(freshAccess);
        return freshAccess;
      }
    }

    // Sesión no recuperable.
    await _clearSession();
    return null;
  }

  Future<void> _clearSession() async {
    debugPrint('🚪 [AuthClient] clearSession → notificando sesión expirada');
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user_data');
    _tokenCache.clear();
    _sessionExpiredNotifier.notify();
  }
}

/// Copia bufferizada de un [http.BaseRequest] que puede reenviarse varias veces.
///
/// Finaliza el request una sola vez a bytes (funciona igual para [http.Request]
/// y [http.MultipartRequest] — en este último, `finalize()` fija el header
/// `content-type` con el boundary correcto, que capturamos después) y reconstruye
/// un [http.Request] fresco en cada reenvío.
class _ReplayableRequest {
  final String method;
  final Uri url;
  final Map<String, String> headers;
  final List<int> bodyBytes;
  final bool followRedirects;
  final int maxRedirects;
  final bool persistentConnection;

  _ReplayableRequest({
    required this.method,
    required this.url,
    required this.headers,
    required this.bodyBytes,
    required this.followRedirects,
    required this.maxRedirects,
    required this.persistentConnection,
  });

  static Future<_ReplayableRequest> capture(http.BaseRequest request) async {
    // finalize() consume el cuerpo y (para multipart) fija content-type+boundary.
    final bytes = await request.finalize().toBytes();
    return _ReplayableRequest(
      method: request.method,
      url: request.url,
      headers: Map<String, String>.of(request.headers),
      bodyBytes: bytes,
      followRedirects: request.followRedirects,
      maxRedirects: request.maxRedirects,
      persistentConnection: request.persistentConnection,
    );
  }

  http.Request build(String? authorization) {
    final r = http.Request(method, url)
      ..headers.addAll(headers)
      ..bodyBytes = bodyBytes
      ..followRedirects = followRedirects
      ..maxRedirects = maxRedirects
      ..persistentConnection = persistentConnection;
    if (authorization != null) {
      r.headers['Authorization'] = authorization;
    } else {
      r.headers.remove('Authorization');
    }
    return r;
  }
}
