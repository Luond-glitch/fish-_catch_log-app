import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class WeeklyReportsScreen extends StatefulWidget {
  final String username;
  final String boatNumber;

  const WeeklyReportsScreen({
    super.key,
    required this.username,
    required this.boatNumber,
  });

  @override
  State<WeeklyReportsScreen> createState() => _WeeklyReportsScreenState();
}

class _WeeklyReportsScreenState extends State<WeeklyReportsScreen> {
  List<DailyCatchData> _catchData = [];
  List<CatchDetail> _catchDetails = [];
  bool _isLoading = true;
  DateTimeRange? _selectedDateRange;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _selectedDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    );
    _loadCatchData();
  }

  Future<void> _loadCatchData() async {
    setState(() => _isLoading = true);
    
    try {
      if (_user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to view reports')),
        );
        return;
      }

      // Query Firestore for catches in the selected date range
      final QuerySnapshot querySnapshot = await _firestore
          .collection('catches')
          .where('userId', isEqualTo: _user.uid)
          .where('date', isGreaterThanOrEqualTo: _selectedDateRange!.start)
          .where('date', isLessThanOrEqualTo: _selectedDateRange!.end)
          .orderBy('date', descending: false)
          .get();

      // Process the data for the chart
      final Map<DateTime, List<CatchDetail>> catchesByDate = {};
      final List<CatchDetail> allCatches = [];
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final date = (data['date'] as Timestamp).toDate();
        final catchDetail = CatchDetail(
          date: date,
          fishType: data['fishType'] ?? 'Unknown',
          weight: data['weight']?.toString() ?? '0',
          length: data['length']?.toString() ?? '0',
          location: data['location'] ?? 'Unknown',
          notes: data['notes'] ?? '',
        );
        
        allCatches.add(catchDetail);
        
        // Group by date
        final dateOnly = DateTime(date.year, date.month, date.day);
        if (!catchesByDate.containsKey(dateOnly)) {
          catchesByDate[dateOnly] = [];
        }
        catchesByDate[dateOnly]!.add(catchDetail);
      }
      
      // Convert to DailyCatchData for the chart
      final List<DailyCatchData> chartData = [];
      catchesByDate.forEach((date, catches) {
        final totalWeight = catches.fold(0.0, (total, catchDetail) {
          return total + double.parse(catchDetail.weight);
        });
        
        chartData.add(DailyCatchData(
          date, 
          catches.length, 
          totalWeight,
        ));
      });
      
      // Sort by date
      chartData.sort((a, b) => a.date.compareTo(b.date));
      allCatches.sort((a, b) => b.date.compareTo(a.date)); // Most recent first

      setState(() {
        _catchData = chartData;
        _catchDetails = allCatches;
        _isLoading = false;
      });
    } catch (e) {
     if(mounted){ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
      setState(() => _isLoading = false);
    }
    } 
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    
    if (picked != null && picked != _selectedDateRange) {
      setState(() => _selectedDateRange = picked);
      _loadCatchData(); // Reload data with new date range
    }
  }

  Future<void> _exportToCSV() async {
    final status = await Permission.storage.request();
    if (!status.isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission is required to export reports')),
      );
      return;
    }

    try {
      // Create CSV data
      final List<List<dynamic>> csvData = [];
      
      // Add header
      csvData.add(['Date', 'Catch Count', 'Total Weight (kg)']);
      
      // Add data rows
      for (var data in _catchData) {
        csvData.add([
          DateFormat('yyyy-MM-dd').format(data.date),
          data.catchCount,
          data.totalWeight.toStringAsFixed(2),
        ]);
      }
      
      // Add catch details header
      csvData.add([]);
      csvData.add(['Detailed Catch Report']);
      csvData.add(['Date', 'Fish Type', 'Weight (kg)', 'Length (cm)', 'Location', 'Notes']);
      
      // Add catch details rows
      for (var detail in _catchDetails) {
        csvData.add([
          DateFormat('yyyy-MM-dd').format(detail.date),
          detail.fishType,
          detail.weight,
          detail.length,
          detail.location,
          detail.notes,
        ]);
      }
      
      // Convert to CSV string
      final String csv = const ListToCsvConverter().convert(csvData);
      
      // Get directory for saving
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;
      final fileName = 'SamakiLog_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('$path/$fileName');
      
      // Write file
      await file.writeAsString(csv);
      
      // Share file
      await Share.shareXFiles([XFile(file.path)], text: 'Samakillog Weekly Report');
      
      if (mounted) {ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report exported to $fileName')),
      );
      }
    } catch (e) {
      if(mounted) {ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting CSV: $e')),
      );
    }
    }
  }

  Future<void> _exportToPDF() async {
    // PDF export implementation would go here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF export functionality coming soon!')),
    );
  }

  // Helper method to format x-axis labels
  String getDayLabel(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Reports'),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDateRange(context),
            tooltip: 'Select Date Range',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCatchData,
            tooltip: 'Refresh Data',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'csv') {
                _exportToCSV();
              } else if (value == 'pdf') {
                _exportToPDF();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'csv',
                child: Text('Export to CSV'),
              ),
              const PopupMenuItem<String>(
                value: 'pdf',
                child: Text('Export to PDF'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _catchData.isEmpty
            ? const Center(child: Text('No catch data available for the selected period'))
            : Column(
                children: [
                  // Date range selector
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Date Range:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '${DateFormat('MMM d, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM d, yyyy').format(_selectedDateRange!.end)}',
                          style: const TextStyle(color: Colors.deepOrange),
                        ),
                      ],
                    ),
                  ),
                  
                  // Summary cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        _buildSummaryCard(
                          'Total Catches',
                          _catchData.fold(0, (total, item) => total + item.catchCount).toString(),
                          Icons.assignment,
                          Colors.blue,
                        ),
                        const SizedBox(width: 10),
                        _buildSummaryCard(
                          'Total Weight',
                          '${_catchData.fold(0.0, (total, item) => total + item.totalWeight).toStringAsFixed(1)} kg',
                          Icons.scale,
                          Colors.green,
                        ),
                      ],
                    ),
                  ),
                  
                  // Chart
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() < _catchData.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        getDayLabel(_catchData[value.toInt()].date),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                                reservedSize: 32,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                                reservedSize: 32,
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                                reservedSize: 32,
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                          minX: 0,
                          maxX: _catchData.length.toDouble() - 1,
                          minY: 0,
                          maxY: _catchData.map((e) => e.catchCount.toDouble()).reduce((a, b) => a > b ? a : b) * 1.1,
                          lineBarsData: [
                            // Catch count bars
                            LineChartBarData(
                              spots: _catchData.asMap().entries.map((entry) {
                                return FlSpot(entry.key.toDouble(), entry.value.catchCount.toDouble());
                              }).toList(),
                              isCurved: false,
                              color: Colors.blue,
                              barWidth: 4,
                              isStrokeCapRound: true,
                              belowBarData: BarAreaData(show: false),
                              dotData: FlDotData(show: true),
                            ),
                            // Total weight line
                            LineChartBarData(
                              spots: _catchData.asMap().entries.map((entry) {
                                return FlSpot(entry.key.toDouble(), entry.value.totalWeight);
                              }).toList(),
                              isCurved: true,
                              color: Colors.red,
                              barWidth: 4,
                              isStrokeCapRound: true,
                              belowBarData: BarAreaData(show: false),
                              dotData: FlDotData(show: true),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Legend
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem(Colors.blue, 'Catch Count'),
                        const SizedBox(width: 16),
                        _buildLegendItem(Colors.red, 'Total Weight (kg)'),
                      ],
                    ),
                  ),
                  
                  // Detailed catches section
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Recent Catches',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  
                  Expanded(
                    flex: 1,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _catchDetails.length,
                      itemBuilder: (context, index) {
                        final catchDetail = _catchDetails[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.waves, color: Colors.deepOrange),
                            title: Text(catchDetail.fishType),
                            subtitle: Text(
                              '${catchDetail.weight} kg, ${catchDetail.length} cm',
                            ),
                            trailing: Text(DateFormat('MMM d').format(catchDetail.date)),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(catchDetail.fishType),
                                  content: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Weight: ${catchDetail.weight} kg'),
                                      Text('Length: ${catchDetail.length} cm'),
                                      Text('Location: ${catchDetail.location}'),
                                      if (catchDetail.notes.isNotEmpty)
                                        Text('Notes: ${catchDetail.notes}'),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(title, style: TextStyle(color: color, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(
                color: color, 
                fontSize: 16, 
                fontWeight: FontWeight.bold,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class DailyCatchData {
  final DateTime date;
  final int catchCount;
  final double totalWeight;

  DailyCatchData(this.date, this.catchCount, this.totalWeight);
}

class CatchDetail {
  final DateTime date;
  final String fishType;
  final String weight;
  final String length;
  final String location;
  final String notes;

  CatchDetail({
    required this.date,
    required this.fishType,
    required this.weight,
    required this.length,
    required this.location,
    required this.notes,
  });
}