// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

class WebNotificationService {
  static const _tag = '[WebNotif]';

  bool get isSupported => html.Notification.supported;

  /// 'granted' | 'denied' | 'default' | 'unsupported'
  String get permission => html.Notification.supported
      ? (html.Notification.permission ?? 'default')
      : 'unsupported';

  Future<String> requestPermission() async {
    if (!html.Notification.supported) return 'unsupported';
    try {
      final result = await html.Notification.requestPermission();
      debugPrint('$_tag Permission: $result');
      return result;
    } catch (e) {
      debugPrint('$_tag Error requesting permission: $e');
      return 'denied';
    }
  }

  bool get _documentHasFocus =>
      js.context.callMethod('eval', ['document.hasFocus()']) as bool? ?? true;

  /// Muestra notificación nativa solo si el documento no tiene el foco.
  void showNotification(String title, {String? body}) {
    if (!html.Notification.supported) return;
    if (html.Notification.permission != 'granted') return;
    if (_documentHasFocus) return;
    try {
      html.Notification(title, body: body);
      _playBeep();
    } catch (e) {
      debugPrint('$_tag Error showing notification: $e');
    }
  }

  void _playBeep() {
    try {
      js.context.callMethod('eval', [r'''
        (function() {
          try {
            var ctx = new (window.AudioContext || window.webkitAudioContext)();
            var osc = ctx.createOscillator();
            var gain = ctx.createGain();
            osc.connect(gain);
            gain.connect(ctx.destination);
            osc.type = 'sine';
            osc.frequency.value = 880;
            gain.gain.setValueAtTime(0.12, ctx.currentTime);
            gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.25);
            osc.start(ctx.currentTime);
            osc.stop(ctx.currentTime + 0.25);
          } catch(e) {}
        })()
      ''']);
    } catch (e) {
      debugPrint('$_tag Error playing beep: $e');
    }
  }
}
