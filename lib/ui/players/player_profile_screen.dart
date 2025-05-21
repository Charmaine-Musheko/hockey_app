import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerProfileScreen extends StatelessWidget {
  final String playerId; // The ID of the player to display (which is now the user's UID)

  const PlayerProfileScreen({Key? key, required this.playerId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Player Profile'), // Will update with player name once loaded
      ),
      body: FutureBuilder<DocumentSnapshot>(
        // Fetch the specific player document from Firestore using the user's UID as the document ID
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

          // Handle case where document doesn't exist (e.g., no player profile created for this user ID)
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Player profile not found.'));
          }

          // Player data is loaded
          final playerData = snapshot.data!.data() as Map<String, dynamic>;
          final playerName = playerData['playerName'] ?? 'Unknown Player';
          final position = playerData['position'] ?? 'N/A';
          final teamName = playerData['teamName'] ?? 'N/A'; // Assuming teamName is stored with player
          final int jerseyNumber = playerData['jerseyNumber'] ?? 'N/A'; // Fetch jersey number

          // --- New fields for Stats and Achievements ---
          final int goals = playerData['goals'] ?? 0;
          final int assists = playerData['assists'] ?? 0;
          final int gamesPlayed = playerData['gamesPlayed'] ?? 0;
          final List<dynamic> achievementsList = playerData['achievements'] is List ? playerData['achievements'] : [];


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
                  playerName,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('Team: $teamName', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Position: $position', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Jersey #: ${jerseyNumber == 'N/A' ? 'N/A' : jerseyNumber.toString()}', style: TextStyle(fontSize: 18)),


                SizedBox(height: 24),
                // --- Section for Stats ---
                Text(
                  'Stats:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('Games Played: $gamesPlayed', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('Goals: $goals', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('Assists: $assists', style: TextStyle(fontSize: 16)),


                SizedBox(height: 24),
                // --- Section for Achievements ---
                Text(
                  'Achievements:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                if (achievementsList.isEmpty)
                  Text('No achievements listed yet.', style: TextStyle(fontStyle: FontStyle.italic)),
                if (achievementsList.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: achievementsList.map<Widget>((achievement) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text('- $achievement', style: TextStyle(fontSize: 16)),
                    )).toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
