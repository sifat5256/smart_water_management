import 'dart:math';

import 'package:flutter/material.dart';

class BubbleAnimation extends StatefulWidget {
  @override
  _BubbleAnimationState createState() => _BubbleAnimationState();
}

class _BubbleAnimationState extends State<BubbleAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Bubble> bubbles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Initialize bubbles
    for (int i = 0; i < 8; i++) {
      bubbles.add(Bubble());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Update bubbles
        for (var bubble in bubbles) {
          bubble.update(_controller.value);
        }

        return CustomPaint(
          painter: BubblePainter(bubbles: bubbles),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class Bubble {
  double x = Random().nextDouble();
  double y = Random().nextDouble();
  double size = Random().nextDouble() * 0.1 + 0.05;
  double speed = Random().nextDouble() * 0.01 + 0.005;
  double opacity = Random().nextDouble() * 0.5 + 0.1;

  void update(double delta) {
    y -= speed;
    if (y < -0.2) {
      y = 1.2;
      x = Random().nextDouble();
    }
  }
}

class BubblePainter extends CustomPainter {
  final List<Bubble> bubbles;

  BubblePainter({required this.bubbles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var bubble in bubbles) {
      final paint = Paint()
        ..color = Colors.orange.withOpacity(bubble.opacity)
        ..style = PaintingStyle.fill;

      final posX = bubble.x * size.width;
      final posY = bubble.y * size.height;
      final radius = bubble.size * size.width / 2;

      canvas.drawCircle(Offset(posX, posY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BubblePainter oldDelegate) => true;
}