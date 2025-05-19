import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hockey_union_app/ui/players/manage_players_screen.dart';
import 'package:hockey_union_app/ui/teams/team_list_screen.dart';
import 'package:hockey_union_app/ui/teams/teams_registration_screen.dart';
import 'package:hockey_union_app/ui/events/events_list.dart';
import 'package:hockey_union_app/ui/matches/add_edit_match_screen.dart';
import 'package:hockey_union_app/ui/matches/match_scheduler_screen.dart'; // Corrected import name
import 'package:hockey_union_app/ui/news/news_list_screen.dart';
import 'package:hockey_union_app/ui/booking/user_booking_screen.dart'; // Import the user bookings screen

import '../services/auth_service.dart';


class HomeScreen extends StatelessWidget {
  final String userId; // Accept the user ID passed from Wrapper

  const HomeScreen({Key? key, required this.userId}) : super(key: key); // Require userId

  @override
  Widget build(BuildContext context) {
    final AuthService _auth = AuthService(); // Get AuthService instance for logout

    // Define a consistent navy blue color
    final Color navyBlue = Color(0xFF000080); // A standard navy blue hex code

    return Scaffold(
      appBar: AppBar(
        title: Text('Namibia Hockey Union'),
        backgroundColor: navyBlue, // Set AppBar background to navy blue
        foregroundColor: Colors.white, // Set text/icon color to white for contrast
        actions: [
          // Add a Logout button to the AppBar
          TextButton.icon(
            icon: Icon(Icons.logout, color: Colors.white), // White icon for contrast
            label: Text('Logout', style: TextStyle(color: Colors.white)), // White text for contrast
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
                padding: const EdgeInsets.all(24.0), // Increased padding
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Center the column content vertically (within the available space)
                  crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch buttons horizontally
                  children: [
                    // --- Banner Image Placeholder ---
                    Container(
                      height: 180, // Slightly increased banner height
                      decoration: BoxDecoration(
                        color: navyBlue.withOpacity(0.1), // Light navy background for placeholder
                        borderRadius: BorderRadius.circular(12.0), // Rounded corners for the container
                        border: Border.all(color: navyBlue, width: 2.0), // Navy border
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Placeholder for your logo image
                            Icon(
                              Icons.sports_hockey,
                              size: 60,
                              color: navyBlue,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Hockey Union Banner',
                              style: TextStyle(fontSize: 18, color: navyBlue.withOpacity(0.8)),
                            ),
                          ],
                        ),
                      ),
                      // TODO: Replace this Container with your Image widget later
                      // Example using an asset image (requires adding image to pubspec.yaml and project):
                      // child: ClipRRect( // Clip the image to match the container's rounded corners
                      //    borderRadius: BorderRadius.circular(12.0),
                      //    child: Image.asset(
                      //      'assets/images/your_banner.png', // Your asset path
                      //      fit: BoxFit.cover,
                      //      errorBuilder: (context, error, stackTrace) => Center(child: Text('Error loading image')),
                      //    ),
                      // ),
                    ),
                    SizedBox(height: 40), // Increased space

                    Text(
                      'Welcome, ${userRole}!', // Display a welcome message with the role
                      textAlign: TextAlign.center, // Center the welcome text
                      style: TextStyle(
                        fontSize: 22, // Slightly larger font
                        fontWeight: FontWeight.bold,
                        color: navyBlue, // Navy blue text color
                      ),
                    ),
                    SizedBox(height: 30), // Increased space

                    // --- Navigation Buttons (Conditional based on Role) ---

                    // Button for Registering a Team (e.g., only for Coach or Admin)
                    if (userRole == 'Coach' || userRole == 'Admin')
                      Padding( // Add padding around the button
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: navyBlue, // Navy blue background
                            foregroundColor: Colors.white, // White text
                            padding: EdgeInsets.symmetric(vertical: 15.0), // Button padding
                            shape: RoundedRectangleBorder( // Rounded corners
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: Text('Register a Team', style: TextStyle(fontSize: 16)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => TeamRegistrationScreen()),
                            );
                          },
                        ),
                      ),


                    // Button for Viewing Teams (e.g., for all roles)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navyBlue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 15.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text('View Teams', style: TextStyle(fontSize: 16)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => TeamListScreen(userId: userId,)),
                          );
                        },
                      ),
                    ),

                    // Button for Managing Players (e.g., only for Coach or Admin)
                    if (userRole == 'Coach' || userRole == 'Admin')
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: navyBlue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 15.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: Text('Manage Players', style: TextStyle(fontSize: 16)),
                          onPressed: () {
                            // Navigate to the Manage Players Screen, passing the userId
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ManagePlayersScreen(userId: userId)),
                            );
                          },
                        ),
                      ),


                    // Button for Viewing Match Schedule (for all roles)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navyBlue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 15.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text('View Match Schedule', style: TextStyle(fontSize: 16)),
                        onPressed: () {
                          // Pass the userId received by HomeScreen to MatchScheduleScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MatchScheduleScreen(userId: userId)),
                          );
                        },
                      ),
                    ),

                    // Button for Adding New Match (only for Coach or Admin)
                    if (userRole == 'Coach' || userRole == 'Admin')
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: navyBlue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 15.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: Text('Add New Match', style: TextStyle(fontSize: 16)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AddEditMatchScreen()), // Navigate without matchId for adding
                            );
                          },
                        ),
                      ),


                    // Button for Viewing Events (for all roles)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navyBlue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 15.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text('View Events', style: TextStyle(fontSize: 16)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EventListScreen()),
                          );
                        },
                      ),
                    ),

                    // Button for Viewing My Bookings (for all roles - if logged in)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navyBlue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 15.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text('My Bookings', style: TextStyle(fontSize: 16)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => UserMatchBookingsScreen()), // Navigate to the user bookings screen
                          );
                        },
                      ),
                    ),


                    // Button for Real-time Info (News) (for all roles)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navyBlue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 15.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text('Real-time Info (News)', style: TextStyle(fontSize: 16)),
                        onPressed: () {
                          // Pass the userId to the NewsListScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => NewsListScreen(userId: userId)),
                          );
                        },
                      ),
                    ),

                    // Add other buttons here, wrapped in 'if' conditions based on userRole
                    // Example: Admin-only button
                    // if (userRole == 'Admin')
                    //    Padding(
                    //       padding: const EdgeInsets.symmetric(vertical: 8.0),
                    //       child: ElevatedButton(
                    //         style: ElevatedButton.styleFrom(
                    //           backgroundColor: navyBlue,
                    //           foregroundColor: Colors.white,
                    //           padding: EdgeInsets.symmetric(vertical: 15.0),
                    //           shape: RoundedRectangleBorder(
                    //             borderRadius: BorderRadius.circular(8.0),
                    //           ),
                    //         ),
                    //         child: Text('Admin Panel', style: TextStyle(fontSize: 16)),
                    //         onPressed: () {
                    //           // Navigate to Admin Panel
                    //         },
                    //       ),
                    //    ),
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
