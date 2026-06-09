import 'package:flutter/material.dart';
import '../theme/saas_palette.dart';
import '../../features/notificaciones/domain/entities/notificacion.dart';

/// ─── SaasSnackBar ────────────────────────────────────────────────────────
/// Una utilidad centralizada para mostrar SnackBars con el diseño premium
/// de la aplicación. Evita duplicar código de estilo en cada pantalla.
class SaasSnackBar {
  const SaasSnackBar._();

  /// Muestra un SnackBar de éxito (verde).
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: SaasPalette.success,
      icon: Icons.check_circle_rounded,
    );
  }

  /// Muestra un SnackBar de error (rojo).
  static void showError(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: SaasPalette.danger,
      icon: Icons.error_outline_rounded,
    );
  }

  /// Muestra un SnackBar de advertencia (naranja).
  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: SaasPalette.warning,
      icon: Icons.warning_amber_rounded,
    );
  }

  /// Muestra un SnackBar informativo (azul).
  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: SaasPalette.brand600,
      icon: Icons.info_outline_rounded,
    );
  }

  /// Muestra un SnackBar de notificación entrante con ícono y detalle por tipo.
  static void showNotificacion(
    BuildContext context, {
    required Notificacion notificacion,
  }) {
    final (icon, color) = switch (notificacion.tipo) {
      'cotizacion' => (Icons.request_quote_rounded, const Color(0xFF7C3AED)),
      'pago'       => (Icons.payments_rounded, const Color(0xFF059669)),
      'reserva'    => (Icons.airplane_ticket_rounded, SaasPalette.brand600),
      'sistema'    => (Icons.settings_rounded, const Color(0xFF6B7280)),
      _            => (Icons.campaign_rounded, const Color(0xFFD97706)),
    };

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    notificacion.titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (notificacion.mensaje.isNotEmpty)
                    Text(
                      notificacion.mensaje,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    // Cerramos cualquier SnackBar activo para mostrar el nuevo inmediatamente
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
