import 'package:flutter/material.dart';

/// Premium design system — dark-first.
/// Los static const son los valores dark (compatibilidad hacia atrás).
/// Usa [D.of(context)] para colores adaptativos light/dark.
class D {
  const D._();

  // ── Dark (valores originales — retrocompatibles) ───────────────────────────
  static const Color bg          = Color(0xFF1E3A8A);
  static const Color surface     = Color(0xFF0D1828);
  static const Color surfaceHigh = Color(0xFF122035);
  static const Color border      = Color(0xFF1A2E45);

  static const Color royalBlue = Color(0xFF1447E6);
  static const Color skyBlue   = Color(0xFF38BDF8);
  static const Color cyan      = Color(0xFF06B6D4);
  static const Color indigo    = Color(0xFF6366F1);

  static const Color emerald = Color(0xFF10B981);
  static const Color rose    = Color(0xFFF43F5E);
  static const Color gold    = Color(0xFFF59E0B);

  static const Color white    = Colors.white;
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate800 = Color(0xFF1E293B);

  static const Color cardGlow = Color(0xFF1447E6);

  // ── Light variants ────────────────────────────────────────────────────────
  static const Color bgLight          = Color(0xFFEFF6FF);
  static const Color surfaceLight     = Color(0xFFFFFFFF);
  static const Color surfaceHighLight = Color(0xFFF8FAFC);
  static const Color borderLight      = Color(0xFFCBD5E1);

  static const Color royalBlueLight = Color(0xFF1447E6);
  static const Color skyBlueLight   = Color(0xFF0284C7);
  static const Color cyanLight      = Color(0xFF0891B2);
  static const Color indigoLight    = Color(0xFF4F46E5);

  static const Color emeraldLight = Color(0xFF059669);
  static const Color roseLight    = Color(0xFFE11D48);
  static const Color goldLight    = Color(0xFFD97706);

  static const Color whiteLight    = Color(0xFF0F172A);
  static const Color slate200Light = Color(0xFF1E293B);
  static const Color slate400Light = Color(0xFF475569);
  static const Color slate600Light = Color(0xFF94A3B8);
  static const Color slate800Light = Color(0xFFF1F5F9);

  static const Color cardGlowLight = Color(0xFF1447E6);

  // ── Resolución adaptativa ─────────────────────────────────────────────────
  /// Devuelve el conjunto de colores correcto según el brillo del tema actual.
  static DTheme of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? DTheme.dark
        : DTheme.light;
  }
}

/// Atajo de contexto: `context.premium.surface`, `context.premium.rose`, etc.
extension PremiumContext on BuildContext {
  DTheme get premium => D.of(this);
}

/// Conjunto de colores resuelto para un brillo específico.
/// Accede vía [D.of(context)] o [context.premium].
class DTheme {
  const DTheme._({
    required this.bg,
    required this.surface,
    required this.surfaceHigh,
    required this.border,
    required this.royalBlue,
    required this.skyBlue,
    required this.cyan,
    required this.indigo,
    required this.emerald,
    required this.rose,
    required this.gold,
    required this.white,
    required this.slate200,
    required this.slate400,
    required this.slate600,
    required this.slate800,
    required this.cardGlow,
  });

  final Color bg;
  final Color surface;
  final Color surfaceHigh;
  final Color border;
  final Color royalBlue;
  final Color skyBlue;
  final Color cyan;
  final Color indigo;
  final Color emerald;
  final Color rose;
  final Color gold;
  final Color white;
  final Color slate200;
  final Color slate400;
  final Color slate600;
  final Color slate800;
  final Color cardGlow;

  static const DTheme dark = DTheme._(
    bg:          Color(0xFF1E3A8A),
    surface:     Color(0xFF0D1828),
    surfaceHigh: Color(0xFF122035),
    border:      Color(0xFF1A2E45),
    royalBlue:   Color(0xFF1447E6),
    skyBlue:     Color(0xFF38BDF8),
    cyan:        Color(0xFF06B6D4),
    indigo:      Color(0xFF6366F1),
    emerald:     Color(0xFF10B981),
    rose:        Color(0xFFF43F5E),
    gold:        Color(0xFFF59E0B),
    white:       Color(0xFFFFFFFF),
    slate200:    Color(0xFFE2E8F0),
    slate400:    Color(0xFF94A3B8),
    slate600:    Color(0xFF475569),
    slate800:    Color(0xFF1E293B),
    cardGlow:    Color(0xFF1447E6),
  );

  static const DTheme light = DTheme._(
    bg:          Color(0xFFEFF6FF),
    surface:     Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFF8FAFC),
    border:      Color(0xFFCBD5E1),
    royalBlue:   Color(0xFF1447E6),
    skyBlue:     Color(0xFF0284C7),
    cyan:        Color(0xFF0891B2),
    indigo:      Color(0xFF4F46E5),
    emerald:     Color(0xFF059669),
    rose:        Color(0xFFE11D48),
    gold:        Color(0xFFD97706),
    white:       Color(0xFF0F172A),
    slate200:    Color(0xFF1E293B),
    slate400:    Color(0xFF475569),
    slate600:    Color(0xFF94A3B8),
    slate800:    Color(0xFFF1F5F9),
    cardGlow:    Color(0xFF1447E6),
  );
}

/// Compatibility alias
typedef PremiumPalette = D;
