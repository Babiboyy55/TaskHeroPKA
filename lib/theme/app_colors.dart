import 'package:flutter/material.dart';

class AppColors {
  // Core orange values (Tailwind orange palette)
  static const orange50 = Color(0xFFFFF7ED);
  static const orange500 = Color(0xFFF97316);
  static const orange600 = Color(0xFFEA580C);
  static const orange400 = Color(0xFFFB923C);
  static const orangeLight = Color(0xFFFFF7ED); // orange-50
  static const orangeMid = Color(0xFFFFEDD5);   // orange-100

  // Additional colors for status and stats
  static const green500 = Color(0xFF10B981);
  static const green600 = Color(0xFF059669);
  static const green100 = Color(0xFFD1FAE5);
  static const blue500 = Color(0xFF3B82F6);
  static const blue100 = Color(0xFFDBEAFE);
  static const purple500 = Color(0xFF8B5CF6);
  static const purple100 = Color(0xFFEDE9FE);

  // Gradient for logo & special CTAs
  static const orangeGradient = LinearGradient(
    colors: [orange400, orange600],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Subtle tint for backgrounds
  static const orangeSubtle = LinearGradient(
    colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
