import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hockey_union_app/ui/players/player_profile_screen.dart'; // Import PlayerProfileScreen

class PlayerListScreen extends StatelessWidget {
  final String teamId;
  final String teamName;

  const PlayerListScreen({Key? key, required this.teamId, required this.teamName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Players for ${teamName}'), // Dynamic title based on team name
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Fetch players from the top-level 'players' collection
        // and filter by the 'teamId' field
        stream: FirebaseFirestore.instance
            .collection('players')
            .where('teamId', isEqualTo: teamId) // Filter by the specific teamId
            .orderBy('playerName') // Order players alphabetically by name
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print("Error loading players: ${snapshot.error}");
            return Center(child: Text('Error loading players.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final players = snapshot.data!.docs;

          if (players.isEmpty) {
            return Center(child: Text('No players found for this team.'));
          }

          return ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index].data() as Map<String, dynamic>;
              final playerId = players[index].id; // This is the user's UID linked to the player profile
              final playerName = player['playerName'] ?? 'Unknown Player';
              final position = player['position'] ?? 'N/A';
              final jerseyNumber = player['jerseyNumber']?.toString() ?? 'N/A';

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: Icon(Icons.person), // Player icon
                  title: Text(playerName),
                  subtitle: Text('Position: $position | Jersey #: $jerseyNumber'),
                  onTap: () {
                    // Navigate to PlayerProfileScreen when a player is tapped
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerProfileScreen(playerId: playerId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
