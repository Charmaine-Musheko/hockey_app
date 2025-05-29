import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage
import 'package:hockey_union_app/services/fcm_service.dart';
import 'dart:io'; // Required for File class

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance; // Initialize Firebase Storage
  final FcmService _fcmService = FcmService();

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
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        await _fcmService.saveTokenToFirestore(fcmToken);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Error during Sign In: ${e.code} - ${e.message}");
      return null;
    } catch (e) {
      print("General Error during Sign In: ${e.toString()}");
      return null;
    }
  }

  // Sign up with email and password AND create user document in Firestore
  Future<User?> signUpWithEmailAndPassword(
      String email,
      String password,
      String firstName,
      String lastName,
      String requestedRole,
      String roleReason,
      File? profileImage, // New parameter for profile image
      ) async {
    try {
      UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      if (user != null) {
        String? profileImageUrl;
        if (profileImage != null) {
          // Upload image to Firebase Storage
          final ref = _firebaseStorage
              .ref()
              .child('user_profile_images')
              .child('${user.uid}.jpg'); // Unique path for each user's profile image

          await ref.putFile(profileImage);
          profileImageUrl = await ref.getDownloadURL(); // Get download URL
        }

        // Create a new document for the user in the 'users' collection
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'firstName': firstName,
          'lastName': lastName,
          'role': 'Fan', // Default role for new registrations
          'profileImageUrl': profileImageUrl, // Save the image URL
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (requestedRole != 'Fan') {
          await _firestore.collection('roleRequests').add({
            'userId': user.uid,
            'email': user.email,
            'firstName': firstName,
            'lastName': lastName,
            'requestedRole': requestedRole,
            'roleReason': roleReason,
            'status': 'Pending',
            'requestDate': FieldValue.serverTimestamp(),
          });
          print('Role upgrade request submitted for ${user.email} to $requestedRole');
        }

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

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      } else {
        print('User document not found for uid: $uid');
        return null;
      }
    } catch (e) {
      print("Error getting user data: ${e.toString()}");
      return null;
    }
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Error sending password reset email: ${e.code} - ${e.message}");
      return e.code;
    } catch (e) {
      print("General Error sending password reset email: ${e.toString()}");
      return 'unknown-error';
    }
  }

  Future<void> signOut() async {
    try {
      return await _firebaseAuth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}
