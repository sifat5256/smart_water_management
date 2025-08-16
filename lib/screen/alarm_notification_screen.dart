import 'package:flutter/material.dart';

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

  final List<Map<String, dynamic>> _notifications = [
    {
      'type': 'motor',
      'status': 'on',
      'message': 'Water motor turned ON',
      'time': '10:30 AM',
      'urgent': false,
    },
    {
      'type': 'level',
      'status': 'low',
      'message': 'Water level below 20%',
      'time': 'Yesterday',
      'urgent': true,
    },
    {
      'type': 'motor',
      'status': 'off',
      'message': 'Water motor automatically turned OFF',
      'time': 'Yesterday',
      'urgent': false,
    },
    {
      'type': 'alert',
      'status': 'high',
      'message': 'Water overflow detected!',
      'time': 'Mar 15',
      'urgent': true,
    },
  ];

  @override
  void initState() {
    super.initState();

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
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
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
                  status: 'ON',
                  isActive: true,
                  icon: Icons.electric_bolt,
                ),
                _buildStatusIndicator(
                  label: 'Water Level',
                  status: '65%',
                  isActive: true,
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
              value: 0.65,
              backgroundColor: Colors.grey[200],
              color: const Color(0xFF00A8E8),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
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
