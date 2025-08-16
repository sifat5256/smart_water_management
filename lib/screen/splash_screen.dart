

import 'dart:math';

import 'package:flutter/material.dart';

import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _waveAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _waveAnimation = Tween(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
      ),
    );

    _controller.forward().whenComplete(() {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00A8E8),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Background water waves
                Positioned.fill(
                  child: CustomPaint(
                    painter: SplashWavePainter(
                      waveValue: _waveAnimation.value,
                      progress: _controller.value,
                    ),
                  ),
                ),

                // App content
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated water drop icon
                        CustomPaint(
                          size: const Size(80, 80),
                          painter: WaterDropPainter(
                            progress: _controller.value,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'AquaTrack',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Smart Water Management',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class SplashWavePainter extends CustomPainter {
  final double waveValue;
  final double progress;

  SplashWavePainter({required this.waveValue, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    // Draw multiple animated waves
    for (int i = 0; i < 3; i++) {
      final waveHeight = 20.0 + (i * 15);
      final waveSpeed = 0.5 + (i * 0.2);
      final path = Path();

      path.moveTo(0, size.height * 0.7);

      for (double x = 0; x <= size.width; x++) {
        final y = waveHeight *
            sin((x / size.width * 4 * pi) +
                (waveValue * waveSpeed));
                path.lineTo(
                x,
                size.height * 0.7 - y * (progress * 1.5)
            );
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      canvas.drawPath(path, paint..color = paint.color.withOpacity(0.15 - (i * 0.05)));
    }

    // Draw some random bubbles rising up
    final bubblePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final random = Random(DateTime.now().millisecond);
    final bubbleCount = (progress * 20).toInt();

    for (int i = 0; i < bubbleCount; i++) {
      final bubbleX = random.nextDouble() * size.width;
      final bubbleY = size.height - (progress * size.height * random.nextDouble());
      final bubbleRadius = random.nextDouble() * 8 + 2;
      canvas.drawCircle(
        Offset(bubbleX, bubbleY),
        bubbleRadius * progress,
        bubblePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SplashWavePainter oldDelegate) => true;
}

class WaterDropPainter extends CustomPainter {
  final double progress;

  WaterDropPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * progress;
    final dropHeight = size.height * 0.8 * progress;

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw water drop shape
    final path = Path()
      ..moveTo(center.dx, center.dy - dropHeight / 2)
      ..quadraticBezierTo(
        center.dx + radius,
        center.dy - dropHeight / 4,
        center.dx,
        center.dy + dropHeight / 2,
      )
      ..quadraticBezierTo(
        center.dx - radius,
        center.dy - dropHeight / 4,
        center.dx,
        center.dy - dropHeight / 2,
      );

    canvas.drawPath(path, paint);

    // Add highlight effect
    if (progress > 0.5) {
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..style = PaintingStyle.fill;

      final highlightPath = Path()
        ..moveTo(center.dx - radius * 0.3, center.dy - dropHeight * 0.3)
        ..quadraticBezierTo(
          center.dx - radius * 0.1,
          center.dy - dropHeight * 0.4,
          center.dx + radius * 0.2,
          center.dy - dropHeight * 0.2,
        )
        ..quadraticBezierTo(
          center.dx + radius * 0.1,
          center.dy,
          center.dx - radius * 0.3,
          center.dy - dropHeight * 0.3,
        );

      canvas.drawPath(highlightPath, highlightPaint);
    }

    // Add ripple effect when nearly complete
    if (progress > 0.8) {
      final ripplePaint = Paint()
        ..color = Colors.white.withOpacity(1 - (progress - 0.8) * 5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final rippleRadius = radius * (1 + (progress - 0.8) * 5);
      canvas.drawCircle(center, rippleRadius, ripplePaint);
    }
  }

  @override
  bool shouldRepaint(covariant WaterDropPainter oldDelegate) => true;
}