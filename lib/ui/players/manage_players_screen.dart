import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hockey_union_app/services/auth_service.dart'; // Import AuthService to get user data
import 'package:hockey_union_app/ui/players/player_registration_screen.dart'; // Import Player Registration/Edit Screen
import 'package:hockey_union_app/ui/players/player_profile_screen.dart'; // Import PlayerProfileScreen

class ManagePlayersScreen extends StatefulWidget {
  final String userId; // Accept the user ID to determine the user's role

  const ManagePlayersScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ManagePlayersScreenState createState() => _ManagePlayersScreenState();
}

class _ManagePlayersScreenState extends State<ManagePlayersScreen> {
  String? _selectedTeamId; // To store the selected team's document ID
  List<DropdownMenuItem<String>> _teamDropdownItems = []; // List to hold team dropdown items
  Map<String, String> _teamNames = {}; // Map to store team IDs and names

  bool _isLoadingTeams = true; // To indicate if teams are being fetched
  String? _userRole; // To store the fetched user role

  @override
  void initState() {
    super.initState();
    _fetchUserDataAndTeams(); // Fetch user data and teams when the screen initializes
  }

  // Function to fetch user data and then teams
  Future<void> _fetchUserDataAndTeams() async {
    setState(() {
      _isLoadingTeams = true;
    });
    try {
      final userData = await AuthService().getUserData(widget.userId);
      if (userData != null) {
        _userRole = userData['role'] ?? 'Fan';
        // Only fetch teams if the user is authorized to manage players
        if (_userRole == 'Coach' || _userRole == 'Admin') {
          await _fetchTeams(); // Fetch teams after getting user role
          // If user has a teamId associated, pre-select it in the dropdown
          final String? userAssociatedTeamId = userData['teamId'];
          if (userAssociatedTeamId != null && _teamNames.containsKey(userAssociatedTeamId)) {
            setState(() {
              _selectedTeamId = userAssociatedTeamId;
            });
          } else if (_teamDropdownItems.isNotEmpty) {
            // If no associated team or team not found, select the first team
            setState(() {
              _selectedTeamId = _teamDropdownItems.first.value;
            });
          }
        }
      } else {
        // Handle case where user data couldn't be fetched
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load user data.')));
      }
    } catch (e) {
      print("Error fetching user data or teams: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load data.')));
    } finally {
      setState(() {
        _isLoadingTeams = false;
      });
    }
  }


  // Function to fetch the list of teams from Firestore
  Future<void> _fetchTeams() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('teams').orderBy('teamName').get();
      List<DropdownMenuItem<String>> items = [];
      Map<String, String> names = {};

      for (var doc in snapshot.docs) {
        final teamData = doc.data() as Map<String, dynamic>;
        final teamId = doc.id;
        final teamName = teamData['teamName'] ?? 'Unnamed Team';
        items.add(DropdownMenuItem(
          value: teamId,
          child: Text(teamName),
        ));
        names[teamId] = teamName;
      }

      setState(() {
        _teamDropdownItems = items;
        _teamNames = names;
      });

    } catch (e) {
      print("Error fetching teams: $e");
      // Optionally show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load teams.')));
    }
  }


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
    // Check if the user role is loaded and authorized
    if (_isLoadingTeams) {
      return Scaffold(
        appBar: AppBar(title: Text('Manage Players')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userRole != 'Coach' && _userRole != 'Admin') {
      return Scaffold(
        appBar: AppBar(title: Text('Manage Players')),
        body: Center(child: Text('You do not have permission to manage players.')),
      );
    }

    // User is authorized, show the screen content
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Players'),
      ),
      body: Column( // Use a Column to arrange dropdown and player list
        children: [
          // Team Selection Dropdown
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Team to Manage',
                enabled: _teamDropdownItems.isNotEmpty, // Corrected: enabled on InputDecoration
              ),
              value: _selectedTeamId, // Current selected value
              items: _teamDropdownItems, // List of dropdown items
              onChanged: (String? newValue) {
                setState(() {
                  _selectedTeamId = newValue;
                });
              },
              validator: (val) => val == null ? 'Please select a team' : null,
            ),
          ),
          Expanded( // Allow the player list to take the remaining space
            child: _selectedTeamId == null
                ? Center(child: Text('Please select a team to view players.'))
                : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('players')
                  .where('teamId', isEqualTo: _selectedTeamId) // Filter players by the selected team ID
                  .orderBy('playerName') // Order players alphabetically
                  .snapshots(),
              builder: (context, playerSnapshot) {
                // Show loading indicator for player data
                if (playerSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                // Handle errors fetching player data
                if (playerSnapshot.hasError) {
                  print("Error fetching players for team $_selectedTeamId: ${playerSnapshot.error}");
                  return Center(child: Text('Error loading players.'));
                }

                final players = playerSnapshot.data!.docs;

                if (players.isEmpty) {
                  return Center(child: Text('No players registered for this team yet.'));
                }

                // Display the list of players with edit/delete options
                return ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index].data() as Map<String, dynamic>;
                    final playerId = players[index].id; // Get player document ID (which is now the user's UID)
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
                                // Navigate to PlayerRegistrationScreen for editing, passing only the playerId
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlayerRegistrationScreen(
                                      playerId: playerId, teamId: '', // Pass the player ID for editing
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
                        onTap: () {
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
          ),
        ],
      ),
    );
  }
}
