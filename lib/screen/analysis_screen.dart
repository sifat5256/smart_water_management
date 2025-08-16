import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import '../service/firebase_service.dart';
import 'analysis_screen/widget/time_periodic_slector.dart';



class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  StreamSubscription<Map<String, dynamic>>? _flow1Subscription;
  StreamSubscription<Map<String, dynamic>>? _flow2Subscription;

  double flow1TotalLiters = 0;
  double flow2TotalLiters = 0;
  double flow1TotalBill = 0;
  double flow2TotalBill = 0;
  double flow1PricePerLiter = 1.5;
  double flow2PricePerLiter = 2.0;
  int _selectedTab = 0;
  final List<String> _tabs = ['Daily', 'Weekly', 'Monthly'];

  double _waterRate = 0.05; // Default water rate per liter (in rupees)
  double _currentBill = 0.0;
  DateTime _billingCycleStart = DateTime.now();
  int _daysRemaining = 30;
  List<double> _monthlyUsageData = [];
  List<Map<String, dynamic>> _flatData = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutQuart,
      ),
    );

    _controller.forward();
    _initializeData();
    _setupFirebaseListeners();
  }
  void _setupFirebaseListeners() {
    _flow1Subscription = FirebaseService.getFlow1Data().listen((data) {
      setState(() {
        flow1TotalLiters = data['total_liters'] ?? 0;
        flow1TotalBill = data['total_bill'] ?? 0;
        flow1PricePerLiter = data['price_per_liter'] ?? 1.5;
      });
    });

    _flow2Subscription = FirebaseService.getFlow2Data().listen((data) {
      setState(() {
        flow2TotalLiters = data['total_liters'] ?? 0;
        flow2TotalBill = data['total_bill'] ?? 0;
        flow2PricePerLiter = data['price_per_liter'] ?? 2.0;
      });
    });
  }

  @override
  void dispose() {
    _flow1Subscription?.cancel();
    _flow2Subscription?.cancel();
    super.dispose();
  }
  void _initializeData() {
    final now = DateTime.now();
    _billingCycleStart = DateTime(now.year, now.month, 1);
    _daysRemaining = DateTime(now.year, now.month + 1, 1).difference(now).inDays;

    // Initialize with random data for demo (in a real app, this would come from IoT sensors)
    final random = Random();
    _monthlyUsageData = List.generate(30, (index) {
      if (index > now.day) return 0.0; // Future days
      return index == now.day ? 0.0 : 50 + random.nextDouble() * 30;
    });

    // Initialize flat comparison data
    _initializeFlatData();

    // Calculate current bill
    _calculateCurrentBill();
  }

  void _initializeFlatData() {
    final random = Random();
    _flatData = [
      {
        'name': 'Flat 1',
        'usage': 2150,
        'bill': 2150 * _waterRate,
        'color': const Color(0xFF00A8E8),
        'paid': true,
        'dailyUsage': List.generate(30, (i) => (50 + random.nextInt(30)).toDouble()), // Convert to double
      },
      {
        'name': 'Flat 2', // Current user's flat
        'usage': _monthlyUsageData.where((e) => e > 0).reduce((a, b) => a + b).round(),
        'bill': (_monthlyUsageData.where((e) => e > 0).reduce((a, b) => a + b) * _waterRate),
        'color': Colors.orange,
        'paid': true,
        'dailyUsage': _monthlyUsageData,
      },
      {
        'name': 'Flat 3',
        'usage': 2450,
        'bill': 2450 * _waterRate,
        'color': Colors.green,
        'paid': false,
        'dailyUsage': List.generate(30, (i) => (60 + random.nextInt(35)).toDouble()), // Convert to double
      },
      {
        'name': 'Flat 4',
        'usage': 1950,
        'bill': 1950 * _waterRate,
        'color': Colors.purple,
        'paid': true,
        'dailyUsage': List.generate(30, (i) => (45 + random.nextInt(30)).toDouble()), // Convert to double
      },
    ];

    // Sort by usage (ascending - lower usage is better)
    _flatData.sort((a, b) => (a['usage'] as int).compareTo(b['usage'] as int));
  }

  void _calculateCurrentBill() {
    final totalUsage = _monthlyUsageData.where((e) => e > 0).reduce((a, b) => a + b);
    _currentBill = totalUsage * _waterRate;
  }

  void _updateWaterRate(double newRate) {
    setState(() {
      _waterRate = newRate;
      _calculateCurrentBill();
      _initializeFlatData();
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Usage Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TimePeriodSelector(
                      selectedTab: _selectedTab,
                      tabs: _tabs,
                      onTabChanged: (index) {
                        setState(() {
                          _selectedTab = index;
                          _controller.reset();
                          _controller.forward();
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildWaterUsageChart(),
                    const SizedBox(height: 30),
                    ConsumptionStats(
                      totalUsage: _getTotalUsage(),
                      averageUsage: _getAverageUsage(),
                      peakUsage: _getPeakUsage(),
                    ),
                    const SizedBox(height: 20),
                    BillingInfoCard(
                      currentBill: flow1TotalBill + flow2TotalBill,
                      billingCycleStart: _billingCycleStart,
                      daysRemaining: _daysRemaining,
                      waterRate: flow1PricePerLiter, // or average if needed
                      daysWithUsage: _monthlyUsageData.where((e) => e > 0).length,
                      flow1TotalBill: flow1TotalBill,
                      flow2TotalBill: flow2TotalBill,
                    ),
                    const SizedBox(height: 20),
                    FlatUsageComparison(
                      flatData: _flatData,
                      onViewDetails: _showMonthlyDetails,
                      flow1TotalLiters: flow1TotalLiters,
                      flow2TotalLiters: flow2TotalLiters,
                      flow1TotalBill: flow1TotalBill,
                      flow2TotalBill: flow2TotalBill,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showWaterRateDialog(),
        backgroundColor: const Color(0xFF00A8E8),
        child: const Icon(Icons.edit, color: Colors.white),
        tooltip: 'Set Water Rate',
      ),
    );
  }

  void _showWaterRateDialog() {
    final rateController = TextEditingController(text: _waterRate.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Water Rate'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: rateController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Price per liter (₹)',
                  prefixText: '₹',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Current rate: ₹$_waterRate/L',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newRate = double.tryParse(rateController.text) ?? _waterRate;
                if (newRate >= 0) {
                  _updateWaterRate(newRate);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A8E8),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWaterUsageChart() {
    final data = _getChartData();

    return AspectRatio(
      aspectRatio: 1.7,
      child: Card(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Water Consumption',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getTimeRangeText(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _getXAxisLabel(value.toInt()),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                          reservedSize: 28,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}L',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            );
                          },
                          reservedSize: 32,
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: data.isEmpty ? 1 : data.length - 1.toDouble(),
                    minY: 0,
                    maxY: data.isEmpty ? 100 : data.reduce(max).toDouble() * 1.2,
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(data.length, (index) {
                          return FlSpot(index.toDouble(), data[index]);
                        }),
                        isCurved: true,
                        color: const Color(0xFF00A8E8),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF00A8E8).withOpacity(0.3),
                              const Color(0xFF00A8E8).withOpacity(0.1),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: const Color(0xFF00A8E8),
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<double> _getChartData() {
    final random = Random(DateTime.now().day);
    switch (_selectedTab) {
      case 0: // Daily
        return List.generate(24, (index) => 20 + random.nextDouble() * 80);
      case 1: // Weekly
        return List.generate(7, (index) => 100 + random.nextDouble() * 200);
      case 2: // Monthly
        return _monthlyUsageData.where((e) => e > 0).toList();
      default:
        return List.generate(7, (index) => 100 + random.nextDouble() * 200);
    }
  }

  String _getTimeRangeText() {
    final now = DateTime.now();
    switch (_selectedTab) {
      case 0: // Daily
        return DateFormat('MMMM d, y').format(now);
      case 1: // Weekly
        final start = now.subtract(const Duration(days: 6));
        return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d, y').format(now)}';
      case 2: // Monthly
        return '${DateFormat('MMM d').format(_billingCycleStart)} - ${DateFormat('MMM d, y').format(now)}';
      default:
        return DateFormat('MMMM d, y').format(now);
    }
  }

  String _getXAxisLabel(int index) {
    switch (_selectedTab) {
      case 0: // Daily
        return '$index:00';
      case 1: // Weekly
        return DateFormat('E').format(DateTime.now().subtract(Duration(days: 6 - index)));
      case 2: // Monthly
        return '${index + 1}';
      default:
        return '$index';
    }
  }

  int _getTotalUsage() {
    final data = _getChartData();
    return data.isEmpty ? 0 : data.reduce((a, b) => a + b).round();
  }

  int _getAverageUsage() {
    final data = _getChartData();
    return data.isEmpty ? 0 : (data.reduce((a, b) => a + b) / data.length).round();
  }

  int _getPeakUsage() {
    final data = _getChartData();
    return data.isEmpty ? 0 : data.reduce(max).round();
  }

  void _showMonthlyDetails(List<Map<String, dynamic>> flatData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Monthly Usage Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: flatData.length,
                  itemBuilder: (context, index) {
                    final flat = flatData[index];
                    final isCurrentUser = flat['name'] == 'Flat 2';
                    final dailyUsage = (flat['dailyUsage'] as List).map((e) => e.toDouble()).toList();
                    final maxY = dailyUsage.isNotEmpty
                        ? dailyUsage.reduce((a, b) => a > b ? a : b) * 1.2
                        : 100.0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: flat['color'] as Color,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            flat['name'] as String,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: isCurrentUser ? const Color(0xFF00A8E8) : Colors.black,
                                            ),
                                          ),
                                          if (isCurrentUser)
                                            const Padding(
                                              padding: EdgeInsets.only(left: 4),
                                              child: Icon(Icons.person, size: 16, color: Color(0xFF00A8E8)),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Total Usage: ${flat['usage']}L',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            'Bill: ₹${(flat['bill'] as double).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 150,
                              child: LineChart(
                                LineChartData(
                                  gridData: const FlGridData(show: false),
                                  titlesData: const FlTitlesData(show: false),
                                  borderData: FlBorderData(show: false),
                                  minX: 0,
                                  maxX: dailyUsage.length > 0 ? dailyUsage.length - 1.toDouble() : 1,
                                  minY: 0,
                                  maxY: maxY,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: dailyUsage.asMap().entries.map((e) {
                                        return FlSpot(e.key.toDouble(), e.value);
                                      }).toList(),
                                      isCurved: true,
                                      color: flat['color'] as Color,
                                      barWidth: 2,
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: (flat['color'] as Color).withOpacity(0.1),
                                      ),
                                      dotData: const FlDotData(show: false),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Daily Consumption',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (flat['paid'] as bool)
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    (flat['paid'] as bool) ? 'PAID' : 'PENDING',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: (flat['paid'] as bool) ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}