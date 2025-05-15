import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hockey_union_app/ui/players/manage_players_screen.dart';
// Removed self-referential import: import 'package:hockey_union_app/ui/home_screen.dart';
import 'package:hockey_union_app/ui/teams/team_list_screen.dart';
import 'package:hockey_union_app/ui/teams/teams_registration_screen.dart';

import '../services/auth_service.dart';
import 'booking/user_booking_screen.dart';
import 'events/events_list.dart';
import 'matches/add_edit_match_screen.dart';
import 'matches/match_scheduler_screen.dart';
import 'news/news_list_screen.dart';



class HomeScreen extends StatelessWidget {
  final String userId; // Accept the user ID passed from Wrapper

  const HomeScreen({Key? key, required this.userId}) : super(key: key); // Require userId

  @override
  Widget build(BuildContext context) {
    final AuthService _auth = AuthService(); // Get AuthService instance for logout

    return Scaffold(
      appBar: AppBar(
        title: Text('Namibia Hockey Union'),
        actions: [
          // Add a Logout button to the AppBar
          TextButton.icon(
            icon: Icon(Icons.logout, color: Colors.indigo),
            label: Text('Logout', style: TextStyle(color: Colors.black87)),
            onPressed: () async {
              await _auth.signOut(); // Call the signOut method from AuthService
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get().then((doc) => doc.data()), // Fetch user document
        builder: (context, snapshot) {
          // Show loading indicator while fetching user data
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Handle errors or if user data is not found (shouldn't happen if Wrapper works)
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            print("Error fetching user data in HomeScreen: ${snapshot.error}");
            return Center(child: Text('Error loading user data.')); // Display error message
          }

          // User data is fetched, get the role
          final userData = snapshot.data!;
          final userRole = userData['role'] ?? 'Fan'; // Default to 'Fan' if role is missing

          print('HomeScreen loaded for user ${userId} with role: $userRole'); // Debugging

          // Now, build the main content with the banner placeholder and buttons
          return SingleChildScrollView( // Use SingleChildScrollView to prevent overflow if content is tall
            child: Center( // Center the content horizontally
              child: Padding(
                padding: const EdgeInsets.all(16.0), // Add some padding around the content
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Center the column content vertically (within the available space)
                  crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch buttons horizontally
                  children: [
                    // --- Banner Image Placeholder ---
                    Container(
                      height: 150, // Set a height for the banner
                      color: Colors.grey[300], // Placeholder color
                      child: Center(
                        child: Text(
                          'Hockey Union Banner',
                          style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                        ),
                      ),
                      // Replace this Container with your Image widget later
                      // Example using a network image:
                      // child: Image.network(
                      //   'YOUR_BANNER_IMAGE_URL_HERE',
                      //   fit: BoxFit.cover, // Cover the container area
                      //   errorBuilder: (context, error, stackTrace) => Center(child: Text('Error loading image')), // Handle loading errors
                      // ),
                      // Example using an asset image (requires adding image to pubspec.yaml and project):
                      // child: Image.asset(
                      //   'assets/images/your_banner.png', // Your asset path
                      //   fit: BoxFit.cover,
                      //   errorBuilder: (context, error, stackTrace) => Center(child: Text('Error loading image')),
                      // ),
                    ),
                    SizedBox(height: 30), // Space between banner and buttons

                    Text(
                      'Welcome, ${userRole}!', // Display a welcome message with the role
                      textAlign: TextAlign.center, // Center the welcome text
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20), // Space between welcome text and buttons

                    // --- Navigation Buttons (Conditional based on Role) ---
                    // Buttons are stretched horizontally due to crossAxisAlignment: CrossAxisAlignment.stretch on the parent Column

                    // Button for Registering a Team (e.g., only for Coach or Admin)
                    if (userRole == 'Coach' || userRole == 'Admin') ...[ // Use spread operator with if
                      ElevatedButton(
                        child: Text('Register a Team'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => TeamRegistrationScreen()),
                          );
                        },
                      ),
                      SizedBox(height: 10), // Place SizedBox directly after the button
                    ],


                    // Button for Viewing Teams (e.g., for all roles)
                    ElevatedButton(
                      child: Text('View Teams'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => TeamListScreen(userId: userId,)),
                        );
                      },
                    ),
                    SizedBox(height: 10),

                    // Button for Managing Players (e.g., only for Coach or Admin)
                    // In your HomeScreen's Column children:
                    if (userRole == 'Coach' || userRole == 'Admin') ...[
                      ElevatedButton(
                        child: Text('Manage Players'),
                        onPressed: () {
                          // Navigate to the Manage Players Screen, passing the userId
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ManagePlayersScreen(userId: userId)),
                          );
                        },
                      ),
                      SizedBox(height: 10),
                    ],

                    if (userRole == 'Coach' || userRole == 'Admin') ...[
                    // Button for Viewing Match Schedule (for all roles)
                    ElevatedButton(
                      child: Text('View Match Schedule'),
                      onPressed: () {
                        // Pass the userId received by HomeScreen to MatchScheduleScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MatchScheduleScreen(userId: userId)),
                        );
                      },
                    ),
                    SizedBox(height: 10),
                    ],
                    // Button for Adding New Match (only for Coach or Admin)
                    if (userRole == 'Coach' || userRole == 'Admin') ...[ // Use spread operator with if
                      ElevatedButton(
                        child: Text('Add New Match'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AddEditMatchScreen()), // Navigate without matchId for adding
                          );
                        },
                      ),
                      SizedBox(height: 10), // Place SizedBox directly after the button
                    ],

                    // Button for Viewing Events (for all roles)
                    ElevatedButton(
                      child: Text('View Events'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EventListScreen()),
                        );
                      },
                    ),
                    SizedBox(height: 10),

                    // Button for Viewing My Bookings (for all roles - if logged in)
                    ElevatedButton(
                      child: Text('My Bookings'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => UserMatchBookingsScreen()),
                        );
                      },
                    ),
                    SizedBox(height: 10),


                    // Button for Real-time Info (News) (for all roles)
                    ElevatedButton(
                      child: Text('Real-time Info (News)'), // Maybe update the text
                      onPressed: () {
                        // Pass the userId to the NewsListScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => NewsListScreen(userId: userId)),
                        );
                      },
                    ),
                    SizedBox(height: 10),


                    // Add other buttons here, wrapped in 'if' conditions based on userRole
                    // Example: Admin-only button
                    // if (userRole == 'Admin') ...[ // Use spread operator with if
                    //   ElevatedButton(
                    //     child: Text('Admin Panel'),
                    //     onPressed: () {
                    //       // Navigate to Admin Panel
                    //     },
                    //   ),
                    //   SizedBox(height: 10), // Place SizedBox directly after the button
                    // ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
