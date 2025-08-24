import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in anonymously and store user data
  Future<User?> signInAnonymously(String username, String boatNumber) async {
    try {
      // Sign in anonymously
      UserCredential result = await _auth.signInAnonymously();
      User user = result.user!;

      // Store user data in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'username': username,
        'boatNumber': boatNumber,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return user;
    } catch (e) {
      return null;
    }
  }

  // Check if boat number is already registered
  Future<bool> isBoatNumberRegistered(String boatNumber) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('boatNumber', isEqualTo: boatNumber)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
