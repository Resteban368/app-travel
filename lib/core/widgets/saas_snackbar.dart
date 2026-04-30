import 'package:flutter/material.dart';
import '../theme/saas_palette.dart';

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
