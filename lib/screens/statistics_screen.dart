import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/statistics_service.dart';
import '../models/daily_statistics.dart';

class StatisticsScreen extends StatefulWidget {
  final String userId;

  const StatisticsScreen({super.key, required this.userId});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StatisticsService _statsService = StatisticsService();
  List<DailyStatistics> _dailyStats = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await _statsService.getDailyStatistics(widget.userId);
      setState(() {
        _dailyStats = stats;
        _isLoading = false;
        _errorMessage = '';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load statistics: $e';
      });
    }
  }

  /// Convert stats into FlSpot points for the chart
  List<FlSpot> _createSpots() {
    // Sort by date to ensure proper order
    _dailyStats.sort((a, b) => a.date.compareTo(b.date));

    return List.generate(_dailyStats.length, (i) {
      final stat = _dailyStats[i];
      return FlSpot(i.toDouble(), stat.totalWeight.toDouble());
    });
  }

  /// Calculate appropriate Y-axis maximum
  double _calculateMaxY() {
    if (_dailyStats.isEmpty) return 10;
    final maxWeight = _dailyStats
        .map((stat) => stat.totalWeight)
        .reduce((a, b) => a > b ? a : b);
    return (maxWeight * 1.2).toDouble(); // Add 20% padding
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fishing Statistics'),
        backgroundColor: Colors.deepOrange,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage,
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadStatistics,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
          : _dailyStats.isEmpty
          ? const Center(
              child: Text(
                'No catch data available yet.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Catch Weight (kg)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  /// Chart with x-axis and y-axis labels
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          show: true,
                          // Hide top titles
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          // Show y-axis labels with "kg" suffix
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                // Only show labels at major intervals
                                if (value == meta.min ||
                                    value == meta.max ||
                                    value % 5 == 0) {
                                  return Text(
                                    '${value.toInt()} kg',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.black,
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          // Show x-axis labels
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              getTitlesWidget: (value, meta) {
                                // Only show labels for integer values
                                if (value == meta.min ||
                                    value == meta.max ||
                                    value % 1 == 0) {
                                  final index = value.toInt();
                                  if (index >= 0 &&
                                      index < _dailyStats.length) {
                                    return Text(
                                      DateFormat(
                                        'MMM dd',
                                      ).format(_dailyStats[index].date),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.black,
                                      ),
                                    );
                                  }
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        minX: 0,
                        maxX: _dailyStats.length > 1
                            ? (_dailyStats.length - 1).toDouble()
                            : 1,
                        minY: 0,
                        maxY: _calculateMaxY(),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _createSpots(),
                            isCurved: true,
                            color: Colors.deepOrange,
                            barWidth: 3,
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.deepOrange,
                            ),
                            dotData: const FlDotData(show: true),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Daily Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  /// Daily summary list
                  Expanded(
                    child: ListView.builder(
                      itemCount: _dailyStats.length,
                      itemBuilder: (context, index) {
                        final stat = _dailyStats[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: const Icon(
                              Icons.calendar_today,
                              color: Colors.deepOrange,
                            ),
                            title: Text(
                              DateFormat('MMM dd, yyyy').format(stat.date),
                            ),
                            trailing: Text(
                              '${stat.totalWeight.toStringAsFixed(1)} kg',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.deepOrange,
                              ),
                            ),
                            subtitle: Text('${stat.catchCount} catches'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
