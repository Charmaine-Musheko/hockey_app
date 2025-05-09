import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeamProfileScreen extends StatelessWidget {
  final String teamId; // The ID of the team to display

  const TeamProfileScreen({Key? key, required this.teamId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Team Profile'), // Will update this with team name once loaded
      ),
      body: FutureBuilder<DocumentSnapshot>(
        // Fetch the specific team document from Firestore
        future: FirebaseFirestore.instance.collection('teams').doc(teamId).get(),
        builder: (context, snapshot) {
          // Show loading indicator
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Handle errors
          if (snapshot.hasError) {
            print("Error fetching team data: ${snapshot.error}");
            return Center(child: Text('Error loading team profile.'));
          }

          // Handle case where document doesn't exist
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Team not found.'));
          }

          // Team data is loaded
          final teamData = snapshot.data!.data() as Map<String, dynamic>;
          final teamName = teamData['teamName'] ?? 'Unknown Team';
          final coachName = teamData['coachName'] ?? 'N/A';
          final contactNumber = teamData['contactNumber'] ?? 'N/A';
          // Add other fields you might have or add later (e.g., stats, achievements)
          // final wins = teamData['wins'] ?? 0;
          // final losses = teamData['losses'] ?? 0;

          // Update AppBar title once data is loaded
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) { // Check if screen is still in view
              // This is a common pattern to update AppBar title from FutureBuilder
              // It might cause a slight flicker, but works for StatelessWidget
              // For a more seamless update, consider making this a StatefulWidget
              // and using setState after data is loaded in initState or didChangeDependencies
            }
          });


          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teamName,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('Coach: $coachName', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Contact: $contactNumber', style: TextStyle(fontSize: 18)),
                SizedBox(height: 24),
                // Add sections for Players, Stats, Achievements etc. here later
                Text(
                  'Team Details:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                // Example: Displaying placeholder stats
                // Text('Wins: $wins', style: TextStyle(fontSize: 16)),
                // Text('Losses: $losses', style: TextStyle(fontSize: 16)),
                // SizedBox(height: 24),

                // TODO: Add a section to list players belonging to this team
                // This would likely involve another StreamBuilder or FutureBuilder
                // fetching documents from the 'players' collection where 'teamId' matches this teamId.
                Text(
                  'Players:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                // Placeholder for player list
                Text('Player list coming soon...', style: TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
          );
        },
      ),
    );
  }
}
