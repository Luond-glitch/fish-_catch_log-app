import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Helper: generate pseudo email
  String _makeEmail(String username, String boatNumber) {
    return "${username}_${boatNumber}@samaki.com".toLowerCase();
  }

  // Create account
  Future<User?> createAccount(
    String username,
    String phoneNumber,
    String boatNumber,
  ) async {
    try {
      final email = _makeEmail(username, boatNumber);
      final password = boatNumber; 

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'username': username,
          'phoneNumber': phoneNumber,
          'boatNumber': boatNumber,
          'createdAt': FieldValue.serverTimestamp(),
          'userId': user.uid,
        });
      }

      return user;
    } catch (e) {
      return null;
    }
  }

  // Sign in with username + boat number
  Future<User?> signInWithUsername(String username, String boatNumber) async {
    try {
      final email = _makeEmail(username, boatNumber);
      final password = boatNumber;

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return result.user;
    } catch (e) {
      return null;
    }
  }

  // Check if boat number exists
  Future<bool> isBoatNumberRegistered(String boatNumber) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('boatNumber', isEqualTo: boatNumber)
        .limit(1)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  // Check if username exists
  Future<bool> isUsernameRegistered(String username) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  // Get user data by uid
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
