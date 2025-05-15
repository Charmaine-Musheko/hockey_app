import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:hockey_union_app/services/auth_service.dart'; // Import AuthService to get user data
import 'package:hockey_union_app/ui/matches/add_edit_match_screen.dart'; // Import the Add/Edit screen
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth for current user

class MatchScheduleScreen extends StatelessWidget {
  final String userId; // Accept the user ID

  const MatchScheduleScreen({Key? key, required this.userId}) : super(key: key); // Require userId

  // Function to handle match booking
  Future<void> _handleMatchBooking(BuildContext context, String matchId, String homeTeamName, String awayTeamName) async {
    final AuthService _auth = AuthService();
    final currentUser = _auth.getCurrentUser(); // Get the currently logged-in user

    if (currentUser == null) {
      // User is not logged in, prompt them to log in
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please sign in to book a spot for a match.')),
      );
      // You might want to navigate to the AuthScreen here
      // Navigator.pushReplacementNamed(context, '/auth');
      return;
    }

    // --- Implement the booking logic ---
    // We'll record the booking in a 'matchBookings' collection
    final matchBookingsRef = FirebaseFirestore.instance.collection('matchBookings');

    try {
      // Check if the user has already booked this match (optional but good practice)
      final existingBooking = await matchBookingsRef
          .where('userId', isEqualTo: currentUser.uid)
          .where('matchId', isEqualTo: matchId)
          .limit(1)
          .get();

      if (existingBooking.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You have already booked a spot for this match.')),
        );
        return;
      }


      // Create a new booking document
      await matchBookingsRef.add({ // Use add() to let Firestore generate an ID
        'userId': currentUser.uid,
        'matchId': matchId,
        'bookingDate': FieldValue.serverTimestamp(),
        'status': 'Confirmed', // Default status (e.g., Confirmed, Attended, Cancelled)
        'userName': currentUser.email, // Or fetch from user doc if you stored name
        'matchName': '$homeTeamName vs $awayTeamName', // Store match name for easier query
        // You might add fields for number of attendees if applicable
      });

      // Booking successful
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully booked your spot for the match!')),
      );

      // TODO: Optionally update the match document to track attendees count

    } catch (e) {
      print("Error during match booking: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to book spot for the match.')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final AuthService _auth = AuthService(); // Get AuthService instance

    // Use a FutureBuilder to fetch the current user's role
    return Scaffold(
      appBar: AppBar(
        title: Text('Match Schedule'),
      ),
      // Use a FutureBuilder to fetch the current user's role
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _auth.getUserData(userId), // Fetch user data using the passed userId
        builder: (context, userSnapshot) {
          // Show loading indicator while fetching user data
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Handle error or missing user data
          if (userSnapshot.hasError || !userSnapshot.hasData || userSnapshot.data == null) {
            print("Error fetching user data in MatchScheduleScreen: ${userSnapshot.error}");
            // You might still want to show the schedule but disable editing/booking
            return Center(child: Text('Error loading user data for permissions/booking.'));
          }

          // User data fetched, get the role
          final userData = userSnapshot.data!;
          final userRole = userData['role'] ?? 'Fan'; // Default to 'Fan'

          // Determine if the user is allowed to edit matches
          final bool canEditMatches = userRole == 'Coach' || userRole == 'Admin';

          // Now, build the main content (the match list) using a StreamBuilder
          return StreamBuilder<QuerySnapshot>(
            // Fetch matches, ordered by date
            stream: FirebaseFirestore.instance
                .collection('matches')
                .orderBy('matchDate', descending: false) // Order by upcoming date
                .snapshots(),
            builder: (context, matchSnapshot) {
              if (matchSnapshot.hasError) {
                return Center(child: Text('Error loading match schedule.'));
              }

              if (matchSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              final matches = matchSnapshot.data!.docs;

              if (matches.isEmpty) {
                return Center(child: Text('No matches scheduled yet.'));
              }

              return ListView.builder(
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final match = matches[index].data() as Map<String, dynamic>;
                  final matchDocId = matches[index].id; // Get the document ID for editing/booking

                  final Timestamp matchTimestamp = match['matchDate'] ?? Timestamp.now();
                  final DateTime matchDateTime = matchTimestamp.toDate();
                  final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(matchDateTime); // Format the date

                  // Display scores only if the match status indicates completion or in-progress
                  String scoreDisplay = '';
                  if (match['status'] == 'Completed' || match['status'] == 'InProgress') {
                    scoreDisplay = 'Score: ${match['homeTeamScore'] ?? '-'} - ${match['awayTeamScore'] ?? '-'}';
                  }

                  final String homeTeamName = match['homeTeamName'] ?? 'TBD';
                  final String awayTeamName = match['awayTeamName'] ?? 'TBD';
                  final String status = match['status'] ?? 'Scheduled';

                  // Determine if booking is possible (e.g., if match is Scheduled and in the future)
                  final bool canBook = status == 'Scheduled' && matchDateTime.isAfter(DateTime.now());


                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      // Conditionally enable onTap based on user role for editing
                      onTap: canEditMatches
                          ? () { // Only allow tap if canEditMatches is true
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddEditMatchScreen(matchId: matchDocId), // Pass the match ID
                          ),
                        );
                      }
                          : null, // Set onTap to null if user cannot edit

                      title: Text('$homeTeamName vs $awayTeamName'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date: $formattedDate'),
                          Text('Location: ${match['location'] ?? 'TBD'}'),
                          Text('Status: $status'),
                          if (scoreDisplay.isNotEmpty) Text(scoreDisplay), // Show score if available
                        ],
                      ),
                      // Add trailing button for booking if possible
                      trailing: canBook
                          ? ElevatedButton(
                        onPressed: () {
                          _handleMatchBooking(context, matchDocId, homeTeamName, awayTeamName);
                        },
                        child: Text('Book Spot'),
                      )
                          : null, // Hide the button if booking is not possible
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
