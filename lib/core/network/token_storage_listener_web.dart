// TODO(Fase 5): migrar a package:web + dart:js_interop (ANALISIS_Y_PLAN_MEJORAS.md)
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'token_storage_listener.dart';

/// Implementación web: escucha el evento `storage` de `window`, que el navegador
/// dispara **en las demás pestañas** del mismo origen cuando una escribe/borra
/// en `localStorage` (nunca en la pestaña que hizo el cambio).
class TokenStorageListenerImpl implements TokenStorageListener {
  StreamSubscription<html.StorageEvent>? _sub;

  @override
  void start(void Function() onExternalChange) {
    _sub?.cancel();
    _sub = html.window.onStorage.listen((event) {
      // `event.key == null` → `localStorage.clear()` (p. ej. logout global).
      // Filtramos por 'token' para no reaccionar a claves ajenas (tema, etc.).
      final key = event.key;
      if (key == null || key.contains('token')) {
        onExternalChange();
      }
    });
  }

  @override
  void stop() {
    _sub?.cancel();
    _sub = null;
  }
}
