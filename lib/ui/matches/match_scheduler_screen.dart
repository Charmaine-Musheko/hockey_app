import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:hockey_union_app/services/auth_service.dart'; // Import AuthService to get user data
import 'package:hockey_union_app/ui/matches/add_edit_match_screen.dart'; // Import the Add/Edit screen

// Update MatchScheduleScreen to accept the userId
class MatchScheduleScreen extends StatelessWidget {
  final String userId; // Accept the user ID

  const MatchScheduleScreen({Key? key, required this.userId}) : super(key: key); // Require userId

  @override
  Widget build(BuildContext context) {
    final AuthService _auth = AuthService(); // Get AuthService instance

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
            // You might still want to show the schedule but disable editing
            // For now, let's show an error message, but you could adjust this
            return Center(child: Text('Error loading user data for permissions.'));
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
                  final matchDocId = matches[index].id; // Get the document ID for editing

                  final Timestamp matchTimestamp = match['matchDate'] ?? Timestamp.now();
                  final DateTime matchDateTime = matchTimestamp.toDate();
                  final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(matchDateTime); // Format the date

                  // Display scores only if the match status indicates completion or in-progress
                  String scoreDisplay = '';
                  if (match['status'] == 'Completed' || match['status'] == 'InProgress') {
                    scoreDisplay = 'Score: ${match['homeTeamScore'] ?? '-'} - ${match['awayTeamScore'] ?? '-'}';
                  }

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      title: Text('${match['homeTeamName'] ?? 'TBD'} vs ${match['awayTeamName'] ?? 'TBD'}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date: $formattedDate'),
                          Text('Location: ${match['location'] ?? 'TBD'}'),
                          Text('Status: ${match['status'] ?? 'Scheduled'}'),
                          if (scoreDisplay.isNotEmpty) Text(scoreDisplay), // Show score if available
                        ],
                      ),
                      // Conditionally enable onTap based on user role
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
