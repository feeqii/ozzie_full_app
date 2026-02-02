import 'package:flutter/material.dart';

class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> buttonAccent = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 0,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> inner({required Color color, double blur = 8}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.45),
        blurRadius: blur,
        offset: const Offset(0, 2),
        spreadRadius: -2,
      ),
    ];
  }
}
