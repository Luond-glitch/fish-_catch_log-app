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
    return "$username.$boatNumber@samaki.com".toLowerCase();
  }

  // ✅ Create account with boat number uniqueness guarantee
  Future<User?> createAccount(
    String username,
    String phoneNumber,
    String boatNumber,
  ) async {
    try {
      final email = _makeEmail(username, boatNumber);
      final password = boatNumber;

      // Step 1: Check if username already exists
      final usernameQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'username-already-exists',
          message: 'This username is already taken',
        );
      }

      // Step 2: Check if boat number already exists
      final boatNumberDoc = await _firestore
          .collection('users')
          .doc(boatNumber)
          .get();
      if (boatNumberDoc.exists) {
        final data = boatNumberDoc.data();
        // Check if the account is still active
        if (data != null && data['isActive'] != false) {
          throw FirebaseAuthException(
            code: 'boat-number-already-exists',
            message: 'This boat number is already registered by another user',
          );
        }
      }

      // Step 3: Create Firebase Auth account
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // Step 4: Create user document in Firestore
        try {
          await _firestore.collection('users').doc(boatNumber).set({
            'username': username,
            'phoneNumber': phoneNumber,
            'boatNumber': boatNumber,
            'createdAt': FieldValue.serverTimestamp(),
            'userId': user.uid,
            'isActive': true,
          });
        } catch (e) {
          // If Firestore write fails, delete the auth account
          await user.delete();

          throw FirebaseAuthException(
            code: 'firestore-write-failed',
            message: 'Account creation failed. Please try again.',
          );
        }
      }

      return user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  // ✅ Sign in with username + boat number
  Future<User?> signInWithUsername(String username, String boatNumber) async {
    try {
      final email = _makeEmail(username, boatNumber);
      final password = boatNumber;

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return result.user;
    } on FirebaseAuthException catch (e) {
      // Provide more user-friendly error messages
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        throw FirebaseAuthException(
          code: 'invalid-credentials',
          message: 'Invalid username or boat number',
        );
      }

      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  // ✅ Check if boat number exists
  Future<bool> isBoatNumberRegistered(String boatNumber) async {
    try {
      final doc = await _firestore.collection('users').doc(boatNumber).get();
      if (doc.exists) {
        final data = doc.data();
        return data != null && data['isActive'] != false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ✅ Check if username exists
  Future<bool> isUsernameRegistered(String username) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;


    } catch (e) {
      
      return false;
    }
  }


  // ✅ Get user data by boatNumber
  Future<Map<String, dynamic>?> getUserData(String boatNumber) async {
    try {
      final doc = await _firestore.collection('users').doc(boatNumber).get();
      return doc.exists ? doc.data() : null;


    } catch (e) {
     
      return null;
    }
  }

  // ✅ Get user data by UID
  Future<Map<String, dynamic>?> getUserDataByUid(String uid) async {


    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();


      return querySnapshot.docs.isNotEmpty
          ? querySnapshot.docs.first.data()
          : null;
    } catch (e) {
     
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
