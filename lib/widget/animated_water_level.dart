import 'package:flutter/material.dart';
import 'package:iot_water_level_track/widget/wave_painter.dart';

class AnimatedWaterLevel extends StatefulWidget {
  final double percentage;

  const AnimatedWaterLevel({super.key, required this.percentage});

  @override
  State<AnimatedWaterLevel> createState() => _AnimatedWaterLevelState();
}

class _AnimatedWaterLevelState extends State<AnimatedWaterLevel>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _fillController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = 150.0 * widget.percentage;

    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          size: Size(120, height),
          painter: WavePainter(
            waveValue: _waveController.value,
            fillValue: _fillController.value,
          ),
        );
      },
    );
  }
}