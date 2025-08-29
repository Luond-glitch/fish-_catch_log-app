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

  // ✅ Create account (boatNumber as Firestore doc ID for uniqueness)
  Future<User?> createAccount(
    String username,
    String phoneNumber,
    String boatNumber,
  ) async {
    try {
      final email = _makeEmail(username, boatNumber);
      final password = boatNumber;

      print("🔍 Starting account creation for: $username, boat: $boatNumber");
      print("🔍 Generated email: $email");

      // Step 1: Check for username uniqueness first
      print("🔍 Checking username uniqueness...");
      final usernameQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
          
      if (usernameQuery.docs.isNotEmpty) {
        print("❌ Username already exists: $username");
        throw FirebaseAuthException(
          code: 'username-already-exists',
          message: 'This username is already taken',
        );
      }

      // Step 2: Check for boat number uniqueness
      print("🔍 Checking boat number uniqueness...");
      final boatNumberDoc = await _firestore.collection('users').doc(boatNumber).get();
      if (boatNumberDoc.exists) {
        print("❌ Boat number already exists: $boatNumber");
        throw FirebaseAuthException(
          code: 'boat-number-already-exists',
          message: 'This boat number is already registered by another user',
        );
      }

      // Step 3: Create Firebase Auth account
      print("🔍 Creating Firebase Auth account...");
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      print("✅ Firebase Auth account created successfully: ${user?.uid}");

      if (user != null) {
        // Step 4: Create user document in Firestore
        print("🔍 Creating Firestore user document...");
        try {
          await _firestore.collection('users').doc(boatNumber).set({
            'username': username,
            'phoneNumber': phoneNumber,
            'boatNumber': boatNumber,
            'createdAt': FieldValue.serverTimestamp(),
            'userId': user.uid,
          });
          print("✅ Firestore user document created successfully");
        } catch (e) {
          // If Firestore write fails, delete the auth account
          print("❌ Firestore write failed: $e");
          await user.delete();
          print("🗑️ Deleted auth account due to Firestore failure");
          throw FirebaseAuthException(
            code: 'firestore-write-failed',
            message: 'Failed to create user profile. Please try again.',
          );
        }
      }

      // ✅ Return user after successful creation
      print("✅ Account creation completed successfully");
      return user;
    } on FirebaseAuthException catch (e) {
      print("❌ Firebase Auth Error in createAccount: ${e.code} - ${e.message}");
      rethrow;
    } catch (e, stackTrace) {
      print("❌ Unexpected Error in createAccount: $e");
      print("❌ Stack trace: $stackTrace");
      
      // Provide more specific error messages based on the exception type
      if (e is FirebaseException) {
        throw FirebaseAuthException(
          code: e.code,
          message: 'Firebase error: ${e.message}',
        );
      } else if (e.toString().contains('network')) {
        throw FirebaseAuthException(
          code: 'network-error',
          message: 'Network error. Please check your internet connection.',
        );
      } else {
        throw FirebaseAuthException(
          code: 'unknown-error',
          message: 'An unexpected error occurred. Please try again.',
        );
      }
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
      print("❌ Firebase Auth Error in signInWithUsername: ${e.code} - ${e.message}");
      
      // Provide more user-friendly error messages
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        throw FirebaseAuthException(
          code: 'invalid-credentials',
          message: 'Invalid username or boat number',
        );
      }
      
      rethrow;
    } catch (e, stackTrace) {
      print("❌ Error in signInWithUsername: $e");
      print("❌ Stack trace: $stackTrace");
      
      if (e.toString().contains('network')) {
        throw FirebaseAuthException(
          code: 'network-error',
          message: 'Network error. Please check your internet connection.',
        );
      } else {
        throw FirebaseAuthException(
          code: 'unknown-error',
          message: 'An unexpected error occurred. Please try again.',
        );
      }
    }
  }

  // ✅ Check if boat number exists (direct doc lookup now)
  Future<bool> isBoatNumberRegistered(String boatNumber) async {
    try {
      final doc = await _firestore.collection('users').doc(boatNumber).get();
      return doc.exists;
    } catch (e) {
      print("❌ Error checking boat number: $e");
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
      print("❌ Error checking username: $e");
      return false;
    }
  }

  // ✅ Get user data by boatNumber (since it's now the doc ID)
  Future<Map<String, dynamic>?> getUserData(String boatNumber) async {
    try {
      final doc = await _firestore.collection('users').doc(boatNumber).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print("❌ Error getting user data by boat number: $e");
      return null;
    }
  }

  // ✅ Get user data by UID
  Future<Map<String, dynamic>?> getUserDataByUid(String uid) async {
    try {
      // Query the users collection to find the document with the matching userId
      final querySnapshot = await _firestore
          .collection('users')
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      print("❌ Error in getUserDataByUid: $e");
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}