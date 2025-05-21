import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Import Firebase Messaging
import 'package:hockey_union_app/services/fcm_service.dart'; // Import the new FcmService


class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FcmService _fcmService = FcmService(); // Create an instance of FcmService


  // Get the current user
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      if (user != null) {
        // User signed in successfully, get and save FCM token using FcmService
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        await _fcmService.saveTokenToFirestore(fcmToken); // Use the new service
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Error during Sign In: ${e.code} - ${e.message}");
      return null; // Return null on error
    } catch (e) {
      print("General Error during Sign In: ${e.toString()}");
      return null; // Return null on error
    }
  }

  // Sign up with email and password AND create user document in Firestore
  // Updated to accept firstName, lastName, desiredRole, and roleReason
  Future<User?> signUpWithEmailAndPassword(String email, String password, String firstName, String lastName, String desiredRole, String roleReason) async {
    try {
      UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      if (user != null) {
        // Create a new document for the user in the 'users' collection
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'firstName': firstName, // Save first name
          'lastName': lastName,   // Save last name
          'role': 'Fan',           // Default to 'Fan' role, admin approval needed for others
          'desiredRole': desiredRole, // Save desired role
          'roleReason': roleReason, // Save reason for desired role
          'createdAt': FieldValue.serverTimestamp(),
        });

        // User signed up successfully, get and save FCM token using FcmService
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        await _fcmService.saveTokenToFirestore(fcmToken); // Use the new service
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Error during Sign Up: ${e.code} - ${e.message}");
      return null; // Return null on error
    } catch (e) {
      print("General Error during Sign Up: ${e.toString()}");
      return null; // Return null on error
    }
  }

  // Add a method to get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      } else {
        print('User document not found for uid: $uid on first attempt. Retrying...');
        // Add a small delay and retry once
        await Future.delayed(Duration(seconds: 1)); // Wait for 1 second
        doc = await _firestore.collection('users').doc(uid).get();
        if (doc.exists) {
          print('User document found on retry for uid: $uid');
          return doc.data() as Map<String, dynamic>?;
        } else {
          print('User document still not found for uid: $uid after retry.');
          return null;
        }
      }
    } catch (e) {
      print("Error getting user data: ${e.toString()}");
      return null;
    }
  }

  // Method to send password reset email
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return null; // Return null on success
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Error sending password reset email: ${e.code} - ${e.message}");
      return e.code; // Return error code on failure
    } catch (e) {
      print("General Error sending password reset email: ${e.toString()}");
      return 'unknown-error'; // Return a generic error code
    }
  }


  // Sign out
  Future<void> signOut() async {
    try {
      // Optional: Consider removing the FCM token from Firestore on sign out
      // This prevents sending notifications to a device after the user logs out.
      // However, if the user has multiple devices logged in, you'd only want to remove
      // the token for the device that is signing out. This requires more complex token management.
      // For now, we'll leave tokens in place on sign out.

      return await _firebaseAuth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Auth state changes stream
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}
