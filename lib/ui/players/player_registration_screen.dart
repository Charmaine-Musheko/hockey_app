import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth for current user

class PlayerRegistrationScreen extends StatefulWidget {
  // Optional: Pass playerId if editing an existing player.
  // This playerId will now be the user's UID.
  final String? playerId;

  // teamId and teamName are now optional in the constructor.
  // They are used for initial selection when adding a new player.
  // When editing, the screen will fetch the player's team data.
  final String? teamId;
  final String? teamName;

  PlayerRegistrationScreen({
    Key? key,
    this.teamId, // Made optional
    this.teamName, // Made optional
    this.playerId,
  }) : super(key: key);

  @override
  _PlayerRegistrationScreenState createState() => _PlayerRegistrationScreenState();
}

class _PlayerRegistrationScreenState extends State<PlayerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _goalsController = TextEditingController();
  final TextEditingController _assistsController = TextEditingController();
  final TextEditingController _gamesPlayedController = TextEditingController();
  final TextEditingController _achievementsController = TextEditingController();
  final TextEditingController _jerseyNumberController = TextEditingController(); // Added jersey number controller

  String? _selectedUserId; // To store the UID of the selected user for new registrations
  List<DropdownMenuItem<String>> _userDropdownItems = []; // List to hold user dropdown items
  Map<String, Map<String, dynamic>> _userMap = {}; // Map to store user data by UID

  String? _currentTeamId; // Internal state for the team ID of the player being registered/edited
  String? _currentTeamName; // Internal state for the team name of the player being registered/edited

  bool _isLoading = false; // To show a loading indicator for saving/loading player
  bool _isFetchingUsers = true; // To indicate if users are being fetched
  bool _isEditing = false; // To know if we are editing or adding

  @override
  void initState() {
    super.initState();
    _isEditing = widget.playerId != null;

    // If adding a new player, use the teamId and teamName passed from the widget
    if (!_isEditing) {
      _currentTeamId = widget.teamId;
      _currentTeamName = widget.teamName;
    }

    _fetchUsers(); // Fetch users (for new player selection)
    // No need to fetch all teams if we're always getting teamId/Name from widget or player doc
    // _fetchTeams(); // Removed as per user request
  }

  @override
  void dispose() {
    _positionController.dispose();
    _goalsController.dispose();
    _assistsController.dispose();
    _gamesPlayedController.dispose();
    _achievementsController.dispose();
    _jerseyNumberController.dispose(); // Dispose jersey number controller
    super.dispose();
  }

  // Function to fetch the list of users from Firestore (only 'Player' role)
  Future<void> _fetchUsers() async {
    setState(() {
      _isFetchingUsers = true;
    });
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Player') // Filter by 'Player' role
          .get();
      List<DropdownMenuItem<String>> items = [];
      Map<String, Map<String, dynamic>> usersData = {};

      for (var doc in snapshot.docs) {
        final userData = doc.data() as Map<String, dynamic>;
        final String uid = doc.id;
        final String role = userData['role'] ?? 'Fan';
        final String firstName = userData['firstName'] ?? '';
        final String lastName = userData['lastName'] ?? '';
        final String email = userData['email'] ?? 'No Email';

        String displayName = '';
        if (firstName.isNotEmpty && lastName.isNotEmpty) {
          displayName = '$firstName $lastName ($role)';
        } else if (firstName.isNotEmpty) {
          displayName = '$firstName ($role)';
        } else {
          displayName = '$email ($role)';
        }

        items.add(DropdownMenuItem(
          value: uid,
          child: Text(displayName),
        ));
        usersData[uid] = userData; // Store full user data
      }

      setState(() {
        _userDropdownItems = items;
        _userMap = usersData;
        _isFetchingUsers = false;

        // If adding and no user selected, pre-select the first user if available
        if (!_isEditing && _selectedUserId == null && _userDropdownItems.isNotEmpty) {
          _selectedUserId = _userDropdownItems.first.value;
        }
        // If editing, load player data after users are fetched
        else if (_isEditing) {
          _loadPlayerData(widget.playerId!);
        }
      });

    } catch (e) {
      print("Error fetching users: $e");
      setState(() {
        _isFetchingUsers = false;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load users.')));
      });
    }
  }

  // Function to load data for editing an existing player profile
  Future<void> _loadPlayerData(String playerId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      // The player document ID is now the user's UID
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('players').doc(playerId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _positionController.text = data['position'] ?? '';
        _jerseyNumberController.text = (data['jerseyNumber']?.toString() ?? ''); // Load jersey number
        _goalsController.text = (data['goals']?.toString() ?? '0');
        _assistsController.text = (data['assists']?.toString() ?? '0');
        _gamesPlayedController.text = (data['gamesPlayed']?.toString() ?? '0');
        final List<dynamic> achievementsList = data['achievements'] is List ? data['achievements'] : [];
        _achievementsController.text = achievementsList.join(', ');

        // Set the selected user and team from player data
        _selectedUserId = data['userId'];
        _currentTeamId = data['teamId'];
        _currentTeamName = data['teamName'];

      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Player profile not found for editing.')));
        Navigator.pop(context);
      }
    } catch (e) {
      print("Error loading player data: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load player data.')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to save or update player data
  Future<void> _savePlayer() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select a user to register as a player.')));
        return;
      }
      // Ensure team context is available for both new and edited players
      if (_currentTeamId == null || _currentTeamName == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Team context is missing. Please ensure the player has an associated team.')));
        return;
      }


      setState(() {
        _isLoading = true;
      });

      final selectedUserData = _userMap[_selectedUserId!];
      final String playerName = '${selectedUserData!['firstName'] ?? ''} ${selectedUserData['lastName'] ?? ''}'.trim();
      final String playerEmail = selectedUserData['email'] ?? '';

      // Prepare data map for player profile
      Map<String, dynamic> playerData = {
        'userId': _selectedUserId, // Link to the user's UID
        'playerName': playerName.isEmpty ? playerEmail : playerName, // Use name if available, else email
        'position': _positionController.text.trim(),
        'jerseyNumber': int.tryParse(_jerseyNumberController.text.trim()) ?? null,
        'teamId': _currentTeamId, // Link to the current team
        'teamName': _currentTeamName, // Store current team name for easier display
        'goals': int.tryParse(_goalsController.text.trim()) ?? 0,
        'assists': int.tryParse(_assistsController.text.trim()) ?? 0,
        'gamesPlayed': int.tryParse(_gamesPlayedController.text.trim()) ?? 0,
        'achievements': _achievementsController.text.trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'timestamp': FieldValue.serverTimestamp(), // Update timestamp on save
      };

      try {
        // Use the selected user's UID as the document ID for the player profile
        await FirebaseFirestore.instance.collection('players').doc(_selectedUserId).set(playerData, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Player profile saved successfully!')));

        if (!_isEditing) {
          _positionController.clear();
          _jerseyNumberController.clear();
          _goalsController.clear();
          _assistsController.clear();
          _gamesPlayedController.clear();
          _achievementsController.clear();
          setState(() {
            _selectedUserId = null; // Reset selected user
            // Keep team context for potential next player registration for the same team
          });
        } else {
          Navigator.pop(context);
        }

      } catch (e) {
        print("Error saving player: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save player.')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle = _isEditing
        ? 'Edit Player Profile'
        : 'Register Player for ${_currentTeamName ?? 'Team'}'; // Use _currentTeamName for display

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
      ),
      body: _isLoading || _isFetchingUsers
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // User Selection Dropdown (only for adding new player)
              if (!_isEditing) ...[
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Select User (Player Role)'),
                  value: _selectedUserId,
                  items: _userDropdownItems,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedUserId = newValue;
                    });
                  },
                  validator: (val) => val == null ? 'Please select a user' : null,
                  hint: Text('Select a user with Player role'),
                ),
                SizedBox(height: 16.0),
              ],
              // Display selected user's name if editing
              if (_isEditing && _selectedUserId != null && _userMap.containsKey(_selectedUserId))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Player: ${_userMap[_selectedUserId]!['firstName'] ?? ''} ${_userMap[_selectedUserId]!['lastName'] ?? ''} (${_userMap[_selectedUserId]!['email']})',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              SizedBox(height: 16.0),

              // Display Team Name (auto-populated)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Team: ${_currentTeamName ?? 'Loading Team...'}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 16.0),

              TextFormField(
                controller: _positionController,
                decoration: InputDecoration(labelText: 'Position (e.g., Forward, Defense, Goalie)'),
                validator: (val) => val!.isEmpty ? 'Enter player position' : null,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _jerseyNumberController,
                decoration: InputDecoration(labelText: 'Jersey Number (Optional)'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val != null && val.isNotEmpty && int.tryParse(val) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24.0),

              // --- Stats Section ---
              Text(
                'Stats',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _goalsController,
                decoration: InputDecoration(labelText: 'Goals'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val != null && val.isNotEmpty && int.tryParse(val) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _assistsController,
                decoration: InputDecoration(labelText: 'Assists'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val != null && val.isNotEmpty && int.tryParse(val) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _gamesPlayedController,
                decoration: InputDecoration(labelText: 'Games Played'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val != null && val.isNotEmpty && int.tryParse(val) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24.0),

              // --- Achievements Section ---
              Text(
                'Achievements',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _achievementsController,
                decoration: InputDecoration(
                  labelText: 'Achievements (comma-separated)',
                  hintText: 'e.g., MVP 2023, All-Star Team',
                ),
                maxLines: null,
                keyboardType: TextInputType.multiline,
              ),
              SizedBox(height: 24.0),

              ElevatedButton(
                child: Text(_isEditing ? 'Update Player' : 'Register Player'),
                onPressed: _savePlayer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
