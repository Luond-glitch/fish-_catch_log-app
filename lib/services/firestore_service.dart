import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a fish catch to Firestore
  Future<void> addFishCatch({
    required String userId,
    required String species,
    required double weight,
    required String location,
    required DateTime date,
    required String boatNumber,
    String notes = '',
  }) async {
    try {
      await _firestore.collection('catches').add({
        'userId': userId,
        'species': species,
        'weight': weight,
        'location': location,
        'date': Timestamp.fromDate(date),
        'boatNumber': boatNumber,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get all fish catches for a user
  Stream<QuerySnapshot> getUserCatches(String userId) {
    return _firestore
        .collection('catches')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots();
  }

  // Get all fish catches for a boat number
  Stream<QuerySnapshot> getBoatCatches(String boatNumber) {
    return _firestore
        .collection('catches')
        .where('boatNumber', isEqualTo: boatNumber)
        .orderBy('date', descending: true)
        .snapshots();
  }

  // Update a fish catch
  Future<void> updateFishCatch(String catchId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('catches').doc(catchId).update(updates);
    } catch (e) {
      rethrow;
    }
  }

  // Delete a fish catch
  Future<void> deleteFishCatch(String catchId) async {
    try {
      await _firestore.collection('catches').doc(catchId).delete();
    } catch (e) {
      rethrow;
    }
  }
}