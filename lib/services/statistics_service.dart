import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_statistics.dart';

class StatisticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get daily statistics for a user
  Future<List<DailyStatistics>> getDailyStatistics(String userId) async {
    // Get catches for the user
    final querySnapshot = await _firestore
        .collection('catches')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: false)
        .get();

    // Group catches by date
    Map<String, List<DocumentSnapshot>> catchesByDate = {};
    
for (var doc in querySnapshot.docs) {
  final catchData = doc.data(); // Removed the cast
  final date = (catchData['date'] as Timestamp).toDate();
  final dateKey = '${date.year}-${date.month}-${date.day}';
  
  if (!catchesByDate.containsKey(dateKey)) {
    catchesByDate[dateKey] = [];
  }
  catchesByDate[dateKey]!.add(doc);
}

    // Calculate daily totals
    List<DailyStatistics> dailyStats = [];
    
    catchesByDate.forEach((dateKey, catches) {
      double totalWeight = 0;
      
      for (var catchDoc in catches) {
        final catchData = catchDoc.data() as Map<String, dynamic>;
        totalWeight += (catchData['weight'] as num).toDouble();
      }
      
      // Parse date from dateKey
      final parts = dateKey.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      
      dailyStats.add(DailyStatistics(
        date: date,
        totalWeight: totalWeight,
        catchCount: catches.length,
      ));
    });
    
    // Sort by date
    dailyStats.sort((a, b) => a.date.compareTo(b.date));
    
    return dailyStats;
  }

  // Get statistics for a date range
  Future<List<DailyStatistics>> getDateRangeStatistics(
    String userId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    final allStats = await getDailyStatistics(userId);
    return allStats.where((stat) => 
      stat.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
      stat.date.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();
  }
}