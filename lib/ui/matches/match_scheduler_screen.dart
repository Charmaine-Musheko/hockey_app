import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting (ensure intl package is in pubspec.yaml)
import 'package:hockey_union_app/services/auth_service.dart'; // Import AuthService to get user data
import 'package:hockey_union_app/ui/matches/add_edit_match_screen.dart'; // Import the Add/Edit screen
// Import TeamProfileScreen if you want to navigate to it from here
// import 'package:hockey_union_app/ui/teams/team_profile_screen.dart';


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

                  final String homeTeamName = match['homeTeamName'] ?? 'TBD';
                  final String awayTeamName = match['awayTeamName'] ?? 'TBD';
                  final String status = match['status'] ?? 'Scheduled';
                  final int homeScore = match['homeTeamScore'] ?? 0; // Default score to 0
                  final int awayScore = match['awayTeamScore'] ?? 0; // Default score to 0

                  final Timestamp matchTimestamp = match['matchDate'] ?? Timestamp.now();
                  final DateTime matchDateTime = matchTimestamp.toDate();
                  final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(matchDateTime); // Format the date
                  final formattedTime = DateFormat('HH:mm').format(matchDateTime); // Format just the time

                  // Determine if scores should be prominently displayed
                  final bool showScores = status == 'Completed' || status == 'InProgress';

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    elevation: showScores ? 4.0 : 2.0, // Slightly raise card for live/completed matches
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

                      // Use a Row to place team names/scores and match info side-by-side
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space out the teams/score and info
                        children: [
                          // Team Names and Scores
                          Expanded( // Allow team names/scores to take available space
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$homeTeamName vs $awayTeamName',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis, // Prevent overflow
                                ),
                                if (showScores) // Show scores below team names if applicable
                                  Text(
                                    '$homeScore - $awayScore',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: status == 'InProgress' ? Colors.red : Colors.black, // Highlight live scores
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(width: 16), // Space between team/score and info

                          // Match Info (Date, Time, Location, Status)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end, // Align info to the right
                            children: [
                              Text(formattedDate, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                              // Text(formattedTime, style: TextStyle(fontSize: 12, color: Colors.grey[700])), // Could show time separately
                              Text(match['location'] ?? 'TBD', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                              Text(
                                status,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: status == 'InProgress' ? Colors.red : Colors.black, // Highlight live status
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // We removed the subtitle property and integrated its content into the title Row
                      // We removed the trailing property and integrated its content into the onTap logic or removed it
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
