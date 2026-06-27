import 'package:flutter/material.dart';

/// Corporate color palette for Agente Viajes.
class AppColors {
  AppColors._();

  // Primary Blues
  static const Color navy = Color(0xFF0D1B2A);
  static const Color navyLight = Color(0xFF1B2838);
  static const Color cobalt = Color(0xFF1B4965);
  static const Color cobaltLight = Color(0xFF2A6F97);
  static const Color accent = Color(0xFF62B6CB);
  static const Color accentLight = Color(0xFF89D0E0);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF7F9FC);
  static const Color greyLight = Color(0xFFE8EDF2);
  static const Color grey = Color(0xFFB0BEC5);
  static const Color greyDark = Color(0xFF546E7A);

  // Semantic
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFC62828);

  // Sidebar
  static const Color sidebarBg = navy;
  static const Color sidebarActive = cobalt;
  static const Color sidebarHover = Color(0xFF162536);

  // Dark mode surfaces
  static const Color darkBg = Color(0xFF0B1520);
  static const Color darkSurface = Color(0xFF162030);
  static const Color darkElevated = Color(0xFF1B2838);
  static const Color onDark = Color(0xFFDFECF4);
  static const Color onDarkMuted = Color(0xFF8CAEC4);
  static const Color darkDivider = Color(0xFF1E3045);
  static const Color errorDark = Color(0xFFEF5350);
}
