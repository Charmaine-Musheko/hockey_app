import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:hockey_union_app/services/auth_service.dart'; // Import AuthService to get user data
import 'package:hockey_union_app/ui/matches/add_edit_match_screen.dart'; // Import the Add/Edit screen
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth for current user
import 'package:hockey_union_app/utils/app_colors.dart'; // Import your new AppColors

class MatchScheduleScreen extends StatelessWidget {
  final String userId; // Accept the user ID

  const MatchScheduleScreen({Key? key, required this.userId}) : super(key: key); // Require userId

  // Function to handle match booking
  Future<void> _handleMatchBooking(BuildContext context, String matchId, String homeTeamName, String awayTeamName) async {
    final currentUser = FirebaseAuth.instance.currentUser; // Get the currently logged-in user

    if (currentUser == null) {
      // User is not logged in, prompt them to log in
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please sign in to book a spot for a match.')),
      );
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

    return Scaffold(
      backgroundColor: AppColors.primaryGreen, // Dark green background
      appBar: AppBar(
        title: Text('Match Schedule'),
        backgroundColor: AppColors.primaryGreen, // Dark green AppBar
        foregroundColor: AppColors.white, // White text/icons
        elevation: 0, // No shadow
      ),
      // Use a FutureBuilder to fetch the current user's role
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _auth.getUserData(userId), // Fetch user data using the passed userId
        builder: (context, userSnapshot) {
          // Show loading indicator while fetching user data
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppColors.accentOrange));
          }

          // Handle error or missing user data
          if (userSnapshot.hasError || !userSnapshot.hasData || userSnapshot.data == null) {
            print("Error fetching user data in MatchScheduleScreen: ${userSnapshot.error}");
            return Center(child: Text('Error loading user data for permissions.', style: TextStyle(color: AppColors.white)));
          }

          // User data fetched, get the role
          final userData = userSnapshot.data!;
          final userRole = userData['role'] ?? 'Fan'; // Default to 'Fan'

          // Determine if the user is allowed to edit matches
          final bool canEditMatches = userRole == 'Coach' || userRole == 'Admin';

          // Now, build the main content (the match list) using a StreamBuilder
          return Container( // This Container forms the main white "card"
            decoration: BoxDecoration(
              color: AppColors.white, // White background for the content area
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30.0), // Large rounded top-left
                topRight: Radius.circular(30.0), // Large rounded top-right
              ),
            ),
            child: StreamBuilder<QuerySnapshot>(
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
                  return Center(child: CircularProgressIndicator(color: AppColors.accentOrange));
                }

                final matches = matchSnapshot.data!.docs;

                if (matches.isEmpty) {
                  return Center(child: Text('No matches scheduled yet.'));
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16.0), // Padding inside the list
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final match = matches[index].data() as Map<String, dynamic>;
                    final matchDocId = matches[index].id; // Get the document ID for editing/booking

                    final String homeTeamName = match['homeTeamName'] ?? 'TBD';
                    final String awayTeamName = match['awayTeamName'] ?? 'TBD';
                    final String status = match['status'] ?? 'Scheduled';
                    final int homeScore = match['homeTeamScore'] ?? 0;
                    final int awayScore = match['awayTeamScore'] ?? 0;

                    final Timestamp matchTimestamp = match['matchDate'] ?? Timestamp.now();
                    final DateTime matchDateTime = matchTimestamp.toDate();
                    final formattedDate = DateFormat('yyyy-MM-dd').format(matchDateTime);
                    final formattedTime = DateFormat('HH:mm').format(matchDateTime);

                    final bool showScores = status == 'Completed' || status == 'InProgress';

                    // Determine if booking is possible (e.g., if match is Scheduled and in the future)
                    final bool canBook = status == 'Scheduled' && matchDateTime.isAfter(DateTime.now());

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8), // Vertical margin only
                      elevation: 4.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0), // Rounded corners for cards
                      ),
                      child: Padding( // Add padding inside the card
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Team Names
                                Expanded(
                                  child: Text(
                                    '$homeTeamName vs $awayTeamName',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: AppColors.primaryGreen,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Edit Button (if applicable)
                                if (canEditMatches)
                                  IconButton(
                                    icon: Icon(Icons.edit, color: AppColors.primaryGreen),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AddEditMatchScreen(matchId: matchDocId),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                            SizedBox(height: 8),
                            // Date and Time
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: AppColors.secondaryGreen),
                                SizedBox(width: 8),
                                Text('$formattedDate at $formattedTime', style: TextStyle(fontSize: 14, color: AppColors.darkText)),
                              ],
                            ),
                            SizedBox(height: 4),
                            // Location
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 16, color: AppColors.secondaryGreen),
                                SizedBox(width: 8),
                                Text(match['location'] ?? 'TBD', style: TextStyle(fontSize: 14, color: AppColors.darkText)),
                              ],
                            ),
                            SizedBox(height: 8),
                            // Status and Scores
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Status: $status',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: status == 'InProgress' ? Colors.red : AppColors.primaryGreen,
                                  ),
                                ),
                                if (showScores)
                                  Text(
                                    'Score: $homeScore - $awayScore',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: status == 'InProgress' ? Colors.red : AppColors.darkText,
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 16),
                            // Book Spot Button (if applicable)
                            Center(
                              child: canBook
                                  ? ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentOrange, // Orange button
                                  foregroundColor: AppColors.white,
                                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                                child: Text('BOOK SPOT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  _handleMatchBooking(context, matchDocId, homeTeamName, awayTeamName);
                                },
                              )
                                  : Text(
                                status == 'Scheduled' && matchDateTime.isBefore(DateTime.now())
                                    ? 'Booking Closed' // Match is in the past
                                    : 'Not Available for Booking', // Other statuses
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
