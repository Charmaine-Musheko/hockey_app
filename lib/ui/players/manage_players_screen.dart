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

  // We no longer need _isLoadingTeams and _userRole as instance variables
  // because StreamBuilder will handle the loading state and provide the data.

  @override
  void initState() {
    super.initState();
    _fetchTeams(); // Only fetch teams initially. User role will be handled by StreamBuilder.
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
        // If teams are fetched, and _selectedTeamId is null, try to set the first one
        if (_selectedTeamId == null && _teamDropdownItems.isNotEmpty) {
          _selectedTeamId = _teamDropdownItems.first.value;
        }
      });

    } catch (e) {
      print("Error fetching teams: $e");
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
    final AuthService _auth = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Players'),
      ),
      // --- Use StreamBuilder to get real-time user data ---
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _auth.getUserDataStream(widget.userId),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Handle error or missing user data
          if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
            print("Error or missing user data in ManagePlayersScreen: ${userSnapshot.error ?? 'Document does not exist.'}");
            return Center(child: Text('Failed to load user permissions.'));
          }

          final userData = userSnapshot.data!.data();
          final userRole = userData?['role'] ?? 'Fan';
          final bool canManagePlayers = userRole == 'Coach' || userRole == 'Admin';

          if (!canManagePlayers) {
            return Center(child: Text('You do not have permission to manage players.'));
          }

          // User is authorized, show the content
          return Column(
            children: [
              // Team Selection Dropdown
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Select Team to Manage',
                    // Conditionally disable if no teams are loaded
                    enabled: _teamDropdownItems.isNotEmpty,
                  ),
                  value: _selectedTeamId,
                  items: _teamDropdownItems,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedTeamId = newValue;
                    });
                  },
                  validator: (val) => val == null ? 'Please select a team' : null,
                ),
              ),
              Expanded(
                child: _selectedTeamId == null
                    ? Center(child: Text('Please select a team to view players.'))
                    : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('players')
                      .where('teamId', isEqualTo: _selectedTeamId)
                      .orderBy('playerName')
                      .snapshots(),
                  builder: (context, playerSnapshot) {
                    if (playerSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (playerSnapshot.hasError) {
                      print("Error fetching players for team $_selectedTeamId: ${playerSnapshot.error}");
                      return Center(child: Text('Error loading players.'));
                    }

                    final players = playerSnapshot.data!.docs;

                    if (players.isEmpty) {
                      return Center(child: Text('No players registered for this team yet.'));
                    }

                    return ListView.builder(
                      itemCount: players.length,
                      itemBuilder: (context, index) {
                        final player = players[index].data() as Map<String, dynamic>;
                        final playerId = players[index].id;
                        final playerName = player['playerName'] ?? 'Unknown Player';
                        final playerPosition = player['position'] ?? 'N/A';

                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          child: ListTile(
                            leading: Icon(Icons.person),
                            title: Text(playerName),
                            subtitle: Text('Position: $playerPosition'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  tooltip: 'Edit Player',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PlayerRegistrationScreen(
                                          playerId: playerId, teamId: _selectedTeamId ?? '', // Pass the player ID and selected team ID
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Delete Player',
                                  onPressed: () {
                                    _deletePlayer(context, playerId, playerName);
                                  },
                                ),
                              ],
                            ),
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
          );
        },
      ),
    );
  }
}