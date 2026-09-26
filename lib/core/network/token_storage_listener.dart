import 'token_storage_listener_stub.dart'
    if (dart.library.html) 'token_storage_listener_web.dart';

/// Escucha cuando **otra pestaña** del navegador modifica el storage de tokens.
///
/// En web cada pestaña es una instancia independiente de la app (memoria Dart
/// propia, [TokenCache] propio) pero **comparten el mismo `localStorage`**. Si
/// la pestaña A renueva/rota el token, la pestaña B seguiría usando el token
/// viejo que tiene cacheado en memoria hasta recibir un 401. Este listener le
/// avisa a B —vía el evento `storage` del navegador— para que invalide su caché
/// y rehidrate desde el storage compartido.
///
/// Fuera de web (VM de `flutter test`, móvil) es un **no-op**: no existen
/// pestañas que compartan storage, así que la implementación stub no hace nada.
abstract class TokenStorageListener {
  factory TokenStorageListener() = TokenStorageListenerImpl;

  /// Empieza a escuchar. En web, [onExternalChange] se invoca cada vez que otra
  /// pestaña cambia (o limpia) una clave de token del `localStorage` compartido.
  void start(void Function() onExternalChange);

  /// Deja de escuchar (idempotente).
  void stop();
}
