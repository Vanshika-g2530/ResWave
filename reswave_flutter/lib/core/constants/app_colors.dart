import 'package:flutter/material.dart';

/// RESWAVE v3.0 Official Teal Visual Design System Tokens (Section H)
class AppColors {
  // Brand Teal Palette
  static const Color primaryTeal = Color(0xFF0F766E); // Primary action teal
  static const Color deepTeal = Color(0xFF115E59);    // Headings & dark brand surfaces
  static const Color brightTeal = Color(0xFF2DD4BF);  // Mint / highlights & progress glow
  
  // Dark Mode Theme (Default / First)
  static const Color darkBackground = Color(0xFF071B1B);
  static const Color darkSurface = Color(0xFF102C2B);
  static const Color darkSurfaceVariant = Color(0xFF163837);
  static const Color darkBorder = Color(0xFF1A3D3C);
  static const Color darkDivider = darkBorder;
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Light Mode Theme
  static const Color lightBackground = Color(0xFFF5FAF9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFC8DEDA);
  static const Color lightTextPrimary = Color(0xFF102A2A);
  static const Color lightTextSecondary = Color(0xFF58716E);

  // Feedback & Semantic Colors
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color privateBadge = Color(0xFFA855F7);
}
