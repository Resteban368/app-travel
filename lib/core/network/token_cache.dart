/// Caché en memoria del `access_token` para evitar una lectura de
/// `FlutterSecureStorage` en **cada** petición HTTP (Fase 1, punto 5).
///
/// En web el costo de leer storage es bajo (localStorage), pero en móvil cada
/// lectura cruza el canal de plataforma. Cachear en memoria elimina esa latencia
/// por request.
///
/// Correctitud entre sesiones: el caché es la **fuente rápida**, no la fuente de
/// verdad (esa sigue siendo el storage seguro). Por eso todo punto que cambia el
/// token debe sincronizarlo aquí:
///   - login exitoso  → [set] (ApiAuthRepository)
///   - refresh (401)  → [set] (AuthClient)
///   - logout         → [clear] (ApiAuthRepository)
///   - sesión perdida → [clear] (AuthClient)
/// Si nadie lo ha cargado aún ([isLoaded] == false), quien lo necesite lo
/// hidrata leyendo storage una sola vez.
class TokenCache {
  String? _accessToken;
  bool _loaded = false;

  /// Token cacheado (o `null` si no hay sesión / aún no se cargó).
  String? get accessToken => _accessToken;

  /// `true` si el caché refleja un valor conocido (aunque sea `null` tras logout).
  /// `false` obliga a rehidratar desde storage.
  bool get isLoaded => _loaded;

  /// Guarda un token conocido (login/refresh/hidratación desde storage).
  void set(String? token) {
    _accessToken = token;
    _loaded = true;
  }

  /// Sesión cerrada: sabemos que no hay token, no hace falta releer storage.
  void clear() {
    _accessToken = null;
    _loaded = true;
  }
}
