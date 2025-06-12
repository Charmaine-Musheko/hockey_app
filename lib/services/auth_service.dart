import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Import Firebase Messaging
import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage
import 'package:hockey_union_app/services/fcm_service.dart'; // Import the new FcmService
import 'dart:io'; // Required for File class


class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance; // Instance for Storage
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
  Future<User?> signUpWithEmailAndPassword(
      String email,
      String password,
      String firstName,
      String lastName,
      String desiredRole, // This is the role the user *requested*
      String roleReason,
      File? profileImage,
      ) async {
    try {
      UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      if (user != null) {
        String? profileImageUrl;
        if (profileImage != null) {
          final ref = _firebaseStorage
              .ref()
              .child('user_profile_images')
              .child('${user.uid}.jpg');

          await ref.putFile(profileImage);
          profileImageUrl = await ref.getDownloadURL();
        }

        // Create the user's primary document in the 'users' collection
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'firstName': firstName,
          'lastName': lastName,
          'role': 'Fan', // IMPORTANT: User is *always* initially a 'Fan'
          'desiredRole': desiredRole, // Store the requested role
          'roleReason': roleReason,   // Store the reason for the requested role
          'profileImageUrl': profileImageUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // --- THIS IS THE ADDED LOGIC FOR ROLE REQUESTS ---
        // If the user requested a role other than 'Fan', create a role request
        if (desiredRole != 'Fan') {
          await _firestore.collection('roleRequests').add({
            'userId': user.uid,
            'email': user.email,
            'firstName': firstName,
            'lastName': lastName,
            'requestedRole': desiredRole, // Use desiredRole for the request
            'roleReason': roleReason,
            'status': 'Pending', // Status is 'Pending' for admin review
            'requestDate': FieldValue.serverTimestamp(),
          });
          print('Role upgrade request submitted for ${user.email} to $desiredRole');
        }
        // --------------------------------------------------

        String? fcmToken = await FirebaseMessaging.instance.getToken();
        await _fcmService.saveTokenToFirestore(fcmToken);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Error during Sign Up: ${e.code} - ${e.message}");
      return null;
    } catch (e) {
      print("General Error during Sign Up: ${e.toString()}");
      return null;
    }
  }

  // --- THIS IS THE CRUCIAL CHANGE: THIS REPLACES YOUR OLD FUTURE-BASED getUserData ---
  // It provides a stream that the Wrapper will listen to.
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserDataStream(String uid) {
    // .snapshots() returns a stream that emits a new DocumentSnapshot
    // every time the document changes (or is created/deleted).
    return _firestore.collection('users').doc(uid).snapshots();
  }
  // ----------------------------------------------------------------------------------

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
      return await _firebaseAuth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Auth state changes stream
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}