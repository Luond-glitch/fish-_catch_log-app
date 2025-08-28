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
      });
    } catch (e) {
      print('Error loading statistics: $e');
      setState(() {
        _isLoading = false;
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

  /// Generate bottom labels (dates)
  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    final style = const TextStyle(fontSize: 10);

    if (value.toInt() < 0 || value.toInt() >= _dailyStats.length) {
      return const SizedBox.shrink();
    }

    final date = _dailyStats[value.toInt()].date;
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(DateFormat('MM/dd').format(date), style: style),
    );
  }

  /// Generate left labels (weights)
  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    return Text('${value.toInt()}kg',
        style: const TextStyle(fontSize: 10), textAlign: TextAlign.left);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fishing Statistics'),
        backgroundColor: Colors.deepOrange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      /// Line Chart with fl_chart
                      Expanded(
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: true),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32,
                                  getTitlesWidget: _bottomTitleWidgets,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: _leftTitleWidgets,
                                  reservedSize: 40,
                                ),
                              ),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(color: Colors.grey),
                            ),
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
                                dotData: FlDotData(show: true),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      const Text(
                        'Daily Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                                leading: const Icon(Icons.calendar_today,
                                    color: Colors.deepOrange),
                                title: Text(
                                    DateFormat('MMM dd, yyyy').format(stat.date)),
                                trailing: Text(
                                  '${stat.totalWeight} kg',
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
