import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../service/firebase_service.dart';


class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late AnimationController _pulseController;

  late DatabaseReference _alertsRef;
  late StreamSubscription<DatabaseEvent> _alertsSubscription;
  List<Map<String, dynamic>> _notifications = [];

  // System status variables
  bool _pumpStatus = false;
  int _waterLevel = 0;
  late StreamSubscription<bool> _pumpSubscription;
  late StreamSubscription<int> _waterLevelSubscription;

  @override
  void initState() {
    super.initState();

    // Initialize Firebase references
    _alertsRef = FirebaseDatabase.instance.ref('devices/${FirebaseService.deviceId}/alerts');

    // Main animation controller
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Pulse animation for urgent notifications
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),)
    );

    _slideAnimation = Tween(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
          parent: _mainController,
          curve: Curves.easeOutQuart),
    );

    _mainController.forward();

    // Setup Firebase listeners
    _setupFirebaseListeners();
  }

  void _setupFirebaseListeners() {
    // Listen to alerts
    _alertsSubscription = _alertsRef.orderByChild('timestamp').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
        final List<Map<String, dynamic>> alerts = [];

        data.forEach((key, value) {
          final alert = Map<String, dynamic>.from(value as Map);
          alerts.add(alert);
        });

        // Sort by timestamp (newest first)
        alerts.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));

        setState(() {
          _notifications = alerts.map((alert) {
            return {
              'type': alert['type'] ?? 'alert',
              'status': alert['status'] ?? 'unknown',
              'message': alert['message'] ?? 'No message',
              'time': _formatTimestamp(alert['timestamp']),
              'urgent': alert['urgent'] ?? false,
            };
          }).toList();
        });
      }
    });

    // Listen to pump status
    _pumpSubscription = FirebaseService.getPumpStatus().listen((status) {
      setState(() {
        _pumpStatus = status;
      });
    });

    // Listen to water level
    _waterLevelSubscription = FirebaseService.getWaterLevel().listen((level) {
      setState(() {
        _waterLevel = level;
      });
    });
  }

  String _formatTimestamp(int? timestamp) {
    if (timestamp == null) return 'Just now';

    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    if (difference.inDays < 1) return '${difference.inHours} hours ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _alertsSubscription.cancel();
    _pumpSubscription.cancel();
    _waterLevelSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _mainController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildSystemStatusCard(),
                    const SizedBox(height: 20),
                    Text(
                      'Recent Alerts',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          return _buildNotificationCard(index);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSystemStatusCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusIndicator(
                  label: 'Motor',
                  status: _pumpStatus ? 'ON' : 'OFF',
                  isActive: _pumpStatus,
                  icon: Icons.electric_bolt,
                ),
                _buildStatusIndicator(
                  label: 'Water Level',
                  status: '$_waterLevel%',
                  isActive: _waterLevel > 20,
                  icon: Icons.water_drop,
                ),
                _buildStatusIndicator(
                  label: 'System',
                  status: 'OK',
                  isActive: true,
                  icon: Icons.check_circle,
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _waterLevel / 100,
              backgroundColor: Colors.grey[200],
              color: _getWaterLevelColor(_waterLevel),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  Color _getWaterLevelColor(int level) {
    if (level < 20) return Colors.red;
    if (level < 50) return Colors.orange;
    return const Color(0xFF00A8E8);
  }

  Widget _buildStatusIndicator({required String label, required String status, required bool isActive, required IconData icon}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF00A8E8).withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isActive ? const Color(0xFF00A8E8) : Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        Text(
          status,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.black : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(int index) {
    final notification = _notifications[index];
    final isUrgent = notification['urgent'] as bool;

    return AnimatedBuilder(
      animation: isUrgent ? _pulseController : AlwaysStoppedAnimation(0),
      builder: (context, child) {
        final pulseValue = isUrgent
            ? 1.0 + 0.1 * _pulseController.value
            : 1.0;

        return Transform.scale(
          scale: pulseValue,
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isUrgent
                    ? Colors.red.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getNotificationColor(notification).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getNotificationIcon(notification),
                      color: _getNotificationColor(notification),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification['message'],
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isUrgent ? Colors.red : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification['time'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isUrgent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'URGENT',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getNotificationIcon(Map<String, dynamic> notification) {
    switch (notification['type']) {
      case 'motor':
        return notification['status'] == 'on'
            ? Icons.power
            : Icons.power_off;
      case 'level':
        return notification['status'] == 'low'
            ? Icons.water_drop_outlined
            : Icons.opacity;
      case 'alert':
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(Map<String, dynamic> notification) {
    if (notification['urgent'] as bool) return Colors.red;

    switch (notification['type']) {
      case 'motor':
        return notification['status'] == 'on'
            ? Colors.green
            : Colors.orange;
      case 'level':
        return notification['status'] == 'low'
            ? Colors.orange
            : Colors.blue;
      case 'alert':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('About System Alerts'),
          content: const Text(
            'This screen helps you monitor system status and alerts.\n\n'
                '• Get notified about motor status changes\n'
                '• Receive alerts for water level changes\n'
                '• View urgent system notifications',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}