import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get the current user
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  // Sign in with email and password
  // We can add specific error handling here later too if needed
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) { // Catch specific Firebase Auth exceptions
      print("Firebase Auth Error during Sign In: ${e.code} - ${e.message}");
      // Return null, and the AuthScreen will handle displaying a generic error
      // Or you could return e.code to handle specific messages in the UI
      return null;
    } catch (e) {
      print("General Error during Sign In: ${e.toString()}");
      return null;
    }
  }

  // Sign up with email and password AND create user document in Firestore
  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      if (user != null) {
        // Create a new document for the user in the 'users' collection
        // Use the user's UID as the document ID
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'role': 'Fan', // Assign a default role, e.g., 'Fan'
          'createdAt': FieldValue.serverTimestamp(),
          // You can add other initial fields here (e.g., name, etc.)
        });
      }

      return user;
    } on FirebaseAuthException catch (e) { // Catch specific Firebase Auth exceptions
      print("Firebase Auth Error during Sign Up: ${e.code} - ${e.message}");
      // Return the error code so the UI can display a specific message
      // Or you could return a custom string based on the code
      // For now, let's return null and handle messaging in AuthScreen
      // return e.code; // Option 1: Return code
      return null; // Option 2: Return null, handle message in UI based on error type
    } catch (e) {
      print("General Error during Sign Up: ${e.toString()}");
      return null;
    }
  }

  // Add a method to get user data from Firestore
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
