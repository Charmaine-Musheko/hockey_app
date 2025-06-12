import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hockey_union_app/ui/players/player_registration_screen.dart';
import 'package:hockey_union_app/services/auth_service.dart'; // Import AuthService to get user data

import '../players/player_list_screen.dart';
import '../teams/team_profile_screen.dart'; // Import TeamProfileScreen


// Update TeamListScreen to accept the userId
class TeamListScreen extends StatelessWidget {
  final String userId; // Accept the user ID

  const TeamListScreen({Key? key, required this.userId}) : super(key: key); // Require userId

  @override
  Widget build(BuildContext context) {
    final AuthService _auth = AuthService(); // Get AuthService instance

    return Scaffold(
      appBar: AppBar(
        title: Text('Registered Teams'),
      ),
      // --- CRITICAL CHANGE HERE: Use StreamBuilder instead of FutureBuilder ---
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _auth.getUserDataStream(userId), // <--- Use the new Stream method
        builder: (context, userSnapshot) {
          // Show loading indicator while fetching user data
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Handle error or missing user data
          // Check if userSnapshot has data and if the document exists
          if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
            print("Error or missing user data in TeamListScreen: ${userSnapshot.error ?? 'Document does not exist.'}");
            // You might still want to show the team list even if user data fails
            return Center(child: Text('Error loading user data for permissions.'));
          }

          // User data fetched, get the role
          final userData = userSnapshot.data!.data(); // Get the data map
          final userRole = userData?['role'] ?? 'Fan'; // Default to 'Fan' if userData is null or role is missing

          // Determine if the user is allowed to see the management buttons
          final bool canManagePlayers = userRole == 'Coach' || userRole == 'Admin';

          // Now, build the main content (the team list) using a StreamBuilder
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('teams').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, teamSnapshot) {
              if (teamSnapshot.hasError) {
                return Center(child: Text('Error fetching teams.'));
              }

              if (teamSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              final teams = teamSnapshot.data!.docs;

              if (teams.isEmpty) {
                return Center(child: Text('No teams registered yet.'));
              }

              return ListView.builder(
                itemCount: teams.length,
                itemBuilder: (context, index) {
                  final team = teams[index].data() as Map<String, dynamic>;
                  final teamDocId = teams[index].id; // Get the document ID

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      title: Text(team['teamName'] ?? 'Unknown Team'),
                      subtitle: Text('Coach: ${team['coachName'] ?? 'N/A'}\nContact: ${team['contactNumber'] ?? 'N/A'}'),
                      isThreeLine: true,
                      // Conditionally show the trailing Row of buttons
                      trailing: canManagePlayers
                          ? Row( // Only show the Row if the user can manage players
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.person_add),
                            tooltip: 'Register Player',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlayerRegistrationScreen(
                                    teamId: teamDocId, // Pass the team ID
                                    teamName: team['teamName'] ?? 'Unknown Team', // Pass the team name
                                  ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.group),
                            tooltip: 'View Players',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlayerListScreen(
                                    teamId: teamDocId, // Use the document ID
                                    teamName: team['teamName'] ?? 'Unknown',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      )
                          : null, // Set trailing to null if user cannot manage players
                      // Add onTap here if you want to navigate to Team Profile from the ListTile itself
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TeamProfileScreen(teamId: teamDocId),
                          ),
                        );
                      },
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