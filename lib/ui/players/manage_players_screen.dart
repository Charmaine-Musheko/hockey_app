import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hockey_union_app/services/auth_service.dart'; // Import AuthService to get user data
import 'package:hockey_union_app/ui/players/player_registration_screen.dart'; // Import Player Registration/Edit Screen

class ManagePlayersScreen extends StatelessWidget {
  final String userId; // Accept the user ID to determine the user's team

  const ManagePlayersScreen({Key? key, required this.userId}) : super(key: key);

  // Function to show a confirmation dialog before deleting a player
  Future<bool?> _confirmDelete(BuildContext context, String playerName) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete player "$playerName"? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false); // Return false on cancel
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(true); // Return true on confirm
              },
            ),
          ],
        );
      },
    );
  }

  // Function to delete a player from Firestore
  Future<void> _deletePlayer(BuildContext context, String playerId, String playerName) async {
    final bool? confirm = await _confirmDelete(context, playerName);
    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('players').doc(playerId).delete();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Player "$playerName" deleted successfully!')));
      } catch (e) {
        print("Error deleting player: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete player "$playerName".')));
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final AuthService _auth = AuthService(); // Get AuthService instance

    // Use a FutureBuilder to fetch the current user's data (role and teamId)
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Players'),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _auth.getUserData(userId), // Fetch user data
        builder: (context, userSnapshot) {
          // Show loading indicator while fetching user data
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Handle error or missing user data
          if (userSnapshot.hasError || !userSnapshot.hasData || userSnapshot.data == null) {
            print("Error fetching user data in ManagePlayersScreen: ${userSnapshot.error}");
            return Center(child: Text('Error loading user data for player management.'));
          }

          // User data fetched, get the role and teamId
          final userData = userSnapshot.data!;
          final userRole = userData['role'] ?? 'Fan'; // Default to 'Fan'
          final String? userTeamId = userData['teamId']; // Get the team ID associated with the user

          // Check if the user is authorized and has a teamId
          if (userRole != 'Coach' && userRole != 'Admin') {
            return Center(child: Text('You do not have permission to manage players.'));
          }
          if (userTeamId == null || userTeamId.isEmpty) {
            return Center(child: Text('Your user account is not associated with a team.'));
          }

          // User is authorized and has a teamId, now fetch players for that team
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('players')
                .where('teamId', isEqualTo: userTeamId) // Filter players by the user's team ID
                .orderBy('playerName') // Order players alphabetically
                .snapshots(),
            builder: (context, playerSnapshot) {
              // Show loading indicator for player data
              if (playerSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              // Handle errors fetching player data
              if (playerSnapshot.hasError) {
                print("Error fetching players for team $userTeamId: ${playerSnapshot.error}");
                return Center(child: Text('Error loading players.'));
              }

              final players = playerSnapshot.data!.docs;

              if (players.isEmpty) {
                return Center(child: Text('No players registered for your team yet.'));
              }

              // Display the list of players with edit/delete options
              return ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final player = players[index].data() as Map<String, dynamic>;
                  final playerId = players[index].id; // Get player document ID
                  final playerName = player['playerName'] ?? 'Unknown Player';
                  final playerPosition = player['position'] ?? 'N/A';

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: ListTile(
                      leading: Icon(Icons.person), // Player icon
                      title: Text(playerName),
                      subtitle: Text('Position: $playerPosition'),
                      trailing: Row( // Use a Row for multiple trailing icons
                        mainAxisSize: MainAxisSize.min, // Keep the row size minimal
                        children: [
                          // Edit Icon Button
                          IconButton(
                            icon: Icon(Icons.edit),
                            tooltip: 'Edit Player',
                            onPressed: () {
                              // Navigate to PlayerRegistrationScreen for editing
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlayerRegistrationScreen(

                                  ),
                                ),
                              );
                            },
                          ),
                          // Delete Icon Button
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete Player',
                            onPressed: () {
                              // Call the delete function
                              _deletePlayer(context, playerId, playerName);
                            },
                          ),
                        ],
                      ),
                      // Optional: Add onTap for viewing player profile without edit/delete
                      // onTap: () {
                      //   Navigator.push(
                      //     context,
                      //     MaterialPageRoute(
                      //       builder: (context) => PlayerProfileScreen(playerId: playerId),
                      //     ),
                      //   );
                      // },
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
