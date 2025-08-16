import 'package:flutter/material.dart';

import 'gear_painter.dart';

class RotationAnimation extends StatefulWidget {
  @override
  _RotationAnimationState createState() => _RotationAnimationState();
}

class _RotationAnimationState extends State<RotationAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: CustomPaint(
        painter: GearPainter(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}