import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Import PlayerProfileScreen later when created
// import 'package:hockey_union_app/ui/players/player_profile_screen.dart';

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
          // Show loading indicator for team data
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Handle errors fetching team data
          if (snapshot.hasError) {
            print("Error fetching team data: ${snapshot.error}");
            return Center(child: Text('Error loading team profile.'));
          }

          // Handle case where team document doesn't exist
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Team not found.'));
          }

          // Team data is loaded
          final teamData = snapshot.data!.data() as Map<String, dynamic>;
          final teamName = teamData['teamName'] ?? 'Unknown Team';
          final coachName = teamData['coachName'] ?? 'N/A';
          final contactNumber = teamData['contactNumber'] ?? 'N/A';
          // Add other fields you might have or add later (e.g., stats, achievements)

          // Update AppBar title once data is loaded (still a note for StatelessWidget)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Consider making this a StatefulWidget for smoother title update
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

                // --- Section to List Players ---
                Text(
                  'Players:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),

                // Use a StreamBuilder to fetch players for this team
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('players')
                      .where('teamId', isEqualTo: teamId) // Filter players by the current teamId
                      .orderBy('playerName') // Order players alphabetically
                      .snapshots(),
                  builder: (context, playerSnapshot) {
                    // Show loading indicator for player data
                    if (playerSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    // Handle errors fetching player data
                    if (playerSnapshot.hasError) {
                      print("Error fetching players: ${playerSnapshot.error}");
                      return Text('Error loading players.');
                    }

                    final players = playerSnapshot.data!.docs;

                    if (players.isEmpty) {
                      return Text('No players registered for this team yet.', style: TextStyle(fontStyle: FontStyle.italic));
                    }

                    // Display the list of players
                    return ListView.builder(
                      shrinkWrap: true, // Important: Allows ListView inside SingleChildScrollView
                      physics: NeverScrollableScrollPhysics(), // Important: Disables ListView's own scrolling
                      itemCount: players.length,
                      itemBuilder: (context, index) {
                        final player = players[index].data() as Map<String, dynamic>;
                        final playerId = players[index].id; // Get player document ID

                        return ListTile(
                          leading: Icon(Icons.person), // Player icon
                          title: Text(player['playerName'] ?? 'Unknown Player'),
                          subtitle: Text('Position: ${player['position'] ?? 'N/A'}'),
                          // Add onTap here to navigate to Player Profile screen later
                          // onTap: () {
                          //   Navigator.push(
                          //     context,
                          //     MaterialPageRoute(
                          //       builder: (context) => PlayerProfileScreen(playerId: playerId),
                          //     ),
                          //   );
                          // },
                        );
                      },
                    );
                  },
                ),
                // --- End of Player List Section ---

              ],
            ),
          );
        },
      ),
    );
  }
}
