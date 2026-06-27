import 'package:flutter/material.dart';

/// Paleta de colores para el diseño SaaS.
/// Los static const son los valores light (compatibilidad hacia atrás).
/// Usa [SaasPalette.of(context)] para colores adaptativos light/dark.
class SaasPalette {
  const SaasPalette._();

  // ── Light (valores originales — retrocompatibles) ─────────────────────────
  static const Color bgApp    = Color(0xFFFAFAF9);
  static const Color bgCanvas = Color(0xFFFFFFFF);
  static const Color bgSubtle = Color(0xFFF5F5F4);

  static const Color textPrimary   = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF57534E);
  static const Color textTertiary  = Color(0xFF78716C);

  static const Color brand50  = Color(0xFFEFF6FF);
  static const Color brand600 = Color(0xFF2563EB);
  static const Color brand900 = Color(0xFF1E3A8A);

  static const Color success = Color(0xFF1DAF53);
  static const Color warning = Color(0xFFD97706);
  static const Color danger  = Color(0xFFDC2626);

  static const Color border = Color(0xFFE5E7EB);

  // ── Dark variants ─────────────────────────────────────────────────────────
  static const Color bgAppDark    = Color(0xFF0B1520);
  static const Color bgCanvasDark = Color(0xFF162030);
  static const Color bgSubtleDark = Color(0xFF1B2838);

  static const Color textPrimaryDark   = Color(0xFFDFECF4);
  static const Color textSecondaryDark = Color(0xFF8CAEC4);
  static const Color textTertiaryDark  = Color(0xFF5E82A0);

  static const Color brand50Dark  = Color(0xFF0F2340);
  static const Color brand600Dark = Color(0xFF3B82F6);
  static const Color brand900Dark = Color(0xFF93C5FD);

  static const Color successDark = Color(0xFF34D399);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color dangerDark  = Color(0xFFF87171);

  static const Color borderDark = Color(0xFF1E3045);

  // ── Resolución adaptativa ─────────────────────────────────────────────────
  /// Devuelve el conjunto de colores correcto según el brillo del tema actual.
  static SaasPaletteTheme of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? SaasPaletteTheme.dark
        : SaasPaletteTheme.light;
  }
}

/// Atajo de contexto: `context.saas.bgApp`, `context.saas.brand600`, etc.
extension SaasContext on BuildContext {
  SaasPaletteTheme get saas => SaasPalette.of(this);
}

/// Conjunto de colores resuelto para un brillo específico.
/// Accede vía [SaasPalette.of(context)] o [context.saas].
class SaasPaletteTheme {
  const SaasPaletteTheme._({
    required this.bgApp,
    required this.bgCanvas,
    required this.bgSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.brand50,
    required this.brand600,
    required this.brand900,
    required this.success,
    required this.warning,
    required this.danger,
    required this.border,
  });

  final Color bgApp;
  final Color bgCanvas;
  final Color bgSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color brand50;
  final Color brand600;
  final Color brand900;
  final Color success;
  final Color warning;
  final Color danger;
  final Color border;

  static const SaasPaletteTheme light = SaasPaletteTheme._(
    bgApp:         Color(0xFFFAFAF9),
    bgCanvas:      Color(0xFFFFFFFF),
    bgSubtle:      Color(0xFFF5F5F4),
    textPrimary:   Color(0xFF1A1A1A),
    textSecondary: Color(0xFF57534E),
    textTertiary:  Color(0xFF78716C),
    brand50:       Color(0xFFEFF6FF),
    brand600:      Color(0xFF2563EB),
    brand900:      Color(0xFF1E3A8A),
    success:       Color(0xFF1DAF53),
    warning:       Color(0xFFD97706),
    danger:        Color(0xFFDC2626),
    border:        Color(0xFFE5E7EB),
  );

  static const SaasPaletteTheme dark = SaasPaletteTheme._(
    bgApp:         Color(0xFF0B1520),
    bgCanvas:      Color(0xFF162030),
    bgSubtle:      Color(0xFF1B2838),
    textPrimary:   Color(0xFFDFECF4),
    textSecondary: Color(0xFF8CAEC4),
    textTertiary:  Color(0xFF5E82A0),
    brand50:       Color(0xFF0F2340),
    brand600:      Color(0xFF3B82F6),
    brand900:      Color(0xFF93C5FD),
    success:       Color(0xFF34D399),
    warning:       Color(0xFFFBBF24),
    danger:        Color(0xFFF87171),
    border:        Color(0xFF1E3045),
  );
}
