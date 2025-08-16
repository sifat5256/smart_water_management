import 'dart:math' as math;

import 'package:flutter/material.dart';

class WavePainter extends CustomPainter {
  final double waveValue;
  final double fillValue;

  WavePainter({required this.waveValue, required this.fillValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00A8E8).withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 10.0;
    final baseHeight = size.height;

    path.moveTo(0, baseHeight);

    for (double i = 0; i <= size.width; i++) {
      final y = waveHeight *
          math.sin((i / size.width * 2 * math.pi) + (2 * math.pi * waveValue));
      path.lineTo(i, baseHeight - y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}