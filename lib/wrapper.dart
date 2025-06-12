import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:hockey_union_app/services/auth_service.dart';
import 'package:hockey_union_app/ui/authentication/auth_screen.dart';
import 'package:hockey_union_app/ui/home_screen.dart';

class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AuthService _auth = AuthService();

    return StreamBuilder<User?>(
      stream: _auth.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (authSnapshot.hasData && authSnapshot.data != null) {
          // User is logged in, now fetch their data from Firestore via stream
          String uid = authSnapshot.data!.uid;
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _auth.getUserDataStream(uid), // Listen to the new stream
            builder: (context, userDocSnapshot) {
              if (userDocSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              // Check if the user document exists and has data
              if (userDocSnapshot.hasData && userDocSnapshot.data!.exists) {
                final userData = userDocSnapshot.data!.data(); // Get the data map
                if (userData != null) {
                  final userRole = userData['role'] ?? 'Fan'; // Get the role

                  print('User ${uid} logged in with role: $userRole');
                  return HomeScreen(userId: uid); // Navigate to HomeScreen
                } else {
                  // Document exists but data is null (shouldn't happen often)
                  print("User document exists but data is null for uid: $uid");
                  return const AuthScreen(); // Fallback to AuthScreen
                }
              } else if (userDocSnapshot.hasError) {
                // Handle error fetching user data
                print("Error fetching user data in Wrapper: ${userDocSnapshot.error}");
                return const AuthScreen(); // Fallback to AuthScreen on error
              } else {
                // Document does not exist yet. The StreamBuilder will keep waiting here
                // until the document appears (which it will after successful signup).
                print("User document not found for uid: $uid in stream. Waiting...");
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
            },
          );
        } else {
          // User is not logged in, show the authentication screen
          print('User is logged out or no data');
          return const AuthScreen();
        }
      },
    );
  }
}