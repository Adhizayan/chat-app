import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Get current user ID
  static String get currentUserId => _auth.currentUser?.uid ?? '';

  // Get auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  static Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    String? phoneNumber,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(displayName);

      // Get FCM token
      String? fcmToken = await _messaging.getToken();

      // Create user document in Firestore
      UserModel userModel = UserModel(
        id: userCredential.user!.uid,
        email: email,
        displayName: displayName,
        phoneNumber: phoneNumber,
        isOnline: true,
        lastSeen: DateTime.now(),
        createdAt: DateTime.now(),
        fcmToken: fcmToken,
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userModel.toMap());

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Sign in with email and password
  static Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update FCM token and online status
      await _updateUserOnlineStatus(true);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      // Update offline status
      await _updateUserOnlineStatus(false);
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Update user profile
  static Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
    String? phoneNumber,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Update Firebase Auth profile
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      // Update Firestore document
      Map<String, dynamic> updateData = {};
      if (displayName != null) updateData['displayName'] = displayName;
      if (photoURL != null) updateData['photoURL'] = photoURL;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;

      if (updateData.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .update(updateData);
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Get user data from Firestore
  static Future<UserModel?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserModel.fromDocumentSnapshot(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Update user online status
  static Future<void> _updateUserOnlineStatus(bool isOnline) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) return;

      Map<String, dynamic> updateData = {
        'isOnline': isOnline,
        'lastSeen': Timestamp.now(),
      };

      if (isOnline) {
        String? fcmToken = await _messaging.getToken();
        if (fcmToken != null) {
          updateData['fcmToken'] = fcmToken;
        }
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .update(updateData);
    } catch (e) {
      print('Failed to update online status: $e');
    }
  }

  // Update FCM token
  static Future<void> updateFCMToken() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) return;

      String? fcmToken = await _messaging.getToken();
      if (fcmToken != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .update({'fcmToken': fcmToken});
      }
    } catch (e) {
      print('Failed to update FCM token: $e');
    }
  }

  // Search users by email
  static Future<List<UserModel>> searchUsersByEmail(String email) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(10)
          .get();

      return query.docs
          .map((doc) => UserModel.fromDocumentSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  // Get users by phone numbers (for contact sync)
  static Future<List<UserModel>> getUsersByPhoneNumbers(List<String> phoneNumbers) async {
    try {
      if (phoneNumbers.isEmpty) return [];

      QuerySnapshot query = await _firestore
          .collection('users')
          .where('phoneNumber', whereIn: phoneNumbers)
          .get();

      return query.docs
          .map((doc) => UserModel.fromDocumentSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get users by phone numbers: $e');
    }
  }

  // Handle authentication exceptions
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }

  // Initialize app lifecycle listeners
  static void initializeAppLifecycleListeners() {
    // This would be called in main.dart to handle app state changes
    // Update online status when app goes to background/foreground
  }
}
