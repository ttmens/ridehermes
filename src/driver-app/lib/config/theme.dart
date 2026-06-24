import 'package:flutter/material.dart';

class AppColors {
  // 主色 — 与乘客端/管理后台统一使用 Teal
  static const primary = Color(0xFF0D9488); // Teal 600
  static const primaryLight = Color(0xFF5EEAD4); // Teal 300
  static const primaryDark = Color(0xFF0F766E); // Teal 700

  // 功能色
  static const success = Color(0xFF22C55E); // Green 500
  static const warning = Color(0xFFF59E0B); // Amber 500
  static const error = Color(0xFFEF4444); // Red 500
  static const info = Color(0xFF3B82F6); // Blue 500

  // 中性色
  static const textPrimary = Color(0xFF1F2937); // Gray 800
  static const textSecondary = Color(0xFF6B7280); // Gray 500
  static const textHint = Color(0xFF9CA3AF); // Gray 400
  static const divider = Color(0xFFE5E7EB); // Gray 200
  static const background = Color(0xFFF9FAFB); // Gray 50
  static const surface = Color(0xFFFFFFFF); // White

  // 地图标记色
  static const markerPickup = Color(0xFF3B82F6); // Blue
  static const markerDropoff = Color(0xFFEF4444); // Red
  static const markerDriver = Color(0xFF0D9488); // Teal
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const base = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
}

class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const full = 999.0;
}
