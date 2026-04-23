import 'package:flutter/material.dart';

/// Premium dark-themed design system used across the application.
/// Named [D] as a shorthand for Developer/Design palette.
class D {
  const D._();

  static const bg = Color(0xFF1E3A8A);
  static const surface = Color(0xFF0D1828);
  static const surfaceHigh = Color(0xFF122035);
  static const border = Color(0xFF1A2E45);

  static const royalBlue = Color(0xFF1447E6);
  static const skyBlue = Color(0xFF38BDF8);
  static const cyan = Color(0xFF06B6D4);
  static const indigo = Color(0xFF6366F1);

  static const emerald = Color(0xFF10B981);
  static const rose = Color(0xFFF43F5E);
  static const gold = Color(0xFFF59E0B);

  static const white = Colors.white;
  static const slate200 = Color(0xFFE2E8F0);
  static const slate400 = Color(0xFF94A3B8);
  static const slate600 = Color(0xFF475569);
  static const slate800 = Color(0xFF1E293B);

  static const cardGlow = Color(0xFF1447E6);
}

/// Compatibility alias
typedef PremiumPalette = D;
