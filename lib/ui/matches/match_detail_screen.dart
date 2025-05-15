import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

class MatchDetailScreen extends StatelessWidget {
  final String matchId; // The ID of the match to display

  const MatchDetailScreen({Key? key, required this.matchId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Match Details'), // Will update with match name once loaded
      ),
      body: FutureBuilder<DocumentSnapshot>(
        // Fetch the specific match document from Firestore
        future: FirebaseFirestore.instance.collection('matches').doc(matchId).get(),
        builder: (context, snapshot) {
          // Show loading indicator
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Handle errors
          if (snapshot.hasError) {
            print("Error fetching match data: ${snapshot.error}");
            return Center(child: Text('Error loading match details.'));
          }

          // Handle case where document doesn't exist
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Match not found.'));
          }

          // Match data is loaded
          final matchData = snapshot.data!.data() as Map<String, dynamic>;
          final homeTeamName = matchData['homeTeamName'] ?? 'TBD';
          final awayTeamName = matchData['awayTeamName'] ?? 'TBD';
          final location = matchData['location'] ?? 'TBD';
          final status = matchData['status'] ?? 'Scheduled';

          final Timestamp matchTimestamp = matchData['matchDate'] ?? Timestamp.now();
          final DateTime matchDateTime = matchTimestamp.toDate();
          final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(matchDateTime);

          // Display scores only if the match status indicates completion or in-progress
          String scoreDisplay = '';
          if (status == 'Completed' || status == 'InProgress') {
            scoreDisplay = 'Score: ${matchData['homeTeamScore'] ?? '-'} - ${matchData['awayTeamScore'] ?? '-'}';
          }

          // Update AppBar title once data is loaded (Note for StatelessWidget)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Consider making this a StatefulWidget for smoother title update
          });


          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$homeTeamName vs $awayTeamName',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('Date: $formattedDate', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Location: $location', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Status: $status', style: TextStyle(fontSize: 18)),
                if (scoreDisplay.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text(scoreDisplay, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ],

                SizedBox(height: 24),
                // TODO: Add sections for match summary, key events, etc. later
                Text(
                  'Match Information:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('More details coming soon...', style: TextStyle(fontStyle: FontStyle.italic)),

                // TODO: Potentially add booking/cancellation button here later
              ],
            ),
          );
        },
      ),
    );
  }
}
