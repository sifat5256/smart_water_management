// analysis_widgets.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class TimePeriodSelector extends StatelessWidget {
  final int selectedTab;
  final List<String> tabs;
  final Function(int) onTabChanged;

  const TimePeriodSelector({
    super.key,
    required this.selectedTab,
    required this.tabs,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(tabs.length, (index) {
          return GestureDetector(
            onTap: () => onTabChanged(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selectedTab == index
                    ? const Color(0xFF00A8E8)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tabs[index],
                style: TextStyle(
                  color: selectedTab == index
                      ? Colors.white
                      : Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class BillingInfoCard extends StatelessWidget {
  final double currentBill;
  final DateTime billingCycleStart;
  final int daysRemaining;
  final double waterRate;
  final int daysWithUsage;
  final double flow1TotalBill;
  final double flow2TotalBill;

  const BillingInfoCard({
    super.key,
    required this.currentBill,
    required this.billingCycleStart,
    required this.daysRemaining,
    required this.waterRate,
    required this.daysWithUsage,
    required this.flow1TotalBill,
    required this.flow2TotalBill,
  });

  @override
  Widget build(BuildContext context) {
    final totalBill = flow1TotalBill + flow2TotalBill;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Billing Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${daysRemaining}d left',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Bill',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${totalBill.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$daysWithUsage days of usage',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Flow Rates',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Flow1: ₹${flow1TotalBill.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Flow2: ₹${flow2TotalBill.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rate: ₹$waterRate/L',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: daysWithUsage / 30,
              backgroundColor: Colors.grey.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00A8E8)),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Month Progress',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${((daysWithUsage / 30) * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FlatUsageComparison extends StatelessWidget {
  final List<Map<String, dynamic>> flatData;
  final Function(List<Map<String, dynamic>>) onViewDetails;
  final double flow1TotalLiters;
  final double flow2TotalLiters;
  final double flow1TotalBill;
  final double flow2TotalBill;

  const FlatUsageComparison({
    super.key,
    required this.flatData,
    required this.onViewDetails,
    required this.flow1TotalLiters,
    required this.flow2TotalLiters,
    required this.flow1TotalBill,
    required this.flow2TotalBill,
  });

  @override
  Widget build(BuildContext context) {
    final flats = [
      {
        'name': 'Flow 1',
        'usage': flow1TotalLiters.round(),
        'bill': flow1TotalBill,
        'color': const Color(0xFF00A8E8),
        'paid': true,
      },
      {
        'name': 'Flow 2',
        'usage': flow2TotalLiters.round(),
        'bill': flow2TotalBill,
        'color': Colors.orange,
        'paid': true,
      },
    ];

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Flow Comparison',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: flats.map((flat) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
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
                            Text(
                              flat['name'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: flat['color'] as Color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Usage: ${flat['usage']}L',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Bill: ₹${(flat['bill'] as double).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        backgroundColor: (flat['color'] as Color).withOpacity(0.1),
                        label: Text(
                          '${(flat['usage'] as int).toString()}L',
                          style: TextStyle(
                            color: flat['color'] as Color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.grey.withOpacity(0.2)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Total: ₹${(flow1TotalBill + flow2TotalBill).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ConsumptionStats extends StatelessWidget {
  final int totalUsage;
  final int averageUsage;
  final int peakUsage;

  const ConsumptionStats({
    super.key,
    required this.totalUsage,
    required this.averageUsage,
    required this.peakUsage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context: context,
            title: 'Total Usage',
            value: '${totalUsage}L',
            icon: Icons.water_drop_outlined,
            color: const Color(0xFF00A8E8),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context: context,
            title: 'Avg. Daily',
            value: '${averageUsage}L',
            icon: Icons.timeline,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context: context,
            title: 'Peak Usage',
            value: '${peakUsage}L',
            icon: Icons.flag_outlined,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
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
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}