import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hockey_union_app/services/auth_service.dart';
import 'package:hockey_union_app/ui/auth_screen.dart';
import 'package:hockey_union_app/ui/home_screen.dart';
import 'firebase_options.dart';

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
            future: _auth.getUserData(uid), // Use the getUserData method from AuthService
            builder: (context, userSnapshot) {
              // If fetching user data is waiting
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              // If there's an error fetching user data or data is null
              if (userSnapshot.hasError || !userSnapshot.hasData || userSnapshot.data == null) {
                print("Error fetching user data in Wrapper: ${userSnapshot.error}"); // Log the error
                // Handle this case - maybe show an error screen or log out the user
                // For now, let's show a simple error text
                return Scaffold(body: Center(child: Text('Error loading user data. Please try again.')));
              }

              // User data is successfully fetched
              // We don't necessarily need the role here in Wrapper,
              // as HomeScreen will fetch it again using the userId.
              // But having the user data here could be useful for other purposes later.

              // Pass the user ID to the HomeScreen
              return HomeScreen(userId: uid);

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );  // <-- NO options here
  runApp(HockeyUnionApp());
}


class HockeyUnionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Namibia Hockey Union',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Wrapper(),
    );
  }
}
