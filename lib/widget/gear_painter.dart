import 'dart:math';

import 'package:flutter/material.dart';

class GearPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    final paint = Paint()
      ..color = Colors.purple.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw gear teeth
    for (int i = 0; i < 12; i++) {
      final angle = i * (2 * pi / 12);
      final toothStart = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      final toothEnd = Offset(
        center.dx + (radius * 1.2) * cos(angle),
        center.dy + (radius * 1.2) * sin(angle),
      );
      canvas.drawLine(toothStart, toothEnd, paint);
    }

    // Draw inner circle
    canvas.drawCircle(center, radius * 0.7, paint);
  }

  @override
  bool shouldRepaint(covariant GearPainter oldDelegate) => false;
}