import 'package:flutter/material.dart';

class WaterTankPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final tankRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(tankRect, paint);

    // Draw tank details
    final innerPaint = Paint()
      ..color = Colors.blue.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    canvas.drawRect(tankRect.deflate(2), innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}