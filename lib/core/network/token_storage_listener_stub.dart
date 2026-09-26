import 'token_storage_listener.dart';

/// Implementación no-web (VM de tests, móvil): no hay pestañas compartiendo
/// `localStorage`, así que no hay nada que escuchar.
class TokenStorageListenerImpl implements TokenStorageListener {
  @override
  void start(void Function() onExternalChange) {}

  @override
  void stop() {}
}
