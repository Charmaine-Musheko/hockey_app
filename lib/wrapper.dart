import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

import 'package:hockey_union_app/services/auth_service.dart';

import 'package:hockey_union_app/ui/authentication/auth_screen.dart';
import 'package:hockey_union_app/ui/home_screen.dart';

import 'database/firebase_options.dart';
// Import other screens as needed


// The Wrapper widget now fetches user data from Firestore
class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AuthService _auth = AuthService(); // Get an instance of your AuthService

    // Listen to the Firebase Auth state changes
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges,
      builder: (context, authSnapshot) {
        // If the auth state is waiting (e.g., checking cached login)
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Check if the user is logged in
        if (authSnapshot.hasData && authSnapshot.data != null) {
          // User is logged in, now fetch their data from Firestore
          String uid = authSnapshot.data!.uid;
          return FutureBuilder<Map<String, dynamic>?>(
            future: _auth.getUserData(uid), // Use the getUserData method
            builder: (context, userSnapshot) {
              // If fetching user data is waiting
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              // If there's an error fetching user data or data is null
              if (userSnapshot.hasError || !userSnapshot.hasData || userSnapshot.data == null) {
                print("Error fetching user data in Wrapper: ${userSnapshot.error}"); // Log the error
                // If user data is not found (e.g., deleted from Firestore), redirect to AuthScreen
                // This effectively logs them out from the app's perspective.
                return AuthScreen();
              }

              // User data is successfully fetched
              final userData = userSnapshot.data!;
              final userRole = userData['role'] ?? 'Fan'; // Get the role, default to 'Fan'

              print('User ${uid} logged in with role: $userRole'); // For debugging

              // Now you can pass the user data or role to HomeScreen
              // Option 1: Pass the whole map
              // return HomeScreen(userData: userData);
              // Option 2: Pass just the role
              // return HomeScreen(userRole: userRole);
              // Option 3: Use a state management solution (recommended for larger apps)
              // For now, we'll just show the HomeScreen, assuming HomeScreen
              // might fetch user data itself or you'll pass it later.
              // A better approach is to pass the data here. Let's pass the user ID for now.
              return HomeScreen(userId: uid); // Pass the user ID

            },
          );
        } else {
          // User is not logged in, show the authentication screen
          print('User is logged out'); // For debugging
          return AuthScreen(); // Show your authentication screen
        }
      },
    );
  }
}

// You might need to update your HomeScreen to accept the user ID or user data
/*
class HomeScreen extends StatelessWidget {
  final String? userId; // Accept the user ID
  // final Map<String, dynamic>? userData; // Or accept user data

  const HomeScreen({Key? key, this.userId}) : super(key: key);
  // const HomeScreen({Key? key, this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Now you have the userId (and potentially userData) available in HomeScreen
    // You can use this to fetch more user-specific data or control UI
    // For example, fetch the user document again here if needed:
    // if (userId != null) {
    //   FirebaseFirestore.instance.collection('users').doc(userId).get().then((doc) {
    //      if (doc.exists) {
    //         final role = doc.data()?['role'];
    //         print('Fetched role in HomeScreen: $role');
    //      }
    //   });
    // }


    return Scaffold(
      appBar: AppBar(
        title: Text('Hockey Union Home'),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.logout, color: Colors.white),
            label: Text('Logout', style: TextStyle(color: Colors.white)),
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Welcome to the Hockey Union App!'),
            SizedBox(height: 20),
            // Add your navigation buttons here
            ElevatedButton(
              child: Text('Register a Team'),
              onPressed: () {
                // Navigate to Team Registration Screen
              },
            ),
             SizedBox(height: 10),
             ElevatedButton(
               child: Text('View Registered Teams'),
               onPressed: () {
                 // Navigate to Team List Screen
               },
             ),
             // Add other buttons based on user role later
          ],
        ),
      ),
    );
  }
}
*/
