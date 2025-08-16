import 'dart:math';

import 'package:flutter/material.dart';

class WaterLevelPainter extends CustomPainter {
  final double percentage;
  final double waveAmplitude;
  final double waveFrequency;
  final DateTime timestamp = DateTime.now();

  WaterLevelPainter({
    required this.percentage,
    this.waveAmplitude = 5.0,
    this.waveFrequency = 0.02,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final waterHeight = size.height * (1 - percentage);
    final waterPaint = Paint()
      ..color = const Color(0xFF00A8E8).withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final wavePath = Path();
    wavePath.moveTo(0, waterHeight);

    // Create a wavy water surface
    final now = DateTime.now().millisecondsSinceEpoch / 1000;
    for (double x = 0; x <= size.width; x++) {
      final y = waterHeight +
          sin(x * waveFrequency + now * 2) * waveAmplitude;
      wavePath.lineTo(x, y);
    }

    // Complete the water shape
    wavePath.lineTo(size.width, size.height);
    wavePath.lineTo(0, size.height);
    wavePath.close();

    canvas.drawPath(wavePath, waterPaint);

    // Add some water highlights
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw some random bubbles
    final random = Random(DateTime.now().millisecond);
    final bubblePaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 10; i++) {
      final bubbleX = random.nextDouble() * size.width;
      final bubbleY = waterHeight +
          (size.height - waterHeight) * random.nextDouble();
      final bubbleRadius = random.nextDouble() * 3 + 1;
      canvas.drawCircle(
          Offset(bubbleX, bubbleY), bubbleRadius, bubblePaint);
    }
  }

  @override
  bool shouldRepaint(covariant WaterLevelPainter oldDelegate) => true;
}