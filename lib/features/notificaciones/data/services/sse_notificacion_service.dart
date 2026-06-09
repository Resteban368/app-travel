// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class SseNotificacionService {
  html.EventSource? _eventSource;

  bool get isConnected =>
      _eventSource != null &&
      _eventSource!.readyState == html.EventSource.OPEN;

  void connect(
    String baseUrl,
    String token, {
    required void Function(Map<String, dynamic> data) onData,
    void Function()? onConnected,
    void Function()? onError,
  }) {
    disconnect();
    final url = '$baseUrl/v1/notificaciones/stream?token=$token';
    debugPrint('🔔 [SSE] Conectando a $url');
    _eventSource = html.EventSource(url);

    _eventSource!.onMessage.listen((event) {
      try {
        final raw = event.data as String?;
        if (raw == null || raw.isEmpty) return;
        final data = jsonDecode(raw) as Map<String, dynamic>;
        if (data['tipo'] == 'connected') {
          debugPrint('🔔 [SSE] Conectado al servidor de notificaciones');
          onConnected?.call();
          return;
        }
        onData(data);
      } catch (e) {
        debugPrint('⚠️ [SSE] Error parseando evento: $e');
      }
    });

    _eventSource!.onError.listen((_) {
      debugPrint('⚠️ [SSE] Error de conexión');
      onError?.call();
    });
  }

  void disconnect() {
    _eventSource?.close();
    _eventSource = null;
  }
}
