import 'dart:math';

import 'package:flutter/material.dart';

class PumpAnimation extends StatefulWidget {
  final bool isRunning;

  const PumpAnimation({super.key, required this.isRunning});

  @override
  State<PumpAnimation> createState() => _PumpAnimationState();
}

class _PumpAnimationState extends State<PumpAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );

    if (widget.isRunning) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant PumpAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: PumpPainter(
            rotation: _rotationAnimation.value,
            isRunning: widget.isRunning,
          ),
        );
      },
    );
  }
}

class PumpPainter extends CustomPainter {
  final double rotation;
  final bool isRunning;

  PumpPainter({required this.rotation, required this.isRunning});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final pumpRadius = size.width / 3;

    // Draw pump body
    final pumpPaint = Paint()
      ..color = Colors.blueGrey
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, pumpRadius, pumpPaint);

    // Draw pump details
    final detailPaint = Paint()
      ..color = Colors.blueGrey[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, pumpRadius * 0.9, detailPaint);
    canvas.drawCircle(center, pumpRadius * 0.6, detailPaint);

    // Draw rotating fan
    final fanPaint = Paint()
      ..color = isRunning ? Colors.orange : Colors.blueGrey[400]!
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final angle = rotation + i * pi / 2;
      final fanPath = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + cos(angle) * pumpRadius * 0.6,
          center.dy + sin(angle) * pumpRadius * 0.6,
        )
        ..lineTo(
          center.dx + cos(angle + pi / 4) * pumpRadius * 0.4,
          center.dy + sin(angle + pi / 4) * pumpRadius * 0.4,
        )
        ..close();
      canvas.drawPath(fanPath, fanPaint);
    }

    // Draw inlet and outlet pipes
    final pipePaint = Paint()
      ..color = Colors.blueGrey
      ..style = PaintingStyle.fill
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    // Inlet pipe (left)
    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width * 0.3, size.height * 0.3),
      pipePaint,
    );

    // Outlet pipe (right)
    canvas.drawLine(
      Offset(size.width * 0.7, size.height * 0.7),
      Offset(size.width, size.height * 0.7),
      pipePaint,
    );

    // Add water flow animation if running
    if (isRunning) {
      final waterPaint = Paint()
        ..color = const Color(0xFF00A8E8).withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;

      final now = DateTime.now().millisecondsSinceEpoch / 1000;
      final waveOffset = (now * 3) % 20;

      // Inlet water flow
      for (double i = 0; i < 3; i++) {
        final offset = waveOffset + i * 7;
        if (offset < 30) {
          canvas.drawLine(
            Offset(offset, size.height * 0.3),
            Offset(offset + 5, size.height * 0.3),
            waterPaint,
          );
        }
      }

      // Outlet water flow
      for (double i = 0; i < 3; i++) {
        final offset = waveOffset + i * 7;
        if (offset < 30) {
          canvas.drawLine(
            Offset(size.width - offset, size.height * 0.7),
            Offset(size.width - offset - 5, size.height * 0.7),
            waterPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant PumpPainter oldDelegate) =>
      oldDelegate.rotation != rotation || oldDelegate.isRunning != isRunning;
}
