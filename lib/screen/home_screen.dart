import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


import '../service/firebase_service.dart';
import '../widget/bubble_animation_painter.dart';
import '../widget/pump_animation_painter.dart';
import '../widget/ripple_animation_painter.dart';
import '../widget/rotation_animation.dart';
import '../widget/water_level_painter.dart';
import '../widget/water_tank_painter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isPumpRunning = false;
  int waterLevelPercent = 0;
  double temperature = 0.0;
  Map<String, dynamic> turbidity = {'ntu': 0.0, 'status': 'UNKNOWN'};
  Map<String, dynamic> flow1 = {
    'lpm': 0.0,
    'total_liters': 0.0,
    'total_bill': 0.0,
    'price_per_liter': 1.5
  };
  Map<String, dynamic> flow2 = {
    'lpm': 0.0,
    'total_liters': 0.0,
    'total_bill': 0.0,
    'price_per_liter': 2.0
  };

  StreamSubscription<bool>? _pumpStatusSubscription;
  StreamSubscription<int>? _waterLevelSubscription;
  StreamSubscription<double>? _temperatureSubscription;
  StreamSubscription<Map<String, dynamic>>? _turbiditySubscription;
  StreamSubscription<Map<String, dynamic>>? _flow1Subscription;
  StreamSubscription<Map<String, dynamic>>? _flow2Subscription;

  @override
  void initState() {
    super.initState();
    _initializeSubscriptions();

    // Add debug prints to verify data
    FirebaseService.getTemperature().listen((temp) {
      debugPrint('Temperature: $temp°C');
    });

    FirebaseService.getTurbidity().listen((turb) {
      debugPrint('Turbidity: ${turb['ntu']} NTU, Status: ${turb['status']}');
    });
  }
  void _initializeSubscriptions() {
    _pumpStatusSubscription = FirebaseService.getPumpStatus().listen((status) {
      if (mounted) {
        setState(() {
          isPumpRunning = status;
        });
      }
    });

    _waterLevelSubscription = FirebaseService.getWaterLevel().listen((level) {
      if (mounted) {
        setState(() {
          waterLevelPercent = level;
        });
      }
    });

    _temperatureSubscription = FirebaseService.getTemperature().listen((temp) {
      print('Temperature updated: $temp');
      if (mounted) {
        setState(() {
          temperature = temp;
        });
      }
    });

    _turbiditySubscription = FirebaseService.getTurbidity().listen((turb) {
      print('Turbidity updated: $turb');
      if (mounted) {
        setState(() {
          turbidity = turb;
        });
      }
    });

    _flow1Subscription = FirebaseService.getFlow1Data().listen((flow) {
      if (mounted) {
        setState(() {
          flow1 = flow;
        });
      }
    });

    _flow2Subscription = FirebaseService.getFlow2Data().listen((flow) {
      if (mounted) {
        setState(() {
          flow2 = flow;
        });
      }
    });
  }

  @override
  void dispose() {
    _pumpStatusSubscription?.cancel();
    _waterLevelSubscription?.cancel();
    _temperatureSubscription?.cancel();
    _turbiditySubscription?.cancel();
    _flow1Subscription?.cancel();
    _flow2Subscription?.cancel();
    super.dispose();
  }

  void togglePump() async {
    try {
      // Desired new state
      final newState = !isPumpRunning;

      // UI আগে আপডেট
      setState(() {
        isPumpRunning = newState;
      });

      // Haptic feedback
      HapticFeedback.lightImpact();

      // Firebase update সঠিক state দিয়ে
      await FirebaseService.controlPump(turnOn: newState);
    } catch (e) {
      // Error হলে UI revert
      if (mounted) {
        setState(() {
          isPumpRunning = !isPumpRunning;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to control pump: ${e.toString()}')),
      );
    }
  }


  void enableAutoMode() async {
    try {
      await FirebaseService.enableAutoMode();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Auto mode enabled')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to enable auto mode: ${e.toString()}')),
      );
    }
  }

  void refillNow() async {
    try {
      await FirebaseService.controlPump(turnOn: true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pump turned on to refill tank')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refill: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Water Level Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWaterTankCard(),
              const SizedBox(height: 20),
              _buildPumpStatusCard(),
              const SizedBox(height: 20),
              _buildQuickActions(),
              const SizedBox(height: 20),
              _buildWaterQualityComparison(),
              const SizedBox(height: 20),
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaterTankCard() {
    return Card(
      color: Colors.blue.shade50,
      elevation: 0.1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Main Water Tank',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Current Level',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$waterLevelPercent%',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00A8E8),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(120, 200),
                    painter: WaterTankPainter(),
                  ),
                  Positioned(
                    bottom: 20,
                    child: CustomPaint(
                      size: const Size(100, 180),
                      painter: WaterLevelPainter(
                        percentage: waterLevelPercent / 100,
                        waveAmplitude: 5,
                        waveFrequency: 0.015,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: waterLevelPercent / 100,
              backgroundColor: Colors.white,
              color: const Color(0xFF00A8E8),
              minHeight: 8,
              borderRadius: const BorderRadius.all(Radius.circular(4)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPumpStatusCard() {
    return Card(
      color: Colors.blue.shade50,
      elevation: 0.1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: PumpAnimation(
                isRunning: isPumpRunning,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pump Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPumpRunning
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPumpRunning
                              ? Icons.check_circle
                              : Icons.error_outline,
                          color: isPumpRunning ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPumpRunning ? 'Running' : 'Stopped',
                          style: TextStyle(
                            color: isPumpRunning ? Colors.green : Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPumpRunning
                        ? 'Flow Rate: ${flow1['lpm'].toStringAsFixed(1)} L/min'
                        : 'Pump is currently off',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isPumpRunning
                    ? Icons.power_settings_new
                    : Icons.power_off,
                color: isPumpRunning ? Colors.red : Colors.green,
              ),
              onPressed: togglePump,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildAnimatedActionButton(
              icon: Icons.autorenew,
              label: 'Auto Mode',
              color: const Color(0xFF00A8E8),
              onTap: enableAutoMode,
              animation: RippleAnimation(),
            ),
            _buildAnimatedActionButton(
              icon: Icons.opacity,
              label: 'Refill Now',
              color: Colors.orange,
              onTap: refillNow,
              animation: BubbleAnimation(),
            ),
            _buildAnimatedActionButton(
              icon: Icons.settings,
              label: 'Settings',
              color: Colors.purple,
              onTap: () {
                HapticFeedback.lightImpact();
                // Navigate to settings screen
              },
              animation: RotationAnimation(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimatedActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required Widget animation,
  }) {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: animation),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterQualityComparison() {
    final turbidityStatus = turbidity['status'] ?? 'UNOWN';
    final turbidityValue = turbidity['ntu'] ?? 0.0;
    final isTurbidityGood = turbidityStatus == 'CLEAR' || turbidityValue <= 5.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Water Quality',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.blue.shade50,
          elevation: 0.1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildQualityIndicator(
                  parameter: 'Temperature',
                  currentValue: temperature,
                  unit: '°C',
                  idealRange: '10 - 30°C',
                  isGood: temperature >= 10 && temperature <= 30,
                ),
                const SizedBox(height: 12),
                _buildQualityIndicator(
                  parameter: 'Turbidity',
                  currentValue: turbidityValue,
                  unit: 'NTU',
                  idealRange: '0 - 5 NTU',
                  isGood: isTurbidityGood,
                  status: turbidityStatus,
                ),
                const SizedBox(height: 12),
                _buildQualityIndicator(
                  parameter: 'Flow Rate 1',
                  currentValue: flow1['lpm'] ?? 0.0,
                  unit: 'L/min',
                  idealRange: '0 - 10 L/min',
                  isGood: true,
                ),
                const SizedBox(height: 12),
                _buildQualityIndicator(
                  parameter: 'Flow Rate 2',
                  currentValue: flow2['lpm'] ?? 0.0,
                  unit: 'L/min',
                  idealRange: '0 - 10 L/min',
                  isGood: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQualityIndicator({
    required String parameter,
    required double currentValue,
    required String unit,
    required String idealRange,
    required bool isGood,
    String? status,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            parameter,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: currentValue / (parameter.contains('Temp') ? 30 : 10),
                backgroundColor: Colors.grey[200],
                color: isGood ? Colors.green : Colors.orange,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${currentValue.toStringAsFixed(1)} $unit',
                    style: TextStyle(
                      color: isGood ? Colors.green : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    idealRange,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              if (status != null) ...[
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    color: isGood ? Colors.green : Colors.orange,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          isGood ? Icons.check_circle : Icons.warning,
          color: isGood ? Colors.green : Colors.orange,
          size: 20,
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    final activities = [
      {
        'time': 'Now',
        'event': isPumpRunning
            ? 'Pump is running'
            : 'Pump is stopped',
        'icon': isPumpRunning ? Icons.power : Icons.power_off,
        'color': isPumpRunning ? Colors.green : Colors.red,
      },
      {
        'time': 'Now',
        'event': 'Water level at $waterLevelPercent%',
        'icon': Icons.opacity,
        'color': const Color(0xFF00A8E8),
      },
      {
        'time': 'Now',
        'event': 'Temperature: ${temperature.toStringAsFixed(1)}°C',
        'icon': Icons.thermostat,
        'color': Colors.orange,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: activities.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final activity = activities[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: activity['color'] as Color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    activity['icon'] as IconData,
                    color: activity['color'] as Color,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity['time'] as String,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activity['event'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}