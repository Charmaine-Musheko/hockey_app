import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerProfileScreen extends StatelessWidget {
  final String playerId; // The ID of the player to display

  const PlayerProfileScreen({Key? key, required this.playerId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Player Profile'), // Will update with player name once loaded
      ),
      body: FutureBuilder<DocumentSnapshot>(
        // Fetch the specific player document from Firestore
        future: FirebaseFirestore.instance.collection('players').doc(playerId).get(),
        builder: (context, snapshot) {
          // Show loading indicator
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Handle errors
          if (snapshot.hasError) {
            print("Error fetching player data: ${snapshot.error}");
            return Center(child: Text('Error loading player profile.'));
          }

          // Handle case where document doesn't exist
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Player not found.'));
          }

          // Player data is loaded
          final playerData = snapshot.data!.data() as Map<String, dynamic>;
          final playerName = playerData['playerName'] ?? 'Unknown Player';
          final position = playerData['position'] ?? 'N/A';
          final teamName = playerData['teamName'] ?? 'N/A'; // Assuming teamName is stored with player

          // --- New fields for Stats and Achievements (Add these to Firestore documents) ---
          final int goals = playerData['goals'] ?? 0; // Example stat: Goals
          final int assists = playerData['assists'] ?? 0; // Example stat: Assists
          final int gamesPlayed = playerData['gamesPlayed'] ?? 0; // Example stat: Games Played
          // Ensure 'achievements' is stored as a List in Firestore
          final List<dynamic> achievementsList = playerData['achievements'] is List ? playerData['achievements'] : []; // Safely cast to List


          // Update AppBar title once data is loaded (Note for StatelessWidget)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Consider making this a StatefulWidget for smoother title update
          });


          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [ // Start of the Column children list
                Text(
                  playerName,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('Team: $teamName', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Position: $position', style: TextStyle(fontSize: 18)),
                // Add other basic details here (e.g., age, jerseyNumber if you add them)
                // SizedBox(height: 8),
                // Text('Age: ${playerData['age'] ?? 'N/A'}', style: TextStyle(fontSize: 18)),
                // SizedBox(height: 8),
                // Text('Jersey #: ${playerData['jerseyNumber'] ?? 'N/A'}', style: TextStyle(fontSize: 18)),


                SizedBox(height: 24),
                // --- Section for Stats ---
                Text(
                  'Stats:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                // Displaying the new stats fields
                Text('Games Played: $gamesPlayed', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('Goals: $goals', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('Assists: $assists', style: TextStyle(fontSize: 16)),
                // Add more stats fields here as you add them to Firestore


                SizedBox(height: 24),
                // --- Section for Achievements ---
                Text(
                  'Achievements:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                // Displaying the list of achievements conditionally
                if (achievementsList.isEmpty) // If list is empty, add this Text widget
                  Text('No achievements listed yet.', style: TextStyle(fontStyle: FontStyle.italic)),
                // No 'else' keyword here. If the list is not empty, the first 'if' is false,
                // and we proceed to the next widget in the Column's children list.
                if (achievementsList.isNotEmpty) // If list is NOT empty, add this Column widget
                  Column( // Use a Column to list achievements
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: achievementsList.map<Widget>((achievement) => Padding( // Explicitly cast map result to Widget
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text('- $achievement', style: TextStyle(fontSize: 16)),
                    )).toList(), // Convert the Iterable to a List<Widget>
                  ),
              ], // End of the Column children list
            ),
          );
        },
      ),
    );
  }
}
